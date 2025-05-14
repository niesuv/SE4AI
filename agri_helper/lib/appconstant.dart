import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const greenBack = Color.fromARGB(255, 170, 227, 160);
const buttonBack = Color.fromARGB(255, 4, 120, 87);
final urlAPI = Uri.http("35.247.138.127", "api-ai/predict");

final background = Color.fromARGB(255, 245, 245, 245);
final apilua = 'https://plant-disease-api-service-326088373215.asia-southeast1.run.app/predict/';
final apitintuc = 'https://avydyue6uf3nv6jfcpuysg2sjy0tykue.lambda-url.ap-southeast-1.on.aws/';
final apiGoogleMapKey = dotenv.env["googlemap_api_key"];
