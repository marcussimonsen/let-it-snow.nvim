# let-it-snow.nvim

A Neovim plugin written in Lua to bring winter "hygge" into your editor.

<!-- TODO: Add video/gif of example -->

## But why?

Image this:
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

## Installation

```lua
{
    "marcussimonsen/let-it-snow.nvim",
    cmd = "LetItSnow", -- Wait with loading until command is run
    opts = {},
}
```

## How to run

The only function available in `let-it-snow.nvim` is `LetItSnow` which is meant
to *help bring you some "hygge" into your editor :) Oh and when the snow has
piled up too much `EndHygge` will be available to save your code from being
burried in the snow.

## Inspiration:

Credit where credit is due; This plugin was inspired by the following amazing
people/projects:

- [cellular-automaton.nvim](https://github.com/Eandrju/cellular-automaton.nvim)
  for bringing animations into Neovim.
- [Coding Traing Challenge 180](https://www.youtube.com/watch?v=L4u7Zy_b868) for
  physics.
- [treesj](https://github.com/Wansmer/treesj/tree/main) by
  [Wansmer](https://github.com/Wansmer) for much of the project structure and
  many helper functions.
