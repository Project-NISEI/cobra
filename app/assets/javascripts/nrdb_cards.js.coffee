$(document).on 'turbolinks:load', ->
  if document.getElementById('nrdb_decks')? || document.getElementById('display_decks')? || document.getElementById('display_opponent_deck')?

    nrdbPrintingsById = new Map()

    window.getNrdbPrinting = (printingId) =>
      nrdbPrintingsById.get(printingId)

    window.nrdbFactionBackground = (printing) =>
      'background-' + printing.attributes.faction_id.replaceAll('_', '-') + '-20'

    window.nrdbFactionBackgroundStriped = (printing, index) =>
      if index % 2 == 0
        'background-' + printing.attributes.faction_id.replaceAll('_', '-') + '-20'
      else
        'background-' + printing.attributes.faction_id.replaceAll('_', '-') + '-10'

    window.nrdbFactionClass = (printing) =>
      printing.attributes.faction_id.replaceAll('_', '-')

    window.nrdbFactionIcon = (printing) =>
      'icon-' + nrdbFactionClass(printing)

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
