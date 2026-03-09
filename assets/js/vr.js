(function () {
  "use strict";

  const allowedPokemon = new Set([
    "bulbasaur",
    "charmander",
    "squirtle",
    "pikachu",
  ]);
  const params = new URLSearchParams(window.location.search);
  const pokemon = params.get("pokemon");
  const selectedPokemon = allowedPokemon.has(pokemon) ? pokemon : "bulbasaur";
  const model = document.getElementById("pokemon-model");

  if (model) {
    model.setAttribute("gltf-model", `#${selectedPokemon}`);
  }

  document.title = `PokeAR - ${selectedPokemon}`;
})();
