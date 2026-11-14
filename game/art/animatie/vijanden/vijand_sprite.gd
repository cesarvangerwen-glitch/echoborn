extends Sprite2D
## Eén laag van een slice-vijand (Technical Artist, #272): een `Sprite2D` op een
## frame van een blad uit `<type>.json`. `VijandBeeld` kiest per tick het blad,
## de animatie en het frame; hier staat wat er nu getoond wordt (voor tests en
## de meting).

## Blad (`kadeloper`, `tell_haak`, `duiklijn`, …), animatie en frame van nu, of "" / -1.
var blad := ""
var anim := ""
var frame_nr := -1
