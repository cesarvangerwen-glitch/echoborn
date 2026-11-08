extends RefCounted
## Physics-lagen (bitwaarden). Namen staan ook in project.godot [layer_names].

const WORLD := 1 << 0   ## laag 1 "wereld": vloeren, muren
const LIGHT := 1 << 1   ## laag 2 "licht": levende spelers
const SHADOW := 1 << 2  ## laag 3 "schaduw": echo's
