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

convertArray(::Type{DataArrays.DataArray}, v::Array) = DataArrays.DataArray(v)

convertArray(::Type{NullableArray}, v::Array) = NullableArray(v)

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



