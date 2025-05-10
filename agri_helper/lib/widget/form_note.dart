import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agri_helper/models/note.dart';
import 'package:agri_helper/provider/note_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormNote extends ConsumerStatefulWidget {
  FormNote({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _FormNoteState();
  }
}

class _FormNoteState extends ConsumerState<FormNote> {
  final _formKey = GlobalKey<FormState>();

  var _title, _content;
  void submitForm() {
    final isValid = _formKey.currentState!.validate();
    if (isValid) {
      _formKey.currentState!.save();
      final date = DateTime.now();
      ref
          .read(NoteProvider.notifier)
          .addNote(Note(_title, _content, date), addFirst: true);
      FirebaseFirestore.instance.collection("notes").add({
        "userid": FirebaseAuth.instance.currentUser!.uid,
        "title": _title,
        "date": Timestamp.fromDate(date),
        "content": _content
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      color: Colors.white,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: "Tiêu đề",
              ),
              onSaved: (newValue) {
                _title = newValue!;
              },
              validator: (value) {
                if (value == null || value.trim().length == 0)
                  return "Vui lòng không bỏ trống tiêu đề";
                return null;
              },
            ),
            TextFormField(
              maxLines: 9,
              decoration: InputDecoration(
                labelText: "Nội dung",
              ),
              onSaved: (newValue) {
                _content = newValue!;
              },
              validator: (value) {
                if (value == null || value.trim().length == 0)
                  return "Vui lòng không bỏ trống nội dung!";
                return null;
              },
            ),
            Expanded(
                child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    "Thêm",
                    style: TextStyle(fontSize: 18, color: Colors.green),
                  ),
                )
              ],
            ))
          ],
        ),
      ),
    );
  }
}
