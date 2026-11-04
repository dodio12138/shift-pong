extends RefCounted
## SHIFT RUN (the jam's main mode): six opponents in a row, each a single game
## to 7, the last one a legend. You start with your loadout of four skills;
## after every win three new ones are offered and one may be shifted in for one
## you have. Two hearts: a loss costs one and the same opponent comes again;
## with none left the run is over.

const Roster := preload("res://scripts/roster.gd")
const People := preload("res://scripts/people.gd")
const Tour := preload("res://scripts/tour.gd")

const STAGES := 6
const HEARTS := 2
const GAME_TO := 7                 # points a game in a run

var me: Dictionary                 # the player you took in
var ladder: Array = []             # the opponents, weakest first; the last a legend
var stage := 0                     # the next opponent (index into ladder)
var hearts := HEARTS
var loadout: Array = []            # skill ids, as in the settings
var offer: Array = []              # skill ids offered after a win (empty when none waits)
var log: Array = []                # per match played: {stage, won, score}


func _init(player: Dictionary, start_loadout: Array) -> void:
	me = player
	loadout = start_loadout.duplicate()
	var tour := Tour.new()
	var pool := []
	for c in tour.clubs:
		for p in c.players:
			if p.name != me.name:
				pool.append(p)
	pool.sort_custom(func(x, y): return Roster.overall(x) < Roster.overall(y))
	# five from the field, spread from the weaker end to the strong
	for k in STAGES - 1:
		var at := int(lerpf(0.05, 0.92, float(k) / float(STAGES - 2)) * (pool.size() - 1))
		ladder.append(pool[at])
	var b: Dictionary = Roster.BOSSES.pick_random().duplicate(true)
	People.ensure(b)
	ladder.append(b)


func opponent() -> Dictionary:
	return ladder[mini(stage, ladder.size() - 1)]


func is_boss() -> bool:
	return stage == STAGES - 1


func is_over() -> bool:
	return hearts <= 0 or stage >= STAGES


func won_all() -> bool:
	return stage >= STAGES


## The match against this stage's opponent is over.
func resolve(won: bool, score: String, all_ids: Array) -> void:
	log.append({"stage": stage, "won": won, "score": score})
	if won:
		stage += 1
		if stage < STAGES:
			var fresh := all_ids.filter(func(id): return not loadout.has(id))
			fresh.shuffle()
			offer = fresh.slice(0, 3)
	else:
		hearts -= 1


## Takes offered skill `id` in place of loadout slot `slot`.
func take(id: String, slot: int) -> void:
	loadout[slot] = id
	offer = []
