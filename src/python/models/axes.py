import sys, os
import json
from utils import extend, defaults, with_default, parse_matlab_named_arguments, todict
from basic import Color, Font, Text

class Figure:
  def __init__(self, config=None):
    config = extend({}, defaults.figure, config)
    self.subplots = [Axes(sp) for sp in config["subplots"]]
  def plot(self, *args, **kwargs):
    if len(self.subplots) == 0:
      self.subplots.append(Axes())
    ax = self.subplots[-1]
    apply(Axes.plot, [ax] + list(args), kwargs)
    return ax
  def dict(self):
    return {
      "subplots": todict(self.subplots)
    }
  def save_to(self, filepath):
    f = open(filepath, "w")
    json.dump(self.dict(), f, indent=2)
    f.close()

class Axes:
  def __init__(self, config=None):
    config = extend({}, defaults.axes, config)
    # Appearance
    self.color = Color(config["color"])
    self.box_on = config["box_on"]
    self.box_style = config["box_style"]
    self.line_width = config["line_width"]
    # Axis
    self.xaxis = Axis(config["xaxis"])
    self.yaxis = Axis(config["yaxis"])
    self.zaxis = Axis(config["zaxis"])
    self.xaxis_location = config["xaxis_location"]
    self.yaxis_location = config["yaxis_location"]
    # Ticks
    self.xticks = Ticks(config["xticks"])
    self.yticks = Ticks(config["yticks"])
    self.zticks = Ticks(config["zticks"])
    # Grids
    self.grid = Grid(config["grid"])
    # Font
    self.font = Font(config["font"])
    # Title and Label
    self.title = Text(config["title"], config["title_font"] or self.font)
    self.xlabel = Text(config["xlabel"], config["xlabel_font"] or self.font)
    self.ylabel = Text(config["ylabel"], config["ylabel_font"] or self.font)
    self.zlabel = Text(config["zlabel"], config["zlabel_font"] or self.font)
    # Line color order
    self.color_order = [Color(c) for c in config["color_order"]]
    self._next_color_idx = 0
    # Position and Visibility
    self.outer_position = config["outer_position"]
    self.position = config["position"]
    self.visible = config["visible"]
    self.units = config["units"]
    # Viewports
    #     Viewports is an array of 2D viewport vector
    #     Each 2D viewport vector is viewport of a dimension
    #     A 2D viewport vector is defined as [ lower_bound, upper_bound ]
    self.viewport = config["viewport"]
    self.default_viewport = config["default_viewport"]
    # Components
    self.components = [Component(c).component for c in config["components"]]

  def get_viewport(self):
    return with_default(self.viewport, self.default_viewport)

  def next_color(self):
    color = self.color_order[self._next_color_idx]
    self._next_color_idx = (self._next_color_idx + 1) % len(self.color_order)
    return color

  def plot(self, *args):
    if len(args) == 0:
      return
    elif len(args) == 1:
      ydata = list(args[0])
      xdata = range(1, len(ydata) + 1)
    else:
      ydata = list(args[1])
      xdata = list(args[0])
    named_args = parse_matlab_named_arguments(args[2:]) if (len(args) > 2) else {}
    axes_default = {
      "data": [[xdata[i], ydata[i]] for i in xrange(len(xdata))],
      "color": self.next_color(),
      "line_width": self.line_width
    }
    config = extend({}, defaults.line, axes_default, named_args)
    line = Line(config)
    self.components.append(Component(line))
    self.add_viewport(line.viewport())
    return self

  def add_viewport(self, viewport = None):
    if viewport is None:
      return
    if self.viewport is None:
      self.viewport = [[rng[0], rng[1]] for rng in viewport]
      return
    for i in xrange(min(len(viewport), len(self.viewport))):
      self.viewport[i][0] = min(self.viewport[i][0], viewport[i][0])
      self.viewport[i][1] = max(self.viewport[i][1], viewport[i][1])
    return
  
  def dict(self):
    return {
      "color": todict(self.color),
      "box_on": todict(self.box_on),
      "box_style": todict(self.box_style),
      "line_width": todict(self.line_width),
      "xaxis": todict(self.xaxis),
      "yaxis": todict(self.yaxis),
      "zaxis": todict(self.zaxis),
      "xaxis_location": todict(self.xaxis_location),
      "yaxis_location": todict(self.yaxis_location),
      "xticks": todict(self.xticks),
      "yticks": todict(self.yticks),
      "zticks": todict(self.zticks),
      "grid": todict(self.grid),
      "font": todict(self.font),
      "title": todict(self.title),
      "xlabel": todict(self.xlabel),
      "ylabel": todict(self.ylabel),
      "zlabel": todict(self.zlabel),
      "color_order": todict(self.color_order),
      "outer_position": todict(self.outer_position),
      "position": todict(self.position),
      "visible": todict(self.visible),
      "units": todict(self.units),
      "viewport": todict(self.viewport),
      "default_viewport": todict(self.default_viewport),
      "components": todict(self.components)
    }

