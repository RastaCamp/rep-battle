import 'dart:math';

import '../models/game_card.dart';
import '../models/quest/quest_dungeon.dart';
import '../models/quest/quest_enemy.dart';
import '../models/quest/quest_item.dart';
import '../models/quest/quest_player_state.dart';
import '../models/quest/quest_run_state.dart';
import '../../services/quest_data_loader.dart';

class QuestCombatOutcome {
  final int damageToEnemy;
  final int damageToPlayer;
  final int armorGained;
  final int hpHealed;
  final int goldGained;
  final int xpGained;
  final String message;
  final bool enemyDefeated;
  final bool comboBroken;
  final String? barkKind;

  const QuestCombatOutcome({
    this.damageToEnemy = 0,
    this.damageToPlayer = 0,
    this.armorGained = 0,
    this.hpHealed = 0,
    this.goldGained = 0,
    this.xpGained = 0,
    this.message = '',
    this.enemyDefeated = false,
    this.comboBroken = false,
    this.barkKind,
  });
}

class QuestEngine {
  final QuestDataBundle data;
  final Random _rng;

  QuestEngine(this.data, {int? seed}) : _rng = Random(seed);

  String suitCombatLabel(CardSuit suit) => switch (suit) {
        CardSuit.spades => 'Power Attack',
        CardSuit.hearts => 'Endurance / Heal',
        CardSuit.clubs => 'Core / Defense',
        CardSuit.diamonds => 'Speed / Evasion',
        CardSuit.joker => 'Chaos',
      };

  String cardRpgAction(GameCard card) {
    if (card.isJoker) return 'Joker — Rest, Loot, or Chaos';
    if (card.isKing) return 'Boss Strike / Group Challenge';
    if (card.isQueen) return 'Defend / Shield';
    if (card.isJack) return 'Combo Strike (repeat last attack)';
    if (card.rank == 'A') return 'Weak Hit / Lucky Dodge';
    return 'Attack';
  }

  String challengeText(GameCard card) {
    final action = cardRpgAction(card);
    final suit = suitCombatLabel(card.suit);
    if (card.isQueen || card.isJoker) {
      return '$suit — $action\n${card.exerciseName} ${card.displayReps}';
    }
    return '$suit — $action\n${card.exerciseName} × ${card.displayReps}';
  }

  QuestRoomSpec roomSpec(QuestDungeonTemplate dungeon, int roomIndex) {
    final idx = roomIndex - 1;
    if (idx >= 0 && idx < dungeon.rooms.length) {
      return dungeon.rooms[idx];
    }
    return const QuestRoomSpec(type: QuestRoomType.combat);
  }

  String pickEnemyTemplateId({
    required QuestDungeonTemplate dungeon,
    required int roomIndex,
    required QuestRoomSpec spec,
  }) {
    final isBoss = spec.type == QuestRoomType.boss ||
        (roomIndex % dungeon.bossEvery == 0 && roomIndex > 0);
    if (isBoss) return dungeon.bossId;

    switch (spec.type) {
      case QuestRoomType.trap:
        return 'dust_sprite';
      case QuestRoomType.combat:
        if (dungeon.id == 'rust_arena') {
          return _rng.nextDouble() < 0.6 ? 'rust_goblin' : 'iron_rat';
        }
        break;
      default:
        break;
    }
    return dungeon.enemyPool[_rng.nextInt(dungeon.enemyPool.length)];
  }

  QuestEnemyInstance spawnEnemy({
    required QuestDungeonTemplate dungeon,
    required QuestDifficulty difficulty,
    required int roomIndex,
    required QuestRoomSpec spec,
    String? templateId,
  }) {
    final enemyId = templateId ??
        pickEnemyTemplateId(
          dungeon: dungeon,
          roomIndex: roomIndex,
          spec: spec,
        );
    final t = QuestEnemyCatalog.get(enemyId);
    return QuestEnemyInstance.fromTemplate(
      t,
      hpMult: difficulty.enemyHpMult,
      attackBonus: difficulty.enemyAttackBonus,
    );
  }

