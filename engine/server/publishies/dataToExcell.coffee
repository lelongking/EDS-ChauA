fullBorder =
  top: {style:"thin"}
  left: {style:"thin"}
  bottom: {style:"thin"}
  right: {style:"thin"}

Enums = Apps.Merchant.Enums
Excel       = Meteor.npmRequire('exceljs')
express     = Meteor.npmRequire('express')
path        = Meteor.npmRequire('path')
pathResolve = path.resolve('.')


#get path of Public
if pathResolve.indexOf('.meteor') > 0
  #is Client Folder Public
  publicPath = pathResolve.split('.meteor')[0] + 'public/'
else
  #is Server Folder Public
  publicPath = pathResolve.split('server')[0] + 'web.browser/app/'


Express = ->
  app = express()
  WebApp.connectHandlers.use Meteor.bindEnvironment(app)
  app
app = Express()


app.get '/download/customer/:id', (req, res) ->
  if customer = Schema.customers.findOne(req.params.id)
    #newFile Excel
    workbook  = new Excel.Workbook()
    worksheet = workbook.addWorksheet("cong_no")

    #getData of Order and Return
    orderLists  = getOrderLists(customer._id)
    returnLists = getReturnLists(customer._id)


    #writeData to Excel
    beginRowData = 13
    workbook.xlsx.readFile(publicPath+'template/TBD.xlsx').then ->
      worksheet = workbook.getWorksheet("cong_no")

      resetValueHead(worksheet, beginRowData)
      worksheet.getColumn(i).numFmt = "#,##0" for i in [6,8,9,10,11]
      worksheet.getColumn(index).alignment = { vertical: "middle", horizontal: "center" } for index in [6..9]


      worksheet.getRow(2).font = { name: "Times New Roman", family: 2, size: 16, bold: true }
      worksheet.getRow(3).font = { name: "Times New Roman", family: 2, size: 12, bold: false }
      worksheet.getRow(4).font = { name: "Times New Roman", family: 2, size: 16, bold: true }
      worksheet.getRow(5).font = { name: "Times New Roman", family: 2, size: 12, bold: false }
      worksheet.getRow(6).font = { name: "Times New Roman", family: 2, size: 12, bold: true }
      worksheet.getRow(11).font = { name: "Times New Roman", family: 2, size: 12, bold: true }
      worksheet.getRow(12).font = { name: "Times New Roman", family: 2, size: 12, bold: true }

      worksheet.getCell('A2').alignment = { vertical: "middle", horizontal: "center" }
      worksheet.getCell('A2').font      = { name: "Times New Roman", family: 2, size: 14, bold: true }
      worksheet.getCell('A3').alignment = { vertical: "middle", horizontal: "center" }

      for cell in ['B7', 'A8', 'B9', 'A10']
        worksheet.getCell(cell).font      = { name: "Times New Roman", family: 2, size: 12, bold: false }
        worksheet.getCell(cell).alignment = { vertical: "middle", horizontal: "left" }


      worksheet.getRow(11).font = { name: "Times New Roman", family: 2, size: 12, bold: true }
      worksheet.getRow(12).font = { name: "Times New Roman", family: 2, size: 12, bold: true }


      worksheet.getCell('B6').value = 'Kính gởi Khách hàng: ' + customer.name
      worksheet.getCell('B6').alignment = { vertical: "middle", horizontal: "left" }
      worksheet.getCell('H6').value = 'Địa chỉ: ' + (customer.profiles.address ? '')
      worksheet.getCell('H6').alignment = { vertical: "middle", horizontal: "left" }

      worksheet.getCell('B11').alignment = { vertical: "middle", horizontal: "center" }
      worksheet.getCell('B11').border = fullBorder


      worksheet.getCell('F5').value = 0
      oldDate = orderLists[0]?.successDate
      oldDate = returnLists[0]?.successDate unless oldDate
      oldDate = new Date unless oldDate


      worksheet.getCell('A5').value = '( từ ngày ' + moment(oldDate).format('DD/MM/YYYY') + ' đến ngày ' + moment().format('DD/MM/YYYY') + ' )'
      worksheet.getCell('A5').alignment = { vertical: "middle", horizontal: "center" }
      worksheet.getCell('B9').value = 'Từ ngày ' + moment(oldDate).format('DD/MM/YYYY') + ' đến ngày ' + moment().format('DD/MM/YYYY') + ', CÔNG TY CỐ PHẦN CHÂU Á THÁI BÌNH DƯƠNG đã cung cấp cho Quý đại lý các mặt hàng với'

      #addData OrderDetail
      beginRowData = addDataInExcelCustomer(worksheet, orderLists, beginRowData)

      if returnLists.length > 0
        #add Head Table Return
        getRow = worksheet.getRow(beginRowData)
        returnHead = []; returnHead[2] = 'HÀNG TRẢ VỀ'; getRow.values = returnHead
        getRow.getCell(2).border = fullBorder
        worksheet.getCell('B'+beginRowData).alignment = { vertical: "middle", horizontal: "left" }
        worksheet.mergeCells('B' + beginRowData + ':M' + beginRowData)
        beginRowData +=1

        #addData ReturnDetail
        beginRowData = addDataInExcelCustomer(worksheet, returnLists, beginRowData)

      #addFooter
      keys = [
        undefined
        "Nợ tồn đầu kỳ:"
        "Phát sinh trong kỳ:"
        "Thu nợ trong kỳ:"
        "Trừ hàng trả về:"
        "Nợ cuối kỳ:"
      ]
      values = [
        "VNĐ"
        (customer.debtRequiredCash ? 0) + (customer.debtBeginCash ? 0)
        customer.debtSaleCash + customer.debtIncurredCash
        customer.paidSaleCash + customer.paidIncurredCash
        customer.returnSaleCash
        customer.calculateTotalCash()
      ]

      for i in [0..5]
        worksheet.getCell('E'+beginRowData).value     = keys[i]
        worksheet.getCell('E'+beginRowData).font      = { name: "Times New Roman", family: 2, size: 12, bold: true }
        worksheet.getCell('E'+beginRowData).alignment = { vertical: "middle", horizontal: "left" }

        worksheet.getCell('F'+beginRowData).value     = values[i]
        worksheet.getCell('F'+beginRowData).font      = { name: "Times New Roman", family: 2, size: 12, bold: true }
        worksheet.getCell('F'+beginRowData).alignment = { vertical: "middle", horizontal: "right" }
        worksheet.mergeCells('F'+beginRowData+':G'+beginRowData)

        worksheet.getCell('B'+beginRowData).font      = { name: "Times New Roman", family: 2, size: 12, bold: true }
        worksheet.getCell('B'+beginRowData).alignment = { vertical: "middle", horizontal: "left" }
        beginRowData+=1

      beginRowData += 1
      worksheet.getCell('B'+beginRowData).value = 'XÁC NHẬN CỦA ĐẠI LÝ'
      worksheet.getCell('B'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }
      worksheet.getCell('B'+beginRowData).font = { name: "Times New Roman", family: 2, size: 12, bold: true }
      worksheet.mergeCells('B'+beginRowData+':D'+beginRowData)

      worksheet.getCell('J'+beginRowData).value = 'KẾ TOÁN PHỤ TRÁCH'
      worksheet.getCell('J'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }
      worksheet.getCell('J'+beginRowData).font = { name: "Times New Roman", family: 2, size: 12, bold: true }
      worksheet.mergeCells('J'+beginRowData+':K'+beginRowData)

      beginRowData += 4
      worksheet.getCell('J'+beginRowData).value = 'PHẠM THỊ HUỆ'
      worksheet.getCell('J'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }
      worksheet.getCell('J'+beginRowData).font = { name: "Times New Roman", family: 2, size: 12, bold: true }
      worksheet.mergeCells('J'+beginRowData+':K'+beginRowData)



      fileName = 'template/cong_no.xlsx'
      workbook.xlsx.writeFile(publicPath+ fileName).then ->
        path = publicPath+ fileName
        res.download path

