Enums = Apps.Merchant.Enums

simpleSchema.transactions = new SimpleSchema
  transactionName   : type: String, defaultValue: 'ĐƠN HÀNG'
  transactionCode   : type: String, optional: true
  transactionStatus : type: Number  , defaultValue: Enums.getValue('TransactionStatuses', 'initialize')
  transactionGroup  : type: Number  , defaultValue: Enums.getValue('TransactionGroups', 'customer')

  transactionType   : type: Number  , defaultValue: Enums.getValue('TransactionTypes', 'saleCash')
  #Nếu returnCash: KH thì Paid , NCC là Debit

  #Nếu là KH: True là Debt, False là  Paid
  #Nếu là NCC: True là Paid, False là Debt
  receivable        : type: Boolean , defaultValue: true

  description     : type: String, optional: true
  owner           : type: String, optional: true # chu no (KH hoac NCC)
  parent          : type: String, optional: true # thong tin phiu ban, phiu nhap (Nhap - Ban - ko co) tuy theo
  dueDay          : type: Date  , optional: true # han no


  beforeBalance: type: Object, optional: true
  'beforeBalance.paidRequiredCash': type: Number, defaultValue: 0
  'beforeBalance.paidBeginCash'   : type: Number, defaultValue: 0
  'beforeBalance.debtIncurredCash': type: Number, defaultValue: 0
  'beforeBalance.paidIncurredCash': type: Number, defaultValue: 0
  'beforeBalance.debtSaleCash'    : type: Number, defaultValue: 0
  'beforeBalance.paidSaleCash'    : type: Number, defaultValue: 0
  'beforeBalance.returnSaleCash'  : type: Number, defaultValue: 0

  changeBalance: type: Object, optional: true
  'changeBalance.paidRequiredCash': type: Number, defaultValue: 0
  'changeBalance.paidBeginCash'   : type: Number, defaultValue: 0
  'changeBalance.debtIncurredCash': type: Number, defaultValue: 0
  'changeBalance.paidIncurredCash': type: Number, defaultValue: 0
  'changeBalance.debtSaleCash'    : type: Number, defaultValue: 0
  'changeBalance.paidSaleCash'    : type: Number, defaultValue: 0
  'changeBalance.returnSaleCash'  : type: Number, defaultValue: 0

  latestBalance: type: Object, optional: true
  'latestBalance.paidRequiredCash': type: Number, defaultValue: 0
  'latestBalance.paidBeginCash'   : type: Number, defaultValue: 0
  'latestBalance.debtIncurredCash': type: Number, defaultValue: 0
  'latestBalance.paidIncurredCash': type: Number, defaultValue: 0
  'latestBalance.debtSaleCash'    : type: Number, defaultValue: 0
  'latestBalance.paidSaleCash'    : type: Number, defaultValue: 0
  'latestBalance.returnSaleCash'  : type: Number, defaultValue: 0

  owedCash        : type: Number  , defaultValue: 0     # so tien con no, luôn bang 0 neu receivable is  false

  isBeginCash     : type: Boolean , defaultValue: false # transaction la no dau ky
  isUseCode       : type: Boolean , defaultValue: false # transaction co Ma Phieu
  isRoot          : type: Boolean , defaultValue: false # transaction cua order hoac import or return

  balanceBefore : type: Number, defaultValue: 0
  balanceChange : type: Number, defaultValue: 0
  balanceLatest : type: Number, defaultValue: 0

  beforeDebtBalance: type: Number, defaultValue: 0
  latestDebtBalance: type: Number, defaultValue: 0
  debtBalanceChange: type: Number, defaultValue: 0
  paidBalanceChange: type: Number, defaultValue: 0


  merchant   : simpleSchema.DefaultMerchant
  allowDelete: simpleSchema.DefaultBoolean()
  creator    : simpleSchema.DefaultCreator
  version    : { type: simpleSchema.Version }


  details                : type: [Object], optional: true
  'details.$.transaction': type: String
  'details.$.paymentCash': type: Number

Schema.add 'transactions', "Transaction", class Transaction
  @transform: (doc) ->


  debtDate:
    type: Date
    defaultValue: new Date()

  paidDate:
    type: Date
    defaultValue: new Date()

  confirmed:
    type: Boolean
    defaultValue: false

  conformer:
    type: String
    optional: true

  conformedAt:
    type: Date
    optional: true
