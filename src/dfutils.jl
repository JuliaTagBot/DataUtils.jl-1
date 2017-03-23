

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
    shuffle!(df::DataTable)

Shuffles a dataframe in place.
"""
function shuffle!(df::DataTable)
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
    convertNulls!(df::DataTable, cols::Vector{Symbol}, newvalue::Any)

Convert all null values in columns of a DataTable to a particular value.

There is also a method for passing a single column symbol, not as a vector.
"""
function convertNulls!(df::DataTable, cols::Vector{Symbol}, newvalue::Any)
    for col in cols
        df[col] = convertNulls(df[col], newvalue)
    end
    return
end
convertNulls!(df::DataTable, col::Symbol, newvalue) = convertNulls!(df, [col], newvalue)
export convertNulls!


"""
    copyColumns(df::DataTable)

The default copy method for dataframes only copies one level deep, so basically it stores
an array of columns.  If you assign elements of individual (column) arrays then, it can
make changes to references of those arrays that exist elsewhere.

This method instead creates a new dataframe out of copies of the (column) arrays.

This is not named copy due to the fact that there is already an explicit copy(::DataTable)
implementation in dataframes.

Note that deepcopy is recursive, so this is *NOT* the same thing as deepcopy(df), which 
copies literally everything.
"""
function copyColumns(df::DataTable)
    ndf = DataTable()
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
function applyCatConstraints(dict::Dict, df::DataTable)
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

function applyCatConstraints(df::DataTable; kwargs...)
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
                      names::Vector{Symbol}=Symbol[])::DataTable
    df = DataTable()
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


"""
    nans2nulls(col)
    nans2nulls(df, colname)

Converts all `NaN`s appearing in the column to `Nullable()`.  The return
type is `NullableArray`, even if the original type of the column is not.
"""
function nans2nulls{T}(col::NullableArray{T})::NullableArray
    # this is being done without lift because of bugs in NullableArrays
    # haven't checked whether this bug still exists
    # map(x -> (isnan(x) ? Nullable{T}() : x), col, lift=true)
    map(col) do x
        if !isnull(x) && isnan(get(x))
            return Nullable{T}()
        end
        return x
    end
end

function nans2nulls(col::Vector)::NullableArray
    col = convert(NullableArray, col)
    nans2nulls(col)
end

function nans2nulls(df::DataTable, col::Symbol)::NullableArray
    nans2nulls(df[col])
end
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

function getCategoryVector{U}(df::AbstractDataTable, col::Symbol, vals::Vector, ::Type{U}=Int64)
    getCategoryVector(df[col], vals, U)
end

function getCategoryVector{U}(df::AbstractDataTable, col::Symbol, val, ::Type{U}=Int64)
    getCategoryVector(df[col], [val], U)
end
export getCategoryVector


"""
    getUnwrappedColumnElTypes(df[, cols=[]])

Get the element types of columns in a dataframe.  If the element types are `Nullable`, 
instead give the `eltype` of the `Nullable`.  If `cols=[]` this will be done for
all columns in the dataframe.
"""
function getUnwrappedColumnElTypes(df::DataTable, cols::Vector{Symbol}=Symbol[])
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
of each `SubDataTable` `sdf` in the groupby.  Note that the keys are always tuples
even if `keycols` only has one element.

If a type `T` is provided, the output matrices will be of type `Matrix{T}`.
"""
function getMatrixDict(df::DataTable, keycols::Vector{Symbol}, datacols::Vector{Symbol})
    keycoltypes = getUnwrappedColumnElTypes(df, keycols)
    dict = Dict{Tuple{keycoltypes...},Matrix}()
    for sdf ∈ groupby(df, keycols)
        key = tuple(convert(Array{Any}, sdf[1, keycols])...)
        dict[key] = convert(Array, sdf[datacols])
    end
    dict
end

function getMatrixDict{T}(::Type{T}, gdf::GroupedDataTable, keycols::Vector{Symbol},
                          datacols::Vector{Symbol})
    keycoltypes = getUnwrappedColumnElTypes(gdf.parent, keycols)
    dict = Dict{Tuple{keycoltypes...},Matrix{T}}()
    for sdf ∈ gdf
        key = tuple(convert(Array{Any}, sdf[1, keycols])...)
        dict[key] = convert(Array{T}, sdf[datacols])
    end
    dict
end

function getMatrixDict{T}(::Type{T}, gdf::GroupedDataTable, keycols::Vector{Symbol},
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

function getMatrixDict{T}(::Type{T}, df::DataTable, keycols::Vector{Symbol},
                          datacols::Vector{Symbol})
    getMatrixDict(T, groupby(df, keycols), keycols, datacols)
end

# this version is used by grouped dataframe
function getMatrixDict{T}(::Type{T}, df::DataTable, keycols::Vector{Symbol},
                          Xcols::Vector{Symbol}, ycols::Vector{Symbol})
    getMatrixDict(T, groupby(df, keycols), keycols, Xcols, ycols)
end

export getMatrixDict


#==========================================================================================
Conversions between DataTables and DataFrames
==========================================================================================#
"""
    convertArray(array_type, a)

Convert between `NullableArray`s and `DataArray`s.  The former is used by `DataTables` while
the latter is used by `DataFrames`.

Note that this is named `convertArray` rather than simply `convert` so as not to conflict
with the existing definitions for `convert`.
"""
function convertArray{T,N}(::Type{DataArrays.DataArray}, v::NullableArray{T,N})
    DataArrays.DataArray{T,N}(copy(v.values), BitArray(v.isnull))
end

function convertArray{T,N}(::Type{NullableArray}, v::DataArrays.DataArray{T,N})
    NullableArray{T,N}(copy(v.data), BitArray(v.na))
end

# TODO this will no longer be needed once Feather is updated
convertArray(::Type{NullableArray}, v::NullableArray) = copy(v)
export convertArray


function convert(::Type{DataFrames.DataFrame}, dt::DataTable)
    df = DataFrames.DataFrame()
    for name ∈ names(dt)
        df[name] = convertArray(DataArrays.DataArray, dt[name])
    end
    df
end


function convert(::Type{DataTable}, df::DataFrames.DataFrame)
    dt = DataTable()
    for name ∈ names(df)
        dt[name] = convertArray(NullableArray, df[name])
    end
    dt
end
export convert