app.get '/download/order/:id', (req, res) ->
  console.log req.params.id
  if order = Schema.orders.findOne(req.params.id)
    customer = Schema.customers.findOne(order.buyer)
    merchant = Schema.merchants.findOne(order.merchant)

    for detail, index in order.details
      if product = Schema.products.findOne(detail.product)
        order.details[index].array = [
          index+1
          product.name
          product.unitName()
          if product.units[1] then Math.floor(detail.basicQuantity/product.units[1].conversion) else 0
          detail.basicQuantity
#          detail.price
#          detail.price * detail.basicQuantity
        ]

    workbook  = new Excel.Workbook()
    workbook.xlsx.readFile(publicPath+'template/PXK.xlsx').then ->
      worksheet = workbook.getWorksheet("xuat_kho")

      resetValueHead(worksheet)
      for row in [1..100]
        worksheet.getRow(row).font      = { name: "Times New Roman", family: 2, size: 12, bold: false }
        worksheet.getRow(row).alignment = { vertical: "middle", horizontal: "center" }


      worksheet.getColumn(i).numFmt = "#,##0" for i in [4..7]

      exportDate = 'Ngày ' + moment().format('DD') + ' tháng ' + moment().format('MM') + ' năm ' + moment().format('YYYY')

      worksheet.getRow(2).font = { name: "Times New Roman", family: 2, size: 12, bold: true }
      worksheet.getCell('B2').value = 'CÔNG TY CỔ PHẦN CHÂU Á THÁI BÌNH DƯƠNG'

      worksheet.getCell('B3').value = '60 Trần Đại Nghĩa, Ninh Kiều, Cần Thơ'
      worksheet.getCell('B4').value = 'ĐT: 08.6295.9999   Fax: 08.6294.9999'

      worksheet.getCell('A5').value     = 'PHIẾU XUẤT KHO'
      worksheet.getCell('A5').alignment = { vertical: "middle", horizontal: "center" }
      worksheet.getCell('A5').font      = { name: "Times New Roman", family: 2, size: 16, bold: true }

      customerBillNo = Helpers.orderCodeCreate(customer?.saleBillNo ? '00')
      merchantBillNo = Helpers.orderCodeCreate(merchant?.saleBillNo ? '00')
      worksheet.getCell('A6').value     = 'Số: ' + customerBillNo + '/' + merchantBillNo
      worksheet.getCell('A6').alignment = { vertical: "middle", horizontal: "center" }
      worksheet.getCell('A6').font      = { name: "Times New Roman", family: 2, size: 12, bold: false }

      worksheet.getCell('A7').value     = exportDate
      worksheet.getCell('A7').alignment = { vertical: "middle", horizontal: "center" }
      worksheet.getCell('A7').font      = { name: "Times New Roman", family: 2, size: 12, bold: false }

      worksheet.getCell('B8').value = 'Người nhận hàng: ' + customer?.name
      worksheet.getCell('B8').font  = { name: "Times New Roman", family: 2, size: 12, bold: true }
      worksheet.getCell('B8').alignment = { vertical: "middle", horizontal: "left" }

      worksheet.getCell('B9').value = 'Địa chỉ: ' + customer?.profiles?.address
      worksheet.getCell('B9').alignment = { vertical: "middle", horizontal: "left" }

      worksheet.getCell('G9').value = 'Lý do xuất: Xuất bán'
      worksheet.getCell('G9').alignment = { vertical: "middle", horizontal: "left" }

      worksheet.getCell('B10').value = 'Điện thoại: ' + customer?.profiles?.phone
      worksheet.getCell('B10').alignment = { vertical: "middle", horizontal: "left" }

      worksheet.getCell('G10').value = 'Vận chuyển:'
      worksheet.getCell('G10').alignment = { vertical: "middle", horizontal: "left" }

      worksheet.getCell('B11').value = 'Xuất tại kho: Asia Pacific'
      worksheet.getCell('B11').alignment = { vertical: "middle", horizontal: "left" }



      for row in [12,13]
        worksheetRow = worksheet.getRow(row)
        worksheetRow.getCell(cell).border = fullBorder for cell in [1..8]

      #writeData to Excel
      beginRowData = 14
      beginRowData = addDataInExcelOrder(worksheet, [order], beginRowData, 1, 8)


      #add Footer
      worksheet.getCell('A'+beginRowData).value = '(Mọi thắc mắc về hàng hóa, vui lòng liên hệ số điện thoại 08.6295.9999 trong vòng 03 ngày từ ngày nhận hàng)'
      worksheet.getCell('A'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }
      worksheet.mergeCells('A'+beginRowData+':H'+beginRowData)
      beginRowData += 1

      worksheet.getCell('B'+beginRowData).value = 'Địa chỉ chành:' + customer.deliveryAdd
      worksheet.getCell('B'+beginRowData).alignment = { vertical: "middle", horizontal: "left" }
      beginRowData +=1

      worksheet.getCell('H'+beginRowData).value     = exportDate
      worksheet.getCell('H'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }
      worksheet.getCell('H'+beginRowData).font      = { name: "Times New Roman", family: 2, size: 12, bold: false }
