scope = logics.basicReport
newCashGroup = -> {requiredCash: 0, beginCash: 0, incurredCash: 0, saleCash: 0, totalCash: 0}
formatMoney = (value, symbol = '', precision = 3)->
  accounting.formatMoney(value, "", precision, ".", ",") + (if symbol then ' ' + symbol else '')

lemon.defineApp Template.revenueOfAreaReport,
  created: ->
    console.log Template.instance()
    console.log Template.currentData().customers
    scope.customerLists = []
    Schema.customers.find({group: Template.currentData()._id}).forEach(
      (customer) ->
        requiredCash = (customer.debtRequiredCash ? 0) - (customer.paidRequiredCash ? 0)
        beginCash    = (customer.debtBeginCash ? 0) - (customer.paidBeginCash ? 0)
        incurredCash = (customer.debtIncurredCash ? 0) - (customer.paidIncurredCash ? 0)
        saleCash     = (customer.debtSaleCash ? 0) - (customer.paidSaleCash ? 0) - (customer.returnSaleCash ? 0)
        totalCash    = requiredCash + beginCash + incurredCash + saleCash

        if requiredCash isnt 0 or beginCash isnt 0 or incurredCash isnt 0 or totalCash isnt 0
          scope.customerLists.push({
            _id          : customer._id
            name         : customer.name
            requiredCash : requiredCash/1000000
            beginCash    : beginCash/1000000
            incurredCash : incurredCash/1000000
            saleCash     : saleCash/1000000
            totalCash    : totalCash/1000000
            totalAllCash : Template.currentData().totalCash/1000000
          })
    )
    scope.customerLists = _.sortBy(scope.customerLists, 'totalCash')


  rendered: ->
    scope.revenueOfAreaReport =
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
              name         = scope.customerLists[d].name
              totalCash    = scope.customerLists[d].totalCash ? 0
              totalAllCash = scope.customerLists[d].totalAllCash ? 0
              cashPercent  = (totalCash*100/totalAllCash).toFixed(2)

              totalCashFormat    = formatMoney totalCash
              totalAllCashFormat = formatMoney totalAllCash
              name + ' - ' + cashPercent + '% ' + '(' + totalCashFormat + '/' + totalAllCashFormat + ')'
            value: (value, ratio, id) -> formatMoney value, 'Tr'

#    scope.revenueBasicArea =c3.generate(
#      bindto: '#revenueOfAreaReport'
#      data:
#        columns: [ ['data1', 30], ['data2', 120] ]
#        type: 'pie'
#        onclick: (d, i) ->
#          console.log 'onclick', d, i
#          return
#        onmouseover: (d, i) ->
#          console.log 'onmouseover', d, i
#          return
#        onmouseout: (d, i) ->
#          console.log 'onmouseout', d, i
#          return
#    )


  helpers:
    areaSelectOptions: -> scope.areaSelectOptions