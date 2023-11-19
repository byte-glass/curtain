# Curtain.jl


module Curtain

export Process, rec, send, spawn, isstarted, isdone, isfailed, msg

mutable struct Process
    id::Symbol
    queue::Vector{Any}
    channel::Channel{Any}
    task::Task
    timer::Union{Nothing, Timer}
end

Process(s::Symbol) = begin
    t = @task begin end
    Process(s, Vector{Any}(), Channel{Any}(32), t, Timer(_ -> nothing, 0))
end

import Base.show
show(io::IO, p::Process) = show(io, p.id)

using Random

function spawn(f::Function, s = Symbol(lowercase(randstring(4))))
    p = Process(s)
    t = @task begin f(p); end
    schedule(t)
    p.task = t
    return p
end

function send(p::Process, message::Any)
    @info (; call = :put, p = p, message = message)
    put!(p.channel, message)
    return nothing # message
end


nonnull(x) = !isnothing(x)
nonempty(x) = !isempty(x)


function rec(p, k; timeout = nothing)
    if !isnothing(timeout)
        p.timer = Timer(_ -> send(p, (; msg = :timeout, timeout = timeout)), timeout)
    end
    while isready(p.channel)
        m = take!(p.channel)
        @info (; call = :take, p = p, m = m, ready = true)
        push!(p.queue, m)
    end
    found = false
    v = nothing
    m = nothing
    while !found
        j = copy(k)
        while nonempty(j) && !found
            kappa = popfirst!(j)
            r = findfirst(kappa.first, p.queue)
            if nonnull(r)
                found = true
                m = popat!(p.queue, r)
                v = kappa.second(m)
            end
        end
        if !found
            wait(p.channel)
            while isready(p.channel)
                m = take!(p.channel)
                @info (; call = :take, p = p, m = m, found = false)
                push!(p.queue, m)
            end
        end
    end
    if !isnothing(timeout)
        close(p.timer)
    end
    return v
end


isstarted(p::Process) = istaskstarted(p.task)
isdone(p::Process) = istaskdone(p.task)
isfailed(p::Process) = istaskfailed(p.task)


## convenience function for handling messages of the form
##
##      (; msg = :msg_type, payload = ... )
##

msg(s) = m -> m[:msg] == s

end

### end
