$(document).on 'turbolinks:load', ->
  if document.getElementById('player_consent_data_sharing')?
    $dataSharing = $('#player_consent_data_sharing')
    $deckSharingWithTo = $('#player_consent_deck_sharing_with_to')
    setPlayerFormDisabled = () =>
      consent = $dataSharing.is(":checked")
      if $deckSharingWithTo.length > 0 && !$deckSharingWithTo.is(":checked")
        consent = false
      $('form.player button[type="submit"]').attr('disabled', !consent)

    $dataSharing.on('change', setPlayerFormDisabled)
    if $deckSharingWithTo.length > 0
      $deckSharingWithTo.on('change', setPlayerFormDisabled)
    setPlayerFormDisabled()
