import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("TkAgg")
from matplotlib import pyplot as plt
import csv

df = pd.read_csv("plot.csv", delimiter='\n')
x_data = df['# time step = 0.000005 sec']

x_int = []

for x in range(len(x_data)-1):
    if (x_data[x+1] >= 0) and (x_data[x] < 0):
        x_int.append(x * 0.000005)

periods = []
for x in range(len(x_int)-1):
    periods.append(x_int[x+1]-x_int[x])

frequencies = [1/x for x in periods]

plt.subplot(2,1,1)
plt.hist(periods, bins=500)
plt.xlabel("Frequency (Hz)")

plt.subplot(2,1,2)
plt.plot(x_data)
plt.xlabel("Time")

plt.show()