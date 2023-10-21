# nested.jl

## usage 
#
#   $ JULIA_LOAD_PATH="$JULIA_LOAD_PATH:$(pwd)" julia [-i nested.jl]
#

using Curtain

## echo

function echo_process(s)
    function (self::Mailbox)
        while true
            rec(self, 
                [(_ -> true) => 
                    m -> print(string((; echo = s, p = m)) * "\n")])
        end
    end
end

## nest

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

function reply_process(a::Mailbox)
    function (self::Mailbox)
        while true
            rec(self, 
                [msg(:z) => 
                     m -> begin
                         z = spawn(zeta_process())
                         send(z, (; msg = :zeta, from = self, k = "please hash this", p = m, t = tau()))
                         rec(self,
                             [msg(:zeta_reply) => # guard is a call to `msg` - this seems to work?!
                                  m -> begin
                                      println(z)
                                      println(m[:from])
                                      guard = ((m -> m[:from] == z)(m))
                                      println("guard is $guard")
                                      send(a, (; msg = :nest_zeta, p = m, t = tau()))
                                  end])
                     end,
                 (_ -> true) => m -> send(a, (; msg = :nest, p = m, t = tau()))])
        end
    end
end

function from_process(a::Mailbox)
    function (self::Mailbox)
        while true
            rec(self, 
                [msg(:z) => 
                     m -> begin
                         z = spawn(zeta_process())
                         send(z, (; msg = :zeta, from = self, k = "please hash this", p = m, t = tau()))
                         rec(self,
                             [(m -> m[:from] == z) => # the test on the :from field of the message can lead to the process hanging
                                  m -> begin
                                      println(z)
                                      println(m[:from])
                                      guard = ((m -> m[:from] == z)(m))
                                      println("guard is $guard")
                                      send(a, (; msg = :nest_zeta, p = m, t = tau()))
                                  end])
                     end,
                 (_ -> true) => m -> send(a, (; msg = :nest, p = m, t = tau()))])
        end
    end
end


_t0 = time()

function tau()
    round(time() - _t0; digits = 2)
end


a = echo_process(:vanilla) |> spawn;

r = reply_process(a) |> spawn; # this seems to behave as expected with all the combinations of the messages I have tried i.e. one or more at a time, with or without the begin ... end block, change the order

begin
send(r, (; msg = :x, p = "xyz", t = tau()))
send(r, (; msg = :y, p = pi, t = tau()))
send(r, (; msg = :z, q = -1, t = tau()))
end


f = from_process(a) |> spawn; # this process can handle messages one at a time, it can handle more than one message provided none of them have msg(:z); more than one message at a time any one of which has msg(:z) and it hangs!

begin
send(f, (; msg = :z, q = -1, t = tau()))
begin
send(f, (; msg = :x, p = "xyz", t = tau()))
send(f, (; msg = :y, p = pi, t = tau()))
end


### end
