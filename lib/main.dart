import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const BGRemoverPro());
}

class BGRemoverPro extends StatelessWidget {
  const BGRemoverPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BG Remover Pro',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  XFile? selectedImage;
  Uint8List? removedImageBytes;
  bool isLoading = false;

  Future<void> pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = image;
        removedImageBytes = null;
      });
    }
  }

  Future<void> removeBackground() async {
    if (selectedImage == null) return;

    setState(() => isLoading = true);

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("http://127.0.0.1:5000/remove-bg"),
      );

      final imageBytes = await selectedImage!.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          "image",
          imageBytes,
          filename: selectedImage!.name,
        ),
      );

      final response = await request.send();
      final bytes = await response.stream.toBytes();

      if (response.statusCode == 200) {
        setState(() {
          removedImageBytes = bytes;
        });
      } else {
        throw Exception("Background removal failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void downloadImage() {
    if (removedImageBytes == null) return;

    final blob = html.Blob([removedImageBytes!], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute("download", "bg_removed_image.png")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f4ff),
      appBar: AppBar(title: const Text("BG Remover Pro"), centerTitle: true),
      body: Center(
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_fix_high, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    "Remove Background Instantly",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),

                  if (removedImageBytes != null)
                    Image.memory(
                      removedImageBytes!,
                      height: 350,
                      width: 350,
                      fit: BoxFit.contain,
                    )
                  else if (selectedImage != null)
                    Image.network(
                      selectedImage!.path,
                      height: 350,
                      width: 350,
                      fit: BoxFit.contain,
                    )
                  else
                    const Text("No Image Selected"),

                  const SizedBox(height: 22),

                  FilledButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Choose Image"),
                  ),

                  const SizedBox(height: 12),

                  if (selectedImage != null)
                    FilledButton.icon(
                      onPressed: isLoading ? null : removeBackground,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_fix_high),
                      label: Text(
                        isLoading ? "Processing..." : "Remove Background",
                      ),
                    ),

                  const SizedBox(height: 12),

                  if (removedImageBytes != null)
                    FilledButton.icon(
                      onPressed: downloadImage,
                      icon: const Icon(Icons.download),
                      label: const Text("Download PNG"),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}