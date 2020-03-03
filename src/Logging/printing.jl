export processing_log, source_log, write_log

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

"""
    write_log(S::GphysData)
    write_log(S::GphysData, i::Int64)
    write_log(C::GphysChannel)

Tabulate and print all data writes logged in `:notes` to stdout in human-readable format.

See Also: `processing_log`, `note!`, `clear_notes!`
"""
function write_log(S::GphysData)
  for i in 1:S.n
    println("\nChannel ", i)
    print_log(S.notes[i], "write")
  end
  return nothing
end
write_log(S::GphysData, i::Int) = print_log(S.notes[i], "write")
write_log(C::GphysChannel) = print_log(C.notes, "write")
