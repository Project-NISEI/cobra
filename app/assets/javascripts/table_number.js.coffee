$(document).on 'turbolinks:load', ->
  window.assignTableNumber = (playerId) ->
    if playerId
      form = $("form#edit_player_#{playerId}")
    else
      form = $('form.register-player')
    form.find('.form-group.table-number').removeClass('d-none')
    form.find('.assign-table-number').addClass('d-none')
    form.find('.unassign-table-number').removeClass('d-none')
  window.unassignTableNumber = (playerId) ->
    if playerId
      form = $("form#edit_player_#{playerId}")
    else
      form = $('form.register-player')
    form.find('.form-group.table-number input').val(null)
    form.find('.form-group.table-number').addClass('d-none')
    form.find('.assign-table-number').removeClass('d-none')
    form.find('.unassign-table-number').addClass('d-none')
