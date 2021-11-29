export createnode, findnode

"""
"""
function createnode(st::FStatus, path::AbstractString, mode::Integer=0)
    db = st.db
    modef = Int(mode)
    dir, name = dirbase(path)
    dino = findnode(st, dir)
    if dino == 0
        throw(st.exception)
    end
    ino = 0
    SQLite.transaction(db) do
        DBInterface.execute(db, "INSERT INTO inode (nlinks, mode) VALUES (0, ?)", [modef])
        ino = SQLite.last_insert_rowid(db)
        DBInterface.execute(db, "INSERT INTO direntry (dino, name, ino) VALUES(?, ?, ?)", [dino, name, ino])
    end
    ino
end

function Base.rm(st::FStatus, path::AbstractString; force::Bool=false, recursive::Bool=false)
    ino = findnode(st, path)
    if ino == 0
        if !force
            throw(ArgumentError("file '$path' does not exist"))
        end
    else
        rm(st, ino; recursive)
    end
end

function Base.rm(st::FStatus, path::AbstractString; recursive::Bool=false)
    db = st.db
    dir, name = dirbase(path)
    dino = findnode(st, dir)
    ino = findnode(st, path)
    if dino == 0 || ino == 0
        throw(ArgumentError("file $path does not exist"))
    end
    SQLite.transaction(db) do
        DBInterface.execute(db, "DELETE FROM direntry WHERE dino = ? AND name = ?", (dino, name))
        DBInterface.execute(db, "DELETE FROM inode WHERE ino = ? AND nlinks = 0", (ino,))
    end
    ino
end


function Base.pwd(st::FStatus)
    st.dir
end

function Base.cd(st::FStatus, dir::AbstractString)
    ino = findnode(st, dir)
    if ino == 0
        throw(st.exception)
    else
        st.dir = normpath(joinpath(st.dir, dir))
        st.ino = ino
    end
end

function Base.hardlink(st::FStatus, inode::Integer, path::AbstractString)
    db = st.db
    dir, name = dirbase(path)
    dino = findnode(st, dir)
    if dino == 0
        throw(st.exception)
    end
    DBInterface.execute(db, "INSERT INTO direntry (dino, name, ino) VALUES(?, ?, ?)", (dino, name, inode))
    dino
end

function Base.mv(st::FStatus, src::AbstractString, dst::AbstractString; force::Bool=false)
    db = st.db
    sdir, sname = dirbase(src)
    sdino = findnode(st, sdir)
    if sdino == 0
        throw(ArgumentError("file $src does not exist"))
    end
    ddir, dname = dirbase(dst)
    ddino = findnode(st, ddir)
    if ddino == 0
        throw(ArgumentError("destination dir $ddir does not exist"))
    end
    DBInterface.execute(db,
                "UPDATE direntry SET dino = ?, name = ? WHERE dino = ? AND name = ?",
                (ddino, dname, sdino, sname)
    )
end

function findnode(st::FStatus, dir::AbstractString)
    dirs = splitpath(normpath(dir))
    ino = st.ino
    for d in dirs
        if d == "."
            continue
        elseif d == "/"
            ino = 1
            continue
        end
        try
            row = if d == ".."
                DBInterface.execute(st.db, "SELECT dino AS ino FROM direntry WHERE ino = ?", (ino,))
            else
                DBInterface.execute(st.db, "SELECT ino FROM direntry WHERE dino = ? AND name = ?", (ino, d))
            end
            ino = first(row).ino
        catch ex
            st.exception = ArgumentError("$d does not exist\n$ex")
            ino = 0
            break
        end
    end
    ino
end

function dirbase(path::AbstractString)
    path = normpath(path)
    dir, name = dirname(path), basename(path)
    if isempty(name)
        dir, name = dirname(dir), basename(dir)
    end
    dir, name
end
