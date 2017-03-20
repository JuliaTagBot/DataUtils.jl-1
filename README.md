
<a id='DataUtils.jl-1'></a>

# DataUtils.jl


This package contains simple, standalone functions that are often useful when working with data, especially [DataTables](https://github.com/JuliaData/DataTables.jl).  It is intended that this package have no dependencies other than `DataTables` itself.


<a id='Data-Filtering-1'></a>

## Data Filtering


Currently there aren't really any good ways of doing basic filtering of data for `DataTables`.  The nicest package (in my opinion) for doing this sort of thing is [DataFramesMeta](https://github.com/JuliaStats/DataFramesMeta.jl) but it hasn't been updated for `DataTables`.  Therefore, to provide basic filtering functionality that covers the vast majority of use cases, `DataUtils` provides the `constrain` function and `@constrain` macro.


<a id='constrain-1'></a>

### `constrain`


This function filters a `DataTable` so that it only contains data-points for which a particular feature is in some set.  For example


```julia
constrain(dt, A=[1,2], B=[:γ])
```


Returns a `DataTable` containing only rows of the original for which the column `:A` has values `1` *or* `2` *and* the column `B` has value `:γ`.  So, when specifying multiple columns, rows must have values in *all* of the specified sets.


<a id='@constrain-1'></a>

### `@constrain`


For other filters DataUtils provides the `@constrain` macro.  To this macro one should supply a `DataTable` and an expression which must be satisfied, using the symbols for columns.  For example, let `dt` be a `DataTable` with columns `[:A, :B, :C]`


```julia
@constrain(dt, (:A > 0.0) && (:B % 3 ≠ 1))
```


This will retrun a `DataTable` with only rows that satisfy the above expression.


___TODO:___ There is still a bug preventing the user from using the name of the same column more than once.  Not too hard to fix, fix it!


<a id='API-Docs-1'></a>

## API Docs

<a id='Base.Dict-Tuple{Array{K,1},Array{V,1}}' href='#Base.Dict-Tuple{Array{K,1},Array{V,1}}'>#</a>
**`Base.Dict`** &mdash; *Method*.



**DataUtils**

`DataUtils` provides the following new constructors for `Dict`:

```
Dict(keys, values)
Dict(df, keycol, valcol)
```

One can provide `Dict` with (equal length) vector arguments.  The first vector provides a list of keys, while the second provides a list of values. If the vectors are `NullableVector`, only key, value pairs with *both* their elements non-null will be added.

<a id='Base.convert-Tuple{Type{NullableArrays.NullableArray{T<:Integer,N}},NullableArrays.NullableArray{K<:AbstractFloat,N}}' href='#Base.convert-Tuple{Type{NullableArrays.NullableArray{T<:Integer,N}},NullableArrays.NullableArray{K<:AbstractFloat,N}}'>#</a>
**`Base.convert`** &mdash; *Method*.



convert(NullableArray{T<:Integer,N}, a)

This converts a column of floats that should have been ints, but got converted to floats because it has missing values which were converted to NaN's. The supplied `NullableArray` should have eltype `Float32` or `Float64`.

<a id='DataUtils.applyCatConstraints-Tuple{Dict,DataTables.DataTable}' href='#DataUtils.applyCatConstraints-Tuple{Dict,DataTables.DataTable}'>#</a>
**`DataUtils.applyCatConstraints`** &mdash; *Method*.



```
applyCatConstraints(dict, df[, kwargs])
```

Returns a copy of the dataframe `df` with categorical constraints applied.  `dict` should  be a dictionary with keys equal to column names in `df` and values equal to the categorical values that column is allowed to take on.  For example, to select gauge bosons we can pass `Dict(:PID=>[i for i in 21:24; -24])`.  Alternatively, the values in the dictionary can be functions which return boolean values, in which case the returned dataframe will be the one with column values for which the functions return true.

Note that this requires that the dictionary values are either `Vector` or `Function`  (though one can of course mix the two types).

Alternatively, instead of passing a `Dict` one can pass keywords, for example `applyCatConstraints(df, PID=[i for i in 21:24; -24])`.

<a id='DataUtils.constrain-Tuple{DataTables.AbstractDataTable,Dict{K<:Symbol,V<:Function}}' href='#DataUtils.constrain-Tuple{DataTables.AbstractDataTable,Dict{K<:Symbol,V<:Function}}'>#</a>
**`DataUtils.constrain`** &mdash; *Method*.



```
constrain(df, dict)
constrain(df, kwargs...)
constrain(df, cols, func)
```

Returns a subset of the dataframe `df` for which the column `key` satisfies  `value(df[i, key]) == true`.  Where `(key, value)` are the pairs in `dict`.   Alternatively one can use keyword arguments instead of a `Dict`.

Also, one can pass a function the arguments of which are elements of columns specified by `cols`.

<a id='DataUtils.convertArray-Tuple{Type{DataArrays.DataArray},NullableArrays.NullableArray{T,N}}' href='#DataUtils.convertArray-Tuple{Type{DataArrays.DataArray},NullableArrays.NullableArray{T,N}}'>#</a>
**`DataUtils.convertArray`** &mdash; *Method*.



```
convertArray(array_type, a)
```

Convert between `NullableArray`s and `DataArray`s.  The former is used by `DataTables` while the latter is used by `DataFrames`.

Note that this is named `convertArray` rather than simply `convert` so as not to conflict with the existing definitions for `convert`.

<a id='DataUtils.convertNulls!-Tuple{Array{T<:AbstractFloat,1},T<:AbstractFloat}' href='#DataUtils.convertNulls!-Tuple{Array{T<:AbstractFloat,1},T<:AbstractFloat}'>#</a>
**`DataUtils.convertNulls!`** &mdash; *Method*.



```
convertNulls!{T}(A::Array{T, 1}, newvalue::T)
```

Converts all null values (NaN's and Nullable()) to a particular value. Note this has to check whether the type is Nullable.

<a id='DataUtils.convertNulls!-Tuple{DataTables.DataTable,Array{Symbol,1},Any}' href='#DataUtils.convertNulls!-Tuple{DataTables.DataTable,Array{Symbol,1},Any}'>#</a>
**`DataUtils.convertNulls!`** &mdash; *Method*.



```
convertNulls!(df::DataTable, cols::Vector{Symbol}, newvalue::Any)
```

Convert all null values in columns of a DataTable to a particular value.

There is also a method for passing a single column symbol, not as a vector.

<a id='DataUtils.convertNulls-Tuple{NullableArrays.NullableArray{T,N},T}' href='#DataUtils.convertNulls-Tuple{NullableArrays.NullableArray{T,N},T}'>#</a>
**`DataUtils.convertNulls`** &mdash; *Method*.



```
convertNulls{T}(A, newvalue)
```

Converts all null vlaues (NaN's and Nullable()) to a particular value. This is a wrapper added for sake of naming consistency.

<a id='DataUtils.convertWeakRefStrings-Tuple{DataTables.AbstractDataTable}' href='#DataUtils.convertWeakRefStrings-Tuple{DataTables.AbstractDataTable}'>#</a>
**`DataUtils.convertWeakRefStrings`** &mdash; *Method*.



```
convertWeakRefStrings(df)
convertWeakRefStrings!(df)
```

Converts all columns with eltype `Nullable{WeakRefString}` to have eltype `Nullable{String}`. `WeakRefString` is a special type of string used by the feather package to improve deserialization performance.

Note that this will no longer be necessary in Julia 0.6.

<a id='DataUtils.copyColumns-Tuple{DataTables.DataTable}' href='#DataUtils.copyColumns-Tuple{DataTables.DataTable}'>#</a>
**`DataUtils.copyColumns`** &mdash; *Method*.



```
copyColumns(df::DataTable)
```

The default copy method for dataframes only copies one level deep, so basically it stores an array of columns.  If you assign elements of individual (column) arrays then, it can make changes to references to those arrays that exist elsewhere.

This method instead creates a new dataframe out of copies of the (column) arrays.

This is not named copy due to the fact that there is already an explicit copy(::DataTable) implementation in dataframes.

Note that deepcopy is recursive, so this is *NOT* the same thing as deepcopy(df), which  copies literally everything.

<a id='DataUtils.discreteDiff-Tuple{Array{T,1}}' href='#DataUtils.discreteDiff-Tuple{Array{T,1}}'>#</a>
**`DataUtils.discreteDiff`** &mdash; *Method*.



```
discreteDiff{T}(X::Array{T, 1})
```

Returns the discrete difference between adjacent elements of a time series.  So,  for instance, if one has a time series $y_{1},y_{2},ldots,y_{N}$ this will return a set of $δ$ such that $δ_{i} = y_{i+1} - y_{i}$.  The first element of the returned array will be a `NaN`.

<a id='DataUtils.featherRead-Tuple{AbstractString}' href='#DataUtils.featherRead-Tuple{AbstractString}'>#</a>
**`DataUtils.featherRead`** &mdash; *Method*.



```
featherRead(filename[; convert_strings=true])
```

A wrapper for reading dataframes which are saved in feather files.  The purpose of this wrapper is primarily for converting `WeakRefString` to `String`.  This will no longer be necessary in Julia 0.6.

<a id='DataUtils.featherWrite-Tuple{AbstractString,DataFrames.DataFrame}' href='#DataUtils.featherWrite-Tuple{AbstractString,DataFrames.DataFrame}'>#</a>
**`DataUtils.featherWrite`** &mdash; *Method*.



```
featherWrite(filename, df[, overwrite=false])
```

A wrapper for writing dataframes to feather files.  To be used while Feather.jl package is in development.

If `overwrite`, this will delete the existing file first (an extra step taken to avoid some strange bugs).

<a id='DataUtils.getCategoryVector' href='#DataUtils.getCategoryVector'>#</a>
**`DataUtils.getCategoryVector`** &mdash; *Function*.



```
getCategoryVector(A, vals[, dtype])
```

Get a vector which is 1 for each `a ∈ A` that satisfies `a ∈ vals`, and 0 otherwise. If `A` is a `NullableVector`, any null elements will be mapped to 0.

Optionally, one can specify the datatype of the output vector.

<a id='DataUtils.getDefaultCategoricalMapping-Tuple{Array}' href='#DataUtils.getDefaultCategoricalMapping-Tuple{Array}'>#</a>
**`DataUtils.getDefaultCategoricalMapping`** &mdash; *Method*.



```
getDefaultCategoricalMapping(A::Array)
```

Gets the default mapping of categorical variables which would be returned by numericalCategories.

<a id='DataUtils.getMatrixDict-Tuple{DataTables.DataTable,Array{Symbol,1},Array{Symbol,1}}' href='#DataUtils.getMatrixDict-Tuple{DataTables.DataTable,Array{Symbol,1},Array{Symbol,1}}'>#</a>
**`DataUtils.getMatrixDict`** &mdash; *Method*.



```
getMatrixDict([T,] df, keycols, datacols)
```

Gets a dictionary the keys of which are the keys of a groupby of `df` by the columns `keycols` and the values of which are the matrices produced by taking `sdf[datacols]` of each `SubDataTable` `sdf` in the groupby.  Note that the keys are always tuples even if `keycols` only has one element.

If a type `T` is provided, the output matrices will be of type `Matrix{T}`.

<a id='DataUtils.getUnwrappedColumnElTypes' href='#DataUtils.getUnwrappedColumnElTypes'>#</a>
**`DataUtils.getUnwrappedColumnElTypes`** &mdash; *Function*.



```
getUnwrappedColumnElTypes(df[, cols=[]])
```

Get the element types of columns in a dataframe.  If the element types are `Nullable`,  instead give the `eltype` of the `Nullable`.  If `cols=[]` this will be done for all columns in the dataframe.

<a id='DataUtils.nans2nulls-Tuple{NullableArrays.NullableArray{T,N}}' href='#DataUtils.nans2nulls-Tuple{NullableArrays.NullableArray{T,N}}'>#</a>
**`DataUtils.nans2nulls`** &mdash; *Method*.



```
nans2nulls(col)
nans2nulls(df, colname)
```

Converts all `NaN`s appearing in the column to `Nullable()`.  The return type is `NullableArray`, even if the original type of the column is not.

<a id='DataUtils.numericalCategories!-Tuple{Type{T},DataTables.DataTable,Array{Symbol,N}}' href='#DataUtils.numericalCategories!-Tuple{Type{T},DataTables.DataTable,Array{Symbol,N}}'>#</a>
**`DataUtils.numericalCategories!`** &mdash; *Method*.



```
numericalCategories!(otype::DataType, df::DataTable, cols::Array{Symbol})
```

Converts categorical variables into numerical values for multiple columns in a dataframe.  

**TODO** For now doesn't return mapping, may have to implement some type of  mapping type.

<a id='DataUtils.numericalCategories!-Tuple{Type{T},DataTables.DataTable,Symbol}' href='#DataUtils.numericalCategories!-Tuple{Type{T},DataTables.DataTable,Symbol}'>#</a>
**`DataUtils.numericalCategories!`** &mdash; *Method*.



```
numericalCategories!(otype::DataType, df::DataTable, col::Symbol)
```

Converts a categorical value in a column into a numerical variable of the given type.

Returns the mapping.

<a id='DataUtils.numericalCategories-Tuple{Type{T},Array}' href='#DataUtils.numericalCategories-Tuple{Type{T},Array}'>#</a>
**`DataUtils.numericalCategories`** &mdash; *Method*.



```
numericalCategories(otype, A)
```

Converts a categorical variable into numerical values of the given type.

Returns the mapping as well as the new array, but the mapping is just an array so it always maps to an integer

<a id='DataUtils.randomData-Tuple{Vararg{DataType,N}}' href='#DataUtils.randomData-Tuple{Vararg{DataType,N}}'>#</a>
**`DataUtils.randomData`** &mdash; *Method*.



```
randomData(dtypes...; nrows=10^4)
```

Creates a random dataframe with columns of types specified by `dtypes`.  This is useful for testing various dataframe related functionality.

<a id='DataUtils.shuffle!-Tuple{DataTables.DataTable}' href='#DataUtils.shuffle!-Tuple{DataTables.DataTable}'>#</a>
**`DataUtils.shuffle!`** &mdash; *Method*.



```
shuffle!(df::DataTable)
```

Shuffles a dataframe in place.

<a id='DataUtils.@constrain-Tuple{Any,Any}' href='#DataUtils.@constrain-Tuple{Any,Any}'>#</a>
**`DataUtils.@constrain`** &mdash; *Macro*.



```
@constrain(df, expr)
```

Constrains the dataframe to rows for which `expr` evaluates to `true`.  `expr` should specify columns with column names written as symbols.  For example, to do `(a ∈ A) > M` one should write `:A .> M`.

