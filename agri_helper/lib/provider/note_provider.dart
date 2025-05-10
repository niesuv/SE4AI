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

  void clear() {
    state.clear();
  }
}

final NoteProvider =
    StateNotifierProvider<NoteNotifier, List<Note>>((ref) => NoteNotifier());
