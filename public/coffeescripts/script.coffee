$(document).ready () ->
  $.get '/defaults.json', (data) ->
    window.webfig = window.webfig.init(data)
    fig = new webfig.Figure()
    fig.plot([1,2,3], [4,5,6])
    figframe = new webfig.FigureFrame("#figframe", fig)
    figframe.createView()
