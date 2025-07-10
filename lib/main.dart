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
                future: generateImageWithImagen(),
                builder: (
                  BuildContext context,
                  AsyncSnapshot<ImagenInlineImage?> snapshot,
                ) {
                  if (snapshot.hasError) {
                    return TextSection(description: 'Error: ${snapshot.error}');
                  } else if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsetsGeometry.all(8),
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasData) {
                    final Uint8List imageBytes =
                        snapshot.data!.bytesBase64Encoded;
                    return Image.memory(imageBytes);
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

//Official doc, doesn't compile at the moment
// Future<Unit8List?> generateImagesWithGeminiDoc() async {
//   // Initialize the Gemini Developer API backend service
//   // Create a `GenerativeModel` instance with a Gemini model that supports image output
//   final model = FirebaseAI.googleAI().generativeModel(
//     model: 'gemini-2.0-flash-preview-image-generation',
//     // Configure the model to respond with text and images
//     generationConfig: GenerationConfig(
//       responseModalities: [ResponseModality.text, ResponseModality.image],
//     ),
//   );

//   // Provide a text prompt instructing the model to generate an image
//   final prompt = [
//     Content.text(
//       'Generate an image of the Eiffel Tower with fireworks in the background.',
//     ),
//   ];

//   // To generate an image, call `generateContent` with the text input
//   final response = await model.generateContent(prompt);
//   if (response.inlineDataParts.isNotEmpty) {
//     final imageBytes = response.inlineDataParts[0].bytes;
//     // Process the image
//   } else {
//     // Handle the case where no images were generated
//     print('Error: No images were generated.');
//   }
// }

//Adapted by myself
Future<Uint8List?> generateImagesWithGemini() async {
  // Initialize the Gemini Developer API backend service
  // Create a `GenerativeModel` instance with a Gemini model that supports image output
  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.0-flash-preview-image-generation',
    // Configure the model to respond with text and images
    generationConfig: GenerationConfig(
      responseModalities: [ResponseModalities.text, ResponseModalities.image],
    ),
  );

  // Provide a text prompt instructing the model to generate an image
  final prompt = [
    Content.text(
      'Generate an image of the Eiffel Tower with fireworks in the background.',
    ),
  ];

  // To generate an image, call `generateContent` with the text input
  final response = await model.generateContent(prompt);
  if (response.inlineDataParts.isNotEmpty) {
    //final imageBytes = response.inlineDataParts[0].bytes;
    final imageBytes = response.inlineDataParts.first.bytes;
    return imageBytes;
    // Process the image
  } else {
    // Handle the case where no images were generated
    return null;
  }
}

Future<ImagenInlineImage?> generateImageWithImagen() async {
  // Initialize the Gemini Developer API backend service
  final ai = FirebaseAI.googleAI();

  // Create an `ImagenModel` instance with an Imagen model that supports your use case
  final model2 = ai.imagenModel(model: 'imagen-3.0-generate-002');

  // Provide an image generation prompt
  const prompt = 'An astronaut riding a horse.';

  // To generate an image, call `generateImages` with the text prompt
  final response = await model2.generateImages(prompt);

  if (response.images.isNotEmpty) {
    final image = response.images[0];
    return image;
    // Process the image
  } else {
    // Handle the case where no images were generated
    return null;
  }
}
