import 'dart:convert';

import 'package:agri_helper/appconstant.dart';
import 'package:agri_helper/widget/market_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

class ListMarket extends ConsumerStatefulWidget {
  ListMarket({super.key, this.lat, this.lan});
  final lat, lan;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _ListMarketState();
  }
}

class _ListMarketState extends ConsumerState<ListMarket> {
  var isload = true;
  var markets;

  void loadData() async {
    var headers = {
      'X-Goog-FieldMask':
          'places.displayName.text,places.nationalPhoneNumber,places.googleMapsUri,places.location',

      'X-Goog-Api-Key': apiGoogleMapKey,

      'Content-Type': 'application/json'
    };
    var data = json.encode({
      "includedTypes": ["supermarket", "market"],
      "rankPreference": "DISTANCE",
      "maxResultCount": 10,
      "locationRestriction": {
        "circle": {
          "center": {"latitude": widget.lat, "longitude": widget.lan},
          "radius": 20000
        }
      }
    });
    var dio = Dio();
    var response = await dio.request(
      'https://places.googleapis.com/v1/places:searchNearby',
      options: Options(
        method: 'POST',
        headers: headers,
      ),
      data: data,
    );

    if (response.statusCode == 200) {
      setState(() {
        markets = response.data;
      });
    }
  }

  double getDistance(lat1, lon1) {
    final lat2 = widget.lat;
    final lon2 = widget.lan;
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    List data = (markets == null)
        ? []
        : ((markets["places"]) == null ? [] : markets["places"]);
    return Expanded(
        child: SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(top: 5),
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ...data.map((item) {
              return MarketPlaces(
                  name: item["displayName"]["text"],
                  link: item["googleMapsUri"],
                  phone: item["nationalPhoneNumber"],
                  distance: getDistance(item["location"]["latitude"],
                      item["location"]["longitude"]));
            })
          ],
        ),
      ),
    ));
  }
}
