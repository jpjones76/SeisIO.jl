# Define default values for keyword arguments.
mutable struct SLDefs
  port::Int64
  gap::Int64
  kai::Int64
  mode::String
  refresh::Real
  x_on_err::Bool
end

mutable struct FiltDefs
  fl::Float64
  fh::Float64
  np::Int64
  rp::Int64
  rs::Int64
  rt::String
  dm::String
end

mutable struct KWDefs
  SL::SLDefs
  Filt::FiltDefs
  evw::Array{Real,1}
  fmt::String
  full::Bool
  mag::Array{Float64,1}
  nd::Real
  nev::Int64
  nx_add::Int64
  nx_new::Int64
  opts::String
  pha::String
  prune::Bool
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

| KW       | Default    | Allowed Data Types | Meaning                        |
|----------|:-----------|:-------------------|:-------------------------------|
| evw      | [600,      | Array{Real,1}      | search for events in window    |
|          |  600]      |                    |   (ot-|t1|, ot+|t2|)           |
| fmt      | "miniseed" | String             | request data format            |
| full     | false      | Bool               | read full headers?             |
| mag      | [6.0, 9.9] | Array{Float64,1}   | search magitude range          |
| nd       | 1          | Real               | number of days per subrequest  |
| nev      | 1          | Int64              | number of events per query     |
| nx_add   | 360000     | Int64              | minimum length increase of an  |
|          |            |                    |    undersized data array       |
| nx_new   | 8640000    | Int64              | number of samples allocated    |
|          |            |                    |    for a new data channel      |
| opts     | ""         | String             | user-specified options[^1]     |
| pha      | "P"        | String             | phases to get (comma-separated |
|          |            |                    |    list; use "ttall" for all)  |
| prune    | true       | Bool               | call prune! after get_data?    |
| rad      | []         | Array{Float64,1}   | radius search: `[center_lat,`  |
|          |            |                    |    `center_lon, r_min, r_max]` |
|          |            |                    |    in decimal degrees (°)      |
| reg      | []         | Array{Float64,1}   | geographic search region:      |
|          |            |                    |    `[min_lat, max_lat,`        |
|          |            |                    |     `min_lon, max_lon,`        |
|          |            |                    |    `min_dep, max_dep]`         |
|          |            |                    |    lat, lon in degrees (°)     |
|          |            |                    |    dep in km with down = +     |
| si       | true       | Bool               | autofill request station info? |
| to       | 30         | Int64              | timeout (s) for web requests   |
| v        | 0          | Int64              | verbosity                      |
| w        | false      | Bool               | write requests to disc?        |
| y        | false      | Bool               | sync after web requests?       |


[^1]: Format as for an http request request URL, e.g. "szsrecs=true&repo=realtime" for FDSN (note: string should not begin with an ampersand).

### Substructures

    SeisIO.KW.SL: Seedlink-specific keyword defaults. SeedLink also uses some
general keywords.

| Name        | Default | Type            | Description                       |
|:------------|:--------|:----------------|:----------------------------------|
| gap         | 3600    | Real            | max. gap since last packet [s]    |
| kai         | 600     | Real            | keepalive interval [s]            |
| mode        | "DATA"  | String          | TIME, DATA, or FETCH              |
| port        | 18000   | Int64           | port number                       |
| refresh     | 20      | Real            | base refresh interval [s]         |
| xonerr      | true    | Bool            | exit on error?                    |

SeisIO.KW.Filt: Defaults parameters for time-series filtering.

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
                 "DATA",    # mode::String
                   20.0,    # refresh::Real
                   true ),  # x_on_err::Bool

           FiltDefs(1.0,    # fl::Float64
                   15.0,    # fh::Float64
                      4,    # np::Int64
                      8,    # rp::Int64
                     30,    # rs::Int64
             "Bandpass",    # rt::String
          "Butterworth" ),  # dm::String

               [600, 600],  # evw::Real
               "miniseed",  # fmt::String
                    false,  # full::Bool
        Float64[6.0, 9.9],  # mag::Array{Float64,1}
                        1,  # nd::Real
                        1,  # nev::Int64
                   360000,  # nx_add::Int64
                  8640000,  # nx_new::Int64
                        "", # opts::String
                       "P", # pha::String
                      true, # prune::Bool
                 Float64[], # rad: Array{Float64,1}
                 Float64[], # reg: Array{Float64,1}
                      true, # si::Bool
                    "IRIS", # src::String
                        30, # to::Int64
                         0, # v::Int (verbosity)
                     false, # w::Bool (write to disk)
                     false) # y::Bool (syc)
