# TO DO: Comment parse_chstr.jl, even I can't figure out what I've done here anymore
function parse_charr(chan_in::Array{String,1}; d='.'::Char, fdsn=false::Bool)
    N = length(chan_in)
    chan_data = Array{String,2}(undef, 0, 5)

    # Initial pass to parse to string array
    for i = 1:N
      chan_line = [strip(String(j)) for j in split(chan_in[i], d, keepempty=true, limit=5)]
      L = length(chan_line)
      if L < 5
        resize!(chan_line, 5)
        chan_line[L+1:5] .= ""
      end
      chan_data = vcat(chan_data, reshape(chan_line, 1, 5))
    end

    return fdsn == true ? minreq!(String.(chan_data)) : map(String, chan_data)
end

function parse_chstr(chan_in::String; d=','::Char, fdsn=false::Bool, SL=false::Bool)
  chan_out = Array{String, 2}(undef, 0, 5)
  if safe_isfile(chan_in)
    return parse_chstr(join([strip(j, ['\r','\n']) for j in
      filter(i -> !startswith(i, ['#','*']), open(readlines, chan_in))],','))
  else
    chan_data = [strip(String(j)) for j in split(chan_in, d)]
    for j = 1:length(chan_data)

      # Build array
      tmp_data = map(String, split(chan_data[j], '.'))
      L = length(tmp_data)
      if L < 5
        append!(tmp_data, Array{String,1}(undef, 5-L))
        tmp_data[L+1:5] .= ""
      end
      chan_out = cat(chan_out, reshape(tmp_data, 1, 5), dims=1)
    end
  end
  if fdsn == true
    minreq!(chan_out)
  end
  N = SL ? 4 : 5
  return chan_out[:,1:N]
end

function parse_sl(CC::Array{String,2})
  L = size(CC,1)
  S = CC[:,2].*(" "^L).*CC[:,1]
    P = [(i = isempty(i) ? "??" : i) for i in CC[:,3]] .*
        [(i = isempty(i) ? "???" : i) for i in CC[:,4]] .* fill(".", L) .*
        [(i = isempty(i) ? "D" : i) for i in CC[:,5]]
  return S,P
end

# FDSNWS
# http://service.iris.edu/fdsnws/dataselect/1/query?net=IU&sta=ANMO&loc=00&cha=BHZ&start=2010-02-27T06:30:00.000&end=2010-02-27T10:30:00.000
# IRISWS
# http://service.iris.edu/irisws/timeseries/1/query?net=IU&sta=ANMO&loc=00&cha=BHZ&starttime=2005-01-01T00:00:00&endtime=2005-01-02T00:00:00
# IRISWS
function build_stream_query(C::Array{String,1}, d0::String, d1::String; estr=""::String)
  net_str = isempty(C[1]) ? estr : "net="*C[1]
  sta_str = isempty(C[2]) ? estr : "&sta="*C[2]
  loc_str = isempty(C[3]) ? estr : "&loc="*C[3]
  cha_str = isempty(C[4]) ? estr : "&cha="*C[4]
  return net_str * sta_str * loc_str * cha_str * string("&start=", d0, "&end=", d1)
end

# ============================================================================
# Purpose: Create the most compact set of requests, one per row
# """
#     minreq!(S::Array{String,2})
#
# Reduce `S` to the most compact possible set of SeedLink request query strings
# that completely cover its string requests.
# """
function minreq!(S::Array{String,2})
  d = ','
  (M,N) = size(S)
  K = Array{Int64, 1}(undef, N)
  T = Array{String, 2}(undef, M, N)
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
    Q = Array{String,2}(undef, L, N)
    for i = 1:L
      j = findall(V.==U[i])
      Q[i,1:N.!=J] = split(V[j[1]],d)
      Q[i,J] = join(S[j,J],d)
    end
    S = Q
  end
  return map(String, S)
end
minreq(S::Array{String,2}) = (T = deepcopy(S); minreq!(T); return T)
