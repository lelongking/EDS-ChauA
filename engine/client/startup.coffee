reloadBrowser = ->
  if window then window.location.reload() else location.reload()
  console.log 'reload browser'

Meteor.startup ->
  moment.locale('vi')
  Router.configure
    progressDebug: false

  Meteor.call('trackingProduct')
#  Meteor.setInterval(reloadBrowser, 120*1000)
  Tracker.autorun ->

    if Meteor.userId() and !Meteor.status()?.connected
      console.log 'check connected'
      Helpers.deferredAction ->
        unless Meteor.status()?.connected
          if window then window.location.reload() else location.reload()
      , "reloadIfServerFail"
      , 10*1000


    if Meteor.userId()
      user = Meteor.users.findOne(Meteor.userId()); Session.set 'myUser', user

      if user.profile
        user.profile._id = user._id
        Session.set 'myProfile', user.profile

      if user.sessions
        user.sessions._id = user._id
        Session.set 'mySession', user.sessions

      Session.set 'merchant', Schema.merchants.findOne(user.profile?.merchant)
      Session.set 'priceBookBasic', Schema.priceBooks.findOne({priceBookType: 0, merchant: user.profile?.merchant})

      unless Session.get('mySession')
        user = Meteor.users.findOne(Meteor.userId())
        user.sessions._id = user._id
        Session.set 'mySession', user.sessions

      unless Session.get('myProfile')
        user = Meteor.users.findOne(Meteor.userId())
        user.profile._id = user._id
        Session.set 'myProfile', user.profile