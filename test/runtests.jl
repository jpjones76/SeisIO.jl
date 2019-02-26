using Test, Compat, Dates, Random, SeisIO

path = Base.source_dir()
@warn("Tests require up to 20 minutes to execute. Begin in 5 seconds...")
sleep(5)
printstyled(stdout, string(Dates.now(), ": tests begin, source_dir = ", path, "\n"), color=:light_green, bold=true)

include("test_helpers.jl")

# Utilities that don't require SeisIO types to work
printstyled("Testing CoreUtils\n", color=:light_green, bold=true)
for i in readdir(path*"/CoreUtils")
  include(joinpath("CoreUtils",i))
end

# Utilities that don't require SeisIO types to work
printstyled("Testing Types\n", color=:light_green, bold=true)
for i in readdir(path*"/Types")
  include(joinpath("Types",i))
end

# Utilities that don't require SeisIO types to work
printstyled("Testing File IO\n", color=:light_green, bold=true)
for i in readdir(path*"/FileIO")
  include(joinpath("FileIO",i))
end

# Utilities that don't require SeisIO types to work
printstyled("Testing Web Functionality\n", color=:light_green, bold=true)
for i in readdir(path*"/Web")
  include(joinpath("Web",i))
end

printstyled("...done!\n", color=:light_green, bold=true)

# printstyled("To run canonical examples, execute this command: include(\"", path, "/examples.jl\")")
