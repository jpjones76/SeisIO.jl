# SeedDef: default SEED values
mutable struct SeedDef
  nx::Int
  SeedDef() = new(360000)
end

# [201] Murdock Event Detection Blockette (60 bytes)
mutable struct Blk201
  sig::Array{Float32,1}
  flags::UInt8
  t::Array{Int32,1}
  det::String
  snr::Array{UInt8,1} # includes spots for lookback and pick algorithm
  Blk201() = new(zeros(Float32, 3), 0x00, Array{Int32,1}(undef,7), "None", zeros(UInt8,8))
end

#  [500] Timing Blockette (200 bytes)
mutable struct Blk500
  vco_correction::Float32
  t::Array{Int32,1}
  μsec::Int8
  reception_quality::Int8
  exception_count::UInt32
  exception_type::String
  clock_model::String
  clock_status::String
  Blk500() = new(0.0f0, Array{Int32,1}(undef,7), Int8(0), Int8(0), 0x0000, "", "", "")
end

# [2000] Variable Length Opaque Data Blockette
mutable struct Blk2000
  n::UInt32
  NB::UInt16
  os::UInt16
  flag::UInt8
  hdr::Array{UInt8,1}
  data::Array{UInt8,1}
  Blk2000() = new(
                  0x00000000,
                  0x0000,
                  0x0000,
                  0x00,
                  Array{UInt8,1}(undef,0),
                  Array{UInt8,1}(undef,0)
                  )
end

# Calibration blockettes: [300], [310], [320], [390]
mutable struct BlkCalib
  t::Array{Int32,1}
  n::UInt8
  flags::UInt8
  dur1::UInt32
  dur2::UInt32
  amplitude::Float32
  period::Float32
  channel::Array{UInt8,1}
  ref::UInt32
  coupling::Array{UInt8,1}
  rolloff::Array{UInt8,1}
  noise::Array{UInt8,1}
  BlkCalib() = new( Array{Int32,1}(undef,7),
                    0x00,
                    0x00,
                    0x00000000,
                    0x00000000,
                    zero(Float32),
                    zero(Float32),
                    Array{UInt8,1}(undef, 3),
                    0x00000000,
                    Array{UInt8,1}(undef, 12),
                    Array{UInt8,1}(undef, 12),
                    Array{UInt8,1}(undef, 8)
                  )
end

mutable struct SeedVol
  fmt::UInt8    # 0x0a
  lx::UInt8     # 0x00
  nx::UInt16    # 0x1000
  wo::UInt8     # 0x01
  nsk::UInt16   # [Number of bytes to skip after end of data record]
  tc::Int32     # Time correction
  swap::Bool
  parsable::Array{UInt16,1}
  calibs::Array{UInt16,1}

  # hdr:
  hdr::Vector{UInt8}
  u16::Vector{UInt16}   #  year, jdy, record start time, beginning of data, first blockette, position of next blockette from record begin
  id::Array{UInt8,1}
  r::Array{Int16,1}

  # Values read from file/stream
  dt::Float64
  t::Array{Int32,1}
  xs::Bool
  k::Int
  n::UInt16

  # Data-related
  x::Array{Float64,1}
  u::Array{UInt32, 1}
  x0::Float64
  xn::Float64
  u8::Array{UInt8,1}

  # Defaults
  def::SeedDef

  # Blockette containers
  B201::Blk201
  B500::Blk500
  B2000::Blk2000
  Calib::BlkCalib

  # Steim
  steimvals::Array{UInt32,1}

  # Dictionary for decoders
  dec::Dict{UInt8,String}

  function SeedVol()
    id = Array{UInt8,1}(undef, 15)
    fill!(id, 0x20)
    id[[3,9,12]] .= 0x2e
    new(0x0a,                               # fmt
        0x00,                               # lx
        0x1000,                             # nx
        0x01,                               # wo
        0x0000,                             # nsk
        zero(Int32),                        # tc
        false,                              # swap

        # blockettes with parsers
        UInt16[0x0064, 0x00c9, 0x01f4, 0x018b, 0x03e8, 0x03e9, 0x07d0],
        # calibiration blockettes (all use the same parser)
        UInt16[0x012c, 0x0136, 0x0140, 0x0186],

        # header
        Array{UInt8,1}(undef,20),           # hdr::Vector{UInt8}
        Array{UInt16,1}(undef,6),           # u16::Vector{UInt16}
        id,                                 # id::Array{UInt8,1}
        Array{Int16,1}(undef, 2),           # r::Array{Int16,1}

        # computed
        0.0,                                # dt::Float64
        zeros(Int32,7),                     # t::Array{Int32,1}
        false,                              # xs::Bool
        0,                                  # k::Int
        0x0000,                             # n::UInt16

        # data-related
        Array{Float64, 1}(undef, 65535),    # x::Array{Float64,1}
        Array{UInt32, 1}(undef, 3),         # u::Array{UInt32, 1}
        zero(Float64),                      # x0::Float64
        zero(Float64),                      # xn::Float64
        Array{UInt8,1}(undef, 4),           # u8::Array{UInt8,1}

        # structure to hold SEED defaults
        SeedDef(),                          # def::SeedDef

        # blockette fields
        Blk201(),                           # Blk201:: Blk201
        Blk500(),                           # Blk500:: Blk500
        Blk2000(),                          # Blk2000:: Blk2000
        BlkCalib(),                         # Calib:: BlkCalib

        # steimvals::Array{UInt32,1}
        reverse(collect(0x00000000:0x00000002:0x0000001e), dims=1),

        Dict{UInt8,String}( 0x00 => "Char",
                            0x01 => "Unenc",
                            0x02 => "Int24",
                            0x03 => "Unenc",
                            0x04 => "Unenc",
                            0x05 => "Unenc",
                            0x0a => "Steim",
                            0x0b => "Steim",
                            0x0d => "Geoscope",
                            0x0e => "Geoscope",
                            0x10 => "CDSN",
                            0x1e => "SRO",
                            0x20 => "DWWSSN" )
        )
  end
end
