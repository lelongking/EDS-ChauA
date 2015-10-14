scope = logics.basicReport

lemon.defineApp Template.revenueOfAreaReport,
  created: ->
    scope.dataView =
      x: ['x']
      totalCash: 0
      debtCash: 0
      beginCash: 0
      dataTotalCash :['data1']
      dataDebtCash  :['data2']
      dataBeginCash :['data3']

  rendered: ->
    scope.revenueBasicArea =c3.generate(
      bindto: '#revenueOfAreaReport'
      data:
        columns: [ ['data1', 30], ['data2', 120] ]
        type: 'pie'
        onclick: (d, i) ->
          console.log 'onclick', d, i
          return
        onmouseover: (d, i) ->
          console.log 'onmouseover', d, i
          return
        onmouseout: (d, i) ->
          console.log 'onmouseout', d, i
          return
    )

#    nv.addGraph ->
#      #    tp = (key, y, e) ->
#      #      console.log key
#      #      '<h3>' + key.data.name + '</h3>' + '<p>!!' + y + '!!</p>' + '<p>Doanh So: ' + accounting.formatNumber(key.data.totalCash/1000000) + '</p>'
#      #
#      #    pieChart.tooltipContent(tp)
#
#      logics.basicReport.revenueOfArea = nv.models.pieChart()
#      logics.basicReport.revenueOfArea.x((d)-> d.name )
#      logics.basicReport.revenueOfArea.y((d)-> d.totalCash/1000000 )
#      logics.basicReport.revenueOfArea.labelType("percent")
#      logics.basicReport.revenueOfArea.showLabels(true)
#      logics.basicReport.revenueOfArea.labelsOutside(true)
#
#
#      d3.select('#revenueOfAreaReport')
#      .datum(logics.basicReport.customers)
#      .transition().duration(500)
#      .call(logics.basicReport.revenueOfArea)
#      nv.utils.windowResize(logics.basicReport.revenueOfArea.update())
#      logics.basicReport.revenueOfArea

  helpers:
    areaSelectOptions: -> scope.areaSelectOptions