# Introduction
A Balatro example mod for adding a custom Editions in Steamodded.

Feel free to copy and use this for any of projects!

## Notes in case you can't read
**If you want an Edition to have more than one of the following:**
- mult
- chips
- x_mult

Then you will have to write the code for it yourself!

**Also as of right now, editions do NOT work with:**
- h_mult (Mult for holding in hand)
- h_x_mult (X Mult for holding in hand)

Again, you'd have to write it yourself.

## Working with Shaders
[ionized.fs](assets/shaders/ionized.fs) has shader code explanation with comments.
For a general guide, look at [LOVE2D introduction to shaders](https://blogs.love2d.org/content/beginners-guide-shaders).

If you want to see vanilla Balatro shaders, unzip the Balatro.exe and go to `resources/shaders` folder.

To see values for default externs check out `engine/sprite.lua` -> `Sprite:draw_shader`.
