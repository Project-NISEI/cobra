$(document).on 'turbolinks:load', ->
  if document.getElementById("nrdb_decks")
    window.selectDeck = (id) =>
      alert(id)
