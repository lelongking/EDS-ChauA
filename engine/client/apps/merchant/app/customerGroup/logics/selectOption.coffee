formatCustomerSearch = (item) -> "#{item.name}" if item

Apps.Merchant.customerGroupInit.push (scope) ->
  scope.customerGroupSelects =
    query: (query) -> query.callback
      results: Schema.customerGroups.find(
          {$or: [{name: Helpers.BuildRegExp(query.term), _id: {$not: scope.currentCustomerGroup._id }}]}
        ,
          {sort: {nameSearch: 1, name: 1}}
        ).fetch()
      text: 'name'
    initSelection: (element, callback) -> callback 'skyReset'
    formatSelection: formatCustomerSearch
    formatResult: formatCustomerSearch
    id: '_id'
    placeholder: 'CHỌN NHÓM'
    changeAction: (e) ->
      if User.hasManagerRoles()
        Session.set("customerGroupSelectGroup", 'selectChange')
        scope.currentCustomerGroup.changeCustomerTo(e.added._id)
        Session.set("customerGroupSelectGroup", 'skyReset')
    reactiveValueGetter: -> 'skyReset' if Session.get("customerGroupSelectGroup")

