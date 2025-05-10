import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketPlaces extends StatelessWidget {
  String? name;
  double distance;
  String? link;
  String? phone;
  void _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  MarketPlaces(
      {super.key,
      required this.name,
      required this.distance,
      required this.link,
      required this.phone});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: InkWell(
        onTap: () {
          _launchUrl(link == null ? "" : link!);
        },
        child: Card(
          child: Container(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name == null ? "" : name!.trim(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  "Số điện thoại: ${phone == null ? "" : phone!.trim()}",
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  "Cách bạn ${distance.toStringAsFixed(0)} km",
                  style: TextStyle(fontSize: 20),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
