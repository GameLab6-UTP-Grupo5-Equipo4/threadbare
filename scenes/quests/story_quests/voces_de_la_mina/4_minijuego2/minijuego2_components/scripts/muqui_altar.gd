# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
@tool
extends InteractArea

## Altar del Muqui — acepta ofrendas en secuencia y desbloquea el paso final
## Este script va directamente en el nodo InteractArea del AltarMuqui

signal offering_accepted(offering_index: int)
signal all_offerings_complete

@export var required_offerings: Array[InventoryItem] = []
@export var offering_dialogue_titles: Array[StringName] = []
@export var final_dialogue_title: StringName = &"coca_delivered"
@export var need_offering_dialogue_title: StringName = &"need_offering"
@export var already_complete_dialogue_title: StringName = &"coca_delivered"
@export var dialogue: DialogueResource
@export var blocked_passage: Node2D

var offerings_delivered := 0

func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	interaction_started.connect(_on_interacted)

func _on_interacted(player: Player, _from_right: bool) -> void:
	var inventory := GameState.items_collected()
	
	if offerings_delivered >= required_offerings.size():
		# Todas las ofrendas entregadas, mostrar diálogo de completado
		if dialogue:
			DialogueManager.show_dialogue_balloon(dialogue, already_complete_dialogue_title, [self, player])
			await DialogueManager.dialogue_ended
		end_interaction()
		return
	
	var next_offering := required_offerings[offerings_delivered]
	var has_offering := false
	
	for item in inventory:
		if item.name == next_offering.name:
			has_offering = true
			break
	
	if has_offering:
		# Consumir TODAS las ofrendas del inventario (simplificación para prototipo)
		# En una implementación más compleja, se removería solo la ofrenda específica
		GameState.clear_inventory()
		offerings_delivered += 1
		offering_accepted.emit(offerings_delivered)
		
		var dialogue_title := offering_dialogue_titles[offerings_delivered - 1] if offerings_delivered - 1 < offering_dialogue_titles.size() else final_dialogue_title
		
		if dialogue:
			DialogueManager.show_dialogue_balloon(dialogue, dialogue_title, [self, player])
			await DialogueManager.dialogue_ended
		end_interaction()
		
		if offerings_delivered >= required_offerings.size():
			_unlock_passage()
	else:
		if dialogue:
			DialogueManager.show_dialogue_balloon(dialogue, need_offering_dialogue_title, [self, player])
			await DialogueManager.dialogue_ended
		end_interaction()

func _unlock_passage() -> void:
	all_offerings_complete.emit()
	if blocked_passage:
		blocked_passage.queue_free()
