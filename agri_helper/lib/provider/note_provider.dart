import 'package:agri_helper/models/note.dart';
import 'package:riverpod/riverpod.dart';

class NoteNotifier extends StateNotifier<List<Note>> {
  NoteNotifier() : super([]);
  void addNote(Note note, {addFirst = false}) {
    if (!addFirst)
      state = [...state, note];
    else
      state = [note, ...state];
  }

  void deleteNote(int index) {
    state = [
      ...state.sublist(0, index),
      ...state.sublist(index + 1),
    ];
  }

  void updateNote(int index, Note updatedNote) {
    state = [
      ...state.sublist(0, index),
      updatedNote,
      ...state.sublist(index + 1),
    ];
  }

  void clear() {
    state.clear();
  }
}

final NoteProvider =
    StateNotifierProvider<NoteNotifier, List<Note>>((ref) => NoteNotifier());
