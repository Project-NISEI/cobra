$(document).on 'turbolinks:load', ->
  if document.getElementById('nrdb_decks')?

    corpPlaceholder = $('#nrdb_corp_selected li').get()[0]
    runnerPlaceholder = $('#nrdb_runner_selected li').get()[0]

    nrdbPrintingsById = new Map()

    readDecks = () =>
      nrdbDecks = $('#nrdb_decks li')
        .map((index, item) => JSON.parse($(item).attr('data-deck')))
        .get()

      printingIds = new Set(nrdbDecks.flatMap((deck) => Object.keys(deck.cards)))
      printingIdsStr = Array.from(printingIds).join()
      $.get({
        url: 'https://api-preview.netrunnerdb.com/api/v3/public/printings',
        data: {
          'fields[printings]': 'card_id,card_type_id,title,side_id,faction_id,minimum_deck_size,influence_limit,influence_cost',
          'filter[id]': printingIdsStr,
          'page[limit]': 1000
        },
        success: (response) =>
          readDecksWithPrintingsResponse(nrdbDecks, new Array(), response)
      })

    readDecksWithPrintingsResponse = (nrdbDecks, nrdbPrintingsBefore, response) =>
      nrdbPrintings = nrdbPrintingsBefore.concat(response.data)
      if response.links.next?
        $.get({
          url: response.links.next,
          success: (response) =>
            readDecksWithPrintingsResponse(nrdbDecks, nrdbPrintings, response)
        })
      else
        for nrdbPrinting from nrdbPrintings
          nrdbPrintingsById.set(nrdbPrinting.id, nrdbPrinting)
        readDecksWithPrintings(nrdbDecks)

    readDecksWithPrintings = (nrdbDecks) =>
      $('#nrdb_corp_decks').empty()
      $('#nrdb_runner_decks').empty()
      for nrdbDeck from nrdbDecks
        $item = $('#nrdb_deck_' + nrdbDeck.uuid)
        deck = readNrdbDeck(nrdbDeck)
        side = deck.details.side_id
        $item.attr('data-side', side)
        $item.prepend($('<div/>', {
          class: 'deck-list-identity', css: {
            'background-image': 'url(https://static.nrdbassets.com/v1/small/' + deck.details.identity_nrdb_printing_id + '.jpg)'
          }
        }))
        $item.append($('<small/>', text: deck.details.identity_title))
        $('#nrdb_' + side + '_decks').append($item)
      updateDecksFromNrdb(readDecksFromInputs())
      decks = readDecksFromInputs()
      renderDeckSelection(decks)
      renderDecksDisplay(decks)
      for corp from $('#nrdb_corp_decks li.active').get()
        corp.scrollIntoView(false)
      for runner from $('#nrdb_runner_decks li.active').get()
        runner.scrollIntoView(false)

    updateDecksFromNrdb = (decks) =>
      updateDeckFromNrdb('corp', decks.corp.after)
      updateDeckFromNrdb('runner', decks.runner.after)

    updateDeckFromNrdb = (side, deck) =>
      $item = $('#nrdb_deck_' + deck.details.nrdb_uuid)
      if $item.length == 0
        return
      updated = readDeckFrom$Item($item)
      $('#player_' + side + '_deck').val(JSON.stringify(updated))
      $('#player_' + side + '_identity').val(updated.details.identity_title)

    readDeckFrom$Item = ($item) =>
      nrdbDeck = JSON.parse($item.attr('data-deck'))
      return readNrdbDeck(nrdbDeck)

    readNrdbDeck = (nrdbDeck) =>
      details = {name: nrdbDeck.name, nrdb_uuid: nrdbDeck.uuid, mine: true}
      for code, count of nrdbDeck.cards
        attributes = nrdbPrintingsById.get(code).attributes
        if attributes.card_type_id.endsWith('identity')
          identity = attributes
          details.identity_title = attributes.title
          details.identity_nrdb_printing_id = code
          details.identity_nrdb_card_id = attributes.card_id
          details.side_id = attributes.side_id
          details.min_deck_size = attributes.minimum_deck_size
          details.max_influence = attributes.influence_limit
      cards = []
      for code, count of nrdbDeck.cards
        attributes = nrdbPrintingsById.get(code).attributes
        if !attributes.card_type_id.endsWith('identity')
          if identity.faction_id == attributes.faction_id
            influence_spent = 0
          else
            influence_spent = attributes.influence_cost * count
          cards.push({
            title: attributes.title,
            quantity: count,
            influence: influence_spent,
            nrdb_card_id: attributes.card_id,
            nrdb_printing_id: code
          })
      return {details: details, cards: cards}

    window.selectDeck = (id) =>
      $item = $('#nrdb_deck_' + id)
      if $item.length == 0
        return
      deck = readDeckFrom$Item($item)
      setDeckSelected(deck, !$item.hasClass('active'))

    undoDeckSelection = (side) =>
      deck = JSON.parse($('#player_' + side + '_deck_before').val())
      setDeckSelected(deck, true)

    setDeckSelected = (deck, active) =>
      side = deck.details.side_id
      if active
        setSideDeckSelected(side, deck)
      else
        setSideDeckSelected(side, null)

    setSideDeckSelected = (side, deck) =>
      if deck
        $('#player_' + side + '_deck').val(JSON.stringify(deck))
        $('#player_' + side + '_identity').val(deck.details.identity_title)
      else
        $('#player_' + side + '_deck').val('')
        $('#player_' + side + '_identity').val('')
      decks = readDecksFromInputs()
      renderDeckSelection(decks)
      renderDecksDisplay(decks)

    renderDeckSelection = (decks) =>
      renderSideDeckSelection('corp', decks.corp)
      renderSideDeckSelection('runner', decks.runner)

    renderSideDeckSelection = (side, decks) =>
      $('#nrdb_' + side + '_decks li').removeClass('active')
      deck = decks.after
      if !deck.unset
        $item = $('#nrdb_deck_' + deck.details.nrdb_uuid)
        if $item.length > 0
          $item.toggleClass('active', true)
      setSelectedView(side, decks)

    setSelectedView = (side, decks) =>
      $('#nrdb_' + side + '_selected').empty().append(
        cloneSelectedOrGetPlaceholder(side, decks))

    cloneSelectedOrGetPlaceholder = (side, decks) =>
      $item = $('#nrdb_deck_' + decks.after.details.nrdb_uuid)
      if $item.length > 0
        $clone = $item.clone().removeClass('active').addClass('selected-deck').removeAttr('id')
        $clone.find('.deck-list-identity').removeClass('deck-list-identity').addClass('selected-deck-identity')
        $clone.find('small').remove()
        $clone.prop('onclick', null).off('click')
        $clone.prepend($('<div/>', {'class': 'selected-deck-buttons'}))
        addSelectedDeckButtons($clone, side, decks)
      else
        if side == 'corp'
          $placeholder = $(corpPlaceholder)
        else
          $placeholder = $(runnerPlaceholder)
        $placeholder.find('p').text(unselectedPlaceholderText(side, decks))
        addSelectedDeckButtons($placeholder, side, decks)

    unselectedPlaceholderText = (side, decks) =>
      if !decks.before.unset
        if decks.change_type == 'none'
          'No ' + side + ' selected, leaving deck unchanged'
        else
          'No ' + side + ' selected, will submit no deck'
      else
        'No ' + side + ' selected'

    addSelectedDeckButtons = ($item, side, decks) =>
      $buttons = $item.find('.selected-deck-buttons').empty()
      if !decks.before.unset && decks.change_type != 'none'
        $undo = $('<a/>', {'title': 'Undo', 'href': '#'})
        $undo.append($('<i/>', {'class': 'fa fa-undo'}))
        $undo.on('click', (e) =>
          e.preventDefault()
          undoDeckSelection(side))
        $buttons.append($undo)
      if !decks.after.unset
        $deselect = $('<a/>', {'title': 'Deselect', 'href': '#'})
        $deselect.append($('<i/>', {'class': 'fa fa-close'}))
        $deselect.on('click', (e) =>
          e.preventDefault()
          setSideDeckSelected(side, null))
        $buttons.append($deselect)
      $item

    renderDeckSelection(readDecksFromInputs())
    readDecks()
