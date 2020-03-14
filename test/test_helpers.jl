path = Base.source_dir()
for i in readdir(path * "/TestHelpers")
  if endswith(i, ".jl")
    include(joinpath(path, "TestHelpers", i))
  end
end
