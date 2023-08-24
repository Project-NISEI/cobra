$(document).on 'turbolinks:load', ->
  if document.getElementById('player_stream_consent_form')?
    $('#player_consented_to_be_streamed').on 'change', ->
      $('#player_consented_to_be_streamed').closest("form").submit()
