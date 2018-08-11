# ============================================================================
# Annotation

# Adding a string to SeisData writes a note; if the string mentions a channel
# name or ID, the note is restricted to the given channels(s), else it's
# added to all channels
"""
    note!(S::SeisData, i::Int64, s::String)

Append `s` to channel `i` of `S` and time stamp.

    note!(S::SeisData, id::String, s::String)

As above for the first channel in `S` whose id is an exact match to `id`.
"""
note!(S::SeisData, i::Int64, s::String) = push!(S.notes[i], tnote(s))


"""
    note!(S::SeisData, s::String)

Append `s` to `S.notes` and time stamp. If `txt` contains a channel name or ID, only the channel mentioned is annotated; otherwise, all channels are annotated.
"""
function note!(S::SeisData, s::String)
    J = [occursin(i, s) for i in S.name]
    K = [occursin(i, s) for i in S.id]
    j = findall(max.(J,K) .== true)
  if !isempty(j)
    [push!(S.notes[i], tnote(s)) for i in j]
  else
    for i = 1:S.n
      push!(S.notes[i], tnote(s))
    end
  end
  return nothing
end

function note!(S::SeisData, id::String, s::String)
  i = findid(id, S)
  (i == 0) && error(string("id = ", id, " not found in S!"))
  push!(S.notes[i], tnote(s))
  return nothing
end

note!(H::SeisHdr, s::String) = push!(H.notes, tnote(s))
note!(S::SeisChannel, s::String) = push!(S.notes, tnote(s))

"""
    clear_notes!(S::Union{SeisData,SeisChannel})

Clear all notes from all channels of `S`.
"""
function clear_notes!(S::SeisData)
  cstr = tnote("notes cleared.")
  for i = 1:S.n
    empty!(S.notes[i])
    push!(S.notes[i], identity(cstr))
  end
  return nothing
end
clear_notes!(C::SeisChannel) = (C.notes = Array{String,1}(1); C.notes[i][1] = tnote("notes cleared."); return nothing)

"""
    clear_notes!(S::SeisData, i::Int64, s::String)

Clear all notes from channel `i` of `S`.

    clear_notes!(S::SeisData, id::String, s::String)

As above for the first channel in `S` whose id is an exact match to `id`.
"""
function clear_notes!(S::SeisData, i::Int64)
  empty!(S.notes[i])
  push!(S.notes[i], tnote("notes cleared."))
  return nothing
end

function clear_notes!(S::SeisData, id::String)
  i = findid(id, S)
  (i == 0) && error(string("id = ", id, " not found in S!"))
  empty!(S.notes[i])
  push!(S.notes[i], tnote("notes cleared."))
  return nothing
end

clear_notes!(H::SeisHdr) = empty!(H.notes)
