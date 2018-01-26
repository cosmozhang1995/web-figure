max = require('../utils/utils').max
min = require('../utils/utils').min
minmax = require('../utils/utils').minmax
with_default = require('../utils/utils').with_default
arrsort = require('../utils/utils').arrsort
sprintf = require('../utils/utils').sprintf

# NOTE:
# For figure/axes size, we currently support only units: 'pixels' and 'normalized'
# For font size or line width, we currently support only units: 'pixels'


pos2ltrb = (pos) ->
  return [pos[0], pos[1], pos[0] + pos[2], pos[1] + pos[3]]
normlen2pxlen = (normlen, pxrange) ->
  pxrange = arrsort(pxrange)
  return normlen * (pxrange[1] - pxrange[0])
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

toscinum = (num) ->
  unit = 1
  index = 0
  if num < 0.0000000000001 then num = 0
  anum = Math.abs(num)
  if anum > 0
    while anum / unit >= 10
      unit = unit * 10
      index += 1
    while anum / unit < 1
      unit = unit * 0.1
      index -= 1
    anum = Math.floor(anum / unit)
  num = if num > 0 then anum else -anum
  return {
    num: num
    unit: unit
    index: index
  }

autoticks = (range, pxrange) ->
  reversal = range[0] > range[1]
  range = arrsort(range)
  pxrange = arrsort(pxrange)
  pxlength = pxrange[1] - pxrange[0]
  n = Math.floor(pxlength / 50)
  dis = range[1] - range[0]
  if dis == 0
    return []
  intv = dis / n
  aintv = Math.abs(intv)
  aintvsci = toscinum(aintv)
  unit = aintvsci.unit
  aintv = aintvsci.num * unit
  intv = if intv > 0 then aintv else -aintv
  tval = (if intv > 0 then Math.ceil else Math.floor)(range[0] / unit) * unit
  ticks = [tval]
  compare = () ->
    if intv > 0
      return ((tval = tval + intv) <= range[1])
    else
      return ((tval = tval + intv) >= range[1])
  while compare()
    ticks.push(tval)
  if reversal
    ticks = ticks.reverse()
  return ticks

val2px = (val, range, pxrange, reversed) ->
  range = arrsort(range)
  pxrange = arrsort(pxrange)
  pxlength = pxrange[1] - pxrange[0]
  ratio = pxlength / (range[1] - range[0])
  if reversed
    return (range[1] - val) * ratio + pxrange[0]
  else
    return (val - range[0]) * ratio + pxrange[0]

format_tickvals = (tickvals) ->
  scis = (toscinum(n) for n in tickvals)
  indexes = (s.index for s in scis when s.num != 0)
  minmaxindex = minmax(indexes)
  minindex = minmaxindex[0]
  maxindex = minmaxindex[1]
  if Math.abs(minindex) < 3 and Math.abs(maxindex) < 3
    index = 0
  else if minindex >= 0
    index = Math.max(maxindex - 2, minindex)
  else if maxindex <= 0
    index = Math.min(minindex + 2, maxindex)
  else
    index = 0
  unit = Math.pow(10, index)
  nums = ((n/unit) for n in tickvals)
  return {
    nums: nums
    exp: index
  }

format_number = (num, float_digits) ->
  numstr = sprintf("%." + float_digits + "f", num)
  while (numstr.length > 0) and (numstr[numstr.length-1] == "0")
    numstr = numstr.slice(0, numstr.length-1)
  if (numstr.length > 0) and (numstr[numstr.length-1] == ".")
    numstr = numstr.slice(0, numstr.length-1)
  return numstr



