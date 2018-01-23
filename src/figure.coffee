axesModuleInitializer = require('./models/axes')
basicModuleInitializer = require('./models/basic')
drawModule = require('./drawing/draw')
extend = require('./utils/utils').extend

out_module = {}
out_module.init = (defaults) ->
  basicModule = basicModuleInitializer({ defaults: defaults })
  axesModule = axesModuleInitializer({
    defaults: defaults
    basic: basicModule
  })
  return extend({}, basicModule, axesModule, drawModule)

window.webfig = out_module
module.exports = out_module