#      worksheet.mergeCells('G'+beginRowData+':H'+beginRowData)
      beginRowData += 1

      worksheet.getCell('B'+beginRowData).value     = 'Người nhận hàng'
      worksheet.getCell('B'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }

      worksheet.getCell('C'+beginRowData).value = 'Kiểm soát 1'
      worksheet.getCell('C'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }
      worksheet.mergeCells('C'+beginRowData+':D'+beginRowData)

      worksheet.getCell('E'+beginRowData).value = 'Kiểm soát 2'
      worksheet.getCell('E'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }
      worksheet.mergeCells('E'+beginRowData+':F'+beginRowData)

      worksheet.getCell('G'+beginRowData).value = 'Thủ kho'
      worksheet.getCell('G'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }

      worksheet.getCell('H'+beginRowData).value = 'Người lập phiếu'
      worksheet.getCell('H'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }
      beginRowData += 4

      worksheet.getCell('C'+beginRowData).value = 'NG. ĐÌNH LỊCH'
      worksheet.getCell('C'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }
      worksheet.mergeCells('C'+beginRowData+':D'+beginRowData)

      worksheet.getCell('E'+beginRowData).value = 'NG. ĐÌNH THĂNG'
      worksheet.getCell('E'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }
      worksheet.mergeCells('E'+beginRowData+':F'+beginRowData)

      worksheet.getCell('G'+beginRowData).value = 'NGUYỄN HỮU HOÀNG'
      worksheet.getCell('G'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }

      worksheet.getCell('H'+beginRowData).value = 'PHAN THỊ ĐỊNH'
      worksheet.getCell('H'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }



      fileName = 'template/xuat_kho.xlsx'
      workbook.xlsx.writeFile(publicPath+ fileName).then ->
        path = publicPath+ fileName
        res.download path



