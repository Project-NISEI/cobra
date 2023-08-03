$(document).on 'turbolinks:load', ->
  if document.getElementById('nrdb_decks')? || document.getElementById('display_decks')? || document.getElementById('display_opponent_deck')?

    nrdbPrintingsById = new Map()

    window.getNrdbPrinting = (printingId) =>
      nrdbPrintingsById.get(printingId)

    window.nrdbFactionImageOrEmpty = (faction_id) =>
      if !faction_id
        []
      else
        nrdbFactionImage(faction_id)

    window.nrdbFactionImage = (faction_id) =>
      if faction_id.startsWith('neutral')
        $('<img/>', {
          src: 'https://netrunnerdb.com/images/factions/16px/' + nrdbFactionClass(faction_id) + '.png'
        })
      else
        $('<i/>', {
          class: 'fa icon text-center ' + nrdbFactionIcon(faction_id) + ' ' + nrdbFactionClass(faction_id),
          style: 'width: 16px'
        })

    nrdbFactionIcon = (faction_id) =>
      'icon-' + nrdbFactionClass(faction_id)

    nrdbFactionClass = (faction_id) =>
      faction_id.replaceAll('_', '-')

    window.loadNrdbPrintings = (printingIds, callback) =>
      printingIds = new Set(printingIds)
      for printingId from printingIds
        if nrdbPrintingsById.has(printingId)
          printingIds.delete(printingId)
      if printingIds.size == 0
        callback()
        return
      printingIdsStr = Array.from(printingIds).join()
      $.get({
        url: 'https://api-preview.netrunnerdb.com/api/v3/public/printings',
        data: {
          'fields[printings]': 'card_id,card_type_id,title,side_id,faction_id,minimum_deck_size,influence_limit,influence_cost',
          'filter[id]': printingIdsStr,
          'page[limit]': 1000
        },
        success: (response) =>
          loadMoreNrdbPrintings(new Array(), response, callback)
      })

    loadMoreNrdbPrintings = (nrdbPrintingsBefore, response, callback) =>
      nrdbPrintings = nrdbPrintingsBefore.concat(response.data)
      if response.links.next?
        $.get({
          url: response.links.next,
          success: (response) =>
            loadMoreNrdbPrintings(nrdbPrintings, response, callback)
        })
      else
        for nrdbPrinting from nrdbPrintings
          nrdbPrintingsById.set(nrdbPrinting.id, nrdbPrinting)
        callback()
