import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

// main()를 async로 바꿔서 .env를 먼저 로드
Future<void> main() async {
  // .env 파일에서 환경변수 로드
  await dotenv.load(fileName: '.env');

  // 로드된 값은 dotenv.env['KEY_NAME']으로 접근 가능
  runApp(const MyApp());
}