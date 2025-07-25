
  AppNotification({
    required this.id,
    required this.title,
    required this.message,


  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
