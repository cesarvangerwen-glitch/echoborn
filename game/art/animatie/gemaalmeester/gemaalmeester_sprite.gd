extends Sprite2D
## Eén laag van de Gemaalmeester (Technical Artist, #265): een `Sprite2D` op een
## frame van een blad uit `gemaalmeester.json`. `GemaalmeesterBeeld` kiest per
## tick het blad, de animatie en het frame; hier staat wat er nu getoond wordt
## (voor tests en de meting).

## Blad (`lichaam`, `ketel`, `rad`, `pompslag`, …), animatie en frame van nu, of "" / -1.
var blad := ""
var anim := ""
var frame_nr := -1
