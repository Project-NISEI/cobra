$(document).on 'turbolinks:load', ->
  if document.getElementById('player_corp_deck')?
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

    readSideDecks = (description, $beforeInput, $afterInput) =>
      after = readDeck($afterInput)
      if $beforeInput.length < 1
        before = after
      else
        before = readDeck($beforeInput)

      addDiff({
        description: description,
        before: before,
        after: after
      })

    addDiff = (decks) =>
      decks.diff = diffDecks(decks.before, decks.after)

      if decks.before.unset
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
        sortCards(deck.cards)
        deck
      else
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

    sortCards = (cards) =>
      cards.sort((a, b) =>
        if a.title > b.title
          1
        else if a.title < b.title
          -1
        else
          0)
