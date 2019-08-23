note!(R::SeisSrc, s::String) = push!(R.notes, tnote(s))
note!(H::SeisHdr, s::String) = push!(H.notes, tnote(s))
clear_notes!(U::Union{SeisHdr,SeisSrc}) = (U.notes = Array{String,1}(undef,1); U.notes[1] = tnote("notes cleared."); return nothing)
clear_notes!(Ev::SeisEvent) = (clear_notes!(Ev.hdr); clear_notes!(Ev.source); clear_notes!(Ev.data))
