import numpy as np
import matplotlib
matplotlib.use("TkAgg")
from matplotlib import pyplot as plt

f = 24E6 # 24 MHz
t = [x * 1E-7 for x in range(10000)] #
a = [np.sin(2*np.pi*f*x) for x in t]

plt.plot(t,a)
plt.show()