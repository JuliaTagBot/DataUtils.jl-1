

# helper function for constrain
function _colconstraints!(col::Vector{Union{T,Null}}, bfunc::Function, keep::Vector{Bool}) where T
    for i ∈ 1:length(keep)
        if !isnull(col[i])
            keep[i] &= bfunc(get(col[i]))
        else
            keep[i] = false
        end
    end
    keep
end


# this is for fixing slowness due to bad dispatching
# performance is better, but it's still slow
function _dispatchConstrainFunc!(f::Function, mask::Union{Vector{Bool},BitArray},
                                 keep::BitArray, cols::Vector{Union{T,Null}}...) where T
    ncols = length(cols)
    # for some reason this completely fixes the performance issues
    # still don't completely understand why
    get_idx(i, j) = get(cols[j][i])
    get_args(i) = (get_idx(i, j) for j ∈ 1:ncols)
    # all arg cols are same length
    for i ∈ 1:length(keep)
        if !mask[i]
            keep[i] = false
        else
            # this is inexplicably slow
            # note that this is even true for the generator alone; not a dispatch issue
            # keep[i] = f((get(col[i]) for col ∈ cols)...)
            keep[i] = f(get_args(i)...)
        end
    end
end

"""
    constrain(df, dict)
    constrain(df, kwargs...)
    constrain(df, cols, func)

Returns a subset of the dataframe `df` for which the column `key` satisfies
`value(df[i, key]) == true`.  Where `(key, value)` are the pairs in `dict`.
Alternatively one can use keyword arguments instead of a `Dict`.

Also, one can pass a function the arguments of which are elements of columns specified
by `cols`.
"""
function constrain(df::AbstractDataFrame, 
                   constraints::Dict{K, V})::DataFrame where {K<:Symbol,V<:Function}
    keep = ones(Bool, size(df, 1))
    for (col, bfunc) ∈ constraints
        _colconstraints!(df[col], bfunc, keep)
    end
    df[keep, :]
end

function constrain{K, V<:Array}(df::AbstractDataFrame, constraints::Dict{K, V})::DataFrame
    newdict = Dict(k=>(x -> x ∈ v) for (k, v) ∈ constraints)
    constrain(df, newdict)
end

constrain(df::AbstractDataFrame; kwargs...) = constrain(df, Dict(kwargs))

function constrain(df::AbstractDataFrame, cols::Vector{Symbol}, f::Function)
    keep = BitArray(size(df, 1))
    _dispatchConstrainFunc!(f, completecases(df[cols]), keep, (df[col] for col ∈ cols)...)
    df[keep, :]
end
export constrain


# this is a helper function to @constrain
# TODO fix this so it works for variables used multiple times
function _checkConstraintExpr!(expr::Expr, dict::Dict)
    # the dictionary keys are the column names (as :(:col)) and the values are the symbols
    for (idx, arg) ∈ enumerate(expr.args)
        if isa(arg, QuoteNode)
            newsym = gensym()
            dict[Meta.quot(arg.value)] = newsym
            expr.args[idx] = newsym
        elseif  isa(arg, Expr) && arg.head == :quote
            newsym = gensym()
            dict[Meta.quot(arg.args[1])] = newsym
            expr.args[idx] = newsym
        elseif isa(arg, Expr)
            _checkConstraintExpr!(expr.args[idx], dict)
        end
    end
end

# TODO this is still having performance issues
"""
    @constrain(df, expr)

Constrains the dataframe to rows for which `expr` evaluates to `true`.  `expr` should
specify columns with column names written as symbols.  For example, to do `(a ∈ A) > M`
one should write `:A .> M`.
"""
macro constrain(df, expr)
    dict = Dict()
    _checkConstraintExpr!(expr, dict)
    cols = collect(keys(dict))
    vars = [dict[k] for k ∈ cols]
    cols_expr = Expr(:vect, cols...)
    fun_name = gensym()
    o = quote
        function $fun_name($(vars...))
            $expr
        end
        constrain($df, $cols_expr, $fun_name)
    end
    esc(o)
end
export @constrain



