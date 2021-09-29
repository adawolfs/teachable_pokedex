function playSound(sound) {
    var audio = new Audio(sound);
    audio.play();
}

function playPressA() {
    playSound("../assets/sounds/SFX_PRESS_AB.wav");
}