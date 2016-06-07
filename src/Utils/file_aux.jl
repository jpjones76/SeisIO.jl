function lsw(filestr::ASCIIString)
  d, f = splitdir(filestr)
  i = search(f, '*')
  if !isempty(i)
    ff = f[1:i[1]-1]
    for j = 1:1:length(i)
      ei = j == length(i) ? length(f) : i[j+1]
      ff = join([ff, '.', '*', f[i[j]+1:ei]])
    end
  else
    ff = f
  end
  fff = Regex(ff)
  files = [joinpath(d, j) for j in filter(i -> ismatch(fff,i), readdir(d))]
  return files
end
