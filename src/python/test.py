from main import *
import numpy as np

xx = np.linspace(-2*np.pi, 2*np.pi, 1000)
yy = np.sin(xx)

fig = Figure()
fig.plot(xx, yy)

fig.save_to("../../public/image/webfig.json")
