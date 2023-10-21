# murk

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


### end
