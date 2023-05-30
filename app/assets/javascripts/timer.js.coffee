$(document).on 'turbolinks:load', ->
  if roundTimer?

    addLeadingZero = (number) ->
      if number < 10
        "0" + number
      else
        "" + number

    timeRemainingString = (millis) ->
      totalSeconds = Math.abs(Math.ceil(millis / 1000))
      minutes = Math.trunc(totalSeconds / 60)
      seconds = totalSeconds % 60
      if minutes > 99
        minutes = 99
        seconds = 99
      addLeadingZero(minutes) + ":" + addLeadingZero(seconds)

    allAlertClasses = "alert-primary alert-secondary alert-warning alert-danger"
    alertClassesForTimeRemaining = (millis) ->
      if roundTimer.paused
        "alert-secondary"
      else if millis < 1 * 60 * 1000
        "alert-danger"
      else if millis < 5 * 60 * 1000
        "alert-warning"
      else
        "alert-primary"

    setTimeRemaining = (millis) ->
      $('#time_remaining_header').html(if millis > 0 then 'Remaining' else 'Overtime')
      $("#round_time_remaining").html(timeRemainingString(millis))
      $("#round_time_remaining").parent().removeClass(allAlertClasses).addClass(alertClassesForTimeRemaining(millis))

    if roundTimer.paused
      setTimeRemaining(roundTimer.remaining_seconds * 1000)
    else if roundTimer.started
      finishTime = new Date(roundTimer.finish_time)
      renderTimeRemaining = () ->
        setTimeRemaining(finishTime.getTime() - new Date().getTime())
      renderTimeRemaining()
      setInterval(renderTimeRemaining, 100)
    else
      setTimeRemaining(roundTimer.length_minutes * 60000)

    popOutButton = document.getElementById("pop_out_button")
    if popOutButton && window.history.length > 1
      popOutButton.style.display = ""

    window.popOutRoundTimer = () ->
      window.open(window.location.href,"_blank","width=,height=")
      window.history.back()

    window.closeRoundTimer = () ->
      if window.history.length > 1
        window.history.back()
      else
        window.close()
