$(document).on 'turbolinks:load', ->
  if document.getElementById('nrdb_decks')?

    decksTop = $('#nrdb_decks').offset().top
    deckOffsets = {}
    $('#nrdb_decks li').each (index, item) =>
      deckOffsets[$(item).attr('data-deck-id')] = $(item).offset().top - decksTop

    pinItems = []
    pinSelectedDecks = () =>
      scrollTop = $('#nrdb_decks').scrollTop()
      scrollBottom = scrollTop + $('#nrdb_decks').height()
      $('#nrdb_decks li').css({position:'', top:'', width: ''})
      pinItems.forEach (item) => $(item).remove()
      pinItems = []
      $('#nrdb_decks li.active').each (index, item) =>
        itemTop = deckOffsets[$(item).attr('data-deck-id')]
        itemBottom = itemTop + $(item).outerHeight()
        if itemBottom < scrollTop || itemTop > scrollBottom
          pinItems.push($(item).clone())
      pinItems.forEach (item, index) =>
        $(item).appendTo('#nrdb_decks')
        $(item).css({position:'absolute', top:50 + index*76, width: "100%"})

    $('#nrdb_decks').scroll(pinSelectedDecks)

    window.selectDeck = (id, side) =>
      $('#nrdb_decks li[data-side*='+side+']').removeClass('active')
      $('#nrdb_deck_'+id).addClass('active')
      pinSelectedDecks()
