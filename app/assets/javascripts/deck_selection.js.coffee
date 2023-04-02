$(document).on 'turbolinks:load', ->
  if document.getElementById('nrdb_decks')
    window.selectDeck = (id, side) =>
      $('#nrdb_decks li[data-side*='+side+']').removeClass('active')
      $('#nrdb_deck_'+id).addClass('active')
