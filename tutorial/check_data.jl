using SeisIO, SeisIO.RandSeis, Test

"""
    check_tutorial_data(S::GphysData; prune::Bool=true)

Check tutorial data for possible errors. If `prune=true`, channels with data
errors are deleted.

Current checks:
* No data
* Data are all NaNs (common with bad filtering parameters)
* Data are all equal (very rare; theoretically possible but we've never seen it)
"""
function check_tutorial_data!(S::GphysData; prune::Bool=true)
  pull = falses(S.n)

  for i in 1:S.n
    T = eltype(S.x[i])

    # check for no data
    if length(S.x[i]) == 0
      @warn(string("Channel ", i, " [id = ", S.id[i], "] has no data."))
      pull[i] = true
      continue
    end

    # check for NaNs
    nn = length(findall(isnan.(S.x[i])))
    if nn > 0
      @warn(string("Channel ", i,
            " [id = ", S.id[i], ", data type = ", T,
            "]. Output contains ", nn, " NaNs."))
      pull[i] = true
    end

    # check for variation
    mx = maximum(abs.(diff(S.x[i])))
    if mx == zero(T)
      @warn(string("Channel ", i,
            " [id = ", S.id[i], ", data type = ", T,
            "]. Output is a constant."))
      pull[i] = true
    end
  end


  if prune
    inds = findall(pull.==true)
    if isempty(inds)
      @info("No data issues found.")
    else
      info_strings = join([string(i, ": ", S.id[i]) for i in inds], "\n")
      @info(string("Deleting channels: \n", info_strings))
      deleteat!(S, inds)
    end
  end
  return nothing
end

# run a test to ensure this is behaving correctly
function test_check_tutorial_data()
  @info(string("Testing check_tutorial_data(). Expect two Warnings and an Info string."))
  S = randSeisData(6, nx=32000, s=1.0)
  U = deepcopy(S)
  S.x[1][12:20] .= NaN
  fill!(S.x[3], 3*one(eltype(S.x[3])))
  S.x[6] = eltype(S.x[6])[]
  check_tutorial_data!(S)
  @test S.id == U.id[[2, 4, 5]]
  @test S.x == U.x[[2, 4, 5]]
  println("Test of check_tutorial_data! complete.")
  return nothing
end
