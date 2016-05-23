using DSP, PyPlot

function specgram(T::SeisObj; window=nothing)
#fmt="%Y-%m-%d\n%H:%M:%S"
fmt="%H:%M:%S"
fs = T.fs
S = spectrogram(T.x, nextpow2(round(Int, 4*fs)), round(Int, .75*fs), fs=fs, window=window)
f = freq(S)
t = time(S)+T.t[1,2]
h = figure()
ax = axes()

u = imshow(flipud(10*log10(power(S))), extent=[first(t), last(t), fs*first(f), fs*last(f)], aspect="auto")
xmi = t[1]
xma = t[end]
ymi = fs*f[1]
yma = fs*f[end]
dt = (xma-xmi)/3
dy = (yma-ymi)/5
xt = Array{Float64,1}[]
xl = Array{ASCIIString,1}[]
yt = Array{Float64,1}[]
yl = Array{ASCIIString,1}[]
for i = 1:1:4
  xt = cat(1, xt, xmi+(i-1)*dt)
  xl = cat(1, xl, Libc.strftime(fmt,xt[i]))
end
for i = 1:1:6
  yt = cat(1, yt, ymi+(i-1)*dy)
  yl = cat(1, yl, @sprintf("%.2f", ymi+(i-1)*dy/fs))
end
xlim(xmi, xma)
xticks(xt, xl)
yticks(yt, yl)
xlabel(@sprintf("Time [%s]",replace(fmt, "%", "")))
title(string("Spectrogram, ", T.id))
hc = colorbar(u, ax=ax, drawedges=true)
return (h, u, ax, hc)
end
