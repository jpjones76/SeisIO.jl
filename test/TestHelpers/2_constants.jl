# ===========================================================================
# All constants needed by tests are here
const unicode_chars = String.(readdlm(path*"/SampleFiles/julia-unicode.csv", '\n')[:,1])
const n_unicode = length(unicode_chars)
const breaking_dict = Dict{String,Any}(
  "0" => rand(Char), "1" => randstring(rand(51:100)),
  "16" => rand(UInt8), "17" => rand(UInt16), "18" => rand(UInt32), "19" => rand(UInt64), "20" => rand(UInt128),
  "32" => rand(Int8), "33" => rand(Int16), "34" => rand(Int32), "35" => rand(Int64), "36" => rand(Int128),
  "48" => rand(Float16), "49" => rand(Float32), "50" => rand(Float64),
  "80" => rand(Complex{UInt8}), "81" => rand(Complex{UInt16}), "82" => rand(Complex{UInt32}), "83" => rand(Complex{UInt64}), "84" => rand(Complex{UInt128}),
  "96" => rand(Complex{Int8}), "97" => rand(Complex{Int16}), "98" => rand(Complex{Int32}), "99" => rand(Complex{Int64}), "100" => rand(Complex{Int128}),
  "112" => rand(Complex{Float16}), "113" => rand(Complex{Float32}), "114" => rand(Complex{Float64}),
  "128" => collect(rand(Char, rand(4:24))), "129" => [randstring(rand(4:24)) for i=1:rand(4:24)],
  "144" => collect(rand(UInt8, rand(4:24))), "145" => collect(rand(UInt16, rand(4:24))), "146" => collect(rand(UInt32, rand(4:24))), "147" => collect(rand(UInt64, rand(4:24))), "148" => collect(rand(UInt128, rand(4:24))),
  "160" => collect(rand(Int8, rand(4:24))), "161" => collect(rand(Int16, rand(4:24))), "162" => collect(rand(Int32, rand(4:24))), "163" => collect(rand(Int64, rand(4:24))), "164" => collect(rand(Int128, rand(4:24))),
  "176" => collect(rand(Float16, rand(4:24))), "177" => collect(rand(Float32, rand(4:24))), "178" => collect(rand(Float64, rand(4:24))), "208" => collect(rand(Complex{UInt8}, rand(4:24))),
  "209" => collect(rand(Complex{UInt16}, rand(4:24))), "210" => collect(rand(Complex{UInt32}, rand(4:24))), "211" => collect(rand(Complex{UInt64}, rand(4:24))), "212" => collect(rand(Complex{UInt128}, rand(4:24))),
  "224" => collect(rand(Complex{Int8}, rand(4:24))), "225" => collect(rand(Complex{Int16}, rand(4:24))), "226" => collect(rand(Complex{Int32}, rand(4:24))), "227" => collect(rand(Complex{Int64}, rand(4:24))), "228" => collect(rand(Complex{Int128}, rand(4:24))),
  "240" => collect(rand(Complex{Float16}, rand(4:24))), "241" => collect(rand(Complex{Float32}, rand(4:24))), "242" => collect(rand(Complex{Float64}, rand(4:24)))
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
