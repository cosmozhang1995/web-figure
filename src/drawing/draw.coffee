max = require('../utils/utils').max
min = require('../utils/utils').min
minmax = require('../utils/utils').minmax
with_default = require('../utils/utils').with_default

# NOTE:
# For figure/axes size, we currently support only units: 'pixels' and 'normalized'
# For font size or line width, we currently support only units: 'pixels'


pos2ltrb = (pos) ->
  return [pos[0], pos[1], pos[0] + pos[2], pos[1] + pos[3]]
norm2px = (pos, figsize) ->
  figw = figsize[0]
  figh = figsize[1]
  return [pos[0] * figw, pos[1] * figh, pos[2] * figw, pos[3] * figh]
any2px = (pos, units, figinfo) ->
  if units == "normalized"
    return norm2px(pos, figinfo.size)
  else
    return pos

linestyle2dasharray = (style, linewidth) ->
  dotlen = linewidth
  dashlen = linewidth * 4
  gaplen = linewidth * 4
  if style.indexOf("--") >= 0
    return [dashlen,gaplen].join(",")
  else if style.indexOf("-.") >= 0
    return [dashlen,gaplen,dotlen,gaplen].join(",")
  else if style.indexOf(":") >= 0
    return [dotlen,gaplen].join(",")
  else
    return "0"

autoticks = (range, pxrange) ->
  reversal = range[0] > range[0]
  range = range.sort()
  pxrange = pxrange.sort()
  pxlength = pxrange[1] - pxrange[0]
  n = Math.floor(pxlength / 50)
  dis = range[1] - range[0]
  if dis == 0
    return []
  intv = dis / n
  aintv = Math.abs(intv)
  unit = 1
  while aintv / unit >= 10
    unit = unit * 10
  while aintv / unit <= 0.1
    unit = unit * 0.1
  aintv = Math.floor(aintv / unit) * unit
  intv = if intv > 0 then aintv else -aintv
  tval = Math.ceil(range[0] / unit) * unit
  ticks = [tval]
  while (tval = tval + unit) < range[1]
    ticks.push(tval)
  if reversal
    ticks = ticks.reverse()
  return ticks

val2px = (val, range, pxrange) ->
  pxlength = pxrange[1] - pxrange[0]
  ratio = pxlength / (range[1] - range[0])
  return (val - range[0]) * ratio + pxrange[0]


createTextArea = (text, anchorpoint) ->
  anchorpoint = anchorpoint || "center"
  if anchorpoint.indexOf("left") >= 0
    xoffset = 0
  else if anchorpoint.indexOf("right") >= 0
    xoffset = -1
  else
    xoffset = -0.5
  if anchorpoint.indexOf("top") >= 0
    yoffset = 0
  else if anchorpoint.indexOf("bottom") >= 0
    yoffset = -1
  else
    yoffset = -0.5
  font = text.font
  text = text.text
  fontsize = font.size
  areawidth = fontsize * text.length
  areaheight = fontsize
  el = $('<span></span>')
    .css("display", "block")
    .css("width", areawidth)
    .css("height", areaheight)
    .css("position", "absolute")
    .css("left", 0)
    .css("top", 0)
    .css("margin-left", xoffset * areawidth)
    .css("margin-top", yoffset * areaheight)
    .css("font-size", fontsize)
    .css("font-family", font.name)
    .css("font-weight", font.weight)
    .css("font-style", if font.italic then "italic" else "normal")
    .css("color", font.color.csscolor())
    .css("opacity", font.color.alpha)
  return el


createSVG = () ->
  el = $('<svg></svg>')
    .attr("version", "1.1")
    .attr("xmlns", "http://www.w3.org/2000/svg")
  return el


class FigureFrame
  constructor: (sel, figure) ->
    this.givenRoot = $(sel)
    this.figure = figure
  createView: () ->
    this.givenRoot.children().remove()
    this.root = $("<div></div>").appendTo(this.givenRoot)
      .css("position", "relative")
      .css("height", "100%")
      .css("width", "100%")
    for axes in this.figure.subplots
      axes_frame = new AxesFrame(this, axes)
      axes_frame.createView()

