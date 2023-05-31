$(document).on 'turbolinks:load', ->
  if document.getElementById('nrdb_decks')?

    deckPlaceholders = $('#nrdb_decks_selected li').get()
    runnerPlaceholder = deckPlaceholders[0]
    corpPlaceholder = deckPlaceholders[1]

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

    window.selectDeck = (id, side) =>
      activeBefore = $('#nrdb_deck_'+id).hasClass('active')
      $('#nrdb_decks li[data-side*='+side+']').removeClass('active')
      $('#nrdb_deck_'+id).toggleClass('active', !activeBefore)
      $('#nrdb_decks_selected').empty()
      cloneToSelectedOrElse($('#nrdb_decks li.active[data-side*=runner]'), runnerPlaceholder)
      cloneToSelectedOrElse($('#nrdb_decks li.active[data-side*=corp]'), corpPlaceholder)
      $('#player_'+side+'_deck').val($('#nrdb_deck_'+id).attr('data-deck'))
