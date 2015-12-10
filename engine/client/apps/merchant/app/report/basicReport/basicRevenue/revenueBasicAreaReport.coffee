scope = logics.basicReport
newCashGroup = -> {requiredCash: 0, beginCash: 0, incurredCash: 0, saleCash: 0, totalCash: 0}
formatMoney = (value, symbol = '', precision = 3)->
  accounting.formatMoney(value, "", precision, ".", ",") + (if symbol then ' ' + symbol else '')

lemon.defineApp Template.revenueBasicAreaReport,
  created: ->
    customerGroups = {}
    totalCash = 0
    Schema.customers.find({merchant: Merchant.getId()}).forEach(
      (customer) ->
        group = customerGroups[customer.group]
        group = customerGroups[customer.group] = newCashGroup() unless group

        requiredCash = (customer.debtRequiredCash ? 0) - (customer.paidRequiredCash ? 0)
        beginCash    = (customer.debtBeginCash ? 0) - (customer.paidBeginCash ? 0)
        incurredCash = (customer.debtIncurredCash ? 0) - (customer.paidIncurredCash ? 0)
        saleCash     = (customer.debtSaleCash ? 0) - (customer.paidSaleCash ? 0) - (customer.returnSaleCash ? 0)
        totalCash   += requiredCash + beginCash + incurredCash + saleCash

        group.requiredCash += requiredCash
        group.beginCash    += beginCash
        group.incurredCash += incurredCash
        group.saleCash     += saleCash
        group.totalCash    += requiredCash + beginCash + incurredCash + saleCash

        console.log totalCash
    )

    scope.customerGroups = []
    for groupId, data of customerGroups
      if group = Schema.customerGroups.findOne({_id: groupId})
        splitName = group.name.split('.')
        name = if splitName.length > 1 then splitName[1] ? '' else splitName[0] ? ''
        if data.requiredCash isnt 0 or data.beginCash isnt 0 or data.incurredCash isnt 0 or data.totalCash isnt 0
          scope.customerGroups.push({
            _id          : group._id
            name         : name
            requiredCash : data.requiredCash/1000000
            beginCash    : data.beginCash/1000000
            incurredCash : data.incurredCash/1000000
            saleCash     : data.saleCash/1000000
            totalCash    : data.totalCash/1000000
            totalAllCash : totalCash/1000000
          })

    scope.customerGroups = _.sortBy(scope.customerGroups, 'totalCash')

  rendered: ->
    scope.revenueBasicArea =
      c3.generate
        bindto: '#revenueBasic'
        size: height: (30*scope.customerGroups.length+55)
        data:
          json: scope.customerGroups
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
              name         = scope.customerGroups[d].name
              totalCash    = scope.customerGroups[d].totalCash ? 0
              totalAllCash = scope.customerGroups[d].totalAllCash ? 0
              cashPercent  = (totalCash*100/totalAllCash).toFixed(2)

              totalCashFormat    = formatMoney totalCash
              totalAllCashFormat = formatMoney totalAllCash
              name + ' - ' + cashPercent + '% ' + '(' + totalCashFormat + '/' + totalAllCashFormat + ')'
            value: (value, ratio, id) -> formatMoney value, 'Tr'


  destroyed: ->
    scope.revenueBasicArea.destroy()
