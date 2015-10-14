Enums = Apps.Merchant.Enums
findTransactionParent = (transaction)->
  if transaction.transactionType is Enums.getValue('TransactionTypes', 'provider')
    parent = Schema.imports.findOne(transaction.parent)
  else if transaction.transactionType is Enums.getValue('TransactionTypes', 'customer')
    parent = Schema.orders.findOne(transaction.parent)
  else
    parent = Schema.returns.findOne(transaction.parent)
  parent


Meteor.methods
  createTransaction: (ownerId, money, name = null, description = null, transactionGroup = Enums.getValue('TransactionGroups', 'provider'), receivable = undefined)->
    console.log ownerId, money, name, description, transactionGroup, receivable


    if transactionGroup is Enums.getValue('TransactionGroups', 'provider')
      owner = Schema.providers.findOne(ownerId)
#    else if transactionType is Enums.getValue('TransactionGroups', 'customer')
#      owner = Schema.customers.findOne(ownerId)

    if owner
      transaction = Schema.transactions.findOne({owner: owner._id}, {sort: {'version.createdAt': -1}})

      ownerUpdate = $set: {allowDelete : false}, $inc:{}
      ownerUpdate.$inc.totalCash = if receivable then money else -money
      if transaction # tao phieu tra tien, no cu. ko co tao phieu ban voi tra hang
        ownerUpdate.$inc.paidCash  = if receivable then 0 else money
        ownerUpdate.$inc.loanCash  = if receivable then money else 0
      else #Nhap ton dau ky
        ownerUpdate.$inc.beginCash = if receivable then money else -money

      transactionInsert =
  #      transactionCode :
        transactionGroup  : transactionGroup
        transactionType : Enums.getValue('TransactionTypes', 'incurredCash')
        owner             : owner._id
        receivable        : receivable
        beforeDebtBalance : owner.totalCash
        owedCash          : money
        status            : Enums.getValue('TransactionStatuses', if receivable then 'tracking' else 'closed')

      transactionInsert.transactionName = name if name
      transactionInsert.description = description if description
      transactionInsert.parent = transaction.parent if transaction?.parent
      transactionInsert.isBeginCash = if transaction then false else true
      transactionInsert.isUseCode = !transactionInsert.isBeginCash

      if transactionGroup is Enums.getValue('TransactionGroups', 'provider')
        transactionInsert.transactionName   = if receivable then 'Phiếu Thu' else 'Phiếu Chi'
        unless description
          transactionInsert.description     = if receivable then 'Nợ tiền' else 'Trả tiền'
        transactionInsert.debtBalanceChange = if receivable then money else 0
        transactionInsert.paidBalanceChange = if receivable then 0 else money

#      else if transactionType is Enums.getValue('TransactionTypes', 'customer')
#        transactionInsert.transactionName   = if receivable then 'Phiếu Chi' else 'Phiếu Thu'
#        unless description
#          transactionInsert.description     = if receivable then 'Nợ tiền' else 'Trả tiền'
#        transactionInsert.debtBalanceChange = if receivable then money else 0
#        transactionInsert.paidBalanceChange = if receivable then 0 else money

      latestDebtBalance = transactionInsert.beforeDebtBalance + ownerUpdate.$inc.totalCash
      transactionInsert.latestDebtBalance = latestDebtBalance

      if Schema.transactions.insert(transactionInsert)
        if transactionGroup is Enums.getValue('TransactionGroups', 'provider')
          Schema.providers.update owner._id, ownerUpdate
