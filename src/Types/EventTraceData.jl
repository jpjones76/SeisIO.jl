export EventTraceData

@doc (@doc EventTraceData)
mutable struct EventTraceData <: GphysData
  n     ::Int64                         # number of channels
  az    ::Array{Float64,1}              # source azimuth
  baz   ::Array{Float64,1}              # backazimuth
  dist  ::Array{Float64,1}              # distance
  id    ::Array{String,1}               # id
  loc   ::Array{InstrumentPosition,1}   # loc
  fs    ::Array{Float64,1}              # fs
  gain  ::Array{Float64,1}              # gain
  misc  ::Array{Dict{String,Any},1}     # misc
  name  ::Array{String,1}               # name
  notes ::Array{Array{String,1},1}      # notes
  pha   ::Array{PhaseCat,1}             # phase catalog
  resp  ::Array{InstrumentResponse,1}   # resp
  src   ::Array{String,1}               # src
  t     ::Array{Array{Int64,2},1}       # time
  units ::Array{String,1}               # units
  x     ::Array{FloatArray,1}           # data

  function EventTraceData()
    return new( 0,                                        # n
                Array{Float64,1}(undef,0),                # az
                Array{Float64,1}(undef,0),                # baz
                Array{Float64,1}(undef,0),                # dist
                Array{String,1}(undef,0),                 # id
                Array{InstrumentPosition,1}(undef,0),     # loc
                Array{Float64,1}(undef,0),                # fs
                Array{Float64,1}(undef,0),                # gain
                Array{Dict{String,Any},1}(undef,0),       # misc
                Array{String,1}(undef,0),                 # name
                Array{Array{String,1},1}(undef,0),        # notes
                Array{PhaseCat,1}(undef,0),               # pha
                Array{InstrumentResponse,1}(undef,0),     # resp
                Array{String,1}(undef,0),                 # src
                Array{Array{Int64,2},1}(undef,0),         # time
                Array{String,1}(undef,0),                 # units
                Array{FloatArray,1}(undef,0)              # x
                )
  end

  function EventTraceData(n::UInt)
    TD = new( n,                                        # n
              Array{Float64,1}(undef,n),                # az
              Array{Float64,1}(undef,n),                # baz
              Array{Float64,1}(undef,n),                # dist
              Array{String,1}(undef,n),                 # id
              Array{InstrumentPosition,1}(undef,n),     # loc
              Array{Float64,1}(undef,n),                # fs
              Array{Float64,1}(undef,n),                # gain
              Array{Dict{String,Any},1}(undef,n),       # misc
              Array{String,1}(undef,n),                 # name
              Array{Array{String,1},1}(undef,n),        # notes
              Array{PhaseCat,1}(undef,n),               # pha
              Array{InstrumentResponse,1}(undef,n),     # resp
              Array{String,1}(undef,n),                 # src
              Array{Array{Int64,2},1}(undef,n),         # time
              Array{String,1}(undef,n),                 # units
              Array{FloatArray,1}(undef,n)              # x
            )

    # Fill these fields with something to prevent undefined reference errors
    fill!(TD.az, 0.0)                                        # az
    fill!(TD.baz, 0.0)                                       # baz
    fill!(TD.dist, 0.0)                                      # dist
    fill!(TD.fs, 0.0)                                        # fs
    fill!(TD.gain, 1.0)                                      # gain
    fill!(TD.id, "")                                         # id
    fill!(TD.name, "")                                       # name
    fill!(TD.src, "")                                        # src
    fill!(TD.units, "")                                      # units
    for i = 1:n
      TD.loc[i]    = GeoLoc()                                # loc
      TD.misc[i]   = Dict{String,Any}()                      # misc
      TD.notes[i]  = Array{String,1}(undef,0)                # notes
      TD.resp[i]   = PZResp()                                # resp
      TD.pha[i]    = PhaseCat()                              # pha
      TD.t[i]      = Array{Int64,2}(undef,0,2)               # t
      TD.x[i]      = Array{Float32,1}(undef,0)               # x
    end
    return TD
  end
  EventTraceData(n::Int) = n > 0 ? EventTraceData(UInt(n)) : EventTraceData()
end

function sizeof(TD::EventTraceData)
  s = sizeof(TD.c) + 8
  for f in tracefields
    V = getfield(TD, f)
    s += sizeof(V)
    for i = 1:TD.n
      v = getindex(V, i)
      s += sizeof(v)
      if f == :notes
        if !isempty(v)
          s += sum([sizeof(j) for j in v])
        end
      elseif f == :misc || f == :pha
        for i in values(v)
          s += sizeof(i)
        end
        s += sizeof(collect(keys(v)))
      end
    end
  end
  return s
end
