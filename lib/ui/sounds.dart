import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';

const String RECOGNITION = "SFX_PURCHASE.wav";
const String OPEN_CAMERA = "SFX_PRESS_AB.wav";
AudioCache audioPlugin = AudioCache(prefix: 'assets/sounds/');
bool isPlaying = false;

Future<void> loadSounds() async {
  audioPlugin.loadAll([OPEN_CAMERA, RECOGNITION]);
}

Future<void> playSound(sound) async {
  if (isPlaying) return;
  isPlaying = true;
  return audioPlugin.play(sound, mode: PlayerMode.MEDIA_PLAYER).then((_) {
    isPlaying = false;
  });
}
