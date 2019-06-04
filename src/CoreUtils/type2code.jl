# allowed values in misc: char, string, numbers, and arrays of same.
tos(t::Type) = round(UInt8, log2(sizeof(t)))
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
    n = 0x30 + tos(t) - 0x01
  elseif t <: Complex
    n = 0x40 + typ2code(real(t))
  elseif t <: Array
    n = 0x80 + typ2code(eltype(t))
  end
  return n
end
# Who needs "switch"...

function code2typ(c::UInt8)
  t::Type = Any
  if c >= 0x80
    t = Array{code2typ(c-0x80)}
  elseif c >= 0x40
    t = Complex{code2typ(c-0x40)}
  elseif c >= 0x30
    t = getindex((Float16, Float32, Float64), c-0x2f)
  elseif c >= 0x20
    t = getindex((Int8, Int16, Int32, Int64, Int128), c-0x1f)
  elseif c >= 0x10
    t = getindex((UInt8, UInt16, UInt32, UInt64, UInt128), c-0x0f)
  elseif c == 0x01
    t = String
  elseif c == 0x00
    t = Char
  else
    error("unknown type!")
  end
  return t
end

# SUPPORTED TYPES IN :MISC
#
#= HOW TO CHECK:
(1) copy the two lines below to the command line to generate a table like the one below
(2) if anything in column 4 of your table is false, these functions are broken

using SeisIO, SeisIO.RandSeis, BenchmarkTools, LightXML; import SeisIO:code2typ, typ2code;
for c = 0x00:0xff; try; println(stdout, rpad(string(code2typ(c)), 36), "| ", repr(typ2code(code2typ(c)))," | ", repr(c), " | ", isequal(c, typ2code(code2typ(c)))); catch; end; end

GUIDE TO THE TABLE:
Column 1 is a list of types allowed in :misc
Column 2 is the corresponding UInt8 type codes
Column 3 is the value returned by typ2code(code2typ(c))
Column 4 is the result of c == typ2code(code2typ(c))

Type                                | Code | Ret  | ==?
:---------------                    |:-----|:-----|-----
Char                                | 0x00 | 0x00 | true
String                              | 0x01 | 0x01 | true
UInt8                               | 0x10 | 0x10 | true
UInt16                              | 0x11 | 0x11 | true
UInt32                              | 0x12 | 0x12 | true
UInt64                              | 0x13 | 0x13 | true
UInt128                             | 0x14 | 0x14 | true
Int8                                | 0x20 | 0x20 | true
Int16                               | 0x21 | 0x21 | true
Int32                               | 0x22 | 0x22 | true
Int64                               | 0x23 | 0x23 | true
Int128                              | 0x24 | 0x24 | true
Float16                             | 0x30 | 0x30 | true
Float32                             | 0x31 | 0x31 | true
Float64                             | 0x32 | 0x32 | true
Complex{UInt8}                      | 0x50 | 0x50 | true
Complex{UInt16}                     | 0x51 | 0x51 | true
Complex{UInt32}                     | 0x52 | 0x52 | true
Complex{UInt64}                     | 0x53 | 0x53 | true
Complex{UInt128}                    | 0x54 | 0x54 | true
Complex{Int8}                       | 0x60 | 0x60 | true
Complex{Int16}                      | 0x61 | 0x61 | true
Complex{Int32}                      | 0x62 | 0x62 | true
Complex{Int64}                      | 0x63 | 0x63 | true
Complex{Int128}                     | 0x64 | 0x64 | true
Complex{Float16}                    | 0x70 | 0x70 | true
Complex{Float32}                    | 0x71 | 0x71 | true
Complex{Float64}                    | 0x72 | 0x72 | true
Array{Char,N} where N               | 0x80 | 0x80 | true
Array{String,N} where N             | 0x81 | 0x81 | true
Array{UInt8,N} where N              | 0x90 | 0x90 | true
Array{UInt16,N} where N             | 0x91 | 0x91 | true
Array{UInt32,N} where N             | 0x92 | 0x92 | true
Array{UInt64,N} where N             | 0x93 | 0x93 | true
Array{UInt128,N} where N            | 0x94 | 0x94 | true
Array{Int8,N} where N               | 0xa0 | 0xa0 | true
Array{Int16,N} where N              | 0xa1 | 0xa1 | true
Array{Int32,N} where N              | 0xa2 | 0xa2 | true
Array{Int64,N} where N              | 0xa3 | 0xa3 | true
Array{Int128,N} where N             | 0xa4 | 0xa4 | true
Array{Float16,N} where N            | 0xb0 | 0xb0 | true
Array{Float32,N} where N            | 0xb1 | 0xb1 | true
Array{Float64,N} where N            | 0xb2 | 0xb2 | true
Array{Complex{UInt8},N} where N     | 0xd0 | 0xd0 | true
Array{Complex{UInt16},N} where N    | 0xd1 | 0xd1 | true
Array{Complex{UInt32},N} where N    | 0xd2 | 0xd2 | true
Array{Complex{UInt64},N} where N    | 0xd3 | 0xd3 | true
Array{Complex{UInt128},N} where N   | 0xd4 | 0xd4 | true
Array{Complex{Int8},N} where N      | 0xe0 | 0xe0 | true
Array{Complex{Int16},N} where N     | 0xe1 | 0xe1 | true
Array{Complex{Int32},N} where N     | 0xe2 | 0xe2 | true
Array{Complex{Int64},N} where N     | 0xe3 | 0xe3 | true
Array{Complex{Int128},N} where N    | 0xe4 | 0xe4 | true
Array{Complex{Float16},N} where N   | 0xf0 | 0xf0 | true
Array{Complex{Float32},N} where N   | 0xf1 | 0xf1 | true
Array{Complex{Float64},N} where N   | 0xf2 | 0xf2 | true
=#
