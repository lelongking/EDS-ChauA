Enums = Apps.Merchant.Enums
simpleSchema.customers = new SimpleSchema
  name        : simpleSchema.StringUniqueIndex
  code        : type: String , optional: true
  deliveryAdd : type: String , optional: true
  description : simpleSchema.OptionalString
  group       : simpleSchema.OptionalString
  staff       : simpleSchema.OptionalString
  billNo      : type: Number, defaultValue: 0
  saleBillNo        : type: Number, defaultValue: 0 #số phiếu bán
  importBillNo      : type: Number, defaultValue: 0 #số phiếu nhap
  returnBillNo      : type: Number, defaultValue: 0 #số phiếu tra hang
  transactionBillNo : type: Number, defaultValue: 0 #số phiếu thu chi


  nameSearch  : simpleSchema.searchSource('name')
  merchant    : simpleSchema.DefaultMerchant
  avatar      : simpleSchema.OptionalString
  allowDelete : simpleSchema.DefaultBoolean()
  creator     : simpleSchema.DefaultCreator
  version     : { type: simpleSchema.Version }


  orderWaiting : type: [String], defaultValue: []
  orderFailure : type: [String], defaultValue: []
  orderSuccess : type: [String], defaultValue: []


  beginCash   : simpleSchema.DefaultNumber()
  debtCash    : simpleSchema.DefaultNumber()
  loanCash    : simpleSchema.DefaultNumber()
  paidCash    : simpleSchema.DefaultNumber()
  returnCash  : simpleSchema.DefaultNumber()
  totalCash   : type: Number, defaultValue: 0 #nợ tiền hiện tại


  debtRequiredCash : type: Number, defaultValue: 0 #số nợ bắt buộc phải thu
  paidRequiredCash : type: Number, defaultValue: 0 #số nợ bắt buộc đã trả

  debtBeginCash    : type: Number, defaultValue: 0 #số nợ đầu kỳ phải thu
  paidBeginCash    : type: Number, defaultValue: 0 #số nợ đầu kỳ đã trả

  debtIncurredCash : type: Number, defaultValue: 0 #chi phí phát sinh cộng
  paidIncurredCash : type: Number, defaultValue: 0 #chi phí phát sinh trừ

  debtSaleCash     : type: Number, defaultValue: 0 #số tiền bán hàng phát sinh trong kỳ
  paidSaleCash     : type: Number, defaultValue: 0 #số tiền đã trả phát sinh trong kỳ
  returnSaleCash   : type: Number, defaultValue: 0 #số tiền trả hàng phát sinh trong kỳ


  profiles               : type: Object, optional: true
  'profiles.phone'       : simpleSchema.OptionalString
  'profiles.address'     : simpleSchema.OptionalString
  'profiles.gender'      : simpleSchema.DefaultBoolean()
  'profiles.areas'       : simpleSchema.OptionalStringArray

  'profiles.dateOfBirth' : simpleSchema.OptionalString
  'profiles.pronoun'     : simpleSchema.OptionalString
  'profiles.companyName' : simpleSchema.OptionalString
  'profiles.email'       : simpleSchema.OptionalString

  productTraded: type: [Object], defaultValue: []
  'productTraded.$.product'       : type: String
  'productTraded.$.productUnit'   : type: String
  'productTraded.$.saleQuantity'   : type: Number
  'productTraded.$.returnQuantity' : type: Number

