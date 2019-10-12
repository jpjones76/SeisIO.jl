module XMLwrite
using Dates, SeisIO
import SeisIO:datafields, ucum_to_seed

include("XMLwrite/sxml.jl")

# exports
export write_sxml
end
