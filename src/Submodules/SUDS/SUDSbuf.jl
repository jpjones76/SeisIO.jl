abstract type SUDSStruct end


# STATIONCOMP:  Generic station component information
mutable struct StationComp <: SUDSStruct
  az            ::Int16    # component azimuth, N°E
  inc           ::Int16    # component angle of incidence from vertical
  lat           ::Float64  # latitude, N = +
  lon           ::Float64  # longitude, E = +
  ele           ::Float32  # elevation in meters
  codes         ::Array{UInt8,1}
  # 1       d=dam, n=nuclear plant, v=vault, b=buried, s=surface, etc.
  # 2       annotated comment code
  # 3       type device data recorded on
  # 4       rock type: i=igneous, m=metamorphic, s=sedimentary
  # 5:6     code for type of rock
  # 7       p=permafrost, etc.
  # 8       sensor type: d=displacement, v=velocity, a=acceleration, t=time code
  # 9       data type: see suds_decode.jl
  # 10      data units: d=digital counts, v=mV, n=nanometers (nm/s or nm/s2
  # 11      polarity: n=normal, r=reversed
  # 12      status: d=dead, g=good
  gain          ::Array{Float32,1}  # 1   maximum gain of the amplifier
                                    # 2   abs val at which clipping begins
                                    # 3   conversion to millivolts: mV/count
  a2d           ::Array{Int16,1}    # 1   a2d channel number
                                    # 2   gain of analog-to-digital converter
  t_corr        ::Array{Float32,1}  # 1   clock correction in seconds
                                    # 2   seismological station delay

  StationComp() = new(zero(Int16),
                      zero(Int16),
                      zero(Float64),
                      zero(Float64),
                      zero(Float32),
                      zeros(UInt8, 12),
                      zeros(Float32, 3),
                      zeros(Int16, 2),
                      zeros(Float32, 2)
                      )
end

#=  DESCRIPTRACE:  Descriptive information about a seismic trace.
                   Normally followed by waveform data =#
mutable struct TraceHdr <: SUDSStruct
  net           ::UInt16
  n_ch          ::Int16
  desc          ::UInt8
  ns            ::Int32

  TraceHdr() = new( 0x0000,
                    zero(Int16),
                    0x00,
                    zero(Int32)
                    )
end

# FEATURE:  Observed phase arrival time, amplitude, and period
mutable struct SudsPhase <: SUDSStruct
  pc            ::UInt16
  onset         ::UInt8
  fm            ::UInt8
  snr           ::Int16
  gr            ::Int16
  amp           ::Float32

  SudsPhase() = new(0x0000,
                    0x00,
                    0x00,
                    zero(Int16),
                    zero(Int16),
                    0.0f0)
end

#  ORIGIN: Information about a specific solution for a given event
mutable struct SudsEvtHdr <: SUDSStruct
  evno        ::Int32
  auth        ::Int16
  chars       ::Array{UInt8,1}
  reg         ::Int32
  ot          ::Float64
  lat         ::Float64
  lon         ::Float64
  floats      ::Array{Float32,1}
  model       ::Array{UInt8, 1}
  gap         ::Int16
  d_min       ::Float32
  shorts      ::Array{Int16,1}
  mag         ::Array{Float32,1}

  SudsEvtHdr() = new( zero(Int32),
                      zero(Int16),
                      zeros(UInt8, 6),
                      zero(Int32),
                      zero(Float64),
                      zero(Float64),
                      zero(Float64),
                      zeros(Float32, 4),
                      zeros(UInt8, 6),
                      zero(Int16),
                      zero(Float32),
                      zeros(Int16, 8),
                      zeros(Float32, 3)
                      )

end

# CHANSET
mutable struct ChanSet <: SUDSStruct
  typ     ::Int16             # CHANSET
  n       ::Int16
  sta     ::Array{UInt8,1}
  tu      ::Int32
  td      ::Int32
  inst    ::Int32             # CHANSETENTRY
  stream  ::Int16
  chno    ::Int16

  ChanSet() = new(zero(Int16),
                  zero(Int16),
                  zeros(UInt8, 9),
                  zero(Int32),
                  zero(Int32),
                  zero(Int32),
                  zero(Int16),
                  zero(Int16))
end

mutable struct SUDSBuf
  # struct_tag
  sid::Int16
  nbs::Int32
  nbx::Int32
  nx::Int32
  nz::Int32

  # staident
  hdr       ::Array{UInt8,1}
  id        ::Array{UInt8,1}
  id_str    ::String

  # common variables in many structures
  data_type ::UInt8           # data type code
  sync_code ::UInt8           # sync code
  irig      ::Bool            # whether the time correction is to "IRIG"
  fs        ::Float32         # fs
  rc        ::Float32         # rc
  t_f64     ::Float64         # Begin time, phase time
  t_f32     ::Float32         # Pick time (τ)
  t_i32     ::Int32           # Effective time, time picked (!= pick time)
  t_i16     ::Int16           # Local time correction in minutes
  tc        ::Float64         # Time correction

  # Placeholders
  nx_new    ::Int64
  nx_add    ::Int64

  # too trivial for its own sub-buffer
  comm_i    ::Array{Int16,1}  # Numeric indices associated with comments
  comm_s    ::String

  # sub-buffers
  S05::StationComp
  T::TraceHdr
  P::SudsPhase
  H::SudsEvtHdr
  C::ChanSet

  function SUDSBuf()
    new(
          zero(Int16),        # sid
          zero(Int32),        # nbs
          zero(Int32),        # nbx
          zero(Int32),        # nx
          zero(Int32),        # nz

          zeros(UInt8, 12),   # hdr
          zeros(UInt8, 13),   # id
          "",                 # id_str

          0x00,               # data_type
          0x00,               # sync_code
          false,              # irig
          0.0f0,              # fs
          0.0f0,              # rc
          zero(Float64),      # t_f64
          zero(Float32),      # t_f32
          zero(Int32),        # t_i32
          zero(Int16),        # t_i16
          zero(Float64),      # tc

          KW.nx_new,          # nx_new
          KW.nx_add,          # nx_add

          zeros(Int16, 2),    # comm_i
          "",                 # comm_s

        # structural buffers                Code
        StationComp(),                      # 5
        TraceHdr(),                         # 6-7
        SudsPhase(),                        # 10
        SudsEvtHdr(),                       # 14
        ChanSet(),                          # 32--33

        )
  end
end

const SB = SUDSBuf()
