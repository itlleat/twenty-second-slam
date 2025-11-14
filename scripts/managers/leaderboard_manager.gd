extends Node

# Leaderboard Manager - Handles Purple Token API integration
signal scores_retrieved(scores)
signal score_submitted(success, message)

# Purple Token credentials loaded from .env file (or fallback to hardcoded)
var GAME_KEY: String
var SECRET_PHRASE: String

const API_BASE_URL = "https://purpletoken.com/update/v3/"
const GET_ENDPOINT = API_BASE_URL + "get"
const SUBMIT_ENDPOINT = API_BASE_URL + "submit"

var http_request: HTTPRequest

func _ready():
	# Load credentials from .env file or use fallbacks
	_load_credentials()
	
	# Create HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func _load_credentials():
	"""Load API credentials from .env file with fallbacks"""
	var env_vars = EnvReader.load_env_file(".env")
	
	# Load from .env or use fallbacks
	GAME_KEY = env_vars.get("PURPLE_TOKEN_GAME_KEY", "8588ca934d8b0272a55b559f74af14337c9f4550")
	SECRET_PHRASE = env_vars.get("PURPLE_TOKEN_SECRET", "your_secret_phrase_here")
	
	# Validate credentials
	if SECRET_PHRASE == "your_secret_phrase_here":
		print("WARNING: Using default secret phrase. Please set PURPLE_TOKEN_SECRET in .env file!")
	
	print("LeaderboardManager: Credentials loaded (Game Key: ", GAME_KEY.substr(0, 8), "...)")

func _create_signature(encoded_params: String) -> String:
	"""Create SHA-256 signature for API authentication"""
	var to_hash = encoded_params + SECRET_PHRASE
	var hash_context = HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(to_hash.to_utf8_buffer())
	var hash_result = hash_context.finish()
	return hash_result.hex_encode()

func _encode_params(params: Dictionary) -> String:
	"""Convert parameters to URL encoded string, then base64 encode"""
	var param_strings = []
	for key in params:
		var encoded_key = key.uri_encode()
		var encoded_value = str(params[key]).uri_encode()
		param_strings.append(encoded_key + "=" + encoded_value)
	
	var param_string = "&".join(param_strings)
	return Marshalls.utf8_to_base64(param_string)

func get_leaderboard(limit: int = 20):
	"""Retrieve leaderboard scores from Purple Token API"""
	print("LeaderboardManager: Fetching leaderboard...")
	
	var params = {
		"gamekey": GAME_KEY,
		"format": "json",
		"array": "yes",
		"dates": "yes",
		"ids": "yes",
		"limit": limit
	}
	
	var encoded = _encode_params(params)
	var signature = _create_signature(encoded)
	
	var url = GET_ENDPOINT + "?payload=" + encoded + "&sig=" + signature
	
	print("LeaderboardManager: Making GET request to Purple Token API")
	var error = http_request.request(url)
	if error != OK:
		print("LeaderboardManager: Error making request: ", error)
		emit_signal("scores_retrieved", [])

func submit_score(player_name: String, score: int):
	"""Submit a score to Purple Token API"""
	print("LeaderboardManager: Submitting score - Player: ", player_name, " Score: ", score)
	
	# Validate inputs
	if player_name.length() == 0:
		print("LeaderboardManager: Error - Player name cannot be empty")
		emit_signal("score_submitted", false, "Player name cannot be empty")
		return
	
	if player_name.length() > 32:
		player_name = player_name.substr(0, 32)  # Truncate to 32 chars max
		print("LeaderboardManager: Player name truncated to: ", player_name)
	
	var params = {
		"gamekey": GAME_KEY,
		"player": player_name,
		"score": score
	}
	
	var encoded = _encode_params(params)
	var signature = _create_signature(encoded)
	
	var url = SUBMIT_ENDPOINT + "?payload=" + encoded + "&sig=" + signature
	
	print("LeaderboardManager: Making POST request to Purple Token API")
	var error = http_request.request(url, [], HTTPClient.METHOD_POST)
	if error != OK:
		print("LeaderboardManager: Error making request: ", error)
		emit_signal("score_submitted", false, "Network error occurred")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	"""Handle HTTP request completion"""
	print("LeaderboardManager: Request completed - Code: ", response_code, " Result: ", result)
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		print("LeaderboardManager: Failed to parse JSON response")
		emit_signal("scores_retrieved", [])
		emit_signal("score_submitted", false, "Invalid server response")
		return
	
	var response_data = json.data
	
	if response_code == 200:
		# Check if this was a GET request (retrieve scores) or POST request (submit score)
		if typeof(response_data) == TYPE_ARRAY:
			# This is a scores array from GET request
			print("LeaderboardManager: Successfully retrieved ", response_data.size(), " scores")
			emit_signal("scores_retrieved", response_data)
		elif typeof(response_data) == TYPE_DICTIONARY and response_data.has("scores"):
			# This is a dictionary with scores array from GET request
			print("LeaderboardManager: Successfully retrieved ", response_data.scores.size(), " scores")
			emit_signal("scores_retrieved", response_data.scores)
		else:
			# Assume this is a submit response
			print("LeaderboardManager: Score submission successful")
			emit_signal("score_submitted", true, "Score submitted successfully!")
	else:
		print("LeaderboardManager: Server error - Code: ", response_code)
		var error_message = "Server error (Code: " + str(response_code) + ")"
		if response_data is Dictionary and response_data.has("error"):
			error_message = response_data.error
		emit_signal("scores_retrieved", [])
		emit_signal("score_submitted", false, error_message)