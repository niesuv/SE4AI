import 'package:riverpod/riverpod.dart';

class UserNotifier extends StateNotifier<Map<String, dynamic>> {
  UserNotifier()
      : super({
          "username": "",
          "phone": "",
          "news": "",
          "lat": 0,
          "lan": 0,
          "add": ""
        });

  void setUsername(String name) {
    state["username"] = name;
  }

  void setphone(String phoneNumber) {
    state["phone"] = phoneNumber;
  }

  void setNews(String news) {
    state["news"] = news;
  }

  void setAdd(add) {
    state["add"] = add;
  }

  void setloc(lat, lan) {
    state["lat"] = lat;
    state["lan"] = lan;
  }

  void clear() {
    state["username"] = "";
    state["phone"] = "";
    state["news"] = "";
  }
}

final UserProvider = StateNotifierProvider<UserNotifier, Map<String, dynamic>>(
    (ref) => UserNotifier());
