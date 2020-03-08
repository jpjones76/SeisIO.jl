# Define default values for keyword arguments.
mutable struct SLDefs
  port::Int64
  gap::Int64
  kai::Int64
  refresh::Real
  seq::String
  u::String
  x_on_err::Bool

  SLDefs( port::Int64,
          gap::Int64,
          kai::Int64,
          refresh::Real,
          seq::String,
          u::String,
          x_on_err::Bool
          ) = new(port, gap, kai, refresh, seq, u, x_on_err)
end

mutable struct FiltDefs
  fl::Float64
  fh::Float64
  np::Int64
  rp::Int64
  rs::Int64
  rt::String
  dm::String

  FiltDefs( fl::Float64,
            fh::Float64,
            np::Int64,
            rp::Int64,
            rs::Int64,
            rt::String,
            dm::String) = new(fl, fh, np, rp, rs, rt, dm)
end

mutable struct KWDefs
  SL::SLDefs
  Filt::FiltDefs
  comp::UInt8
  fmt::String
  full::Bool
  nd::Real
  n_zip::Int64
  nx_add::Int64
  nx_new::Int64
  opts::String
  prune::Bool
  rad::Array{Float64,1}
  reg::Array{Float64,1}
  si::Bool
  src::String
  to::Int64
  v::Integer
  w::Bool
  y::Bool
end

"""
    SeisIO.KW

A mutable structure containing default keyword argument values in SeisIO.
Arguments that accept keywords in SeisIO.KW use the default values when a
keyword isn't specified.

### Keywords

| KW       | Default    | Allowed Data Types | Meaning                        |
|----------|:-----------|:-------------------|:-------------------------------|
| comp     | 0x00       | UInt8              | compress data on write?[^1]    |
| fmt      | "miniseed" | String             | request data format            |
| full     | false      | Bool               | read full headers?             |
| n_zip    | 100000     | Int64              | compress if length(x) > n_zip  |
| nd       | 1          | Real               | number of days per subrequest  |
| nx_add   | 360000     | Int64              | minimum length increase of an  |
|          |            |                    |  undersized data array         |
| nx_new   | 8640000    | Int64              | number of samples allocated    |
|          |            |                    |   for a new data channel       |
| opts     | ""         | String             | user-specified options[^2]     |
| prune    | true       | Bool               | call prune! after get_data?    |
| rad      | []         | Array{Float64,1}   | radius search: `[center_lat,`  |
|          |            |                    |   `center_lon, r_min, r_max]`  |
|          |            |                    |   in decimal degrees (°)       |
| reg      | []         | Array{Float64,1}   | geographic search region:      |
|          |            |                    |   `[min_lat, max_lat,`         |
|          |            |                    |    `min_lon, max_lon,`         |
|          |            |                    |   `min_dep, max_dep]`          |
|          |            |                    |   lat, lon in degrees (°)      |
|          |            |                    |   dep in km with down = +      |
| si       | true       | Bool               | autofill request station info? |
| src      | "IRIS"     | String             | data source; `?seis_www` lists |
| to       | 30         | Int64              | timeout (s) for web requests   |
| v        | 0          | Integer            | verbosity                      |
| w        | false      | Bool               | write requests to disk?        |
| y        | false      | Bool               | sync after web requests?       |

[^1]: If `comp == 0x00`, never compress data; if `comp == 0x01`, only compress channel `i` if `length(S.x[i]) > KW.n_zip`; if `comp == 0x02`, always compress data.
[^2]: Format like an http request string, e.g. "szsrecs=true&repo=realtime" for FDSN. String shouldn't begin with an ampersand.

### SeisIO.KW.SL
Seedlink-specific keyword default values. SeedLink also uses some general keywords.

| Name    | Default | Type    | Description                                 |
|:--------|:--------|:--------|:----------------------------------          |
| gap     | 3600    | Real    | allowed time since last packet [s] [^1]     |
| kai     | 600     | Real    | keepalive interval [s]                      |
| port    | 18000   | Int64   | port number                                 |
| refresh | 20      | Real    | base refresh interval [s]                   |
| seq     | ""      | String  | starting sequence no. (hex), e.g., "5BE37A" |
| u       | (iris)  | String  | Default URL ("rtserve.iris.washington.edu") |
| xonerr  | true    | Bool    | exit on error?                              |

[^1]: A channel is considered non-transmitting (hence, excluded from the SeedLink session) if the time since last packet exceeds `gap` seconds.

### SeisIO.KW.Filt
Default keyword values for time-series filtering.

| Name  | Default       | Type    | Description                         |
|:------|:--------------|:--------|:------------------------------------|
| fl    | 1.0           | Float64 | lower corner frequency [Hz] [^1]    |
| fh    | 15.0          | Float64 | upper corner frequency [Hz] [^1]    |
| np    | 4             | Int64   | number of poles                     |
| rp    | 8             | Int64   | pass-band ripple (dB)               |
| rs    | 30            | Int64   | stop-band ripple (dB)               |
| rt    | "Bandpass"    | String  | response type (type of filter)      |
| dm    | "Butterworth" | String  | design mode (name of filter)        |

[^1]: Remember the (counter-intuitive) convention that the lower corner frequency (fl) is used in a Highpass filter, and fh is used in a Lowpass filter. This convention is preserved in SeisIO.

"""
const KW = KWDefs(
                  SLDefs(18000,    # port::Int64
                          3600,    # gap::Int64
                           600,    # kai::Int64
                          20.0,    # refresh::Real
                            "",    # seq::String
 "rtserve.iris.washington.edu",    # u::String
                          true ),  # x_on_err::Bool

                  FiltDefs(1.0,    # fl::Float64
                          15.0,    # fh::Float64
                             4,    # np::Int64
                             8,    # rp::Int64
                            30,    # rs::Int64
                    "Bandpass",    # rt::String
                 "Butterworth" ),  # dm::String

                            0x00,  # comp::Bool
                      "miniseed",  # fmt::String
                           false,  # full::Bool
                               1,  # nd::Real
                          100000,  # n_zip::Int64
                          360000,  # nx_add::Int64
                         8640000,  # nx_new::Int64
                              "",  # opts::String
                            true,  # prune::Bool
                       Float64[],  # rad: Array{Float64,1}
                       Float64[],  # reg: Array{Float64,1}
                            true,  # si::Bool
                          "IRIS",  # src::String
                              30,  # to::Int64
                               0,  # v::Integer (verbosity)
                           false,  # w::Bool (write to disk)
                           false)  # y::Bool (syc)
