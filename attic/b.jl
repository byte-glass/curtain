# b.jc


struct Mailbox
    queue::Vector{Any}
    channel::Channel{Any}
    Mailbox() = new(Vector{Any}(), Channel{Any}(32))
end

nonnull(x) = !isnothing(x)
nonempty(x) = !isempty(x)

function rec(b, k)
    while isready(b.channel)
        push!(b.queue, take!(b.channel))
    end
    found = false
    m = nothing
    while !found
        j = copy(k)
        while nonempty(j) && !found
            kappa = popfirst!(j)
            r = findfirst(kappa, b.queue)
            if nonnull(r)
                found = true
                m = popat!(b.queue, r)
            end
        end
        if !found
            wait(b.channel)
            while isready(b.channel)
                push!(b.queue, take!(b.channel))
            end
        end
    end
    return m
end

function send(b::Mailbox, message::Any)
    put!(b.channel, message)
    return
end

struct Actor
    mailbox::Mailbox
    task::Task
end

function send(a::Actor, message::Any)
    send(a.mailbox, message)
end
        
function spawn(f::Function)
    b = Mailbox()
    t = @task begin f(b); end
    schedule(t)
    return Actor(b, t)
end


##


function echo(b::Mailbox)
    while true
        m = rec(b, [_ -> true])
        print(string((; msg = :echo, p = m)) * "\n")
    end
end

echo_server = spawn(echo);

send(echo_server.mailbox, "echo this!")
send(echo_server, (; msg = :are, p = "you there"))


##

function sink(b::Mailbox)
    while true
        rec(b, [_ -> false])
    end
end


sink_server = spawn(sink)

send(sink_server, (; m = "eat my shorts", p = 0))
send(sink_server, (; m = "whaaaaa??", p = -1))

sink_server.mailbox


##

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


##

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

echo_server = spawn(echo)
send(pong_server, (; msg = :x, from = echo_server, p = "echo this"))

pinger = spawn(b -> ping(b, pong_server)); # see comment above


m = (; msg = :ping, from = b, p = "whoaa")

msg(:pong)(m)

### end
