import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Labels extends StatelessWidget {
  final List<dynamic> _recognitions;

  Labels(this._recognitions);

  @override
  Widget build(BuildContext context) {
    Widget _renderLabels() {
      return Column(
        children: _recognitions != null
            ? _recognitions.map((res) {
                return Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Text(
                    "${res["index"]} - ${res["label"]}: ${res["confidence"].toStringAsFixed(3)}",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20.0,
                      background: Paint()..color = Colors.white,
                    ),
                  ),
                );
              }).toList()
            : [],
      );
    }

    return Center(
      child: _renderLabels(),
    );
  }
}
