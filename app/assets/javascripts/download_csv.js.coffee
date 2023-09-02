$(document).on 'turbolinks:load', ->
  if document.getElementById('display_decks')? || document.getElementById('download_decks_button')?
    window.downloadDeckCsv = (deck) =>
      downloadCsv(deck.details.player_name + ' - ' + deck.details.name + '.csv',
        renderDecksCsv([deck]))

    renderDecksCsv = (decks) =>
      deck_separator = ',,'
      '' +
        forEachDeck(decks, (deck) => 'Player,' + quoteCsvValue(deck.details.player_name) + ',') + '\n' +
        forEachDeck(decks, (deck) => 'Deck,' + quoteCsvValue(deck.details.name) + ',') + '\n' +
        '\n' +
        forEachDeck(decks, (deck) => 'Min,Identity,Max') + '\n' +
        forEachDeck(decks, (deck) =>
          deck.details.min_deck_size + ',' +
            quoteCsvValue(deck.details.identity_title) + ',' +
            deck.details.max_influence
        ) + '\n' +
        '\n' +
        renderCardsCsv(decks)

    renderCardsCsv = (decks) =>
      maxCards = decks.reduce(getMaxCards, 0)
      csv = forEachDeck(decks, (deck) => 'Qty,"Card Name",Inf') + '\n'
      for i in [0...maxCards]
        csv += forEachDeck(decks, (deck) =>
          if i < deck.cards.length
            card = deck.cards[i]
            card.quantity + ',' + quoteCsvValue(card.title) + ',' + renderIfPositive(card.influence)
          else
            ',,'
        ) + '\n'
      csv + '\n' + forEachDeck(decks, (deck) =>
        deck.cards.reduce(addCardQuantity, 0) + ',Totals,' + deck.cards.reduce(addCardInfluence, 0))

    forEachDeck = (decks, render) =>
      decks.map(render).join(',,')

    getMaxCards = (max, deck) =>
      Math.max(max, deck.cards.length)

    addCardQuantity = (total, card) =>
      total + card.quantity

    addCardInfluence = (total, card) =>
      total + card.influence

    renderStreamingCsv = (players) =>
      'Player,"Include in coverage? (players were notified this may be necessary in the cut)"\n' +
        players.map((player) => quoteCsvValue(player.name) + ',' + renderOptOut(player))
          .join('\n')

    renderOptOut = (player) =>
      if player.include_in_stream
        'Yes'
      else
        'No'

    downloadCsv = (filename, csv) =>
      csvData = new Blob(["\ufeff" + csv], {type: "text/csv"}) # "\ufeff" lets Excel know it's Unicode encoded
      a = document.createElement('a')
      a.href = URL.createObjectURL(csvData)
      a.download = filename
      a.click()

    quoteCsvValue = (string) =>
      '"' + string.replaceAll('"', '""') + '"'

    renderIfPositive = (number) =>
      if number > 0
        number
      else
        ''

    downloadDecksSpinner = (spin) =>
      $('#download_decks_spinner').toggleClass('d-none', !spin)
      $('#download_decks_icon').toggleClass('d-none', spin)

    if document.getElementById('download_decks_button')?
      $('#download_decks_button').on('click', (e) =>
        e.preventDefault()
        downloadDecksSpinner(true)
        $.get($('#download_decks_path').val()).done((response) =>
          downloadCsv('Decks for ' + $('#download_tournament').val() + '.csv',
            renderDecksCsv(response))
        ).always(() => downloadDecksSpinner(false))
      )

    downloadStreamingSpinner = (spin) =>
      $('#download_streaming_spinner').toggleClass('d-none', !spin)
      $('#download_streaming_icon').toggleClass('d-none', spin)

    if document.getElementById('download_streaming_button')?
      $('#download_streaming_button').on('click', (e) =>
        e.preventDefault()
        downloadStreamingSpinner(true)
        $.get($('#download_streaming_path').val()).done((response) =>
          downloadCsv('Streaming information for ' + $('#download_tournament').val() + '.csv',
            renderStreamingCsv(response))
        ).always(() => downloadStreamingSpinner(false))
      )
