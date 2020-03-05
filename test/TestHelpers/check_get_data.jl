# Uses "fallback" start and end times to deal with outages
function check_get_data!(S::SeisData, protocol::String, channels::Union{String, Array{String,1}};
       incr::DatePeriod        = Day(1)        , # Increment for failed reqs
max_retries::Integer           = 7             , # Maximum retries on fail
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

  has_data(S::SeisData) = (isempty(S) ? 0 : maximum([length(x) for x in S.x])) > 0
  warn_str(s::DateTime, α::DateTime, i::Integer, incr::DatePeriod; a::Bool=false) =
      string("S had no data ",
              a ? string("after ", i, " retries") : string("until retry #", i),
              " (", typeof(incr)(α-s), " before original request begin time)")
  s,t = parsetimewin(s,t)
  max_retries = max(max_retries, 3)
  s = DateTime(s)
  t = DateTime(t)
  α = deepcopy(s)
  i = 0
  while i ≤ max_retries
    i += 1
    try
      get_data!(S, protocol, channels,
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
    catch err
      @warn(string("Calling get_data threw error ", err))
    end
    if has_data(S)
      if i > 1
        str = warn_str(s, α, i-1, incr)
        printstyled("WARNING: ", str, ".\nCheck server; contact admins if problem persists.\n", color=:light_yellow)
        @warn(str)
      end
      return nothing
    end
    s -= incr
    t -= incr
    println("Retrying; start time decremented by ", incr)
  end
  str = warn_str(s, α, max_retries, incr, a=true)
  printstyled("WARNING: ", str, ".\nCheck ", protocol, " scripts and dependencies for new bugs!\n", color=:magenta, bold=true)
  @warn(str)
  return nothing
end

function check_get_data(protocol::String, channels::Union{String, Array{String,1}};
       incr::DatePeriod        = Day(1)        , # Increment for failed reqs
max_retries::Integer           = 7             , # Maximum retries on fail
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

  S = SeisData()
  check_get_data!(S, protocol, channels,
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
  return S
end
