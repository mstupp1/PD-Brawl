# Building PD Brawl for Web Browsers

This document explains how to compile the PD Brawl game for web browsers using Emscripten.

## Prerequisites

- [Emscripten](https://emscripten.org/docs/getting_started/index.html)
- [LÖVE](https://love2d.org/) (for testing)
- [love.js](https://github.com/Davidobot/love.js) or similar LÖVE to Web compiler

## Building Process

1. **Install Emscripten**

   Follow the instructions on the [Emscripten website](https://emscripten.org/docs/getting_started/downloads.html) to install Emscripten on your system.

2. **Package the game as a .love file**

   Run the package script to create a .love file:

   ```bash
   ./package.sh
   ```

   This will create `build/pd-brawl.love`.

3. **Compile with love.js**

   Use love.js to compile the .love file to JavaScript:

   ```bash
   # Clone love.js
   git clone https://github.com/Davidobot/love.js.git
   cd love.js

   # Compile the game
   python3 love.js/package.py ../build/pd-brawl.love ../build/web

   # Or use the release version
   python3 love.js/package.py --release ../build/pd-brawl.love ../build/web
   ```

4. **Alternatively: Use LÖVE's official Web port**

   LÖVE provides an official web port called "love-webplayer":

   ```bash
   # After packaging the .love file
   cd path/to/love-webplayer
   # Follow the instructions provided by the love-webplayer project
   ```

## Deployment

After compilation, the `build/web` directory will contain all necessary files to deploy the game to a web server:

1. Upload all files in the `build/web` directory to your web server
2. Access the game via `index.html`

## Optimizations

For production use, consider the following optimizations:

- Enable compression on your web server for .js and .wasm files
- Set appropriate caching headers
- Minify the JavaScript code using a tool like UglifyJS
- Optimize the game assets (images, sounds) to reduce file size

## Troubleshooting

- If the game doesn't load, check the browser console for error messages
- Ensure that your web server is configured to serve the correct MIME types for .wasm and .js files
- Some older browsers may not support WebAssembly, consider providing fallback options

## Browser Compatibility

The game should work in modern browsers that support WebAssembly, including:

- Google Chrome 57+
- Firefox 53+
- Safari 11+
- Edge 16+

## Further Resources

- [Emscripten Documentation](https://emscripten.org/docs/index.html)
- [LÖVE Forums](https://love2d.org/forums/) - Good place to ask for help
- [LÖVE Wiki](https://love2d.org/wiki/Main_Page) - Contains useful information on LÖVE 