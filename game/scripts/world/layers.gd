extends RefCounted
## Physics-lagen (bitwaarden) volgens gdd E-05. Namen staan ook in
## project.godot [layer_names]; de tabel met maskers staat in gdd §2.3.

const WORLD := 1 << 0            ## laag 1 "wereld": geometrie in beide werelden
const LIGHT := 1 << 1            ## laag 2 "licht": lichaam en vlakken van P1
const SHADOW := 1 << 2           ## laag 3 "schaduw": lichaam en vlakken van echo en P2
const LIGHT_GEOMETRY := 1 << 3   ## laag 4 "licht-geometrie": bestaat alleen in licht
const SHADOW_GEOMETRY := 1 << 4  ## laag 5 "schaduw-geometrie": bestaat alleen in schaduw
const PLANK := 1 << 5            ## laag 6 "schaduwplank": eenrichtingscollider op echo en P2
const ZONES := 1 << 6            ## laag 7 "zones": FelLicht en Schaduwgevaar
const LIGHT_PLANK := 1 << 7      ## laag 8 "lichtplank": eenrichtingscollider op P1, alleen in co-op (C-09)
## Elke plank waarop een springer kan staan (E-07, C-09).
const ANY_PLANK := PLANK | LIGHT_PLANK

## Maskers uit de tabel van E-05.
const P1_MASK := WORLD | LIGHT_GEOMETRY | PLANK
const P2_MASK := WORLD | SHADOW_GEOMETRY | LIGHT_PLANK
## Wat de controles van de echo zien (E-08a/b); zones apart (E-08c/d).
const ECHO_CHECK_MASK := WORLD | SHADOW_GEOMETRY
