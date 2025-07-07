import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/sections/button_section.dart';
import 'package:myapp/sections/image_section.dart';
import 'package:myapp/sections/text_section.dart';
import 'package:myapp/sections/title_section.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'firebase_options.dart';

//void main() => runApp(const MyApp());

void main() async {
  //To avoid "Binding has not yet been initialized"
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

final GenerativeModel model = FirebaseAI.googleAI().generativeModel(
  model: 'gemini-2.5-flash',
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    generateTextWithGemini();

    const String appTitle = 'Flutter layout demo';
    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(title: const Text(appTitle)),
        body: SingleChildScrollView(
          child: Column(
            children: [
              ImageSection(image: 'images/lake.jpg'),
              TitleSection(
                name: 'Oeschinen Lake Campground',
                location: 'Kandersteg, Switzerland',
              ),
              ButtonSection(),

              FutureBuilder(
                future: generateTextWithGeminiFromImageWeb(),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<String?> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return TextSection(description: 'Error: ${snapshot.error}');
                  } else if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsetsGeometry.all(8),
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasData) {
                    return TextSection(description: snapshot.data ?? 'Foo');
                  } else {
                    return Container();
                  }
                },
              ),

              FutureBuilder(
                future: generateTextWithGemini(),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<String?> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return TextSection(description: 'Error');
                  } else if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsetsGeometry.all(8),
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasData) {
                    return TextSection(description: snapshot.data ?? 'Foo');
                  } else {
                    return Container();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> generateTextWithGemini() async {
  final List<Content> prompt = [
    Content.text('Write a story abouta a magic Lake'),
  ];

  final GenerateContentResponse response = await model.generateContent(prompt);

  return response.text;
}

Future<String?> generateTextWithGeminiFromImage() async {
  // Provide a text prompt to include with the image
  final prompt = TextPart("What's in the picture?");
  // Prepare images for input
  final Uint8List image = await File('images/lake.jpg').readAsBytes();
  final imagePart = InlineDataPart('image/jpeg', image);

  // To generate text output, call generateContent with the text and image
  final response = await model.generateContent([
    Content.multi([prompt, imagePart]),
  ]);

  return response.text;
}

Future<String?> generateTextWithGeminiFromImageWeb() async {
  final TextPart prompt = TextPart("What's in the picture?");
  // dart:io not supported on the web
  final Uint8List imageBytes = await rootBundle
      .load('images/lake.jpg')
      .then((byteData) => byteData.buffer.asUint8List());
  final InlineDataPart imagePart = InlineDataPart('image/jpeg', imageBytes);

  final GenerateContentResponse response = await model.generateContent([
    Content.multi([prompt, imagePart]),
  ]);

  return response.text;
}
