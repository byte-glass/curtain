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

This is a curious bug. The argument `s` should be more properly named `pong_server` or something similar and if `b` were `self`, it would be more informative.

In my haste to receive a reply from the pong server, I've written `m = rec(s, ...`. It should be `m = rec(self, ...` and the receive should be on a condition such as `m -> m[:from] == pong_server`.

The code as it stands can send to `s` and then steal the message from `s` before the intended task gets a chance to even see it! Careless use of print statements made it hard to spot that this was indeed going on.

The moral of the story - don't code in a hurry and use structured messages.


## next steps
 - timeout in rec, start a separate task to send a :timeout message to this mailbox or do I mean a timedwait?
 = tidy up a.jl

### end