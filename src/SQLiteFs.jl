module SQLiteFs

using SQLite
using DataFrames
mutable struct FStatus
    db::SQLite.DB
    dir::String
    ino::Int
    exception::Union{Nothing,Exception}
    FStatus(db) = new(db, DIRROOT, ROOT_INO, nothing)
end

include("layout.jl")
include("cstruct.jl")
include("fuseapi.jl")
include("fusebridge.jl")
include("initdb.jl")
include("filesystem.jl")

include("examplefs.jl")

function _umask()
    umask = mktempdir() do tmp
        s = mkdir(joinpath(tmp, "stest"))
        st = stat(s)
        ~st.mode & X_UGO
    end
    umask
end

function __init__()
    eval(:(const UMASK = _umask()))
end
end