addExcelHead = (worksheet) ->
  worksheet.getCell("A1").value = "CÔNG TY CỔ PHẦN CHÂU Á THÁI BÌNH DƯƠNG"
  worksheet.mergeCells("A1:F1")
  worksheet.getCell("A2").value = "60 Trần Đại Nghĩa, Ninh Kiều, Cần Thơ"
  worksheet.mergeCells("A2:F2")
  worksheet.getCell("A3").value = "BẢNG ĐỐI CHIẾU CÔNG NỢ"
  worksheet.mergeCells("A3:O3")
  worksheet.getCell("A4").value = "(từ ngày 01/03/2015 đến ngày 31/08/2015)"
  worksheet.mergeCells("A4:O4")

  worksheet.getCell("A5").value = "Kính gởi Khách hàng: "
  worksheet.mergeCells("A5:D5")
  worksheet.getCell("I5").value = "Địa chỉ: "
  worksheet.mergeCells("I5:M5")


  worksheet.getCell("A6").value = 'Trước hết, CÔNG TY CỐ PHẦN CHÂU Á THÁI BÌNH DƯƠNG xin được gửi tới Quý khách hàng lời cảm ơn chân thành vì sự ủng hộ nhiệt tình '
  worksheet.mergeCells("A6:M6")
  worksheet.getCell("A7").value = 'dành cho Công ty chúng tôi trong thời gian qua.'
  worksheet.mergeCells("A7:M7")
  worksheet.getCell("A8").value = 'Từ ngày 01/03/2015 đến ngày 31/08/2015, CÔNG TY CỐ PHẦN CHÂU Á THÁI BÌNH DƯƠNG đã cung cấp cho Quý đại lý các mặt hàng với'
  worksheet.mergeCells("A8:M8")
  worksheet.getCell("A9").value = 'chi tiết như sau:'
  worksheet.mergeCells("A9:M9")


getOrderLists = (customerId) ->
  orderIndex = 1
  Schema.orders.find({
    buyer      : customerId
    orderType  : Enums.getValue('OrderTypes', 'success')
    orderStatus: Enums.getValue('OrderStatus', 'finish')
  }).map((order) ->
    for detail, index in order.details
      if product = Schema.products.findOne(detail.product)
        fullName     = product.name.split('-')
        productName  = fullName[0].replace(/^\s*/, "").replace(/\s*$/, "")
        productSkull = if fullName[1] then fullName[1].replace(/^\s*/, "").replace(/\s*$/, "") else ""
        unitQuantity = if product.units[1] then Math.floor(detail.basicQuantity/product.units[1].conversion) else 0

        if index is 0
          detailIndex = orderIndex
          orderIndex += 1
        else
          detailIndex = ''


        order.details[index].array = [
          undefined
          detailIndex
          order.orderCode
          moment(order.successDate).format('DD/MM/YYYY')
          productName.toString()
          productSkull
          product.unitName()
          unitQuantity
          detail.basicQuantity
          detail.price
          detail.price * detail.basicQuantity
          ''
          ''
        ]
    order
  )

