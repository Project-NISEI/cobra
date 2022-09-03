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

    setTimeRemaining = (millis) ->
      $("#round_time_remaining").html(timeRemainingString(millis))

    if roundTimer.paused
      setTimeRemaining(roundTimer.remaining_seconds * 1000)

    else
      finishTime = new Date(roundTimer.finish_time)
      renderTimeRemaining = () ->
        setTimeRemaining(finishTime.getTime() - new Date().getTime())
      renderTimeRemaining()
      setInterval(renderTimeRemaining, 100)
