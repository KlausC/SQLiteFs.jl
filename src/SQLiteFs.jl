module SQLiteFs

using SQLite

mutable struct FStatus
    db::SQLite.DB
    dir::String
    ino::Int
    exception::Union{Nothing,Exception}
    FStatus(db) = new(db, "/", 1, nothing)
end

include("initdb.jl")
include("filesystem.jl")


end
