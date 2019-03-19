export get_data!, get_data

# | KW | Default    | Allowed Data Types     | Meaning                        |
# |----|:-----------|:-----------------------|:-------------------------------|
# | fmt| "miniseed" | String                 | Request data format            |
# | opts  | ""         | String                 | User-specified options[^1]     |
# | q  | 'B'        | Char                   | Data quality flag              |
# | s  | 0          | Real, DateTime, String | Start time                     |
# | si | true       | Bool                   | Get station info. from FDSN?   |
# | t  | (-600)     | Real, DateTime, String | End time or length (s)[^2]     |
# | to | 30         | Int                    | Read timeout (s)               |
# | v  | 0          | Int                    | Verbosity                      |
# | w  | false      | Bool                   | Write directly to disc?        |
# | y  | false      | Bool                   | Sync?                          |
#
# [^1]: String is passed as-is, so format for the appropriate request type, e.g. "szsrecs=true&repo=realtime" for FDSN (note: string should not begin with an ampersand).
# [^2]: If one of `-s` or `-t` is 0, the data request begins (or ends) at the start of the minute in which the request is submitted.
#
"""
    get_data!(S::SeisData, method::String, channels, src::String; KWs)

## Arguments
* `method`: retrieval method.
  + `"FDSN"`: FDSNWS dataselect
  + `"IRIS"`: IRISWS
* `channels`: channels to retrieve.
* `src`: source identification string; type `?seis_www` for a list.

Standard keywords: fmt, opts, q, si, to, v, w, y

Other keywords:


## Examples
1. `get_data!(S, "FDSN", "UW.SEP..EHZ,UW.SHW..EHZ,UW.HSR..EHZ", src="IRIS", t=(-600))`: using FDSNWS, get the last 10 minutes of data from three short-period vertical-component channels at Mt. St. Helens, USA.
2. `get_data!(S, "IRIS", "CC.PALM..EHN", t=(-120), f="sacbl")`: using IRISWS, fetch the last two minutes of data from component EHN, station PALM (Palmer Lift (Mt. Hood), OR, USA,), network CC (USGS Cascade Volcano Observatory, Vancouver, WA, USA), in bigendian SAC format, and merge into SeisData structure `S`.
3. `get_data!(S, "FDSN", "CC.TIMB..EHZ", t=(-600), w=true)`: using FDSNWS, get the last 10 minutes of data from channel EHZ, station TIMB (Timberline Lodge, OR, USA), save the data directly to disk, and add it to SeisData structure `S`.
4. `S = get_data("FDSN", "HV.MOKD..HHZ", s="2012-01-01T00:00:00", t=(-3600))`: using FDSNWS, fill a new SeisData structure `S` with an hour of data ending at 2012-01-01, 00:00:00 UTC, from HV.MOKD..HHZ (USGS Hawai'i Volcano Observatory).

See also: chanspec, parsetimewin, seis_www
"""
function get_data!(S::SeisIO.SeisData, method_in::String, C::Union{String,Array{String,1},Array{String,2}};
      src::String = KW.src                              ,  # Data source
      fmt::String = KW.fmt                              ,  # File format
     opts::String = KW.opts                             ,  # Options string
          q::Char = KW.q                                ,  # Quality
         si::Bool = KW.si                               ,  # Fill station info?
        to::Int64 = KW.to                               ,  # Timeout (s)
         v::Int64 = KW.v                                ,  # Verbosity
          w::Bool = KW.w                                ,  # Write to disc?
          y::Bool = KW.y                                ,  # Sync
                s = 0::Union{Real,DateTime,String}      ,  # Start
                t = (-600)::Union{Real,DateTime,String}    # End or Length (s)
     )

  # Parse time window
  α, ω = parsetimewin(s, t)

  # Condense requests as much as possible
  if method_in == "FDSN"
    if isa(C, String)
      C = parse_chstr(C, fdsn = true)
    elseif isa(C, Array{String,1})
      C = parse_charr(C, fdsn = true)
    end
    R = minreq(C)
    FDSNget!(S, R, α, ω, fmt = fmt, opts = opts, q = q, si = si, src = src, to = to, v = v, w = w)
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
    IRISget!(S, R, α, ω, fmt = fmt, opts = opts, to = to, v = v, w = w)
  end

  # DND DND DND
  # Wrapper to a generic "get" function -- leave as example code
  # getfield(SeisIO, Symbol(string(method_in, "get!")))(S, C, α, ω,
  #          f = f, opts = opts, q = q, si = si, src = src, to = to, v = v, w = w)
  # DND DND DND

  # Sync
  if y == true
    sync!(S)
  end
  return nothing
end

"""
    S = get_data(method::String, channels, src::String; KWs)

See ?get_data!
"""
function get_data(method_in::String, C::Union{String,Array{String,1},Array{String,2}};
      src::String = KW.src                              ,  # Data source
      fmt::String = KW.fmt                              ,  # File format
     opts::String = KW.opts                             ,  # Options string
          q::Char = KW.q                                ,  # Quality
         si::Bool = KW.si                               ,  # Fill station info?
        to::Int64 = KW.to                               ,  # Timeout (s)
         v::Int64 = KW.v                                ,  # Verbosity
          w::Bool = KW.w                                ,  # Write to disc?
          y::Bool = KW.y                                ,  # Sync
                s = 0::Union{Real,DateTime,String}      ,  # Start
                t = (-600)::Union{Real,DateTime,String}    # End or Length (s)
     )

  S = SeisIO.SeisData()
  get_data!(S, method_in, C,
          src = src,
          fmt = fmt,
          opts = opts,
          q = q,
          s = s,
          si = si,
          t = t,
          to = to,
          v = v,
          w = w,
          y = y)
  v > 2 && println(stdout, S)
  return S
end
