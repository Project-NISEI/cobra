$(document).on 'turbolinks:load', ->
  if document.getElementById('nrdb_decks')?

    deckPlaceholders = $('#nrdb_decks_selected li').get()
    runnerPlaceholder = deckPlaceholders[0]
    corpPlaceholder = deckPlaceholders[1]

    cloneToSelectedOrElse = (element, ifNotPresent) =>
      if element.length > 0
        clone = element.clone().removeClass('active').addClass('selected-deck')
        clone.find('.deck-list-identity').removeClass('deck-list-identity').addClass('selected-deck-identity')
        clone.find('small').remove()
        clone.appendTo('#nrdb_decks_selected')
      else
        $(ifNotPresent).appendTo('#nrdb_decks_selected')

    window.selectDeck = (id, side) =>
      $('#nrdb_decks li[data-side*='+side+']').removeClass('active')
      $('#nrdb_decks_selected').empty()
      $('#nrdb_deck_'+id).addClass('active')
      cloneToSelectedOrElse($('#nrdb_decks li.active[data-side*=runner]'), runnerPlaceholder)
      cloneToSelectedOrElse($('#nrdb_decks li.active[data-side*=corp]'), corpPlaceholder)
