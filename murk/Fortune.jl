# Fortune.jl


module Fortune

export Process, rec, send, spawn, isstarted, isdone, isfailed, msg

mutable struct Process
    id::Symbol
    queue::Vector{Any}
    channel::Channel{Any}
    task::Task
end

Process(s::Symbol) = Process(s, Vector{Any}(), Channel{Any}(32), @task begin end)

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
    return message
end


nonnull(x) = !isnothing(x)
nonempty(x) = !isempty(x)


function rec(p, k; timeout = nothing)
    # this handling of timeouts is too naive and leads to a timeout message being scheduled for each call to `rec`. timeouts scheduled by previous calls will arrive and be earlier than expected for the current call - this is not the desired behaviour. a long running timeout process for each (normal) process?
    if !isnothing(timeout)
        t = @task begin sleep(timeout); send(p, (; msg = :timeout, timeout = timeout)) end
        schedule(t)
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
    return v
end


isstarted(p::Process) = istaskstarted(p.task)
isdone(p::Process) = istaskdone(p.task)
isfailed(p::Process) = istaskfailed(p.task)


msg(s) = m -> m[:msg] == s

end

### end
