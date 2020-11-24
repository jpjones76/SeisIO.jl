merge_ext!(S::NodalData, Ω::Int64, rest::Array{Int64, 1}) = nothing

merge!(S::NodalData) = error("NodalData cannot be merged!")
