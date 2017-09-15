

"""
convert(NullableArray{T<:Integer,N}, a)

This converts a column of floats that should have been ints, but got converted to
floats because it has missing values which were converted to NaN's.
The supplied `NullableArray` should have eltype `Float32` or `Float64`.
"""
function convert{T<:Integer,N,K<:AbstractFloat}(::Type{NullableArray{T,N}},
                                                a::NullableArray{K})
    NullableArray([isnan(x) ? Nullable() : convert(dtype, x) for x in a])
end
export convert



"""
    shuffle!(df::DataFrame)

Shuffles a dataframe in place.
"""
function Base.shuffle!(df::DataFrame)
    permutation = shuffle(collect(1:size(df)[1]))
    tdf = copyColumns(df)
    for i in 1:length(permutation)
        df[i, :] = tdf[permutation[i], :]
    end
    return df
end
export shuffle!


"""
    convertNulls!{T}(A::Array{T, 1}, newvalue::T)

Converts all null values (NaN's and Nullable()) to a particular value.
Note this has to check whether the type is Nullable.
"""
function convertNulls!{T <: AbstractFloat}(A::Vector{T}, newvalue::T)
    for i in 1:length(A)
        if isnan(A[i])
            A[i] = newvalue
        end
    end
    return A
end

function convertNulls!{T <: Nullable}(A::Vector{T}, newvalue::T)
    for i in 1:length(A)
        if isnull(A[i])
            A[i] = newvalue
        end
    end
    return A
end

export convertNulls!


"""
    convertNulls{T}(A, newvalue)

Converts all null vlaues (NaN's and Nullable()) to a particular value.
This is a wrapper added for sake of naming consistency.
"""
function convertNulls{T}(A::NullableArray{T}, newvalue::T)
    convert(Array, A, newvalue)
end
export convertNulls


"""
    convertNulls!(df::DataFrame, cols::Vector{Symbol}, newvalue::Any)

Convert all null values in columns of a DataFrame to a particular value.

There is also a method for passing a single column symbol, not as a vector.
"""
function convertNulls!(df::DataFrame, cols::Vector{Symbol}, newvalue::Any)
    for col in cols
        df[col] = convertNulls(df[col], newvalue)
    end
    return
end
convertNulls!(df::DataFrame, col::Symbol, newvalue) = convertNulls!(df, [col], newvalue)
export convertNulls!


"""
    copyColumns(df::DataFrame)

The default copy method for dataframes only copies one level deep, so basically it stores
an array of columns.  If you assign elements of individual (column) arrays then, it can
make changes to references of those arrays that exist elsewhere.

This method instead creates a new dataframe out of copies of the (column) arrays.

This is not named copy due to the fact that there is already an explicit copy(::DataFrame)
implementation in dataframes.

Note that deepcopy is recursive, so this is *NOT* the same thing as deepcopy(df), which
copies literally everything.
"""
function copyColumns(df::DataFrame)
    ndf = DataFrame()
    for col in names(df)
        ndf[col] = copy(df[col])
    end
    return ndf
end
export copyColumns


"""
    applyCatConstraints(dict, df[, kwargs])

Returns a copy of the dataframe `df` with categorical constraints applied.  `dict` should
be a dictionary with keys equal to column names in `df` and values equal to the categorical
values that column is allowed to take on.  For example, to select gauge bosons we can
pass `Dict(:PID=>[i for i in 21:24; -24])`.  Alternatively, the values in the dictionary
can be functions which return boolean values, in which case the returned dataframe will
be the one with column values for which the functions return true.

Note that this requires that the dictionary values are either `Vector` or `Function`
(though one can of course mix the two types).

Alternatively, instead of passing a `Dict` one can pass keywords, for example
`applyCatConstraints(df, PID=[i for i in 21:24; -24])`.
"""
function applyCatConstraints(dict::Dict, df::DataFrame)
    constr = Bool[true for i in 1:size(df)[1]]
    for (col, values) in dict
        constr &= if typeof(values) <: Vector
            convert(BitArray, map(x -> x ∈ values, df[col]))
        elseif typeof(values) <: Function
            convert(BitArray, map(values, df[col]))
        else
            throw(ArgumentError("Constraints must be either vectors or functions."))
        end
    end
    return df[constr, :]
