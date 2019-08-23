# trace data character codes
# /* s = 12 bit unsigned stored as short int, 0 to 4096, */
# /* q = 12 bit signed stored as short int, -2048 to 2048, */
# /* u = 16 bit unsigned stored as short int, 0 to 65536 */
# /* i = 16 bit signed stored as short int, -32767 to 32767, */
# /* 2 = 24 bit signed integer stored as long, */
# /* l = 32 bit signed integer stored as long, */
# /*  r = 12 bit data, 4 lsb time stored as short int, */
# /* f = float (32 bit IEEE real), */
# /* d = double (64 bit IEEE real), */
# /*  c = complex, */
# /* v = vector, */
# /* t = tensor */

function suds_decode(x::Array{UInt8,1}, code::UInt8)
  if code in (0x69, 0x71, 0x73, 0x75)   # 'i', 'q', 's', 'u'
    y = reinterpret(Int16, x)
    s = 2
  elseif code == 0x32 || code == 0x6c   # '2', 'l'
    y = reinterpret(Int32, x)
    s = 4
  elseif code == 0x63                   # 'c'
    y = reinterpret(Complex{Float32}, x)
    s = 8
  elseif code == 0x64                   # 'd'
    y = reinterpret(Float64, x)
    s = 8
  elseif code == 0x66                   # 'f'
    y = reinterpret(Float32, x)
    s = 4
  else
    error(string("no decoder for trace data code ", code, "!"))
  end

  return y,s
end
# No decoders for (and no idea what to do with)
# 0x72 # 'r',       would need a win32-style bits parser
# 0x74 # 't',       not a bits type, not defined in documentation
# 0x76 # 'v',       not a bits type, not defined in documentation
