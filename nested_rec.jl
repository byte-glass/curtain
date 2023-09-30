# nested_rec.jl

## usage 
#
#   $ JULIA_LOAD_PATH="$JULIA_LOAD_PATH:$(pwd)" julia [-i nested_rec.jl]
#


using Curtain


function echo(s)
    function (self::Mailbox)
        while true
            m = rec(self, [_ -> true])
            print(string((; echo = s, p = m)) * "\n")
        end
    end
end


msg(s) = m -> m[:msg] == s

function nest(self::Mailbox, a::Actor)
    while true
        m = rec(self, [_ -> true])
        if msg(:z)(m)
            z = spawn(
                  function (b::Mailbox)
                      m = rec(b, [msg(:zeta)])
                      h = hash(m[:k])
                      send(m[:from], (; msg = :zeta_reply, h = h, t = tau()))
                  end
             )
            send(z, (; msg = :zeta, from = self, k = "please hash this", t = tau()))
            r = rec(self, [_ -> true])
            send(a, (; msg = :nest_zeta, r = r, t = tau()))
        else
            send(a, (; msg = :nest, p = m))
        end
    end
end


function zeta()
    function (self::Mailbox)
        m = rec(self, [msg(:zeta)])
        h = hash(m[:k])
        send(m[:from], (; msg = :zeta_reply, h = h, t = tau()))
    end
end

function nid(a::Actor)
    function (self::Mailbox)
        while true
            m = rec(self, [_ -> true])
            if msg(:z)(m)
                z = spawn(zeta())
                send(z, (; msg = :zeta, from = self, k = "please hash this", t = tau()))
                r = rec(self, [_ -> true])
                send(a, (; msg = :nest_zeta, r = r, t = tau()))
            else
                send(a, (; msg = :nest, p = m))
            end
        end
    end
end

_t0 = time()

function tau()
    round(time() - _t0; digits = 2)
end


a = spawn(echo(:vanilla));
a = echo(:vanilla) |> spawn;

p = spawn(b -> nest(b, a));

send(p, (; msg = :x, p = "xyz"))
send(p, (; msg = :y, p = pi))

q = spawn(b -> nest(b, spawn(echo(:green))));
q = spawn(b -> nest(b, echo(:green) |> spawn));

send(q, (; msg = :y, p = pi))
send(q, (; msg = :x, p = "abc", t = tau()))
send(q, (; msg = :z, q = -1))

send(q, (; msg = :z, t = tau()))


r = spawn(nid(spawn(echo(:pink))))

rho = echo(:pink) |> spawn |> nid |> spawn

send(rho, (; msg = :x, q = -1))
send(rho, (; msg = :z, t = tau()))




### end