Schema.add 'customers', "Customer", class Customer
  @transform: (doc) ->
    doc.orderWaitingCount = -> if @orderWaiting then @orderWaiting.length else 0
    doc.orderFailureCount = -> if @orderFailure then @orderFailure.length else 0
    doc.orderSuccessCount = -> if @orderSuccess then @orderSuccess.length else 0

    doc.hasAvatar = -> if doc.avatar then '' else 'missing'
    doc.avatarUrl = -> if doc.avatar then AvatarImages.findOne(doc.avatar)?.url() else undefined

    doc.totalDebtCash = ->
      if (typeof @debtCash is "number") and (typeof @loanCash is "number")
        @debtCash + @loanCash
      else 0

    doc.calculateTotalCash = ->
      (@debtRequiredCash ? 0) - (@paidRequiredCash ? 0) +
        (@debtBeginCash ? 0) - (@paidBeginCash ? 0) +
        (@debtIncurredCash ? 0) - (@paidIncurredCash ? 0) +
        (@debtSaleCash ? 0) - (@paidSaleCash ? 0) - (@returnSaleCash ? 0)

    doc.remove = ->
      if @allowDelete and checkAllowDelete(@) and Schema.customers.remove(@_id)
        randomGetCustomerId = Schema.customers.findOne()?._id ? ''
        Meteor.users.update(Meteor.userId(), {$set: {'sessions.currentCustomer': randomGetCustomerId}})

        #update customer group
        if @group
          totalCash = @debtCash + @loanCash
          Schema.customerGroups.update(@group, {$pull: {customers: @_id }, $inc:{totalCash: -totalCash}})
      else
        Schema.customers.update(@_id, $set:{allowDelete: false})

    doc.calculateBalance = ->
      customerUpdate = {paidCash: 0, returnCash: 0, totalCash: 0, loanCash: 0, beginCash: 0, debtCash: 0}
      Schema.transactions.find({owner: @_id}).forEach(
        (transaction) ->
          console.log transaction
          if transaction.transactionType is Enums.getValue('TransactionTypes', 'customer')
            if transaction.parent
              customerUpdate.beginCash  += 0
              customerUpdate.debtCash   += transaction.debtBalanceChange
              customerUpdate.loanCash   += 0
              customerUpdate.paidCash   += transaction.paidBalanceChange
              customerUpdate.returnCash += 0

            else
              customerUpdate.beginCash  += transaction.debtBalanceChange - transaction.paidBalanceChange
              customerUpdate.debtCash   += 0
              customerUpdate.loanCash   += 0
              customerUpdate.paidCash   += 0
              customerUpdate.returnCash += 0

          if transaction.transactionType is Enums.getValue('TransactionTypes', 'return')
            customerUpdate.beginCash  += 0
            customerUpdate.debtCash   += 0
            customerUpdate.loanCash   += 0
            customerUpdate.paidCash   += 0
            customerUpdate.returnCash += transaction.paidBalanceChange
      )
      customerUpdate.totalCash = customerUpdate.beginCash + customerUpdate.debtCash + customerUpdate.loanCash - customerUpdate.paidCash - customerUpdate.returnCash
      console.log customerUpdate
      Schema.customers.update @_id, $set: customerUpdate

  @calculate: ->
    Schema.customers.find({}).forEach(
      (customer) ->
        Schema.customers.update customer._id, {
          $set:{paidCash:0, debtCash:0, loanCash:0, totalCash:0}
          $unset:{salePaid:"", saleDebt:"", saleTotalCash:""}
        }
    )

  @insert: (name, description) ->
    customerId = Schema.customers.insert({name: name, description: description, totalCash: 0})
    CustomerGroup.addCustomer(customerId) if customerId

  @splitName: (fullText) ->
    if fullText.indexOf("(") > 0
      namePart        = fullText.substr(0, fullText.indexOf("(")).trim()
      descriptionPart = fullText.substr(fullText.indexOf("(")).replace("(", "").replace(")", "").trim()
      return { name: namePart, description: descriptionPart }
    else
      return { name: fullText }

  @nameIsExisted: (name, merchant) ->
    existedQuery = {name: name, merchant: merchant}
    Schema.customers.findOne(existedQuery)

  @setSession: (customerId) ->
    Meteor.users.update(Meteor.userId(), {$set: {'sessions.currentCustomer': customerId}})

  @updateCustomer: ->
    Schema.customers.find({}).forEach(
      (customer)->
        console.log customer
        Schema.customers.update(customer._id, {
          $set:{
            saleBillNo       : 0
            importBillNo     : 0
            returnBillNo     : 0
            transactionBillNo: 0
            beginCash : 0
            debtCash  : 0
            loanCash  : 0
            paidCash  : 0
            returnCash: 0
            totalCash : 0
            orderWaiting: []
            orderFailure: []
            orderSuccess: []
            allowDelete : true
          }
        })
    )

  @updateGroup: ->
    if defaultGroup = Schema.customerGroups.findOne({isBase: true})
      listCustomerIds = []
      Schema.customers.find({}).forEach(
        (customer)->
          Schema.customers.update(customer._id, { $set:{ group: defaultGroup._id } })
          listCustomerIds.push(customer._id)
      )
      if Schema.customerGroups.update(defaultGroup._id, $set:{customers: []})
        Schema.customerGroups.update(defaultGroup._id, $set:{customers: listCustomerIds})

  @checkAllowDelete: ->
    Schema.customers.find().forEach(
      (customer) -> Schema.customers.update(customer._id, $set:{allowDelete: checkAllowDelete(customer)})
    )

checkAllowDelete = (customer)->
  findOrder = Schema.orders.findOne({buyer: customer._id})
  findTransaction = Schema.transactions.findOne({owner: customer._id})
  checkBeginCash =
    if customer.debtRequiredCash isnt 0 or
      customer.paidRequiredCash isnt 0 or
      customer.debtBeginCash isnt 0 or
      customer.paidBeginCash isnt 0 or
      customer.debtIncurredCash isnt 0 or
      customer.paidIncurredCash isnt 0 or
      customer.debtSaleCash isnt 0 or
      customer.paidSaleCash isnt 0 or
      customer.returnSaleCash isnt 0
         true
    else
      false
  if findOrder or findTransaction or checkBeginCash then false else true