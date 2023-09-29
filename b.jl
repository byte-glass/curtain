# b.jl


struct Mailbox
    q::Vector{Any}
    ch::Channel{Any}
    Mailbox() = new(Vector{Any}(), Channel{Any}(32))
end

nonnull(x) = !isnothing(x)
nonempty(x) = !isempty(x)

function rec(b, k)
    while isready(b.ch)
        push!(b.q, take!(b.ch))
    end
    found = false
    m = nothing
    while !found
        j = copy(k)
        while nonempty(j) && !found
            kappa = popfirst!(j)
            r = findfirst(kappa, b.q)
            if nonnull(r)
                found = true
                m = popat!(b.q, r)
            end
        end
        if !found
            wait(b.ch)
            while isready(b.ch)
                push!(b.q, take!(b.ch))
            end
        end
    end
    return m
end

function send(b::Mailbox, m::Any)
    put!(b.ch, m)
    return
end

function spawn(f::Function)
    b = Mailbox()
    t = @task begin f(b); end
    schedule(t)
    return (; task = t, mailbox = b)
end


##


msg(s) = m -> m[:msg] == s


function echo(b::Mailbox)
    while true
        m = rec(b, [_ -> true])
        print(string((; msg = :echo, p = m)) * "\n")
    end
end

echo_server = spawn(echo);

send(echo_server[:mailbox], "echo this!")
send(echo_server[:mailbox], (; msg = :are, p = "you there"))



##

function sink(b::Mailbox)
    while true
        rec(b, [_ -> false])
    end
end


sink_server = spawn(sink)

send(sink_server[:mailbox], (; m = "eat my shorts", p = 0))

sink_server[:mailbox]

##

function forward(b::Mailbox)
    m = rec(b, [msg(:please_forward)])
    send(m[:to], (; msg = :forward, p = m))
end

forwarder = spawn(forward)

echo_server = spawn(echo)
sink_server = spawn(sink)

send(forwarder[:mailbox], (; msg = :please_forward, to = echo_server[:mailbox], a = 1, b = "xyz"))
send(forwarder[:mailbox], (; msg = :please_forward, to = sink_server[:mailbox], a = 0, b = "it's all over!"))


##

function ping(b::Mailbox, s)
    send(s, (; msg = :ping, from = b, p = "this is a ping"))
    m = rec(b, [_ -> true])
    print(string((; received_q = m)) * "\n")
end

echo_server = spawn(echo)
pinger = spawn(b -> ping(b, echo_server[:mailbox]))

function pong(b::Mailbox) # , sink::Mailbox)
    while true
        m = rec(b, [msg(:ping)])
        m = (; msg = :pong, q = m)
        # send(sink, m)
        send(m[:from], m)
    end
end

sink_server = spawn(sink)

pong_server = spawn(b -> pong(b, sink_server[:mailbox]))

pinger = spawn(b -> ping(b, pong_server[:mailbox]))


m = (; msg = :ping, from = b, p = "whoaa")

msg(:pong)(m)

### end
