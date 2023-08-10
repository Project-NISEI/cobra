$(document).on 'turbolinks:load', ->
  if document.getElementById('display_decks')? || document.getElementById('display_opponent_deck')?

    window.renderDecksDisplay = (decks) =>
      normaliseCardTables(decks)
      $('#display_decks').empty().append(
        renderDeck(decks.corp),
        renderDeck(decks.runner))
      any_changes = decks.corp.change_type != 'none' || decks.runner.change_type != 'none'
      $('#deck_changes_not_submitted_warning').toggleClass('d-none', !any_changes)

    normaliseCardTables = (decks) =>
      decks.corp.pad_cards = 0
      decks.runner.pad_cards = 0
      if decks.corp.change_type != decks.runner.change_type
        return decks
      if decks.corp.change_type != 'change_cards'
        max_cards = Math.max(decks.runner.after.cards.length, decks.corp.after.cards.length)
        decks.corp.pad_cards = max_cards - decks.corp.after.cards.length
        decks.runner.pad_cards = max_cards - decks.runner.after.cards.length
      decks

    renderDeck = (decks, opponent) =>
      $container = $('<div/>', {class: 'col-md-6'})
      if decks.before.unset && decks.after.unset
        return $container
      deck = decks.after
      $container.append(
        deckSummaryTable(decks, opponent),
        deckDiffTable(decks.diff),
        identityTable(deck),
        cardsTable(decks),
        totalsTable(deck))

    deckSummaryTable = (decks, opponent) =>
      return $('<table/>', {
        class: 'table table-bordered table-striped'
      }).append(
        $('<thead/>', {class: 'thead-dark'}).append(
          $('<tr/>').append(
            $('<th/>', {class: 'text-center deck-name-header', text: decks.description}))),
        $('<tbody/>')
          .append(deckNameRow(decks.after, opponent))
          .append(deckChangesRow(decks)))

    deckNameRow = (deck, opponent) =>
      if deck.details.name
        $('<tr/>').append($('<td/>')
          .append(deckNameButtons(deck, opponent))
          .append(document.createTextNode(deck.details.name)))
      else
        $('<tr/>').append($('<td/>')
          .append('None selected'))

    deckNameButtons = (deck, opponent) =>
      if opponent
        []
      else if deck.details.mine
        $('<a/>', {
          class: 'float-right dontprint',
          title: 'Edit Deck',
          href: 'https://netrunnerdb.com/en/deck/edit/' + deck.details.nrdb_uuid,
          target: '_blank'
        }).append(
          $('<i/>', {class: 'fa fa-external-link'})
        )
      else
        $('<div/>', {class: 'dropdown float-right dontprint'}).append(
          $('<a/>', {
            title: 'Export deck',
            href: '#',
            'data-toggle': 'dropdown',
            'aria-expanded': false
          }).append(
            $('<i/>', {class: 'fa fa-upload'})
          ),
          $('<div/>', {class: 'dropdown-menu'}).append(
            $('<a/>', {class: 'dropdown-item', href: '#'})
              .append('Copy to clipboard in NetrunnerDB format')
              .on('click', (e) =>
                e.preventDefault()
                copyDeckToClipboard(deck)),
            $('<a/>', {class: 'dropdown-item', href: '#'})
              .append('Download as a CSV spreadsheet')
              .on('click', (e) =>
                e.preventDefault()
                downloadDeckCsv(deck))
          )
        )

    copyDeckToClipboard = (deck) =>
      msg = ""
      for card from deck.cards
        msg += card.quantity + " " + card.title + "\n"
      navigator.clipboard.writeText(msg)
      alert("Copied to clipboard")

    deckChangesRow = (decks) =>
      switch decks.change_type
        when 'choose_deck' then $('<tr/>', {class: 'alert-warning'}).append(
          $('<td/>').append('Not yet submitted'))
        when 'change_deck' then $('<tr/>', {class: 'alert-warning'}).append(
          $('<td/>').append(
            'Change not yet submitted. Previously submitted:',
            $('<br/>'),
            $('<span/>', {text: decks.before.details.name})
          ))
        when 'change_cards' then $('<tr/>', {class: 'alert-warning'}).append(
          $('<td/>').append('Changes not yet submitted. See below for differences from NetrunnerDB.'))
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

    cardsTable = (decks) =>
      deck = decks.after
      cards = deck.cards
      if not cards || cards.length < 1
        return []
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
        ).append(emptyCardRows(decks.pad_cards)))

    emptyCardRows = (numRows) =>
      rows = []
      for i in [0...numRows]
        rows.push($('<tr/>', {class: 'd-none d-md-table-row'}).append(
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
        class: 'table table-bordered table-striped-horizontal'
      }).append(
        $('<tbody/>').append(
          $('<tr/>').append(
            $('<td/>', {class: 'text-center deck-side-column', text: qty}),
            $('<td/>', {class: 'text-center', text: 'Totals'}),
            $('<td/>', {class: 'text-center deck-side-column', text: influence}))))

    changeStr = (change) =>
      if change
        return change.quantity + ' ' + change.title
      else
        return ''

    if document.getElementById('display_decks')?
      try
        renderDecksDisplay(readDecksFromInputs())
      catch e
        console.log(e)

    $('#display_opponent_deck').append(
      renderDeck(readOpponentDeckFromInputs(), true))
