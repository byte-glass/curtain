# curtain -- erlang style processes

## latest 
 - merge murk/Fortune.jl into Curtain.jl, get examples.jl working 

## next steps
 - [wip] merge murk/Fortune.jl
 - Mailbox{Any} -- how to write Mailbox{T} and pass in channel and queue capacity??

## Fortune.jl

This seems to work nicely!

Note: `rec` expects pairs of functions that _each_ expect a message, the first is the guard (and obviously takes a message as its argument), the second is the body i.e. what to do with the message that passed the guard -- in other words, it is a function that takes a message as its argument. 

If the body does not depend on the message beyond the fact that it has satisfied the guard then the body should be `_ -> ...`.

## `state_machine.jl`

[Now that I have figured out that body clauses _also_ expect a message!] this works quite nicely!

### The donkey is laughing its arse off!!

## The donkey is taking a good long look at me - the "nested rec" saga

[In `./murk/a.jl`] A guard `m -> m[:from] == z` in `from_process` caused an error (threw an exception?) when presented with a message _without_ a field `:from`. This caused the task to fail, the message in question was `(; msg = :x, t = tau())`.

This has been put right and it now runs without error, the fix `(m -> get(m, :from, false) == z)`

It should be kept in mind that checking equality against another process is _not a good idea_. That process could well have done its work, terminated successfully and been swept up. What would a test for equality yield then??

## contents

The module `Curtain` defines mailboxes and their behaviour. The definition of the function `spawn` explains much of what is going on here. 

```julia
function spawn(f::Function)
    b = Mailbox()
    t = @task begin f(b); end
    schedule(t)
    return b
end
```

It expects a function as its argument, that function takes a mailbox as its argument. A task is created to evaluate the function with a freshly created mailbox and the task is scheduled. It is the mailbox that is returned by the call to spawn. This means that processes (strictly speaking - mailboxes) can pass themselves in messages for example as the return address for a computation.

`examples.jl` has processes that echo messages, forward messages to another process and a pong process that returns a ping. A process can spawn a subprocess and delegate a computation to it, see `delegate.jl`.

## dir. `murk` 

### nested calls to `rec`

In erlang calls to `rec` can be nested. [In erlang it is a keyword rather than a function.] Here nested calls to `rec` lead to puzzling behaviour. In short, I suspect this leads to contention (or at the very least, confusion) over the mailbox that a task is running with. A task wakes up when a new message arrives in a channel. If that message does not satisfy a guard function in the call to rec, it will sit in the queue in the mailbox and the task may never get another chance to deal with it. See `nested.jl` if you are curious.

## see also

The file `notes.jl` covers an earlier version and problems with it in particular the behaviour of nested calls to `rec`.


#### end
