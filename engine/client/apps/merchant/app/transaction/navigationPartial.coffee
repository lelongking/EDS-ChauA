Enums = Apps.Merchant.Enums
lemon.defineApp Template.transactionNavigationPartial,
  helpers:
    isShowHistory: -> Session.get('transactionShowHistory')

  events:
    "click .transactionCreateNew": (event, template) ->
      Session.set('transactionShowHistory', false)

    "click .transactionHistories": (event, template) ->
      Session.set('transactionShowHistory', true)