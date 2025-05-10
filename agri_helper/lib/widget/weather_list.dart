import 'package:agri_helper/appconstant.dart';
import 'package:intl/intl.dart';
import 'package:agri_helper/provider/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _WeatherScreenState();
  }
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  List<dynamic> weatherData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
    });

    final dio = Dio();
    final lat = ref.read(UserProvider)["lat"];
    final lon = ref.read(UserProvider)["lan"];
    final apiKey = apiGoogleMapKey;
    final url = 'https://weather.googleapis.com/v1/forecast/days:lookup'
        '?key=$apiKey&location.latitude=$lat&location.longitude=$lon&days=5';

    try {
      final resp = await dio.get(url);
      final list = resp.data["forecastDays"] as List<dynamic>?;
      setState(() {
        weatherData = list ?? [];
      });
    } catch (e) {
      print('Error fetching weather: $e');
      setState(() {
        weatherData = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : weatherData.isEmpty
              ? const Center(child: Text('Không có dữ liệu thời tiết'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: weatherData.map((item) {
                      // 1. Lấy displayDate
                      final displayDate = item["displayDate"] as Map<String, dynamic>;
                      final year = displayDate["year"];
                      final month = displayDate["month"].toString().padLeft(2, '0');
                      final day = displayDate["day"].toString().padLeft(2, '0');
                      final date = '$year-$month-$day';

                      // 2. Lấy phần daytimeForecast
                      final dayFc = item["daytimeForecast"] as Map<String, dynamic>;

                      // 3. Lấy loại icon và mô tả
                      final cond = dayFc["weatherCondition"] as Map<String, dynamic>;
                      final iconType = (cond["type"] as String).toUpperCase();
                      final desc = cond["description"]["text"] as String;

                      // 4. Nhiệt độ (lấy giá trị maxTemperature)
                      final maxTemp = item["maxTemperature"]["degrees"] as num;
                      final temp = maxTemp.toDouble();

                      // 5. Độ ẩm
                      final humidity = dayFc["relativeHumidity"] as int;

                      return Container(
                        width: 175,
                        margin: const EdgeInsets.only(top: 20, right: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color.fromARGB(255, 100, 142, 205),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(date,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 25)),
                            const SizedBox(height: 20),
                            _getWeatherIcon(iconType, 80.0),
                            const SizedBox(height: 20),
                            Text("Nhiệt độ: ${temp.toStringAsFixed(1)}°C",
                                style: const TextStyle(fontSize: 18),
                                textAlign: TextAlign.center),
                            Text(desc.toUpperCase(),
                                style: const TextStyle(fontSize: 18),
                                textAlign: TextAlign.center),
                            Text("Độ ẩm: $humidity%",
                                style: const TextStyle(fontSize: 18),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }

  Icon _getWeatherIcon(String iconCode, double size) {
    switch (iconCode) {
      case 'THUNDERSTORM':
      case 'SCATTERED_THUNDERSTORMS':
      case 'HEAVY_THUNDERSTORM':
        return Icon(Icons.flash_on, size: size, color: Colors.white);
      case 'MOSTLY_CLOUDY':
        return Icon(Icons.cloud_queue, size: size, color: Colors.white);
      // Bạn có thể tiếp tục bổ sung các case khác nếu cần
      case 'CLEAR_DAY':
      case 'SUNNY':
        return Icon(Icons.wb_sunny, size: size, color: Colors.white);
      default:
        return Icon(Icons.cloud, size: size, color: Colors.white);
    }
  }
}

Icon _getWeatherIcon(String iconType, double size) {
  switch (iconType) {
    // Trời quang đãng ban ngày / ban đêm
    case 'CLEAR_DAY':
      return Icon(Icons.wb_sunny, size: size, color: Colors.white);
    case 'CLEAR_NIGHT':
      return Icon(Icons.nightlight_round, size: size, color: Colors.white);

    // Trời ít mây / mây rải rác
    case 'PARTLY_CLOUDY_DAY':
    case 'SCATTERED_CLOUDS':
      return Icon(Icons.wb_cloudy, size: size, color: Colors.white);
    case 'PARTLY_CLOUDY_NIGHT':
    case 'SCATTERED_CLOUDS_NIGHT':
      return Icon(Icons.cloud, size: size, color: Colors.white);

    // Trời nhiều mây / mưa rào ban đêm
    case 'MOSTLY_CLOUDY':
    case 'BROKEN_CLOUDS':
      return Icon(Icons.cloud_queue, size: size, color: Colors.white);
    case 'MOSTLY_CLOUDY_NIGHT':
      return Icon(Icons.cloud_off, size: size, color: Colors.white);

    // Sấm sét, giông bão
    case 'THUNDERSTORM':
    case 'SCATTERED_THUNDERSTORMS':
    case 'HEAVY_THUNDERSTORM':
      return Icon(Icons.flash_on, size: size, color: Colors.white);

    // Mưa và mưa nhẹ
    case 'RAIN':
    case 'LIGHT_RAIN':
    case 'SHOWERS':
      return Icon(Icons.grain, size: size, color: Colors.white);

    // Tuyết, mưa đá
    case 'SNOW':
    case 'SLEET':
      return Icon(Icons.ac_unit, size: size, color: Colors.white);

    // Sương mù, khói, mù
    case 'FOG':
    case 'HAZE':
    case 'MIST':
      return Icon(Icons.cloud, size: size, color: Colors.white);

    // Gió
    case 'WIND':
      return Icon(Icons.air, size: size, color: Colors.white);

    // Mặc định nếu không khớp type nào ở trên
    default:
      return Icon(Icons.cloud, size: size, color: Colors.white);
  }
}
