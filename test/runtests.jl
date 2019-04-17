@info("Please allow 10-20 minutes for all tests to execute.")
import SeisIO
cd(dirname(pathof(SeisIO))*"/../test")
include("test_helpers.jl")
printstyled(stdout, string(Dates.now(), ": tests begin, source_dir = ", path, "/\n"), color=:light_green, bold=true)

open("runtests.log", "w") do io
  write(io, "stdout redirect:")
end


# huehuehue grep "include(joinpath" runtests.jl | awk -F "(" '{print $3}' | awk -F "," {'print $1'}
for d in ["CoreUtils", "Types", "RandSeis", "NativeIO", "DataFormats", "Processing", "Web"]
  printstyled(string("Testing ", d, "/\n"), color=:light_green, bold=true)
  for i in readdir(path*"/"*d)
    if endswith(i, ".jl")
      include(joinpath(d,i))
    end
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
files = ls("*.geocsv")
for f in files
  rm(f)
end
rm("FDSNsta.xml")

printstyled("Done!\n", color=:light_green, bold=true)
printstyled("To run some data acquisition examples, execute this command: include(\"", path, "/examples.jl\").\n", color=:cyan, bold=true)
