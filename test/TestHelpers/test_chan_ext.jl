"""
    test_chan_ext(file::String, fmt::String, id::String, fs::Float64, i::Int64, t0::Int64)

Test for Issue 34
"""

function test_chan_ext(file::String, fmt::String, id::String, fs::Float64, i::Int64, t0::Int64)

  # Comparison struct
  S = verified_read_data(fmt, file)
  j = findid(id, S)
  if j == 0
    println("Test failing; cannot find ID!")
    println(rpad("File: ", 12), file)
    println(rpad("Format: ", 12), fmt)
    println("Channel ID: ", id)
    println("Output IDs: ", S.id)
    throw("Test failed; ID not found!")
  end

  # Create SeisData struct with data present using correct headers
  ny = max(100, round(Int64, 10*fs))
  y = rand(Float32, ny)
  S1 = SeisData(
    SeisChannel(
      id = id,
      fs = fs,
      gain = S.gain[j],
      units = S.units[j],
      loc = deepcopy(S.loc[j]),
      resp = deepcopy(S.resp[j]),
      t = [1 rand(0:10000000); ny 0],
      x = copy(y)
      )
    )

  # Read into S1
  verified_read_data!(S1, fmt, file)
  t1 = t_expand(S1.t[i], S.fs[i])[ny+1]
  t2 = S.t[j][1,2]

  # Check that read preserves time, data
  @test S1.x[i][1:ny] == y
  @test S1.x[i][ny+1:end] == S.x[j]
  @test t0 == t1 == t2
  return nothing
end
