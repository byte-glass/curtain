# murk

## latest
 - a workable implementation of timeouts, see `timeouts.jl` for examples

## contents
 - Fortune.jl -- current version of `Process` etc
 - Curtain.jl -- previous version
 - timeout.jl -- examples of timeouts
 - a.jl, x.jl and nested.jl -- various versions of nested `rec` calls, could do with tidying up!

## module Tau

or BigBen to allow `t = tau()` in logging in the module Curtain and e.g. x.jl

## other ways to break `rec`

Two calls to `rec` in series,

```julia
rec(self,
    [msg(:a) => ... ; sleep(2); ])
rec(self,
    [msg(:b) => ... ])
```

and send plenty of `(; msg = :b, ...` before a `(; msg = :a)`

## a catcher process for testing

need a timeout, if messages :a and :b haven't arrived after a reasonable amount of time, fail loudly e.g.

```julia
rec(self, [msg(:a) => true, (_ -> true) => assert(false)], timeout = 2)
rec(self, [msg(:b) => true, (_ -> true) => assert(false)], timeout = 2)
```

or possibly,

```julia
for m in [:a, :b]
    rec(self, [msg(m) => true, (_ -> true) => assert(false)], timeout = 2)
end
```

and `[:a, :b]` could be an argument to a function `catcher_process`

### end
