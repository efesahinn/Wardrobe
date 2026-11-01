import 'package:image_picker/image_picker.dart';

typedef PickClothingImage = Future<String?> Function();

Future<String?> pickGalleryImage() async {
  final image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    maxHeight: 1600,
    requestFullMetadata: false,
  );
  return image?.path;
}
