# curtain -- actors in the style of erlang processes

## latest

There is a problem with testing for a message being from a particular process, see a.jl::154

                             [msg(:zeta_reply) => # (m -> m[:from] == z) => 

The code above works as expected when several messages are sent before the zeta process has replied but the commented out code does not. It is fine for a single message but not if others are sent before the reply from zeta is received !?!?

On the other hand, see function `ping_process`.

## `Actor` and `Mailbox`

 - I tried to filter messages on a field :from in a message. In one message this was an Actor, in another it proved to be the mailbox of the actor. The test for equality of the two failed but this was not the behaviour I expected. Having both actors and mailboxes was the cause. Do away with actors, mailboxes alone will do. See `a.jl` and/or `b.jl`. The question now is whether or not to keep track of the task that is created in the function `spawn`.

 - `rec` has been rewritten to take a list of guard and body pairs, implemented as a vector of pair{function, function}, the first function being the guard and returning a boolean, the second the body that is passed the matching message. The syntax looks good, viz

```julia
rec(self,
    [msg(:please_forward) => m -> send(m[:to], (; msg = :forward, p = m)),
     (_ -> true) => m -> nothing])
```

the indenting could be better. See `a.jl` for other examples.

I will commit this lot as wip.


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

 - show methods for actors and mailboxes? a hash for a pid for a show method
 - timeout in rec, start a separate task to send a :timeout message to this mailbox or do I mean a timedwait?
 - how to get Mailbox{T} to work?


### end
