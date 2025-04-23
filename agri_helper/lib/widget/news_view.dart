import 'dart:convert';

import 'package:agri_helper/appconstant.dart';
import 'package:agri_helper/provider/user_provider.dart';
import 'package:agri_helper/widget/news_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewsView extends ConsumerStatefulWidget {
  NewsView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _NewsViewState();
  }
}

class _NewsViewState extends ConsumerState<NewsView> {
  var data;

  @override
  void initState() {
    super.initState();
    var str = ref.read(UserProvider)["news"];
    if (str == "") {
      var dio = Dio();
      var response = dio.request(
        apitintuc,
        options: Options(
          method: 'GET',
        ),
      );
      response.then((value) {
        if (value.statusCode == 200) {
          final res = value.data["data"];
          setState(() {
            data = res;
          });
          ref.read(UserProvider.notifier).setNews(json.encode((res)));
        }
      });
    } else {
      data = json.decode(str!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data == null
              ? []
              : [
                  ...data!.map((item) {
                    return NewsThumbnail(
                        title: item["title"],
                        imageUrl: item["image"],
                        description: item["description"],
                        link: item["link"]);
                  })
                ],
        ),
      ),
    );
  }
}
