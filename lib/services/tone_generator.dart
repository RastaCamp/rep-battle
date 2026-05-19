import 'dart:math';
import 'dart:typed_data';

class ToneGenerator {
  static Uint8List wavBytes({
    required double frequency,
    required int durationMs,
    double volume = 0.35,
    int sampleRate = 22050,
  }) {
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final dataSize = sampleCount * 2;
    final buffer = BytesBuilder();
    void writeString(String s) => buffer.add(s.codeUnits);
    void writeInt32(int v) {
      buffer.add([(v >> 0) & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
    }
    void writeInt16(int v) {
      buffer.add([(v >> 0) & 0xff, (v >> 8) & 0xff]);
    }

    writeString('RIFF');
    writeInt32(36 + dataSize);
    writeString('WAVE');
    writeString('fmt ');
    writeInt32(16);
    writeInt16(1);
    writeInt16(1);
    writeInt32(sampleRate);
    writeInt32(sampleRate * 2);
    writeInt16(2);
    writeInt16(16);
    writeString('data');
    writeInt32(dataSize);

    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      var env = 1.0;
      final attack = sampleRate * 0.01;
      final release = sampleRate * 0.05;
      if (i < attack) env = i / attack;
      if (i > sampleCount - release) env = (sampleCount - i) / release;
      final sample =
          sin(2 * pi * frequency * t) * volume * env * 32767;
      final v = sample.clamp(-32767, 32767).round();
      writeInt16(v);
    }
    return buffer.toBytes();
  }
}
