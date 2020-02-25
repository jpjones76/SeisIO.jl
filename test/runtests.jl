import SeisIO
import SeisIO: get_svn

# =====================================================================
# Setup
@info("Please allow 20 minutes for all tests to execute.")
cd(dirname(pathof(SeisIO))*"/../test")
if isdir("SampleFiles") == false
  get_svn("https://github.com/jpjones76/SeisIO-TestData/trunk/SampleFiles", "SampleFiles")
end
include("local_restricted.jl")
include("test_helpers.jl")

# Announce test begin
test_start  = Dates.now()
ltn         = 48
printstyled(stdout,
  string(test_start, ": tests begin, path = ", path, ", has_restricted = ",
    has_restricted, ", keep_log = ", keep_log, ", keep_samples = ",
    keep_samples, "\n"),
  color=:light_green,
  bold=true)

# =====================================================================
# Run all tests
# grep "include(joinpath" runtests.jl | awk -F "(" '{print $3}' | awk -F "," {'print $1'}
for d in ["CoreUtils", "Types", "RandSeis", "Utils", "NativeIO", "DataFormats", "Processing", "Quake", "Web"]
  ld = length(d)
  ll = div(ltn - ld - 2, 2)
  lr = ll + (isodd(ld) ? 1 : 0)
  printstyled(string("="^ll, " ", d, " ", "="^lr, "\n"), color=:cyan, bold=true)
  for i in readdir(joinpath(path, d))
    f = joinpath(d,i)
    if endswith(i, ".jl")
      printstyled(lpad(" "*f, ltn)*"\n", color=:cyan)
      write(out, string("\n\ntest ", f, "\n\n"))
      flush(out)
      include(f)
    end
  end
end

# =====================================================================
# Cleanup
include("cleanup.jl")
(keep_samples == true) || include("rm_samples.jl")
if !keep_log
  try
    rm("runtests.log")
  catch err
    @warn(string("can't remove runtests.log; threw err", err))
  end
end

# Announce tests end
test_end = Dates.now()
δt = 0.001*(test_end-test_start).value
printstyled(string(test_end, ": tests end, elapsed time (mm:ss.μμμ) = ",
                   @sprintf("%02i", round(Int, div(δt, 60))), ":",
                   @sprintf("%06.3f", rem(δt, 60)), "\n"),
            color=:light_green,
            bold=true)
printstyled("To run some data acquisition examples, execute: include(\"",
            path, "/examples.jl\").\n", color=:cyan, bold=true)
