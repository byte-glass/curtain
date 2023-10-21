# Curtain.jl

module Curtain

export Mailbox, rec, send, spawn, msg

using Random


struct Mailbox
    id::Symbol
    queue::Vector{Any}
    channel::Channel{Any}
end

Mailbox(s::Symbol) = Mailbox(s, Vector{Any}(), Channel{Any}(32))
# Mailbox() = Mailbox(lowercase(randstring(4)), Vector{Any}(), Channel{Any}(32))

import Base.show
show(io::IO, b::Mailbox) = show(io, b.id)

function send(b::Mailbox, message::Any)
    @info (; call = :send, to = b, message = message)
    put!(b.channel, message)
    return
end

nonnull(x) = !isnothing(x)
nonempty(x) = !isempty(x)


function rec(b, k)
#     @info (; call = :rec, b = b, is_ready = isready(b.channel))
#     while isready(b.channel)
#         push!(b.queue, take!(b.channel))
#     end
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
                m = take!(b.channel)
                push!(b.queue, m)
                @info (; call = :rec_push, b = b, m = m)
            end
        end
    end
    @info (; call = :rec_return, b = b, m = m, v = v)
    return v
end

        
function spawn(f::Function, s = Symbol(lowercase(randstring(4))))
    b = Mailbox(s)
    t = @task begin f(b); end
    schedule(t)
    return b
end

## convenience function for handling messages of the form
##
##      (; msg = :msg_type, payload = ... )
##

msg(s) = m -> m[:msg] == s



end


### end
