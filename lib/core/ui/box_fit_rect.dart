import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pixel rect where [BoxFit.contain] would paint an image inside [container].
Rect boxFitContainRect({
  required Size imageSize,
  required Size containerSize,
  Alignment alignment = Alignment.center,
}) {
  if (imageSize.width <= 0 || imageSize.height <= 0) {
    return Offset.zero & containerSize;
  }
  final scale = math.min(
    containerSize.width / imageSize.width,
    containerSize.height / imageSize.height,
  );
  final w = imageSize.width * scale;
  final h = imageSize.height * scale;
  final dx = (containerSize.width - w) * ((alignment.x + 1) / 2);
  final dy = (containerSize.height - h) * ((alignment.y + 1) / 2);
  return Rect.fromLTWH(dx, dy, w, h);
}

/// Map normalized (0–1) coords on the image into container coordinates.
Offset mapNormalizedOnImage({
  required double nx,
  required double ny,
  required Size imageSize,
  required Size containerSize,
  Alignment alignment = Alignment.center,
}) {
  final rect = boxFitContainRect(
    imageSize: imageSize,
    containerSize: containerSize,
    alignment: alignment,
  );
  return Offset(rect.left + nx * rect.width, rect.top + ny * rect.height);
}
