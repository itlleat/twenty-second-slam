# Purple Token API test script
# Run this in Godot or as a standalone GDScript file

extends Node

var GAME_KEY = ""
var SECRET_PHRASE = ""
const API_BASE_URL = "https://purpletoken.com/update/v3/"
const GET_ENDPOINT = API_BASE_URL + "get"
const SUBMIT_ENDPOINT = API_BASE_URL + "submit"

func _ready():
    print("Testing Purple Token API with .env credentials...")
    _load_env()
    test_submit_score("TestUser", 123)
    test_get_leaderboard()

func _load_env():
    var env_vars = EnvReader.load_env_file(".env")
    GAME_KEY = env_vars.get("PURPLE_TOKEN_GAME_KEY", "")
    SECRET_PHRASE = env_vars.get("PURPLE_TOKEN_SECRET", "")
    print("Loaded GAME_KEY: ", GAME_KEY.substr(0, 8), "... SECRET: ", SECRET_PHRASE.substr(0, 4), "...")

func _encode_params(params: Dictionary) -> String:
    var param_strings = []
    for key in params:
        var encoded_key = key.uri_encode()
        var encoded_value = str(params[key]).uri_encode()
        param_strings.append(encoded_key + "=" + encoded_value)
    var param_string = "&".join(param_strings)
    return Marshalls.utf8_to_base64(param_string)

func _create_signature(encoded_params: String) -> String:
    var to_hash = encoded_params + SECRET_PHRASE
    var hash_context = HashingContext.new()
    hash_context.start(HashingContext.HASH_SHA256)
    hash_context.update(to_hash.to_utf8_buffer())
    var hash_result = hash_context.finish()
    return hash_result.hex_encode()

func test_submit_score(player_name: String, score: int):
    var params = {
        "gamekey": GAME_KEY,
        "player": player_name,
        "score": score
    }
    var encoded = _encode_params(params)
    var signature = _create_signature(encoded)
    var url = SUBMIT_ENDPOINT + "?payload=" + encoded + "&sig=" + signature
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_submit_completed)
    var error = http.request(url, [], HTTPClient.METHOD_POST)
    if error != OK:
        print("Error making submit request: ", error)

func _on_submit_completed(result, response_code, headers, body):
    print("Submit completed: code=", response_code, " result=", result)
    print("Raw body: ", body.get_string_from_utf8())

func test_get_leaderboard():
    var params = {
        "gamekey": GAME_KEY,
        "format": "json",
        "array": "yes",
        "dates": "yes",
        "ids": "yes",
        "limit": 10
    }
    var encoded = _encode_params(params)
    var signature = _create_signature(encoded)
    var url = GET_ENDPOINT + "?payload=" + encoded + "&sig=" + signature
    var http = HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_get_completed)
    var error = http.request(url)
    if error != OK:
        print("Error making get request: ", error)

func _on_get_completed(result, response_code, _headers, body):
    print("Get completed: code=", response_code, " result=", result)
    print("Raw body: ", body.get_string_from_utf8())
