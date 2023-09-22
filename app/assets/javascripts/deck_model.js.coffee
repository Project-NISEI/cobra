$(document).on 'turbolinks:load', ->
  window.deckDisplayEnabled = () =>
    document.getElementById('display_decks')? || document.getElementById('display_pairing_decks')? || document.getElementById('display_player_decks')?

  if deckDisplayEnabled()
    window.readDecksFromInputs = () =>
      {
        corp: readSideDecks(
          'Corp Deck',
          $('#player_corp_deck_before'),
          $('#player_corp_deck')),
        runner: readSideDecks(
          'Runner Deck',
          $('#player_runner_deck_before'),
          $('#player_runner_deck'))
      }

    window.readPairingDecksFromInputs = () =>
      {
        player1: markViewOnlyDeck(readSideDecks($('#player1_name').val(), [], $('#player1_deck'))),
        player2: markViewOnlyDeck(readSideDecks($('#player2_name').val(), [], $('#player2_deck')))
      }

    window.readPlayerDecksFromInputs = () =>
      {
        corp: markViewOnlyDeck(readSideDecks('Corp Deck', [], $('#corp_deck'))),
        runner: markViewOnlyDeck(readSideDecks('Runner Deck', [], $('#runner_deck')))
      }

    markViewOnlyDeck = (decks) =>
      decks.viewOnly = true
      decks

    readSideDecks = (description, $beforeInput, $afterInput) =>
      after = readDeck($afterInput)
      if $beforeInput.length < 1
        before = after
      else
        before = readDeck($beforeInput)

      addDeckDiff({
        description: description,
        before: before,
        after: after,
        input: $afterInput
      })

    window.addDeckDiff = (decks) =>
      decks.diff = diffDecks(decks.before, decks.after)

      if decks.before.unset && !decks.after.unset
        decks.change_type = 'choose_deck'
      else if decks.before.details.nrdb_uuid != decks.after.details.nrdb_uuid
        decks.change_type = 'change_deck'
      else if decks.diff
        decks.change_type = 'change_cards'
      else
        decks.change_type = 'none'

      decks

    readDeck = ($input) =>
      deckStr = $input.val()
      if deckStr.length > 0
        deck = JSON.parse(deckStr)
        if !deck
          unsetDeck()
        else
          sortCards(deck.cards)
          deck
      else
        unsetDeck()

    unsetDeck = () =>
      {details: {}, cards: [], unset: true}

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
        else if countAfter > countBefore
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

    sortCards = (cards) =>
      cards.sort((a, b) =>
        if a.title > b.title
          1
        else if a.title < b.title
          -1
        else
          0)
