# PD Brawl - Public Domain Trading Card Game

A digital card game featuring public domain characters in an epic battle of wits and strategy!

## About the Game

PD Brawl is a trading card game where players use Essence to play character cards from public domain works, along with action and item cards. Characters can attack opponents and even be fused together to create more powerful cards!

## How to Play

1. **Characters**: Play character cards from your hand by spending Essence
2. **Actions & Items**: Support your characters with action and item cards
3. **Attack**: Use your characters to attack the opponent's characters or the opponent directly
4. **Fusion**: Combine character cards to create more powerful fusion characters
5. **Win Condition**: Reduce your opponent's characters' HP to zero

## Running the Game

### macOS Instructions

1. **Install LÖVE**:
   - Download and install LÖVE from [love2d.org](https://love2d.org)
   - Move the LÖVE.app to your Applications folder

2. **Command Line Setup** (one-time setup):
   ```
   sudo ln -s /Applications/love.app/Contents/MacOS/love /usr/local/bin/love
   ```

3. **Running the Game**:
   - Open Terminal
   - Navigate to the PD-Brawl directory
   - Run the game: `love .`

4. **Alternative Methods**:
   - Package the game: `./package.sh`
   - Run the packaged version: `love build/pd-brawl.love`
   - Or drag the `pd-brawl.love` file onto the LÖVE.app icon

### Windows Instructions

1. **Install LÖVE**:
   - Download and install LÖVE from [love2d.org](https://love2d.org)
   - Make sure LÖVE is added to your PATH during installation

2. **Running the Game**:
   - Open Command Prompt
   - Navigate to the PD-Brawl directory
   - Run the game: `love .`

3. **Alternative Methods**:
   - Create a shortcut that points to: `"C:\Program Files\LOVE\love.exe" "C:\path\to\PD-Brawl"`
   - Or drag the entire PD-Brawl folder onto love.exe

## Game Controls

- **Mouse**: Click and drag cards to interact with them
- **Drag and Drop**:
  - Drag cards from hand to field to play them
  - Drag cards from field to opponent's cards to attack
  - Drag character cards from hand onto your field characters to fuse them
- **ESC**: Quit the game
- **F**: Toggle fullscreen
- **V**: Toggle VSync (can improve performance)
- **End Turn Button**: Click to end your turn

## Game Features

- **Dynamic UI**: Fullscreen gameplay with adaptive layout
- **AI Opponent**: Challenge a computer opponent with strategic gameplay
- **Beautiful Graphics**: Starfield background, card gradients, and visual effects
- **Interactive Gameplay**: Intuitive drag and drop controls for all card actions
- **Visual Feedback**: 
  - Cards glow when selected or dragged
  - Screen shakes during attacks
  - Spectacular fusion effects with particles and explosions
  - Color highlights guide valid drag targets
- **Fourth Wall Breaking**: Characters occasionally break the fourth wall with humorous messages
- **Fusion System**: Combine characters by dragging one onto another to create more powerful versions

## Characters

The game features public domain characters such as:
- Steamboat Willie (Mickey Mouse)
- Sherlock Holmes
- Dracula
- Popeye
- and more!

## Requirements

- LÖVE 11.4 or higher
- Minimum resolution: 1280x720

## Game Concept

PD Brawl blends mechanics from popular TCGs like Pokémon TCG Pocket (simple HP values and resource management) with fusion mechanics reminiscent of Yu-Gi-Oh! The game features:

- **Public Domain Characters**: Play with famous characters that have entered the public domain, like Popeye, Steamboat Willie (original Mickey Mouse), Sherlock Holmes, and Dracula.
- **Humorous Variants**: Each character has multiple art variants, including vintage, "sexy" variants, cigar-smoking versions, and more.
- **Fourth-Wall Breaking**: Characters and cards occasionally break the fourth wall, commenting on gameplay or interacting directly with the player.

## Core Mechanics

1. **Essence Resource System**
   - Players receive 1 Essence per turn
   - Cards and abilities cost Essence to play

2. **Character Cards**
   - Each has HP values (30-200) and Power stats
   - Multiple variants with different abilities

3. **Fusion System**
   - Combine character cards with materials to create more powerful versions
   - Fusion requires specific materials and essence cost

4. **Card Types**
   - Characters: Main attackers with HP and Power
   - Actions: One-time effect cards
   - Items: Attach to characters for ongoing effects

## Project Structure

- `main.lua`: Entry point for the game
- `src/game.lua`: Core game logic
- `src/player.lua`: Player data and actions
- `src/ui.lua`: Game UI and rendering
- `src/card_types/`: Card type definitions
- `src/data/`: Game data including card database

## License

This project uses public domain characters and is available under the MIT License.

## Credits

Created as a demonstration of a digital card game using public domain characters. 