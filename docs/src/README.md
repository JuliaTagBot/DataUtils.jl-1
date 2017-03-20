# DataUtils.jl
This package contains simple, standalone functions that are often useful when working with
data, especially [DataTables](https://github.com/JuliaData/DataTables.jl).  It is intended that this package have no dependencies other than `DataTables`
itself.

## Data Filtering
Currently there aren't really any good ways of doing basic filtering of data for `DataTables`.  The nicest package (in my opinion) for doing this sort of thing
is [DataFramesMeta](https://github.com/JuliaStats/DataFramesMeta.jl) but it hasn't been updated for `DataTables`.  Therefore, to provide basic filtering
functionality that covers the vast majority of use cases, `DataUtils` provides the `constrain` function and `@constrain` macro.

### `constrain`
This function filters a `DataTable` so that it only contains data-points for which a particular feature is in some set.  For example
```julia
constrain(dt, A=[1,2], B=[:γ])
```
Returns a `DataTable` containing only rows of the original for which the column `:A` has values `1` *or* `2` *and* the column `B` has value `:γ`.  So, when
specifying multiple columns, rows must have values in *all* of the specified sets.

### `@constrain`
For other filters DataUtils provides the `@constrain` macro.  To this macro one should supply a `DataTable` and an expression which must be satisfied, using the
symbols for columns.  For example, let `dt` be a `DataTable` with columns `[:A, :B, :C]`
```julia
@constrain(dt, (:A > 0.0) && (:B % 3 ≠ 1))
```
This will retrun a `DataTable` with only rows that satisfy the above expression.

___TODO:___ There is still a bug preventing the user from using the name of the same column more than once.  Not too hard to fix, fix it!

## API Docs
```@autodocs
Modules = [DataUtils]
Private = false
```

