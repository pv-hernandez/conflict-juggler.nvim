# conflict-juggler.nvim

This project took inspiration from the VSCode extension [Conflict Squeezer](https://github.com/angelo-mollame/conflict-squeezer).

Over the years working with Git, I've had to resolve many merge conflicts.  When I used VSCode, the [Conflict Squeezer extension](https://marketplace.visualstudio.com/items?itemName=angelomollame.conflict-squeezer) saved me a lot of time on the more challenging merge conflicts.  After moving on to Neovim, I started missing this functionality so much that I decided to rewrite it.  One late night later and a bit less hair on my head, here it is!

## Features

This plugin creates a command called `ConflictJuggler` that:

- Scans the current buffer and removes the conflict markers when both sides of the conflict are the same.

- Simplifies the conflict when the start or the end are the same, moving the matching lines out of the block.

- Supports nested conflict markers (WOW! 🤩)

## Installation

You can install this plugin with the plugin manager of your choice.  Here are a few examples:

### Lazy

```lua
{ 'pv-hernandez/conflict-juggler.nvim' }
```

### Plug

```vim
Plug 'pv-hernandez/conflict-juggler.nvim'
```

## Usage

To use this plugin you just need to run the command `:ConflictJuggler` on a buffer with conflict markers.  The conflict block will get simplified.

The conflict below:

```
<<<<<<< HEAD
aaa
bbb
=======
bbb
>>>>>>> remote
```

Becomes:

```
<<<<<<< HEAD
aaa
=======
>>>>>>> remote
bbb
```

The strategy is to make both sides of the conflict match so that the lines get moved by the plugin.  So say we want the final file to have the "aaa" line.  We add that line to the "remote" part of the conflict:


```
<<<<<<< HEAD
aaa
=======
aaa
>>>>>>> remote
bbb
```

And run the command again:

```
aaa
bbb
```

This is a small example but it get really useful when the conflict blocks span tens or hundreds of lines, most of them are the same with indentation changes or some other small change that is hard to spot quickly.

## Real world example

A Flutter project is an example of code base where this kind of conflict happens frequently, because of the amount of nested objects you create.  In this example one change added a Theme around the widget tree, and another change added a Column around the widget tree.  The entire tree got indented by a different amount in each change, so the conflict block spans the entire build method:

```dart
Widget build(BuildContext context) {
<<<<<<< HEAD
    return Theme(
        data: ...,
        child: A(
            child: B(
                children: [
                    C(),
                    // Many items
                    C(),
                ],
            ),
        ),
|||||||
    return A(
        child: B(
            children: [
                C(),
                // Many items
                C(),
            ],
        ),
=======
    return Column(
        children: [
            A(
                child: B(
                    children: [
                        C(),
                        // Many items
                        C(),
                    ],
                ),
            ),
        ],
>>>>>>> remote
    );
}
```

It is difficult to know if there are more changes in the middle of the widget tree by just looking at the conflict block, so we make the start and the end of the changes the same and run the command `:ConflictJuggler`:

```dart
Widget build(BuildContext context) {
<<<<<<< HEAD
    return Theme(
        data: ...,
        child: Column(
            children: [
                A(
                    child: B(
                        children: [
                            C(),
                            // Many items
                            C(),
                        ],
                    ),
                ),
            ],
        ),
|||||||
    return A(
        child: B(
            children: [
                C(),
                // Many items
                C(),
            ],
        ),
=======
    return Theme(
        data: ...,
        child: Column(
            children: [
                A(
                    child: B(
                        children: [
                            C(),
                            // Many items
                            C(),
                        ],
                    ),
                ),
            ],
        ),
>>>>>>> remote
    );
}
```

```dart
Widget build(BuildContext context) {
    return Theme(
        data: ...,
        child: Column(
            children: [
                A(
                    child: B(
                        children: [
                            C(),
<<<<<<< HEAD
                            // Many items
|||||||
    return A(
        child: B(
            children: [
                C(),
                // Many items
                C(),
            ],
        ),
=======
                            // Many items
>>>>>>> remote
                            C(),
                        ],
                    ),
                ),
            ],
        ),
    );
}
```

The conflict makers move closer together, around one part of the widget tree that is different between both sides.  Now you can keep making both sides match and running the command until the conflict is gone.

This process avoids missing on small changes in the middle of the conflict block.

If you like this plugin, don't forget to share it with others!

