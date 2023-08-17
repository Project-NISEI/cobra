$(document).on 'turbolinks:load', ->
  if document.getElementById('player_consent_data_sharing')?
    $dataSharing = $('#player_consent_data_sharing')
    setPlayerFormDisabled = () =>
      $('form.player button[type="submit"]').attr('disabled', !$dataSharing.is(":checked"))

    $dataSharing.on('change', setPlayerFormDisabled)
    setPlayerFormDisabled()
