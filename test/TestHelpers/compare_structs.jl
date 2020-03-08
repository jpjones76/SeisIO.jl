function compare_SeisHdr(H1::SeisHdr, H2::SeisHdr)
  for f in fieldnames(EQLoc)
    if typeof(getfield(H1.loc, f)) <: Union{AbstractFloat, Int64}
      (f == :rms) && continue
      @test isapprox(getfield(H1.loc, f), getfield(H2.loc,f))
    end
  end
  @test getfield(H1.loc, :typ) == getfield(H2.loc, :typ)
  @test getfield(H1.loc, :src) == getfield(H2.loc, :src)
  @test H1.mag.val ≈ H2.mag.val
  @test H1.mag.gap ≈ H2.mag.gap
  @test H1.mag.src == H2.mag.src
  @test H1.mag.scale == H2.mag.scale
  @test H1.mag.nst == H2.mag.nst
  @test H1.id == H2.id
  @test H1.ot == H2.ot
  # :src isn't tested; in tests, :src changes depending on file/web origin
  @test H1.typ == H2.typ
  return nothing
end

function compare_SeisSrc(R1::SeisSrc, R2::SeisSrc)
  @test R1.id == R2.id
  @test R1.eid == R2.eid
  @test R1.m0 ≈ R2.m0
  @test R1.mt ≈ R2.mt
  @test R1.dm ≈ R2.dm
  @test R1.gap ≈ R2.gap
  @test R1.pax ≈ R2.pax
  @test R1.planes ≈ R2.planes
  # :src isn't tested; in tests, :src changes depending on file/web origin
  @test R1.st.desc == R2.st.desc
  @test R1.st.dur ≈ R2.st.dur
  @test R1.st.rise ≈ R2.st.rise
  @test R1.st.decay ≈ R2.st.decay
  return nothing
end

function compare_SeisData(S1::SeisData, S2::SeisData)
  sort!(S1)
  sort!(S2)
  @test S1.id == S2.id
  @test S1.name == S2.name
  @test S1.units == S2.units
  @test isapprox(S1.fs, S2.fs)
  @test isapprox(S1.gain, S2.gain)
  for i in 1:S1.n
    L1 = S1.loc[i]
    L2 = S2.loc[i]
    @test isapprox(L1.lat, L2.lat)
    @test isapprox(L1.lon, L2.lon)
    @test isapprox(L1.el, L2.el)
    @test isapprox(L1.dep, L2.dep)
    @test isapprox(L1.az, L2.az)
    @test isapprox(L1.inc, L2.inc)

    R1 = S1.resp[i]
    R2 = S2.resp[i]
    for f in fieldnames(PZResp)
      @test isapprox(getfield(R1, f), getfield(R2,f))
    end

    #=
      Changed 2020-03-05

      was:
      @test S1.t[i] == S2.t[i]
      @test isapprox(S1.x[i],S2.x[i])

      reason:
      :t, :x require more sophisticated testing because :t isn't a unique
        representation of sample times.

      in rare cases, writing and rereading :t, :x can yield a different time
        matrix with the same data at the same sample times.
    =#
    t1 = t_expand(S1.t[i], S1.fs[i])
    t2 = t_expand(S2.t[i], S2.fs[i])
    ii = sortperm(t1)
    jj = sortperm(t2)
    @test isapprox(t1[ii], t2[jj])
    @test isapprox(S1.x[i][ii], S2.x[i][jj])
  end
  return nothing
end

function compare_events(Ev1::SeisEvent, Ev2::SeisEvent)
  compare_SeisHdr(Ev1.hdr, Ev2.hdr)
  compare_SeisSrc(Ev1.source, Ev2.source)
  S1 = convert(SeisData, Ev1.data)
  S2 = convert(SeisData, Ev2.data)
  compare_SeisData(S1, S2)
  return nothing
end

function rse_wb(n::Int64)
  Ev = randSeisEvent(n, s=1.0)

  Ev.source.misc = Dict{String,Any}(
  "pax_desc"    => "azimuth, plunge, length",
  "mt_id"       => "smi:SeisIO/moment_tensor;fmid="*Ev.source.id,
  "planes_desc" => "strike, dip, rake")
  Ev.source.eid = Ev.hdr.id
  Ev.source.npol = 0
  Ev.source.notes = String[]
  note!(Ev.source, "+origin ¦ " * Ev.source.src)

  Ev.hdr.int = (0x00, "")
  Ev.hdr.loc.datum = ""
  Ev.hdr.loc.typ = ""
  Ev.hdr.loc.rms = 0.0
  flags = bitstring(Ev.hdr.loc.flags)
  if flags[1] == '1' || flags[2] == '1'
    flags = "11" * flags[3:8]
    Ev.hdr.loc.flags = parse(UInt8, flags, base=2)
  end

  Ev.hdr.mag.src = Ev.hdr.loc.src * ","
  Ev.hdr.notes = String[]
  note!(Ev.hdr, "+origin ¦ " * Ev.hdr.src)
  Ev.hdr.misc = Dict{String,Any}()

  for j in 1:Ev.data.n
    Ev.data.misc[j] = Dict{String,Any}()
    Ev.data.notes[j] = String[]
    Ev.data.loc[j] = GeoLoc(
      lat = (rand(0.0:1.0:89.0) + rand())*-1.0^rand(1:2),
      lon = (rand(0.0:1.0:179.0) + rand())*-1.0^rand(1:2),
      el = rand()*1000.0,
      dep = rand()*1000.0,
      az = (rand()-0.5)*180.0,
      inc = rand()*90.0
      )
      if j == 1
        Ev.data.t[j] = breaking_tstruct(Ev.data.t[j][1,2],
                                        length(Ev.data.x[j]),
                                        Ev.data.fs[j])
      end
  end
  return Ev
end
