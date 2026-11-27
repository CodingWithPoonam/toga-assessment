// Deliberately flawed static review excerpt. repo is an injected mock abstraction.
import 'package:flutter/material.dart';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key, required this.lessonId, required this.repo});
  final String lessonId;
  final dynamic repo;
  @override
  State<StudyPage> createState() => _StudyPageState();
}
class _StudyPageState extends State<StudyPage> {
  String text = '';
  @override
  void initState() {
    super.initState();
    widget.repo.events.listen((event) { setState(() => text = event.text); });
    load();
  }
  Future<void> load() async {
    final lesson = await widget.repo.fetchLesson(widget.lessonId);
    setState(() => text = lesson.body);
  }
  @override
  Widget build(BuildContext context) {
    widget.repo.saveProgress(widget.lessonId, text);
    return Column(children: [Text(text), ElevatedButton(
      onPressed: () { widget.repo.submit(); }, child: const Text('Submit'))]);
  }
}