class AxesFrame
  constructor: (infig, axes) ->
    this.infig = infig
    this.axes = axes
    this.ndims = 2
    this.init_viewport = this.axes.viewport
    this.viewport = this.init_viewport
    this.hasview = false

  figinfo: () ->
    return {
      size: [this.infig.root.width(), this.infig.root.height()]
    }

  updateViewport: () ->
    this.updateAxes()

  createView: () ->
    figinfo = this.figinfo()
    this.outpos = any2px(this.axes.outer_position, this.axes.units, figinfo)
    this.pos = any2px(this.axes.position, this.axes.units, figinfo)
    this.boxleft = this.pos[0] - this.outpos[0]
    this.boxtop = this.pos[1] - this.outpos[1]
    this.boxwidth = this.pos[2]
    this.boxheight = this.pos[3]
    this.boxright = this.boxleft + this.boxwidth
    this.boxbottom = this.boxtop + this.boxheight
    this.outwidth = this.outpos[2]
    this.outheight = this.outpos[3]
    this.root = $("<div></div").appendTo(this.infig.root)
      .css("position", "absolute")
      .css("left", this.outpos[0])
      .css("top", this.outpos[1])
      .css("width", this.outpos[2])
      .css("height", this.outpos[3])
      .css("z-stack", 0)
    this.topLayer = $("<div></div>").appendTo(this.root)
      .css("width", this.outwidth)
      .css("height", this.outheight)
      .css("position", "absolute")
      .css("left", 0)
      .css("top", 0)
      .css("z-stack", 50)
    this.axesLayer = null
    this.compLayer = null
    this.gridLayer = null
    that = this
    allLoaded = () ->
      if that.axesLayer and that.compLayer and that.gridLayer
        that.createAxes()
        # that.createComponents()
    $("<div></div>").appendTo(this.root)
      .css("width", this.outwidth)
      .css("height", this.outheight)
      .css("position", "absolute")
      .css("left", 0)
      .css("top", 0)
      .css("z-stack", 0)
      .svg({
        onLoad: (svg) ->
          that.axesLayer = svg
          allLoaded()
        settings: {
          width: that.outwidth
          height: that.outheight
        }
      })
    $("<div></div>").appendTo(this.root)
      .css("width", this.pos[2])
      .css("height", this.pos[3])
      .css("position", "absolute")
      .css("left", this.boxleft)
      .css("top", this.boxtop)
      .css("z-stack", 0)
      .svg({
        onLoad: (svg) ->
          that.compLayer = svg
          allLoaded()
        settings: {
          width: that.pos[2]
          height: that.pos[3]
        }
      })
    $("<div></div>").appendTo(this.root)
      .css("width", this.outwidth)
      .css("height", this.outheight)
      .css("position", "absolute")
      .css("left", 0)
      .css("top", 0)
      .css("z-stack", 0)
      .svg({
        onLoad: (svg) ->
          that.gridLayer = svg
          allLoaded()
        settings: {
          width: that.outwidth
          height: that.outheight
        }
      })

  createAxes: () ->
    this.topLayer.find(".axis-tick-label").remove()
    if this.xaxisline then this.axesLayer.remove(this.xaxisline)
    if this.yaxisline then this.axesLayer.remove(this.yaxisline)
    this.axesLayer.remove(el) for el in (this.axesTicks || [])
    this.axesLayer.remove(el) for el in (this.axesTickLabels || [])
    this.xaxistop = this.axes.xaxis_location == "top"
    this.yaxisleft = this.axes.xaxis_location != "right"
    this.xaxisposy = if this.xaxistop then this.boxtop else this.boxbottom
    this.yaxisposx = if this.yaxisleft then this.boxleft else this.boxright
    this.xaxisline = this.axesLayer.line(null,
      this.boxleft,
      this.xaxisposy,
      this.boxright,
      this.xaxisposy, {
        'stroke': "black"
        'stroke-width': this.axes.line_width
      })
    this.yaxisline = this.axesLayer.line(null,
      this.yaxisposx,
      this.boxtop,
      this.yaxisposx,
      this.boxbottom, {
        'stroke': "black"
        'stroke-width': this.axes.line_width
      })
    this.axesTicks = []
    this.axesTickLabels = []
    this.updateAxes()

  updateAxes: () ->
    this.topLayer.find('.axis-tick-label').remove()
    # Axis lines
    this.axesLayer.remove(el) for el in (this.axesTicks || [])
    this.axesLayer.remove(el) for el in (this.axesTickLabels || [])
    # X ticks
    ticks = this.axes.xticks
    tickvals = ticks.ticks
    viewport = this.viewport[0].sort()
    if this.axes.xaxis.reversal
      viewport = viewport.reverse()
    if tickvals == "auto"
      tickvals = autoticks(viewport, [this.boxleft, this.boxright])
    tickposes = (val2px(v, viewport, [this.boxleft, this.boxright]) for v in tickvals)
    ticklabels = ticks.labels
    if ticklabels == "auto"
      ticklabels = ("" + t for t in tickvals)
    sign = if this.xaxistop then 1 else -1
    ticklen = ticks.length[0]
    if ticks.dir == "both"
      ticky = [this.xaxisposy - ticklen, this.xaxisposy + ticklen]
    else if ticks.dir == "out"
      ticky = [this.xaxisposy - sign * ticklen, this.xaxisposy]
    else
      ticky = [this.xaxisposy, this.xaxisposy + sign * ticklen]
    for i in [0..tickvals.length-1]
      this.axesTicks.push this.axesLayer.line(null
        tickposes[i],
        ticky[0],
        tickposes[i],
        ticky[1], {
          "stroke": "black"
          "stroke-width": this.axes.line_width
        })
      createTextArea({ text: ticklabels.text, font: this.font }, if this.xaxistop then "centerbottom" else "centertop").appendTo(this.topLayer)
        .addClass('axis-tick-label')
        .css('top', this.xaxisposy - sign * ticklen * 2)
        .css('left', tickposes[i])
    # Y ticks
    ticks = this.axes.yticks
    tickvals = ticks.ticks
    viewport = this.viewport[0].sort()
    if this.axes.xaxis.reversal
      viewport = viewport.reverse()
    if tickvals == "auto"
      tickvals = autoticks(viewport, [this.boxtop, this.boxbottom])
    tickposes = (val2px(v, viewport, [this.boxtop, this.boxbottom]) for v in tickvals)
    ticklabels = ticks.labels
    if ticklabels == "auto"
      ticklabels = ("" + t for t in tickvals)
    sign = if this.yaxisleft then 1 else -1
    ticklen = ticks.length[0]
    if ticks.dir == "both"
      tickx = [this.yaxisposx - ticklen, this.yaxisposx + ticklen]
    else if ticks.dir == "out"
      tickx = [this.yaxisposx - sign * ticklen, this.yaxisposx]
    else
      tickx = [this.yaxisposx, this.yaxisposx + sign * ticklen]
    for i in [0..tickvals.length-1]
      this.axesTicks.push this.axesLayer.line(null
        tickx[0],
        tickposes[i],
        tickx[1],
        tickposes[i], {
          "stroke": "black"
          "stroke-width": this.axes.line_width
        })
      createTextArea({ text: ticklabels.text, font: this.font }, if this.yaxisleft then "rightcenter" else "leftcenter").appendTo(this.topLayer)
        .addClass('axis-tick-label')
        .css('top', tickposes[i])
        .css('left', this.yaxisposx - sign * ticklen * 2)

  createComponents: () ->
    this.compLayer.children().remove()
    for comp in this.axes.components
      if comp.type == "line"
        this.drawLine(comp.component)

  drawLine: (line) ->
    data = line.data
    pxpoints = ([val2px(p[0], this.viewport[0], [this.boxleft, this.boxright]), val2px(p[1], this.viewport[1], [this.boxtop, this.boxbottom])] for p in line.data)
    pxpointsstr = (p.join(",") for p in pxpoints).join(" ")
    linewidth = with_default(with_default(line.line_width, this.axes.line_width), 1)
    styles = {}
    styles["strock"] = line.color.csscolor()
    styles["stroke-width"] = linewidth
    styles["stroke-dasharray"] = linestyle2dasharray(line.style, linewidth)
    stylestr = ((k + ":" + v) for k,v of styles).join(";")
    polyline = $("<polyline></polyline>").appendTo(this.compLayer)
      .addClass("axes-component")
      .attr("points", pxpointsstr)
      .attr("style", stylestr)



module.exports.FigureFrame = FigureFrame
module.exports.AxesFrame = AxesFrame