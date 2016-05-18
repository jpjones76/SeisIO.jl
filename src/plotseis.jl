using PyPlot: figure, axes, plot, xlim, ylim, xlabel, xticks, yticks, title

rescaled(x::Array{Float64,1},i::Int) = (Float64(i) + x./(2.0*maximum(abs(x))))

"""
    plotseis(S::SeisData)

Renormalized, time-aligned trace plot of data in S.x using timestamps in S.t.

    plotseis(S::SeisData; fmt=FMT)

Use timing of channel C to determine x-ticks and format FMT to format x-labels.
"""
function plotseis(S::SeisData; fmt="%H:%M:%S"::ASCIIString)
  # Basic plotting
  figure()
  axes([0.15, 0.1, 0.8, 0.8])
  xmi = Inf
  xma = -Inf

  for i = 1:1:S.n
    t = t_expand(S.t[i],1/S.fs[i])
    xmi = min(xmi, t[1])
    xma = max(xmi, t[end])
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

  dt = (xma-xmi)/3
  xt = Array{Float64,1}[]
  xl = Array{ASCIIString,1}[]
  for i = 1:1:4
    xt = cat(1, xt, xmi+(i-1)*dt)
    xl = cat(1, xl, Libc.strftime(fmt,xt[i]))
  end

  # Plot micromanagement
  xlim(xmi, xma)
  ylim(0.5, S.n+0.5)
  xticks(xt, xl)
  yticks(collect(1:1:S.n), map((x) -> replace(x, " ", ""), S.id))
  xlabel(@sprintf("Time [%s]",replace(fmt, "%", "")))
  return
end
