Enums = Apps.Merchant.Enums
logics.sales = { name: 'sale-logics' }
Apps.Merchant.salesInit = []
Apps.Merchant.salesReactiveRun = []

Apps.Merchant.salesInit.push (scope) ->
  scope.tabOptions =
    source: Order.findNotSubmitted()
    currentSource: 'currentOrder'
    caption: 'orderName'
    key: '_id'
    createAction  : -> Order.insert()
    destroyAction : (instance) -> if instance then Order.findNotSubmitted().count() if instance.remove() else -1
    navigateAction: (instance) -> Order.setSession(instance._id)

  scope.debtDateOptions =
    reactiveSetter: (val) -> scope.currentOrder.changeDueDay(val)
    reactiveValue: -> Session.get('currentOrder')?.dueDay ? 0
    reactiveMax: -> 180
    reactiveMin: -> 0
    reactiveStep: -> 30
    others:
      forcestepdivisibility: 'none'

Apps.Merchant.salesReactiveRun.push (scope) ->
  if Session.get('mySession')
    scope.currentOrder = Schema.orders.findOne({
      _id        : Session.get('mySession').currentOrder
      orderType  : Enums.getValue('OrderTypes', 'initialize')
      orderStatus: Enums.getValue('OrderStatus', 'initialize')
    })
    Session.set 'currentOrder', scope.currentOrder

  if newBuyerId = Session.get('currentOrder')?.buyer
    if !(oldBuyerId = Session.get('currentBuyer')?._id) or oldBuyerId isnt newBuyerId
      customer =  Schema.customers.findOne newBuyerId
      customer.totalCash =
        (customer.debtRequiredCash ? 0) - (customer.paidRequiredCash ? 0) +
          (customer.debtBeginCash ? 0) - (customer.paidBeginCash ? 0) +
          (customer.debtIncurredCash ? 0) - (customer.paidIncurredCash ? 0) +
          (customer.debtSaleCash ? 0) - (customer.paidSaleCash ? 0) - (customer.returnSaleCash ? 0)
      Session.set('currentBuyer', customer)
  else
    Session.set 'currentBuyer'