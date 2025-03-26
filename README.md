# PD Brawl - Public Domain Trading Card Game

A digital Trading Card Game (TCG) built with LÖVE2D that features public domain characters in a humorous, fourth-wall-breaking setting.

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

## How to Play

1. **Setup**
   - Each player starts with a deck of 20 cards
   - Draw 5 cards initially

2. **Turn Structure**
   - Gain 1 Essence at start of turn
   - Play cards from hand (Character, Action, Item)
   - Attack opponent's characters
   - Fuse characters (if conditions met)
   - End turn

3. **Victory Conditions**
   - Defeat 3 of your opponent's characters to win

## Controls

- **Mouse**: Click cards to select, click targets to attack or apply effects
- **Space**: End turn
- **F**: Activate fusion (when a field card is selected)

## Technical Requirements

- [LÖVE2D](https://love2d.org/) 11.4 or higher

## Running the Game

1. Install LÖVE2D from [love2d.org](https://love2d.org/)
2. Download this repository
3. Run using one of these methods:
   - Drag the folder onto the LÖVE2D shortcut
   - Use command line: `love path/to/PD-Brawl`

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