import 'package:agri_helper/appconstant.dart';
import 'package:agri_helper/provider/user_provider.dart';
import 'package:agri_helper/widget/weather_list.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class WeatherView extends ConsumerStatefulWidget {
  const WeatherView({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _WeatherViewState();
  }
}

class _WeatherViewState extends ConsumerState<WeatherView> {
  String currentLoc = '';
  bool isLoad = true;

  @override
  void initState() {
    super.initState();
    currentLoc = ref.read(UserProvider)["add"] ?? '';
    if (currentLoc.isEmpty) {
      _getLocate();
    } else {
      isLoad = false;
    }
  }

  Future<void> _loadLoc() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      print("__________________________________\n");
      print(pos);
      ref.read(UserProvider.notifier).setloc(pos.latitude, pos.longitude);

      final dio = Dio();
      final resp = await dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '${pos.latitude},${pos.longitude}',
          'key': apiGoogleMapKey,
        },
      );

      final addr = resp.data["results"]?[0]?["formatted_address"] as String?;
      setState(() {
        currentLoc = addr ?? 'Không có thông tin';
        ref.read(UserProvider.notifier).setAdd(currentLoc);
        isLoad = false;
      });
    } catch (e) {
      setState(() {
        currentLoc = 'Không có thông tin';
        isLoad = false;
      });
    }
  }

  Future<void> _getLocate() async {
    setState(() {
      isLoad = true;
    });
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always) {
      await _loadLoc();
    } else {
      setState(() {
        currentLoc = 'Không có quyền truy cập.';
        isLoad = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          SizedBox(height: 20),
          Row(
            children: [
              SizedBox(width: 20),
              Icon(Icons.add_location_outlined,
                  color: buttonBack, size: 30),
              SizedBox(width: 15),
              isLoad
                  ? CircularProgressIndicator()
                  : Expanded(
                      child: Text(
                        "Vị trí: $currentLoc",
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
            ],
          ),
          Container(
            height: 35,
            margin: EdgeInsets.only(left: 20, top: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBack,
                  foregroundColor: Colors.white),
              onPressed: _getLocate,
              child: Text("Cập nhật vị trí"),
            ),
          ),
          if (!currentLoc.startsWith("Không") && !isLoad)
            const WeatherScreen()
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
