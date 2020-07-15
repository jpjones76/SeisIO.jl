const LEAD_IN_LENGTH = 0x1c
const DECIMATE_MASK = 0b00100000
const convertible_fields = (:id, :name, :loc, :fs, :gain, :resp, :units, :src, :notes, :misc)
const nodalfields = (:id, :loc, :fs, :gain, :misc, :name, :notes, :resp, :src, :units, :t)
const tdms_dtos = round(Int64, d2u(DateTime("1904-01-01T00:00:00")))
const tdms_codes = Dict{UInt32, Type}(
  0x00000000 => UInt8,
  0x00000001 => Int8,
  0x00000002 => Int16,
  0x00000003 => Int32,
  0x00000004 => Int64,
  0x00000005 => UInt8,
  0x00000006 => UInt16,
  0x00000007 => UInt32,
  0x00000008 => UInt64,
  0x00000009 => Float32,
  0x0000000a => Float64,
  0x00000020 => Char,
  0x00000021 => Bool,
  0x00000044 => UInt64,   # *** convert to date string
)
const unindexed_fields = (:n, :ox, :oy, :oz, :data, :info, :x)

const TDMS = TDMSbuf(
    zero(UInt32),
    zero(UInt64),
    zero(UInt64),
    zero(UInt32),
    zero(Int64),
    zero(Float64),
    zero(Float64),
    zero(Float64),
    zero(Float64),
    "",
    Dict{String, Any}()
    )
