using Compat, Dates, DSP, Logging, Printf, SeisIO, SeisIO.Quake, SeisIO.RandSeis, Test
import Dates: DateTime, Hour, now
import DelimitedFiles: readdlm
import Random: rand, randperm, randstring
import SeisIO: BUF, FDSN_sta_xml,
  bad_chars, checkbuf!, checkbuf_8!, datafields, datareq_summ, endtime,
  fillx_i16_le!, fillx_i32_be!, fillx_i32_le!, findhex, get_HTTP_req,
  get_http_post, get_views, int2tstr, mean, minreq!,
  mktaper!, mktime, parse_charr, parse_chstr, parse_sl,
  safe_isdir, safe_isfile, sep, sμ, t_collapse,
  t_expand, t_win, taper_seg!, tnote, tstr2int, w_time, webhdr,
  xtmerge!, μs,
  diff_x!, int_x!,
  poly, polyval, polyfit
import SeisIO.RandSeis: getyp2codes, pop_rand_dict!
import SeisIO.Quake: unsafe_convert
import Statistics: mean

# ===========================================================================
# All constants needed by tests are here
const path = Base.source_dir()
const unicode_chars = String.(readdlm(path*"/SampleFiles/julia-unicode.csv", '\n')[:,1])
const n_unicode = length(unicode_chars)
const breaking_dict = Dict{String,Any}(
  "0" => rand(Char), "1" => randstring(rand(51:100)),
  "16" => rand(UInt8), "17" => rand(UInt16), "18" => rand(UInt32), "19" => rand(UInt64), "20" => rand(UInt128),
  "32" => rand(Int8), "33" => rand(Int16), "34" => rand(Int32), "35" => rand(Int64), "36" => rand(Int128),
  "48" => rand(Float16), "49" => rand(Float32), "50" => rand(Float64),
  "80" => rand(Complex{UInt8}), "81" => rand(Complex{UInt16}), "82" => rand(Complex{UInt32}), "83" => rand(Complex{UInt64}), "84" => rand(Complex{UInt128}),
  "96" => rand(Complex{Int8}), "97" => rand(Complex{Int16}), "98" => rand(Complex{Int32}), "99" => rand(Complex{Int64}), "100" => rand(Complex{Int128}),
  "112" => rand(Complex{Float16}), "113" => rand(Complex{Float32}), "114" => rand(Complex{Float64}),
  "128" => collect(rand(Char, rand(4:24))), "129" => [randstring(rand(4:24)) for i=1:rand(4:24)],
  "144" => collect(rand(UInt8, rand(4:24))), "145" => collect(rand(UInt16, rand(4:24))), "146" => collect(rand(UInt32, rand(4:24))), "147" => collect(rand(UInt64, rand(4:24))), "148" => collect(rand(UInt128, rand(4:24))),
  "160" => collect(rand(Int8, rand(4:24))), "161" => collect(rand(Int16, rand(4:24))), "162" => collect(rand(Int32, rand(4:24))), "163" => collect(rand(Int64, rand(4:24))), "164" => collect(rand(Int128, rand(4:24))),
  "176" => collect(rand(Float16, rand(4:24))), "177" => collect(rand(Float32, rand(4:24))), "178" => collect(rand(Float64, rand(4:24))), "208" => collect(rand(Complex{UInt8}, rand(4:24))),
  "209" => collect(rand(Complex{UInt16}, rand(4:24))), "210" => collect(rand(Complex{UInt32}, rand(4:24))), "211" => collect(rand(Complex{UInt64}, rand(4:24))), "212" => collect(rand(Complex{UInt128}, rand(4:24))),
  "224" => collect(rand(Complex{Int8}, rand(4:24))), "225" => collect(rand(Complex{Int16}, rand(4:24))), "226" => collect(rand(Complex{Int32}, rand(4:24))), "227" => collect(rand(Complex{Int64}, rand(4:24))), "228" => collect(rand(Complex{Int128}, rand(4:24))),
  "240" => collect(rand(Complex{Float16}, rand(4:24))), "241" => collect(rand(Complex{Float32}, rand(4:24))), "242" => collect(rand(Complex{Float64}, rand(4:24)))
  )
