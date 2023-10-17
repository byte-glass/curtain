# b.jl

mutable struct Mailbox
    queue::Vector{Any}
    channel::Channel{Any}
    task::Task
    Mailbox() = new(Vector{Any}(), Channel{Any}(32))
end

## ??
##
## import Base.show
## define show(io:IO, ::MIME"text/plain"(), b::Mailbox) = ...
##

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
    b.task = t
    return b 
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

echo = spawn(echo_process(:echo))

m = (; msg = :ping, from = echo)

ping = spawn(ping_process(pong));


## nest

function zeta()
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

function nest(a::Mailbox)
    function (self::Mailbox)
        while true
            rec(self, 
                [msg(:z) => 
                     m -> begin
                         z = spawn(zeta())
                         send(z, (; msg = :zeta, from = self, k = "please hash this", p = m, t = tau()))
                         rec(self,
                             [msg(:zeta_reply) => #(m -> m[:from] == z) => 
                                  m -> begin
                                      send(a, (; msg = :nest_zeta, p = m, t = tau()))
                                  end])
                     end,
                 (_ -> true) => m -> send(a, (; msg = :nest, p = m, t = tau()))])
        end
    end
end

# function nid(a::Mailbox)
#     function (self::Mailbox)
#         while true
#             rec(self,
#                 [(_ -> true) =>
#                     m -> begin
#                     end
#         end
#     end
# end


_t0 = time()

function tau()
    round(time() - _t0; digits = 2)
end


a = echo_process(:vanilla) |> spawn;

p = nest(a) |> spawn;

begin
send(p, (; msg = :z, q = -1, t = tau()))
send(p, (; msg = :x, p = "xyz", t = tau()))
send(p, (; msg = :y, p = pi, t = tau()))
end

### end
