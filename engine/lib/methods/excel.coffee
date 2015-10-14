Enums = Apps.Merchant.Enums
Meteor.methods
  customerExportExcel: (customerId)->
    if Meteor.isServer
      path = Meteor.npmRequire('path')
      basepath = path.resolve('.').split('.meteor')[0]
      console.log basepath
      Excel = Meteor.npmRequire('exceljs')
      workbook = new Excel.Workbook()
      worksheet = workbook.addWorksheet("cong_no")

  #      worksheet.addRow([]) for i in [0...12]
  #      worksheet.addRow([1,23,4,5,1,5,3]) for i in [0...12]
  #      workbook.xlsx.writeFile(basepath+'public/template/test.xlsx').then ->

      writeWorkbook = new Excel.Workbook()
      sheet   = writeWorkbook.addWorksheet("My Sheet")
      mySheet = writeWorkbook.getWorksheet("My Sheet")

      orderIndex = 1
      orderLists = Schema.orders.find({
        buyer      : customerId
        orderType  : Enums.getValue('OrderTypes', 'success')
        orderStatus: Enums.getValue('OrderStatus', 'finish')
      }).map(
        (order) ->
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
                detailIndex = undefined

              order.details[index].array = [
                undefined
                detailIndex
                order.orderCode.toString()
                new Date(order.successDate)
                productName.toString()
                productSkull
                product.unitName()
                unitQuantity
                detail.basicQuantity
                detail.price
                detail.price * detail.basicQuantity
              ]
          order
      )

      beginColumn = 12
      workbook.xlsx.readFile(basepath+'public/template/TBD.xlsx').then ->
        worksheet = workbook.getWorksheet("cong_no")
        worksheet.eachRow (row, rowNumber) ->
          getRow = worksheet.getRow(rowNumber)
          for value, index in worksheet.getRow(rowNumber).values
            getRow.getCell(index+1).value  = undefined
            getRow.getCell(index+1).border = {}

        for order in orderLists
          for detail in order.details
            getRow = worksheet.getRow(beginColumn)
            console.log detail.array
            for value, index in detail.array
              getRow.getCell(index+1).value  = value
            beginColumn += 1



        workbook.xlsx.writeFile(basepath+'seeds/testss.xlsx').then ->
          console.log 'ok'

  #        worksheet.eachRow (row, rowNumber) ->
  ##          console.log 'Row ' + rowNumber + ' = ' + JSON.stringify(row.values)
  #          console.log row.values
  #          mySheet.addRow([])
  #          mySheet.addRow(row.values)
  #          return


  #        writeWorkbook.xlsx.writeFile(basepath+'public/template/test.xlsx').then ->
