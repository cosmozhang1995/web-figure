import sys, os
import json

def extend(to, *args):
  for arg in args:
    if isinstance(arg, dict):
      for k in arg:
        to[k] = arg[k]
  return to

class DefaultsConfig:
  def __init__(self, dictionary):
    this.dictionary = dictionary
  def __getattr__(self, name):
    if name in self.dictionary:
      return this.dictionary[name]
    return super.__getattr__(self, name)

def load_defaults(filepath = None):
  if filepath is None:
    thisdir = os.path.split(os.path.realpath(__file__))[0]
    filepath = os.path.join(thisdir, "../../../defaults.json")
  f = open(filepath)
  d = json.load(f)
  f.close()
  return DefaultsConfig(d)

def with_default(val, defaultval = None):
  if val is None:
    return defaultval
  else:
    return val

def parse_matlab_named_arguments(args):
  name = None
  d = {}
  for item in args:
    if isinstance(name, str):
      d[name] = item
      name = None
      continue
    name = item
  return d

def todict(obj):
  if isinstance(obj, str):
    return obj
  elif isinstance(obj, int):
    return obj
  elif isinstance(obj, float):
    return obj
  elif isinstance(obj, bool):
    return obj
  elif obj is None:
    return obj
  elif isinstance(obj, dict):
    d = {}
    for k in obj:
      d[k] = todict(obj[k])
    return d
  elif isinstance(obj, list):
    return [todict(item) for item in obj]
  else:
    return obj.dict()


defaults = load_defaults()
