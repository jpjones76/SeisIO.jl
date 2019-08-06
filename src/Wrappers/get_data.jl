export get_data!, get_data

@doc """
    S = get_data(method, channels, KWs)
    get_data!(S, method, channels, KWs)

## Arguments
* `method`: String retrieval method
  + `"FDSN"`: FDSNWS dataselect
  + `"IRIS"`: IRISWS
* `channels`: channel selectors. (Union{String,Array{String,1},Array{String,2}})
* `S`: SeisData structure

## Keywords
### Standard keywords
fmt, nd, opts, rad, reg, si, src, to, v, w, y

### Seismic Processing keywords
Certain keywords apply processing steps to seismic data channels (including
pressure sensors). The relevant keywords and order of operations is as follows:

1. unscale: divide gain from data after download?
2. demean: demean data after download?
3. detrend: detrend data after download?
4. taper: taper data after download?
6. ungap: remove gaps in data after download?
5. rr: remove seismic instrument response after download?

None of these keywords are mutually exclusive. Hey, it's your CPU time.

### Other keywords
* s: Start time
* t: Termination (end) time
* xf: Name of XML file to save station metadata

## Examples
1. `S = get_data("FDSN", "UW.SEP..EHZ,UW.SHW..EHZ,UW.HSR..EHZ", src="IRIS", t=(-600))`: using FDSNWS, get the last 10 minutes of data from three short-period vertical-component channels at Mt. St. Helens, USA.
2. `get_data!(S, "IRIS", "CC.PALM..EHN", t=(-120), f="sacbl")`: using IRISWS, fetch the last two minutes of data from component EHN, station PALM (Palmer Lift (Mt. Hood), OR, USA,), network CC (USGS Cascade Volcano Observatory, Vancouver, WA, USA), in bigendian SAC format, and merge into SeisData structure `S`.
3. `S = get_data("FDSN", "CC.TIMB..EHZ", t=(-600), w=true)`: using FDSNWS, get the last 10 minutes of data from channel EHZ, station TIMB (Timberline Lodge, OR, USA), and save the data directly to disk (in addition to returning data in a new SeisData structure S).
4. `S = get_data("FDSN", "HV.MOKD..HHZ", s="2012-01-01T00:00:00", t=(-3600))`: using FDSNWS, create a new SeisData structure `S` with an hour of data ending at 2012-01-01, 00:00:00 UTC, from HV.MOKD..HHZ (USGS Hawai'i Volcano Observatory).

See also: chanspec, parsetimewin, seis_www, SeisIO.KW
""" get_data
function get_data(method_in::String, C="*"::Union{String,Array{String,1},Array{String,2}};
          demean::Bool = false                               ,  # Demean data after download?
         detrend::Bool = false                               ,  # Detrend data after download?
           fmt::String = KW.fmt                              ,  # File format
              nd::Real = KW.nd                               ,  # Number of days per request (in long requests)
          opts::String = KW.opts                             ,  # Options string
 rad::Array{Float64,1} = KW.rad                              ,  # Query radius
 reg::Array{Float64,1} = KW.reg                              ,  # Query region
           prune::Bool = KW.prune                            ,  # Prune empty channels after query?
              rr::Bool = false                               ,  # Remove instrument response after download?
           s::TimeSpec = 0                                   ,  # Start
              si::Bool = KW.si                               ,  # Fill station info?
           src::String = KW.src                              ,  # Data source
           taper::Bool = false                               ,  # Taper data after download?
           t::TimeSpec = (-600)                              ,  # End or Length (s)
             to::Int64 = KW.to                               ,  # Timeout (s)
           ungap::Bool = true                                ,  # Remove data gaps?
         unscale::Bool = true                                ,  # Unscale (divide by :gain)?
              v::Int64 = KW.v                                ,  # Verbosity
               w::Bool = KW.w                                ,  # Write to disc?
            xf::String = "FDSNsta.xml"                       ,  # XML save file
               y::Bool = KW.y                                   # Sync
     )

  # Parse time window
  α, ω = parsetimewin(s, t)

  # Generate SeisData
  S = SeisData()

  # Condense requests as much as possible
  if method_in == "FDSN"
    if isa(C, String)
      C = parse_chstr(C, fdsn = true)
    elseif isa(C, Array{String,1})
      C = parse_charr(C, fdsn = true)
    end
    R = minreq(C)
    parse_err = FDSNget!(S, C,
                          fmt=fmt,
                          nd=nd,
                          opts=opts,
                          rad=rad,
                          reg=reg,
                          s=s,
                          si=si,
                          src=src,
                          t=t,
                          to=to,
                          v=v,
                          w=w,
                          xf=xf,
                          y=y)
  elseif method_in == "IRIS"
    if isa(C, String)
      R = String[strip(String(j)) for j in split(C, ',')]
    elseif isa(C, Array{String,2})
      NC = size(C,1)
      R = Array{String,1}(undef, NC)
      for j = 1:NC
        R[j] = join(C[j,:],'.')
      end
    else
      R = deepcopy(C)
    end
    parse_err = IRISget!(S, R, α, ω, fmt = fmt, opts = opts, to = to, v = v, w = w)
  end

  # DND DND DND
  # Wrapper to a generic "get" function -- leave as example code
  # getfield(SeisIO, Symbol(string(method_in, "get!")))(S, C, α, ω,
  #          f = f, opts = opts, si = si, src = src, to = to, v = v, w = w)
  # DND DND DND

  # ========================================================================
  # Viable operations for any data type
  if prune == true
    if parse_err == false
      v > 0 && @info(tnote("Removing empty channels."))
      prune!(S)
    else
      v > 0 && @info(tnote("Can't prune empty channels; web request wasn't fully parsed."))
    end
  end

  # Sync
  if y == true
    v > 0 && @info(tnote("Synchronizing data."))
    sync!(S)
  end

  # ========================================================================
  # Operations that only make sense for seismic or seismoacoustic data

  if any([demean, detrend, rr, taper, unscale])
    # Get list of channels with sane instrument codes
    CC = get_seis_channels(S)

    # Unscale
    if unscale == true
      v > 0 && @info(tnote("dividing out gain of seismic channels"))
      unscale!(S, chans=CC)
    end

    # Demean
    if demean == true
      v > 0 && @info(tnote("removing mean of seismic channels"))
      demean!(S, chans=CC)
    end

    # Detrend
    if detrend == true
      v > 0 && @info(tnote("detrending seismic channels"))
      detrend!(S, chans=CC)
    end

    # Taper
    if taper == true
      v > 0 && @info(tnote("tapering seismic channel data"))
      taper!(S, chans=CC)
    end

    # Ungap
    if ungap == true
      v > 0 && @info(tnote("ungapping seismic channel data"))
      ungap!(S, chans=CC)
    end

    # Remove response
    if rr == true
      v > 0 && @info(tnote("removing instrument response from seismic channels"))
      remove_resp!(S, chans=CC)
    end
  end

  return S
