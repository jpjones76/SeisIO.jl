# ===========================================================================
# All constants needed by tests are here
const unicode_chars = String.(readdlm(path*"/SampleFiles/julia-unicode.csv", '\n')[:,1])
const n_unicode = length(unicode_chars)
const breaking_dict = Dict{String, Any}(
    "0" => rand(Char),
    "1" => randstring(2^rand(2:10)),
   "16" => rand(UInt8),
   "17" => rand(UInt16),
   "18" => rand(UInt32),
   "19" => rand(UInt64),
   "20" => rand(UInt128),
   "32" => rand(Int8),
   "33" => rand(Int16),
   "34" => rand(Int32),
   "35" => rand(Int64),
   "36" => rand(Int128),
   "48" => rand(Float16),
   "49" => rand(Float32),
   "50" => rand(Float64),
   "80" => rand(Complex{UInt8}),
   "81" => rand(Complex{UInt16}),
   "82" => rand(Complex{UInt32}),
   "83" => rand(Complex{UInt64}),
   "84" => rand(Complex{UInt128}),
   "96" => rand(Complex{Int8}),
   "97" => rand(Complex{Int16}),
   "98" => rand(Complex{Int32}),
   "99" => rand(Complex{Int64}),
  "100" => rand(Complex{Int128}),
  "112" => rand(Complex{Float16}),
  "113" => rand(Complex{Float32}),
  "114" => rand(Complex{Float64}),
  "128" => rand(Char, 2^rand(2:6)),
  "129" => [randstring(2^rand(3:8)) for i = 1:rand(4:24)],
  "144" => rand(UInt8, rand(4:24)),
  "145" => rand(UInt16, rand(4:24)),
  "146" => rand(UInt32, rand(4:24)),
  "147" => rand(UInt64, rand(4:24)),
  "148" => rand(UInt128, rand(4:24)),
  "160" => rand(Int8, rand(4:24)),
  "161" => rand(Int16, rand(4:24)),
  "162" => rand(Int32, rand(4:24)),
  "163" => rand(Int64, rand(4:24)),
  "164" => rand(Int128, rand(4:24)),
  "176" => rand(Float16, rand(4:24)),
  "177" => rand(Float32, rand(4:24)),
  "178" => rand(Float64, rand(4:24)),
  "208" => rand(Complex{UInt8}, rand(4:24)),
  "209" => rand(Complex{UInt16}, rand(4:24)),
  "210" => rand(Complex{UInt32}, rand(4:24)),
  "211" => rand(Complex{UInt64}, rand(4:24)),
  "212" => rand(Complex{UInt128}, rand(4:24)),
  "224" => rand(Complex{Int8}, rand(4:24)),
  "225" => rand(Complex{Int16}, rand(4:24)),
  "226" => rand(Complex{Int32}, rand(4:24)),
  "227" => rand(Complex{Int64}, rand(4:24)),
  "228" => rand(Complex{Int128}, rand(4:24)),
  "240" => rand(Complex{Float16}, rand(4:24)),
  "242" => rand(Complex{Float64}, rand(4:24)),
  "241" => rand(Complex{Float32}, rand(4:24))
  )
const NOOF = "
  HI ITS CLOVER LOL﻿
          ,-'-,  `---..
         /             \\
         =,             .
  ______<3.  ` ,+,     ,\\`
 ( \\  + `-”.` .; `     `.\\
 (_/   \\    | ((         ) \\
  |_ ;  \"    \\   (        ,’ |\\
  \\    ,- '💦 (,\\_____,’   / “\\
   \\__---+ }._)              |\\
   / _\\__💧”)/                  +
  ( /    💧” \\                  ++_
   \\)    ,“  |)                ++  ++
   💧     “💧  (                 *    +***
"
