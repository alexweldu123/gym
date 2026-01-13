import 'dart:io';

class AppConstants {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://164.68.118.20:8080/api';
    }
    return 'http://localhost:8080/api';
  }

  static String get serverUrl {
    if (Platform.isAndroid) {
      return 'http://164.68.118.20:8080';
    }
    return 'http://localhost:8080';
  }
}
