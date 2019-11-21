import SeisIO: fill_id!, checkbuf!, checkbuf_strict!, checkbuf_8!, fillx_i4!, fillx_i8!, fillx_i16_le!, fillx_i16_be!, fillx_i24_be!, fillx_i32_le!, fillx_i32_be!, fillx_u32_be!, fillx_u32_le!

  # fill_id!(id::Array{UInt8,1},
  # checkbuf!(buf::Array{UInt8,1},
  # checkbuf!(buf::AbstractArray,
  # checkbuf_strict!(buf::AbstractArray,
  # checkbuf_8!(buf::Array{UInt8,1},

nx = 4
buf = Array{UInt8, 1}(undef, 4nx)
xl = Array{Float32, 1}(undef, nx)
xb = similar(xl)
yl = rand(UInt32, 4)
yb = bswap.(yl)
buf .= reinterpret(UInt8, yl)
fillx_u32_le!(xl, buf, nx, 0)
fillx_u32_be!(xb, buf, nx, 0)
@test Float32.(yl) == xl
@test Float32.(yb) == xb

# Everything else is tested in readers
