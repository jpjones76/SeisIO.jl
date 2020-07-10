export get_data!, get_data

@doc """
    S = get_data(method, chans [, keywords])
    get_data!(S, method, chans [, keywords])

Wrapper to web requests for time-series data. Request data using `method` from channels `chans` using keywords `KWs`, storing the output in `S`.

* Methods: FDSN, IRIS, PH5
* Channels: See `?web_chanspec`
* Keywords: autoname, demean, detrend, fmt, msr, nd, opts, rad, reg, rr, s, si, src, t, taper, to, ungap, unscale, v, w, xf, y

This function is fully described in the official documentation at https://seisio.readthedocs.io/ under subheading **Web Requests**.

See also: `web_chanspec`, `parsetimewin`, `seis_www`, `SeisIO.KW`
""" get_data
function get_data(method_in::String, C::ChanOpts="*";
   autoname::Bool              = false         , # Auto-generate file names?
     demean::Bool              = false         , # Demean after download?
    detrend::Bool              = false         , # Detrend after download?
        fmt::String            = KW.fmt        , # File format
        msr::Bool              = false         , # Get multi-stage response?
         nd::Real              = KW.nd         , # Number of days per request
       opts::String            = KW.opts       , # Options string
        rad::Array{Float64, 1} = KW.rad        , # Query radius
        reg::Array{Float64, 1} = KW.reg        , # Query region
      prune::Bool              = KW.prune      , # Prune empty channels?
         rr::Bool              = false         , # Remove instrument response?
          s::TimeSpec          = 0             , # Start
         si::Bool              = KW.si         , # Fill station info?
        src::String            = KW.src        , # Data source
      taper::Bool              = false         , # Taper after download?
          t::TimeSpec          = (-600)        , # End or Length (s)
         to::Int64             = KW.to         , # Timeout (s)
      ungap::Bool              = false         , # Remove time gaps?
    unscale::Bool              = false         , # Unscale (divide by gain)?
          v::Integer           = KW.v          , # Verbosity
          w::Bool              = KW.w          , # Write to disc?
         xf::String            = "FDSNsta.xml" , # XML save file
          y::Bool              = KW.y          , # Sync
          )

  # Parse time window
  α, ω = parsetimewin(s, t)

  # KWs that ovewrite other KWs (rare; keep this behavior to an absolute minimum!)
  (autoname == true) && (w = true)

  # Generate SeisData
  S = SeisData()

  # Condense requests as much as possible
  if method_in == "FDSN"
    if isa(C, String)
      C = parse_chstr(C, ',', true, false)
    elseif isa(C, Array{String,1})
      C = parse_charr(C, '.', true)
    end
    R = minreq(C)
    parse_err = FDSNget!(S, R, α, ω,
      autoname, fmt, msr, nd, opts, rad, reg, si, src, to, v, w, xf, y)
  elseif method_in == "PH5"
    if isa(C, String)
      C = parse_chstr(C, ',', true, false)
    elseif isa(C, Array{String,1})
      C = parse_charr(C, '.', true)
    end
    R = minreq(C)
    parse_err = FDSNget!(S, R, α, ω,
      autoname, fmt, msr, nd, opts, rad, reg, si, src*"PH5", to, v, w, xf, y)
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
    parse_err = IRISget!(S, R, α, ω, fmt, opts, to, v, w)
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
function get_data!(S::SeisData, method_in::String, C::ChanOpts="*";
   autoname::Bool              = false         , # Auto-generate file names?
     demean::Bool              = false         , # Demean after download?
    detrend::Bool              = false         , # Detrend after download?
        fmt::String            = KW.fmt        , # File format
        msr::Bool              = false         , # Get multi-stage response?
         nd::Real              = KW.nd         , # Number of days per request
       opts::String            = KW.opts       , # Options string
        rad::Array{Float64, 1} = KW.rad        , # Query radius
        reg::Array{Float64, 1} = KW.reg        , # Query region
      prune::Bool              = KW.prune      , # Prune empty channels?
         rr::Bool              = false         , # Remove instrument response?
          s::TimeSpec          = 0             , # Start
         si::Bool              = KW.si         , # Fill station info?
        src::String            = KW.src        , # Data source
      taper::Bool              = false         , # Taper after download?
          t::TimeSpec          = (-600)        , # End or Length (s)
         to::Int64             = KW.to         , # Timeout (s)
      ungap::Bool              = false         , # Remove time gaps?
    unscale::Bool              = false         , # Unscale (divide by gain)?
          v::Integer           = KW.v          , # Verbosity
          w::Bool              = KW.w          , # Write to disc?
         xf::String            = "FDSNsta.xml" , # XML save file
          y::Bool              = KW.y          , # Sync
          )

  U = get_data(method_in, C,
               autoname=autoname,
                 demean=demean,
                detrend=detrend,
                    fmt=fmt,
                    msr=msr,
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
