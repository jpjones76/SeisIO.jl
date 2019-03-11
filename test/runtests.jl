@warn("Tests require 10-12 minutes to execute. Begin in 3 seconds...")
include("test_helpers.jl")
sleep(3)
printstyled(stdout, string(Dates.now(), ": tests begin, source_dir = ", path, "/\n"), color=:light_green, bold=true)

open("runtests.log", "w") do io
  write(io, "stdout redirect:")
end


# huehuehue grep "include(joinpath" runtests.jl | awk -F "(" '{print $3}' | awk -F "," {'print $1'}
for d in ["CoreUtils", "Types", "RandSeis", "NativeIO", "DataFormats", "Processing", "Web"]
  printstyled(string("Testing ", d, "/\n"), color=:light_green, bold=true)
  for i in readdir(path*"/"*d)
    include(joinpath(d,i))
  end
end

# Done. Clean up.
rm("runtests.log")
files = ls("*.mseed")
for f in files
  rm(f)
end
files = ls("*.SAC")
for f in files
  rm(f)
end

printstyled("Done!\n", color=:light_green, bold=true)
printstyled("To run canonical examples, execute this command: include(\"", path, "/examples.jl\").\n", color=:cyan, bold=true)