getReturnLists = (customerId)->
  returnIndex = 1
  Schema.returns.find({
    owner       : customerId
    returnType  : Enums.getValue('ReturnTypes', 'customer')
    returnStatus: Enums.getValue('ReturnStatus', 'success')
  }).map((currentReturn) ->
    for detail, index in currentReturn.details
      if product = Schema.products.findOne(detail.product)
        fullName     = product.name.split('-')
        productName  = fullName[0].replace(/^\s*/, "").replace(/\s*$/, "")
        productSkull = if fullName[1] then fullName[1].replace(/^\s*/, "").replace(/\s*$/, "") else ""
        unitQuantity = if product.units[1] then Math.floor(detail.basicQuantity/product.units[1].conversion) else 0
        if index is 0
          detailIndex = returnIndex
          returnIndex += 1
        else
          detailIndex = ''

        currentReturn.details[index].array = [
          undefined
          detailIndex
          currentReturn.returnCode
          moment(currentReturn.successDate).format('DD/MM/YYYY')
          productName.toString() if productName
          productSkull
          product.unitName()
          unitQuantity
          detail.basicQuantity
          detail.price
          detail.price * detail.basicQuantity
          ''
          ''
        ]
    currentReturn
  )


addDataInExcelCustomer = (worksheet, dataLists, beginRowData, quantities = 0, totalPrice = 0) ->
  #add detail
  for item in dataLists
    for detail in item.details
      console.log detail.array
      getRow = worksheet.getRow(beginRowData)
      for value, index in detail.array
        getRow.getCell(index+1).value  = value
        getRow.getCell(index+1).border = fullBorder

        if _.contains([5], index+1)
          getRow.getCell(index+1).font = { name: "Times New Roman", family: 2, size: 12, bold: true }
          getRow.getCell(index+1).alignment = { vertical: "middle", horizontal: "left" }
        if _.contains([10,11], index+1)
          getRow.getCell(index+1).alignment = { vertical: "middle", horizontal: "right" }

        quantities += value if index+1 is 8
        totalPrice += value if index+1 is 11
      beginRowData += 1

  #add sumDetail
  getRow = worksheet.getRow(beginRowData)
  for index in [2..13]
    if index is 2
      getRow.getCell(index).value  = "TỔNG"
      getRow.getCell(index).font = { name: "Times New Roman", family: 2, size: 12, bold: true }
    else if index is 8
      getRow.getCell(index).value  = quantities
      getRow.getCell(index).font = { name: "Times New Roman", family: 2, size: 12, bold: true }
    else if index is 11
      getRow.getCell(index).value     = totalPrice
      getRow.getCell(index).font      = { name: "Times New Roman", family: 2, size: 12, bold: true }
      getRow.getCell(index).alignment = { vertical: "middle", horizontal: "right" }
    else
      getRow.getCell(index).value  = ''
    getRow.getCell(index).border = fullBorder

  #set alignment sumDetail
  worksheet.getCell('B'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }
  worksheet.mergeCells('B'+beginRowData+':G'+beginRowData)
  beginRowData += 1

  beginRowData


addDataInExcelOrder = (worksheet, dataLists, beginRowData, columnStart, columnEnd) ->
  #add detail
  quantities = 0; basicQuantities = 0; totalPrice = 0
  for item in dataLists
    for detail in item.details
      getRow = worksheet.getRow(beginRowData)
      for column in [columnStart..columnEnd]
        getRow.getCell(column).value  = if detail.array[column-1] then detail.array[column-1] else ''
        getRow.getCell(column).border = fullBorder

        getRow.getCell(column).alignment = { vertical: "middle", horizontal: "left" } if column is 2

        if column is 4 then basicQuantities += detail.array[column-1]
        else if column is 5 then quantities += detail.array[column-1]
        else if column is 7 then totalPrice += detail.array[column-1]

      beginRowData += 1

  #add sumDetail
  getRow = worksheet.getRow(beginRowData)
  for column in [columnStart..columnEnd]
    if column is 2 then      getRow.getCell(column).value  = "TỔNG"
    else if column is 4 then getRow.getCell(column).value  = basicQuantities
    else if column is 5 then getRow.getCell(column).value  = quantities
#    else if index is 7 then getRow.getCell(index).value  = totalPrice
    else                    getRow.getCell(column).value  = ''
    getRow.getCell(column).border = fullBorder

  #set alignment sumDetail
  worksheet.getCell('B'+beginRowData).alignment = { vertical: "middle", horizontal: "center" }
  beginRowData += 1

  beginRowData



resetValueHead = (worksheet, beginRow = 0) ->
  worksheet.eachRow (row, rowNumber) ->
    if row > beginRow
      getRow = worksheet.getRow(rowNumber)
      for value, index in worksheet.getRow(rowNumber).values
        getRow.getCell(index+1).value     = undefined
        getRow.getCell(index+1).border    = {}