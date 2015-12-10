scope = logics.basicReport
Enums = Apps.Merchant.Enums
formatMoney = (value, symbol = '', precision = 3)->
  accounting.formatMoney(value, "", precision, ".", ",") + (if symbol then ' ' + symbol else '')
getCustomer = -> scope.customers
renderChart = (group)->
  scope.customerLists = []
  for customer in Schema.customers.find({group: group._id}).fetch()
    requiredCash = (customer.debtRequiredCash ? 0) - (customer.paidRequiredCash ? 0)
    beginCash    = (customer.debtBeginCash ? 0) - (customer.paidBeginCash ? 0)
    incurredCash = (customer.debtIncurredCash ? 0) - (customer.paidIncurredCash ? 0)
    saleCash     = (customer.debtSaleCash ? 0) - (customer.paidSaleCash ? 0) - (customer.returnSaleCash ? 0)
    totalCash    = requiredCash + beginCash + incurredCash + saleCash

    if requiredCash isnt 0 or beginCash isnt 0 or incurredCash isnt 0 or totalCash isnt 0
      console.log customer
      scope.customerLists.push({
        _id          : customer._id
        name         : customer.name
        requiredCash : requiredCash/1000000
        beginCash    : beginCash/1000000
        incurredCash : incurredCash/1000000
        saleCash     : saleCash/1000000
        totalCash    : totalCash/1000000
        totalAllCash : group.totalCash/1000000
      })

  scope.customerLists = _.sortBy(scope.customerLists, 'totalCash')
  console.log scope.customerLists


  c3.generate
    bindto: '#revenueOfAreaReport'
    size:
      height: (30*scope.customerLists.length+55)

    data:
      json: scope.customerLists
      names:
        requiredCash: 'Nợ Phải Thu'
        beginCash   : 'Nợ Đầu Kỳ'
        incurredCash: 'Phát Sinh Khác'
        saleCash    : 'Bán Hàng'
      groups: [['requiredCash'
                'beginCash'
                'incurredCash'
                'saleCash']]
      keys:
        x: 'name'
        value: ['requiredCash'
                'beginCash'
                'incurredCash'
                'saleCash']
      colors:
        requiredCash: '#c0392b'
        beginCash   : '#e67e22'
        incurredCash: '#1abc9c'
        saleCash    : '#2e8bcc'

      type: 'bar'
      labels:
        format:
          requiredCash: (value, id, i, j)-> if value isnt 0 then formatMoney(value, 'Tr') else ''
          beginCash   : (value, id, i, j)-> if value isnt 0 then formatMoney(value, 'Tr') else ''
          incurredCash: (value, id, i, j)-> if value isnt 0 then formatMoney(value, 'Tr') else ''
          saleCash    : (value, id, i, j)-> if value isnt 0 then formatMoney(value, 'Tr') else ''

    axis:
      rotated: true
      x: type: 'category'

    tooltip:
      format:
        title: (d) ->
          console.log d
          name         = scope.customerLists[d].name
          totalCash    = scope.customerLists[d].totalCash ? 0
          totalAllCash = scope.customerLists[d].totalAllCash ? 0
          cashPercent  = (totalCash*100/totalAllCash).toFixed(2)

          totalCashFormat    = formatMoney totalCash
          totalAllCashFormat = formatMoney totalAllCash
          name + ' - ' + cashPercent + '% ' + '(' + totalCashFormat + '/' + totalAllCashFormat + ')'
        value: (value, ratio, id) -> formatMoney value, 'Tr'


Apps.Merchant.basicReportInit.push (scope) ->
  scope.areaSelectOptions =
    query: (query) -> query.callback
      results: customerGroupSearch(query)
      text: 'name'
    initSelection: (element, callback) -> callback Session.get("basicReportDynamics").data
    formatSelection: formatCustomerGroupSearch
    formatResult: formatCustomerGroupSearch
    id: '_id'
    placeholder: 'CHỌN KHU VỰC'
    changeAction: (e) ->
      basicReport      = Session.get("basicReportDynamics")
      basicReport.data = e.added
      Session.set("basicReportDynamics", basicReport)
      renderChart(basicReport.data)

    reactiveValueGetter: -> Session.get("basicReportDynamics").data

formatCustomerGroupSearch = (item) -> "#{item.name}" if item
customerGroupSearch = (query) ->
  selector = {merchant: Merchant.getId(), totalCash: {$gt: 0}}; options = {sort: {nameSearch: 1}}
  if(query.term)
    regExp = Helpers.BuildRegExp(query.term);
    selector = {$or: [
      {nameSearch: regExp, merchant: Merchant.getId(), totalCash: {$gt: 0}}
    ]}
  Schema.customerGroups.find(selector, options).fetch()

Apps.Merchant.basicReportInit.push (scope) ->
  scope.customerSelectOptions =
    query: (query) -> query.callback
      results: customerSearch(query)
      text: 'name'
    initSelection: (element, callback) -> callback Session.get("basicReportDynamics").data
    formatSelection: formatCustomerSearch
    formatResult: formatCustomerSearch
    id: '_id'
    placeholder: 'CHỌN KHÁCH HÀNG'
    changeAction: (e) ->
      basicReport      = Session.get("basicReportDynamics")
      basicReport.data = e.added
      Session.set("basicReportDynamics", basicReport)
#      d3.select('#productOfCustomer')
#      .datum(logics.basicReport.products)
#      .transition().duration(500)
#      .call(logics.basicReport.productOfCustomer)
    reactiveValueGetter: -> Session.get("basicReportDynamics").data

formatCustomerSearch = (item) -> "#{item.name}" if item
customerSearch = (query) ->
  selector = {merchant: Merchant.getId(), debtCash: {$gt: 0}}; options = {sort: {nameSearch: 1}}
  if(query.term)
    regExp = Helpers.BuildRegExp(query.term);
    selector = {$or: [
      {nameSearch: regExp, merchant: Merchant.getId(), debtCash: {$gt: 0}}
    ]}
  Schema.customers.find(selector, options).fetch()
