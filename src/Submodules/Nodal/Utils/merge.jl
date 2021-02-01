merge!(S::NodalData) = error("NodalData cannot be merged!")

# This is probably unreachable and perhaps should be deleted
merge_ext!(S::NodalData, Ω::Int64, rest::Array{Int64, 1}) = nothing
