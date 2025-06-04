import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agri_helper/models/note.dart';
import 'package:agri_helper/provider/note_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormNote extends ConsumerStatefulWidget {
  final bool editMode;
  final String? initialTitle;
  final String? initialContent;

  FormNote({
    super.key,
    this.editMode = false,
    this.initialTitle,
    this.initialContent,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _FormNoteState();
  }
}

class _FormNoteState extends ConsumerState<FormNote> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.editMode) {
      _titleController.text = widget.initialTitle ?? '';
      _contentController.text = widget.initialContent ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void submitForm() {
    final isValid = _formKey.currentState!.validate();
    if (isValid) {
      final date = DateTime.now();
      
      if (widget.editMode) {
        // Return data for update
        Navigator.of(context).pop({
          "title": _titleController.text,
          "content": _contentController.text,
          "date": date,
        });
      } else {
        // Add new note
        ref.read(NoteProvider.notifier).addNote(
          Note(_titleController.text, _contentController.text, date), 
          addFirst: true
        );
        
        FirebaseFirestore.instance.collection("notes").add({
          "userid": FirebaseAuth.instance.currentUser!.uid,
          "title": _titleController.text,
          "date": Timestamp.fromDate(date),
          "content": _contentController.text
        });
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          15, 15, 15, MediaQuery.of(context).viewInsets.bottom + 15),
      color: Colors.white,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Tiêu đề",
              ),
              validator: (value) {
                if (value == null || value.trim().length == 0)
                  return "Vui lòng không bỏ trống tiêu đề";
                return null;
              },
            ),
            TextFormField(
              controller: _contentController,
              maxLines: 9,
              decoration: InputDecoration(
                labelText: "Nội dung",
              ),
              validator: (value) {
                if (value == null || value.trim().length == 0)
                  return "Vui lòng không bỏ trống nội dung!";
                return null;
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Thoát",
                    style: TextStyle(fontSize: 18, color: Colors.pink),
                  ),
                ),
                TextButton(
                  onPressed: submitForm,
                  child: Text(
                    widget.editMode ? "Cập nhật" : "Thêm",
                    style: TextStyle(fontSize: 18, color: Colors.green),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
