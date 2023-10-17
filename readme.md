# curtain -- erlang style processes

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

## nested calls to `rec`

In erlang calls to `rec` can be nested. [In erlang it is a keyword rather than a function.] Here nested calls to `rec` lead to puzzling behaviour. In short, I suspect this leads to contention (or at the very least, confusion) over the mailbox that a task is running with. A task wakes up when a new message arrives in a channel. If that message does not satisfy a guard function in the call to rec, it will sit in the queue in the mailbox and the task may never get another chance to deal with it. See `nested.jl` if you are curious.

## see also

The file `notes.jl` covers an earlier version and problems with it in particular the behaviour of nested calls to `rec`.


### end
