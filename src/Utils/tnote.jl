function tnote(s::String)
  str = string(timestamp(), ": ", s)
  L = min(length(str),256)
  return str[1:L]
end
