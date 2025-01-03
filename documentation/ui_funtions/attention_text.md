## attention_text(args[^1])
Creates a pop up text at a given location and offset. The behaviour of the text backdrop is dictated by if the anchor is set with `major`, which creates effects similar to score cards, or with `cover`, which creates effects similar to earning money.

located in: Balatro

### Example usage
`attention_text` using `cover`:
```lua
attention_text({
    text = "x2",
    scale = 0.8, 
    hold = 1,
    cover = G.hand_text_area.mult.parent,
    cover_colour = mix_colours(G.C.MULT, col, 0.1),
    emboss = 0.05,
    align = 'cm',
    cover_align = 'cl'
})
```

`attention_text` using `major`:
```lua
attention_text({
    scale = 0.9, 
    text = "lorem ipsum", 
    hold = 0.9, 
    align = 'tm',
    major = G.play, 
    offset = {x = 0, y = -1}
})
```

TODO: add gifs for each example

[^1]:
    | key  | type | description |
    | ------------- | ------------- | ------------- |
    | text | string | The text to display on screen. |
    | scale | number | The scale of the text to display, defaults to `1`. |
    | colour | table | The colour of the displayed text, defaults to `G.C.WHITE`. |
    | hold | number | The time the text should be displayed on screen before going away, defaults to `0`. |
    | align | string | The alignment the text should follow. |
    | offset | table | The local offset to the primary position (dictated by either `cover` or `major`) of the text, defaults to `{x = 0, y =0}`. |
    | major | table | The anchoring point that will be used for the global transformation of the text. |
    | cover | (node) table | The UI element that will be used for the global transformation of the text. |
    | emboss | number | The size of the embossing of the cover box, giving it the illusion of being 3 dimensional. defaults to `0`. |
    | cover_colour | table | The colour of the box that will be covering the `cover` element, defaults to `G.C.RED`. If no `cover` argument is set in the table, this argument does not have any effect. |
    | cover_padding | number | The padding space around the text inside of the cover box, defaults to `0`. |
    | cover_align | string | The alignment the cover should follow. |
    | backdrop_colour | table | The colour of the backdrop box particle. |
