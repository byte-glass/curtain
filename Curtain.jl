# Curtain.jl

module Curtain

export Mailbox, rec, send, Actor, spawn

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


end

### end