end

@doc (@doc get_data)
function get_data!(S::SeisData, method_in::String, C="*"::Union{String,Array{String,1},Array{String,2}};
          demean::Bool = false                               ,  # Demean data after download?
         detrend::Bool = false                               ,  # Detrend data after download?
           fmt::String = KW.fmt                              ,  # File format
              nd::Real = KW.nd                               ,  # Number of days per request (in long requests)
          opts::String = KW.opts                             ,  # Options string
 rad::Array{Float64,1} = KW.rad                              ,  # Query radius
 reg::Array{Float64,1} = KW.reg                              ,  # Query region
           prune::Bool = KW.prune                            ,  # Prune empty channels after query?
              rr::Bool = false                               ,  # Remove instrument response after download?
           s::TimeSpec = 0                                   ,  # Start
              si::Bool = KW.si                               ,  # Fill station info?
           src::String = KW.src                              ,  # Data source
           taper::Bool = false                               ,  # Taper data after download?
           t::TimeSpec = (-600)                              ,  # End or Length (s)
             to::Int64 = KW.to                               ,  # Timeout (s)
           ungap::Bool = true                                ,  # Remove data gaps?
         unscale::Bool = true                                ,  # Unscale (divide by :gain)?
              v::Int64 = KW.v                                ,  # Verbosity
               w::Bool = KW.w                                ,  # Write to disc?
            xf::String = "FDSNsta.xml"                       ,  # XML save file
               y::Bool = KW.y                                   # Sync
     )

  U = get_data(method_in, C,
                demean=demean,
                detrend=detrend,
                fmt=fmt,
                nd=nd,
                opts=opts,
                prune=prune,
                rad=rad,
                reg=reg,
                rr=rr,
                s=s,
                si=si,
                src=src,
                t=t,
                taper=taper,
                to=to,
                ungap=ungap,
                unscale=unscale,
                v=v,
                w=w,
                xf=xf,
                y=y)
  v > 2 && println(stdout, "S = \n", U)
  append!(S, U)
  return nothing
end
