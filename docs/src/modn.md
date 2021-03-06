```@meta
CurrentModule = Singular
```

# Integers mod n

Integers mod $n$ are implemented via the Singular `n_Zn` type for any positive modulus
that can fit in a Julia `Int`.

The associated ring of integers mod $n$ is represented by a parent object which can
be constructed by a call to the `ResidueRing` constructor.

The types of the parent objects and elements of the associated rings of integers modulo
n are given in the following table according to the library providing them.

 Library        | Element type  | Parent type
----------------|---------------|--------------------
Singular        | `n_Zn`        | `Singular.N_ZnRing`

All integer mod $n$ element types belong directly to the abstract type `RingElem` and
all the parent object types belong to the abstract type `Ring`.

## Integer mod $n$ functionality

Singular.jl integers modulo $n$ implement the Ring and Residue Ring interfaces of
AbstractAlgebra.jl.

[https://nemocas.github.io/AbstractAlgebra.jl/rings.html](https://nemocas.github.io/AbstractAlgebra.jl/rings.html)

[https://nemocas.github.io/AbstractAlgebra.jl/residue_rings.html](https://nemocas.github.io/AbstractAlgebra.jl/residue_rings.html)

Parts of the Euclidean Ring interface may also be implemented, though Singular will
report an error if division is meaningless (even after cancelling zero divisors).

[https://nemocas.github.io/AbstractAlgebra.jl/euclidean.html](https://nemocas.github.io/AbstractAlgebra.jl/euclidean.html)

Below, we describe the functionality that is specific to the Singular integers mod $n$
ring and not already listed at the given links.

### Constructors

Given a ring $R$ of integers modulo $n$, we also have the following coercions in
addition to the standard ones expected.

```julia
R(n::n_Z)
R(n::fmpz)
```

Coerce a Singular or Flint integer value into the ring.

### Basic manipulation

```@docs
isunit(::n_Zn)
```

```@docs
Singular.characteristic(::N_ZnRing)
```

**Examples**

```
R = ResidueRing(ZZ, 26)
a = R(5)

isunit(a)
c = characteristic(R)
```

