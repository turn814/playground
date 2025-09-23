import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("TkAgg")
from matplotlib import pyplot as plt
import csv

df = pd.read_csv("plot_1.csv", delimiter=',')
x_data = df["Time (ns)"]
y_data = df["Amplitude"]

x_int = []
for x in range(len(y_data)-1):
    if (y_data[x+1] >= 0) and (y_data[x] < 0):
        x_int.append(x_data[x])

periods = []
for x in range(len(x_int)-1):
    periods.append(x_int[x+1]-x_int[x])

frequencies = [1/x for x in periods]

plt.hist(frequencies, bins=50)
plt.xlabel("Frequency (Hz)")

plt.show()
