$(document).on 'turbolinks:load', ->
  window.downloadDeckCsv = (deck) =>
    csv = 'Player,' + quoteCsvValue(deck.details.player_name) + '\n' +
      'Deck,' + quoteCsvValue(deck.details.name) + '\n' +
      'Min,Identity,Max\n' +
      deck.details.min_deck_size + ',' + quoteCsvValue(deck.details.identity_title) + ',' + deck.details.max_influence + '\n' +
      'Qty,Card Name,Inf\n'
    for card from deck.cards
      csv += card.quantity + ',' + quoteCsvValue(card.title) + ',' + card.influence + "\n"
    downloadCsv(deck.details.player_name + ' - ' + deck.details.name + '.csv', csv)

  downloadCsv = (filename, csv) =>
    csvData = new Blob([csv], {type: "text/csv"})
    a = document.createElement('a')
    a.href = URL.createObjectURL(csvData)
    a.download = filename
    a.click()

  quoteCsvValue = (string) =>
    '"' + string.replace('"', '""') + '"'
