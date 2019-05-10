# allowed values in misc: char, string, numbers, and arrays of same.
tos(t::Type) = round(Int64, log2(sizeof(t)))
function typ2code(t::Type)
  n = 0xff
  if t == Char
    n = 0x00
  elseif t == String
    n = 0x01
  elseif t <: Unsigned
    n = 0x10 + tos(t)
  elseif t <: Signed
    n = 0x20 + tos(t)
  elseif t <: AbstractFloat
    n = 0x30 + tos(t)-1
  elseif t <: Complex
    n = 0x40 + typ2code(real(t))
  elseif t <: Array
    n = 0x80 + typ2code(eltype(t))
  end
  return UInt8(n)
end
# Who needs "switch"...

findtype(c::UInt8, N::Array{Int64,1}) = findfirst(N.==2^c)
function code2typ(c::UInt8)
  t = Any::Type
  if c >= 0x80
    t = Array{code2typ(c-0x80)}
  elseif c >= 0x40
    t = Complex{code2typ(c-0x40)}
  elseif c >= 0x30
    T = Array{Type,1}([BigFloat, Float16, Float32, Float64])
    N = Int[24, 2, 4, 8]
    t = T[findtype(c-0x2f, N)]
  elseif c >= 0x20
    T = Array{Type,1}([Int128, Int16, Int32, Int64, Int8])
    N = Int[16, 2, 4, 8, 1]
    t = T[findtype(c-0x20, N)]
  elseif c >= 0x10
    T = Array{Type,1}([UInt128, UInt16, UInt32, UInt64, UInt8])
    N = Int[16, 2, 4, 8, 1]
    t = T[findtype(c-0x10, N)]
  elseif c == 0x01
    t = String
  else
    t = Char
  end
  return t
end
