$(document).on 'turbolinks:load', ->
  if document.getElementById('nrdb_decks')
    window.selectDeck = (id) =>
      $('#nrdb_decks li').removeClass('active')
      $('#deck-'+id).addClass('active')
