printstyled("  Utils\n", color=:light_green)
printstyled("    info_dump\n", color=:light_green)

redirect_stdout(out) do
  info_dump(U)
end
