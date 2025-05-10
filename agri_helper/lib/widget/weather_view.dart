import 'package:agri_helper/appconstant.dart';
import 'package:agri_helper/provider/user_provider.dart';
import 'package:agri_helper/widget/list_market.dart';
import 'package:agri_helper/widget/weather_list.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class WeatherView extends ConsumerStatefulWidget {
  WeatherView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _WeatherViewState();
  }
}

class _WeatherViewState extends ConsumerState<WeatherView> {
  var data;
  var currentplace;
  var currentLoc;
  var isLoad = true;
  void loadLoc() async {
    final loc = await Geolocator.getCurrentPosition().then((value) {
      setState(() {
        print(value);
        print('---------------');
        ref.read(UserProvider.notifier).setloc(value.latitude, value.longitude);
        var dio = Dio();
        var response = dio
            .request(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${value.latitude},${value.longitude}&key=${apiGoogleMapKey}',
          options: Options(
            method: 'GET',
          ),
        )
            .then(
          (val) {
            setState(() {
              currentLoc = val.data["results"][0]["formatted_address"];
              ref.read(UserProvider.notifier).setAdd(currentLoc);
              isLoad = false;
            });
          },
        );
      });
    }).onError((error, stackTrace) {
      setState(() {
        isLoad = false;
        currentLoc = "Không có thông tin";
      });
    });
  }

  void getLocate() async {
    setState(() {
      isLoad = true;
    });
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          currentLoc = "Không có quyền truy cập.";
        });
      } else {
        loadLoc();
      }
    } else if (permission == LocationPermission.deniedForever) {
      setState(() {
        currentLoc = "Không có quyền truy cập.";
      });
    } else {
      loadLoc();
    }
  }

  @override
  void initState() {
    super.initState();
    currentLoc = ref.read(UserProvider)["add"];
    if (currentLoc == "") {
      getLocate();
    } else {
      setState(() {
        isLoad = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 20,
          ),
          Row(
            children: [
              SizedBox(
                width: 20,
              ),
              Icon(
                Icons.add_location_outlined,
                color: buttonBack,
                size: 30,
              ),
              SizedBox(
                width: 15,
              ),
              isLoad
                  ? CircularProgressIndicator()
                  : Expanded(
                      child: Text(
                        "Vị trí: $currentLoc",
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 20),
                      ),
                    )
            ],
          ),
          Container(
            height: 35,
            margin: EdgeInsets.only(left: 20, top: 10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBack, foregroundColor: Colors.white),
              onPressed: getLocate,
              child: Text("Cập nhật vị trí"),
            ),
          ),
          !currentLoc.toString().startsWith("Không") && !isLoad
              ? new WeatherScreen()
              : Center()
        ],
      ),
    );
  }
}
