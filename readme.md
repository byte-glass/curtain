# curtain -- actors in the style of erlang processes


## motivation

How much of the behaviour of erlang processes can be implemented in julia

## interesting (?) bug

My first version of `ping` had the following code

```julia
function ping(b::Mailbox, s)
    send(s, (; msg = :ping, from = b, p = "this is a ping"))
    m = rec(s, [_ -> true])
    ...
```

This is a curious bug. The argument `s` should be more properly named `pong_server` or something similar and if `b` were `self` it would be more informative (and accurate).

In my haste to receive a reply from the pong server, I've written `m = rec(s, ...`. It should be `m = rec(self, ...` and the receive should be on a condition such as `m -> m[:from] == pong_server`.

The code as it stands can send to `s` and then steal the message from `s` before the intended task gets a chance to even see it! Careless use of print statements made it hard to spot that this was indeed going on.

The moral of the story - don't code in a hurry and use structured messages.

### possible remedies

 - style - make `self::Mailbox` the customary first argument of a funcion intended to become an actor in the hope that `self` will be obvious enough when reading the code
 - define a closure over the mailbox as a local function and use that rather than `rec` e.g.

```julia
function pong(b::Mailbox, ...
    receive(args...) = rec(b, args...)
    ...
    m = receive([_ -> true])

    ...
```

## next steps
 - Curtain.jl?
 - test nested rec
 - show methods for actors and mailboxes?
 - timeout in rec, start a separate task to send a :timeout message to this mailbox or do I mean a timedwait?
 - how to get Mailbox{T} to work?

### end
