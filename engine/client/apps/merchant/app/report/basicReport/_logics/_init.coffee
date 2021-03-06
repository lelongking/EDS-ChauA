logics.basicReport = {}
Apps.Merchant.basicReportInit = []
Apps.Merchant.basicReportReactive = []

Apps.Merchant.basicReportReactive.push (scope) ->
  if dynamics = Session.get("basicReportDynamics")
    if dynamics.template is 'revenueOfAreaReport'
      scope.customers = Schema.customers.find({group: Session.get("basicReportDynamics").data._id},{$sort: {saleBillNo: -1}}).fetch()

    if dynamics.template is 'productOfCustomerReport'
      customerId = Session.get("basicReportDynamics").data._id
      orders = Schema.orders.find({buyer: customerId}).fetch()
      listProduct = {}
      for order in orders
        for detail in order.details
          console.log detail
          listProduct[detail.product]  = 0 unless listProduct[detail.product]
          listProduct[detail.product] += detail.basicQuantity

      scope.products = []
      for key, value of listProduct
        scope.products.push({name: Schema.products.findOne(key).name, totalCash: value})

      console.log scope.products


Apps.Merchant.basicReportInit.push (scope) ->
#  scope.revenueOfArea =
#    nv.models.pieChart()
#      .x((d) -> d.name )
#      .y((d) -> d.totalCash/1000000)
#      .labelType("percent")
#      .showLabels(true)
#      .valueFormat((d)-> accounting.formatNumber(d) + " Tr")
