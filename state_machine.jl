#! /bin/env julia

# state_machine.jl

## usage 
#
#   $ JULIA_LOAD_PATH="$JULIA_LOAD_PATH:$(pwd)" ./state_machine.jl
#
# or
#
#   $ TERM=dumb JULIA_LOAD_PATH="$JULIA_LOAD_PATH:$(pwd)" rlwrap -a julia [-i state_machine.jl]


using Curtain

function a(self::Process, n)
    rec(self,
        [msg(:a) => _ -> (a, n + 1)
         msg(:b) => _ -> (b, n)
         msg(:x) => _ -> (x, 0)])
end

function b(self::Process, n)
    rec(self,
        [msg(:a) => _ -> (a, n)
         msg(:b) => _ -> (b, n - 1)
         msg(:x) => _ -> (x, 0)])
end

function x(self::Process)
    (x, 0)
end

## echo

function echo_process()
    function (self::Process)
        while true
            rec(self, 
                [(_ -> true) => 
                    m -> @info (; echo = m)])
        end
    end
end

function state_machine_process(echo)
    function (self::Process)
        n = 0
        state = a
        while state != x
            state, n = state(self, n)
            send(echo, (; process = :state_machine_process, state = state, n = n))
        end
    end
end


echo = spawn(echo_process(), :echo);

m = spawn(state_machine_process(echo), :state_machine);
 
# send(m, (; msg = :a));
# send(m, (; msg = :b));
# send(m, (; msg = :x));


### end
