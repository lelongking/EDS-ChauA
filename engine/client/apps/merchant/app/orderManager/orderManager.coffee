scope = logics.orderManager
Enums = Apps.Merchant.Enums
lemon.defineApp Template.orderManager,
  helpers:
    details: ->
      details     = []
      if searchQuery = Session.get('orderManagerSearchOrderByDate')
        orderQuery =
          $and : [
            $or: [
              {
                merchant            : Merchant.getId()
                orderType           : {$in:[ Enums.getValue('OrderTypes', 'success')]}
                orderStatus         : Enums.getValue('OrderStatus', 'finish')
              },
              {
                merchant    : Merchant.getId()
                orderType: {$in:[
                  Enums.getValue('OrderTypes', 'tracking')
                  Enums.getValue('OrderTypes', 'success')
                  Enums.getValue('OrderTypes', 'fail')
                ]}
                orderStatus: {$in:[
                  Enums.getValue('OrderStatus', 'accountingConfirm')
                  Enums.getValue('OrderStatus', 'exportConfirm')
                  Enums.getValue('OrderStatus', 'success')
                  Enums.getValue('OrderStatus', 'fail')
                  Enums.getValue('OrderStatus', 'importConfirm')
                ]}
              }
            ]
          ,
            accountingConfirmAt : {$gt: searchQuery.fromDate}
          ,
            accountingConfirmAt : {$lt: searchQuery.toDate}
          ]

        orderQuery.$and.push({seller: Meteor.userId()}) unless User.hasManagerRoles()
        orders = Schema.orders.find(orderQuery, {sort:{accountingConfirmAt: -1}}).map(
          (order) ->
            typeIsSuccess  = order.orderType is Enums.getValue('OrderTypes', 'success')
            statusIsFinish = order.orderStatus is Enums.getValue('OrderStatus', 'finish')
            order.isSuccess = if typeIsSuccess and statusIsFinish then true else false
            order.color = !order.isSuccess
            order
        )

        if orders.length > 0
          for key, value of _.groupBy(orders, (item) -> moment(item.accountingConfirmAt).format('MM/YYYY'))
            totalCash = 0; finishCash = 0
            for item in value
              typeIsSuccess  = item.orderType is Enums.getValue('OrderTypes', 'success')
              statusIsFinish = item.orderStatus is Enums.getValue('OrderStatus', 'finish')
              finishCash += if typeIsSuccess and statusIsFinish then item.finalPrice else 0
              totalCash += item.finalPrice

            details.push({createdAt: key, data: value, totalCash: totalCash, finishCash: finishCash})
      details


    isShow: ->
      orderShow = Session.get('orderManagerShowOrder')?.isFinish ? true
      if orderShow and !@isSuccess then 'hide' else ''

    totalCash:->
      orderShow = Session.get('orderManagerShowOrder')?.isFinish ? true
      if orderShow and !@isSuccess then @finishCash else @totalCash

  created: ->
    Session.set('orderManagerShowOrder', {isFinish: true})
    Session.set('orderManagerSearchOrderByDate',
      {
        fromDate    : moment().startOf("year")._d
        toDate      : moment().endOf("year")._d
        finish      : true
      }
    )

  rendered:->
    datePicker = Template.instance().datePicker
    datePicker.$fromDate.datepicker('setDate', Session.get('orderManagerSearchOrderByDate').fromDate)
    datePicker.$toDate.datepicker('setDate', Session.get('orderManagerSearchOrderByDate').toDate)

  destroyed: ->
#    $(document).off("keypress")

  events:
    "click .caption.inner": (event, template) ->
      Meteor.users.update(userId, {$set: {'sessions.currentOrderBill': @_id}}) if userId = Meteor.userId()

    "change [name='fromDate']": (event, template) ->
      console.log 'change'
      searchQuery = Session.get('orderManagerSearchOrderByDate')
      getNewFromDate = template.datePicker.$fromDate.data('datepicker').dates[0]
      if getNewFromDate.getTime() isnt searchQuery.fromDate.getTime()
        searchQuery.fromDate = getNewFromDate
        searchQuery.finish   = false
        Session.set('orderManagerSearchOrderByDate', searchQuery)

    "change [name='toDate']": (event, template) ->
      searchQuery  = Session.get('orderManagerSearchOrderByDate')
      getNewToDate = template.datePicker.$toDate.data('datepicker').dates[0]
      if getNewToDate.getTime() isnt searchQuery.toDate.getTime()
        searchQuery.toDate = getNewToDate
        searchQuery.finish = false
        Session.set('orderManagerSearchOrderByDate', searchQuery)

