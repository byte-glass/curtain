# a.jl

struct Mailbox
    queue::Vector{Any}
    channel::Channel{Any}
    Mailbox() = new(Vector{Any}(), Channel{Any}(32))
end

function send(b::Mailbox, message::Any)
    put!(b.channel, message)
    return
end

nonnull(x) = !isnothing(x)
nonempty(x) = !isempty(x)


function rec(b, k)
    while isready(b.channel)
        push!(b.queue, take!(b.channel))
    end
    found = false
    v = nothing
    m = nothing
    while !found
        j = copy(k)
        while nonempty(j) && !found
            kappa = popfirst!(j)
            r = findfirst(kappa.first, b.queue)
            if nonnull(r)
                found = true
                m = popat!(b.queue, r)
                v = kappa.second(m)
            end
        end
        if !found
            wait(b.channel)
            while isready(b.channel)
                push!(b.queue, take!(b.channel))
            end
        end
    end
    return v
end


# struct Process
#     mailbox::Mailbox
#     task::Task
# end
# 
# function send(a::Process, message::Any)
#     send(a.mailbox, message)
# end
        
function spawn(f::Function)
    b = Mailbox()
    t = @task begin f(b); end
    schedule(t)
    return b # Process(b, t)
end


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

msg(s) = m -> m[:msg] == s

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

function ping_process(pong)
    function (self::Mailbox)
        send(pong, (; msg = :ping, from = self))
        # p = rec(self, [msg(:pong) => m -> m])
        # p = rec(self, [(m -> m[:from] == pong.mailbox) => m -> m])
        p = rec(self, [(m -> m[:from] == pong) => m -> m])
        println(string(p))
    end
end

pong = spawn(pong_process());

# echo = spawn(echo_process(:echo))

# m = (; msg = :ping, from = echo)

ping = spawn(ping_process(pong));



### end
