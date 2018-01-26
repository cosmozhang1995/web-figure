load_fig_url = window.location.protocol + ":/" + window.location.host + "/image/webfig.json"

load_fig = () ->
  $.get load_fig_url + "?t=" + new Date().getTime(), (data) ->
    fig = new webfig.Figure(data)
    window.figframe = new webfig.FigureFrame("#figframe", fig)
    window.figframe.createView()
    window.figframe.setAxesProperties("showMouseCoor", true)

$(document).ready () ->
  $.get '/defaults.json', (data) ->
    window.webfig = window.webfig.init(data)
    load_fig()
  $('.figctrl-item').click () ->
    $(this).siblings().removeClass("active")
    if $(this).is('.figctrl-home')
      figframe.setMouseMode(null)
      figframe.setViewport(null)
    else if $(this).is('.figctrl-drag')
      if figframe.mouseMode == "drag"
        figframe.setMouseMode(null)
        $(this).removeClass("active")
      else
        figframe.setMouseMode("drag")
        $(this).addClass("active")
    else if $(this).is('.figctrl-zoom')
      if figframe.mouseMode == "zoom"
        figframe.setMouseMode(null)
        $(this).removeClass("active")
      else
        figframe.setMouseMode("zoom")
        $(this).addClass("active")
    else if $(this).is('.figctrl-curse')
      if figframe.mouseMode == "curse"
        figframe.setMouseMode(null)
        $(this).removeClass("active")
      else
        figframe.setMouseMode("curse")
        $(this).addClass("active")
  $('.figdatactrl-item').click () ->
    if $(this).is('.figdatactrl-refresh')
      load_fig()