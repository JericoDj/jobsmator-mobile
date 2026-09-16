/// Voice & copy (guide §08): talk like a sharp friend who works in recruiting.
/// Second person, present tense, specific numbers. Never apologise, never hype.
abstract final class JmCopy {
  /// Engine/API error code → what the user sees.
  static String forError(String? code, {DateTime? retryAt}) => switch (code) {
    'invalid_request' => 'Pick at least one job site and one interest to search.',
    'resume_unreadable' =>
      "We couldn't read that resume. Try a text-based PDF instead of a scan, or paste a different link.",
    'engine_unavailable' => 'Job sites are slow right now. Try again in a minute.',
    'too_many_runs' =>
      "You've used 5 searches this hour."
          '${retryAt == null ? '' : ' Next one at ${_hhmm(retryAt)}.'}',
    'run_in_progress' => 'A search is already running — hang on.',
    'network' => 'Check your connection and try again.',
    _ => 'Something went wrong. Try again.',
  };

  static String resultsHeadline(int strong, String? interest) {
    final what = interest == null || interest.isEmpty ? '' : ' for $interest';
    return switch (strong) {
      0 => 'No strong matches yet',
      1 => '1 strong match$what',
      _ => '$strong strong matches$what',
    };
  }

  static String weakerLink(int n) => 'Show $n weaker ${n == 1 ? 'match' : 'matches'}';

  static String plural(int n, String one, [String? many]) => n == 1 ? '$n $one' : '$n ${many ?? '${one}s'}';

  /// "2 days ago", "just now" — meta line on the job card.
  static String relative(DateTime? when, {DateTime? now}) {
    if (when == null) return '';
    final d = (now ?? DateTime.now()).difference(when);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${plural(d.inMinutes, 'minute')} ago';
    if (d.inDays < 1) return '${plural(d.inHours, 'hour')} ago';
    if (d.inDays < 7) return '${plural(d.inDays, 'day')} ago';
    if (d.inDays < 30) return '${plural(d.inDays ~/ 7, 'week')} ago';
    return '${plural(d.inDays ~/ 30, 'month')} ago';
  }

  /// "in 2 hours", "tomorrow", "in 6 days".
  static String relativeFuture(DateTime when, {DateTime? now}) {
    final d = when.difference(now ?? DateTime.now());
    if (d.inMinutes < 1) return 'now';
    if (d.inHours < 1) return 'in ${plural(d.inMinutes, 'minute')}';
    if (d.inHours < 24) return 'in ${plural(d.inHours, 'hour')}';
    if (d.inDays == 1) return 'tomorrow';
    return 'in ${plural(d.inDays, 'day')}';
  }

  /// "16 Oct" / "16 Oct 2027" when it's not this year.
  static String dateLabel(DateTime d, {DateTime? now}) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final year = (now ?? DateTime.now()).year == d.year ? '' : ' ${d.year}';
    return '${d.day} ${months[d.month - 1]}$year';
  }

  static String _hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
