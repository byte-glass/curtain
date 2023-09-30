# examples.jl

## usage 
#
#   $ JULIA_LOAD_PATH="$JULIA_LOAD_PATH:$(pwd)" julia [-i examples.jl]
#

using Curtain


## echo

function echo(b::Mailbox)
    while true
        m = rec(b, [_ -> true])
        print(string((; msg = :echo, p = m)) * "\n")
    end
end

echo_server = spawn(echo);

send(echo_server.mailbox, "echo this!")
send(echo_server, (; msg = :are, p = "you there"))


## sink

function sink(b::Mailbox)
    while true
        rec(b, [_ -> false])
    end
end

sink_server = spawn(sink)

send(sink_server, (; m = "eat my shorts", p = 0))
send(sink_server, (; m = "whaaaaa??", p = -1))

sink_server.mailbox.queue


## forward

msg(s) = m -> m[:msg] == s

function forward(b::Mailbox)
    m = rec(b, [msg(:please_forward)])
    send(m[:to], (; msg = :forward, p = m))
end

forwarder = spawn(forward)
echo_server = spawn(echo)
send(forwarder, (; msg = :please_forward, to = echo_server, a = 1, b = "xyz"))

forwarder = spawn(forward)
sink_server = spawn(sink)
send(forwarder, (; msg = :please_forward, to = sink_server, a = 0, b = "it's all over!"))

sink_server.mailbox.queue


## ping pong

function ping(self::Mailbox, pong)
    send(pong, (; msg = :ping, from = self, p = "this is a ping"))
    m = rec(self, [_ -> true])
    print(string((; received = m)) * "\n")
end

echo_server = spawn(echo)
pinger = spawn(b -> ping(b, echo_server)); # without `;` the output in the repl is messy!


function pong(self::Mailbox) 
    while true
        m = rec(self, [msg(:ping)])
        send(m[:from], (; msg = :pong, q = m))
    end
end


pong_server = spawn(pong)

sink_server = spawn(sink)
send(pong_server, (; msg = :ping, from = sink_server, p = "sink this"))
sink_server.mailbox.queue

echo_server = spawn(echo)
send(pong_server, (; msg = :ping, from = echo_server, p = "echo this and that"))

pinger = spawn(b -> ping(b, pong_server)); # see comment above



### end
