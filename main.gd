extends Node

@export var mob_scene: PackedScene
var score

const API_URL = "http://localhost:11434/api/generate" # local ollama

func send_request(prompt: String, temperature = 0.0):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"model": "llama3.2",
		"prompt": prompt,
		"stream": false,
		"temperature": temperature
	})

	var error = http_request.request(API_URL, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("Request failed: ", error)

func _ready():
	pass

func game_over():
	$DeathSound.play()
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()
	$Music.stop()
	send_request("Give me a short inspirational failure quote", 1.0)


func new_game():
	get_tree().call_group("mobs", "queue_free")
	score = 0
	$Player.start($StartPosition.position)
	$Music.play()
	$StartTimer.start()
	$HUD.update_score(score)
	send_request("Send a one-word inspirational start message", 1.0)


func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var response = body.get_string_from_utf8()
		var json = JSON.parse_string(body.get_string_from_utf8())
		$HUD.show_message(json["response"], 5)
	else:
		print("Error: ", response_code)

func _on_mob_timer_timeout():
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()

	# Set the mob's position to the random location.
	mob.position = mob_spawn_location.position

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)
	
	$HUD.update_score(score)


func _on_score_timer_timeout() -> void:
	score += 1

func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()
