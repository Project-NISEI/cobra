$(document).on 'turbolinks:load', ->
  if document.getElementById('nrdb_decks')?

    deckPlaceholders = $('#nrdb_decks_selected li').get()
    corpPlaceholder = deckPlaceholders[0]
    runnerPlaceholder = deckPlaceholders[1]

    $.get('https://netrunnerdb.com/api/2.0/public/cards', (nrdbCards) =>

      readDecks = () =>
        for item from $('#nrdb_decks li').get()
          $item = $(item)
          nrdbDeck = JSON.parse($item.attr('data-deck'))
          deck = readDeck(nrdbDeck)
          $item.attr('data-side', deck.details.side)
          $item.data('deck', deck)

      window.selectDeck = (id) =>
        $item = $('#nrdb_deck_'+id)
        deck = $item.data('deck')
        side = deck.details.side
        activeBefore = $item.hasClass('active')
        $('#nrdb_decks li[data-side*='+side+']').removeClass('active')
        $('#nrdb_deck_'+id).toggleClass('active', !activeBefore)
        $('#nrdb_decks_selected').empty()
        cloneToSelectedOrElse($('#nrdb_decks li.active[data-side*=corp]'), corpPlaceholder)
        cloneToSelectedOrElse($('#nrdb_decks li.active[data-side*=runner]'), runnerPlaceholder)
        setDeckInputs(deck, $item.hasClass('active'))

      cloneToSelectedOrElse = ($element, ifNotPresent) =>
        if $element.length > 0
          $clone = $element.clone().removeClass('active').addClass('selected-deck')
          $clone.find('.deck-list-identity').removeClass('deck-list-identity').addClass('selected-deck-identity')
          $clone.find('small').remove()
          $clone.prop('onclick', null).off('click')
          $deselect = $('<a/>', {'class': 'float-right', 'title': 'Deselect', 'href': '#'})
          $deselect.append($('<i/>', {'class': 'fa fa-close'}))
          $deselect.on('click', (e) =>
            e.preventDefault()
            selectDeck($element.attr('data-deck-id')))
          $clone.prepend($deselect)
          $clone.appendTo('#nrdb_decks_selected')
        else
          $(ifNotPresent).appendTo('#nrdb_decks_selected')

      readDeck = (nrdbDeck) =>
        cardsByCode = new Map(nrdbCards.data.map((card) => [card.code, card]))
        details = { name: nrdbDeck.name, nrdb_id: nrdbDeck.id }
        for code, count of nrdbDeck.cards
          card = cardsByCode.get(code)
          if card.type_code == 'identity'
            identity = card
            details.identity = card.title
            details.side = card.side_code
            details.min_deck_size = card.minimum_deck_size
            details.max_influence = card.influence_limit
        cards = []
        for code, count of nrdbDeck.cards
          card = cardsByCode.get(code)
          if card.type_code != 'identity'
            if identity.faction_code == card.faction_code
              influence_spent = 0
            else
              influence_spent = card.faction_cost
            cards.push({
              name: card.title,
              quantity: count,
              influence: influence_spent
            })
        return {details: details, cards: cards}

      setDeckInputs = (deck, active) =>
        side = deck.details.side
        if active
          $('#player_'+side+'_deck').val(JSON.stringify(deck))
          $('#player_'+side+'_identity').val(deck.details.identity)
        else
          $('#player_'+side+'_deck').val('')
          $('#player_'+side+'_identity').val('')

      preselectDeck = (side) =>
        deckStr = $('#player_'+side+'_deck').val()
        if deckStr.length > 0
          window.selectDeck(JSON.parse(deckStr).details.nrdb_id)

      readDecks()
      preselectDeck('corp')
      preselectDeck('runner'))
