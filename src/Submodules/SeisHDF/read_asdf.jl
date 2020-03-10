#= List of Variables

tr      trace dataset
wv      waveform dataset
sta     station dataset
idₛ     station id
idₜ     trace id
stas    list of station names
traces  list of trace names
trₛ     names of traces in sta

idⱼ     S[j] :id
iⱼ      S[j] first index in :x to write
jⱼ      S[j] last index in :x to write
lxⱼ     S[j] value of :t[end,1]
ntⱼ     S[j] number of times in :t[:,1]
nⱼ      S[j] length(:x)
tⱼ      S[j] :t

eᵣ      request window end time [ns from epoch]
nᵣ      request window length in samples
sᵣ      request window start time [ns from epoch]

eₜ      trace end time [ns from epoch]
fs      trace sampling frequency [Hz]
iₜ      trace first index to read
jₜ      trace last index to read
nₜ      trace total number of samples
sₜ      trace start time [ns from epoch]

nₒ      overlap window number of samples
sₒ      overlap window start time [ns from epoch]

j         index to channel in S
v         verbosity
Δ         sampling interval [ns]

because I managed to confuse even myself with the bookkeeping, and that's not
happened since coding SeisIO began
=#

function read_asdf!(  S::GphysData,
                      hdf::String,
                      id::String,
                      s::TimeSpec,
                      t::TimeSpec,
                      msr::Bool,
                      v::Integer  )

  SX = SeisData() # for XML
  idr = isa(id, String) ? id_to_regex(id) : id
  (v > 2) && println("Reading IDs that match ", idr)

  if typeof(s) == String && typeof(t) == String
    d0 = s
    d1 = t
    sᵣ = DateTime(s).instant.periods.value*1000 - dtconst
    eᵣ = DateTime(t).instant.periods.value*1000 - dtconst
  else
    (d0, d1) = parsetimewin(s, t)
    sᵣ = DateTime(d0).instant.periods.value*1000 - dtconst
    eᵣ = DateTime(d1).instant.periods.value*1000 - dtconst
  end
  sᵣ *= 1000
  eᵣ *= 1000
  Δ = 0
  fs = 0.0

  # this nesting is a mess
  netsta = netsta_to_regex(id)
  idr = id_to_regex(id)
  f = h5open(hdf, "r")
  wv = f["Waveforms"]
  stas = names(wv)
  sort!(stas)
  (v > 2) && println("Net.sta found: ", stas)

  for idₛ in stas
    if occursin(netsta, idₛ)
      sta = wv[idₛ]
      traces = names(sta)
      sort!(traces)
      (v > 2) && println("Traces found: ", traces)
      for idₜ in traces
        if idₜ == "StationXML"
          sxml = String(UInt8.(read(sta[idₜ])))
          read_station_xml!(SX, sxml, d0, d1, msr, v)
        elseif occursin(idr, idₜ)
          tr = sta[idₜ]
          nₜ = length(tr)
          sₜ = read(tr["starttime"])
          fs = read(tr["sampling_rate"])

          # convert fs to sampling interval in ns
          Δ = round(Int64, 1.0e9/fs)
          eₜ = sₜ + (nₜ-1)*Δ
          (v > 2) && println("sₜ = ", sₜ,"; eₜ = ", eₜ, "; sᵣ = ", sᵣ, "; eᵣ = ", eᵣ)

          if (sᵣ ≤ eₜ) && (eᵣ ≥ sₜ)
            lxⱼ = 0
            iₜ, jₜ, sₒ = get_trace_bounds(sᵣ, eᵣ, sₜ, eₜ, Δ, nₜ)
            nₒ = jₜ-iₜ+1
            idⱼ = String(split(idₜ, "_", limit=2, keepempty=true)[1])
            j = findid(idⱼ, S.id)
            (v > 2) && println("idⱼ = ", idⱼ, " (found at index in S = ", j, ")")
            nᵣ = div(eᵣ-sᵣ, Δ)+1
            if j == 0
              T = eltype(tr)
              push!(S, SeisChannel(id = idⱼ,
                                   fs = fs,
                                   x = Array{T,1}(undef, nᵣ)))
              j = S.n
              if has(tr, "event_id")
                S.misc[j]["event_id"] = read(tr["event_id"])
              end
            else
              tⱼ = getindex(getfield(S, :t), j)
              ntⱼ = div(lastindex(tⱼ), 2)
              nⱼ = lastindex(S.x[j])
              if ntⱼ > 0
                lxⱼ = getindex(tⱼ, ntⱼ)
                check_for_gap!(S, j, div(sₒ, 1000), nₒ, v)
              end
              if lxⱼ + nₒ > nⱼ
                resize!(S.x[j], lxⱼ + max(nₒ, nᵣ))
              end
              if S.fs[j] == 0.0
                S.fs[j] = fs
              end
            end

            if lxⱼ == 0
              tⱼ = mk_t(nₒ, div(sₒ, 1000))
              setindex!(getfield(S, :t), tⱼ, j)
            end

            iⱼ = lxⱼ+1
            jⱼ = iⱼ+nₒ-1
            load_data!(S.x[j], tr, iₜ:jₜ, iⱼ:jⱼ)
          end
          HDF5.h5d_close(tr)
        end
      end
      HDF5.h5g_close(sta)
    end
  end

  # merge in the XML that we read
  sxml_mergehdr!(S, SX, false, true, v)
  trunc_x!(S)

  # Done
  HDF5.h5g_close(wv)
  close(f)
  return S
end

function read_asdf(hdf::String, id::Union{String,Regex}, s::TimeSpec, t::TimeSpec, msr::Bool, v::Integer)
  S = SeisData()
  read_asdf!(S, hdf, id, s, t, msr, v)
  return S
end
