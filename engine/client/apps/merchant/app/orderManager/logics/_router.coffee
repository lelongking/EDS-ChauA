scope = logics.orderManager

orderManagerRoute =
  template: 'orderManager',
#  waitOnDependency: 'merchantEssential'
  onBeforeAction: ->
    if @ready()
      Apps.setup(scope, Apps.Merchant.orderManagerInit, 'orderManager')
      Session.set "currentAppInfo",
        name: "đơn hàng"
        navigationPartial:
          template: "orderManagerNavigationPartial"
          data: {}
      @next()
  data: ->
    Apps.setup(scope, Apps.Merchant.orderManagerReactiveRun)
    return {
    }

lemon.addRoute [orderManagerRoute], Apps.Merchant.RouterBase