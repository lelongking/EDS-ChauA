scope = logics.priceBook

lemon.defineHyper Template.priceBookDetailProvider,
  helpers:
    selectAll: ->
      if priceBook = scope.currentPriceBook
        checkProductSelect = priceBook.products.length is Session.get('mySession').productUnitSelected?[priceBook._id].length
      if priceBook?.products.length > 0 and checkProductSelect then '#2e8bcc' else '#d8d8d8'
        
    isPriceBookType: (bookType)->
      priceType = Session.get("currentPriceBook").priceBookType
      return true if bookType is 'default' and priceType is 0
      return true if bookType is 'customer' and (priceType is 1 or priceType is 2)
      return true if bookType is 'provider' and (priceType is 3 or priceType is 4)

    allProductUnits: ->
      scope.findAllProductUnits(@)

    productSelected: ->
      if _.contains(Session.get("priceProductLists"), @_id) then 'selected' else ''

  events:
    "click .detail-row:not(.selected) td.command": (event, template) ->
      scope.currentPriceBook.selectedPriceProduct(@_id)

    "click .detail-row.selected td.command": (event, template) ->
      scope.currentPriceBook.unSelectedPriceProduct(@_id)

#    "click .detail-row": (event, template) ->Session.set("editingId", @_id); event.stopPropagation()