end

function applyCatConstraints(df::DataFrame; kwargs...)
    dct = Dict(kwargs)
    applyCatConstraints(dct, df)
end
export applyCatConstraints


"""
    randomData(dtypes...; nrows=10^4)

Creates a random dataframe with columns of types specified by `dtypes`.  This is useful
for testing various dataframe related functionality.
"""
function randomData(dtypes::DataType...; nrows::Integer=10^4,
                      names::Vector{Symbol}=Symbol[])::DataFrame
    df = DataFrame()
    for (idx, dtype) in enumerate(dtypes)
        col = Symbol(string("col_", idx))
        if dtype <: Real
            df[col] = rand(dtype, nrows)
        elseif dtype <: AbstractString
            df[col] = [randstring(rand(8:16)) for i in 1:nrows]
        elseif dtype <: Dates.TimeType
            df[col] = [dtype(now()) + Dates.Day(i) for i in 1:nrows]
        elseif dtype <: Symbol
            df[col] = [Symbol(randstring(rand(4:12))) for i in 1:nrows]
        end
    end
    if length(names) > 0
        names!(df, names)
    end
    return df
end
export randomData


nans2nulls!(X::NullableArray) = (X[find(isnan(X))] .= Nullable(); X)
nans2nulls!(data::DataFrame, col::Symbol) = nans2nulls!(data[col])


"""
    nans2nulls(col)
    nans2nulls(df, colname)

Converts all `NaN`s appearing in the column to `Nullable()`.  The return
type is `NullableArray`, even if the original type of the column is not.
"""
nans2nulls(col::NullableArray) = nans2nulls!(copy(col))

nans2nulls(col::AbstractVector) = nans2nulls!(convert(NullableArray, col))

nans2nulls(df::DataFrame, col::Symbol) = nans2nulls(df[col])
export nans2nulls


"""
    getCategoryVector(A, vals[, dtype])

Get a vector which is 1 for each `a ∈ A` that satisfies `a ∈ vals`, and 0 otherwise.
If `A` is a `NullableVector`, any null elements will be mapped to 0.

Optionally, one can specify the datatype of the output vector.
"""
function getCategoryVector{T, U}(A::Vector{T}, vals::Vector{T}, ::Type{U}=Int64)
    # this is for efficiency
    valsdict = Dict{T, Void}(v=>nothing for v ∈ vals)
    Vector{U}([a ∈ keys(valsdict) for a ∈ A])
end

function getCategoryVector{T, U}(A::NullableVector{T}, vals::Vector{T}, ::Type{U}=Int64)
    # this is for efficiency
    valsdict = Dict{T, Void}(v=>nothing for v ∈ vals)
    o = map(a -> a ∈ keys(valsdict), A)
    # these nested converts are the result of incomplete NullableArrays interface
    convert(Array{U}, convert(Array, o, 0))
end

function getCategoryVector{T, U}(A::Vector{T}, val::T, ::Type{U}=Int64)
    getCategoryVector(A, [val], U)
end

function getCategoryVector{T, U}(A::NullableVector{T}, val::T, ::Type{U}=Int64)
    getCategoryVector(A, [val], U)
end

function getCategoryVector{U}(df::AbstractDataFrame, col::Symbol, vals::Vector, ::Type{U}=Int64)
    getCategoryVector(df[col], vals, U)
end

function getCategoryVector{U}(df::AbstractDataFrame, col::Symbol, val, ::Type{U}=Int64)
    getCategoryVector(df[col], [val], U)
end
export getCategoryVector


"""
    getUnwrappedColumnElTypes(df[, cols=[]])

Get the element types of columns in a dataframe.  If the element types are `Nullable`,
instead give the `eltype` of the `Nullable`.  If `cols=[]` this will be done for
all columns in the dataframe.
"""
function getUnwrappedColumnElTypes(df::DataFrame, cols::Vector{Symbol}=Symbol[])
    if length(cols) == 0
        cols = names(df)
    end
    [et <: Nullable ? eltype(et) : et for et ∈ eltypes(df[cols])]
