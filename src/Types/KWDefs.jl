# Define default values for keyword arguments.
struct SLDefs
  port::Int64
  gap::Int64
  kai::Int64
  mode::String
  refresh::Real
  x_on_err::Bool
end

struct KWDefs
  SL::SLDefs
  evw::Array{Float64,1}
  fmt::String
  mag::Array{Float64,1}
  nd::Int64
  nev::Int64
  opts::String
  pha::String
  rad::Array{Float64,1}
  reg::Array{Float64,1}
  si::Bool
  src::String
  to::Int64
  v::Int64
  w::Bool
  y::Bool
end

"""
    SeisIO.KW

An immutable structure containing default keyword argument values in SeisIO.
Arguments that accept keywords in SeisIO.KW use the default values when a
keyword isn't specified.

### Keywords

| KW   | Default    | Allowed Data Types     | Meaning                        |
|------|:-----------|:-----------------------|:-------------------------------|
| evw  | [600.0,    | Array{Float64,1}       | search for events from `ot-t1` |
|      |  600.0]    |                        |   to `ot+t2`                   |
| fmt  | "miniseed" | String                 | request data format            |
| mag  | [6.0, 9.9] | Array{Float64,1}       | search magitude range          |
| nd   | 1          | Int64                  | number of days per subrequest  |
| nev  | 1          | Int                    | number of events per query     |
| opts | ""         | String                 | user-specified options[^1]     |
| pha  | "P"        | String                 | phases to get (comma-separated |
|      |            |                        |    list; use "ttall" for all)  |
| rad  | []         | Array{Float64,1}       | radius search: `[center_lat,`  |
|      |            |                        |    `center_lon, r_min, r_max]` |
|      |            |                        |    in decimal degrees (°)      |
| reg  | []         | Array{Float64,1}       | geographic search region:      |
|      |            |                        |    `[min_lat, max_lat,`        |
|      |            |                        |     `min_lon, max_lon,`        |
|      |            |                        |    `min_dep, max_dep]`         |
|      |            |                        |    lat, lon in degrees (°)     |
|      |            |                        |    dep in km with down = +     |
| si   | true       | Bool                   | autofill request station info? |
| to   | 30         | Int                    | timeout (s) for web requests   |
| v    | 0          | Int                    | verbosity                      |
| w    | false      | Bool                   | write requests to disc?        |
| y    | false      | Bool                   | sync after web requests?       |

[^1]: Format as for an http request request URL, e.g. "szsrecs=true&repo=realtime" for FDSN (note: string should not begin with an ampersand).

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
| xonerr      | true    | Bool            | exit on error?                    |

"""
const KW = KWDefs(
           SLDefs(18000,    # port::Int
                   3600,    # gap::Int
                    600,    # kai::Int
                 "DATA",    # mode::String
                   20.0,    # refresh::Real
                   true ),  # x_on_err::Bool
    Float64[600.0, 600.0],  # evw::Real
               "miniseed",  # fmt::String
        Float64[6.0, 9.9],  # mag::Array{Float64,1}
                        1,  # nd::Int
                        1,  # nev::Int
                        "", # opts::String
                       "P", # pha::String
                 Float64[], # rad: Array{}
                 Float64[], # reg: Array{}
                      true, # si::Bool
                    "IRIS", # src::String
                        30, # to::Int
                         0, # v::Int (verbosity)
                     false, # w::Bool (write to disk)
                     false) # y::Bool (syc)
