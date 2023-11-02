# timeout.jl

# TERM=dumb JULIA_LOAD_PATH="$JULIA_LOAD_PATH:$(pwd)" rlwrap -a julia -i timeout.jl

using Fortune

function t_process(timeout)
    function (p::Process)
        done = false
        while !done
            rec(p,
                [msg(:timeout) => 
                    m -> begin
                        done = true
                        @info (; msg = :timeout, m = m)
                    end,
                 (_ -> true) => m -> @info (; msg = :_, m = m)],
                timeout = timeout)
        end
    end
end

# t = spawn(t_process(5));
# 
# send(t, (; msg = :a))
# send(t, (; msg = :b))
# send(t, (; msg = :c))


### end