class Axis:
  def __init__(self, config=None):
    config = extend({}, defaults.axis, config)
    self.color = Color(config["color"])
    self.reversal = config["reversal"] or False
    self.scale = config["scale"] or 'linear'
    self.lim = config["lim"] or 'auto'
  def dict(self):
    return {
      "color": todict(self.color),
      "reversal": todict(self.reversal),
      "scale": todict(self.scale),
      "lim": todict(self.lim)
    }

class Ticks:
  def __init__(self, config=None):
    config = extend({}, defaults.ticks, config)
    self.ticks = config["ticks"]
    self.labels = config["labels"]
    self.rotation = config["rotation"]
    self.length = config["length"]
    if not isinstance(self.length, list):
      self.length = [self.length, 0]
    self.dir = config["dir"] or 'in'
  def dict(self):
    return {
      "ticks": todict(self.ticks),
      "labels": todict(self.labels),
      "rotation": todict(self.rotation),
      "length": todict(self.length),
      "dir": todict(self.dir)
    }

class Grid:
  def __init__(self, config=None):
    config = extend({}, defaults.grid, config)
    self.on = config["on"]
    self.style = config["style"]
    self.color = Color(config["color"])
    self.layer = config["layer"]
  def dict(self):
    return {
      "on": todict(self.on),
      "style": todict(self.style),
      "color": todict(self.color),
      "layer": todict(self.layer)
    }

class Component:
  def __init__(self, arg=None):
    if isinstance(arg, Line):
      self.type = "line"
      self.component = arg
    elif isinstance(arg, Image):
      self.type = "image"
      self.component = arg
    elif isinstance(arg, Shape):
      self.type = "shape"
      self.component = arg
    elif isinstance(arg, dict):
      config = extend({}, defaults.component, config)
      self.type = config["type"]
      if self.type == "line":
        self.component = Line(config["config"])
      elif self.type == "image":
        self.component = Image(config["config"])
      elif self.type == "shape":
        self.component = Shape(config["config"])
    else:
      raise "Not recognized"
  def viewport(self):
    return self.component.viewport()
  def dict(self):
    return {
      "type": todict(self.type),
      "component": todict(self.component)
    }

class Line:
  def __init__(self, config=None):
    config = extend({}, defaults.component_line, config)
    self.data = config["data"]
    self.line_width = config["line_width"]
    self.color = Color(config["color"])
    self.style = config["style"]
  def viewport(self):
    if len(self.data) == 0:
      return None
    ndims = len(self.data[0])
    viewport = [[self.data[0][c], self.data[0][c]] for c in xrange(ndims)]
    for point in self.data:
      for c in xrange(ndims):
        viewport[c][0] = min(viewport[c][0], point[c])
        viewport[c][1] = max(viewport[c][1], point[c])
    return viewport
  def dict(self):
    return {
      "data": todict(self.data),
      "line_width": todict(self.line_width),
      "color": todict(self.color),
      "style": todict(self.style)
    }

class Image:
  def __init__(self, config=None):
    config = extend({}, defaults.component_image, config)
    self.data = config["data"]
    self.rows = config["rows"]
    self.cols = config["cols"]
    self.channels = config["channels"]
  def dict(self):
    return {
      "data": todict(self.data),
      "rows": todict(self.rows),
      "cols": todict(self.cols),
      "channels": todict(self.channels)
    }

class Shape:
  def __init__(self, config=None):
    config = extend({}, defaults.component_shape, config)
    self.data = config["data"]
    self.line_width = config["line_width"]
    self.color = Color(config["color"])
    self.face_color = Color(config["face_color"])
    if not self.face_color.valid:
      self.face_color = Color(self.color)
    self.style = config["style"]
  def dict(self):
    return {
      "data": todict(self.data),
      "line_width": todict(self.line_width),
      "color": todict(self.color),
      "face_color": todict(self.face_color),
      "style": todict(self.style)
    }
