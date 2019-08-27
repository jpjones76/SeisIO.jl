export get_file_ver, set_file_ver

function set_file_ver(f::String, ver::Float32=vSeisIO)
  isfile(f) || error("File not found!")
  io = open(f, "a+")
  seekstart(io)
  String(read(io, 6)) == "SEISIO" || error("Not a SeisIO file!")
  write(io, ver)
  close(io)
  return nothing
end
set_file_ver(f::String, ver::Float64) = set_file_ver(f, Float32(ver))

function get_file_ver(f::String)
  isfile(f) || error("File not found!")
  io = open(f, "r")
  seekstart(io)
  String(read(io, 6)) == "SEISIO" || error("Not a SeisIO file!")
  ver = read(io, Float32)
  close(io)
  return ver
end
