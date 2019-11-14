function safe_rm(file::String)
  try
    rm(file)
  catch err
    @warn(string("Can't remove ", file, ": throws error ", err))
  end
  return nothing
end
