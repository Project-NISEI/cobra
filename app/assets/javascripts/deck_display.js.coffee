$(document).on 'turbolinks:load', ->
  window.displayDeck = (deck, container) =>

    if deck.details.side_id == 'corp'
      deckNameTitle = 'Corp Deck'
    else
      deckNameTitle = 'Runner Deck'
    $name = $('<div/>', {class: 'card mb-3'}).append(
      $('<div/>', {class: 'card-body'}).append(
        $('<h5/>', {class: 'card-title', text: deckNameTitle}),
        $('<p/>', {class: 'card-text', text: deck.details.name})))

    $identity = $('<table/>', {
      class: 'table table-bordered table-striped'
    }).append(
      $('<thead/>').append(
        $('<tr/>').append(
          ['Min', 'Identity', 'Max'].map((title) =>
            $('<th/>', {class: 'text-center', text: title})))),
      $('<tbody/>').append(
        $('<tr/>').append(
          [deck.details.min_deck_size, deck.details.identity_title, deck.details.max_influence].map((value) =>
            $('<td/>', {text: value})))))

    $cards = $('<table/>', {
      class: 'table table-bordered table-striped'
    }).append(
      $('<thead/>').append(
        $('<tr/>').append(
          ['Qty', 'Card Name', 'Inf'].map((title) => $('<th/>', {class: 'text-center', text: title})))),
      $('<tbody/>').append(deck.cards.map((card) =>
        if card.influence > 0
          influence = card.influence
        else
          influence = ''
        $('<tr/>').append(
          [card.quantity, card.title, influence].map((value) => $('<td/>', {text: value}))))))

    $(container).empty().append($name, $identity, $cards)
