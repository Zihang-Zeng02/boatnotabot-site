# Boat's Forest

This a [forest](https://boatnotabot.com) for my notes.

## Build & Development

The site is built using [Forester](https://www.forester-notes.org/index/index.xml).

### Local Workflow

#### Standard Procedure
1. **Build**: `forester build forest/forest.toml`
2. **Preview**: `python3 -m http.server 1313 -d forest/output`

#### Automation Scripts
I have created some scripts for my personal use.
* **Build**: `./build.sh`
    * Clean the output directory `forest/output/`
    * Build the forest and pre-renders XML to HTML for cross-browser compatibility
* **Preview**: `./preview.sh [port]`
    * Trigger a full build and launches a local server (default port 8080) to serve the output
* **Deploy**: `./deploy.sh`
    * Push the output directory `forest/output/` to `deploy` branch
