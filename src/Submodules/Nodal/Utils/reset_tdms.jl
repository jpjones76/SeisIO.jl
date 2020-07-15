function reset_tdms()
  TDMS.flags = zero(UInt32)
  TDMS.nsos = zero(UInt32)
  TDMS.rdos = zero(UInt64)
  TDMS.n_ch = zero(UInt32)
  TDMS.ts = zero(Int64)
  TDMS.fs = zero(Float64)
  TDMS.ox = zero(Float64)
  TDMS.oy = zero(Float64)
  TDMS.oz = zero(Float64)
  TDMS.name = ""
  TDMS.hdr = Dict{String, Any}()

  return nothing
end
