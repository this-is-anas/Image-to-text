import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_to_text/services/claude_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Initialization and declaration
  File? _image;
  String? _description;
  bool _isLoading = false;
  final _picker = ImagePicker();
  String? _errorMessage;

  //PickImage method
  Future<void> _pickImage(ImageSource source) async {
    //pick image either from gallery or camera
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxHeight: 1080,
        maxWidth: 1920,
        imageQuality: 85,
      );
      //After the image has been choosen lets start the analysis
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isLoading = true;
          _errorMessage = null;
        });
        await _analyzeImage();
      }
    }
    //error
    catch (e) {
      print(e);
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  //analyze image method
  Future<void> _analyzeImage() async {
    if (_image == null) return; // no image chosen to analyse

    //loading...
    setState(() {
      _isLoading = true;
    });

    //start analysing of image
    try {
      final description = await ClaudeService().analyzeImage(_image!);
      setState(() {
        _description = description;
        _isLoading = false;
      });
    }
    //error...
    catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  //Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Analyzer',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Image Preview
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_image!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_search,
                                size: 50, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('Select an image to analyze',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  _buildActionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Analysis Results
              if (_isLoading)
                Column(
                  children: [
                    const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 16),
                    Text('Analyzing image...',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                )
              else if (_description != null)
                _buildResultCard(
                  title: 'Analysis Results',
                  content: _description!,
                  color: Colors.blue[50],
                ),

              if (_errorMessage != null)
                _buildResultCard(
                  title: 'Error',
                  content: _errorMessage!,
                  color: Colors.red[50],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildResultCard(
      {required String title, required String content, Color? color}) {
    return Card(
      color: color,
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueGrey,
                  ),
                ),
                const Spacer(),
                if (title == 'Error')
                  const Icon(Icons.error_outline, color: Colors.red, size: 20)
                else
                  const Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
