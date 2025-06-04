import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agri_helper/appconstant.dart';
import 'package:agri_helper/models/note.dart';
import 'package:agri_helper/provider/note_provider.dart';
import 'package:agri_helper/provider/user_provider.dart';
import 'package:agri_helper/widget/form_note.dart';
import 'package:agri_helper/widget/userinfo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class NoteView extends ConsumerStatefulWidget {
  NoteView({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends ConsumerState<NoteView> {
  List<Note> notes = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    notes = ref.read(NoteProvider);
    if (notes.length == 0) {
      FirebaseFirestore.instance
          .collection("notes")
          .where("userid", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .limit(100)
          .orderBy("date", descending: true)
          .get()
          .then((value) {
        for (var item in value.docs) {
          Timestamp timestamp = item["date"];
          ref.read(NoteProvider.notifier).addNote(
              Note(item["title"], item["content"], timestamp.toDate()));
        }
        setState(() {
          notes = ref.read(NoteProvider);
          print(notes);
        });
      });
    }
    setState(() {
      notes = ref.read(NoteProvider);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void addNewNote() async {
    final res = await showModalBottomSheet(
      useSafeArea: false,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return FormNote();
      },
    );
    setState(() {
      notes = ref.read(NoteProvider);
    });
  }

  void _deleteNote(int index) async {
    // Show confirmation dialog
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa ghi chú này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // Get the note's title to query Firestore
    final noteTitle = notes[index].title;
    final noteContent = notes[index].content;

    // Delete from Firestore
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("notes")
          .where("userid", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where("title", isEqualTo: noteTitle)
          .where("content", isEqualTo: noteContent)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      // Update local state
      ref.read(NoteProvider.notifier).deleteNote(index);
      setState(() {
        notes = ref.read(NoteProvider);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa ghi chú thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: Không thể xóa ghi chú. ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateNote(int index) async {
    final note = notes[index];
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      useSafeArea: false,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return FormNote(
          editMode: true,
          initialTitle: note.title,
          initialContent: note.content,
        );
      },
    );

    if (result != null) {
      try {
        // Find and update the document in Firestore
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection("notes")
            .where("userid", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .where("title", isEqualTo: note.title)
            .where("content", isEqualTo: note.content)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.update({
            "title": result["title"],
            "content": result["content"],
            "date": Timestamp.fromDate(result["date"]),
          });

          // Update local state
          ref.read(NoteProvider.notifier).updateNote(
              index,
              Note(result["title"], result["content"], result["date"]));

          setState(() {
            notes = ref.read(NoteProvider);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cập nhật ghi chú thành công'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Không tìm thấy ghi chú để cập nhật');
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: Không thể cập nhật ghi chú. ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          UserInfoCard(username: ref.read(UserProvider)["username"]),
          SizedBox(
            height: 16,
          ),
          if (notes.length == 0)
            Column(
              children: [
                SizedBox(
                  height: 100,
                ),
                Image.asset(
                  "assets/images/emptybox.png",
                  width: 350,
                ),
                SizedBox(
                  height: 12,
                ),
                Text("Nothing here")
              ],
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.all(10),
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(16)),
                  child: Card(
                    color: Color.fromARGB(255, 231, 245, 240),
                    elevation: 7,
                    child: Container(
                      padding: EdgeInsets.all(15),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${notes[index].title}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${DateFormat.yMd().format(notes[index].dateTime)}",
                                  style: TextStyle(fontSize: 15),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "${notes[index].content}",
                                  style: TextStyle(fontSize: 15),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Colors.blue,
                            ),
                            onPressed: () => _updateNote(index),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteNote(index),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
                color: Color.fromARGB(255, 231, 245, 240),
                borderRadius: BorderRadius.circular(50)),
            child: IconButton(
              onPressed: addNewNote,
              icon: Icon(Icons.add),
              color: buttonBack,
            ),
          )
        ],
      ),
    );
  }
}