const NOOF = "
  HI ITS CLOVER LOL﻿
          ,-'-,  `---..
         /             \\
         =,             .
  ______<3.  ` ,+,     ,\\`
 ( \\  + `-”.` .; `     `.\\
 (_/   \\    | ((         ) \\
  |_ ;  \"    \\   (        ,’ |\\
  \\    ,- '💦 (,\\_____,’   / “\\
   \\__---+ }._)              |\\
   / _\\__💧”)/                  +
  ( /    💧” \\                  ++_
   \\)    ,“  |)                ++  ++
   💧     “💧  (                 *    +***
"
# ===========================================================================
# All functions used by tests are here
Lx(T::GphysData) = [length(T.x[i]) for i=1:T.n]
change_sep(S::Array{String,1}) = [replace(i, "/" => sep) for i in S]
test_fields_preserved(S1::GphysData, S2::GphysData, x::Int, y::Int) =
  @test(minimum([getfield(S1,f)[x]==getfield(S2,f)[y] for f in datafields]))
test_fields_preserved(S1::SeisChannel, S2::GphysData, y::Int) =
  @test(minimum([getfield(S1,f)==getfield(S2,f)[y] for f in datafields]))

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

function sizetest(S::GphysData, nt::Int)
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
  S.name = ["Channel 1", "Channel 2", "Channel 3", "Longmire", "September Lobe"]
  S.id = ["XX.TMP01.00.BHZ","XX.TMP01.00.BHN","XX.TMP01.00.BHE","CC.LON..BHZ","UW.SEP..EHZ"]
  S.fs = collect(Main.Base.Iterators.repeated(100.0, S.n))
  S.fs[4] = 20.0
  for i = 1:S.n
    os1 = round(Int64, 1/(S.fs[i]*μs))
    S.x[i] = randn(Int(L0*S.fs[i]))
    S.t[i] = [1 t1+os1; length(S.x[i]) 0]
  end

  T = SeisData(4)
  T.name = ["Channel 6", "Channel 7", "Longmire", "September Lobe"]
  T.id = ["XX.TMP02.00.EHZ","XX.TMP03.00.EHN","CC.LON..BHZ","UW.SEP..EHZ"]
  T.fs = collect(Main.Base.Iterators.repeated(100.0, T.n))
  T.fs[3] = 20.0
  for i = 1:T.n
    T.x[i] = randn(Int(L1*T.fs[i]))
    T.t[i] = [1 t2; length(T.x[i]) 0]
  end
  return (S,T)
end

function remove_low_gain!(S::GphysData)
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
function sync_test!(S::GphysData)
    local L = [length(S.x[i])/S.fs[i] for i = 1:S.n]
    local t = [S.t[i][1,2] for i = 1:S.n]
    @test maximum(L) - minimum(L) ≤ maximum(2.0./S.fs)
    @test maximum(t) - minimum(t) ≤ maximum(2.0./S.fs)
    return nothing
end

function breaking_seis()
  S = SeisData(randSeisData(), randSeisEvent(), randSeisData(2, c=1.0, s=0.0)[2])

  # Test a channel with every possible dict type
  S.misc[1] = breaking_dict

  # Test a channel with no notes
  S.notes[1] = []

  # Need a channel with a very long name to test in show.jl
  S.name[1] = "The quick brown fox jumped over the lazy dog"

  # Need a channel with a non-ASCII filename
  S.name[2] = "Moominpaskanäköinen"
  S.misc[2]["whoo"] = String[]        # ...and an empty String array in :misc
  S.misc[2]["♃♄♅♆♇"] = rand(3,4,5,6)  # ...and a 4d array in :misc

  #= Here we test true, full Unicode support;
    only 0xff can be a separator in S.notes[2] =#
  S.notes[2] = Array{String,1}(undef,6)
  S.notes[2][1] = String(Char.(0x00:0xfe))
  for i = 2:1:6
    uj = randperm(rand(1:n_unicode))
    S.notes[2][i] = join(unicode_chars[uj])
  end

  # Test short data, loc arrays
  S.loc[1] = GenLoc()
  S.loc[2] = GeoLoc()
  S.loc[3] = UTMLoc()
  S.loc[4] = XYLoc()

  # Responses
  S.resp[1] = GenResp()
  S.resp[2] = PZResp()

  S.x[4] = rand(Float64,4)
  S.t[4] = vcat(S.t[4][1:1,:], [4 0])

  # Some IDs that I can search for
  S.id[1] = "UW.VLL..EHZ"
  S.id[2] = "UW.VLM..EHZ"
  S.id[3] = "UW.TDH..EHZ"
  return S
end

function basic_checks(T::GphysData)
  # Basic checks
  for i = 1:T.n
    if T.fs[i] == 0.0
      @test size(T.t[i],1) == length(T.x[i])
    else
      @test T.t[i][end,1] == length(T.x[i])
    end
  end
  return nothing
end

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


function wait_on_data!(S::GphysData; tmax::Real=60.0)
  τ = 0.0
  t = 10.0
  printstyled(string("      (sleep up to ", tmax + t, " s)\n"), color=:green)
  redirect_stdout(out) do

    # Here we actually wait for data to arrive
    sleep(t)
    τ += t
    while isempty(S)
      if any(isopen.(S.c)) == false
        break
      end
      sleep(t)
      τ += t
      if τ > tmax
        show(S)
        break
      end
    end

    # Close the connection cleanly (write & close are redundant, but
    # write should close it instantly)
    for q = 1:length(S.c)
      if isopen(S.c[q])
        if q == 3
          show(S)
        end
        close(S.c[q])
      end
    end
    sleep(t)
  end

  # Synchronize (the reason we used d0,d1 in our test sessions)
  prune!(S)
  if !isempty(S)
    sync!(S, s="first")
  else
    @warn("No data. Is the server down?")
  end
  return nothing
end

function naive_filt!(C::SeisChannel;
  fl::Float64=1.0,
  fh::Float64=15.0,
  np::Int=4,
  rp::Int=10,
  rs::Int=30,
  rt::String="Bandpass",
  dm::String="Butterworth"
  )

  T = eltype(C.x)
  fe = 0.5 * C.fs
  low = T(fl / fe)
  high = T(fh / fe)

  # response type
  if rt == "Highpass"
    ff = Highpass(fh, fs=fs)
  elseif rt == "Lowpass"
    ff = Lowpass(fl, fs=fs)
  else
    ff = getfield(DSP.Filters, Symbol(rt))(fl, fh, fs=fs)
  end

  # design method
  if dm == "Elliptic"
    zp = Elliptic(np, rp, rs)
  elseif dm == "Chebyshev1"
    zp = Chebyshev1(np, rp)
  elseif dm == "Chebyshev2"
    zp = Chebyshev2(np, rs)
  else
    zp = Butterworth(np)
  end

  # polynomial ratio
  pr = convert(PolynomialRatio, digitalfilter(ff, zp))

  # zero-phase filter
  C.x[:] = filtfilt(pr, C.x)
  return nothing
end

function printcol(r::Float64)
  return r ≥ 1.00 ? 1 :
         r ≥ 0.75 ? 202 :
         r ≥ 0.50 ? 190 :
         r ≥ 0.25 ? 148 : 10
end

# ===========================================================================
# Redirect info, warnings, and errors to the logger
out = open("runtests.log", "a")
logger = SimpleLogger(out)
global_logger(logger)
@info("stdout redirect and logging")

# Set some keyword defaults
SeisIO.KW.comp = 0x00
