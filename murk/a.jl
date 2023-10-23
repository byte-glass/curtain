# a.jl

# TERM=dumb JULIA_LOAD_PATH="$JULIA_LOAD_PATH:$(pwd)" rlwrap -a julia -i a.jl

using Fortune

# echo

function echo_process()
    function (self::Process)
        while true
            rec(self, 
                [(_ -> true) => 
                    m -> @info (; echo = m)])
        end
    end
end

# nest

function zeta_process()
    function (self::Process)
        rec(self, 
            [msg(:zeta) => 
                m -> begin
                    # @info (; process = :zeta, m = m)
                    h = hash(m[:k])
                    sleep(2)
                    send(m[:from], (; msg = :zeta_reply, from = self, h = h, t = tau()))
                end])
    end
end

function reply_process(a::Process)
    function (self::Process)
        while true
            rec(self, 
                [msg(:z) => 
                     m -> begin
                         # @info (; process = :reply, rec = :z, m = m)
                         z = spawn(zeta_process(), :zeta_process)
                         send(z, (; msg = :zeta, from = self, k = "please hash this", t = tau()))
                         rec(self,
                             [msg(:zeta_reply) => 
                                  m -> begin
                                      # @info (; process = :reply, rec = :zeta_reply, m = m)
                                      # println(z)
                                      # println(m[:from])
                                      # guard = ((m -> m[:from] == z)(m))
                                      # println("guard is $guard")
                                      send(a, (; g = m[:from] == z, m = m, t = tau()))
                                  end])
                     end,
                 (_ -> true) => 
                     m -> begin
                         # @info (; process = :reply, rec = :_, m = m)
                         send(a, (; m = m, t = tau()))
                     end])
        end
    end
end

function from_process(a::Process)
    function (self::Process)
        while true
            rec(self, 
                [msg(:z) => 
                     m -> begin
                         # @info (; process = :from, rec = :z, m = m)
                         z = spawn(zeta_process(), :zeta_process)
                         send(z, (; msg = :zeta, from = self, k = "please hash this", t = tau()))
                         rec(self,
                             [(m -> get(m, :from, false) == z) =>
                                  m -> begin
                                      # @info (; process = :from, rec = :from, m = m)
                                      # println(z)
                                      # println(m[:from])
                                      # guard = ((m -> m[:from] == z)(m))
                                      # println("guard is $guard")
                                      send(a, (; m = m, t = tau()))
                                  end])
                     end,
                 (_ -> true) => 
                     m -> begin
                         # @info (; process = :from, rec = :_, m = m)
                         send(a, (; m = m, t = tau()))
                     end])
        end
    end
end


_t0 = time()

function tau()
    round(time() - _t0; digits = 2)
end

echo = spawn(echo_process(), :echo)

f = spawn(from_process(echo), :from)


# begin
# send(f, (; msg = :z, t = tau()));
# send(f, (; msg = :x, t = tau()));
# send(f, (; msg = :y, t = tau()));
# end


# r = spawn(reply_process(echo), :reply)

# begin
# send(r, (; msg = :z, t = tau()));
# send(r, (; msg = :x, t = tau()));
# send(r, (; msg = :y, t = tau()));
# end


### end

