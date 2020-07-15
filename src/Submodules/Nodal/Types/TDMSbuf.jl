mutable struct TDMSbuf
  flags::UInt32
  nsos::UInt64
  rdos::UInt64
  n_ch::UInt32
  ts::Int64
  fs::Float64
  ox::Float64
  oy::Float64
  oz::Float64
  name::String
  hdr::Dict{String, Any}

  TDMSbuf(
        flags::UInt32,
        nsos::UInt64,
        rdos::UInt64,
        n_ch::UInt32,
        ts::Int64,
        fs::Float64,
        ox::Float64,
        oy::Float64,
        oz::Float64,
        name::String,
        hdr::Dict{String, Any}
      ) = new(flags, nsos, rdos, n_ch, ts, fs, ox, oy, oz, name, hdr)
end
