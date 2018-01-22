extend = require('../utils/utils').extend
isset = require('../utils/utils').isset

module.exports = (rootConfig) ->
  defaults = rootConfig.defaults
  class Color
    constructor: () ->
      if arguments[0] instanceof Color
        # Color(clone: Color)
        clone = arguments[0]
        this.red = clone.red
        this.green = clone.green
        this.blue = clone.blue
        this.alpha = clone.alpha
        this.valid = clone.valid
      else if arguments[0] instanceof Array
        # Color(rgba: [r, g, b, a])
        rgba = arguments[0]
        this.red = rgba[0] || defaults.color.red
        this.green = rgba[1] || defaults.color.green
        this.blue = rgba[2] || defaults.color.blue
        this.alpha = rgba[3] || defaults.color.alpha
        this.valid = rgba.length > 0
      else if typeof arguments[0] == "object"
        # Color(config: { red: number, green: number, blue: number, alpha: number })
        config = arguments[0]
        this.red = config.red || defaults.color.red
        this.green = config.green || defaults.color.green
        this.blue = config.blue || defaults.color.blue
        this.alpha = config.alpha || defaults.color.alpha
        this.valid = true
      else if typeof arguments[0] == "string"
        color_scheme = defaults.color.color_scheme
        rgb = color_scheme[arguments[0]]
        this.red = rgb[0] || defaults.color.red
        this.green = rgb[1] || defaults.color.green
        this.blue = rgb[2] || defaults.color.blue
        this.alpha = defaults.color.alpha
        this.valid = true
      else
        # Color(r: number, g: number, b: number, a: number)
        # Color(void)
        arg = arguments || []
        this.red = arg[0] || defaults.color.red
        this.green = arg[1] || defaults.color.green
        this.blue = arg[2] || defaults.color.blue
        this.alpha = arg[3] || defaults.color.alpha
        this.valid = arg.length > 0
    
    csscolor: () ->
      norm2hex = (norm) ->
        intval = Math.round(norm * 255)
        if intval > 255
          intval = 255
        if intval < 0
          intval = 0
        chs = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f']
        d1 = Math.floor(intval / 16)
        d0 = intval - 16 * d1
        return chs[d1] + chs[d0]
      return "#" + norm2hex(this.red) + norm2hex(this.green) + norm2hex(this.blue)

  class Font
    constructor: (arg) ->
      # Font(void)
      # Font(name: string)
      # Font(config: {
      #   name: string,
      #   size: number,
      #   weight: 'normal' | 'bold',
      #   units: 'points' | 'inches' | 'centimeters' | 'pixels' | 'normalized',
      #   italic: boolean
      # })
      this.valid = isset(arg)
      arg = arg || {}
      if typeof arg == "string"
        arg = {
          name: arg
        }
      config = extend({}, defaults.font, arg)
      this.name = config.name
      this.size = config.size
      this.weight = config.weight
      this.units = config.units
      this.italic = config.italic
      this.color = new Color(config.color)

  class Text
    constructor: () ->
      this.valid = false
      if typeof arguments[0] == "string"
        # Text(text, font)
        this.text = arguments[0]
        this.font = new Font(font)
        this.valid = true
      else
        # Text({
        #   text: string
        #   font: Font | config<Font>
        # })
        config = extend({}, defaults.text, arguments[0])
        this.text = config.text
        this.font = new Font(config.font)
        this.valid = isset(this.text)

  return {
    Color: Color,
    Font: Font,
    Text: Text
  }
