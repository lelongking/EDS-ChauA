scope = logics.customerGroup
Enums = Apps.Merchant.Enums
lemon.defineHyper Template.customerGroupDetailSection,
  helpers:
    selected: -> if _.contains(Session.get("customerSelectLists"), @_id) then 'selected' else ''
    totalCashByStaff: ->
      totalCash = 0
      (totalCash += customer.calculateTotalCash()) for customer in scope.customerList
      totalCash

    customerLists: ->
      return [] if !@customers or @customers.length is 0
      customerListId = _.intersection(@customers, Session.get('myProfile').customers)
      customerQuery = {group: @_id}
      customerQuery._id = {$in: customerListId} unless User.hasManagerRoles()
      customerList = Schema.customers.find(customerQuery,{sort: {name: 1}}).map(
        (item) ->
          console.log item
          order = Schema.orders.findOne({
            buyer       : item._id
            orderType   : Enums.getValue('OrderTypes', 'success')
            orderStatus : Enums.getValue('OrderStatus', 'finish')
          })
          if order
            item.latestTradingDay       = order.successDate
            item.latestTradingTotalCash = accounting.formatNumber(order.finalPrice) + ' VND'

          item.totalCashToFormatNumber = accounting.formatNumber(item.calculateTotalCash()) + ' VND'
          item
      )
      scope.customerList = customerList
      customerSearchText = Session.get('customerGroupSearchCustomerFilter')
      if customerSearchText
        customerList =
          _.filter customerList, (customer) ->
            unsignedTerm = Helpers.RemoveVnSigns customerSearchText
            unsignedName = Helpers.RemoveVnSigns customer.name

            unsignedName.indexOf(unsignedTerm) > -1

      customerList

  events:
    "click .detail-row:not(.selected) td.command": (event, template) ->
      scope.currentCustomerGroup.selectedCustomer(@_id) if User.hasManagerRoles()
      event.stopPropagation()

    "click .detail-row.selected td.command": (event, template) ->
      scope.currentCustomerGroup.unSelectedCustomer(@_id) if User.hasManagerRoles()
      event.stopPropagation()

    "click .detail-row": (event, template) ->
      Router.go('/customer')
      Session.set 'currentOrder', @
      Customer.setSession(@_id)