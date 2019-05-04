import SeisIO: BUF, fillx_i32_le!, fillx_i32_be!, checkbuf!
nx = 256
os = 3
buf = getfield(BUF, :buf)
x = getfield(BUF, :int32_buf)
checkbuf!(buf, 4*(os + nx))
checkbuf!(x, os + nx)

y = rand(Int32, nx)
copyto!(buf, 1, reinterpret(UInt8, y), 1, 4*nx)
fillx_i32_le!(x, buf, nx, os)
@test x[1+os:nx+os] == y

fillx_i32_be!(x, buf, nx, os)
@test x[1+os:nx+os] == bswap.(y)
