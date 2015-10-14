Enums = Apps.Merchant.Enums
scope = logics.transaction
numericOption = {autoGroup: true, groupSeparator:",", radixPoint: ".", suffix: " VNĐ", integerDigits:11}

lemon.defineApp Template.transactionOverviewSection,
  rendered: ->
    @ui.$transactionAmount.inputmask("numeric", numericOption) if @ui.$transactionAmount

  helpers:
    owner: -> Session.get('transactionOwner')
    transaction: ->
      owner = Session.get('transactionOwner')
      owner = {totalCash: 0} unless owner
      transaction = Session.get('transactionDetail')
      display = _.findWhere(Enums.TransactionCustomerIncomeOrCost, {_id: transaction.incomeOrCost})?.display ? ''
      transaction.receivableDisplay = display

      if transaction.receivable
        transaction.finalDebtCash = owner.totalCash + transaction.amount
      else
        transaction.finalDebtCash = owner.totalCash - transaction.amount

      if transaction.owner and transaction.description.length > 0 and transaction.amount > 0
        Session.set('transactionCreateNewIsDisabled', '')
      else
        Session.set('transactionCreateNewIsDisabled', 'disabled')

      transaction




  events:
    "keyup input.transaction-field":  (event, template) ->
      payAmount      = parseInt($(template.find("[name='transactionAmount']")).inputmask('unmaskedvalue'))
      payDescription = template.ui.$transactionDescription.val()
      if transaction = Session.get('transactionDetail')
        transaction.amount = if !isNaN(payAmount) then Math.abs(payAmount) else 0
        transaction.description = payDescription
        Session.set('transactionDetail', transaction)
