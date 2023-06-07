$(document).on 'turbolinks:load', ->
  if document.getElementById('nrdb_decks')?

    deckPlaceholders = $('#nrdb_decks_selected li').get()
    corpPlaceholder = deckPlaceholders[0]
    runnerPlaceholder = deckPlaceholders[1]

    $.get('https://netrunnerdb.com/api/2.0/public/cards', (nrdbCards) =>
      nrdbCardsByCode = new Map(nrdbCards.data.map((card) => [card.code, card]))

      readDecks = () =>
        for item from $('#nrdb_decks li').get()
          $item = $(item)
          deck = readDeckFrom$Item($item)
          $item.attr('data-side', deck.details.side_id)
          $item.prepend($('<div/>', {class: 'deck-list-identity', css: {
            'background-image':'url(https://static.nrdbassets.com/v1/small/'+deck.details.identity_nrdb_code+'.jpg)'}}))
          $item.append($('<small/>', text: deck.details.identity_title))

      readDeckFrom$Item = ($item) =>
        nrdbDeck = JSON.parse($item.attr('data-deck'))
        return readNrdbDeck(nrdbDeck)
      readNrdbDeck = (nrdbDeck) =>
        details = { name: nrdbDeck.name, nrdb_uuid: nrdbDeck.uuid }
        for code, count of nrdbDeck.cards
          nrdbCard = nrdbCardsByCode.get(code)
          if nrdbCard.type_code == 'identity'
            identity = nrdbCard
            details.identity_title = nrdbCard.title
            details.identity_nrdb_code = nrdbCard.code
            details.side_id = nrdbCard.side_code
            details.min_deck_size = nrdbCard.minimum_deck_size
            details.max_influence = nrdbCard.influence_limit
        cards = []
        for code, count of nrdbDeck.cards
          nrdbCard = nrdbCardsByCode.get(code)
          if nrdbCard.type_code != 'identity'
            if identity.faction_code == nrdbCard.faction_code
              influence_spent = 0
            else
              influence_spent = nrdbCard.faction_cost
            cards.push({
              title: nrdbCard.title,
              quantity: count,
              influence: influence_spent
            })
        return {details: details, cards: cards}

      window.selectDeck = (id) =>
        $item = $('#nrdb_deck_'+id)
        deck = readDeckFrom$Item($item)
        side = deck.details.side_id
        activeBefore = $item.hasClass('active')
        $('#nrdb_decks li[data-side*='+side+']').removeClass('active')
        $item.toggleClass('active', !activeBefore)
        $('#nrdb_decks_selected').empty()
        cloneToSelectedOrElse($('#nrdb_decks li.active[data-side*=corp]'), corpPlaceholder)
        cloneToSelectedOrElse($('#nrdb_decks li.active[data-side*=runner]'), runnerPlaceholder)
        setDeckInputs(deck, $item.hasClass('active'))

      cloneToSelectedOrElse = ($item, ifNotPresent) =>
        if $item.length > 0
          $clone = $item.clone().removeClass('active').addClass('selected-deck').removeAttr('id')
          $clone.find('.deck-list-identity').removeClass('deck-list-identity').addClass('selected-deck-identity')
          $clone.find('small').remove()
          $clone.prop('onclick', null).off('click')
          $deselect = $('<a/>', {'class': 'float-right', 'title': 'Deselect', 'href': '#'})
          $deselect.append($('<i/>', {'class': 'fa fa-close'}))
          $deselect.on('click', (e) =>
            e.preventDefault()
            window.selectDeck(readDeckFrom$Item($item).details.nrdb_uuid))
          $clone.prepend($deselect)
          $clone.appendTo('#nrdb_decks_selected')
        else
          $(ifNotPresent).appendTo('#nrdb_decks_selected')

      setDeckInputs = (deck, active) =>
        side = deck.details.side_id
        if active
          $('#player_'+side+'_deck').val(JSON.stringify(deck))
          $('#player_'+side+'_identity').val(deck.details.identity_title)
        else
          $('#player_'+side+'_deck').val('')
          $('#player_'+side+'_identity').val('')

      preselectDeck = (side) =>
        deckStr = $('#player_'+side+'_deck').val()
        if deckStr.length > 0
          window.selectDeck(JSON.parse(deckStr).details.nrdb_uuid)

      readDecks()
      preselectDeck('corp')
      preselectDeck('runner'))
