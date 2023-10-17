# delegate.jl

## usage 
#
#   $ JULIA_LOAD_PATH="$JULIA_LOAD_PATH:$(pwd)" julia -i delegate.jl
#

using Curtain

function echo_process(s)
    function (self::Mailbox)
        while true
            rec(self, 
                [(_ -> true) => 
                    m -> print(string((; echo = s, p = m)) * "\n")])
        end
    end
end

function zeta_process()
    function (self::Mailbox)
        rec(self, 
            [msg(:zeta) => 
                m -> begin
                    h = hash(m[:k])
                    sleep(2)
                    send(m[:from], (; msg = :zeta_reply, from = self, h = h, p = m, t = tau()))
                end])
    end
end

function delegate_process(a::Mailbox)
    function (self::Mailbox)
        while true
            rec(self,
                [msg(:z) =>
                    m -> begin
                        z = spawn(zeta_process())
                        send(z, (; msg = :zeta, from = self, k = "please hash this", p = m, t = tau()))
                    end,
                 msg(:zeta_reply) => m -> send(a, (; msg = :delegate_zeta, p = m, t = tau())),
                 (_ -> true) => m -> send(a, (; msg = :delegate, p = m, t = tau()))])
        end
    end
end

_t0 = time()

function tau()
    round(time() - _t0; digits = 2)
end

echo = echo_process(:vanilla) |> spawn;

delegate = delegate_process(echo) |> spawn;

# send(delegate, (; msg = :z, q = -1, t = tau()))
# send(delegate, (; msg = :x, p = "xyz", t = tau()))
# send(delegate, (; msg = :y, p = pi, t = tau()))


### end
