# Define default values for keyword arguments.

#
# name  ::String                    = "new",
# id    ::String                    = "...YYY",
# loc   ::Array{Float64,1}          = zeros(Float64, 5),
# fs    ::Float64                   = zero(Float64),
# gain  ::Float64                   = one(Float64),
# resp  ::Array{Complex{Float64},2} = Array{Complex{Float64},2}(undef, 0, 2),
# units ::String                    = "",
# src   ::String                    = "",
# misc  ::Dict{String,Any}          = Dict{String,Any}(),
# notes ::Array{String,1}           = Array{String,1}(undef, 0),
# t     ::Array{Int64,2}            = Array{Int64,2}(undef, 0, 2),
# x     ::Array{Float64,1}          = Array{Float64,1}(undef, 0)

struct SLDefs
  safety::UInt8
  port::Int
  gap::Int
  kai::Int
  mode::String
  refresh::Real
  x_on_err::Bool
end

struct KWDefs
  SL::SLDefs
  evw::Array{Float64,1}
  fmt::String
  mag::Array{Float64,1}
  nev::Int
  opts::String
  pha::String
  q::Char
  reg::Array{Float64,1}
  si::Bool
  src::String
  to::Int
  v::Int
  w::Bool
  y::Bool
end

# mag|Array{Float64,1}|6.0, 9.9]|magitude range for earthquake searches
# reg|Array{Float64,1}|[-90.0, 90.0, -180.0,180.0, 30.0, 700.0]| search region
# nev|Int|1|number of events returned per earthquake search
# evw|Real|[600.0, 600.0]|search for events from `ot-t1` to `ot+t2`
# fmt|String|"miniseed"|request format
# opts|String|""|options string to pass to web requests
# pha|String|"P"|first phase in data request
# src|String|"IRIS"|data source; `?seis_www` for a list
# to|Int|30|read timeout (s) for web requests
# v|Int|0|verbosity: 0 = quiet, 1 = verbose, 2 = very verbose, 3 = debug
# si|Bool|false|autofill station info after web request?
# w|Bool|false|write requests directly to disk?
# y|Bool|false|sync after web requests?


"""
    SeisIO.KW

A custom structure containing default keyword argument values in SeisIO. Arguments
that accept keywords in SeisIO.KW use its default values.

### Keywords

| KW   | Default    | Allowed Data Types     | Meaning                        |
|------|:-----------|:-----------------------|:-------------------------------|
| evw  | [600.0,    | Array{Float64,1}       | search for events from `ot-t1` |
|      |  600.0]    |                        |   to `ot+t2`                   |
| fmt  | "miniseed" | String                 | request data format            |
| mag  | [6.0, 9.9] | Array{Float64,1}       | search magitude range          |
| nev  | 1          | Int                    | number of events per query     |
| opts | ""         | String                 | user-specified options         |
| q    | 'B'        | Char                   | data quality                   |
| pha  | "P"        | String                 | phases to get (comma-separated |
|      |            |                        |    list; use "ttall" for all)  |
| reg  | [-90.0,    | Array{Float64,1}       | geographic search region:      |
|      |   90.0,    |                        |    [min_lat, max_lat,          |
|      |  -180.0,   |                        |     min_lon, max_lon,          |
|      |   180.0,   |                        |     min_dep, max_dep]          |
|      |   -30.0,   |                        |    lat, lon in degrees (°)     |
|      |   660.0]   |                        |    dep in km with down = +     |
| si   | true       | Bool                   | autfill request station info?  |
| to   | 30         | Int                    | timeout (s) for web requests   |
| v    | 0          | Int                    | verbosity                      |
| w    | false      | Bool                   | write requests to disc?        |
| y    | false      | Bool                   | sync after web requests?       |


### Substructures

    SeisIO.KW.SL: Seedlink-specific keyword defaults. SeedLink also uses some
general keywords.

| Name        | Default | Type            | Description                       |
|:------------|:--------|:----------------|:----------------------------------|
| gap         | 3600    | Real            | max. gap since last packet [s]    |
| kai         | 600     | Real            | keepalive interval [s]            |
| mode        | "DATA"  | String          | TIME, DATA, or FETCH              |
| port        | 18000   | Integer         | port number                       |
| refresh     | 20      | Real            | base refresh interval [s]         |
| safety      | 0x00    | UInt8           | safety check level                |
| xonerr      | true    | Bool            | exit on error?                    |


"""
const KW = KWDefs(
           SLDefs( 0x00,    # safety::UInt8
                  18000,    # port::Int
                   3600,    # gap::Int
                    600,    # kai::Int
                 "DATA",    # mode::String
                     20,    # refresh::Real
                   true ),  # x_on_err::Bool
    Float64[600.0, 600.0],  # evw::Real
               "miniseed",  # fmt::String
        Float64[6.0, 9.9],  # mag::Array{Float64,1}
                        1,  # nev::Int
                        "", # opts::String
                       "P", # pha::String
                       'B', # q::Char (data quality)
     Float64[ -90.0, 90.0,  # reg::Array{Float64,1}
             -180.0,180.0,
              -30.0,700.0],
                      true, # si::Bool
                    "IRIS", # src::String
                        30, # to::Int
                         0, # v::Int (verbosity)
                     false, # w::Bool (write to disk)
                     false) # y::Bool (syc)
