function string_time(str::String, T::Array{Y,1}) where Y<:Integer
  if isdigit(str[end])
    s = str*"~"
    io = IOBuffer(s)
  else
    io = IOBuffer(str)
  end
  seekstart(io)
  t = stream_time(io, T)
  close(io)
  return t
end
string_time(str::String) = string_time(str, BUF.date_buf)
