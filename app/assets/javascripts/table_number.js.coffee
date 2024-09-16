$(document).on 'turbolinks:load', ->
  window.assignTableNumber = (playerId) ->
    form = $("form#edit_player_#{playerId}")
    form.find('.form-group.table-number').removeClass('d-none')
    form.find('.assign-table-number').addClass('d-none')
    form.find('.unassign-table-number').removeClass('d-none')
  window.unassignTableNumber = (playerId) ->
    form = $("form#edit_player_#{playerId}")
    form.find('.form-group.table-number input').val(null)
