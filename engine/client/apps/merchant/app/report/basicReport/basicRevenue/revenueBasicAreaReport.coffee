scope = logics.basicReport
newCashGroup = {requiredCash: 0, beginCash: 0, incurredCash: 0, saleCash: 0, totalCash: 0}

lemon.defineApp Template.revenueBasicAreaReport,
  created: ->
    Session.set('revenueBasicAreaReportView', 'totalCash')
    scope.dataView =
      x: ['x']
      totalCash: 0
      debtCash: 0
      beginCash: 0
      dataTotalCash :['data1']
      dataDebtCash  :['data2']
      dataBeginCash :['data3']

    customerGroups = {}
    totalCash = 0
    Schema.customers.find({merchant: Merchant.getId()}).forEach(
      (customer) ->
        group = customerGroups[customer.group]
        group = customerGroups[customer.group] = new newCashGroup unless group

        group.requiredCash += (customer.debtRequiredCash ? 0) - (customer.paidRequiredCash ? 0)
        group.beginCash    += (customer.debtBeginCash ? 0) - (customer.paidBeginCash ? 0)
        group.incurredCash += (customer.debtIncurredCash ? 0) - (customer.paidIncurredCash ? 0)
        group.saleCash     += (customer.debtSaleCash ? 0) - (customer.paidSaleCash ? 0) - (customer.returnSaleCash ? 0)
        group.totalCash    += group.requiredCash + group.beginCash + group.incurredCash + group.saleCash
        totalCash          += group.totalCash
    )

    scope.customerGroups = []
    for groupId, data of customerGroups
      if group = Schema.customerGroups.findOne({_id: groupId})
        splitName = group.name.split('.')
        name = if splitName.length > 1 then splitName[1] ? '' else splitName[0] ? ''
        scope.customerGroups.push({
          _id           : group._id
          name          : name
          requiredCash  : data.requiredCash
          beginCash     : data.beginCash
          incurredCash  : data.incurredCash
          saleCash      : data.saleCash
          totalCash     : data.totalCash
        })

    console.log scope.customerGroups

#    scope.customerGroups = Schema.customerGroups.find({totalCash: {$gt: 0}},{sort: {totalCash: 1}}).map(
#      (group) ->
#        scope.dataView.x.push(group.name)
#        group.requiredCash = 0
#        group.beginCash    = 0
#        group.incurredCash = 0
#        group.saleCash     = 0
#
#        group.debtCash  = 0
#        Schema.customers.find(group: group._id).forEach(
#          (customer)->
#            group.requiredCash += (customer.debtRequiredCash ? 0) - (customer.paidRequiredCash ? 0)
#            group.beginCash    += (customer.debtBeginCash ? 0) - (customer.paidBeginCash ? 0)
#            group.incurredCash += (customer.debtIncurredCash ? 0) - (customer.paidIncurredCash ? 0)
#            group.saleCash     += (customer.debtSaleCash ? 0) - (customer.paidSaleCash ? 0) - (customer.returnSaleCash ? 0)
#
#          group.beginCash += ( +
#                )/1000000
#            group.debtCash  += ( +
#                )/1000000
#        )
#        scope.dataView.totalCash += Math.round(group.debtCash + group.beginCash)
#        scope.dataView.debtCash  += Math.round(group.debtCash)
#        scope.dataView.beginCash += Math.round(group.beginCash)
#
#        scope.dataView.dataTotalCash.push(Math.round(group.debtCash + group.beginCash))
#        scope.dataView.dataDebtCash.push(Math.round(group.debtCash))
#        scope.dataView.dataBeginCash.push(Math.round(group.beginCash))
#
#        splitName = group.name.split('.')
#        if splitName.length > 1
#          group.name = splitName[1]
#        else
#          group.name = splitName[0]
#
#        group
#    )

  rendered: ->
    scope.revenueBasicArea =
      c3.generate
        bindto: '#revenueBasic'
        size: height: (30*scope.customerGroups.length)
        data:
          json: scope.customerGroups
