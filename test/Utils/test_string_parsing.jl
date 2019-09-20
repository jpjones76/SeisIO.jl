printstyled("  parsing\n", color=:light_green)
import SeisIO: string_time, stream_float, stream_time
date_buf = BUF.date_buf

s = [ "2010",
      "2010-01-03",
      "2012-03-01",
      "2010-11-17",
      "2010-11-17T20:20:10",
      "2010-11-17T20:20:01",
      "2010-11-17T20:20:00.100000Z",
      "2010-11-17T20:20:00.010000Z",
      "2010-11-17T20:20:00.001000Z",
      "2010-11-17T20:20:00.000100Z",
      "2010-11-17T20:20:00.000010Z",
      "2010-11-17T20:20:00.000001Z" ]

t = [ 1262304000000000,
      1262476800000000,
      1330560000000000,
      1289952000000000,
      1290025210000000,
      1290025201000000,
      1290025200100000,
      1290025200010000,
      1290025200001000,
      1290025200000100,
      1290025200000010,
      1290025200000001 ]

for (i,j) in enumerate(s)
  @test string_time(j, date_buf) == t[i]
  @test stream_time(IOBuffer(j*"~"), date_buf) == t[i]
end

float_strings = ["49.981",
                 ".9183948913749817",
                 "1232.0",
                 "1232.34a",
                 "0",
                 "313,",
                 "-12345",
                 "-12345.0",
                 "3.1E19",
                 "1.23E-08",
                 "+1.23E+8",
                 "1.234E-8",
                 "1.234E+8",
                 "3.4028235f38",  # largest finite Float32
                 "-3.4028235f38", # smallest finite Float32
                 "1.0f-45"]

float_vals = Float32[49.981,
  0.91839486f0,
  1232.0,
  1232.34,
  0.0,
  313.0,
  -12345.0,
  -12345.0,
  3.1f19,
  1.23f-8,
  1.23f8,
  1.234f-8,
  1.234f8,
  3.4028235f38,
  -3.4028235f38,
  1.0f-45]

for (i,j) in enumerate(float_strings)
  # println("test ", i, ": ", j)
  b = IOBuffer(j*"~")
  @test stream_float(b, 0x00) ≈ float_vals[i]
  close(b)
end

bad_floats = ["49.9.81",
  ".9f",
 ".9fff183948913749817",
 "+-+-+-1232.0",
 "12a32.34a",
 "threeve",
 "Texa\$",
 "13.13.13.",
 "-.123efe"]

printstyled("    how bad float strings parse:\n", color=:light_green)
for (i,j) in enumerate(bad_floats)
  # println("test ", i, ": ", j, " => ", string(bad_vals[i]))
  b = IOBuffer(j*"~")
  try
    f = stream_float(b, 0x00)
    println("      ", j, " => ", string(f))
  catch err
    println("      ", j, " => error (", err, ")")
  end
  close(b)
end
