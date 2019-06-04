printstyled("  code2typ, typ2code\n", color=:light_green)
for c = 0x00:0xfe
  d = (try
        typ2code(code2typ(c))
      catch
        0xff
      end)
  if d != 0xff
    @test c == d
  end
end
