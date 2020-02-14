# Aliases and short functions go here
# ===========================================================================

# Length of data vector in each channel in S
Lx(S::GphysData) = [length(S.x[i]) for i in 1:S.n]

# Change a string separator to a path separator
change_sep(S::Array{String,1}) = [replace(i, "/" => Base.Filesystem.pathsep()) for i in S]

# Check that fields are preserved from S1 to S2
test_fields_preserved(S1::GphysData, S2::GphysData, x::Int, y::Int) =
  @test(minimum([getfield(S1,f)[x]==getfield(S2,f)[y] for f in datafields]))
test_fields_preserved(S1::SeisChannel, S2::GphysData, y::Int) =
  @test(minimum([getfield(S1,f)==getfield(S2,f)[y] for f in datafields]))

# Randomly colored printing
printcol(r::Float64) = (r ≥ 1.00 ? 1 : r ≥ 0.75 ? 202 : r ≥ 0.50 ? 190 : r ≥ 0.25 ? 148 : 10)

# This function exists because Appveyor can't decide on its own write permissions
function safe_rm(file::String)
  try
    rm(file)
  catch err
    @warn(string("Can't remove ", file, ": throws error ", err))
  end
  return nothing
end

# Basic sanity check: does :t match :x
function basic_checks(S::GphysData)
  for i = 1:S.n
    if S.fs[i] == 0.0
      @test size(S.t[i],1) == length(S.x[i])
    else
      @test S.t[i][end,1] == length(S.x[i])
    end
  end
  return nothing
end

# Get the start and end times of each channel in S
function get_edge_times(S::GphysData)
  ts = [S.t[i][1,2] for i=1:S.n]
  te = copy(ts)
  for i=1:S.n
    if S.fs[i] == 0.0
      te[i] = S.t[i][end,2]
    else
      te[i] += (sum(S.t[i][2:end,2]) + dtμ*length(S.x[i]))
    end
  end
  return ts, te
end

# Convert lat, lon to x, y
function latlon2xy(xlat::Float64, xlon::Float64)
  s = sign(xlon)
  c = 111194.6976
  y = c*xlat
  d = acosd(cosd(xlon*s)*cosd(xlat))
  x = sqrt(c^2*d^2-y^2)
  return [round(Int32, s*x), round(Int32, y)]
end

# A simple time counting loop
function loop_time(ts::Int64, te::Int64; ti::Int64=86400000000)
  t1 = deepcopy(ts)
  j = 0
  while t1 < te
    j += 1
    t1 = min(ts + ti, te)
    s_str = int2tstr(ts + 1)
    t_str = int2tstr(t1)
    ts += ti
  end
  return j
end

# Remove low-gain seismic data channels
function remove_low_gain!(S::GphysData)
    i_low = findall([occursin(r".EL?", S.id[i]) for i=1:S.n])
    if !isempty(i_low)
        for k = length(i_low):-1:1
            @warn(join(["Low-gain, low-fs channel removed: ", S.id[i_low[k]]]))
            S -= S.id[i_low[k]]
        end
    end
    return nothing
end

# test that each field has the right number of entries
function sizetest(S::GphysData, nt::Int)
  @test ≈(S.n, nt)
  @test ≈(maximum([length(getfield(S,i)) for i in datafields]), nt)
  @test ≈(minimum([length(getfield(S,i)) for i in datafields]), nt)
  return nothing
end

# Test that data are time synched correctly within a SeisData structure
function sync_test!(S::GphysData)
    local L = [length(S.x[i])/S.fs[i] for i = 1:S.n]
    local t = [S.t[i][1,2] for i = 1:S.n]
    @test maximum(L) - minimum(L) ≤ maximum(2.0./S.fs)
    @test maximum(t) - minimum(t) ≤ maximum(2.0./S.fs)
    return nothing
end
