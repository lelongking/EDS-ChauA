scope = logics.staffManagement
Enums = Apps.Merchant.Enums

lemon.defineHyper Template.customerNotOfStaffSection,
  helpers:
    customerGroups: ->
      scope.customerGroup =  Schema.customerGroups.find({}, {sort: {nameSearch: 1}}).map(
        (group) ->
          group.customerLists = Schema.customers.find({group: group._id, staff: {$exists: false}}, {sort:{group: 1}}).fetch()
          group
      )
      scope.customerGroup

    selectedCustomer: -> if _.contains(Session.get("staffManagementCustomerListNotOfStaffSelect"), @_id) then 'selected' else ''
    selectedCustomerGroup: -> if _.contains(Session.get("staffManagementCustomerGroupListNotOfStaffSelect"), @_id) then 'selected' else ''

  events:
    "click .customer.detail-row:not(.selected) td.command": (event, template) ->
      customerId  = @_id
      customerIds = Session.get('staffManagementCustomerListNotOfStaffSelect')
      customerIds.push(customerId)
      Session.set('staffManagementCustomerListNotOfStaffSelect', customerIds)

      customerGroupId  = @group
      customerGroup  = _.findWhere(scope.customerGroup, {_id: customerGroupId})
      oldCustomerIds = _.pluck(customerGroup.customerLists, '_id')

      customerGroupIds        = Session.get('staffManagementCustomerGroupListNotOfStaffSelect')
      countCustomerNotSelects = _.difference(oldCustomerIds, customerIds)
      if countCustomerNotSelects.length is 0
        customerGroupIds.push(customerGroupId)
        Session.set('staffManagementCustomerGroupListNotOfStaffSelect', customerGroupIds)
      event.stopPropagation()

    "click .customer.detail-row.selected td.command": (event, template) ->
      customerId  = @_id
      customerIds = Session.get('staffManagementCustomerListNotOfStaffSelect')
      customerIds = _.without(customerIds, customerId)
      Session.set('staffManagementCustomerListNotOfStaffSelect', customerIds)

      customerGroupId  = @group
      customerGroupIds = Session.get('staffManagementCustomerGroupListNotOfStaffSelect')
      customerGroupIds = _.without(customerGroupIds, customerGroupId)
      Session.set('staffManagementCustomerGroupListNotOfStaffSelect', customerGroupIds)
      event.stopPropagation()

    "click .customerGroup.detail-row:not(.selected) td.command": (event, template) ->
      customerGroupId  = @_id
      customerGroupIds = Session.get('staffManagementCustomerGroupListNotOfStaffSelect')
      customerGroupIds.push(customerGroupId)
      Session.set('staffManagementCustomerGroupListNotOfStaffSelect', customerGroupIds)

      customerGroup = _.findWhere(scope.customerGroup, {_id: customerGroupId})
      newCustomerIds   = _.pluck(customerGroup.customerLists, '_id')

      oldCustomerIds = Session.get('staffManagementCustomerListNotOfStaffSelect')
      customerIds = _.union(oldCustomerIds, newCustomerIds)
      Session.set('staffManagementCustomerListNotOfStaffSelect', customerIds)

      event.stopPropagation()

    "click .customerGroup.detail-row.selected td.command": (event, template) ->
      customerGroupId  = @_id
      customerGroupIds = Session.get('staffManagementCustomerGroupListNotOfStaffSelect')
      customerGroupIds = _.without(customerGroupIds, customerGroupId)
      Session.set('staffManagementCustomerGroupListNotOfStaffSelect', customerGroupIds)

      customerGroup = _.findWhere(scope.customerGroup, {_id: customerGroupId})
      newCustomerIds   = _.pluck(customerGroup.customerLists, '_id')

      oldCustomerIds = Session.get('staffManagementCustomerListNotOfStaffSelect')
      customerIds = _.difference(oldCustomerIds, newCustomerIds)
      Session.set('staffManagementCustomerListNotOfStaffSelect', customerIds)
      event.stopPropagation()