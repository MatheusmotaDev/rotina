class NotificationTime {
  const NotificationTime();

  DateTime nextDaily(DateTime now, int minutes) {
    var date = DateTime(
      now.year,
      now.month,
      now.day,
      minutes ~/ 60,
      minutes % 60,
    );
    if (!date.isAfter(now)) date = date.add(const Duration(days: 1));
    return date;
  }
}