createTextArea = (text, anchorpoint) ->
  anchorpoint = anchorpoint || "center"
  if anchorpoint.indexOf("left") >= 0
    xoffset = 0
    textalign = "left"
  else if anchorpoint.indexOf("right") >= 0
    xoffset = -1
    textalign = "right"
  else
    xoffset = -0.5
    textalign = "center"
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
    .css("text-align", textalign)
    .css("font-size", fontsize)
    .css("font-family", font.name)
    .css("font-weight", font.weight)
    .css("font-style", if font.italic then "italic" else "normal")
    .css("color", font.color.csscolor())
    .css("opacity", font.color.alpha)
    .text(text)
  return el


createSVG = () ->
  el = $('<svg></svg>')
    .attr("version", "1.1")
    .attr("xmlns", "http://www.w3.org/2000/svg")
  return el


click_interval_threshold = 200


class FigureFrame
  constructor: (sel, figure) ->
    this.givenRoot = $(sel)
    this.figure = figure
    this.axes_frames = []
  createView: () ->
    this.givenRoot.children().remove()
    this.axes_frames = []
    this.root = $("<div></div>").appendTo(this.givenRoot)
      .css("position", "relative")
      .css("height", "100%")
      .css("width", "100%")
    for axes in this.figure.subplots
      axes_frame = new AxesFrame(this, axes)
      axes_frame.createView()
      this.axes_frames.push(axes_frame)

  setAxesProperties: (name, val) ->
    for axes_frame in this.axes_frames
      axes_frame[name] = val
  setMouseMode: (mode) ->
    for axes_frame in this.axes_frames
      axes_frame.setMouseMode(mode)
  setViewport: (viewport) ->
    for axes_frame in this.axes_frames
      axes_frame.setViewport(viewport)

