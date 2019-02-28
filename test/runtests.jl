using Test, Compat, Dates, Random, SeisIO, SeisIO.RandSeis
path = Base.source_dir()
@warn("Tests require up to 20 minutes to execute. Begin in 5 seconds...")
include("test_helpers.jl")
sleep(5)
printstyled(stdout, string(Dates.now(), ": tests begin, source_dir = ", path, "/\n"), color=:light_green, bold=true)

# huehuehue grep "include(joinpath" runtests.jl | awk -F "(" '{print $3}' | awk -F "," {'print $1'}
for d in ["CoreUtils", "Types", "NativeIO", "DataFormats", "Web"]
  printstyled(string("Testing ", d, "/\n"), color=:light_green, bold=true)
  for i in readdir(path*"/"*d)
    include(joinpath(d,i))
  end
end

printstyled("Done!\n", color=:light_green, bold=true)
printstyled("To run canonical examples, execute this command: include(\"", path, "/examples.jl\").\n", color=:cyan, bold=true)
