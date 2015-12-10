scope = logics.basicHistory

lemon.defineApp Template.historySynthesisDebts,
  created: ->
    Session.set('revenueBasicAreaReportView', 'totalCash')

  helpers:
    isDisabled: -> Session.get("basicHistoryDynamics")?.name is 'customerGroup'
    sumCash : -> scope.sumCash
    customerLists: ->
      customerSearchText = Session.get('basicHistoryCustomerSearchText')
      if customerSearchText?.length > 1
        _.filter scope.customerLists, (customer) ->
          unsignedTerm = Helpers.RemoveVnSigns customerSearchText
          unsignedName = Helpers.RemoveVnSigns customer.name
          unsignedName.indexOf(unsignedTerm) > -1
      else
        []


    hasSearchCustomer: -> Session.get('basicHistoryCustomerSearchText')?.length > 0

    customerGroups: ->
      scope.sumCash =
        sumDebtRequiredCash : 0
        sumPaidRequiredCash : 0

        sumDebtBeginCash    : 0
        sumPaidBeginCash    : 0

        sumDebtIncurredCash : 0
        sumPaidIncurredCash : 0

        sumDebtSaleCash     : 0
        sumReturnSaleCash   : 0

        sumTurnoverSaleCash : 0
        sumPaidSaleCash     : 0
        sumTotalCash        : 0

        sumBeginCash    : 0
        sumDebtCash     : 0
        sumReturnCash   : 0
        sumPaidCash     : 0


      scope.customerLists = []
      console.log 'recalculation'
      Schema.customerGroups.find({},{sort: {name: 1}}).map(
        (customerGroup) ->
          customerGroup.debtRequiredCash   = 0
          customerGroup.paidRequiredCash   = 0
          customerGroup.debtBeginCash      = 0
          customerGroup.paidBeginCash      = 0
          customerGroup.debtIncurredCash   = 0
          customerGroup.paidIncurredCash   = 0
          customerGroup.debtSaleCash       = 0
          customerGroup.returnSaleCash     = 0
          customerGroup.turnoverSaleCash   = 0
          customerGroup.paidSaleCash       = 0
          customerGroup.totalCash          = 0


          customerGroup.customerDetails =
            Schema.customers.find({group: customerGroup._id},{sort: {name: 1}}).map(
              (customer) ->
                customer.debtRequiredCash  = 0 unless customer.debtRequiredCash
                customer.paidRequiredCash  = 0 unless customer.paidRequiredCash
                customer.debtBeginCash     = 0 unless customer.debtBeginCash
                customer.paidBeginCash     = 0 unless customer.paidBeginCash
                customer.debtIncurredCash  = 0 unless customer.debtIncurredCash
                customer.paidIncurredCash  = 0 unless customer.paidIncurredCash
                customer.debtSaleCash      = 0 unless customer.debtSaleCash
                customer.returnSaleCash    = 0 unless customer.returnSaleCash
                customer.paidSaleCash      = 0 unless customer.paidSaleCash

                customer.turnoverSaleCash  = customer.debtSaleCash - customer.returnSaleCash
                customer.totalCash         = customer.debtRequiredCash - customer.paidRequiredCash +
                    customer.debtBeginCash - customer.paidBeginCash + customer.debtIncurredCash - customer.paidIncurredCash +
                    customer.debtSaleCash - customer.returnSaleCash - customer.paidSaleCash


                customerGroup.debtRequiredCash += customer.debtRequiredCash
                customerGroup.paidRequiredCash += customer.paidRequiredCash
                customerGroup.debtBeginCash    += customer.debtBeginCash
                customerGroup.paidBeginCash    += customer.paidBeginCash
                customerGroup.debtIncurredCash += customer.debtIncurredCash
                customerGroup.paidIncurredCash += customer.paidIncurredCash
                customerGroup.debtSaleCash     += customer.debtSaleCash
                customerGroup.returnSaleCash   += customer.returnSaleCash
                customerGroup.turnoverSaleCash += customer.turnoverSaleCash
                customerGroup.paidSaleCash     += customer.paidSaleCash
                customerGroup.totalCash        += customer.totalCash

                scope.customerLists.push customer
                customer
            )

          cash = customerGroup.debtBeginCash
#          console.log 'group', scope.sumCash.sumDebtBeginCash, customerGroup.debtBeginCash

          scope.sumCash.sumDebtRequiredCash += customerGroup.debtRequiredCash
          scope.sumCash.sumPaidRequiredCash += customerGroup.paidRequiredCash
          scope.sumCash.sumDebtBeginCash    += customerGroup.debtBeginCash
          scope.sumCash.sumPaidBeginCash    += customerGroup.paidBeginCash
          scope.sumCash.sumDebtIncurredCash += customerGroup.debtIncurredCash
          scope.sumCash.sumPaidIncurredCash += customerGroup.paidIncurredCash
          scope.sumCash.sumDebtSaleCash     += customerGroup.debtSaleCash
          scope.sumCash.sumReturnSaleCash   += customerGroup.returnSaleCash
          scope.sumCash.sumTurnoverSaleCash += customerGroup.turnoverSaleCash
          scope.sumCash.sumPaidSaleCash     += customerGroup.paidSaleCash
          scope.sumCash.sumTotalCash        += customerGroup.totalCash


          customerGroup.sumDebtRequiredCash = scope.sumCash.sumDebtRequiredCash
          customerGroup.sumPaidRequiredCash = scope.sumCash.sumPaidRequiredCash
          customerGroup.sumDebtBeginCash    = scope.sumCash.sumDebtBeginCash
          customerGroup.sumPaidBeginCash    = scope.sumCash.sumPaidBeginCash
          customerGroup.sumDebtIncurredCash = scope.sumCash.sumDebtIncurredCash
          customerGroup.sumPaidIncurredCash = scope.sumCash.sumPaidIncurredCash
          customerGroup.sumDebtSaleCash     = scope.sumCash.sumDebtSaleCash
          customerGroup.sumReturnSaleCash   = scope.sumCash.sumReturnSaleCash
          customerGroup.sumTurnoverSaleCash = scope.sumCash.sumTurnoverSaleCash
          customerGroup.sumPaidSaleCash     = scope.sumCash.sumPaidSaleCash
          customerGroup.sumTotalCash        = scope.sumCash.sumTotalCash

          if cash
#            console.log customerGroup.name, scope.sumCash.sumDebtBeginCash , scope.sumCash.sumDebtBeginCash - customerGroup.debtBeginCash
            console.log customerGroup.name, scope.sumCash.sumTurnoverSaleCash

          customerGroup
      )

    showCustomer:  -> Session.get("basicHistoryDynamics").name is 'customer'


  events:
    "keyup input[name='searchFilter']": (event, template) ->
      Helpers.deferredAction ->
        searchFilter  = $("input[name='searchFilter']").val()
        Session.set("basicHistoryCustomerSearchText", searchFilter.replace(/(?:(?:^|\n)\s+|\s+(?:$|\n))/g,"").replace(/\s+/g," "))
      , "basicHistorySearchSearchCustomer"
      , 100

    "click label.customer": (event, template)->
      Session.set("basicHistoryDynamics", {name: 'customer',template: 'historySynthesisDebts', data: {}})

    "click label.customerGroup": (event, template)->
      Session.set("basicHistoryDynamics", {name: 'customerGroup',template: 'historySynthesisDebts', data: {}})
      Session.set("basicHistoryCustomerSearchText", '')

    "keyup input.debtRequiredCash":  (event, template) ->
      customer = @
      Helpers.deferredAction ->
        if customer
          debtRequiredCash = $("[name=#{customer._id}].debtRequiredCash").val()
          debtRequiredCash = accounting.unformat(debtRequiredCash)
          Schema.customers.update(customer._id, {$set:{debtRequiredCash: debtRequiredCash}})
      , "basicHistoryChangeDebtRequiredCash"
      , 500

    "keyup input.debtBeginCash":  (event, template) ->
      customer = @
      Helpers.deferredAction ->
        if customer
          debtBeginCash = $("[name=#{customer._id}].debtBeginCash").val()
          debtBeginCash = accounting.unformat(debtBeginCash)
          Schema.customers.update(customer?._id, {$set:{debtBeginCash: debtBeginCash}})
      , "basicHistoryChangeDebtBeginCash"
      , 500

    "click a.icon-print-6": (event, template)->
      name = 'tong_hop_cong_no_' + moment().format('MM/YYYY')
      blobURL = Apps.Merchant.tableToExcel('historyTable', 'W3C Example Table')
      $(event.target).attr 'download', name + '.xls'
      $(event.target).attr 'href', blobURL
