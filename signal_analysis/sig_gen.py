import numpy as np
import matplotlib
matplotlib.use("TkAgg")
from matplotlib import pyplot as plt

# signal
f = 24E6 # Hz
t = [x * 1E-10 for x in range(10000)] # seconds
a = [np.sin(2*np.pi*f*x) for x in t]



plt.plot(t,a)
plt.show()

f = open("plot_1.csv", "w")
f.write("Time (ns),Amplitude\n")
f.close()

for i in range(len(t)):
    with open("plot_1.csv","a") as f:
        f.write(f"{t[i]},{a[i]}\n")
