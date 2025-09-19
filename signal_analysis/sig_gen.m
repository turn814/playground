x = 1:1000;
t = x * 1E-10;

y = sin(t*1E9);

figure(1)
plot(y)

x_int = double.empty;
n = 0;

for i = 1:(length(y)-1)
    if y(i+1) > 0 && y(i) <= 0
        n = n + 1;
        x_int(n) = t(i);
    end
end

periods = double.empty;
for i = 1:(length(x_int)-1)
    periods(i) = x_int(i+1) - x_int(i);
end

frequencies = 1./periods;

figure(2)
histogram(frequencies,50)

figure(3)
plot(spectrum(y))