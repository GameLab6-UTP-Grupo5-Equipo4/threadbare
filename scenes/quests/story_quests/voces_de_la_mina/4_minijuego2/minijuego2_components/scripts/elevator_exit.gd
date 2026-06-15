# SPDX-FileCopyrightText: The Threadbare Authors
# SPDX-License-Identifier: MPL-2.0
extends InteractArea

## Elevador de salida — transiciona a la siguiente escena cuando se interactúa
## Este script va directamente en el nodo InteractArea del Elevador

@export var dialogue: DialogueResource
@export var next_scene: String = ""
@export var blocked_passage: Node2D

func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		return
	interaction_started.connect(_on_interacted)

func _on_interacted(player: Player, _from_right: bool) -> void:
	# Si todavía hay un bloqueo, no permitir usar el elevador
	if blocked_passage and is_instance_valid(blocked_passage):
		if dialogue:
			DialogueManager.show_dialogue_balloon(dialogue, &"elevador_bloqueado", [self, player])
			await DialogueManager.dialogue_ended
		end_interaction()
		return
	
	# El elevador está libre, mostrar diálogo final y transicionar
	if dialogue:
		DialogueManager.show_dialogue_balloon(dialogue, &"elevador_final", [self, player])
		await DialogueManager.dialogue_ended
	end_interaction()
	
	if next_scene:
		GameState.set_challenge_start_scene(next_scene)
		SceneSwitcher.change_to_file_with_transition(next_scene)
