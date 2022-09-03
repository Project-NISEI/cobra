$(document).on 'turbolinks:load', ->
  if roundTimer

    addLeadingZero = (number) ->
      if number < 10
        "0" + number
      else
        "" + number

    timeRemainingString = (millis) ->
      if millis <= 0
        "00:00"
      else
        totalSeconds = Math.trunc(millis / 1000);
        minutes = Math.trunc(totalSeconds / 60);
        seconds = totalSeconds % 60;
        addLeadingZero(minutes) + ":" + addLeadingZero(seconds)

    allAlertClasses = "alert-primary alert-secondary alert-warning alert-danger"
    alertClassesForTimeRemaining = (millis) ->
      if roundTimer.paused
        "alert-secondary"
      else if millis < 5 * 60 * 1000
        "alert-warning"
      else if millis < 1 * 60 * 1000
        "alert-danger"
      else
        "alert-primary"

    setTimeRemaining = (millis) ->
      $("#round_time_remaining").html(timeRemainingString(millis))
      $("#round_time_remaining").parent().removeClass(allAlertClasses).addClass(alertClassesForTimeRemaining(millis))

    if roundTimer.paused
      setTimeRemaining(roundTimer.remaining_seconds * 1000)
    else
      finishTime = new Date(roundTimer.finish_time)
      renderTimeRemaining = () ->
        setTimeRemaining(finishTime.getTime() - new Date().getTime())
      renderTimeRemaining()
      setInterval(renderTimeRemaining, 100)
