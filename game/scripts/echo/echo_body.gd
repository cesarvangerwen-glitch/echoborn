extends CharacterBody2D
## Wat de Sim van elke echo verwacht (C-01, E-07b), voor de clip-echo
## (`echo_actor.gd`) en de staart-echo van v0.4 (`tail_echo.gd`).

## Events van het frame dat deze tick is afgespeeld (E-10); 0 als er geen is.
var tick_events := 0
## Klaar met afspelen; de Sim haalt hem dan na de tick uit zijn lijst.
var finished := false
## Het gevechtssysteem van de Sim (`combat.gd`), gezet door `Sim.add_echo`.
var combat: RefCounted = null


## Bezet deze echo de plaats van de echo (C-01)?
func is_active() -> bool:
	return false


## Staat hij nu als lichaam in de wereld (laag 3, zichtbaar)?
func is_present() -> bool:
	return false


## Haalt de echo uit de wereld, in dezelfde tick.
func stop() -> void:
	pass


## Stap (1) van E-07b.
func sim_step(_tick: int, _delta: float) -> void:
	pass


## Na stap (3): reageren op een reset van de bron in dezelfde tick.
func sim_after_source(_tick: int) -> void:
	pass


## Na stap (5).
func sim_end_tick() -> void:
	pass
