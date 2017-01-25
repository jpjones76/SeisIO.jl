# =============================================================
# Utility functions
sa_prune!(S::Union{Array{String,1},Array{SubString{String},1}}) = (deleteat!(S, find(isempty, S)); return S)
get_phase_start(pha::String, Pha::Array{String,2}) = findmin([parse(Float64,i) for i in Pha[:,4]])
get_phase_time(pha::String, Pha::Array{String,2}) = parse(Float64, Pha[find(Pha[:,3].==pha)[1],4])
get_phase_end(pha::String, Pha::Array{String,2}) = findmax([parse(Float64,i) for i in Pha[:,4]])

function next_phase(pha::String, Pha::Array{String,2})
  s = Pha[:,3]
  t = [parse(Float64,i) for i in Pha[:,4]]
  j = find(s.==pha)[1]
  i = t.-t[j].>0
  tt = t[i]
  ss = s[i]
  k = sortperm(tt.-t[j])[1]
  return(ss[k],tt[k])
end

function next_converted(pha::String, Pha::Array{String,2})
  s = Pha[:,3]
  t = [parse(Float64,i) for i in Pha[:,4]]
  j = find(s.==pha)[1]

  p = replace(lowercase(s[j]),"diff","")[end]
  if p == 'p'
    c = 's'
  else
    c = 'p'
  end
  p_bool = [replace(lowercase(a),"diff","")[end]==c for a in s]
  t_bool = t.-t[j].>0
  i = t_bool.*p_bool

  tt = t[i]
  ss = s[i]
  k = sortperm(tt.-t[j])[1]
  return(ss[k],tt[k])
end

"""
    distaz!(S::SeisEvent)

Compute Δ, Θ by the Haversine formula. Updates `S` with distance, azimuth, and backazimuth for each channel. Values are stored as `S.data.misc["dist"], S.data.misc["az"], S.data.misc["baz"]`.

"""
function distaz!(S::SeisEvent)
  rec = Array{Float64,2}(S.data.n,2)
  for i = 1:S.data.n
    rec[i,:] = S.data.loc[i][1:2]
  end
  (dist, az, baz) = gcdist(S.hdr.loc[1:2], rec)
  for i = 1:S.data.n
    S.data.misc[i]["dist"] = dist[i]
    S.data.misc[i]["az"] = az[i]
    S.data.misc[i]["baz"] = baz[i]
  end
end
