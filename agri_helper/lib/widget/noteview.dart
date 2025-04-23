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
