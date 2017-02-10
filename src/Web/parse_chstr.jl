function parse_charr(chan_in::Array{String,1}; d='.'::Char, fdsn=false::Bool)
    N = size(chan_in,1)
    chan_data = Array{String,2}(0,5)
    default = ""

    # Initial pass to parse to string array
    for i = 1:1:N
      chan_line = [strip(String(j)) for j in split(chan_in[i], d, keep=true, limit=5)]
      L = length(chan_line)
      if L < 2
        continue
      elseif L < 5
        append!(chan_line, collect(repeated(default, 5-L)))
      end
      chan_data = vcat(chan_data, reshape(chan_line, 1, 5))
    end

    return fdsn == true ? minreq!(chan_data) : chan_data
end

function parse_chstr(chan_in::String; d=','::Char, fdsn=false::Bool)
  chan_out = Array{String,2}(0,5)
  if isfile(chan_in)
    return parse_chstr(join([strip(j, ['\r','\n']) for j in filter(i -> !startswith(i, ['\#','\*']), open(readlines, chan_in))],','))
  else
    chan_data = [strip(String(j)) for j in split(chan_in, d)]
    for j = 1:1:length(chan_data)

      # Build array
      tmp_data = map(String, split(chan_data[j], '.'))
      L = length(tmp_data)
      L < 5 && append!(tmp_data, collect(repeated("",5-L)))
      chan_out = cat(1, chan_out, reshape(tmp_data, 1, 5))
    end
  end
  return fdsn == true ? minreq!(chan_out) : chan_out
end

function parse_sl(CC::Array{String,2})
  L = size(CC,1)
  S = CC[:,2].*collect(repeated(" ", L)).*CC[:,1]
  P = [(i = isempty(i) ? "??" : i) for i in CC[:,3]] .* [(i = isempty(i) ? "???" : i) for i in CC[:,4]] .* collect(repeated(".", L)) .* [(i = isempty(i) ? "D" : i) for i in CC[:,5]]
  return S,P
end

function build_stream_query(C::Array{String,1}, d0::String, d1::String, estr=""::String)
  net_str = isempty(C[1]) ? estr : "net="*C[1]
  sta_str = isempty(C[2]) ? estr : "&sta="*C[2]
  loc_str = isempty(C[3]) ? estr : "&loc="*C[3]
  cha_str = isempty(C[4]) ? estr : "&cha="*C[4]
  return net_str * sta_str * loc_str * cha_str * string("&start=", d0, "&end=", d1)
end

# ============================================================================
# Purpose: Create the most compact set of requests, one per row
"""
    minreq!(S::Array{String,2})

Reduce `S` to the most compact possible set of SeedLink request query strings that completely cover its string requests.
"""
function minreq!(S::Array{String,2})
  d = ','
  (M,N) = size(S)
  K = Array{Int64,1}(N)
  T = Array{String,2}(M,N)
  for n = 1:N
    for m = 1:M
      T[m,n] = join(S[m,1:N.!=n],d)
    end
    K[n] = length(unique(T[:,n]))
  end
  (L,J) = findmin(K)
  if L != M
    V = T[:,J]
    U = unique(V)
    Q = Array{String,2}(L,N)
    for i = 1:1:L
      j = find(V.==U[i])
      Q[i,1:N.!=J] = split(V[j[1]],d)
      Q[i,J] = join(S[j,J],d)
    end
    S = Q
  end
  return S
end
minreq!(S::Array{String,1}, T::Array{String,1}) = minreq!(hcat(S,T))
minreq(S::Array{String,2}) = (T = deepcopy(S); minreq!(T); return T)

"""
## CHANNEL ID SPECIFICATION
Channel ID data can be passed to SeisIO web functions in three ways:

1. String: comma-delineated list of IDs, formatted `"NET.STA.LOC.CHA"` (e.g. `"PB.B004.01.BS1,PB.B004.01.BS2"`)
2. Array{String,1}: one ID per entry, formatted `"NET.STA.LOC.CHA"` (e.g. `["PB.B004.01.BS1","PB.B004.01.BS2"]`)
3. Array{String,2}: one ID per row, formatted `["NET" "STA" "LOC" "CHA"]` (e.g. `["PB" "B004" "01" "BS?"; "PB" "B001" "01" "BS?"]`)

The `LOC` field can be left blank (e.g. `"UW.ELK..EHZ", ["UW" "ELK" "" "EHZ"]`).

#### SEEDLINK ONLY
For SeedLink functions (`SeedLink!`, `has_live_stream`, etc.), channel IDs can include a fifth field (i.e. NET.STA.LOC.CHA.T) to set the "type" flag (one of DECOTL, for Data, Event, Calibration, blOckette, Timing, or Logs). Note that calibration, timing, and logs are not yet supported by SeisIO.
"""
function chanspec()
  return nothing
end
