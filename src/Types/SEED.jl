# SeedDef: default SEED values
mutable struct SeedDef
  nx::Int
  SeedDef() = new(360200)
end

# [201] Murdock Event Detection Blockette (60 bytes)
mutable struct Blk201
  sig::Array{Float32,1}
  flags::Array{UInt8, 1}
  t::Array{Int32,1}
  det::String
  Blk201() = new(zeros(Float32, 3), zeros(UInt8, 2), Array{Int32,1}(undef,7), "None")
end

#  [500] Timing Blockette (200 bytes)
mutable struct Blk500
  vco_correction::Float32
  t::Array{Int32,1}
  μsec::Int8
  reception_quality::Int8
  exception_count::UInt16
  exception_type::String
  clock_model::String
  clock_status::String
  Blk500() = new(0.0f0, Array{Int32,1}(undef,7), Int8(0), Int8(0), 0x0000, "", "", "")
end

# [2000] Variable Length Opaque Data Blockette
mutable struct Blk2000
  blk_length::UInt16
  odos::UInt16
  record_number::UInt32
  flags::Array{UInt8,1}
  header_fields::Array{String,1}
  opaque_data::Vector{UInt8}
  Blk2000() = new(0x0000, 0x0000, 0x00000000, zeros(UInt8, 3), String["a","b","c", "d", "e"], Array{UInt8,1}(undef,0))
end

mutable struct SeedVol
  fmt::UInt8    # 0x0a
  lx::UInt8     # 0x00
  nx::UInt16    # 0x1000
  wo::UInt8     # 0x01
  nsk::UInt16
  swap::Bool

  # hdr:
  hdr::Vector{UInt8}
  u16::Vector{UInt16}
  id::Array{UInt8,1}
  r::Array{Int16,1}

  # Computed quantities
  dt::Float64
  t::Array{Int32,1}
  xs::Bool
  k::Int

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

  # Steim
  steimvals::Array{UInt32,1}

  function SeedVol()
    id = Array{UInt8,1}(undef, 15)
    fill!(id, 0x20)
    id[[3,9,12]] .= 0x2e
    new(0x0a, 0x00, 0x1000, 0x01, 0x0000, false,    # fmt, lx, nx, wo, nsk, swap

        # header
        Array{UInt8,1}(undef,20),           # hdr::Vector{UInt8}
        Array{UInt16,1}(undef,5),           # u16::Vector{UInt16}
        id,                                 # id::Array{UInt8,1}
        Array{Int16,1}(undef, 2),           # r::Array{Int16,1}

        # computed
        0.0,                                # dt::Float64
        zeros(Int32,7),                     # t::Array{Int32,1}
        false,                              # xs::Bool
        0,                                  # k::Int

        # data-related
        Array{Float64, 1}(undef, 65535),    # x::Array{Float64,1}
        Array{UInt32, 1}(undef, 3),         # u::Array{UInt32, 1}
        zero(Float64),                      # x0::Float64
        zero(Float64),                      # xn::Float64
        Array{UInt8,1}(undef, 4),           # u8::Array{UInt8,1}

        # structure to hold SEED defaults
        SeedDef(),                          # def::SeedDef

        # blockette fields
        Blk201(),                           # B201:: Blk201
        Blk500(),                           # B500:: Blk500
        Blk2000(),                          # B2000:: Blk2000

        reverse(collect(0x00000000:0x00000002:0x0000001e), dims=1)    # steimvals::Array{UInt32,1}
        )
  end
end