class AxesFrame
  constructor: (infig, axes) ->
    this.infig = infig
    this.axes = axes
    this.ndims = 2
    this.init_viewport = this.axes.get_viewport()
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
      .css("user-select", "none")
      .css("z-index", 0)
    this.axesLayer = null
    this.compLayer = null
    this.gridLayer = null
    this.coorlineLayer = null
    this.topLayer = null
    that = this
    allLoaded = () ->
      if that.axesLayer and that.compLayer and that.gridLayer and that.coorlineLayer and that.topLayer
        that.createAxes()
        that.createComponents()
    $("<div></div>").appendTo(this.root)
      .css("width", this.outwidth)
      .css("height", this.outheight)
      .css("position", "absolute")
      .css("left", 0)
      .css("top", 0)
      .css("z-index", 40)
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
      .css("z-index", 0)
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
      .css("z-index", 0)
      .svg({
        onLoad: (svg) ->
          that.gridLayer = svg
          allLoaded()
        settings: {
          width: that.outwidth
          height: that.outheight
        }
      })
    $("<div></div>").appendTo(this.root)
      .css("width", this.outwidth)
      .css("height", this.outheight)
      .css("position", "absolute")
      .css("left", 0)
      .css("top", 0)
      .css("z-index", 0)
      .svg({
        onLoad: (svg) ->
          that.coorlineLayer = svg
          allLoaded()
        settings: {
          width: that.outwidth
          height: that.outheight
        }
      })
    this.topLayer = $("<div></div>").appendTo(this.root)
      .css("width", this.outwidth)
      .css("height", this.outheight)
      .css("position", "absolute")
      .css("left", 0)
      .css("top", 0)
      .css("z-index", 90)
    allLoaded()
    # Mouse event
    this.mouseDown = false
    this.root.on("mousedown", (event) -> that.onMouseDown(event))
    this.root.on("mouseup", (event) -> that.onMouseUp(event))
    this.root.on("mouseenter", (event) -> that.onMouseEnter(event))
    this.root.on("mouseleave", (event) -> that.onMouseLeave(event))
    this.root.on("mousemove", (event) -> that.onMouseMove(event))
    # Mouse event modes
    this.mouseMode = null
    this.showMouseCoor = false

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
    this.axesTicks = []
    this.axesTickLabels = []
    # X ticks
    ticks = this.axes.xticks
    tickvals = ticks.ticks
    viewport = arrsort(this.viewport[0])
    if this.axes.xaxis.reversal
      viewport = viewport.reverse()
    if tickvals == "auto"
      tickvals = autoticks(viewport, [this.boxleft, this.boxright])
    tickposes = (val2px(v, viewport, [this.boxleft, this.boxright], this.axes.xaxis.reversal) for v in tickvals)
    ticklabels = ticks.labels
    tickexp = null
    if ticklabels == "auto"
      sciticks = format_tickvals(tickvals)
      tickexp = sciticks.exp
      if tickexp == 0 then tickexp = null
      ticknums = sciticks.nums
      ticklabels = (format_number(t, 3) for t in ticknums)
    sign = if this.xaxistop then 1 else -1
    ticklen = normlen2pxlen(ticks.length[0], [this.boxleft, this.boxright])
    if ticks.dir == "both"
      ticky = [this.xaxisposy - ticklen, this.xaxisposy + ticklen]
    else if ticks.dir == "out"
      ticky = [this.xaxisposy - sign * ticklen, this.xaxisposy]
    else
      ticky = [this.xaxisposy, this.xaxisposy + sign * ticklen]
    maxheight = 0
    if tickvals.length > 0
      for i in [0..tickvals.length-1]
        this.axesTicks.push this.axesLayer.line(null,
          tickposes[i],
          ticky[0],
          tickposes[i],
          ticky[1], {
            "stroke": "black"
            "stroke-width": this.axes.line_width
          })
        textarea = createTextArea({ text: ticklabels[i], font: this.axes.font }, if this.xaxistop then "centerbottom" else "centertop").appendTo(this.topLayer)
          .addClass('axis-tick-label')
          .css('top', this.xaxisposy - sign * ticklen * 2)
          .css('left', tickposes[i])
        height = textarea.height()
        if maxheight < height then maxheight = height
      unless tickexp == null
        createTextArea({ text: "10e" + tickexp, font: this.axes.font }, if this.xaxistop then "centerbottom" else "centertop").appendTo(this.topLayer)
          .addClass('axis-tick-label')
          .css('top', this.xaxisposy - sign * (ticklen * 2 + maxheight + ticklen * 2))
          .css('left', tickposes[i-1])
    # Y ticks
    ticks = this.axes.yticks
    tickvals = ticks.ticks
    viewport = arrsort(this.viewport[1])
    if this.axes.xaxis.reversal
      viewport = viewport.reverse()
    if tickvals == "auto"
      tickvals = autoticks(viewport, [this.boxtop, this.boxbottom])
    tickposes = (val2px(v, viewport, [this.boxtop, this.boxbottom], not this.axes.yaxis.reversal) for v in tickvals)
    ticklabels = ticks.labels
    tickexp = null
    if ticklabels == "auto"
      sciticks = format_tickvals(tickvals)
      tickexp = sciticks.exp
      if tickexp == 0 then tickexp = null
      ticknums = sciticks.nums
      ticklabels = (format_number(t, 3) for t in ticknums)
    sign = if this.yaxisleft then 1 else -1
    ticklen = normlen2pxlen(ticks.length[0], [this.boxtop, this.boxbottom])
    if ticks.dir == "both"
      tickx = [this.yaxisposx - ticklen, this.yaxisposx + ticklen]
    else if ticks.dir == "out"
      tickx = [this.yaxisposx - sign * ticklen, this.yaxisposx]
    else
      tickx = [this.yaxisposx, this.yaxisposx + sign * ticklen]
    maxwidth = 0
    if tickvals.length > 0
      for i in [0..tickvals.length-1]
        this.axesTicks.push this.axesLayer.line(null,
          tickx[0],
          tickposes[i],
          tickx[1],
          tickposes[i], {
            "stroke": "black"
            "stroke-width": this.axes.line_width
          })
        textarea = createTextArea({ text: ticklabels[i], font: this.axes.font }, if this.yaxisleft then "rightcenter" else "leftcenter").appendTo(this.topLayer)
          .addClass('axis-tick-label')
          .css('top', tickposes[i])
          .css('left', this.yaxisposx - sign * ticklen * 2)
        width = textarea.width()
        if maxwidth < width then maxwidth = width
      unless tickexp == null
        createTextArea({ text: "10e" + tickexp, font: this.axes.font }, if this.yaxisleft then "rightcenter" else "leftcenter").appendTo(this.topLayer)
          .addClass('axis-tick-label')
          .css('top', tickposes[i-1])
          .css('left', this.yaxisposx - sign * (ticklen * 2 + maxwidth + ticklen * 2))

  createComponents: () ->
    this.compLayer.remove(el) for el in (this.componentEls || [])
    this.componentEls = []
    this.componentPoints = []
    for comp in this.axes.components
      if comp.type == "line"
        this.drawLine(comp.component)

  drawLine: (line) ->
    data = line.data
    that = this
    make_pxpoint = (p) ->
      arr = [val2px(p[0], that.viewport[0], [0, that.boxwidth], that.axes.xaxis.reversal), val2px(p[1], that.viewport[1], [0, that.boxheight], not that.axes.yaxis.reversal)]
      arr.point = p
      return arr
    pxpoints = (make_pxpoint(p) for p in line.data)
    linewidth = with_default(with_default(line.line_width, this.axes.line_width), 1)
    styles = {}
    styles["stroke"] = line.color.csscolor()
    styles["stroke-width"] = linewidth
    styles["stroke-dasharray"] = linestyle2dasharray(line.style, linewidth)
    styles["fill"] = "none"
    el = this.compLayer.polyline(null, pxpoints, styles)
    inframe_points = (p for p in pxpoints when ((p[0] >= 0) and (p[0] <= this.boxwidth) and (p[1] >= 0) and (p[1] <= this.boxheight)))
    this.componentEls.push el
    this.componentPoints.push inframe_points

  setViewport: (viewport) ->
    if viewport == null or viewport == undefined
      viewport = this.init_viewport
      viewbox = null
      this.viewport = viewport
    else
      transviewbox = (vp, ivp, pxlen) ->
        vp = arrsort(vp)
        ivp = arrsort(ivp)
        pxlen = Math.abs(pxlen)
        return [(vp[0] - ivp[0]) / (ivp[1] - ivp[0]) * pxlen, (vp[1] - ivp[0]) / (ivp[1] - ivp[0]) * pxlen]
      viewbox = (transviewbox(viewport[i], this.init_viewport[i], [this.boxwidth, this.boxheight][i]) for i in [0,1])
      viewbox = [viewbox[0][0], viewbox[1][0], viewbox[0][1] - viewbox[0][0], viewbox[1][1] - viewbox[1][0]].join(",")
      this.viewport = viewport
    this.updateAxes()
    # this.compLayer.configure({ "viewBox": viewbox })
    this.createComponents()

  setMouseMode: (mode) ->
    this.mouseMode = mode
    if this.mouseMode == "zoom"
      this.root.css("cursor", "crosshair")
    else if this.mouseMode == "drag"
      this.root.css("cursor", "move")
    else
      this.root.css("cursor", "default")
    if this.mouseMode != "curse"
      this.decursePoint()

  clearMouseObjects: (event) ->
    if this.zoom_frame
      this.zoom_frame.remove()
      this.zoom_frame = null

  onMouseDown: (event) ->
    this.mouseDown = true
    this.mouseDownTime2 = this.mouseDownTime
    this.mouseDownTime = new Date().getTime()
    this.mouseDownPos =
      x: event.clientX - this.root.offset().left
      y: event.clientY - this.root.offset().top
    this.clearMouseObjects()
    if this.mouseMode == "zoom"
      if this.zoom_frame then this.zoom_frame.remove()
      this.zoom_frame = $("<div></div>").appendTo(this.topLayer)
        .addClass('axes-zoom-frame')
        .css("width", 0)
        .css("height", 0)
        .css("position", "absolute")
        .css("left", this.mouseDownPos.x)
        .css("top", this.mouseDownPos.y)
        .css("border-width", 1)
        .css("border-color", "#999999")
        .css("border-style", "solid")
    if this.mouseMode == "drag"
      this.mouseDownViewport = this.viewport
    if this.mouseMode == "curse"
      this.cursePoint(this.mouseDownPos)

  onMouseUp: (event) ->
    mouseDownBefore = this.mouseDown
    this.mouseDown = false
    eventtime = new Date().getTime()
    eventpos = 
      x: event.clientX - this.root.offset().left
      y: event.clientY - this.root.offset().top
    this.clearMouseObjects()
    if this.mouseMode == "zoom" and mouseDownBefore
      select_area = 
        x1: this.mouseDownPos.x - this.boxleft
        y1: this.mouseDownPos.y - this.boxtop
        x2: eventpos.x - this.boxleft
        y2: eventpos.y - this.boxtop
      unless Math.abs(select_area.x2 - select_area.x1) < 2 and Math.abs(select_area.y2 - select_area.y1) < 2
        norm_area = [
          (l / this.boxwidth for l in arrsort([select_area.x1, select_area.x2])),
          (l / this.boxheight for l in arrsort([select_area.y1, select_area.y2]))
        ]
        transviewport = (na, ivp, reversal) ->
          if reversal
            return (na[i] * (ivp[0] - ivp[1]) + ivp[1] for i in [0,1])
          else
            return (na[i] * (ivp[1] - ivp[0]) + ivp[0] for i in [0,1])
        viewport = [
          transviewport(norm_area[0], arrsort(this.viewport[0]), this.axes.xaxis.reversal),
          transviewport(norm_area[1], arrsort(this.viewport[1]), not this.axes.yaxis.reversal)
        ]
        this.setViewport(viewport)
    # Clicks
    if eventtime - this.mouseDownTime < click_interval_threshold
      this.onMouseClick(event)
      if this.mouseDownTime - this.mouseDownTime2 < click_interval_threshold
        this.onMouseDoubleClick(event)

  onMouseClick: (event) ->
    this

  onMouseDoubleClick: (event) ->
    if this.mouseMode == "zoom" then this.setViewport(null)
    if this.mouseMode == "drag" then this.setViewport(null)

  updateCoorlines: (eventpos) ->
    if this.showMouseCoor
      linestyle =
        "stroke": "#333333"
        "stroke-width": 0.25
        "stroke-dasharray": "5,5"
      unless this.xcoorline then this.xcoorline = this.coorlineLayer.line(0, eventpos.y, this.outwidth, eventpos.y, linestyle)
      unless this.ycoorline then this.ycoorline = this.coorlineLayer.line(eventpos.x, 0, eventpos.x, this.outheight, linestyle)
      this.coorlineLayer.change this.xcoorline, {
        y1: eventpos.y
        y2: eventpos.y
      }
      this.coorlineLayer.change this.ycoorline, {
        x1: eventpos.x
        x2: eventpos.x
      }

  cursePoint: (eventpos) ->
    if this.mouseMode == "curse" and this.mouseDown
      minpoint = null
      mindist = null
      for compPoints in this.componentPoints
        for p in compPoints
          d = Math.abs(p[0] - eventpos.x + this.boxleft) + Math.abs(p[1] - eventpos.y + this.boxtop)
          if mindist == null or mindist > d
            mindist = d
            minpoint = p
      if minpoint != null and mindist < 10
        this.cursingPoint = minpoint
        if this.cursingPointLabel then this.cursingPointLabel.remove()
        if this.cursingPointPoint then this.cursingPointPoint.remove()
        this.cursingPointPoint = $("<div></div>").appendTo(this.topLayer)
          .addClass("axes-cursing-point-point")
          .css("position", "absolute")
          .css("left", this.cursingPoint[0] + this.boxleft - 3)
          .css("top", this.cursingPoint[1] + this.boxtop - 3)
          .css("width", 6)
          .css("height", 6)
          .css("border-width", 1)
          .css("border-color", "white")
          .css("border-style", "solid")
          .css("background-color", "black")
        this.cursingPointLabel = $("<div></div>").appendTo(this.topLayer)
          .addClass("axes-cursing-point-label")
          .css("position", "absolute")
          .css("left", this.cursingPoint[0] + this.boxleft + 5)
          .css("top", this.cursingPoint[1] + this.boxtop - 5 - 40)
          .css("padding", 5)
          .css("box-shadow", "0 0 5px #333333")
          .css("font-size", 10)
          .css("font-family", "sans-serif")
          .css("line-height", 15 + "px")
          .css("background-color", "white")
          .css("height", 40)
        $("<div></div>").css("white-space", "nowrap").text("x: " + this.cursingPoint.point[0]).appendTo(this.cursingPointLabel)
        $("<div></div>").css("white-space", "nowrap").text("y: " + this.cursingPoint.point[1]).appendTo(this.cursingPointLabel)

  decursePoint: () ->
    this.cursingPoint = null
    if this.cursingPointLabel
      this.cursingPointLabel.remove()
      this.cursingPointLabel = null
    if this.cursingPointPoint
      this.cursingPointPoint.remove()
      this.cursingPointPoint = null

  onMouseEnter: (event) ->
    eventpos = 
      x: event.clientX - this.root.offset().left
      y: event.clientY - this.root.offset().top
    if this.showMouseCoor then this.updateCoorlines(eventpos)

  onMouseLeave: (event) ->
    this.mouseDown = false
    this.clearMouseObjects()
    if this.xcoorline
      this.coorlineLayer.remove(this.xcoorline)
      this.xcoorline = null
    if this.ycoorline
      this.coorlineLayer.remove(this.ycoorline)
      this.ycoorline = null

  onMouseMove: (event) ->
    eventpos = 
      x: event.clientX - this.root.offset().left
      y: event.clientY - this.root.offset().top
    if this.showMouseCoor then this.updateCoorlines(eventpos)
    if this.mouseMode == "zoom" and this.mouseDown
      this.zoom_frame
        .css("left", Math.min(eventpos.x, this.mouseDownPos.x))
        .css("top", Math.min(eventpos.y, this.mouseDownPos.y))
        .css("width", Math.abs(eventpos.x - this.mouseDownPos.x))
        .css("height", Math.abs(eventpos.y - this.mouseDownPos.y))
    if this.mouseMode == "drag" and this.mouseDown
      deltapxx = eventpos.x - this.mouseDownPos.x
      deltapxy = eventpos.y - this.mouseDownPos.y
      trans = (deltapx, pxlen, vp, reversed) ->
        vp = arrsort(vp)
        if reversed
          return deltapx / pxlen * (vp[0] - vp[1])
        else
          return deltapx / pxlen * (vp[1] - vp[0])
      deltavpx = trans(deltapxx, this.boxwidth, this.mouseDownViewport[0], this.axes.xaxis.reversal)
      deltavpy = trans(deltapxy, this.boxheight, this.mouseDownViewport[1], not this.axes.yaxis.reversal)
      viewport = [
        ((this.mouseDownViewport[0][i] - deltavpx) for i in [0,1]),
        ((this.mouseDownViewport[1][i] - deltavpy) for i in [0,1])
      ]
      this.setViewport(viewport)
    if this.mouseMode == "curse" and this.mouseDown
      this.cursePoint(eventpos)



module.exports.FigureFrame = FigureFrame
module.exports.AxesFrame = AxesFrame
