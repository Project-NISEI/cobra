$(document).on 'turbolinks:load', ->
  if document.getElementById('nrdb_decks')? || document.getElementById('display_decks')? || document.getElementById('display_opponent_deck')?

    nrdbPrintingsById = new Map()

    window.getNrdbPrinting = (printingId) =>
      nrdbPrintingsById.get(printingId)

    window.loadNrdbPrintings = (printingIds, callback) =>
      printingIds = printingIdsNotInMap(printingIds)
      if printingIds.length == 0
        callback()
        return

      for i in [0..printingIds.length - 1] by 100
        loadNrdbPrintingsChunk printingIds.slice(i, i + 100), ->
          if allPrintingIdsLoaded(printingIds)
            callback()

    window.searchNrdbCards = (query, callback) =>
      $.get({
        url: '/nrdb_public/search',
        data: {
          query: query
        },
        success: (response) =>
          for nrdbPrinting from response.data
            nrdbPrintingsById.set(nrdbPrinting.id, nrdbPrinting)
          callback(response.data)
      })

    printingIdsNotInMap = (printingIds) =>
      set = new Set(printingIds)
      for printingId from set
        if nrdbPrintingsById.has(printingId)
          set.delete(printingId)
      Array.from(set)

    allPrintingIdsLoaded = (printingIds) =>
      allLoaded = true
      for id in printingIds
        if !nrdbPrintingsById.has(id)
          allLoaded = false
      allLoaded

    loadNrdbPrintingsChunk = (printingIds, callback) =>
      $.get({
        url: '/nrdb_public/printings',
        data: {
          ids: Array.from(printingIds).join()
        },
        success: (response) =>
          for nrdbPrinting from response.data
            nrdbPrintingsById.set(nrdbPrinting.id, nrdbPrinting)
          callback()
      })
