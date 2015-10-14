scope = logics.customerManagement
numericOption = {autoGroup: true, groupSeparator:",", radixPoint: ".", suffix: " VNĐ", integerDigits:11}

lemon.defineHyper Template.customerManagementSalesHistorySection,
  helpers:
    isDelete: -> moment().diff(@version.createdAt ? new Date(), 'days') < 1
    allSales: -> logics.customerManagement.findAllOrders()
    oldDebts: -> logics.customerManagement.findOldDebtCustomer()
    debitTransaction: ->


    hasOldDebts: -> logics.customerManagement.findOldDebtCustomer().length > 0

    hasDebitBegin: ->
      if @model is "customers"
        (@debtRequiredCash ? 0) + (@debtBeginCash ? 0) isnt 0
      else if Template.parentData()?.model is "customers"
        (Template.parentData().debtRequiredCash ? 0) + (Template.parentData().debtBeginCash ? 0) + (@balanceBefore ? 0) isnt 0



    sumBeforeBalance: ->
      (Template.parentData().debtRequiredCash ? 0) + (Template.parentData().debtBeginCash ? 0) + @balanceBefore ? 0

    sumLatestBalance: ->
      (Template.parentData().debtRequiredCash ? 0) + (Template.parentData().debtBeginCash ? 0) + @balanceLatest ? 0

    sumRequiredAndBeginDebtCash: ->
      if @model is "customers"
        (@debtRequiredCash ? 0) + (@debtBeginCash ? 0)
      else if Template.parentData()?.model is "customers"
        (Template.parentData().debtRequiredCash ? 0) + (Template.parentData().debtBeginCash ? 0)

    totalPaidCash: ->
      if customer = Session.get('customerManagementCurrentCustomer')
        (unless customer.paidRequiredCash is undefined then customer.paidRequiredCash else 0) +
          (unless customer.paidBeginCash is undefined then customer.paidBeginCash else 0) +
          (unless customer.paidSaleCash is undefined then customer.paidSaleCash else 0)
      else 0

    totalCash: ->
      if customer = Session.get('customerManagementCurrentCustomer')
        (unless customer.debtRequiredCash is undefined then customer.debtRequiredCash else 0) +
          (unless customer.debtBeginCash is undefined then customer.debtBeginCash else 0) +
          (unless customer.debtIncurredCash is undefined then customer.debtIncurredCash else 0) +
          (unless customer.debtSaleCash is undefined then customer.debtSaleCash else 0) -
          (unless customer.paidRequiredCash is undefined then customer.paidRequiredCash else 0) -
          (unless customer.paidBeginCash is undefined then customer.paidBeginCash else 0) -
          (unless customer.paidIncurredCash is undefined then customer.paidIncurredCash else 0) -
          (unless customer.paidSaleCash is undefined then customer.paidSaleCash else 0) -
          (unless customer.returnSaleCash is undefined then customer.returnSaleCash else 0)
      else 0


    transactionDescription: -> if Session.get("customerManagementOldDebt") then 'ghi chú nợ tiền' else 'ghi chú trả tiền'
    transactionStatus: -> if Session.get("customerManagementOldDebt") then 'Nợ Tiền' else 'Trả Tiền'
    showTransaction: -> if Session.get("customerManagementOldDebt") is undefined then 'display: none'



  rendered: ->
    Session.get("customerManagementOldDebt")
    @ui.$paySaleAmount.inputmask("numeric", numericOption) if @ui.$paySaleAmount

  events:
    "keyup input.transaction-field":  (event, template) ->
      scope.checkAllowCreateAndCreateTransaction(event, template)

    "click .deleteTransaction": (event, template) ->
      Meteor.call 'deleteNewTransaction', @_id
      event.stopPropagation()

    "click .createTransaction": (event, template) ->
      scope.createTransactionOfCustomer(event, template)
