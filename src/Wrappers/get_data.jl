export get_data!, get_data

@doc """
    get_data!(S, method, channels, KWs)

## Arguments
* `S`: SeisData structure
* `method`: String retrieval method
  + `"FDSN"`: FDSNWS dataselect
  + `"IRIS"`: IRISWS
* `channels`: channel selectors. (Union{String,Array{String,1},Array{String,2}})

Standard keywords: fmt, nd, opts, rad, reg, si, src, to, v, w, y

Other keywords:
* s: Start time
* t: Termination (end) time
* xml_file: Name of XML file to save station metadata

## Examples
1. `get_data!(S, "FDSN", "UW.SEP..EHZ,UW.SHW..EHZ,UW.HSR..EHZ", src="IRIS", t=(-600))`: using FDSNWS, get the last 10 minutes of data from three short-period vertical-component channels at Mt. St. Helens, USA.
2. `get_data!(S, "IRIS", "CC.PALM..EHN", t=(-120), f="sacbl")`: using IRISWS, fetch the last two minutes of data from component EHN, station PALM (Palmer Lift (Mt. Hood), OR, USA,), network CC (USGS Cascade Volcano Observatory, Vancouver, WA, USA), in bigendian SAC format, and merge into SeisData structure `S`.
3. `get_data!(S, "FDSN", "CC.TIMB..EHZ", t=(-600), w=true)`: using FDSNWS, get the last 10 minutes of data from channel EHZ, station TIMB (Timberline Lodge, OR, USA), save the data directly to disk, and add it to SeisData structure `S`.
4. `S = get_data("FDSN", "HV.MOKD..HHZ", s="2012-01-01T00:00:00", t=(-3600))`: using FDSNWS, fill a new SeisData structure `S` with an hour of data ending at 2012-01-01, 00:00:00 UTC, from HV.MOKD..HHZ (USGS Hawai'i Volcano Observatory).

See also: chanspec, parsetimewin, seis_www, SeisIO.KW
""" get_data!
function get_data!(S::SeisIO.SeisData, method_in::String, C="*"::Union{String,Array{String,1},Array{String,2}};
           fmt::String = KW.fmt                              ,  # File format
               nd::Int = KW.nd                               ,  # Number of days per request (in long requests)
          opts::String = KW.opts                             ,  # Options string
 rad::Array{Float64,1} = KW.rad                              ,  # Query radius
 reg::Array{Float64,1} = KW.reg                              ,  # Query region
                     s = 0::Union{Real,DateTime,String}      ,  # Start
              si::Bool = KW.si                               ,  # Fill station info?
           src::String = KW.src                              ,  # Data source
                     t = (-600)::Union{Real,DateTime,String} ,  # End or Length (s)
             to::Int64 = KW.to                               ,  # Timeout (s)
              v::Int64 = KW.v                                ,  # Verbosity
               w::Bool = KW.w                                ,  # Write to disc?
      xml_file::String = "FDSNsta.xml"                       ,  # XML save file
               y::Bool = KW.y                                   # Sync
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
    FDSNget!(S, C,
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
              xml_file=xml_file,
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
    IRISget!(S, R, α, ω, fmt = fmt, opts = opts, to = to, v = v, w = w)
  end

  # DND DND DND
  # Wrapper to a generic "get" function -- leave as example code
  # getfield(SeisIO, Symbol(string(method_in, "get!")))(S, C, α, ω,
  #          f = f, opts = opts, si = si, src = src, to = to, v = v, w = w)
  # DND DND DND

  # Sync
  if y == true
    sync!(S)
  end
  return nothing
end

@doc (@doc get_data)
function get_data(method_in::String, C="*"::Union{String,Array{String,1},Array{String,2}};
           fmt::String = KW.fmt                              ,  # File format
               nd::Int = KW.nd                               ,  # Number of days per request (in long requests)
          opts::String = KW.opts                             ,  # Options string
 rad::Array{Float64,1} = KW.rad                              ,  # Query radius
 reg::Array{Float64,1} = KW.reg                              ,  # Query region
                     s = 0::Union{Real,DateTime,String}      ,  # Start
              si::Bool = KW.si                               ,  # Fill station info?
           src::String = KW.src                              ,  # Data source
                     t = (-600)::Union{Real,DateTime,String} ,  # End or Length (s)
             to::Int64 = KW.to                               ,  # Timeout (s)
              v::Int64 = KW.v                                ,  # Verbosity
               w::Bool = KW.w                                ,  # Write to disc?
      xml_file::String = "FDSNsta.xml"                       ,  # XML save file
               y::Bool = KW.y                                   # Sync
     )

  S = SeisIO.SeisData()
  get_data!(S, method_in, C,
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
            xml_file=xml_file,
            y=y)
  v > 2 && println(stdout, "S = \n", S)
  return S
end
