# Helper to merge quote blocks into npc_profiles.json
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from npc_quotes_respect_pain import RESPECT_PAIN_QUOTES

QUOTES = {
    "anton_40": {
        "quotesModified": [
            "Modified reps still move the mountain.",
            "Knees screaming, pride whispering.",
            "I work smart before I work broken.",
        ],
        "quotesClutch": [
            "That one almost folded me.",
            "Still standing. Barely.",
            "Trash routes trained me for this.",
        ],
        "quotesStartMatch": [
            "Let's get this route started.",
            "Hope y'all stretched.",
            "Night shift energy.",
        ],
        "quotesLegendary": [
            "Steel bins forged steel hands.",
            "Pain clocks in late around me.",
            "The route never truly ends.",
        ],
        "quotesTeamUp": [
            "We carry the load together.",
            "Don't quit on me now.",
            "Teamwork makes lighter work.",
        ],
    },
    "mia_12": {
        "quotesModified": [
            "Coach said breathing matters too!",
            "Still counts if I finish!",
            "Asthma ain't stopping me today.",
        ],
        "quotesClutch": [
            "I almost tapped out!",
            "Okay that was scary.",
            "Still alive though!",
        ],
        "quotesStartMatch": ["I'm ready!", "This is gonna be fun!", "No boring rounds please!"],
        "quotesLegendary": [
            "Tiny but unstoppable.",
            "Future champion loading.",
            "The comeback starts now!",
        ],
        "quotesTeamUp": ["We got this!", "Okay team, go go go!", "Don't leave me hanging!"],
    },
    "rosa_67": {
        "quotesModified": [
            "Form first. Ego second.",
            "Safe movement is strong movement.",
            "A wise athlete adapts.",
        ],
        "quotesClutch": [
            "Experience carried that round.",
            "A close call teaches patience.",
            "Not fast, just durable.",
        ],
        "quotesStartMatch": [
            "Remember your form.",
            "Warm up properly.",
            "Let's move safely.",
        ],
        "quotesLegendary": [
            "Wisdom is endurance.",
            "Patience defeats panic.",
            "The old lessons still matter.",
        ],
        "quotesTeamUp": [
            "Support each other.",
            "Steady pace as a group.",
            "Encourage, don't discourage.",
        ],
    },
    "derek_28": {
        "quotesModified": [
            "Back's tight, not broken.",
            "Half speed still stronger than most.",
            "Modified doesn't mean weak.",
        ],
        "quotesClutch": [
            "That burned bad.",
            "Almost lost my lunch there.",
            "Competitive spirit saved me.",
        ],
        "quotesStartMatch": [
            "Somebody's getting humbled.",
            "Let's work.",
            "No easy rounds.",
        ],
        "quotesLegendary": [
            "Strength built under pressure.",
            "Heavy work makes heavy hitters.",
            "You can't fake grit.",
        ],
        "quotesTeamUp": ["Pull your weight.", "No weak links.", "Let's crush this together."],
    },
    "jin_19": {
        "quotesModified": [
            "Beginner build in progress.",
            "I'm learning the mechanics.",
            "Adaptation patch installed.",
        ],
        "quotesClutch": [
            "One HP remaining.",
            "Critical condition achieved.",
            "I survived somehow.",
        ],
        "quotesStartMatch": [
            "Queueing into battle.",
            "Good luck, have fun.",
            "Time to grind XP.",
        ],
        "quotesLegendary": [
            "Evolution through repetition.",
            "Every defeat updates the build.",
            "Adaptation complete.",
        ],
        "quotesTeamUp": [
            "Party buff activated.",
            "Squad synergy online.",
            "Co-op mode engaged.",
        ],
    },
    "carmen_35": {
        "quotesModified": [
            "Recovery is part of training.",
            "Protect the feet, protect the future.",
            "Sustainable effort wins.",
        ],
        "quotesClutch": [
            "Need electrolytes immediately.",
            "That shift-level exhaustion hit.",
            "Still functioning. Technically.",
        ],
        "quotesStartMatch": [
            "Hydrate before we start.",
            "No injuries tonight.",
            "Everybody ready?",
        ],
        "quotesLegendary": [
            "Recovery creates resilience.",
            "Compassion and strength coexist.",
            "Discipline outlasts motivation.",
        ],
        "quotesTeamUp": [
            "Check on your teammates.",
            "Recovery together.",
            "Support matters.",
        ],
    },
    "tyler_16": {
        "quotesModified": [
            "Temporary adjustment only.",
            "Still putting up numbers.",
            "Brace or no brace, I'm here.",
        ],
        "quotesClutch": [
            "That was almost embarrassing.",
            "I recovered at the last second.",
            "Clutch athlete moment.",
        ],
        "quotesStartMatch": [
            "Let's dominate.",
            "Competition mode activated.",
            "No weak effort today.",
        ],
        "quotesLegendary": [
            "Pressure creates athletes.",
            "The crowd fuels me.",
            "Champions hate excuses.",
        ],
        "quotesTeamUp": ["Team energy!", "We move as one.", "No falling behind!"],
    },
    "grace_52": {
        "quotesModified": [
            "Small improvements add up.",
            "I don't need perfect reps.",
            "Consistency over intensity.",
        ],
        "quotesClutch": [
            "Deep breath… keep going.",
            "Almost shut down there.",
            "Progress isn't always pretty.",
        ],
        "quotesStartMatch": [
            "One step at a time.",
            "Just keep moving.",
            "Let's do our best.",
        ],
        "quotesLegendary": [
            "Quiet consistency changes lives.",
            "Small victories become transformation.",
            "Persistence rewrites habits.",
        ],
        "quotesTeamUp": [
            "We're stronger together.",
            "Little encouragement helps.",
            "Group effort counts.",
        ],
    },
    "omar_45": {
        "quotesModified": [
            "Mobility before pride.",
            "Doctor would approve this pace.",
            "Tight hips, steady progress.",
        ],
        "quotesClutch": [
            "That one hit harder than traffic.",
            "Barely made the turn.",
            "Need to stretch after that.",
        ],
        "quotesStartMatch": [
            "Hope y'all got stamina.",
            "Shortcuts won't save you.",
            "Time to move.",
        ],
        "quotesLegendary": [
            "Movement is survival.",
            "Even slow progress beats standing still.",
            "Every road teaches something.",
        ],
        "quotesTeamUp": [
            "Everybody keep moving.",
            "Stay in rhythm.",
            "No one gets left behind.",
        ],
    },
    "lily_9": {
        "quotesModified": [
            "Tiny version activated!",
            "I'm still doing it!",
            "Modified is more fun!",
        ],
        "quotesClutch": [
            "I almost became a pancake!",
            "That was SUPER hard!",
            "I thought I was done!",
        ],
        "quotesStartMatch": [
            "I'm gonna win!",
            "Can we do funny cards?",
            "This is awesome!",
        ],
        "quotesLegendary": [
            "Fun is a superpower!",
            "Laughing makes me stronger!",
            "Energy beats fear!",
        ],
        "quotesTeamUp": [
            "Team awesome!",
            "We're gonna crush it!",
            "Friends make it easier!",
        ],
    },
    "vic_31": {
        "quotesModified": [
            "Shoulder says relax.",
            "I'll grind through another way.",
            "Pain changes the strategy.",
        ],
        "quotesClutch": [
            "Pain almost won.",
            "That round fought dirty.",
            "Still tougher than the card.",
        ],
        "quotesStartMatch": [
            "Pain builds champions.",
            "Lock in.",
            "No excuses tonight.",
        ],
        "quotesLegendary": [
            "Pain sharpens purpose.",
            "Built from pressure and caffeine.",
            "Hard work leaves scars and stories.",
        ],
        "quotesTeamUp": ["Work like a crew.", "Hold the line.", "Push through together."],
    },
    "elena_24": {
        "quotesModified": [
            "Controlled movement only.",
            "Precision over power.",
            "Even dancers modify sometimes.",
        ],
        "quotesClutch": [
            "Okay… respect to that challenge.",
            "Even I felt that one.",
            "Close, but not close enough.",
        ],
        "quotesStartMatch": [
            "Feel the rhythm.",
            "Movement is medicine.",
            "Ready to flow?",
        ],
        "quotesLegendary": [
            "Movement becomes freedom.",
            "Balance creates power.",
            "Grace can still dominate.",
        ],
        "quotesTeamUp": ["Match the rhythm.", "Flow together.", "Movement sync."],
    },
    "frank_58": {
        "quotesModified": [
            "Old mechanic trick: conserve energy.",
            "Adjusted, not defeated.",
            "Still turning the wrench.",
        ],
        "quotesClutch": [
            "Engine almost stalled.",
            "That was rough on the chassis.",
            "Still got enough gas left.",
        ],
        "quotesStartMatch": [
            "Let's fire it up.",
            "Don't quit early.",
            "Time for a tune-up.",
        ],
        "quotesLegendary": [
            "Old engines still roar.",
            "Strength doesn't retire.",
            "Patience keeps machines alive.",
        ],
        "quotesTeamUp": [
            "Good crews finish jobs.",
            "Keep the engine running.",
            "Everybody contributes.",
        ],
    },
    "zoe_22": {
        "quotesModified": [
            "Grip's tired, switching style.",
            "Climbing teaches adaptation.",
            "Efficient movement matters.",
        ],
        "quotesClutch": [
            "Forearms are cooked.",
            "Almost slipped off the wall.",
            "That challenge had teeth.",
        ],
        "quotesStartMatch": [
            "Climber energy online.",
            "Let's get vertical.",
            "Ready to sweat?",
        ],
        "quotesLegendary": [
            "Grip strength is mindset.",
            "Climbers trust the next hold.",
            "The wall teaches resilience.",
        ],
        "quotesTeamUp": [
            "Climbing partners matter.",
            "Trust your team.",
            "Shared effort, shared win.",
        ],
    },
    "sam_70": {
        "quotesModified": [
            "Slow and steady modifications.",
            "Still in the garden, still growing.",
            "No shame in pacing.",
        ],
        "quotesClutch": [
            "Slow breathing saved me.",
            "Old lungs still hanging on.",
            "Close one, youngster.",
        ],
        "quotesStartMatch": [
            "Slow starts still finish races.",
            "Good to see everybody moving.",
            "Let's enjoy the challenge.",
        ],
        "quotesLegendary": [
            "Deep roots survive storms.",
            "Endurance is quiet strength.",
            "Time humbles everybody.",
        ],
        "quotesTeamUp": [
            "Community keeps people strong.",
            "Help each other along.",
            "Steady together.",
        ],
    },
    "nova_27": {
        "quotesModified": [
            "Wildcard variation selected.",
            "Chaos changes form.",
            "Rules are flexible for me.",
        ],
        "quotesClutch": [
            "The timeline almost collapsed.",
            "Chaos nearly consumed me.",
            "A near miss makes it exciting.",
        ],
        "quotesStartMatch": [
            "The wildcard arrives.",
            "Chaos enters the arena.",
            "Expect the unexpected.",
        ],
        "quotesLegendary": [
            "Probability bends around me.",
            "The anomaly awakens.",
            "Chaos remembers my name.",
        ],
        "quotesTeamUp": [
            "Chaos favors alliances.",
            "Unexpected teamwork.",
            "Together, reality bends.",
        ],
    },
}

root = Path(__file__).resolve().parent.parent
path = root / "assets" / "data" / "npc_profiles.json"
data = json.loads(path.read_text(encoding="utf-8"))
for p in data["profiles"]:
    extra = {**QUOTES.get(p["id"], {}), **RESPECT_PAIN_QUOTES.get(p["id"], {})}
    p.update(extra)
data["version"] = 4
path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print("Updated", path)
print("To append new full profiles, use: python tool/merge_new_profiles.py")
