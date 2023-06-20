$(document).on 'turbolinks:load', ->
  window.displayDeck = (deck, container, deckBefore) =>
    if deckBefore && deckBefore.details.nrdb_uuid == deck.details.nrdb_uuid
      diff = diffDecks(deckBefore, deck)
    else
      diff = null

    $(container).empty().append(
      deckSummaryTable(deck, deckBefore, diff),
      deckDiffTable(deck, deckBefore, diff),
      identityTable(deck),
      cardsTable(deck),
      totalsTable(deck))

  deckSummaryTable = (deck, deckBefore, diff) =>
    if deck.details.side_id == 'corp'
      deckNameTitle = 'Corp Deck'
    else
      deckNameTitle = 'Runner Deck'

    if deckBefore && deckBefore.details.nrdb_uuid != deck.details.nrdb_uuid
      deckChangesRow = [$('<tr/>').append($('<td/>').append(
        $('<p/>', {text: 'Deck not yet submitted. Previous selection:'}),
        $('<p/>', {text: deckBefore.details.name, class: 'mb-0'})))]
    else if diff
      deckChangesRow = [$('<tr/>').append($('<td/>', {
        text: 'Changes not yet submitted. See below for differences from NetrunnerDB.'
      }))]
    else
      deckChangesRow = []

    $editDeck = $('<a/>', {
      class: 'float-right',
      title: 'Edit Deck',
      href: 'https://netrunnerdb.com/en/deck/edit/' + deck.details.nrdb_uuid,
      target: '_blank'
    })
    $editDeck.append($('<i/>', {class: 'fa fa-external-link'}))

    return $('<table/>', {
      class: 'table table-bordered table-striped'
    }).append(
      $('<thead/>', {class: 'thead-dark'}).append(
        $('<tr/>').append(
          $('<th/>', {class: 'text-center deck-name-header', text: deckNameTitle}))),
      $('<tbody/>')
        .append($('<tr/>').append($('<td/>').append($editDeck).append(document.createTextNode(deck.details.name))))
        .append(deckChangesRow))

  deckDiffTable = (deck, deckBefore, diff) =>
    if not diff
      return []

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

  totalsTable = (deck) =>
    cards = deck.cards
    qty = cards.map((card) => card.quantity)
      .reduce(((partialSum, a) => partialSum + a), 0)
    influence = cards.map((card) => card.influence)
      .reduce(((partialSum, a) => partialSum + a), 0)
    return $('<table/>', {
      class: 'table table-bordered table-striped'
    }).append(
      $('<tbody/>').append(
        $('<tr/>').append(
          $('<td/>', {class: 'text-center table-light', text: qty}),
          $('<td/>', {class: 'text-center table-dark', text: 'Totals'}),
          $('<td/>', {class: 'text-center table-light', text: influence}))))

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
    if added.length + removed.length == 0
      return null
    else
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
