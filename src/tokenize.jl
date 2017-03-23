#======================================================================================
This is a set of functions for consistently tokenizing categorical values.

TODO for now there is no special handing of nulls
======================================================================================#


"""
    tokenmap(A[, tokentype=Int64, sort_values=true])

Tokenizes elements in the `Vector` or `NullableVector` `A` by creating a map between distinct
elements of `A` and tokens of type `tokentype`.  The mapping will be returned in the form
of a `Dict`.  If `sort_values`, the distinct values of `A` will be sorted before 
tokenization (so that the map is order-preserving).

**TODO:** Note that currently this doesn't do anything special to handle nulls.
"""
function tokenmap{T,K}(A::Union{Vector{T},NullableVector{T}}, ::Type{K}=Int64;
                       sort_values::Bool=false)
    u = unique(A)
    sort_values && sort!(u)
    t = zero(K)
    mapping = Dict{T,K}();  sizehint!(mapping, length(u))
    for i ∈ 0:(length(u)-1)
        mapping[u[i+1]] = t
        t += one(K)
    end
    mapping
end
export tokenmap


"""
    tokenize(A, mapping)
    tokenize(A[, tokentype=Int64, sort_values=true])

Returns a vector which is the result of applying the map returned by `tokenmap` (see 
documentation for that function) to elements of `A`.  This mapping can either be passed
explicitly as `mapping` or it can be generated if it is not passed.
"""
function tokenize{T,K}(A::Union{Vector{T},NullableVector{T}}, mapping::Dict{T,K})
    K[mapping[a] for a ∈ A]
end


function tokenize{T,K}(A::Union{Vector{T},NullableVector{T}}, ::Type{K}=Int64;
                       sort_values::Bool=false)
    mapping = tokenmap(A, K, sort_values=sort_values)
    tokenize(A, mapping)
end
export tokenize


"""
    detokenize(A, mapping[; is_inverse=false])

Inverts the tokenization of `A` (see `tokenmap` and `tokenize`).  The mapping provided is
assumed to be the forward mapping (from original objects to tokens) unless `is_inverse` in 
which case it is assumed to be the inverse mapping (i.e. from tokens to original objects).
"""
function detokenize{T,K}(A::Union{Vector{T},NullableVector{T}}, mapping::Dict{K,T};
                         is_inverse::Bool=false)
    if !is_inverse
        inv_mapping = invert(mapping)
    else
        inv_mapping = mapping
    end
    T[inv_mapping[a] for a ∈ A] 
end
export detokenize

