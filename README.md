# conflict-juggler.nvim

This project took inspiration from the VSCode extension [Conflict Squeezer](https://github.com/angelo-mollame/conflict-squeezer).

Over the years working with Git, I've had to resolve many merge conflicts. When I used VSCode, the [Conflict Squeezer extension](https://marketplace.visualstudio.com/items?itemName=angelomollame.conflict-squeezer) saved me a lot of time on the more challenging merge conflicts. After moving on to Neovim, I started missing this functionality so much that I decided to rewrite it. One late night later and a bit less hair on my head, here it is!

## Features

This plugin creates a command called `ConflictJuggler` that:

- Scans the current buffer and removes the conflict markers when both sides of the conflict are the same.

- Simplifies the conflict when the start or the end are the same, moving the matching lines out of the block.

- Supports nested conflict markers (WOW! 🤩)

## Installation

You can install this plugin with the plugin manager of your choice. Here are a few examples:

### Lazy

```lua
{ 'pv-hernandez/conflict-juggler.nvim' }
```

### Plug

```vim
Plug 'pv-hernandez/conflict-juggler.nvim'
```

If you like this plugin, don't forget to share it with others!