  GameCard drawCard(QuestRunState run) {
    if (run.deck.isEmpty) {
      run.deck.addAll(run.discard);
      run.discard.clear();
      run.deck.shuffle(_rng);
    }
    final card = run.deck.removeAt(0);
    run.currentCard = card;
    run.discard.add(card);
    run.cardDrawnThisTurn = true;
    if (!card.isJack) {
      run.previousCard = card;
    }
    return card;
  }

  QuestCombatOutcome resolveTurn({
    required QuestRunState run,
    required TurnResultType result,
    String? jokerChoice,
  }) {
    final player = run.activePlayer;
    final card = run.currentCard;
    final enemy = run.enemy;
    if (card == null) {
      return const QuestCombatOutcome(message: 'No card drawn.');
    }

    if (result == TurnResultType.skip) {
      if (player.skips <= 0) {
        return const QuestCombatOutcome(message: 'No skips left.');
      }
      player.skips--;
      run.combo = 0;
      return QuestCombatOutcome(
        message: '${player.name} skipped the challenge.',
        comboBroken: true,
      );
    }

    if (card.isJoker && result == TurnResultType.pass && jokerChoice != null) {
      return _resolveJoker(run, player, jokerChoice);
    }

    if (enemy == null) {
      return _resolveNonCombat(run, player, card, result);
    }

  return _resolveCombat(run, player, enemy, card, result);
  }

  QuestCombatOutcome _resolveJoker(
    QuestRunState run,
    QuestPlayerState player,
    String choice,
  ) {
    switch (choice) {
      case 'rest':
        player.heal(2);
        run.combo++;
        return QuestCombatOutcome(
          hpHealed: 2,
          message: 'Joker Rest — healed 2 HP.',
        );
      case 'loot':
        run.pendingLootIds.add(rollLoot('treasure'));
        return QuestCombatOutcome(
          message: 'Joker Loot — treasure incoming!',
        );
      default:
        run.combo++;
        return QuestCombatOutcome(
          message: 'Chaos Event — combo +1! Draw again next room.',
          goldGained: 2,
        );
    }
  }

  QuestCombatOutcome _resolveNonCombat(
    QuestRunState run,
    QuestPlayerState player,
    GameCard card,
    TurnResultType result,
  ) {
    if (result == TurnResultType.fail) {
      player.takeDamage(1);
      run.combo = 0;
      return QuestCombatOutcome(
        damageToPlayer: 1,
        message: 'Failed — took 1 damage.',
        comboBroken: true,
      );
    }
    final mult = result == TurnResultType.modified ? 0.5 : 1.0;
    final dmg = (_cardDamage(card) * mult).round();
    run.combo++;
    return QuestCombatOutcome(
      damageToEnemy: dmg,
      message: 'Hit for $dmg (no enemy).',
    );
  }

