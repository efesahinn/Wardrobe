import 'package:image_picker/image_picker.dart';

typedef PickClothingImage = Future<String?> Function();

Future<String?> pickGalleryImage() async {
  return _pickImage(ImageSource.gallery);
}

Future<String?> takeCameraPhoto() async {
  return _pickImage(ImageSource.camera);
}

Future<String?> _pickImage(ImageSource source) async {
  final image = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1600,
    maxHeight: 1600,
    requestFullMetadata: false,
  );
  return image?.path;
}
