export jet, minimal_generating_set, hilbert_series, ModuleClass, rank, 
       smodule, slimgb

###############################################################################
#
#   Basic manipulation
#
###############################################################################

parent(a::smodule{T}) where T <: Nemo.RingElem = ModuleClass{T}(a.base_ring)

base_ring(S::ModuleClass) = S.base_ring

base_ring(I::smodule) = I.base_ring

elem_type(::ModuleClass{T}) where T <: AbstractAlgebra.RingElem = smodule{T}

elem_type(::Type{ModuleClass{T}}) where T <: AbstractAlgebra.RingElem = smodule{T}

parent_type(::Type{smodule{T}}) where T <: AbstractAlgebra.RingElem = ModuleClass{T}


@doc Markdown.doc"""
    ngens(I::smodule)
> Return the number of generators in the current representation of the module (as a list
> of vectors).
"""
ngens(I::smodule) = I.ptr == C_NULL ? 0 : Int(libSingular.ngens(I.ptr))

@doc Markdown.doc"""
    rank(I::smodule)
> Return the rank $n$ of the ambient space $R^n$ of which this module is a submodule.
"""
rank(I::smodule) = Int(libSingular.rank(I.ptr))

function checkbounds(I::smodule, i::Int)
   (i > ngens(I) || i < 1) && throw(BoundsError(I, i))
end

function getindex(I::smodule{T}, i::Int) where T <: AbstractAlgebra.RingElem
   checkbounds(I, i)
   R = base_ring(I)
   p = libSingular.getindex(I.ptr, Cint(i - 1))
   return svector{T}(R, rank(I), libSingular.p_Copy(p, R.ptr))
end

@doc Markdown.doc"""
    iszero(p::smodule)
> Return `true` if this is algebraically the zero module.
"""
iszero(p::smodule) = Bool(libSingular.idIs0(p.ptr))

function deepcopy_internal(I::smodule, dict::IdDict)
   R = base_ring(I)
   ptr = libSingular.id_Copy(I.ptr, R.ptr)
   return Module(R, ptr)
end

function hash(M::smodule, h::UInt)
   v = 0x403fd5a7748e75c9%UInt
   for i in 1:ngens(M)
      v = xor(hash(M[i], h), v)
   end
   return v
end

###############################################################################
#
#   String I/O
#
###############################################################################

function show(io::IO, S::ModuleClass)
   print(io, "Class of Singular Modules over ")
   show(io, base_ring(S))
end

function show(io::IO, I::smodule)
   print(io, "Singular Module over ")
   show(io, base_ring(I))
   println(io,", with Generators:")
   n = ngens(I)
   for i = 1:n
      show(io, I[i])
      if i != n
         println(io, "")
      end
   end
end

###############################################################################
#
#   Groebner basis
#
###############################################################################

@doc Markdown.doc"""
    std(I::smodule; complete_reduction::Bool=false)
> Compute the Groebner basis of the module $I$. If `complete_reduction` is
> set to `true`, the result is unique, up to permutation of the generators
> and multiplication by constants. If not, only the leading terms are unique
> (up to permutation of the generators and multiplication by constants, of
> course). Presently the polynomial ring used must be over a field or over
> the Singular integers.
"""
function std(I::smodule; complete_reduction::Bool=false)
   R = base_ring(I)
   ptr = libSingular.id_Std(I.ptr, R.ptr, complete_reduction)
   libSingular.idSkipZeroes(ptr)
   z = Module(R, ptr)
   z.isGB = true
   return z
end

@doc Markdown.doc"""
   slimgb(I::smodule; complete_reduction::Bool=false)
> Given a module $I$ this function computes a Groebner basis for it.
> Compared to `std`, `slimgb` uses different strategies for choosing
> a reducer.
>
> If the optional parameter `complete_reduction` is set to `true` the
> function computes a reduced Gröbner basis for $I$.
"""
function slimgb(I::smodule; complete_reduction::Bool=false)
   R = base_ring(I)
   ptr = libSingular.id_Slimgb(I.ptr, R.ptr, complete_reduction)
   libSingular.idSkipZeroes(ptr)
   z = Module(R, ptr)
   z.isGB = true
   return z
end

###############################################################################
#
#   Syzygies
#
###############################################################################

@doc Markdown.doc"""
    syz(M::smodule)
> Compute the module of syzygies of the given module. This will be given as
> a set of generators in an ambient space $R^n$, where $n$ is the number of
> generators in $M$.
"""
function syz(M::smodule)
   R = base_ring(M)
   ptr = libSingular.id_Syzygies(M.ptr, R.ptr)
   libSingular.idSkipZeroes(ptr)
   return Module(R, ptr)
end

###############################################################################
#
#   Resolutions
#
###############################################################################

@doc Markdown.doc"""
    sres{T <: Nemo.RingElem}(I::smodule{T}, max_length::Int)
> Compute a free resolution of the given module $I$ of length up to the given
> maximum length. If `max_length` is set to zero, a full length free
> resolution is computed. Each element of the resolution is itself a module.
"""
function sres(I::smodule{T}, max_length::Int) where T <: Nemo.RingElem
   I.isGB == false && error("Not a Groebner basis ideal")
   R = base_ring(I)
   if max_length == 0
        max_length = nvars(R)
        # TODO: consider qrings
   end
   r, minimal = libSingular.id_sres(I.ptr, Cint(max_length + 1), R.ptr)
   return sresolution{T}(R, r, minimal)
end

