module SQLiteFs

using SQLite
using DataFrames
mutable struct FStatus
    db::SQLite.DB
    dir::String
    ino::Int
    exception::Union{Nothing,Exception}
    FStatus(db) = new(db, "/", 1, nothing)
end

function _umask()
    umask = mktempdir() do tmp
        s = mkdir(joinpath(tmp, "stest"))
        st = stat(s)
        ~st.mode & X_UGO
    end
    umask
end


include("initdb.jl")
include("filesystem.jl")


end
