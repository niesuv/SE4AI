import 'dart:convert';

import 'package:agri_helper/provider/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _WeatherScreenState();
  }
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  List<dynamic> weatherData = [];

  void loadData() async {
    var dio = Dio();
    print(
        'http://35.247.138.127/api/weather/forecast/location?latlng=${ref.read(UserProvider)["lat"]},${ref.read(UserProvider)["lan"]}');
    var response = await dio.request(
      'http://35.247.138.127/api/weather/forecast/location?latlng=${ref.read(UserProvider)["lan"]},${ref.read(UserProvider)["lat"]}',
      options: Options(
        method: 'GET',
      ),
    );
    setState(() {
      print(response.data);
      weatherData = response.data["data"]["list"] == null
          ? []
          : response.data["data"]["list"];
      print(weatherData);
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...weatherData.map((item) {
            final date = item["dt_txt"].toString().substring(0, 10);
            final time = item["dt_txt"].toString().substring(10);
            return Container(
              width: 175,
              height: null,
              margin: EdgeInsets.only(top: 20, right: 5),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Color.fromARGB(255, 100, 142, 205),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    date,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                  ),
                  Text(
                    time,
                    style:
                        TextStyle(fontWeight: FontWeight.normal, fontSize: 23),
                  ),
                  Container(
                      margin: EdgeInsets.only(top: 50, bottom: 50),
                      child:
                          _getWeatherIcon(item["weather"][0]["icon"], 100.0)),
                  Text(
                    "Nhiệt độ: ${item["main"]["temp"]}",
                    softWrap: true,
                    style:
                        TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "${item["weather"][0]["description"].toString().toUpperCase()}",
                    style:
                        TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
                    softWrap: true,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    " Độ ẩm ${item["main"]["humidity"]} %",
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.normal, fontSize: 20),
                  ),
                ],
              ),
            );
          })
        ],
      ),
    ));
  }

  Icon _getWeatherIcon(String iconCode, size) {
    switch (iconCode) {
      case '01d':
        return Icon(Icons.wb_sunny, size: size, color: Colors.white);
      case '01n':
        return Icon(Icons.nightlight_round, size: size, color: Colors.white);
      case '02d':
      case '02n':
        return Icon(Icons.cloud, size: size, color: Colors.white);
      case '03d':
      case '03n':
        return Icon(Icons.cloud_queue, size: size, color: Colors.white);
      case '04d':
      case '04n':
        return Icon(Icons.cloud_off, size: size, color: Colors.white);
      case '09d':
      case '09n':
        return Icon(Icons.waves, size: size, color: Colors.white);
      case '10d':
      case '10n':
        return Icon(Icons.beach_access, size: size, color: Colors.white);
      case '11d':
      case '11n':
        return Icon(Icons.flash_on, size: size, color: Colors.white);
      case '13d':
      case '13n':
        return Icon(Icons.ac_unit, size: size, color: Colors.white);
      case '50d':
      case '50n':
        return Icon(Icons.cloud_circle, size: size, color: Colors.white);
      default:
        return Icon(Icons.cloud, size: size, color: Colors.white);
    }
  }
}
