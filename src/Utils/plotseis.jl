using PyPlot: figure, axes, plot, xlim, ylim, xlabel, xticks, yticks, title, broken_barh, bar, ylabel

rescaled(x::Array{Float64,1},i::Int) = (Float64(i) + x./(2.0*maximum(abs(x))))

function xfmt(xmi::Int64, xma::Int64; fmt="auto"::ASCIIString, auto_x=true::Bool, N=4::Int)
  dt = (xma-xmi)
  if fmt == "auto"
    if dt*μs < 3600
      fmt ="%M:%S"
      xstr = @sprintf("Time [%s] from %s:00:00 (UTC)",fmt,Libc.strftime("%Y-%m-%d %H",tzcorr()+xmi*μs))
    elseif dt*μs < 86400
      fmt ="%T"
      xstr = @sprintf("Time [%s], %s (UTC)",fmt,Libc.strftime("%Y-%m-%d",tzcorr()+xmi*μs))
    elseif yflag
      fmt ="%Y-%m-%d %H:%M:%S"
      xstr = @sprintf("Time [%s] (UTC)",fmt)
    else
      fmt ="%d %b %T"
      xstr = @sprintf("Time [%s] (UTC), %s",fmt,Libc.strftime("%Y",tzcorr()+xmi*μs))
    end
    xlabel(xstr)
  else
    xlabel(@sprintf("Time [%s]",replace(fmt, "%", "")))
  end
  dt /= 3

  if auto_x
    xt = Array{Float64,1}[]
    xl = Array{ASCIIString,1}[]
    for i = 1:N
      xt = cat(1, xt, xmi+(i-1)*dt)
      xl = cat(1, xl, Libc.strftime(fmt,xt[i]))
    end
    xlim(xmi, xma)
    xticks(xt, xl)
  end
  return nothing
end

"""
    plotseis(S::SeisData)

Renormalized, time-aligned trace plot of data in S.x using timestamps in S.t.

    plotseis(S::SeisData; fmt=FMT)

Use timing of channel C to determine x-ticks and format FMT to format x-labels.
"""
function plotseis(S::SeisData; fmt="auto"::ASCIIString, use_name=false::Bool, auto_x=true::Bool)
  # Basic plotting
  figure()
  axes([0.15, 0.1, 0.8, 0.8])
  xmi = 2^63-1
  xma = xmi+1
  yflag = false

  for i = 1:1:S.n
    t = t_expand(S.t[i],S.fs[i])
    xmi = min(xmi, t[1])
    xma = max(xmi, t[end])
    floor(t[1]/31536000) == floor(t[end]/31536000) || (yflag == true)
    if S.fs[i] > 0
      x = rescaled(S.x[i]-mean(S.x[i]),i)
      plot(t, x, linewidth=1)
    else
      x = (i-0.4) .+ 0.8*S.x[i]./maximum(S.x[i])
      for j = 1:length(t)
        plot([t[j], t[j]], [i-0.4, x[j]], color=[0, 0, 0], ls="-", lw=1)
      end
      plot(t, x, linewidth=1, marker="o", markeredgecolor=[0,0,0], ls="none")
    end
  end

  xfmt(xmi, xma, fmt=fmt, auto_x=auto_x)
  ylim(0.5, S.n+0.5)
  yticks(collect(1:1:S.n), map((i) -> replace(i, " ", ""), use_name? S.name : S.id))
  return nothing
end

"""
    plot_uptimes(S)

Bar plot of uptimes for each channel in S.

    plot_uptimes(S, mode='b')

Bar plot of network uptime for all channels that record timeseries data, scaled
so that y=1 corresponds to all sensors active. Non-timeseries data in S are not
counted.
"""
function plot_uptimes(S::SeisData; mode='c'::Char, fmt="auto"::ASCIIString, use_name=false::Bool, auto_x=true::Bool)
  figure()
  ax = axes([0.15, 0.1, 0.8, 0.8])

  if mode == 'c'
    uptimes_bar(S, fmt, use_name, auto_x)
  elseif mode == 'b'
    uptimes_sum(S, fmt, use_name, auto_x)
  end
  return nothing
end

function uptimes_bar(S::SeisData, fmt::ASCIIString, use_name::Bool, auto_x::Bool)
  xmi = 2^63-1
  xma = xmi+1
  yflag = false

  for i = 1:S.n
    t = t_expand(S.t[i],S.fs[i])
    xmi = min(xmi, t[1])
    xma = max(xma, t[end])
    if S.fs[i] == 0
      plot(t, collect(repeated(i,length(t))),  marker="o", markeredgecolor=[0,0,0], markerfacecolor=[1,0,1], markersize=8, ls="none")
    else
      for j = 1:size(S.t[i],1)-1
        st = t[S.t[i][j,1]+1]
        en = t[S.t[i][j+1,1]-1]
        broken_barh([(st, en-st)], (i-0.4, 0.8), facecolor=[0,0,1])
      end
    end
  end

  xfmt(xmi, xma, fmt=fmt, auto_x=auto_x)
  ylim(0.5, S.n+0.5)
  yticks(collect(1:1:S.n), map((i) -> replace(i, " ", ""), use_name? S.name : S.id))
  title("Channel uptimes")
  return nothing
end

function uptimes_sum(S::SeisData, fmt::ASCIIString, use_name::Bool, auto_x::Bool)
  xmi = 2^63-1
  xma = xmi+1
  yflag = false
  tt = Array{Int64,2}(0,2)

  for i = 1:S.n
    t = t_expand(S.t[i],S.fs[i])
    S.fs[i] == 0 && continue
    xmi = min(xmi, t[1])
    xma = max(xma, t[end])
    for j = 1:size(S.t[i],1)-1
      st = t[S.t[i][j,1]+1]
      en = t[S.t[i][j+1,1]-1]
      tt = [tt; [st 1]; [en -1]]
    end
  end
  tt = sortrows(tt)
  t = tt[:,1]
  h = cumsum(tt[:,2])./S.n
  w = diff(t)
  x = t[1:end-1]
  bar(x,h[1:end-1],w,color="b")

  xfmt(xmi, xma, fmt=fmt, auto_x=auto_x)
  ylabel(@sprintf("%% of Network Active (n=%i)", sum(S.fs.>0)))
  ylim(0.0, 1.0)
  yticks(collect(0.0:0.2:1.0))
  return nothing
end
