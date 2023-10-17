# examples.jl

## usage 
#
#   $ JULIA_LOAD_PATH="$JULIA_LOAD_PATH:$(pwd)" julia [-i examples.jl]
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


echo = echo_process(:vanilla) |> spawn;

send(echo, "echo this!")
send(echo, (; msg = :are, p = "you there"))


## forward

function forward_process()
    function (self::Mailbox)
        while true
            rec(self,
                [msg(:please_forward) => m -> send(m[:to], (; msg = :forward, p = m)),
                 (_ -> true) => m -> nothing])
        end
    end
end

forward = spawn(forward_process())
whisper = spawn(echo_process(:whisper))

send(forward, (; msg = :please_forward, to = whisper, a = 1, b = "xyz"))

send(forward, (; msg = :what_ever, to = whisper, x = "boo"))


## ping pong

function pong_process()
    function (self::Mailbox) 
        while true
            rec(self, [msg(:ping) => m -> send(m[:from], (; msg = :pong, from = self, m = m))])
        end
    end
end


pong = spawn(pong_process());

echo = spawn(echo_process(:echo))

send(pong, (; msg = :ping, from = echo))


function ping_process(pong)
    function (self::Mailbox)
        send(pong, (; msg = :ping, from = self))
        rec(self, [(m -> m[:from] == pong) => m -> println("I got a pong - " * string(m))])
    end
end

# ping = spawn(ping_process(pong));


### end
