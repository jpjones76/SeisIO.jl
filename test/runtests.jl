@info("Please allow up to 20 minutes for all tests to execute.")
import SeisIO
import SeisIO: get_svn
cd(dirname(pathof(SeisIO))*"/../test")
get_svn("https://github.com/jpjones76/SeisIO-TestData/trunk/SampleFiles", "SampleFiles")
include("local_restricted.jl")
include("test_helpers.jl")

# Announce test begin
test_start  = Dates.now()
ltestname   = 48
printstyled(stdout,
  string(test_start, ": tests begin, path = ", path, ", has_restricted = ", has_restricted, ", keep_log = ", keep_log, ", keep_samples = ", keep_samples, "\n"),
  color=:light_green,
  bold=true)

# Run all tests
# huehuehue grep "include(joinpath" runtests.jl | awk -F "(" '{print $3}' | awk -F "," {'print $1'}
for d in ["CoreUtils", "Types", "RandSeis", "Utils", "NativeIO", "DataFormats", "Processing", "Quake", "Web"]
  ld = length(d)
  ll = div(ltestname - ld - 2, 2)
  lr = ll + (isodd(ld) ? 1 : 0)
  printstyled(string("="^ll, " ", d, " ", "="^lr, "\n"), color=:cyan, bold=true)
  for i in readdir(path*"/"*d)
    f = joinpath(d,i)
    if endswith(i, ".jl")
      printstyled(lpad(" "*f, ltestname)*"\n", color=:cyan)
      write(out, string("\n\ntest ", f, "\n\n"))
      flush(out)
      include(f)
    end
  end
end

# Cleanup
include("cleanup.jl")
if keep_samples == false
  include("rm_samples.jl")
end
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
mm = round(Int, div(δt, 60))
ss = rem(δt, 60)
printstyled(string(test_end, ": tests end, elapsed time (mm:ss.μμμ) = ",
                          @sprintf("%02i", mm), ":",
                          @sprintf("%06.3f", ss), "\n"), color=:light_green, bold=true)
printstyled("To run some data acquisition examples, execute this command: include(\"", path, "/examples.jl\").\n", color=:cyan, bold=true)
