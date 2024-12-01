# let-it-snow.nvim

A Neovim plugin written in Lua to bring winter "hygge" into your editor.

![Demo](.github/assets/demo.mp4)

## But why

Imagine this:
It is winter.
You are sitting in the evening by the fireplace and candlelight coding away.
But suddenly you get stuck on a difficult problem.
While sitting there and wondering how you will ever solve this problem, your
code is just sitting there, staring you in the face.
Wouldn't it be nice if you could bring some of the winter cozyness into your
editor?
This is the vision of `let-it-snow.nvim`.
`let-it-snow.nvim` attempts to solve this by letting it snow directly in your
editor, bringing some fluffyness into your code.

## How to run

The only function available in `let-it-snow.nvim` is `LetItSnow` which is meant
to *help bring you some "hygge" into your editor :) Oh and when the snow has
piled up too much `EndHygge` will be available to save your code from being
burried in the snow.

## Installation

```lua
{
    "marcussimonsen/let-it-snow.nvim",
    cmd = "LetItSnow", -- Wait with loading until command is run
    opts = {},
}
```
## Configuration

`let-it-snow.nvim` uses the following default values.
Use the `opts` table where you install the plugin or pass a table to the setup
function to overwrite settings.

```lua
{
	---@type integer Delay between updates
	delay = 500,
	---@type string Single character used to represent snowflakes
	snowflake_char = "\u{2744}",
	---@type string[] Array of single character used to represent snow (in order of least to most)
	snowpile_chars = {
		[1] = "\u{2581}",
		[2] = "\u{2582}",
		[3] = "\u{2583}",
		[4] = "\u{2584}",
		[5] = "\u{2585}",
		[6] = "\u{2586}",
		[7] = "\u{2587}",
		[8] = "\u{2588}",
	},
	---@type integer Max attempts at spawning a snowfile
	max_spawn_attempts = 500,
	---@type boolean Whether to create highlight groups or not
	create_highlight_groups = true,
	---@type string Name of namespace to use for extmarks (you probably don't need to change this)
	namespace = "let-it-snow",
	---@type string Name of highlight group to use for snowflakes
	highlight_group_name_snowflake = "snowflake",
	---@type string Name of highlight group to use for snowpiles
	highlight_group_name_snowpile = "snowpile",
}
```

## Inspiration

Credit where credit is due; This plugin was inspired by the following amazing
people/projects:

- [cellular-automaton.nvim](https://github.com/Eandrju/cellular-automaton.nvim)
  for bringing animations into Neovim.
- [Coding Traing Challenge 180](https://www.youtube.com/watch?v=L4u7Zy_b868) for
  physics.
- [treesj](https://github.com/Wansmer/treesj/tree/main) by
  [Wansmer](https://github.com/Wansmer) for much of the project structure and
  many helper functions.
