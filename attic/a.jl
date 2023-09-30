# a.jl


struct Mailbox
    q::Vector{Any}
    ch::Channel{Any}
    Mailbox() = new(Vector{Any}(), Channel{Any}(32))
end

send(b::Mailbox, m::Any) = put!(b.ch, m)
nonnull(x) = !isnothing(x)
nonempty(x) = !isempty(x)
key(s) = m -> m[1] == s

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



b = Mailbox()
m = nothing
t = @task begin; global m = rec(b, [key(:x), _ -> true]); println("ok"); end

schedule(t)

begin
send(b, (:a, "eat my shorts"))
send(b, (:a, "abc"))
send(b, (:a, "xyz"))
send(b, (:b, "beeu"))
end

begin
send(b, (:y, "yay!"))
send(b, (:x, "zesh!"))
end




function receive(b, k)
    while isready(b.ch)
        push!(b.q, take!(b.ch))
    end
    found = false
    m = nothing
    while !found 
        r = findfirst(k, b.q)
        println("r is $r")
        if isnothing(r)
            wait(b.ch)
            while isready(b.ch)
                push!(b.q, take!(b.ch))
            end
        else
            found = true
            m = popat!(b.q, r)
            println("m is $m")
        end
    end
    return (found, m)
end


key(s) = m -> m[1] == s


b = Mailbox()
m = nothing
t = @task begin; global m = receive(b, key(:b)); println("ok"); end

schedule(t)

begin
send(b, (:a, "eat my shorts"))
send(b, (:a, "abc"))
send(b, (:a, "xyz"))
send(b, (:b, "beeu"))
end




t = @task begin; sleep(5); println("done"); end

schedule(t)

schedule(t); wait(t)



b

take!(b.ch)



q = Vector()

push!(q, (:a, "abc"))
push!(q, (:a, "xyz"))
push!(q, (:b, "beeu"))

key(s) = m -> m[1] == s


r = findfirst(key(:b), q)

popat!(q, r)


### end
