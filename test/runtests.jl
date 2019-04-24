@info("Please allow up to 20 minutes for all tests to execute.")
import SeisIO
cd(dirname(pathof(SeisIO))*"/../test")
include("test_helpers.jl")
test_start = Dates.now()
printstyled(stdout, string(test_start, ": tests begin, source_dir = ", path, "/\n"), color=:light_green, bold=true)

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

test_end = Dates.now()
δt = 0.001*(test_end-test_start).value
mm = round(Int, div(δt, 60))
ss = rem(δt, 60)
printstyled(string(test_end, ": tests end, elapsed time (mm:ss.μμμ) = ",
                          @sprintf("%02i", mm), ":",
                          @sprintf("%06.3f", ss), "\n"), color=:light_green, bold=true)
printstyled("To run some data acquisition examples, execute this command: include(\"", path, "/examples.jl\").\n", color=:cyan, bold=true)
