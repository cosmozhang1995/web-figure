$(document).ready () ->
  $.get '/defaults.json', (data) ->
    window.webfig = window.webfig.init(data)
    xx = (i * 0.01 for i in [-300..300])
    yy = (Math.sin(x) for x in xx)
    fig = new webfig.Figure()
    fig.plot(xx, yy)
    figframe = new webfig.FigureFrame("#figframe", fig)
    figframe.createView()