###############################################################################
#
#   Module constructors
#
###############################################################################

function Module(R::PolyRing{T}, vecs::svector{spoly{T}}...) where T <: Nemo.RingElem
   S = elem_type(R)
   return smodule{S}(R, vecs...)
end

function Module(R::PolyRing{T}, id::libSingular.idealRef) where T <: Nemo.RingElem
   S = elem_type(R)
   return smodule{S}(R, id)
end

###############################################################################
#
#   Differential functions
#
###############################################################################

@doc Markdown.doc"""
   jet(M::smodule, n::Int)
> Given a module $M$ this function truncates the generators of $M$
> up to degree $n$.
"""
function jet(M::smodule, n::Int)
      R = base_ring(M)
      ptr = libSingular.id_Jet(M.ptr, Cint(n), R.ptr)
      libSingular.idSkipZeroes(ptr)
      return Module(R, ptr)
end

###############################################################################
#
#   Functions for local rings
#
###############################################################################

@doc Markdown.doc"""
   minimal_generating_set(M::smodule)
> Given a module $M$ in ring $R$ with local ordering, this returns an array
> containing the minimal generators of $M$.
"""
function minimal_generating_set(M::smodule)
   R = base_ring(M)
   if has_global_ordering(R) || has_mixed_ordering(R)
      error("Ring needs local ordering.")
   end
   N = Singular.Module(R, Singular.libSingular.idMinBase(M.ptr, R.ptr))
   return [N[i] for i in 1:ngens(N)]
end

###############################################################################
#
#   Hilbert - Poincare Series
#
###############################################################################

@doc Markdown.doc"""
    hilbert_series(I::smodule{spoly{T}}, S::PolyRing; number::Int=1,
    ring_weights::Array{Int, 1})
> The function returns the numerator of the Hilbert-Poincaré series of
> $R/L(I)$, where $R$ is the parent ring of $I$ and $L(I)$ is the leading ideal
> of $I$. By default, the algorithm computes the first Hilbert series.
> Setting the optional argument 'number' to $2$, the second series is computed.
> Passing an integer array of weights for the variables of $R$ respectively,
> for the basis vectors $e_i$ of the ambient free module of $I$, the grading
> is computed with respect to these weights. 
> By default, the standard grading is used.
> In case the ideal is homogeneous, the Hilbert-Poincaré series of $R/L(I)$ is
> computed.
> The result is returned in the univariate polynomial ring S, which has to be
> over ZZ.
"""
function hilbert_series(I::smodule{spoly{T}}, S::PolyRing; number::Int=1, ring_weights::Array{Int, 1} = Array{Int, 1}(), module_weights::Array{Int, 1} = Array{Int, 1}()) where T <: Union{Field, Nemo.FieldElem}

   nvars(S) != 1 && error("Ring has to be univariate")

   S.base_ring != ZZ && error("Ring has to be over ZZ")

  if number == 1
    ha = hilbert_first_series(I, ring_weights=ring_weights)
  else
    ha = hilbert_second_series(I, ring_weights=ring_weights)
  end

  hs = S(0)
  t = gen(S, 1)

  for i in 1:length(ha)-1
    hs = hs + ha[i]*t^i
  end
  return hs
end

@doc Markdown.doc"""
    hilbert_series(I::smodule{spoly{T}}; number::Int=1,
    ring_weights::Array{Int, 1})
> The function returns the numerator of the Hilbert-Poincaré series of
> $R/L(I)$, where $R$ is the parent ring of $I$ and $L(I)$ is the leading ideal
> of $I$. By default, the algorithm computes the first Hilbert series.
> Setting the optional argument 'number' to $2$, the second series is computed.
> Passing an integer array of weights for the variables of $R$ respectively,
> for the basis vectors $e_i$ of the ambient free module of $I$, the grading
> is computed with respect to these weights. 
> By default, the standard grading is used.
> In case the ideal is homogeneous, the Hilbert-Poincaré series of $R/L(I)$ is
> computed.
"""
function hilbert_series(I::smodule{spoly{T}}; number::Int=1, ring_weights::Array{Int, 1} = Array{Int, 1}(), module_weights::Array{Int, 1} = Array{Int, 1}()) where T <: Union{Field, Nemo.FieldElem}
  S, = PolynomialRing(ZZ, ["t"])
  return hilbert_series(I, S, number = number, ring_weights = ring_weights)
end

function hilbert_first_series(I::smodule; ring_weights::Array{Int, 1} = Array{Int, 1}(), module_weights::Array{Int, 1} = Array{Int, 1}())

  !I.isGB && error("Not a Groebner basis.")

  R = base_ring(I)
  n = nvars(R)
  r = rank(I)

  length(ring_weights) != 0 && length(ring_weights) != n && error("Ring weights have wrong length.")

  length(module_weights) != 0 && !iszero(I) && length(ring_weights) != r && error("Module weights have wrong length.")

  rw = Cint.(ring_weights)
  mw = Cint.(module_weights)
  res = Array{Int32, 1}()
  libSingular.hFirstSeries(I.ptr, R.ptr, rw, mw, res)
  return res
end

function hilbert_second_series(I::smodule; ring_weights::Array{Int, 1} = Array{Int, 1}(), module_weights::Array{Int, 1} = Array{Int, 1}())

  h1 = hilbert_first_series(I; ring_weights = ring_weights, module_weights = module_weights)
  res = Array{Int32, 1}()
  libSingular.hSecondSeries(h1, res)
  return res
end

