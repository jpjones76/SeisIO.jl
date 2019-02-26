const μs = 1.0e-6
const datafields = [:name, :id, :fs, :gain, :loc, :misc, :notes, :resp, :src, :units, :t, :x]
const hdrfields = [:id, :ot, :loc, :mag, :int, :mt, :np, :pax, :src, :notes, :misc]

test_fields_preserved(S1::SeisData, S2::SeisData, x::Int, y::Int) =
  @test(minimum([getfield(S1,f)[x]==getfield(S2,f)[y] for f in datafields]))
test_fields_preserved(S1::SeisChannel, S2::SeisData, y::Int) =
  @test(minimum([getfield(S1,f)==getfield(S2,f)[y] for f in datafields]))

function sizetest(S::SeisData, nt::Int)
  @test ≈(S.n, nt)
  @test ≈(maximum([length(getfield(S,i)) for i in datafields]), nt)
  @test ≈(minimum([length(getfield(S,i)) for i in datafields]), nt)
  return nothing
end

function mktestseis()
  L0 = 30
  L1 = 10
  os = 5
  tt = time()
  t1 = round(Int64, tt/μs)
  t2 = round(Int64, (L0+os)/μs) + t1

  S = SeisData(5)
  S.name = ["Channel 1", "Channel 2", "Channel 3", "Channel 4", "Channel 5"]
  S.id = ["XX.TMP01.00.BHZ","XX.TMP01.00.BHN","XX.TMP01.00.BHE","CC.LON..BHZ","UW.SEP..EHZ"]
  S.fs = collect(Main.Base.Iterators.repeated(100.0, S.n))
  S.fs[4] = 20.0
  for i = 1:S.n
    os1 = round(Int64, 1/(S.fs[i]*μs))
    S.x[i] = randn(Int(L0*S.fs[i]))
    S.t[i] = [1 t1+os1; length(S.x[i]) 0]
  end

  T = SeisData(4)
  T.name = ["Channel 6", "Channel 7", "Channel 8", "Channel 9"]
  T.id = ["XX.TMP02.00.EHZ","XX.TMP03.00.EHN","CC.LON..BHZ","UW.SEP..EHZ"]
  T.fs = collect(Main.Base.Iterators.repeated(100.0, T.n))
  T.fs[3] = 20.0
  for i = 1:T.n
    T.x[i] = randn(Int(L1*T.fs[i]))
    T.t[i] = [1 t2; length(T.x[i]) 0]
  end
  return (S,T)
end

function remove_low_gain!(S::SeisData)
    # Remove low-gain seismic data channels
    i_low = findall([occursin(r".EL?", S.id[i]) for i=1:S.n])
    if !isempty(i_low)
        for k = length(i_low):-1:1
            @warn(join(["Low-gain, low-fs channel removed: ", S.id[i_low[k]]]))
            S -= S.id[i_low[k]]
        end
    end
    return nothing
end

# Test that data are time synched correctly within a SeisData structure
function sync_test!(S::SeisData)
    local L = [length(S.x[i])/S.fs[i] for i = 1:S.n]
    local t = [S.t[i][1,2] for i = 1:S.n]
    @test maximum(L) - minimum(L) ≤ maximum(2.0./S.fs)
    @test maximum(t) - minimum(t) ≤ maximum(2.0./S.fs)
    return nothing
end
