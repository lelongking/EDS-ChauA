Enums = Apps.Merchant.Enums
lemon.defineApp Template.orderManagerNavigationPartial,
  helpers:
    showOrder: -> Session.get('orderManagerShowOrder') ? {isFinish: true}

  events:
    "click .showOrderAll": (event, template) ->
      Session.set('orderManagerShowOrder', {isFinish: false})

    "click .showOrderFinish": (event, template) ->
      Session.set('orderManagerShowOrder', {isFinish: true})