function wait_on_data!(S::GphysData; tmax::Real=60.0)
  τ = 0.0
  t = 10.0
  printstyled(string("      (sleep up to ", tmax + t, " s)\n"), color=:green)
  redirect_stdout(out) do

    # Here we actually wait for data to arrive
    sleep(t)
    τ += t
    while isempty(S)
      if any(isopen.(S.c)) == false
        break
      end
      sleep(t)
      τ += t
      if τ > tmax
        show(S)
        break
      end
    end

    # Close the connection cleanly (write & close are redundant, but
    # write should close it instantly)
    for q = 1:length(S.c)
      if isopen(S.c[q])
        if q == 3
          show(S)
        end
        close(S.c[q])
      end
    end
    sleep(t)
  end

  # Synchronize (the reason we used d0,d1 in our test sessions)
  prune!(S)
  if !isempty(S)
    sync!(S, s="first")
  else
    @warn("No data. Is the server down?")
  end
  return nothing
end
