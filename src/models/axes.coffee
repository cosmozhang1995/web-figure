extend = require('../utils/utils').extend
parse_matlab_named_arguments = require('../utils/utils').parse_matlab_named_arguments
slice = require('../utils/utils').slice
with_default = require('../utils/utils').with_default

module.exports = (rootConfig) ->
  defaults = rootConfig.defaults
  basicModule = rootConfig.basic

  Color = basicModule.Color
  Font = basicModule.Font
  Text = basicModule.Text

  class Figure
    constructor: (config) ->
      config = extend({}, defaults.figure, config)
      this.subplots = config.subplots

    plot: () ->
      if this.subplots.length == 0
        this.subplots.push(new Axes())
      ax = this.subplots[this.subplots.length-1]
      ax.plot.apply(ax, arguments)
      return ax

  class Axes
    constructor: (config) ->
      config = extend({}, defaults.axes, config)
      # Appearance
      this.color = new Color(config.color)
      this.box_on = config.box_on
      this.box_style = config.box_style
      this.line_width = config.line_width
      # Axis
      this.xaxis = new Axis(config.xaxis)
      this.yaxis = new Axis(config.yaxis)
      this.zaxis = new Axis(config.zaxis)
      this.xaxis_location = config.xaxis_location
      this.yaxis_location = config.yaxis_location
      # Ticks
      this.xticks = new Ticks(config.xticks)
      this.yticks = new Ticks(config.yticks)
      this.zticks = new Ticks(config.zticks)
      # Grids
      this.grid = new Grid(config.grid)
      # Font
      this.font = new Font(config.font)
      # Title and Label
      this.title = new Text(config.title, config.title_font || this.font)
      this.xlabel = new Text(config.xlabel, config.xlabel_font || this.font)
      this.ylabel = new Text(config.ylabel, config.ylabel_font || this.font)
      this.zlabel = new Text(config.zlabel, config.zlabel_font || this.font)
      # Line color order
      this.color_order = (new Color(c) for c in config.color_order)
      this._next_color_idx = 0
      # Position and Visibility
      this.outer_position = config.outer_position
      this.position = config.position
      this.visible = config.visible
      this.units = config.units
      # Viewports
      this.viewport = with_default(config.viewport, config.default_viewport)
      # Components
      this.components = ((new Component(c)).component for c in config.components)
      # If viewport not set, set to default
      this.viewport = with_default(config.viewport, config.default_viewport)

    next_color: () ->
      color = this.color_order[this._next_color_idx]
      this._next_color_idx = (this._next_color_idx + 1) % this.color_order.length
      return color

    plot: () ->
      if arguments.length == 0
        return
      else if arguments.length == 1
        ydata = arguments[0]
        xdata = [0..ydata.length-1]
      else
        ydata = arguments[1]
        xdata = arguments[0]
      named_args = if arguments.length > 2 then parse_matlab_named_arguments(slice(arguments,2)) else {}
      axes_default = {
        data: ([xdata[i], ydata[i]] for i in [0..xdata.length-1])
        color: this.next_color()
        line_width: this.line_width
      }
      config = extend({}, defaults.line, axes_default, named_args)
      line = new Line(config)
      this.components.push(new Component(line))
      this.add_viewport(line.viewport())
      return this

    add_viewport: (viewport) ->
      if viewport == null || viewport == undefined
        return
      if this.viewport == null || this.viewport == undefined
        this.viewport = ([rng[0], rng[1]] for rng in viewport)
        return
      for i in [0..Math.min(viewport.length, this.viewport.length)-1]
        this.viewport[i][0] = Math.min(this.viewport[i][0], viewport[i][0])
        this.viewport[i][1] = Math.max(this.viewport[i][1], viewport[i][1])
      return

  class Axis
    constructor: (config) ->
      config = extend({}, defaults.axis, config)
      this.color = new Color(config.color)
      this.reversal = config.reversal || false
      this.scale = config.scale || 'linear'
      this.lim = config.lim || 'auto'

  class Ticks
    constructor: (config) ->
      config = extend({}, defaults.ticks, config)
      this.ticks = config.ticks
      this.labels = config.labels
      this.rotation = config.rotation
      this.length = config.length
      if typeof this.length == "number"
        this.length = [this.length, 0]
      this.dir = config.dir || 'in'

  class Grid
    constructor: (config) ->
      config = extend({}, defaults.grid, config)
      this.on = config.on
      this.style = config.style
      this.color = new Color(config.color)
      this.layer = config.layer

  class Component
    constructor: (arg) ->
      if arg instanceof Line
        this.type = "line"
        this.component = arg
      else if arg instanceof Image
        this.type = "image"
        this.component = arg
      else if arg instanceof Shape
        this.type = "shape"
        this.component = arg
      else
        config = extend({}, defaults.component, config)
        this.type = config.type
        if this.type == "line"
          this.component = new Line(config.config)
        else if this.type == "image"
          this.component = new Image(config.config)
        else if this.type == "shape"
          this.component = new Shape(config.config)
    viewport: () ->
      return this.component.viewport()

  class Line
    constructor: (config) ->
      config = extend({}, defaults.component_line, config)
      this.data = config.data
      this.line_width = config.line_width
      this.color = new Color(config.color)
      this.style = config.style
    viewport: () ->
      if this.data.length == 0
        return null
      ndims = this.data[0].length
      viewport = ([this.data[0][c], this.data[0][c]] for c in [0..ndims-1])
      for point in this.data
        for c in [0..ndims-1]
          viewport[c][0] = Math.min(viewport[c][0], point[c])
          viewport[c][1] = Math.max(viewport[c][1], point[c])
      return viewport

  class Image
    constructor: (config) ->
      config = extend({}, defaults.component_image, config)
      this.data = config.data
      this.rows = config.rows
      this.cols = config.cols
      this.channels = config.channels

  class Shape
    constructor: (config) ->
      config = extend({}, defaults.component_shape, config)
      this.data = config.data
      this.line_width = config.line_width
      this.color = new Color(config.color)
      this.face_color = new Color(config.face_color)
      unless this.face_color.valid
        this.face_color = new Color(this.color)
      this.style = config.style

  return {
    Figure: Figure
    Axes: Axes
    Axis: Axis
    Ticks: Ticks
    Grid: Grid
    Component: Component
    Line: Line
    Image: Image
    Shape: Shape
  }