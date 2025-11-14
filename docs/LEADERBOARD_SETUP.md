# Twenty Second Slam - Leaderboard Integration Setup Guide

## Overview
This guide will help you complete the leaderboard integration for your "Twenty Second Slam" game using the Purple Token API.

## What's Been Implemented

### 1. Core Managers (✅ Completed)
- **GameManager**: Tracks game state, 20-second timer, and total damage score
- **LeaderboardManager**: Handles Purple Token API integration with proper authentication

### 2. Game Logic (✅ Completed)
- **Enemy Damage Tracking**: Each enemy hit = 1 damage, enemy kill = 5 bonus damage
- **Timer System**: 20-second countdown with automatic game end
- **Score Accumulation**: Total damage becomes the high score

### 3. UI Components (✅ Scripts Created)
- **Game UI**: In-game score and timer display
- **Leaderboard UI**: Display high scores from API
- **Game Over Screen**: Final score display and name input for submission
- **Main Menu Integration**: Leaderboard button already connected

## Next Steps - Scene Creation

You need to create the following .tscn scene files in the Godot editor:

### 1. Game Over Scene (`game_over.tscn`)
```
Control (GameOver script attached)
└── VBoxContainer
    ├── FinalScoreLabel (Label)
    ├── NameInput (LineEdit)
    ├── HBoxContainer
    │   ├── SubmitButton (Button) - "Submit Score"
    │   ├── MenuButton (Button) - "Main Menu"
    │   └── LeaderboardButton (Button) - "View Leaderboard"
    └── StatusLabel (Label)
```

### 2. Leaderboard Scene (`leaderboard.tscn`)
```
Control (LeaderboardUI script attached)
└── VBoxContainer
    ├── Label - "High Scores"
    ├── ScrollContainer
    │   └── ScoreList (VBoxContainer)
    ├── LoadingLabel (Label)
    └── BackButton (Button) - "Back to Menu"
```

### 3. Add Game UI to Test Level (`test_level.tscn`)
Add a CanvasLayer with GameUI script:
```
TestLevel
├── (existing nodes...)
└── GameUI (CanvasLayer with GameUI script)
    └── VBoxContainer (top-left corner)
        ├── ScoreLabel (Label)
        └── TimerLabel (Label)
```

## Purple Token API Configuration

### IMPORTANT: Set Up Your Credentials
Create a `.env` file in your project root with your actual credentials:

```env
PURPLE_TOKEN_GAME_KEY=your_actual_purple_token_game_key
PURPLE_TOKEN_SECRET=your_actual_secret_passphrase
```

**Security Notes:**
- ✅ The `.env` file is in `.gitignore` to keep secrets out of version control
- ✅ Copy `.env.example` to `.env` and fill in your real credentials
- ✅ Never commit the `.env` file to your repository

### Where to Find Your Credentials:
1. **Game Key**: Found in your Purple Token dashboard after creating a game
2. **Secret Phrase**: Set in your Purple Token profile settings (keep this private!)

## Game Flow
1. **Main Menu** → Start Game → **Test Level**
2. **Test Level** → 20 seconds of gameplay → **Game Over Screen**
3. **Game Over Screen** → Submit score → **Leaderboard** or **Main Menu**
4. **Main Menu** → Leaderboards Button → **Leaderboard Screen**

## Features Implemented
- ✅ 20-second gameplay timer
- ✅ Damage scoring (1 per hit, 5 per kill)
- ✅ Score submission to Purple Token API
- ✅ Leaderboard retrieval and display
- ✅ Proper API authentication (base64 + SHA-256)
- ✅ Game state management
- ✅ Scene transitions

## Testing the Integration
1. Create the scene files as described above
2. Update your Purple Token credentials
3. Run the game and complete a 20-second session
4. Submit a test score
5. Check the leaderboard to verify integration

## Troubleshooting
- If API calls fail, check your credentials and internet connection
- Ensure your Purple Token account has the correct permissions
- Check the Godot debugger output for error messages
- The scoring system automatically starts when you enter the test level

## API Details
- **Endpoint**: Purple Token REST API v3
- **Authentication**: Base64-encoded parameters + SHA-256 signature
- **Score Format**: Player name (max 32 chars) + integer score
- **Leaderboard**: Top 20 scores with dates and player names

Your leaderboard system is now ready to use! Just create the scene files and update your API credentials.