#          names:
#            beginCash: 'Nợ Đầu Kỳ '
#            debtCash: 'Phát Sinh'
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
          type: 'bar'
        axis:
          rotated: true
          x: type: 'category'
        tooltip:
          format:
#            title: (d) ->
#              'Data ' + d
            value: (value, ratio, id) ->
              if id is "requiredCash"
                parseFloat(value.toFixed(2)) + ' Tr'
              else if id is "beginCash"
                parseFloat(value.toFixed(2)) + ' Tr'

#        data:
#          x: 'x'
#          columns: [
#            scope.dataView.x
#            scope.dataView.dataTotalCash
#          ]
#          names: {
#            data1: 'Tổng Doanh Số'
#            data2: 'Doanh Số'
#            data3: 'Nợ Củ'
#          }
#          type: 'bar'
#          labels:
#            format:
#              data1: (v, id, i, j)-> v + ' Tr'
#              data2: (v, id, i, j)-> v + ' Tr'
#              data3: (v, id, i, j)-> v + ' Tr'
#
#        axis:
#          x: type: 'category'
#          rotated: true
#        legend: show: false
#        tooltip:
#          format:
##            title: (d) ->
##              'Data ' + d
#            value: (value, ratio, id) ->
#              if id is "data1"
#                parseFloat(value*100/scope.dataView.totalCash).toFixed(2) + ' %'
#              else if id is "data2"
#                parseFloat(value*100/scope.dataView.debtCash).toFixed(2) + ' %'
#              else if id is "data3"
#                parseFloat(value*100/scope.dataView.beginCash).toFixed(2) + ' %'


  destroyed: ->
    logics.basicReport.revenueBasicArea.destroy()

  helpers:
    isActive: (show)->
      'active' if Session.get('revenueBasicAreaReportView') is show


  events:
    "click .showTotalCash": (event, template) ->
      Session.set('revenueBasicAreaReportView', 'totalCash')
      logics.basicReport.revenueBasicArea.unload({ids: ['data2', 'data3']})
      setTimeout (->
        logics.basicReport.revenueBasicArea.load({columns: [logics.basicReport.dataView.dataTotalCash]})
        return
      ), 300



    "click .showDebtCash": (event, template) ->
      Session.set('revenueBasicAreaReportView', 'debtCash')
      logics.basicReport.revenueBasicArea.unload({ids: ['data1', 'data3']})
      setTimeout (->
        logics.basicReport.revenueBasicArea.load({columns: [logics.basicReport.dataView.dataDebtCash]})
        return
      ), 300


    "click .showBeginCash": (event, template) ->
      Session.set('revenueBasicAreaReportView', 'beginCash')
      logics.basicReport.revenueBasicArea.unload({ids: ['data1','data2']})
      setTimeout (->
        logics.basicReport.revenueBasicArea.load({columns: [logics.basicReport.dataView.dataBeginCash]})
        return
      ), 300



#    nv.addGraph ->
#      customerGroups = Schema.customerGroups.find({totalCash: {$gt: 0}},{$sort: {totalCash: -1}}).fetch()
#      height = 500; width = 600
#      pieChart = nv.models.pieChart()
#      pieChart.x((d)-> d.name )
#      pieChart.y((d)-> d.totalCash/1000000 )
#      pieChart.labelType("percent")
#      pieChart.showLabels(true)
#      pieChart.labelsOutside(true)
##      pieChart.width(width).height(height)
#  #    pieChart.valueFormat((d)-> accounting.formatNumber(d) + " Tr")
#
#
#
#  #    tp = (key, y, e) ->
#  #      console.log key
#  #      '<h3>' + key.data.name + '</h3>' + '<p>!!' + y + '!!</p>' + '<p>Doanh So: ' + accounting.formatNumber(key.data.totalCash/1000000) + '</p>'
#  #
#  #    pieChart.tooltipContent(tp)
#
#      d3.select('#totalRevenueAll')
#      .datum(customerGroups)
##      .attr('width', width).attr('height', height)
#      .transition().duration(500)
#      .call(pieChart)
#      nv.utils.windowResize(pieChart.update)
#      pieChart