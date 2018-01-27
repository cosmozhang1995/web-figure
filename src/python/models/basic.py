import sys, os
import json
from utils import extend, defaults, with_default, parse_matlab_named_arguments, todict

class Color:
  def __init__(self, *arguments):
    if (len(arguments) == 0) or (arguments is None):
      # Color(void)
      self.red = defaults.color["red"]
      self.green = defaults.color["green"]
      self.blue = defaults.color["blue"]
      self.alpha = defaults.color["alpha"]
      self.valid = False
    elif isinstance(arguments[0], Color):
      # Color(clone: Color)
      clone = arguments[0]
      self.red = clone.red
      self.green = clone.green
      self.blue = clone.blue
      self.alpha = clone.alpha
      self.valid = clone.valid
    elif isinstance(arguments[0], list):
      # Color(rgba: [r, g, b, a])
      rgba = arguments[0]
      self.red = rgba[0] || defaults.color["red"]
      self.green = rgba[1] || defaults.color["green"]
      self.blue = rgba[2] || defaults.color["blue"]
      self.alpha = rgba[3] || defaults.color["alpha"]
      self.valid = (len(rgba) > 0)
    elif isinstance(arguments[0], dict):
      # Color(config: { red: number, green: number, blue: number, alpha: number })
      config = arguments[0]
      self.red = config.red || defaults.color["red"]
      self.green = config.green || defaults.color["green"]
      self.blue = config.blue || defaults.color["blue"]
      self.alpha = config.alpha || defaults.color["alpha"]
      self.valid = True
    elif isinstance(arguments[0], str):
      color_scheme = defaults.color["color_scheme"]
      rgb = color_scheme[arguments[0]]
      self.red = rgb[0] || defaults.color["red"]
      self.green = rgb[1] || defaults.color["green"]
      self.blue = rgb[2] || defaults.color["blue"]
      self.alpha = defaults.color["alpha"]
      self.valid = True
    else:
      # Color(r: number, g: number, b: number, a: number)
      arg = arguments || []
      while len(arg) < 4: arg.append(None)
      self.red = arg[0] || defaults.color["red"]
      self.green = arg[1] || defaults.color["green"]
      self.blue = arg[2] || defaults.color["blue"]
      self.alpha = arg[3] || defaults.color["alpha"]
      self.valid = True
  
  def csscolor(self):
    def norm2hex(norm):
      intval = int(round(norm * 255))
      if intval > 255:
        intval = 255
      if intval < 0:
        intval = 0
      chs = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f']
      d1 = int(floor(intval / 16.0))
      d0 = intval - 16 * d1
      return chs[d1] + chs[d0]
    return "#" + norm2hex(self.red) + norm2hex(self.green) + norm2hex(self.blue)

  def cssrgba(self):
    def norm2uint8(norm):
      intval = int(round(norm * 255))
      if intval > 255:
        intval = 255
      if intval < 0:
        intval = 0
      return intval
    return "rgba(" + ",".join([str(norm2uint8(self.red)), str(norm2uint8(self.green)), str(norm2uint8(self.blue)), str(norm2uint8(self.alpha))]) + ")"

  def dict(self):
    if self.valid:
      return {
        "red": todict(self.red),
        "green": todict(self.green),
        "blue": todict(self.blue),
        "alpha": todict(self.alpha)
      }
    else:
      return None

class Font:
  def __init__(self, arg):
    # Font(void)
    # Font(name: string)
    # Font(config: {
    #   name: string,
    #   size: number,
    #   weight: 'normal' | 'bold',
    #   units: 'points' | 'inches' | 'centimeters' | 'pixels' | 'normalized',
    #   italic: boolean
    # })
    self.valid = (not arg is None)
    arg = arg || {}
    if isinstance(arg, str):
      arg = {
        name: arg
      }
    config = extend({}, defaults.font, arg)
    self.name = config["name"]
    self.size = config["size"]
    self.weight = config["weight"]
    self.units = config["units"]
    self.italic = config["italic"]
    self.color = Color(config["color"])

  def dict(self):
    if self.valid:
      return {
        "name": todict(self.name),
        "size": todict(self.size),
        "weight": todict(self.weight),
        "units": todict(self.units),
        "italic": todict(self.italic),
        "color": todict(self.color)
      }
    else:
      return None

class Text:
  def __init__(self):
    self.valid = false
    if typeof arguments[0] == "string":
      # Text(text, font)
      self.text = arguments[0]
      self.font = Font(font)
      self.valid = true
    else:
      # Text({
      #   text: string
      #   font: Font | config<Font>
      # })
      config = extend({}, defaults.text, arguments[0])
      self.text = config["text"]
      self.font = Font(config["font"])
      self.valid = (not self.text is None)

  def dict(self):
    if self.valid:
      return {
        "text": todict(self.text),
        "font": todict(self.font),
        "valid": todict(self.valid)
      }
    else:
      return None
