
# TODO: this will be changed once Feather.jl gets updated
"""
    featherWrite(filename, df[, overwrite=false])

A wrapper for writing dataframes to feather files.  To be used while Feather.jl package
is in development.

If `overwrite`, this will delete the existing file first (an extra step taken to avoid some
strange bugs).
"""
function featherWrite(filename::AbstractString, df::DataFrames.DataFrame;
                      overwrite::Bool=false)::Void
    if isfile(filename)
        if !overwrite
            throw(SystemError("File already exists.  Use overwrite=true."))
        end
        rm(filename)     
    end
    Feather.write(filename, df)
    nothing
end

function featherWrite(filename::AbstractString, dt::DataTable;
                      overwrite::Bool=false)::Void
    featherWrite(filename, convert(DataFrames.DataFrame, dt), overwrite=overwrite)
end
export featherWrite


# TODO these will also get changed once Feather gets updated
# .... other parts of thsi might change in 0.6
"""
    convertWeakRefStrings(df)
    convertWeakRefStrings!(df)

Converts all columns with eltype `Nullable{WeakRefString}` to have eltype `Nullable{String}`.
`WeakRefString` is a special type of string used by the feather package to improve deserialization
performance.

Note that this will no longer be necessary in Julia 0.6.
"""
function convertWeakRefStrings(df::AbstractDataTable)
    odf = DataTable()
    for col ∈ names(df)
        if eltype(df[col]) <: Nullable{Feather.WeakRefString{UInt8}}
            odf[col] = convert(NullableVector{String}, df[col])
        else
            odf[col] = df[col]
        end
    end
    odf
end
export convertWeakRefStrings
function convertWeakRefStrings!(df::AbstractDataTable)
    for col ∈ names(df)
        if eltype(df[col]) <: Nullable{Feather.WeakRefString{UInt8}}
            df[col] = convert(NullableVector{String}, df[col])
        end
    end
    df
end
export convertWeakRefStrings!


# TODO: this will also get changed once Feather.jl gets updated
"""
    featherRead(filename[; convert_strings=true])

A wrapper for reading dataframes which are saved in feather files.  The purpose of this
wrapper is primarily for converting `WeakRefString` to `String`.  This will no longer
be necessary in Julia 0.6.
"""
function featherRead(filename::AbstractString; convert_strings::Bool=true)::DataTable
    df = convert(DataTable, Feather.read(filename))
    # df = convert(DataTable, Feather.read(filename))
    if convert_strings
        convertWeakRefStrings!(df)
    end
    df
end
export featherRead


