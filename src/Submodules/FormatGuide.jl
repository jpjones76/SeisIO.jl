module Formats

using Dates:Date
import Base:show

mutable struct FmtVer
  v::Union{Number, String}
  d::Union{Date, String}
  s::Union{Bool, Nothing}

  FmtVer() = new(0, Date("1970-01-01"), nothing)

  FmtVer(v::Union{Number, String},
         d::Union{Date, String},
         s::Union{Bool, Nothing}) = new(v,d,s)
end

const HistVec = Array{FmtVer,1}
const FmtStatus = Dict{UInt8, String}(
  0x00 => "unknown",
  0x01 => "in use; maintained",
  0x20 => "legacy; maintained but no longer in use",
  0xfd => "ostensibly maintained, but they don't answer our emails",
  0xfe => "suspected abandoned, can't find contact info",
  0xff => "abandoned"
)

mutable struct FormatDesc
  name::String
  str::String
  origin::String
  source::String
  contact::String
  ver::HistVec
  desc::Array{String,1}
  used::Array{String,1}
  docs::Array{String,1}
  status::UInt8

  function FormatDesc()
    return new( "",
                "",
                "",
                "",
                "",
                HistVec(undef, 0),
                String[],
                String[],
                String[],
                0x00,
              )
  end

  function FormatDesc(  name::String,
                        str::String,
                        origin::String,
                        source::String,
                        contact::String,
                        ver::HistVec,
                        desc::Array{String,1},
                        used::Array{String,1},
                        docs::Array{String,1},
                        status::UInt8
                      )

    return new(name, str, origin, source, contact, ver, desc, used, docs, status)
  end
end

@doc """
    formats[fmt]

Show resources for working with data format `fmt`. Returned are:
* name: Data format name
* read_data: String(s) to pass to `read_data` for this format, separated by commas
* origin: Where the data format was created
* source: Where to download external source code for working with data in this format
* contact: Whom to contact with questions
* description: Description of the data format's purpose and any notable issues
* used by: Where the data format is typically encountered
* status: Whether the data format is still in use
* versions: Notable versions or revisions to the standard
* documentation: Any useful documentation related to understanding a format

    formats["list"]

List formats with entries.

### How to read "status:"
* "in use" means that a data format is currently used to read, transmit, or archive new data from modern geophysical instruments.
* "legacy" means that a data format is maintained by an official authority but no longer being actively developed or used by new equipment.
* "abandoned" means that a data format is no longer maintained.

### Notes
* `:used` lists locations, programs, and research areas where the format is (or was) used.
* `:ver` format is `number`, `date`, `read/write`. In the third field, "r" means read support, "rw" means read or write support, "-" means no support.

""" formats
const formats = Dict{String, Union{Array{String,1}, FormatDesc}}()

function show(io::IO, F::FormatDesc)
  p = 17
  println("")
  printstyled(lpad("name:", p), color=:cyan, bold=true)
  printstyled(" "*getfield(F, :name)*"\n", bold=true)
  printstyled(lpad("read_data:", p), color=:cyan)
  printstyled(" "*getfield(F, :str)*"\n")
  for i in (:origin, :source, :contact)
    printstyled(lpad(string(i)*":", p), color=:cyan)
    println(" ", getfield(F, i))
  end
  printstyled(lpad("description:\n", p+1), color=:cyan)
  for i in F.desc
    println(" "^(p+1), i)
  end
  printstyled(lpad("used by:\n", p+1), color=:cyan)
  for i in F.used
    println(" "^(p+1), i)
  end
  printstyled(lpad("status:\n", p+1), color=:cyan)
  println(" "^(p+1), FmtStatus[F.status])
  printstyled(lpad("versions:\n", p+1), color=:cyan)
  for i in F.ver
    println(" "^(p+1), i.v, ", ", i.d, ", ", i.s == nothing ? "-" : i.s == true ? "rw" : "r")
  end
  printstyled(lpad("documentation:", p), color=214, bold=true)
  println("")
  for i in F.docs
    println(" "^(p+1), i)
  end
end
show(F::FormatDesc) = show(stdout, F)

include("FormatGuide/formats_list.jl")

end
