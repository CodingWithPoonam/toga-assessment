/// Lifecycle states of a durable submission outbox record
enum OutboxStatus {
  pending('pending'),
  inFlight('in_flight'),
  completed('completed'),
  blocked('blocked'),
  retryScheduled('retry_scheduled');

  final String value;
  const OutboxStatus(this.value);

  static OutboxStatus fromString(String val) {
    return OutboxStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => OutboxStatus.pending,
    );
  }
}

/// Diagnostic failure category distinguishing transient and permanent errors
enum FailureCategory {
  timeout('timeout'),
  network('network'),
  auth('auth'),
  staleContent('stale_content'),
  validation('validation'),
  serverError('server_error');

  final String value;
  const FailureCategory(this.value);

  bool get isTransient =>
      this == FailureCategory.timeout ||
      this == FailureCategory.network ||
      this == FailureCategory.serverError;

  static FailureCategory? fromString(String? val) {
    if (val == null) return null;
    return FailureCategory.values.firstWhere(
      (e) => e.value == val,
      orElse: () => FailureCategory.serverError,
    );
  }
}

/// Draft lifecycle statuses in SQLite replacing old boolean isSubmitted
enum DraftStatus {
  inProgress('in_progress'),
  staged('staged'),
  acknowledged('acknowledged'),
  blocked('blocked');

  final String value;
  const DraftStatus(this.value);

  static DraftStatus fromString(String val) {
    return DraftStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => DraftStatus.inProgress,
    );
  }
}
