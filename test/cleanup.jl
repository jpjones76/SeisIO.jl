printstyled("Tests complete. Cleaning up...\n", color=:light_green)
flush(out)
close(out)
for fpat in ("*.mseed", "*.SAC", "*.geocsv", "FDSNsta.xml", "FDSNevq.log")
  try
    files = ls(fpat)
    for f in files
      rm(f)
    end
  catch err
    println("Attempting to delete ", fpat, " threw error: ", err)
  end
end
