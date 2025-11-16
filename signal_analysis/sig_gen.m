clear
close all

times = 0:0.001:10;
frequency_hz = 1;

A = sin(2*pi*frequency_hz*times);

hold on
plot(A)
plot(asin(A)-2*pi*frequency_hz*times)