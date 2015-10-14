logics.billDetail = {}
Apps.Merchant.billDetailInit = []
Apps.Merchant.billDetailReactiveRun = []

Apps.Merchant.billDetailInit.push (scope) ->

Apps.Merchant.billDetailReactiveRun.push (scope) ->
  if Session.get('currentBillHistory')
    scope.currentBillHistory = Schema.orders.findOne Session.get('currentBillHistory')._id
    Session.set('currentBillHistory', scope.currentBillHistory)

  if newBuyerId = Session.get('currentBillHistory')?.buyer
    if !(oldBuyerId = Session.get('currentBuyer')?._id) or oldBuyerId isnt newBuyerId
      customer = Schema.customers.findOne(newBuyerId)
      customer.totalCash = customer.calculateTotalCash()
      Session.set('currentBuyer', customer)
  else
    Session.set 'currentBuyer'
