# letitsnow.nvim

A Neovim plugin written in Lua to bring winter "hygge" into your editor.

## But why?

Image this:
It is winter.
You are sitting in the evening by the fireplace and candlelight coding away.
But suddenly you get stuck on a difficult problem.
While sitting there and wondering how you will ever solve this problem, your
code is just sitting there, staring you in the face.
Wouldn't it be nice if you could bring some of the winter cozyness into your
editor?
This is the vision of *letitsnow.nvim*.
*letitsnow.nvim* attempts to solve this by letting it snow directly in your
editor, bringing some fluffyness into your code.

## Installation

```lua
{
    "marcussimonsen/letitsnow.nvim",
    cmd = "LetItSnow" -- Wait with loading until command is run
    opts = {},
}
```

## How to run

The only function available in *letitsnow.nvim* is `LetItSnow` which is meant to
*help bring you some "hygge" into your editor :)

## Inspiration:

This plugin was inspired by the following amazing people:

- [cellular-automaton.nvim](https://github.com/Eandrju/cellular-automaton.nvim)
  for bringing animations into Neovim.
- [Coding Traing Challenge 180](https://www.youtube.com/watch?v=L4u7Zy_b868)
  for physics.
