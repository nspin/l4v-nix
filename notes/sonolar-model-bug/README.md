The model SONOLAR produces with `$(cat context/resources/common.smt2 context/resources/get.smt2)` is inconsistent.
In particular, `$(cat context/resources/common.smt2 context/resources/check-sonolar.smt2)` is `unsat`.

```
$ make
image=$(docker build -f Dockerfile context -q) && \
        docker run --rm -it \
                $image \
                ./show.sh
>>> getting model from cvc4
sat
((rodata-witness (_ bv3758113836 32)) (rodata-witness-val (_ bv10485760 32)))
>>> getting model from sonolar
sat
((rodata-witness #b11100000000000011011010001010000)
(rodata-witness-val #b00000000000000000000000000000000))
>>> running cvc4 with model from cvc4
sat
>>> running cvc4 with model from sonolar
unsat
>>> running sonolar with model from cvc4
sat
>>> running sonolar with model from sonolar
unsat
```
