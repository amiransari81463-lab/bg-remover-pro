import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:desktop_drop/desktop_drop.dart';

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
  bool showColorPicker = false;
  bool isDragging = false;

  void setSelectedImage(XFile image) {
    setState(() {
      selectedImage = image;
      removedImageBytes = null;
      isDragging = false;
    });
  }

  Future<void> pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setSelectedImage(image);
    }
  }

  Future<void> pickBackgroundImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        backgroundImage = image;
        isTransparent = false;
        showColorPicker = false;
      });
    }
  }

  void setBgColor(Color color) {
    setState(() {
      selectedColor = color;
      backgroundImage = null;
      isTransparent = false;
      showColorPicker = false;
    });
  }

  void setTransparentBg() {
    setState(() {
      backgroundImage = null;
      isTransparent = true;
      showColorPicker = false;
    });
  }

  void toggleColorPicker() {
    setState(() {
      showColorPicker = !showColorPicker;
      backgroundImage = null;
      isTransparent = false;
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

  Widget resultPreview() {
    if (removedImageBytes != null) {
      return Container(
        height: 360,
        width: 360,
        decoration: BoxDecoration(
          color: isTransparent ? Colors.transparent : selectedColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.deepPurple.shade100),
          image: backgroundImage == null
              ? null
              : DecorationImage(
                  image: NetworkImage(backgroundImage!.path),
                  fit: BoxFit.cover,
                ),
        ),
        child: Image.memory(removedImageBytes!, fit: BoxFit.contain),
      );
    }

    return emptyBox("Result Preview");
  }

  Widget originalPreview() {
    if (selectedImage != null) {
      return Image.network(
        selectedImage!.path,
        height: 360,
        width: 360,
        fit: BoxFit.contain,
      );
    }

    return emptyBox(isDragging ? "Drop Image Here" : "Drag & Drop Image Here");
  }

  Widget emptyBox(String text) {
    return Container(
      height: 260,
      width: 340,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDragging ? Colors.deepPurple.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDragging ? Colors.deepPurple : Colors.deepPurple.shade100,
          width: isDragging ? 2 : 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isDragging ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget actionButton(IconData icon, String text, VoidCallback onTap) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f1ff),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff5b2cff), Color(0xff8f5cff)],
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.auto_fix_high, color: Colors.white, size: 70),
                  SizedBox(height: 12),
                  Text(
                    "BG Remover Pro",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Remove background, add custom background and download PNG.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 10,
              margin: const EdgeInsets.all(18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      alignment: WrapAlignment.center,
                      children: [
                        DropTarget(
                          onDragEntered: (_) {
                            setState(() => isDragging = true);
                          },
                          onDragExited: (_) {
                            setState(() => isDragging = false);
                          },
                          onDragDone: (details) {
                            if (details.files.isNotEmpty) {
                              setSelectedImage(details.files.first);
                            }
                          },
                          child: Column(
                            children: [
                              const Text(
                                "Original",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: originalPreview(),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            const Text(
                              "Result",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: resultPreview(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        actionButton(Icons.upload_file, "Choose Image", pickImage),
                        actionButton(Icons.image, "Upload BG", pickBackgroundImage),
                        actionButton(Icons.format_color_fill, "White", () => setBgColor(Colors.white)),
                        actionButton(Icons.color_lens, "Blue", () => setBgColor(Colors.lightBlue)),
                        actionButton(Icons.color_lens, "Red", () => setBgColor(Colors.red)),
                        actionButton(Icons.color_lens, "Green", () => setBgColor(Colors.green)),
                        actionButton(Icons.palette, "Color Picker", toggleColorPicker),
                        actionButton(Icons.layers_clear, "Transparent", setTransparentBg),
                      ],
                    ),
                    if (showColorPicker) ...[
                      const SizedBox(height: 18),
                      const Text(
                        "Choose Custom Background Color",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ColorPicker(
                        pickerColor: selectedColor,
                        onColorChanged: (color) {
                          setState(() {
                            selectedColor = color;
                            backgroundImage = null;
                            isTransparent = false;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 18),
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
                        label: Text(isLoading ? "Processing..." : "Remove Background"),
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
            const SizedBox(height: 18),
            const Text(
              "How it works: Drag Image or Upload → Remove Background → Add BG → Download",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}