#        else if transactionType is Enums.getValue('TransactionGroups', 'customer')
#          Schema.customers.update owner._id, ownerUpdate
#          Schema.customerGroups.update owner.group, $inc:{totalCash: ownerUpdate.$inc.totalCash} if owner.group

  createNewTransaction: (group, transactionType, receivable, ownerId, money, description = null)->
    console.log ownerId, money, description, transactionType, receivable

    if money < 0
      console.log('transaction Money > 0'); return

    if group is Enums.getValue('TransactionGroups', 'customer')
      if owner = Schema.customers.findOne(ownerId)
        transactionInsert =
          transactionType   : transactionType
          owner             : owner._id
          receivable        : receivable
          balanceChange     : money
          description       : description
          status            : Enums.getValue('TransactionStatuses', if receivable then 'tracking' else 'closed')

          beforeBalance     :
            paidRequiredCash: owner.paidRequiredCash ? 0
            paidBeginCash   : owner.paidBeginCash ? 0
            debtIncurredCash: owner.debtIncurredCash ? 0
            paidIncurredCash: owner.paidIncurredCash ? 0
            debtSaleCash    : owner.debtSaleCash ? 0
            paidSaleCash    : owner.paidSaleCash ? 0
            returnSaleCash  : owner.returnSaleCash ? 0

          changeBalance     :
            paidRequiredCash: 0
            paidBeginCash   : 0
            debtIncurredCash: 0
            paidIncurredCash: 0
            debtSaleCash    : 0
            paidSaleCash    : 0
            returnSaleCash  : 0

          latestBalance:
            paidRequiredCash: owner.paidRequiredCash ? 0
            paidBeginCash   : owner.paidBeginCash ? 0
            debtIncurredCash: owner.debtIncurredCash ? 0
            paidIncurredCash: owner.paidIncurredCash ? 0
            debtSaleCash    : owner.debtSaleCash ? 0
            paidSaleCash    : owner.paidSaleCash ? 0
            returnSaleCash  : owner.returnSaleCash ? 0

        latestTransaction = Schema.transactions.findOne({transactionGroup: group, owner: owner._id}, {sort: {'version.createdAt': -1}})
        transactionInsert.parent = latestTransaction.parent if latestTransaction?.parent


        if receivable #receivable is True(Debt) là nợ: Phát sinh khác, Bán Hàng
          if transactionType is Enums.getValue('TransactionTypes', 'incurredCash') #Phát sinh cộng
            transactionInsert.transactionName                = 'Phát Sinh Cộng'
            transactionInsert.description                    = 'Phát sinh cộng'
            transactionInsert.changeBalance.debtIncurredCash += transactionInsert.balanceChange
            transactionInsert.latestBalance.debtIncurredCash += transactionInsert.balanceChange


          else if transactionType is Enums.getValue('TransactionTypes', 'saleCash') #Bán Hàng
            transactionInsert.transactionName            = 'Bán Hàng'
            transactionInsert.description                = 'Bán hàng'
            transactionInsert.changeBalance.debtSaleCash += transactionInsert.balanceChange
            transactionInsert.latestBalance.debtSaleCash += transactionInsert.balanceChange


        else #receivable is False(Paid) là trả nợ: Nợ Phải Thu, Nợ Đầu Kỳ, Phát Sinh Khác, Bán Hàng, Trả Hàng
          if transactionType is Enums.getValue('TransactionTypes', 'requiredCash') #Trả Nợ - Nợ Phải Thu
            transactionInsert.transactionName                = 'Thu Nợ Phải Thu'
            transactionInsert.description                    = 'Thu nợ phải thu'
            transactionInsert.changeBalance.paidRequiredCash += transactionInsert.balanceChange
            transactionInsert.latestBalance.paidRequiredCash += transactionInsert.balanceChange

          else if transactionType is Enums.getValue('TransactionTypes', 'beginCash') #Trả Nợ - Nợ Đầu Kỳ
            transactionInsert.transactionName              = 'Thu Nợ Đầu Kỳ'
            transactionInsert.description                  = 'Thu nợ đầu kỳ'
            transactionInsert.changeBalance.paidBeginCash += transactionInsert.balanceChange
            transactionInsert.latestBalance.paidBeginCash += transactionInsert.balanceChange

          else if transactionType is Enums.getValue('TransactionTypes', 'incurredCash') #Phát Sinh Trừ - Phieu Thu
            transactionInsert.transactionName                 = 'Phát Sinh Trừ'
            transactionInsert.description                     = 'Phát sinh trừ'
            transactionInsert.changeBalance.paidIncurredCash += transactionInsert.balanceChange
            transactionInsert.latestBalance.paidIncurredCash += transactionInsert.balanceChange

          else if transactionType is Enums.getValue('TransactionTypes', 'saleCash') #Trả Nợ - Bán Hàng
            transactionInsert.transactionName             = 'Trả Tiền'
            transactionInsert.description                 = 'Trả tiền'
            transactionInsert.changeBalance.paidSaleCash += transactionInsert.balanceChange
            transactionInsert.latestBalance.paidSaleCash += transactionInsert.balanceChange

          else if transactionType is Enums.getValue('TransactionTypes', 'returnCash') #Trả Hàng
            transactionInsert.transactionName               = 'Trả Hàng'
            transactionInsert.description                   = 'Trả hàng'
            transactionInsert.changeBalance.returnSaleCash += transactionInsert.balanceChange
            transactionInsert.latestBalance.returnSaleCash += transactionInsert.balanceChange

        transactionInsert.description = description if description
        beforeBalance = transactionInsert.beforeBalance
        transactionInsert.balanceBefore =
          beforeBalance.debtIncurredCash - beforeBalance.paidIncurredCash - beforeBalance.paidRequiredCash +
            beforeBalance.debtSaleCash - beforeBalance.paidSaleCash - beforeBalance.returnSaleCash - beforeBalance.paidBeginCash

        balanceLatest = transactionInsert.latestBalance
        transactionInsert.balanceLatest =
          balanceLatest.debtIncurredCash - balanceLatest.paidIncurredCash - balanceLatest.paidRequiredCash +
            balanceLatest.debtSaleCash - balanceLatest.paidSaleCash - balanceLatest.returnSaleCash - balanceLatest.paidBeginCash

        if transactionInsert.transactionName
          console.log transactionInsert
          changeBalance = transactionInsert.changeBalance
          ownerUpdate =
            $set:
              allowDelete: false

            $inc:
              paidRequiredCash: changeBalance.paidRequiredCash
              paidBeginCash   : changeBalance.paidBeginCash
              debtIncurredCash: changeBalance.debtIncurredCash
              paidIncurredCash: changeBalance.paidIncurredCash
              debtSaleCash    : changeBalance.debtSaleCash
              paidSaleCash    : changeBalance.paidSaleCash
              returnSaleCash  : changeBalance.returnSaleCash

          if Schema.transactions.insert(transactionInsert)
            console.log ownerUpdate, transactionInsert.changeBalance
            ownerUpdate.$inc.totalCash =
              (ownerUpdate.$inc.paidRequiredCash + ownerUpdate.$inc.paidBeginCash + ownerUpdate.$inc.paidIncurredCash +
                ownerUpdate.$inc.paidSaleCash + ownerUpdate.$inc.returnSaleCash -
                ownerUpdate.$inc.debtIncurredCash - ownerUpdate.$inc.debtSaleCash) ? 0
            Schema.customers.update owner._id, ownerUpdate
            Schema.customerGroups.update owner.group, $inc:{totalCash: ownerUpdate.$inc.totalCash} if owner.group

    else if group is Enums.getValue('TransactionGroups', 'provider')
      owner = Schema.providers.findOne(ownerId)

  deleteNewTransaction: (transactionId) ->
    if transaction = Schema.transactions.findOne({
        $and : [
          _id               : transactionId
        ,
          merchant          : Merchant.getId()
        ,
          transactionGroup  : Enums.getValue('TransactionGroups', 'customer')
        ,
          $or: [
            transactionType: Enums.getValue('TransactionTypes', 'incurredCash')
          ,
            transactionType: Enums.getValue('TransactionTypes', 'requiredCash')
            receivable     : false
          ,
            transactionType: Enums.getValue('TransactionTypes', 'beginCash')
            receivable     : false
          ,
            transactionType: Enums.getValue('TransactionTypes', 'saleCash')
            receivable     : false
          ]
        ]
      })

      if Schema.transactions.remove(transaction._id)
        if transaction.parent
          beforeTransactionQuery =
            owner              : transaction.owner
            isRoot             : true
            'version.createdAt': {$lt: transaction.version.createdAt}
          findBeforeTransaction = Schema.transactions.findOne(beforeTransactionQuery)


        beforeBalance = transaction.beforeBalance
        latestBalance =
          paidRequiredCash: beforeBalance.paidRequiredCash
          paidBeginCash   : beforeBalance.paidBeginCash
          debtIncurredCash: beforeBalance.debtIncurredCash
          paidIncurredCash: beforeBalance.paidIncurredCash
          debtSaleCash    : beforeBalance.debtSaleCash
          paidSaleCash    : beforeBalance.paidSaleCash
          returnSaleCash  : beforeBalance.returnSaleCash

        transactionQuery  =
          owner               : transaction.owner
          transactionGroup    : Enums.getValue('TransactionGroups', 'customer')
          'version.createdAt' : {$gt: transaction.version.createdAt}
        Schema.transactions.find(transactionQuery, {sort: {'version.createdAt': 1}}).forEach(
          (item) ->
            balanceBefore =
              beforeBalance.debtIncurredCash - beforeBalance.paidIncurredCash - beforeBalance.paidRequiredCash +
                beforeBalance.debtSaleCash - beforeBalance.paidSaleCash - beforeBalance.returnSaleCash - beforeBalance.paidBeginCash

            changeBalance                   = item.changeBalance
            latestBalance.paidRequiredCash += changeBalance.paidRequiredCash
            latestBalance.paidBeginCash    += changeBalance.paidBeginCash
            latestBalance.debtIncurredCash += changeBalance.debtIncurredCash
            latestBalance.paidIncurredCash += changeBalance.paidIncurredCash
            latestBalance.debtSaleCash     += changeBalance.debtSaleCash
            latestBalance.paidSaleCash     += changeBalance.paidSaleCash
            latestBalance.returnSaleCash   += changeBalance.returnSaleCash

            balanceLatest =
              latestBalance.debtIncurredCash - latestBalance.paidIncurredCash - latestBalance.paidRequiredCash +
                latestBalance.debtSaleCash - latestBalance.paidSaleCash - latestBalance.returnSaleCash - latestBalance.paidBeginCash

            transactionUpdate =
              $set:
                balanceBefore                   : balanceBefore
                balanceLatest                   : balanceLatest

                'beforeBalance.paidRequiredCash': beforeBalance.paidRequiredCash
                'beforeBalance.paidBeginCash'   : beforeBalance.paidBeginCash
                'beforeBalance.debtIncurredCash': beforeBalance.debtIncurredCash
                'beforeBalance.paidIncurredCash': beforeBalance.paidIncurredCash
                'beforeBalance.debtSaleCash'    : beforeBalance.debtSaleCash
                'beforeBalance.paidSaleCash'    : beforeBalance.paidSaleCash
                'beforeBalance.returnSaleCash'  : beforeBalance.returnSaleCash

                'latestBalance.paidRequiredCash': latestBalance.paidRequiredCash
                'latestBalance.paidBeginCash'   : latestBalance.paidBeginCash
                'latestBalance.debtIncurredCash': latestBalance.debtIncurredCash
                'latestBalance.paidIncurredCash': latestBalance.paidIncurredCash
                'latestBalance.debtSaleCash'    : latestBalance.debtSaleCash
                'latestBalance.paidSaleCash'    : latestBalance.paidSaleCash
                'latestBalance.returnSaleCash'  : latestBalance.returnSaleCash

            if transaction.parent and transaction.isRoot and transaction.parent is item.parent
              if findBeforeTransaction
                transactionUpdate.$set.parent = findBeforeTransaction.parent
              else
                transactionUpdate.$unset = {parent: ""}

            Schema.transactions.update item._id, transactionUpdate
            beforeBalance = latestBalance
        )


        updateAllowDelete = {allowDelete: false}
        updateAllowDelete.allowDelete = true if Schema.transactions.find({owner: transaction.owner}).count() is 0
        updateInc =
          paidRequiredCash: -transaction.changeBalance.paidRequiredCash
          paidBeginCash   : -transaction.changeBalance.paidBeginCash
          debtIncurredCash: -transaction.changeBalance.debtIncurredCash
          paidIncurredCash: -transaction.changeBalance.paidIncurredCash
          debtSaleCash    : -transaction.changeBalance.debtSaleCash
          paidSaleCash    : -transaction.changeBalance.paidSaleCash
          returnSaleCash  : -transaction.changeBalance.returnSaleCash
        Schema.customers.update(transaction.owner, {$inc: updateInc, $set: updateAllowDelete})

        if customer = Schema.customers.findOne(transaction.owner)
          totalCash =
            transaction.changeBalance.paidRequiredCash + transaction.changeBalance.paidBeginCash +
              transaction.changeBalance.debtIncurredCash - transaction.changeBalance.paidIncurredCash +
              transaction.changeBalance.debtSaleCash - transaction.changeBalance.paidSaleCash - transaction.changeBalance.returnSaleCash
          console.log transaction.changeBalance, totalCash
          Schema.customerGroups.update customer.group, $inc:{totalCash: -totalCash} if customer.group


  # chi xoa transaction no dau ky, voi phieu tra tien, no cu, ko xoa dc phieu ban hang va tra hang
  deleteTransaction: (transactionId) ->
    if transaction = Schema.transactions.findOne({_id: transactionId, transactionGroup: Enums.getValue('TransactionGroups', 'provider')})
      if Schema.transactions.remove(transaction._id)
        if transaction.parent
          beforeTransactionQuery =
            owner              : transaction.owner
            isRoot             : true
            'version.createdAt': {$lt: transaction.version.createdAt}
          findBeforeTransaction = Schema.transactions.findOne(beforeTransactionQuery)

        latestDebtBalance = 0; beforeDebtBalance = transaction.beforeDebtBalance
        transactionQuery  = {owner: transaction.owner, 'version.createdAt': {$gt: transaction.version.createdAt}}
        Schema.transactions.find(transactionQuery, {sort: {'version.createdAt': 1}}).forEach(
          (item) ->
            if item.transactionGroup is Enums.getValue('TransactionGroups', 'provider')
              latestDebtBalance = beforeDebtBalance + item.debtBalanceChange - item.paidBalanceChange
#            else if item.transactionGroup is Enums.getValue('TransactionGroups', 'customer')
#              latestDebtBalance = beforeDebtBalance + item.debtBalanceChange - item.paidBalanceChange

            transactionUpdate = $set:{beforeDebtBalance: beforeDebtBalance, latestDebtBalance: latestDebtBalance}
            if transaction.parent and transaction.isRoot and transaction.parent is item.parent
              if findBeforeTransaction
                transactionUpdate.$set.parent = findBeforeTransaction.parent
              else
                transactionUpdate.$unset = {parent: ""}

            Schema.transactions.update item._id, transactionUpdate
            beforeDebtBalance = latestDebtBalance
        )

        updateAllowDelete = {allowDelete: false}
        updateAllowDelete.allowDelete = true if Schema.transactions.find({owner: transaction.owner}).count() is 0

        if transaction.transactionGroup is Enums.getValue('TransactionGroups', 'provider')
          if transaction.isBeginCash #no ton day ky
            updateOwner =
              beginCash  : transaction.paidBalanceChange - transaction.debtBalanceChange
              totalCash  : transaction.paidBalanceChange - transaction.debtBalanceChange
          else
            updateOwner =
              paidCash   : -transaction.paidBalanceChange
              loanCash   : -transaction.debtBalanceChange
              totalCash  : transaction.paidBalanceChange - transaction.debtBalanceChange
          Schema.providers.update(transaction.owner, {$inc: updateOwner, $set: updateAllowDelete})

#        else if transaction.transactionGroup is Enums.getValue('TransactionGroups', 'customer')
#          if transaction.isBeginCash #no ton day ky
#            updateOwner =
#              beginCash  : transaction.paidBalanceChange - transaction.debtBalanceChange
#              totalCash  : transaction.paidBalanceChange - transaction.debtBalanceChange
#          else
#            updateOwner =
#              paidCash   : -transaction.paidBalanceChange
#              loanCash   : -transaction.debtBalanceChange
#              totalCash  : transaction.paidBalanceChange - transaction.debtBalanceChange
#          Schema.customers.update(transaction.owner, {$inc: updateOwner, $set: updateAllowDelete})
#
#          if customer = Schema.customers.findOne(transaction.owner)
#            Schema.customerGroups.update customer.group, $inc:{totalCash: updateOwner.totalCash} if customer.group
