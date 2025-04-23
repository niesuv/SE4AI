import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  ImagePickerWidget({super.key, required this.onPickImage});

  void Function(File image) onPickImage;

  @override
  State<StatefulWidget> createState() {
    return _ImagePickerWidgetState();
  }
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _image;
  void addImage() async {
    final returnImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnImage != null) {
      setState(() {
        _image = File(returnImage.path);
      });
      widget.onPickImage(_image!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), border: Border.all()),
            height: 300,
            child: Card(
              child: _image == null
                  ? Image.asset(
                      "assets/images/lua.jpg",
                      fit: BoxFit.fill,
                    )
                  : Image.file(
                      _image!,
                      fit: BoxFit.fill,
                    ),
            )),
        ElevatedButton(onPressed: addImage, child: Icon(Icons.add_a_photo))
      ],
    );
  }
}
