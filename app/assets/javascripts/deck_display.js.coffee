$(document).on 'turbolinks:load', ->
  window.displayDeck = (deck, container, deckBefore) =>
    $(container).empty().append(
      deckSummaryTable(deck, deckBefore),
      deckDiffTable(deck, deckBefore),
      identityTable(deck),
      cardsTable(deck))

  deckSummaryTable = (deck, deckBefore) =>
    if deck.details.side_id == 'corp'
      deckNameTitle = 'Corp Deck'
    else
      deckNameTitle = 'Runner Deck'

    rows = [deck.details.name]
    if deckBefore && deckBefore.details.nrdb_uuid != deck.details.nrdb_uuid
      rows.push('Selection changed from: ' + deckBefore.details.name)

    return $('<table/>', {
      class: 'table table-bordered table-striped'
    }).append(
      $('<thead/>', {'class': 'thead-dark'}).append(
        $('<tr/>').append(
          $('<th/>', {class: 'text-center deck-name-header', text: deckNameTitle}))),
      $('<tbody/>').append(rows.map((row) =>
        $('<tr/>').append($('<td/>', {text: row})))))

  deckDiffTable = (deck, deckBefore) =>
    if !deckBefore || deckBefore.details.nrdb_uuid != deck.details.nrdb_uuid
      return []

    diff = diffDecks(deckBefore, deck)
    maxLength = Math.max(diff.added.length, diff.removed.length)
    if maxLength == 0
      return []

    changes = []
    for i in [0..maxLength - 1]
      changes.push({
        added: changeStr(diff.added[i]),
        removed: changeStr(diff.removed[i])
      })

    return $('<table/>', {
      class: 'table table-bordered table-striped'
    }).append(
      $('<thead/>', {'class': 'thead-dark'}).append(
        $('<tr/>').append(
          $('<th/>', {class: 'text-center', text: 'Added'}),
          $('<th/>', {class: 'text-center', text: 'Removed'}))),
      $('<tbody/>').append(changes.map((change) =>
        $('<tr/>').append(
          $('<td/>', {text: change.added}),
          $('<td/>', {text: change.removed})))))

  identityTable = (deck) =>
    return $('<table/>', {
      class: 'table table-bordered table-striped'
    }).append(
      $('<thead/>', {'class': 'thead-dark'}).append(
        $('<tr/>').append(
          ['Min', 'Identity', 'Max'].map((title) =>
            $('<th/>', {class: 'text-center', text: title})))),
      $('<tbody/>').append(
        $('<tr/>').append(
          [deck.details.min_deck_size, deck.details.identity_title, deck.details.max_influence].map((value) =>
            $('<td/>', {text: value})))))

  cardsTable = (deck) =>
    cards = deck.cards
    sortCards(cards)
    return $('<table/>', {
      class: 'table table-bordered table-striped'
    }).append(
      $('<thead/>', {'class': 'thead-dark'}).append(
        $('<tr/>').append(
          ['Qty', 'Card Name', 'Inf'].map((title) =>
            $('<th/>', {class: 'text-center', text: title})))),
      $('<tbody/>').append(cards.map((card) =>
        if card.influence > 0
          influence = card.influence
        else
          influence = ''
        $('<tr/>').append(
          [card.quantity, card.title, influence].map((value) => $('<td/>', {text: value}))))))

  diffDecks = (before, after) =>
    added = []
    removed = []
    countsBefore = cardCountsByTitle(before)
    countsAfter = cardCountsByTitle(after)
    for title, countBefore of countsBefore
      countAfter = countsAfter[title]
      if !countAfter
        removed.push({title: title, quantity: countBefore})
      else if countAfter < countBefore
        removed.push({title: title, quantity: countBefore - countAfter})
    for title, countAfter of countsAfter
      countBefore = countsBefore[title]
      if !countBefore
        added.push({title: title, quantity: countAfter})
      else if countsAfter > countBefore
        added.push({title: title, quantity: countAfter - countBefore})
    sortCards(added)
    sortCards(removed)
    return {added: added, removed: removed}

  cardCountsByTitle = (deck) =>
    countByTitle = {}
    countByTitle[deck.details.identity_title] = 1
    for card from deck.cards
      countByTitle[card.title] = card.quantity
    return countByTitle

  changeStr = (change) =>
    if change
      return change.quantity + ' ' + change.title
    else
      return ''

  sortCards = (cards) =>
    cards.sort((a, b) =>
      if a.title > b.title
        1
      else if a.title < b.title
        -1
      else
        0)
