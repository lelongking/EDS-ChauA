Enums = Apps.Merchant.Enums
Meteor.methods
  setCurrentPriceBook: (priceBookId)->
    if userId = Meteor.userId()
      Meteor.users.update(userId, {$set: {'sessions.currentPriceBook': priceBookId}})

  setStaffTurnoverCash: (cash)->
    if userId = Meteor.userId()
      Meteor.users.update(userId, $set:{turnoverCash: cash})