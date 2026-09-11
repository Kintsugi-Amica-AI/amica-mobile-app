class DateTimeUtils {
  const DateTimeUtils._();

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${_two(dateTime.month)}-${_two(dateTime.day)} '
        '${_two(dateTime.hour)}:${_two(dateTime.minute)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
