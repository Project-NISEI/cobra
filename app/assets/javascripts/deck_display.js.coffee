$(document).on 'turbolinks:load', ->

  if document.getElementById('display_corp_deck')? && document.getElementById('player_corp_deck')?
    window.displayDecksFromInputs = () =>
      decks = readDecksFromInputs()
      maxCards = Math.max(decks.corp.after.cards.length, decks.runner.after.cards.length)
      displayDeck(decks.corp, $('#display_corp_deck'), maxCards)
      displayDeck(decks.runner, $('#display_runner_deck'), maxCards)

    readDecksFromInputs = () =>
      {
        corp: {
          description: 'Corp Deck',
          before: readDeck($('#player_corp_deck_before')),
          after: readDeck($('#player_corp_deck'))
        },
        runner: {
          description: 'Runner Deck',
          before: readDeck($('#player_runner_deck_before')),
          after: readDeck($('#player_runner_deck'))
        }
      }

    readDeck = ($input, side) =>
      deckStr = $input.val()
      if deckStr.length > 0
        JSON.parse(deckStr)
      else
        {details: {}, cards: [], unset: true}

    displayDeck = (decks, container, cardsTableSize) =>
      if decks.before.unset && decks.after.unset
        $(container).empty()
        return
      deck = decks.after
      diff = diffDecks(decks.before, decks.after)
      $(container).empty().append(
        deckSummaryTable(decks, diff),
        deckDiffTable(diff),
        identityTable(deck),
        cardsTable(deck, cardsTableSize),
        totalsTable(deck))

    deckSummaryTable = (decks, diff) =>
      return $('<table/>', {
        class: 'table table-bordered table-striped'
      }).append(
        $('<thead/>', {class: 'thead-dark'}).append(
          $('<tr/>').append(
            $('<th/>', {class: 'text-center deck-name-header', text: decks.description}))),
        $('<tbody/>')
          .append(deckNameRow(decks.after))
          .append(deckChangesRow(decks.after, decks.before, diff)))

    deckNameRow = (deck) =>
      if deck.details.name
        $('<tr/>').append($('<td/>').append(
          $('<a/>', {
            class: 'float-right',
            title: 'Edit Deck',
            href: 'https://netrunnerdb.com/en/deck/edit/' + deck.details.nrdb_uuid,
            target: '_blank'
          }).append(
            $('<i/>', {class: 'fa fa-external-link'})
          ),
          document.createTextNode(deck.details.name)
        ))
      else
        []

    deckChangesRow = (deck, deckBefore, diff) =>
      if deckBefore.unset
        [$('<tr/>').append($('<td/>').append('Not yet submitted'))]
      else if deckBefore.details.nrdb_uuid != deck.details.nrdb_uuid
        [$('<tr/>').append($('<td/>').append(
          $('<p/>', {text: 'Change not yet submitted. Previously submitted:'}),
          $('<p/>', {text: deckBefore.details.name, class: 'mb-0'})))]
      else if diff
        [$('<tr/>').append($('<td/>', {
          text: 'Changes not yet submitted. See below for differences from NetrunnerDB.'
        }))]
      else
        []

    deckDiffTable = (diff) =>
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
      if not deck.details.identity_title
        return []

      return $('<table/>', {
        class: 'table table-bordered table-striped'
      }).append(
        $('<thead/>', {'class': 'thead-dark'}).append(
          $('<tr/>').append(
            $('<th/>', {class: 'text-center deck-side-column', text: 'Min'}),
            $('<th/>', {class: 'text-center', text: 'Identity'}),
            $('<th/>', {class: 'text-center deck-side-column', text: 'Max'}))),
        $('<tbody/>').append(
          $('<tr/>').append(
            $('<td/>', {class: 'text-center', text: deck.details.min_deck_size}),
            $('<td/>', {text: deck.details.identity_title}),
            $('<td/>', {class: 'text-center', text: deck.details.max_influence}))))

    cardsTable = (deck, cardsTableSize) =>
      cards = deck.cards
      if not cards || cards.length < 1
        return []
      sortCards(cards)
      return $('<table/>', {
        class: 'table table-bordered table-striped'
      }).append(
        $('<thead/>', {'class': 'thead-dark'}).append(
          $('<tr/>').append(
            $('<th/>', {class: 'text-center deck-side-column', text: 'Qty'}),
            $('<th/>', {class: 'text-center', text: 'Card Name'}),
            $('<th/>', {class: 'text-center deck-side-column', text: 'Inf'}))),
        $('<tbody/>').append(cards.map((card) =>
          if card.influence > 0
            influence = card.influence
          else
            influence = ''
          $('<tr/>').append(
            $('<td/>', {class: 'text-center', text: card.quantity}),
            $('<td/>', {text: card.title}),
            $('<td/>', {class: 'text-center', text: influence})))
        ).append(emptyCardRows(cardsTableSize - cards.length)))

    emptyCardRows = (numRows) =>
      rows = []
      for i in [0...numRows]
        rows.push($('<tr/>').append(
          $('<td/>').append('&nbsp;'),
          $('<td/>').append('&nbsp;'),
          $('<td/>').append('&nbsp;')
        ))
      rows

    totalsTable = (deck) =>
      cards = deck.cards
      if not cards || cards.length < 1
        return []
      qty = cards.map((card) => card.quantity)
        .reduce(((partialSum, a) => partialSum + a), 0)
      influence = cards.map((card) => card.influence)
        .reduce(((partialSum, a) => partialSum + a), 0)
      return $('<table/>', {
        class: 'table table-bordered table-striped'
      }).append(
        $('<tbody/>').append(
          $('<tr/>').append(
            $('<td/>', {class: 'text-center table-light deck-side-column', text: qty}),
            $('<td/>', {class: 'text-center table-dark', text: 'Totals'}),
            $('<td/>', {class: 'text-center table-light deck-side-column', text: influence}))))

    diffDecks = (before, after) =>
      if before.unset || after.unset || before.details.nrdb_uuid != after.details.nrdb_uuid
        return null
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

    try
      displayDecksFromInputs()
    catch e
      console.log(e)
