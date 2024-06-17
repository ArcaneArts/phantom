enum EventPriority {
  /// Lowest priority, fires first
  low,

  /// Normal priority, default priority
  normal,

  /// Highest priority, fires last, can cancel (final say)
  high,
}
