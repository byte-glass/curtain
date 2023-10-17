# Curtain.jl

module Curtain

export Mailbox, rec, send, spawn


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

        
function spawn(f::Function)
    b = Mailbox()
    t = @task begin f(b); end
    schedule(t)
    return b
end


end


### end
