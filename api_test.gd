extends Node

# Quick test script for Purple Token API integration
# Add this to a scene and run to test the leaderboard system

func _ready():
	print("=== LEADERBOARD API TEST ===")
	
	# Connect to LeaderboardManager signals
	LeaderboardManager.scores_retrieved.connect(_on_scores_retrieved)
	LeaderboardManager.score_submitted.connect(_on_score_submitted)
	
	# Wait a moment for initialization
	await get_tree().create_timer(1.0).timeout
	
	print("Testing leaderboard retrieval...")
	LeaderboardManager.get_leaderboard(5)  # Get top 5 scores
	
	# Wait for response
	await get_tree().create_timer(3.0).timeout
	
	print("Testing score submission...")
	LeaderboardManager.submit_score("TestPlayer", 42)

func _on_scores_retrieved(scores: Array):
	print("=== SCORES RETRIEVED ===")
	if scores.is_empty():
		print("No scores found or API error")
	else:
		print("Retrieved ", scores.size(), " scores:")
		for i in range(scores.size()):
			var score = scores[i]
			print("%d. %s - %d points" % [i+1, score.get("player", "Unknown"), score.get("score", 0)])

func _on_score_submitted(success: bool, message: String):
	print("=== SCORE SUBMISSION ===")
	print("Success: ", success)
	print("Message: ", message)
	
	if success:
		print("✅ API integration working!")
	else:
		print("❌ API error: ", message)