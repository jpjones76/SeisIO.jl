function SL_wait(ta::Array{Union{Task,Nothing}, 1}, t_interval::Int64)
  t = 0
  while t < 300
    if any([!istaskdone(t) for t in ta])
      sleep(t_interval)
      t += t_interval
    elseif t ≥ 60
      println("      one or more queries incomplete after 60 s; skipping test.")
      for i = 1:4
        ta[i] = nothing
        GC.gc()
      end
      break
    else
      tf1 = fetch(ta[1])
      tf2 = fetch(ta[2])
      tf3 = fetch(ta[3])
      tf4 = fetch(ta[4])
      @test tf1 == tf2 == tf3 == tf4
      break
    end
  end
  return nothing
end

function wait_on_data!(S::GphysData, tmax::Real)
  τ = 0.0
  t = 5.0
  printstyled(string("      (sleep up to ", tmax, " s)\n"), color=:green)
  redirect_stdout(out) do
    show(S)

    # Here we actually wait for data to arrive
    while isempty(S)
      if any(isopen.(S.c)) == false
        break
      end
      if τ > tmax-t
        show(S)
        break
      end
      sleep(t)
      τ += t
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
    τ += t
  end

  # Synchronize (the reason we used d0,d1 in our test sessions)
  prune!(S)
  if !isempty(S)
    sync!(S, s="first")
    str = string("time elapsed = ", τ, " s")
    @info(str)
    printstyled("      "*str*"\n", color=:green)
  else
    str = (if τ < tmax
      string("connection closed after ", τ, " s")
    else
      string("no data after ", τ, " s...is server up?")
    end)
    @warn(str)
    printstyled("      "*str*"\n", color=:green)
  end
  return nothing
end