  QuestCombatOutcome _resolveCombat(
    QuestRunState run,
    QuestPlayerState player,
    QuestEnemyInstance enemy,
    GameCard card,
    TurnResultType result,
  ) {
    if (result == TurnResultType.fail) {
      player.takeDamage(enemy.attack);
      run.combo = 0;
      player.combo = 0;
      return QuestCombatOutcome(
        damageToPlayer: enemy.attack,
        message:
            'FAIL — ${enemy.name} hits for ${enemy.attack}! Combo broken.',
        comboBroken: true,
        barkKind: 'playerFail',
      );
    }

    var dmg = 0;
    var armorGain = 0;
    var healed = 0;
    String msg;

    if (card.isQueen) {
      if (result == TurnResultType.pass ||
          result == TurnResultType.modified) {
        armorGain = 1;
        player.armor++;
        if (player.inventory.hasRelic('crown_of_kings') &&
            result == TurnResultType.pass) {
          armorGain++;
          player.armor++;
        }
        run.combo++;
        player.combo++;
        msg = 'Queen defend — +$armorGain armor.';
      } else {
        dmg = (_cardDamage(card) * 0.5).round();
        msg = 'Queen modified — light hit for $dmg.';
      }
    } else if (card.isKing) {
      dmg = result == TurnResultType.modified ? 7 : 15;
      msg = 'KING STRIKE — $dmg damage!';
      run.combo += 2;
    } else if (card.isJack) {
      final prev = run.previousCard;
      final base = prev != null ? _cardDamage(prev) : 5;
      dmg = result == TurnResultType.modified
          ? (base * 0.5).round()
          : base;
      msg = 'Jack combo — $dmg damage (repeat last attack).';
      run.combo++;
    } else {
      final base = _cardDamage(card);
      dmg = result == TurnResultType.modified
          ? (base * 0.5).round().clamp(1, 99)
          : base + player.attackBonus;
      msg = result == TurnResultType.modified
          ? 'Modified hit — $dmg damage.'
          : 'Attack — $dmg damage!';
      run.combo++;
      player.combo++;
    }

    if (dmg > 0 && _isWeakness(card, enemy)) {
      dmg += 2;
      msg += ' Weakness bonus +2!';
    }

    if (dmg > 0) {
      enemy.hp -= dmg;
      if (enemy.hp < 0) enemy.hp = 0;
    }

    var defeated = enemy.defeated;
    var xp = 0;
    var gold = 0;
    String? bark;

    if (defeated) {
      xp = enemy.rewardXp;
      gold = enemy.rewardGold;
      player.xp += xp;
      player.gold += gold;
      if (player.inventory.hasRelic('combo_charm') && run.combo >= 3) {
        gold += 2;
        player.gold += 2;
      }
      bark = 'defeated';
      msg += ' ${enemy.name} defeated! +$xp XP, +$gold gold.';
    } else if (enemy.lowHealth) {
      bark = 'lowHealth';
    } else if (dmg > 0) {
      bark = 'pain';
    }

    return QuestCombatOutcome(
      damageToEnemy: dmg,
      armorGained: armorGain,
      hpHealed: healed,
      goldGained: gold,
      xpGained: xp,
      message: msg,
      enemyDefeated: defeated,
      barkKind: bark,
    );
  }

  bool _isWeakness(GameCard card, QuestEnemyInstance enemy) {
    if (card.isJoker || card.isJack) return false;
    return card.suit.name == enemy.weakness;
  }

  int _cardDamage(GameCard card) {
    if (card.isKing) return 15;
    if (card.rank == 'A') return 1;
    final n = int.tryParse(card.rank);
    if (n != null) return n;
    if (card.reps != null) return card.reps!.clamp(1, 15);
    return 5;
  }

  String rollLoot(String tableKey) {
    final table = data.lootTables[tableKey] ?? data.lootTables['normal']!;
    return table[_rng.nextInt(table.length)];
  }

  List<String> rollRoomLoot(QuestRoomSpec spec, {bool isBoss = false}) {
    final items = <String>[];
    if (isBoss || spec.type == QuestRoomType.boss) {
      items.add(rollLoot('boss'));
      return items;
    }
    if (spec.type == QuestRoomType.treasure) {
      items.add(rollLoot('treasure'));
      if (_rng.nextBool()) items.add(rollLoot('normal'));
      return items;
    }
    if (spec.type == QuestRoomType.combat && _rng.nextDouble() < 0.25) {
      items.add(rollLoot('normal'));
    }
    return items;
  }

  void applyRelicsOnRunStart(QuestPlayerState player) {
    if (player.inventory.hasRelic('titan_heart')) {
      final bonus = QuestItemCatalog.effectValue(
        QuestItemCatalog.get('titan_heart')!,
        'maxHpBonus',
        2,
      );
      player.maxHp += bonus;
      player.hp += bonus;
    }
  }

  void applyItemEffects(QuestPlayerState player, QuestItem item) {
    final heal = QuestItemCatalog.effectValue(item, 'healHp');
    if (heal > 0) player.heal(heal);
    final armor = QuestItemCatalog.effectValue(item, 'addArmor');
    if (armor > 0) player.armor += armor;
    final skips = QuestItemCatalog.effectValue(item, 'addSkips');
    if (skips > 0) player.skips += skips;
  }

  String enemyBark(QuestEnemyInstance enemy, String kind) {
    final t = QuestEnemyCatalog.tryGet(enemy.templateId);
    if (t == null) return '';
    return t.pickBark(kind);
  }
}
