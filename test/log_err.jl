open(outfile, "w") do out
    open(outfile, "w") do err
        redirect_stdout(out) do
            redirect_stderr(out) do
                
            end
        end
    end
end
