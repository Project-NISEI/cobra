$(document).on 'turbolinks:load', ->
  window.displayDeck = (deck, container) =>

    if deck.details.side_id == 'corp'
      deckNameTitle = 'Corp Deck'
    else
      deckNameTitle = 'Runner Deck'
    $name = $('<table/>', {
      class: 'table table-bordered table-striped'
    }).append(
      $('<thead/>', {'class': 'thead-dark'}).append(
        $('<tr/>').append(
          $('<th/>', {class: 'text-center deck-name-header', text: deckNameTitle}))),
      $('<tbody/>').append(
        $('<tr/>').append(
          $('<td/>', {text: deck.details.name}))))

    $identity = $('<table/>', {
      class: 'table table-bordered table-striped'
    }).append(
      $('<thead/>', {'class': 'thead-dark'}).append(
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
      $('<thead/>', {'class': 'thead-dark'}).append(
        $('<tr/>').append(
          ['Qty', 'Card Name', 'Inf'].map((title) =>
            $('<th/>', {class: 'text-center', text: title})))),
      $('<tbody/>').append(deck.cards.map((card) =>
        if card.influence > 0
          influence = card.influence
        else
          influence = ''
        $('<tr/>').append(
          [card.quantity, card.title, influence].map((value) => $('<td/>', {text: value}))))))

    $(container).empty().append($name, $identity, $cards)
