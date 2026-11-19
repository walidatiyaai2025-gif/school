/// Platform-independent scan geometry: no Android OpenCV/JNI dependency.
typedef ScanPoint = ({double x, double y});

enum ScanFilter { none, enhance, magicColor, grayscale, blackWhite, sharpen }

class DocumentCorners {
  const DocumentCorners({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  final ScanPoint topLeft, topRight, bottomRight, bottomLeft;

  List<ScanPoint> toList() => [topLeft, topRight, bottomRight, bottomLeft];

  double get area {
    final p = toList();
    var sum = 0.0;
    for (var i = 0; i < 4; i++) {
      final a = p[i], b = p[(i + 1) % 4];
      sum += a.x * b.y - b.x * a.y;
    }
    return sum.abs() / 2;
  }

  bool get isConvex {
    final p = toList();
    if (p.any((v) => !v.x.isFinite || !v.y.isFinite ||
        v.x < 0 || v.x > 1 || v.y < 0 || v.y > 1)) {
      return false;
    }
    double? sign;
    for (var i = 0; i < 4; i++) {
      final a = p[i], b = p[(i + 1) % 4], c = p[(i + 2) % 4];
      final cross = (b.x - a.x) * (c.y - b.y) -
          (b.y - a.y) * (c.x - b.x);
      if (cross.abs() < 0.000001) return false;
      if (sign != null && cross * sign < 0) return false;
      sign = cross;
    }
    return area >= 0.002;
  }
}
