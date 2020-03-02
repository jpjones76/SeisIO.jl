export note!, clear_notes!, processing_log, source_log

# ============================================================================
# Annotation

# Adding a string to SeisData writes a note; if the string mentions a channel
# name or ID, the note is restricted to the given channels(s), else it's
# added to all channels
@doc """
    note!(S::SeisData, i::Int64, s::String)

Append `s` to channel `i` of `S` and time stamp.

    note!(S::SeisData, id::String, s::String)

As above for the first channel in `S` whose id is an exact match to `id`.

  note!(S::SeisData, s::String)

Append `s` to `S.notes` and time stamp. If `txt` contains a channel name or ID, only the channel mentioned is annotated; otherwise, all channels are annotated.

See Also: clear_notes!, processing_log, source_log
""" note!
note!(S::T, i::Int64, s::String) where {T<:GphysData} = push!(S.notes[i], tnote(s))

function note!(S::GphysData, s::String)
    J = [occursin(i, s) for i in S.name]
    K = [occursin(i, s) for i in S.id]
    j = findall(max.(J,K) .== true)
  if !isempty(j)
    [push!(S.notes[i], tnote(s)) for i in j]
  else
    tn = tnote(s)
    for i = 1:S.n
      push!(S.notes[i], tn)
    end
  end
  return nothing
end

function note!(S::GphysData, id::String, s::String)
  i = findid(id, S)
  (i == 0) && error(string("id = ", id, " not found in S!"))
  push!(S.notes[i], tnote(s))
  return nothing
end

function note!(S::GphysData, chans::Union{UnitRange,Array{Int64,1}}, s::String)
  tn = tnote(s)
  for c in chans
    push!(S.notes[c], tn)
  end
  return nothing
end

note!(S::GphysChannel, s::String) = push!(S.notes, tnote(s))

# DND, these methods prevent memory reuse
"""
    clear_notes!(U::Union{SeisData,SeisChannel,SeisHdr})

Clear all notes from `U` and leaves a note about this.

    clear_notes!(S::SeisData, i::Int64, s::String)

Clear all notes from channel `i` of `S` and leaves a note about this.

    clear_notes!(S::SeisData, id::String, s::String)

As above for the first channel in `S` whose id is an exact match to `id`.

See Also: note!, processing_log, source_log
"""
function clear_notes!(S::GphysData)
  cstr = tnote("notes cleared.")
  for i = 1:S.n
    empty!(S.notes[i])
    push!(S.notes[i], identity(cstr))
  end
  return nothing
end

function clear_notes!(S::GphysData, i::Int64)
  empty!(S.notes[i])
  push!(S.notes[i], tnote("notes cleared."))
  return nothing
end

function clear_notes!(S::GphysData, id::String)
  i = findid(id, S)
  (i == 0) && error(string("id = ", id, " not found in S!"))
  empty!(S.notes[i])
  push!(S.notes[i], tnote("notes cleared."))
  return nothing
end

clear_notes!(U::GphysChannel) = (U.notes = Array{String,1}(undef,1); U.notes[1] = tnote("notes cleared."); return nothing)

function print_log(notes::Array{String,1}, k::String)
  mm = 60
  println("")
  pl = string("| Time | ", titlecase(k), k == "processing" ? " | Description |\n|:-----|:---------|:------------|\n" : " |\n|:-----|:---------|\n")
  ee = true
  for i = 1:length(notes)
    nn = split(notes[i], " ¦ ", keepempty=true, limit=4)
    (length(nn) < 3) && continue
    L = lastindex(nn[3])
    if nn[2] == k
      (ee == true) && (ee = false)
      func_str = (L > mm) ? (nn[3][firstindex(nn[3]):prevind(nn[3], mm)] * "…") : nn[3]
      if k == "processing"
        pl *= string("| ", nn[1], "|`", func_str, "`|", nn[4], "|\n")
      else
        pl *= string("| ", nn[1], "|`", func_str, "`|\n")
      end
    end
  end

  if ee
    pl *= (k == "processing") ? "|      | (none)   |             |\n" : "|      | (none)   |\n"
  end
  show(stdout, MIME("text/plain"), Markdown.parse(pl))
  println("")
  return nothing
end

"""
    processing_log(S::GphysData)
    processing_log(S::GphysData, i::Int64)
    processing_log(C::GphysChannel)

Tabulate and print all processing steps in `:notes` to stdout in human-readable format.

See Also: source_log, note!, clear_notes!
"""
function processing_log(S::GphysData)
  for i in 1:S.n
    println("\nChannel ", i)
    print_log(S.notes[i], "processing")
  end
  return nothing
end
processing_log(S::GphysData, i::Int) = print_log(S.notes[i], "processing")
processing_log(C::GphysChannel) = print_log(C.notes, "processing")

"""
    source_log(S::GphysData)
    source_log(S::GphysData, i::Int64)
    source_log(C::GphysChannel)

Tabulate and print all data sources logged in `:notes` to stdout in human-readable format.

See Also: processing_log, note!, clear_notes!
"""
function source_log(S::GphysData)
  for i in 1:S.n
    println("\nChannel ", i)
    print_log(S.notes[i], "+source")
  end
  return nothing
end
source_log(S::GphysData, i::Int) = print_log(S.notes[i], "+source")
source_log(C::GphysChannel) = print_log(C.notes, "+source")
