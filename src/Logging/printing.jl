export show_processing, show_src, show_writes

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
      if k in ("processing", "write")
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
    show_processing(S::GphysData)
    show_processing(S::GphysData, i::Int64)
    show_processing(C::GphysChannel)

Tabulate and print all processing steps in `:notes` to stdout in human-readable format.

See also: `show_src`, `show_writes`, `note!`, `clear_notes!`
"""
function show_processing(S::GphysData)
  for i in 1:S.n
    println("\nChannel ", i)
    print_log(S.notes[i], "processing")
  end
  return nothing
end
show_processing(S::GphysData, i::Int) = print_log(S.notes[i], "processing")
show_processing(C::GphysChannel) = print_log(C.notes, "processing")

"""
    show_src(S::GphysData)
    show_src(S::GphysData, i::Int64)
    show_src(C::GphysChannel)

Tabulate and print all data sources logged in `:notes` to stdout in human-readable format.

See also: `show_processing`, `show_writes`, `note!`, `clear_notes!`
"""
function show_src(S::GphysData)
  for i in 1:S.n
    println("\nChannel ", i)
    print_log(S.notes[i], "+source")
  end
  return nothing
end
show_src(S::GphysData, i::Int) = print_log(S.notes[i], "+source")
show_src(C::GphysChannel) = print_log(C.notes, "+source")

"""
    show_writes(S::GphysData)
    show_writes(S::GphysData, i::Int64)
    show_writes(C::GphysChannel)

Tabulate and print all data writes logged in `:notes` to stdout in human-readable format.

See also: `show_processing`, `show_src`, `note!`, `clear_notes!`
"""
function show_writes(S::GphysData)
  for i in 1:S.n
    println("\nChannel ", i)
    print_log(S.notes[i], "write")
  end
  return nothing
end
show_writes(S::GphysData, i::Int) = print_log(S.notes[i], "write")
show_writes(C::GphysChannel) = print_log(C.notes, "write")
