
"""
## DataUtils
`DataUtils` provides the following new constructors for `Dict`:

    Dict(keys, values)
    Dict(df, keycol, valcol)

One can provide `Dict` with (equal length) vector arguments.  The first
vector provides a list of keys, while the second provides a list of values.
If the vectors are `NullableVector`, only key, value pairs with *both* their
elements non-null will be added.
"""
function Dict{K, V}(keys::Vector{K}, values::Vector{V})::Dict
    @assert length(keys) == length(values) ("Vectors for constructing 
                                             Dict must be of equal length.")
    Dict(k=>v for (k, v) ∈ zip(keys, values))
end

function Dict{K, V}(keys::NullableVector{K}, values::NullableVector{V})::Dict
    @assert length(keys) == length(values) ("Vectors for constructing
                                             Dict must be of equal length.")
    dict = Dict{K, V}()
    size_ = sum(!isnull(k) && !isnull(v) ? 1 : 0 for (k, v) ∈ zip(keys, values))::Integer
    sizehint!(dict, size_)
    # we only insert pairs if both values are not null
    for (k, v) ∈ zip(keys, values)
        if !isnull(k) && !isnull(v)
            dict[get(k)] = get(v)
        end
    end
    return dict
end

function Dict(df::DataTable, keycol::Symbol, valcol::Symbol)::Dict
    Dict(df[keycol], df[valcol])
end
export Dict


