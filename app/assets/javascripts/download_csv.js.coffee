$(document).on 'turbolinks:load', ->
  window.downloadCsv = (filename, csv) =>
    csvData = new Blob([csv], {type: "text/csv"})
    a = document.createElement('a')
    a.href = URL.createObjectURL(csvData)
    a.download = filename
    a.click()

  window.quoteCsvValue = (string) =>
    '"' + string.replace('"', '""') + '"'
