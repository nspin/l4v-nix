- ExprTypeHtd vs ExprTypeHTD
- Integer vs prims
- rm void and _ <-
- unwrapXyz -> unwrap
- Function a (Function Maybe, Function Identity)

- smt:
    - https://hackage.haskell.org/package/simple-smt
        - most appropriate, used by cryptol
    - https://hackage.haskell.org/package/smtlib2
    - https://hackage.haskell.org/package/hasmtlib
    -     https://github.com/bruderj15/Hasmtlib
    - https://hackage.haskell.org/package/smtlib-backends
    -     https://github.com/tweag/smtlib-backends
    - https://hackage.haskell.org/package/what4

- mtl alternative:
    - free
        - https://blog.ocharles.org.uk/posts/2020-12-23-monad-transformers-and-effects-with-backpack.html
        - https://degoes.net/articles/modern-fp
        - performance:
            - https://markkarpov.com/post/free-monad-considered-harmful.html
            - requires https://hackage.haskell.org/package/kan-extensions-5.2.6?
    - extensible-effects
        - https://reasonablypolymorphic.com/blog/freer-monads/
        - https://okmij.org/ftp/Haskell/extensible/
        - https://okmij.org/ftp/Haskell/extensible/more.pdf
    - capability (few users)

- create:
    - simple-smt-abstract
        - MonadSMT that combines 'simple-smt' and 'async'

- structure:
    - stage 1: one package with BV.Core, BV.System, and BV.Test
    - stage 2: multiple different packages

- stm solver interaction abstraction:
    - https://hackage.haskell.org/package/lifted-async-0.10.2.7
    - https://hackage.haskell.org/package/lifted-stm-0.2.0.1
