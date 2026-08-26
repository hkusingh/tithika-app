enum EclipseKind { solar, lunar }

/// Solar: partial/annular/total (annularTotal — hybrid — reported as total).
/// Lunar: penumbral/partial/total.
enum EclipseSubtype { partial, annular, total, penumbral }

/// A single solar or lunar eclipse, with visibility and contact times
/// evaluated for a specific observer location.
class EclipseInfo {
  final EclipseKind kind;
  final EclipseSubtype subtype;

  /// UTC time of maximum eclipse.
  final DateTime maxUtc;

  /// UTC time the eclipse begins (first contact) at the observer location.
  final DateTime startUtc;

  /// UTC time the eclipse ends (last contact) at the observer location.
  final DateTime endUtc;

  /// True if any phase of the eclipse is visible (sun/moon above horizon)
  /// at the observer location.
  final bool visible;

  /// UTC time Sutak Kaal begins — 12h before [startUtc] for solar, 9h for
  /// lunar. Null when the eclipse is not visible at the location, since
  /// Sutak is only observed for eclipses one can actually witness.
  final DateTime? sutakStartUtc;

  /// Calendar date (in the observer's local timezone) this eclipse is
  /// keyed to for calendar display — the local date of [maxUtc].
  final DateTime localDate;

  const EclipseInfo({
    required this.kind,
    required this.subtype,
    required this.maxUtc,
    required this.startUtc,
    required this.endUtc,
    required this.visible,
    required this.sutakStartUtc,
    required this.localDate,
  });
}
