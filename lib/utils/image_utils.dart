import 'dart:convert'; // For base64 encoding
import 'dart:io'; // For File operations
import 'package:file_picker/file_picker.dart'; // To handle PlatformFile

Future<void> processImage(PlatformFile file) async {
  try {
    if (file.path != null) {
      // Read the image file as bytes
      final File imageFile = File(file.path!);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      print('Base64 Image: $base64Image');
      // You can now use `base64Image` for further processing, like uploading to an API
    } else {
      print('File path is null');
    }
  } catch (e) {
    print('Error reading image file: $e');
  }
}
