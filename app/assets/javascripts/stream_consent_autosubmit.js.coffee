$(document).on 'turbolinks:load', ->
  if document.getElementById('player_streaming_opt_out_form')?
    $('#player_streaming_opt_out').on 'change', ->
      $('#player_streaming_opt_out').closest("form").submit()
