$(document).ready () ->
  $.get '/defaults.json', (data) ->
    window.webfig = window.webfig.init(data)
    xx = (i * 0.001 for i in [-6000..6000])
    yy = (Math.sin(x) for x in xx)
    fig = new webfig.Figure()
    fig.plot(xx, yy)
    figframe = new webfig.FigureFrame("#figframe", fig)
    figframe.createView()
    figframe.setAxesProperties("showMouseCoor", true)
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