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
    self.dictionary = dictionary
  def __getattr__(self, name):
    if name in self.dictionary:
      return self.dictionary[name]
    return None

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
    if isinstance(name, basestring):
      d[name] = item
      name = None
      continue
    name = item
  return d

def todict(obj):
  if isinstance(obj, basestring):
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

def pad_after(arr, specified_length, elem=None):
  remain = specified_length - len(arr)
  if remain > 0:
    if isinstance(arr, tuple):
      return tuple(list(arr) + [elem for i in xrange(remain)])
    else:
      return arr + [elem for i in xrange(remain)]
  else:
    return arr


defaults = load_defaults()
