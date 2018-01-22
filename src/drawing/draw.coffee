max = require('../utils/utils').max
min = require('../utils/utils').min
minmax = require('../utils/utils').minmax

# NOTE:
# For figure/axes size, we currently support only units: 'pixels' and 'normalized'
# For font size or line width, we currently support only units: 'pixels'


pos2ltrb = (pos) ->
  return [pos[0], pos[1], pos[0] + pos[2], pos[1] + pos[3]]
norm2px = (pos, figsize) ->
  figw = figsize[0]
  figh = figsize[1]
  return [pos[0] / figw, pos[1] / figh, pos[2] / figw, pos[3] / figh]
any2px = (pos, units, figinfo) ->
  if units == "normalized"
    return norm2px(pos, figinfo.size)
  else
    return pos


autoticks = (range, pxrange) ->
  pxlength = pxrange[1] - pxrange[0]
  n = Math.floor(pxlength / 50)
  dis = range[1] - range[0]
  intv = dis / n
  unit = 1
  while intv / unit >= 10
    unit = unit * 10
  while intv / unit <= 0.1
    unit = unit * 0.1
  intv = Math.floor(intv / unit) * unit
  tval = Math.ceil(range[0] / unit) * unit
  ticks = [tval]
  while (tval = tval + unit) < range[1]
    ticks.push(tval)
  return ticks

val2px = (ticks, range, pxrange) ->
  pxlength = pxrange[1] - pxrange[0]
  ratio = pxlength / (range[1] - range[0])
  fn = (val) -> ((val - range[0]) * ratio + pxrange[0])
  return (fn(v) for v in ticks)


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


class FigureWindow
  constructor: (sel, figure) ->
    this.root = $(sel)
  update: () ->
    this.root

class AxesFrame
  constructor: (infig, axes) ->
    this.infig = infig
    this.axes = axes
    this.ndims = axes.data[0].length
    this.length = axes.data.length
    init_viewport = ([axes.data[0][c], axes.data[0][c]] for c in [0..this.ndims-1])
    for i in [0..this.length-1]
      for c in [0..this.ndims-1]
        val = data[i][c]
        if init_viewport[c][0] > val
          init_viewport[c][0] = val
        if init_viewport[c][1] < val
          init_viewport[c][1] = val
    this.init_viewport = init_viewport
    this.viewport = this.init_viewport
    this.hasview = false

  figinfo: () ->
    return {
      size: [this.infig.root.width(), this.infig.root.height()]
    }

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
    this.axesLayer = $("<svg></svg>").appendTo(this.infig.root)
      .attr("width", this.outwidth)
      .attr("height", this.outheight)
      .css("position", "absolute")
      .css("left", 0)
      .css("top", 0)
      .css("z-stack", 0)
    this.compLayer = $("<svg></svg>").appendTo(this.infig.root)
      .attr("width", pos[2])
      .attr("height", pos[3])
      .css("position", "absolute")
      .css("left", this.boxleft)
      .css("top", this.boxtop)
      .css("z-stack", 20)
    this.gridLayer = $("<svg></svg>").appendTo(this.infig.root)
      .attr("width", this.outwidth)
      .attr("height", this.outheight)
      .css("position", "absolute")
      .css("left", 0)
      .css("top", 0)
      .css("z-stack", if this.axes.grid.layer == "top" then 30 else 10)
    this.topLayer = $("<div></div>").appendTo(this.infig.root)
      .css("width", this.outwidth)
      .css("height", this.outheight)
      .css("position", "absolute")
      .css("left", 0)
      .css("top", 0)
      .css("z-stack", 50)
    # Draw the axes
    # Now add the components
    for comp in this.axes.components
      this.

  drawAxes: () ->
    this.root.find.children(".axis-tick, .axis-tick-label, .axis-line").remove()
    this.xaxistop = this.axes.xaxis_location == "top"
    this.yaxisleft = this.axes.xaxis_location != "right"
    this.xaxisposy = if this.xaxistop then this.boxtop else this.boxbottom
    this.yaxisposx = if this.yaxisleft then this.boxleft else this.boxright
    $('<line></line>').appendTo(this.axesLayer)
      .addClass('axis-line')
      .attr('x0', this.boxleft)
      .attr('y0', this.xaxisposy)
      .attr('x1', this.boxright)
      .attr('y1', this.xaxisposy)
    $('<line></line>').appendTo(this.axesLayer)
      .addClass('axis-line')
      .attr('x0', this.yaxisposx)
      .attr('y0', this.boxtop)
      .attr('x1', this.yaxisposx)
      .attr('y1', this.boxbottom)

  updateAxes: () ->
    this.root.find('.axis-tick, .axis-tick-label').remove()
    # X ticks
    ticks = this.axes.xticks
    tickvals = ticks.ticks
    if tickvals == "auto"
      tickvals = autoticks(this.viewport[0], [this.boxleft, this.boxright])
    tickposes = val2px(tickvals, this.viewport[0], [this.boxleft, this.boxright])
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
      $("<line></line>").appendTo(this.axesLayer)
        .addClass('axis-line')
        .attr('x0', tickposes[i])
        .attr('y0', ticky[0])
        .attr('x1', tickposes[i])
        .attr('y1', ticky[1])
      createTextArea({ text: ticklabels.text, font: this.font }, if this.xaxistop then "centerbottom" else "centertop")
        .css('top', this.xaxisposy - sign * ticklen * 2)
        .css('left', tickposes[i])
    # Y ticks
    ticks = this.axes.yticks
    tickvals = ticks.ticks
    if tickvals == "auto"
      tickvals = autoticks(this.viewport[0], [this.boxtop, this.boxbottom])
    tickposes = val2px(tickvals, this.viewport[1], [this.boxtop, this.boxbottom])
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
      $("<line></line>").appendTo(this.axesLayer)
        .addClass('axis-line')
        .attr('x0', tickx[0])
        .attr('y0', tickposes[i])
        .attr('x1', tickx[1])
        .attr('y1', tickposes[i])
      createTextArea({ text: ticklabels.text, font: this.font }, if this.yaxisleft then "rightcenter" else "leftcenter")
        .css('top', tickposes[i])
        .css('left', this.yaxisposx - sign * ticklen * 2)



  update: (infig, viewport) ->
    this.viewport = viewport
    unless this.hasview
      this.axesLayer = $("<svg></svg>").appendTo(this.root)
      this.compLayer = $("<svg></svg>").appendTo(this.root)
      this.gridLayer = $("<svg></svg>").appendTo(this.root)


