totalDecoratorTiles = 5 * 4
lemon.defineWidget Template.metroDecoratorTiles,
  helpers:
    randomColor: -> Helpers.RandomColor()
    decoratorIterator: ->
      array = []
      array.push i for i in [0...totalDecoratorTiles]
      array