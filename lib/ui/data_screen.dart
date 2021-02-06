import 'package:flutter/material.dart';
import 'package:teachable_pokedex/data/pokemon_data.dart';

typedef Future<void> SpeakController(String say);
typedef void Callback();

class DataScreen extends StatefulWidget {
  final int index;
  final SpeakController say;
  final Callback callback;
  DataScreen(this.index, this.say, this.callback, {Key key}) : super(key: key);

  @override
  _DataScreenState createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  @override
  Widget build(BuildContext context) {
    // NOTE Callback hell
    widget.say(pokemonData[widget.index].name).then((_) => widget
        .say(pokemonData[widget.index].description)
        .then((_) => widget.callback));

    PokemonData pokemon = pokemonData[widget.index];

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 100,
            width: 100,
            child: FittedBox(
              child: Image.asset('assets/9.gif'),
              fit: BoxFit.fill,
            ),
          ),
          Text(
            pokemon.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              decoration: TextDecoration.none,
              backgroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
