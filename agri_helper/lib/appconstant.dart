import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const greenBack = Color.fromARGB(255, 170, 227, 160);
const buttonBack = Color.fromARGB(255, 4, 120, 87);
final urlAPI = Uri.http("35.247.138.127", "api-ai/predict");

final background = Color.fromARGB(255, 245, 245, 245);
final apilua = 'http://35.247.138.127/api-ai/predict';
final apitintuc = 'http://35.247.138.127/api-ai/tintucnongnghiep';
final apiGoogleMapKey = dotenv.env["googlemap_api_key"];
