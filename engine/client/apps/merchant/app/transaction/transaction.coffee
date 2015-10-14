Enums = Apps.Merchant.Enums
scope = logics.transaction


formatDefaultSearch  = (item) -> "#{item.display}" if item
formatCustomerSearch = (item) -> "#{item.name}" if item

customerSearch = (textSearch) ->
  transaction = Session.get('transactionDetail')
  return [] unless transaction

  selector = merchant: Merchant.getId(); options = {sort: {nameSearch: 1}}
  if(textSearch)
    regExp = Helpers.BuildRegExp(textSearch);
    selector = {$or: [
      {nameSearch: regExp, merchant: Merchant.getId()}
    ]}
  scope.customerList = Schema.customers.find(selector, options).fetch()
  scope.customerList

findTransactionReceivable = (receivable) ->
  _.findWhere(Enums.TransactionCustomerIncomeOrCost, {_id: receivable})

findTransactionOwner = (ownerId)->
  _.findWhere(scope.customerList, {_id: ownerId})


lemon.defineApp Template.transaction,
  created: ->
    Session.get('transactionShowHistory', false)
    Session.set('transactionDetail',
      transactionGroup: Enums.getValue('TransactionGroups', 'customer')
      transactionType: Enums.getValue('TransactionTypes', 'saleCash')
      incomeOrCost: Enums.getValue('TransactionCustomerIncomeOrCost', 'saleCash')
      receivable: false
      amount: 0
      description: ''
    )

  helpers:
    isShowHistory: -> Session.get('transactionShowHistory')

    customerSelectOptions:
      query: (query) -> query.callback
        results: customerSearch(query.term)
        text: 'name'
      initSelection: (element, callback) -> callback findTransactionOwner(Session.get('transactionDetail')?.owner)
      formatSelection: formatCustomerSearch
      formatResult: formatCustomerSearch
      id: '_id'
      placeholder: 'chọn khách hàng'
      changeAction: (e) ->
        if e.added
          newTransaction = Session.get('transactionDetail')
          newTransaction.owner = e.added._id
          Session.set('transactionDetail', newTransaction)
      reactiveValueGetter: -> Session.get('transactionDetail')?.owner ? 'skyReset'

    customerIncomeOrCostSelectOptions:
      query: (query) -> query.callback
        results: Enums.TransactionCustomerIncomeOrCost
        text: '_id'
      initSelection: (element, callback) -> callback findTransactionReceivable(Session.get('transactionDetail')?.incomeOrCost)
      formatSelection: (item)-> formatDefaultSearch(item)
      formatResult: (item)-> formatDefaultSearch(item)
      placeholder: 'LOẠI PHIẾU'
      minimumResultsForSearch: -1
      changeAction: (e) ->
        if e.added
          console.log e.added
          newTransaction = Session.get('transactionDetail')
          newTransaction.incomeOrCost = e.added._id
          if newTransaction.incomeOrCost is 0
            newTransaction.transactionType = Enums.getValue('TransactionTypes', 'requiredCash')
            newTransaction.receivable      = false
          else if newTransaction.incomeOrCost is 1
            newTransaction.transactionType = Enums.getValue('TransactionTypes', 'beginCash')
            newTransaction.receivable      = false
          else if newTransaction.incomeOrCost is 2
            newTransaction.transactionType = Enums.getValue('TransactionTypes', 'saleCash')
            newTransaction.receivable      = false
          else if newTransaction.incomeOrCost is 3
            newTransaction.transactionType = Enums.getValue('TransactionTypes', 'incurredCash')
            newTransaction.receivable      = false
          else if newTransaction.incomeOrCost is 4
            newTransaction.transactionType = Enums.getValue('TransactionTypes', 'incurredCash')
            newTransaction.receivable      = true


          Session.set('transactionDetail', newTransaction)
      reactiveValueGetter: -> findTransactionReceivable(Session.get('transactionDetail')?.incomeOrCost)

  events:
    "click .createTransaction":  (event, template) ->
      $payDescription = template.ui.$transactionDescription
      $payAmount      = template.ui.$transactionAmount
      transaction     = Session.get('transactionDetail')

      if transaction.transactionType isnt undefined and
        transaction.receivable isnt undefined and
        transaction.owner and
        transaction.amount > 0 and
        transaction.description.length > 0

          Meteor.call(
            'createNewTransaction'
            Enums.getValue('TransactionGroups', 'customer')
            transaction.transactionType
            transaction.receivable

            transaction.owner
            transaction.amount
            transaction.description
            (error, result) -> console.log error, result
          )

          $payDescription.val(''); $payAmount.val('')
          transaction.amount = 0
          Session.set('transactionDetail', transaction)