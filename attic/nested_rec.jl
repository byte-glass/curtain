# nested_rec.jl

## usage 
#
#   $ JULIA_LOAD_PATH="$JULIA_LOAD_PATH:$(pwd)" julia [-i nested_rec.jl]
#


module Nest

using Curtain

export echo, nest, delegate, tau

function echo(s)
    function (self::Mailbox)
        while true
            m = rec(self, [_ -> true])
            print(string((; echo = s, p = m)) * "\n")
        end
    end
end


msg(s) = m -> m[:msg] == s

function zeta()
    function (self::Mailbox)
        m = rec(self, [msg(:zeta)])
        h = hash(m[:k])
        sleep(2)
        send(m[:from], (; msg = :zeta_reply, h = h, p = m, t = tau()))
    end
end

function nest(a::Actor)
    function (self::Mailbox)
        while true
            m = rec(self, [_ -> true])
            if msg(:z)(m)
                z = spawn(zeta())
                send(z, (; msg = :zeta, from = self, k = "please hash this", p = m, t = tau()))
                r = rec(self, [msg(:zeta_reply)])
                send(a, (; msg = :nest_zeta, r = r, t = tau()))
            else
                send(a, (; msg = :nest, p = m, t = tau()))
            end
        end
    end
end

function delegate(a::Actor)
    function (self::Mailbox)
        while true
            m = rec(self, [_ -> true])
            if msg(:z)(m)
                z = spawn(zeta())
                send(z, (; msg = :zeta, from = self, k = "please hash this", p = m, t = tau()))
            else
                send(a, (; msg = :nest, p = m, t = tau()))
            end
        end
    end
end

_t0 = time()

function tau()
    round(time() - _t0; digits = 2)
end

end


using Curtain

using .Nest

a = echo(:vanilla) |> spawn;

p = nest(a) |> spawn;

send(p, (; msg = :x, p = "xyz"))
send(p, (; msg = :y, p = pi))
send(p, (; msg = :z, q = -1))


rho = echo(:pink) |> spawn |> nest |> spawn

send(rho, (; msg = :x, q = 0, t = tau()))

begin
send(rho, (; msg = :z, t = tau()))
send(rho, (; msg = :a, q = 1, t = tau()))
send(rho, (; msg = :b, q = 2, t = tau()))
send(rho, (; msg = :c, q = 3, t = tau()))
end

delta = echo(:green) |> spawn |> delegate |> spawn

send(delta, (; msg = :x, q = 0, t = tau()))

begin
send(delta, (; msg = :z, t = tau()))
send(delta, (; msg = :a, q = 1, t = tau()))
send(delta, (; msg = :b, q = 2, t = tau()))
send(delta, (; msg = :c, q = 3, t = tau()))
end


### end
