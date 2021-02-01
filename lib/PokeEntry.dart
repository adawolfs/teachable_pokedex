import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

typedef void Callback();

class PokeEntry extends StatefulWidget {
  final dynamic prediction;
  const PokeEntry(this.prediction);

  @override
  _PokeEntryState createState() => _PokeEntryState();
}

class _PokeEntryState extends State<PokeEntry> {
  @override
  void initState() {
    super.initState();
    loadVoice();
  }

  @override
  void dispose() {
    super.dispose();
  }

  loadVoice() async {
    if (widget.prediction != null) {
      FlutterTts flutterTts = FlutterTts();
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.speak(widget.prediction["label"]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [Text("${widget.prediction["label"]}")],
      ),
    );
  }
}
