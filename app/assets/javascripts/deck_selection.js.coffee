$(document).on 'turbolinks:load', ->
  if document.getElementById('nrdb_decks')?

    deckPlaceholders = $('#nrdb_decks_selected li').get()
    corpPlaceholder = deckPlaceholders[0]
    runnerPlaceholder = deckPlaceholders[1]

    cloneToSelectedOrElse = ($element, ifNotPresent) =>
      if $element.length > 0
        id = $element.attr('data-deck-id')
        side = $element.attr('data-side')
        $clone = $element.clone().removeClass('active').addClass('selected-deck')
        $clone.find('.deck-list-identity').removeClass('deck-list-identity').addClass('selected-deck-identity')
        $clone.find('small').remove()
        $clone.prop('onclick', null).off('click')
        $deselect = $('<a/>', {'class': 'float-right', 'title': 'Deselect', 'href': '#'})
        $deselect.append($('<i/>', {'class': 'fa fa-close'}))
        $deselect.on('click', (e) =>
          e.preventDefault()
          selectDeck(id, side))
        $clone.prepend($deselect)
        $clone.appendTo('#nrdb_decks_selected')
      else
        $(ifNotPresent).appendTo('#nrdb_decks_selected')

    getDeckIdentityName = (deck, cards) =>
      cardsByCode = new Map(cards.data.map((card) => [card.code, card]))
      for code, count of deck.cards
        card = cardsByCode.get(code)
        if card.type_code == 'identity'
          return card.title

    setDeckInputs = (side, $deck) =>
      if $deck.length > 0
        $.get('https://netrunnerdb.com/api/2.0/public/cards', (cards) =>
          deckStr = $deck.attr('data-deck')
          $('#player_'+side+'_deck').val(deckStr)
          $('#player_'+side+'_deck_format').val('nrdb_v2')
          $('#player_'+side+'_identity').val(getDeckIdentityName(JSON.parse(deckStr), cards)))
      else
        $('#player_'+side+'_deck').val('')
        $('#player_'+side+'_deck_format').val('')
        $('#player_'+side+'_identity').val('')

    window.selectDeck = (id, side) =>
      activeBefore = $('#nrdb_deck_'+id).hasClass('active')
      $('#nrdb_decks li[data-side*='+side+']').removeClass('active')
      $('#nrdb_deck_'+id).toggleClass('active', !activeBefore)
      $('#nrdb_decks_selected').empty()
      $corp = $('#nrdb_decks li.active[data-side*=corp]')
      $runner = $('#nrdb_decks li.active[data-side*=runner]')
      cloneToSelectedOrElse($corp, corpPlaceholder)
      cloneToSelectedOrElse($runner, runnerPlaceholder)
      setDeckInputs(side, $('#nrdb_deck_'+id+'.active'))

    preselectDeck = (side) =>
      deckStr = $('#player_'+side+'_deck').val()
      if deckStr.length > 0
        window.selectDeck(JSON.parse(deckStr)['id'], side)

    preselectDeck('corp')
    preselectDeck('runner')
