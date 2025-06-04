import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  ImagePickerWidget({super.key, required this.onPickImage});

  final void Function(File image) onPickImage;

  @override
  State<ImagePickerWidget> createState() {
    return _ImagePickerWidgetState();
  }
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _image;

  void addImage() async {
    final returnImage = await ImagePicker().pickImage(source: ImageSource.gallery);
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
            borderRadius: BorderRadius.circular(10),
            border: Border.all(),
          ),
          height: 300,
          child: Card(
            child: _image == null
                // Nếu chưa chọn ảnh, hiển thị ô trống hoặc hướng dẫn
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          "Chưa có ảnh",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                // Nếu đã chọn ảnh, hiển thị ảnh từ File
                : Image.file(
                    _image!,
                    fit: BoxFit.fill,
                  ),
          ),
        ),
        SizedBox(height: 12),
        ElevatedButton(
          onPressed: addImage,
          child: Icon(Icons.add_a_photo),
        ),
      ],
    );
  }
}
