#! /bin/env julia

## usage 
#
#   $ JULIA_LOAD_PATH="$JULIA_LOAD_PATH:$(pwd)" JULIA_DEBUG=Curtain ./x.jl 
#

using Curtain

## echo_process

function echo_process()
    function (self::Mailbox)
        while true
            rec(self, 
                [(_ -> true) => 
                    m -> @info (; echo = m)])
        end
    end
end


## nest

function zeta_process()
    function (self::Mailbox)
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

function reply_process(a::Mailbox)
    function (self::Mailbox)
        while true
            rec(self, 
                [msg(:z) => 
                     m -> begin
                         # @info (; process = :reply, rec = :z, m = m)
                         z = spawn(zeta_process(), :zeta_process)
                         send(z, (; msg = :zeta, from = self, k = "please hash this", t = tau()))
                         rec(self,
                             [msg(:zeta_reply) => # guard is a call to `msg` - this seems to work?!
                              m -> begin
                                  # @info (; process = :reply, rec = :zeta_reply, m = m)
                                  # println(z)
                                  # println(m[:from])
                                  # guard = ((m -> m[:from] == z)(m))
                                  # println("guard is $guard")
                                  send(a, (; msg = :nest_zeta, m = m, t = tau()))
                              end])
                     end,
                 (_ -> true) => 
                     m -> begin
                         # @info (; process = :reply, rec = :_, m = m)
                         send(a, (; msg = :nest, m = m, t = tau()))
                     end])
        end
    end
end

function from_process(a::Mailbox)
    function (self::Mailbox)
        while true
            rec(self, 
                [msg(:z) => 
                     m -> begin
                         @info (; process = :from, rec = :z, m = m)
                         z = spawn(zeta_process(), :zeta_process)
                         send(z, (; msg = :zeta, from = self, k = "please hash this", t = tau()))
                         rec(self,
                             [(m -> m[:from] == z) => # the test on the :from field of the message can lead to the process hanging
                                  m -> begin
                                      @info (; process = :from, rec = :from, m = m)
                                      # println(z)
                                      # println(m[:from])
                                      # guard = ((m -> m[:from] == z)(m))
                                      # println("guard is $guard")
                                      send(a, (; msg = :nest_zeta, m = m, t = tau()))
                                  end])
                     end,
                 (_ -> true) => 
                     m -> begin
                         @info (; process = :from, rec = :_, m = m)
                         send(a, (; msg = :nest, m = m, t = tau()))
                     end])
        end
    end
end


_t0 = time()

function tau()
    round(time() - _t0; digits = 2)
end


echo = spawn(echo_process(), :echo);

send(echo, (; msg = "off we go ...", t = tau()))


if length(ARGS) == 0 || ARGS[1] == "from"
    f = spawn(from_process(echo), :from) # this process can handle messages one at a time, it can handle more than one message provided none of them have msg(:z); more than one message at a time any one of which has msg(:z) and it hangs!
    # begin
    send(f, (; msg = :z, t = tau()))
    send(f, (; msg = :x, t = tau()))
    send(f, (; msg = :y, t = tau()))
    # end
else
    r = spawn(reply_process(echo), :reply) # this seems to behave as expected with all the combinations of the messages I have tried i.e. one or more at a time, with or without the begin ... end block, change the order
    # begin
    send(r, (; msg = :z, t = tau()))
    send(r, (; msg = :x, t = tau()))
    send(r, (; msg = :y, t = tau()))
    # end
end

sleep(5)

send(echo, (; msg = "ok, closing down ...", t = tau()))
sleep(1)


### end
