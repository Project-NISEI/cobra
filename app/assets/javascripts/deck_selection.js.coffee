$(document).on 'turbolinks:load', ->
  deckBefore = (side) =>
    deckBeforeStr = $('#player_' + side + '_deck_before').val()
    if deckBeforeStr.length > 0
      JSON.parse(deckBeforeStr)
    else
      null

  emptyDeck = (side) =>
    {details: {side_id: side}, cards: []}

  if document.getElementById('nrdb_decks')?

    deckPlaceholders = $('#nrdb_decks_selected li').get()
    corpPlaceholder = deckPlaceholders[0]
    runnerPlaceholder = deckPlaceholders[1]

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
      for nrdbDeck from nrdbDecks
        $item = $('#nrdb_deck_' + nrdbDeck.uuid)
        deck = readNrdbDeck(nrdbDeck)
        $item.attr('data-side', deck.details.side_id)
        $item.prepend($('<div/>', {
          class: 'deck-list-identity', css: {
            'background-image': 'url(https://static.nrdbassets.com/v1/small/' + deck.details.identity_nrdb_printing_id + '.jpg)'
          }
        }))
        $item.append($('<small/>', text: deck.details.identity_title))
      preselectDeck('corp')
      preselectDeck('runner')

    readDeckFrom$Item = ($item) =>
      nrdbDeck = JSON.parse($item.attr('data-deck'))
      return readNrdbDeck(nrdbDeck)

    readNrdbDeck = (nrdbDeck) =>
      details = {name: nrdbDeck.name, nrdb_uuid: nrdbDeck.uuid}
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
            nrdb_card_id: attributes.card_id
          })
      return {details: details, cards: cards}

    window.selectDeck = (id) =>
      $item = $('#nrdb_deck_' + id)
      deck = readDeckFrom$Item($item)
      side = deck.details.side_id
      activeBefore = $item.hasClass('active')
      $('#nrdb_decks li[data-side*=' + side + ']').removeClass('active')
      $item.toggleClass('active', !activeBefore)
      $('#nrdb_decks_selected').empty()
      $corp = $('#nrdb_decks li.active[data-side*=corp]')
      $runner = $('#nrdb_decks li.active[data-side*=runner]')
      cloneToSelectedOrElse($corp, corpPlaceholder)
      cloneToSelectedOrElse($runner, runnerPlaceholder)
      setDeckInputs(deck, $item.hasClass('active'))
      displayDecksBy$Item($corp, $runner)

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
        $('#player_' + side + '_deck').val(JSON.stringify(deck))
        $('#player_' + side + '_identity').val(deck.details.identity_title)
      else
        $('#player_' + side + '_deck').val('')
        $('#player_' + side + '_identity').val('')

    preselectDeck = (side) =>
      deckStr = $('#player_' + side + '_deck').val()
      if deckStr.length > 0
        window.selectDeck(JSON.parse(deckStr).details.nrdb_uuid)
      else
        displayDecksBy$Item([], [])

    displayDecksBy$Item = ($corp, $runner) =>
      displayDeckBy$ItemAndSide($corp, 'corp')
      displayDeckBy$ItemAndSide($runner, 'runner')

    displayDeckBy$ItemAndSide = ($item, side) =>
      $container = $('#display_' + side + '_deck')
      if $item.length > 0
        displayDeck(readDeckFrom$Item($item), $container, deckBefore(side))
      else
        displayDeck(emptyDeck(side), $container, deckBefore(side))

    readDecks()

  if document.getElementById('display_corp_deck')? && document.getElementById('player_corp_deck')?
    displayDecksFromInputs = () =>
      displayDeckFromInput('corp')
      displayDeckFromInput('runner')

    displayDeckFromInput = (side) =>
      deckStr = $('#player_' + side + '_deck').val()
      $container = $('#display_' + side + '_deck')
      if deckStr.length > 0
        deck = JSON.parse(deckStr)
        displayDeck(deck, $container, deckBefore(side))
      else
        displayDeck(emptyDeck(side), $container, deckBefore(side))

    try
      displayDecksFromInputs()
    catch e
      console.log(e)
