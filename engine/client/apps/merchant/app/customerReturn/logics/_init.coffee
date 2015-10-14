Enums = Apps.Merchant.Enums
logics.customerReturn = {}
Apps.Merchant.customerReturnInit = []
Apps.Merchant.customerReturnReactiveRun = []


Apps.Merchant.customerReturnInit.push (scope) ->

Apps.Merchant.customerReturnReactiveRun.push (scope) ->
  if Session.get('mySession')
    scope.currentCustomerReturn = Schema.returns.findOne(Session.get('mySession').currentCustomerReturn)
    productQuantities = {}
    if scope.currentCustomerReturn
      for detail in scope.currentCustomerReturn.details
        productQuantities[detail.product] = 0 unless productQuantities[detail.product]
        productQuantities[detail.product] += detail.basicQuantity

      for detail in scope.currentCustomerReturn.details
        detail.returnQuantities = productQuantities[detail.product]

    Session.set 'currentCustomerReturn', scope.currentCustomerReturn

    #load danh sach san pham cua phieu ban
    if parent = Schema.orders.findOne(Session.get('currentCustomerReturn')?.parent)
      productQuantities = {}
      for detail in parent.details
        productQuantities[detail.product] = 0 unless productQuantities[detail.product]
        productQuantities[detail.product] += detail.basicQuantityAvailable

      for detail in parent.details
        detail.availableBasicQuantity = productQuantities[detail.product]
        detail.availableQuantity      = Math.floor(productQuantities[detail.product]/detail.conversion)

      returnParent = []
      for productId, value of productQuantities
        if product = Schema.products.findOne(productId)
          for unit in product.units
            returnParent.push({
                product: productId
                productUnit: unit._id
                availableBasicQuantity: value
                availableQuantity: Math.floor(value / unit.conversion)
              })

      for detail, index in returnParent
        found = _.findWhere(parent.details, {productUnit: detail.productUnit})
        found = _.findWhere(parent.details, {product: detail.product}) if !found
        if found
          detail.price = found.price
          detail._id = found._id
        else
          returnParent.splice(index, 1)

      Session.set 'currentReturnParent', returnParent

  #readonly 2 Select Khach Hang va Phieu Ban
  if customerReturn = Session.get('currentCustomerReturn')
    $(".customerSelect").select2("readonly", false)
    $(".orderSelect").select2("readonly", if customerReturn.owner then false else true)
  else
    $(".customerSelect").select2("readonly", true)
    $(".orderSelect").select2("readonly", true)