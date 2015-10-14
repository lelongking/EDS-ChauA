Enums = Apps.Merchant.Enums
logics.transaction = {}
Apps.Merchant.transactionInit = []
Apps.Merchant.transactionReactive = []

Apps.Merchant.transactionReactive.push (scope) ->
  transaction = Session.get('transactionDetail')
  if transaction?.owner
    owner = Schema.customers.findOne(transaction.owner)
    owner.requiredCash = (owner.debtRequiredCash ? 0) - (owner.paidRequiredCash ? 0)
    owner.beginCash    = (owner.debtBeginCash ? 0) - (owner.paidBeginCash ? 0)
    owner.saleCash     = (owner.debtSaleCash ? 0) - (owner.paidSaleCash ? 0) - (owner.returnSaleCash ? 0)
    owner.incurredCash = (owner.debtIncurredCash ? 0) - (owner.paidIncurredCash ? 0)
    owner.totalCash    = owner.requiredCash + owner.beginCash + owner.saleCash + owner.incurredCash
    Session.set('transactionOwner', owner)

Apps.Merchant.transactionInit.push (scope) ->