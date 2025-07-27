# Balatro Mod Menu & Downloader

This project provides an in-game mod manager for **Balatro**. It adds a new
"Mod Menu" button inside the main menu that lets players download, install and
update mods directly from within the game.

The mod menu is written in Lua and built using ImGui. It relies on
LuaSocket for network requests and `dkjson` for JSON parsing. Git must be
available on the user's system in order for mods to be cloned or updated.

## Features

- Fetches a remote `mod_index.json` containing a list of available mods.
- Displays each mod with its name, description and install/update button.
- Clones mods from their GitHub repositories into the game's `Mods` folder.
- Uses `git pull` to update existing mods.
- Reads each mod's `mod.json` to show installed version information.

## Files

- `src/mod_menu.lua` – main implementation of the mod manager UI and logic.

## Usage

Integrate `mod_menu.lua` into a Balatro modding environment that supports
ImGui and LuaSocket. Call `ModMenu.fetch_index()` on startup and render the UI
via `ModMenu.draw()`.

`ModMenu.fetch_index()` will attempt to download the index specified by
`ModMenu.index_url`. If that fails, it falls back to loading the local
`mod_index.json` that ships with this repository.


The local index file is looked up relative to the directory containing
`mod_menu.lua`, so you can package it alongside the script when integrating
with your mod loader.
=======



The exact integration steps depend on the loader (SteamODD/Lovely) used by
Balatro. See the comments in `mod_menu.lua` for details.

### Lovely integration example

For Lovely-based loaders you can create a `lovely.toml` manifest to inject the
script early during startup:



Add another patch to insert a button into `functions/UI_definitions.lua` next to
the "Collection" button. When the button is pressed call `ModMenu.toggle()` and
invoke `ModMenu.draw()` each frame so the window can appear.

