@info("Please allow up to 20 minutes for all tests to execute.")
import SeisIO
cd(dirname(pathof(SeisIO))*"/../test")

# Check that the sample files exist
if isdir("SampleFiles")
  println("SampleFiles/ exists; not downloading.")
else
  include("get_samples.jl")
  p = get_SampleFiles()
  if p != 0
    err_string = "can't download SampleFiles!

    Check: is a command-line SVN client installed?
    (type \"run(`svn --version`)\"; if an error is thrown, you don't have SVN.)

    SlikSVN Windows client: https://sliksvn.com/download/
    Subversion for Ubuntu: sudo apt install subversion
    Subversion for OS X: pkg_add subversion
    "
    error(err_string)
  end
end

# Check for redist-restricted samples ... only works if you're me. W.A.I., email if you need 'em
restr_path = Base.source_dir() * "/SampleFiles/Restricted/"
if isdir(restr_path) == false
  restr_dir = "/data2/SeisIO-TestFiles/SampleFiles/Restricted"
  if isdir(restr_dir)
      run(`cp -r $restr_dir SampleFiles/`)
      println("copied SampleFiles/Restricted/ from /data2/")
  else
    restr_dir_2 = "/data/SeisIO-TestFiles/SampleFiles/Restricted"
    if isdir(restr_dir_2)
      run(`cp -r $restr_dir_2 SampleFiles/`)
      println("copied SampleFiles/Restricted/ from /data/")
    end
  end
else
  println("nothing to copy, SampleFiles/Restricted/ exists")
end

# Add needed test functions
include("test_helpers.jl")

# Announce test begin
test_start  = Dates.now()
ltestname   = 48
printstyled(stdout,
  string(test_start, ": tests begin, path = ", path, ", has_restricted = ", has_restricted, ", keep_log = ", keep_log, ", keep_samples = ", keep_samples, "\n"),
  color=:light_green,
  bold=true)

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

if keep_samples == false
  include("rm_samples.jl")
end
include("cleanup.jl")
if !keep_log
  try
    rm("runtests.log")
  catch err
    @warn(string("can't remove runtests.log; threw err", err))
  end
end
test_end = Dates.now()
δt = 0.001*(test_end-test_start).value
mm = round(Int, div(δt, 60))
ss = rem(δt, 60)
printstyled(string(test_end, ": tests end, elapsed time (mm:ss.μμμ) = ",
                          @sprintf("%02i", mm), ":",
                          @sprintf("%06.3f", ss), "\n"), color=:light_green, bold=true)
printstyled("To run some data acquisition examples, execute this command: include(\"", path, "/examples.jl\").\n", color=:cyan, bold=true)
