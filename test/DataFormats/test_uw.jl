printstyled("  UW\n", color=:light_green)
uwf = joinpath(path, "SampleFiles/[0-9]*W")
S = read_data("uw", uwf)
