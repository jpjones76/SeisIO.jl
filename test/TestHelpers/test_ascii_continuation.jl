"""
    test_ascii_continuation(file::String, fmt::String, id::String, fs::Float64, i::Int64, t0::Int64)

Test for Issue 34
"""

function test_ascii_continuation(file::String, fmt::String, id::String, fs::Float64, i::Int64, t0::Int64)

  # Comparison struct
  S = verified_read_data(fmt, file)

  # Create SeisData struct with data present
  ny = max(100, round(Int64, 10*fs))
  y = rand(Float32, ny)
  S1 = SeisData(1)
  S1.id[1] = id
  S1.fs[1] = fs
  S1.x[1] = copy(y)
  S1.t[1] = [1 rand(0:10000000); ny 0]

  # Read into S1
  verified_read_data!(S1, fmt, file)
  t1 = t_expand(S1.t[i], S.fs[i])[ny+1]
  t2 = S.t[i][1,2]

  # Check that read preserves time, data
  @test S1.x[i][1:ny] == y
  @test S1.x[i][ny+1:end] == S.x[i]
  @test t0 == t1 == t2
  return nothing
end
