import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agri_helper/components/weather_item.dart';
import 'package:agri_helper/constants.dart';
import 'package:agri_helper/ui/detail_page.dart';
import 'package:agri_helper/appconstant.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _cityController = TextEditingController();
  final Constants _constants = Constants();
  static String API_KEY = apiWeatherKey ?? '';

  String location = '';
  String weatherIcon = 'heavycloudy.png';
  int temperature = 0;
  int windSpeed = 0;
  int humidity = 0;
  int cloud = 0;
  String currentDate = '';
  String currentWeatherStatus = '';

  List hourlyWeatherForecast = [];
  List dailyWeatherForecast = [];

  String searchWeatherAPI = "https://api.weatherapi.com/v1/forecast.json?key="
      + API_KEY + "&days=7&q=";

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng bật dịch vụ vị trí')),
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn')),
      );
      return false;
    }

    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      setState(() {
        location = 'London';
      });
      fetchWeatherData(location);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      fetchWeatherData('${position.latitude},${position.longitude}');
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        location = 'London';
      });
      fetchWeatherData(location);
    }
  }

  void fetchWeatherData(String searchText) async {
    try {
      final res = await http.get(Uri.parse(searchWeatherAPI + searchText));
      final weatherData =
      Map<String, dynamic>.from(json.decode(res.body) ?? {});
      final loc = weatherData["location"];
      final cur = weatherData["current"];

      setState(() {
        location = getShortLocationName(loc["name"]);

        final parsedDate = DateTime.parse(loc["localtime"].substring(0, 10));
        currentDate = DateFormat('MMMMEEEEd').format(parsedDate);

        currentWeatherStatus = cur["condition"]["text"];
        weatherIcon = currentWeatherStatus.replaceAll(' ', '').toLowerCase() + ".png";
        temperature = cur["temp_c"].toInt();
        windSpeed = cur["wind_kph"].toInt();
        humidity = cur["humidity"].toInt();
        cloud = cur["cloud"].toInt();

        dailyWeatherForecast = weatherData["forecast"]["forecastday"];
        hourlyWeatherForecast = dailyWeatherForecast[0]["hour"];
      });
    } catch (e) {
      // nếu cần có thể show lỗi
    }
  }

  static String getShortLocationName(String s) {
    final parts = s.split(' ');
    if (parts.length > 1) {
      return '${parts[0]} ${parts[1]}';
    }
    return parts.isNotEmpty ? parts[0] : '';
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 70, left: 10, right: 10, bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildCurrentWeatherCard(size),
            const SizedBox(height: 20),
            _buildHourlyForecastSection(size),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherCard(Size size) {
    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.65),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: _constants.linearGradientBlue,
        boxShadow: [
          BoxShadow(
            color: _constants.primaryColor.withOpacity(.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLocationRow(),
          SizedBox(height: 160, child: Image.asset("assets/$weatherIcon")),
          _buildTemperatureDisplay(),
          Text(currentWeatherStatus,
              style: const TextStyle(color: Colors.white70, fontSize: 20)),
          Text(currentDate,
              style: const TextStyle(color: Colors.white70)),
          const Divider(color: Colors.white70),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              WeatherItem(
                  value: windSpeed.toInt(),
                  unit: 'km/h',
                  imageUrl: 'assets/windspeed.png'),
              WeatherItem(
                  value: humidity.toInt(),
                  unit: '%',
                  imageUrl: 'assets/humidity.png'),
              WeatherItem(
                  value: cloud.toInt(),
                  unit: '%',
                  imageUrl: 'assets/cloud.png'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset("assets/menu.png", width: 40, height: 40),
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white),
            const SizedBox(width: 4),
            Text(location,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              onPressed: () => _showCitySearchSheet(),
            ),
          ],
        ),
        // nếu cần avatar: Image.asset("assets/profile.png", width:40, height:40)
      ],
    );
  }

  void _showCitySearchSheet() {
    showMaterialModalBottomSheet(
      context: context,
      expand: false,
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: SingleChildScrollView(
            controller: ModalScrollController.of(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 70,
                    child: Divider(
                      thickness: 3.5,
                      color: _constants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _cityController,
                    autofocus: true,
                    onChanged: (text) => fetchWeatherData(text),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.search, color: _constants.primaryColor),
                      suffixIcon: GestureDetector(
                        onTap: () => _cityController.clear(),
                        child: Icon(Icons.close, color: _constants.primaryColor),
                      ),
                      hintText: 'Search city e.g. London',
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: _constants.primaryColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTemperatureDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$temperature',
          style: TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            foreground: Paint()..shader = _constants.shader,
          ),
        ),
        Text(
          'o',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            foreground: Paint()..shader = _constants.shader,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecastSection(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Today',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DetailPage(dailyForecastWeather: dailyWeatherForecast),
                ),
              ),
              child: Text('Forecasts',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: _constants.primaryColor)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.builder(
            itemCount: hourlyWeatherForecast.length,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (ctx, index) {
              final nowHour = DateFormat('HH').format(DateTime.now());
              final item = hourlyWeatherForecast[index];
              final forecastTime = item["time"].substring(11, 16);
              final forecastHour = item["time"].substring(11, 13);
              final iconName = item["condition"]["text"]
                  .toString()
                  .replaceAll(' ', '')
                  .toLowerCase() + ".png";
              final temp = item["temp_c"].round().toString();

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                margin: const EdgeInsets.only(right: 20),
                width: 65,
                decoration: BoxDecoration(
                  color: nowHour == forecastHour
                      ? Colors.white
                      : _constants.primaryColor,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 1),
                      blurRadius: 5,
                      color: _constants.primaryColor.withOpacity(.2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(forecastTime,
                        style: TextStyle(
                            fontSize: 17,
                            color: _constants.greyColor,
                            fontWeight: FontWeight.w500)),
                    Image.asset('assets/$iconName', width: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(temp,
                            style: TextStyle(
                                color: _constants.greyColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w600)),
                        Text('o',
                            style: TextStyle(
                              color: _constants.greyColor,
                              fontSize: 17,
                              fontFeatures: const [FontFeature.enable('sups')],
                            )),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