end
export getUnwrappedColumnElTypes


"""
    getMatrixDict([T,] df, keycols, datacols)

Gets a dictionary the keys of which are the keys of a groupby of `df` by the columns
`keycols` and the values of which are the matrices produced by taking `sdf[datacols]`
of each `SubDataFrame` `sdf` in the groupby.  Note that the keys are always tuples
even if `keycols` only has one element.

If a type `T` is provided, the output matrices will be of type `Matrix{T}`.
"""
function getMatrixDict(df::DataFrame, keycols::Vector{Symbol}, datacols::Vector{Symbol})
    keycoltypes = getUnwrappedColumnElTypes(df, keycols)
    dict = Dict{Tuple{keycoltypes...},Matrix}()
    for sdf ∈ groupby(df, keycols)
        key = tuple(convert(Array{Any}, sdf[1, keycols])...)
        dict[key] = convert(Array, sdf[datacols])
    end
    dict
end

function getMatrixDict{T}(::Type{T}, gdf::GroupedDataFrame, keycols::Vector{Symbol},
                          datacols::Vector{Symbol})
    keycoltypes = getUnwrappedColumnElTypes(gdf.parent, keycols)
    dict = Dict{Tuple{keycoltypes...},Matrix{T}}()
    for sdf ∈ gdf
        key = tuple(convert(Array{Any}, sdf[1, keycols])...)
        dict[key] = convert(Array{T}, sdf[datacols])
    end
    dict
end

function getMatrixDict{T}(::Type{T}, gdf::GroupedDataFrame, keycols::Vector{Symbol},
                          Xcols::Vector{Symbol}, ycols::Vector{Symbol})
    keycoltypes = getUnwrappedColumnElTypes(gdf.parent, keycols)
    Xdict = Dict{Tuple{keycoltypes...},Matrix{T}}()
    ydict = Dict{Tuple{keycoltypes...},Matrix{T}}()
    for sdf ∈ gdf
        key = tuple(convert(Array{Any}, sdf[1, keycols])...)
        Xdict[key] = convert(Array{T}, sdf[Xcols])
        ydict[key] = convert(Array{T}, sdf[ycols])
    end
    Xdict, ydict
end

function getMatrixDict{T}(::Type{T}, df::DataFrame, keycols::Vector{Symbol},
                          datacols::Vector{Symbol})
    getMatrixDict(T, groupby(df, keycols), keycols, datacols)
end

# this version is used by grouped dataframe
function getMatrixDict{T}(::Type{T}, df::DataFrame, keycols::Vector{Symbol},
                          Xcols::Vector{Symbol}, ycols::Vector{Symbol})
    getMatrixDict(T, groupby(df, keycols), keycols, Xcols, ycols)
end

export getMatrixDict


#=========================================================================================
Convert an array of Julia objects to a datatable
=========================================================================================#
"""
    struct_to_table(s)
    struct_to_table(v)

Converts a Julia compound type s into a single row of a `DataFrame` with column names
equal to field names and row values equal to field values.

Alternatively, once could pass a vector of compound type instances to create a `DataFrame`
with each row corresponding to an instance of the type.
"""
function struct_to_table{T}(t::T)
    fnames = fieldnames(T)
    dat = Vector{Any}(length(fnames))
    for i ∈ 1:length(fnames)
        dat[i] = [getfield(t, fnames[i])]
    end
    DataFrame(dat, fnames)
end

function struct_to_table{T}(v::AbstractVector{T})
    fnames = fieldnames(T)
    dtypes = (fieldtype(T, n) for n ∈ fnames)
    dat = Any[Vector{dtype}(length(v)) for dtype ∈ dtypes]

    for i ∈ 1:length(v), j ∈ 1:length(fnames)
        dat[j][i] = getfield(v[i], fnames[j])
    end

    DataFrame(dat, fnames)
end
export struct_to_table


"""
    Dict(df, keycol, valcol)

Create a dictionary out of the specified columns of a dataframe.
"""
function Dict(df::DataFrame, keycol::Symbol, valcol::Symbol)::Dict
    Dict(df[keycol], df[valcol])
end
export Dict


