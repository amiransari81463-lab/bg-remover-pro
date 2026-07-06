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
  XFile? backgroundImage;
  Uint8List? removedImageBytes;

  Color selectedColor = Colors.white;
  bool isTransparent = false;
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

  Future<void> pickBackgroundImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        backgroundImage = image;
        isTransparent = false;
      });
    }
  }

  void setBgColor(Color color) {
    setState(() {
      selectedColor = color;
      backgroundImage = null;
      isTransparent = false;
    });
  }

  void setTransparentBg() {
    setState(() {
      backgroundImage = null;
      isTransparent = true;
    });
  }

  Future<void> removeBackground() async {
    if (selectedImage == null) return;

    setState(() => isLoading = true);

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("https://bg-remover-pro.onrender.com/remove-bg"),
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
        setState(() => removedImageBytes = bytes);
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

  Widget previewBox() {
    if (removedImageBytes != null) {
      return Container(
        height: 360,
        width: 360,
        decoration: BoxDecoration(
          color: isTransparent ? Colors.transparent : selectedColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.deepPurple.shade100),
          image: backgroundImage == null
              ? null
              : DecorationImage(
                  image: NetworkImage(backgroundImage!.path),
                  fit: BoxFit.cover,
                ),
        ),
        child: Image.memory(
          removedImageBytes!,
          fit: BoxFit.contain,
        ),
      );
    }

    if (selectedImage != null) {
      return Image.network(
        selectedImage!.path,
        height: 360,
        width: 360,
        fit: BoxFit.contain,
      );
    }

    return Container(
      height: 240,
      width: 340,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: const Text("No Image Selected"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f4ff),
      appBar: AppBar(
        title: const Text("BG Remover Pro"),
        centerTitle: true,
      ),
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_fix_high, size: 60),
                  const SizedBox(height: 12),
                  const Text(
                    "Remove Background Instantly",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Upload photo, remove background, add custom background and download PNG.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: previewBox(),
                  ),

                  const SizedBox(height: 22),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Choose Image"),
                      ),
                      FilledButton.icon(
                        onPressed: pickBackgroundImage,
                        icon: const Icon(Icons.image),
                        label: const Text("Upload BG"),
                      ),
                      FilledButton.icon(
                        onPressed: () => setBgColor(Colors.white),
                        icon: const Icon(Icons.format_color_fill),
                        label: const Text("White BG"),
                      ),
                      FilledButton.icon(
                        onPressed: () => setBgColor(Colors.lightBlue),
                        icon: const Icon(Icons.color_lens),
                        label: const Text("Blue BG"),
                      ),
                      FilledButton.icon(
                        onPressed: () => setBgColor(Colors.red),
                        icon: const Icon(Icons.color_lens),
                        label: const Text("Red BG"),
                      ),
                      FilledButton.icon(
                        onPressed: () => setBgColor(Colors.green),
                        icon: const Icon(Icons.color_lens),
                        label: const Text("Green BG"),
                      ),
                      FilledButton.icon(
                        onPressed: setTransparentBg,
                        icon: const Icon(Icons.layers_clear),
                        label: const Text("Transparent"),
                      ),
                    ],
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