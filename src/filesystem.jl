export createnode, findnode, ls

using Base.Filesystem
import Base.Filesystem: S_IFDIR, S_IFREG, S_IFCHR, S_IFBLK, S_IFIFO, S_IFLNK, S_IFSOCK, S_IFMT
import Base.Filesystem: S_IRWXU, S_IRWXG, S_IRWXO
import Base.Filesystem: S_IRUSR, S_IRGRP, S_IROTH
import Base.Filesystem: S_IWUSR, S_IWGRP, S_IWOTH
import Base.Filesystem: S_IXUSR, S_IXGRP, S_IXOTH
import Base.Filesystem: S_ISUID, S_ISGID, S_ISVTX

const X_UGO = S_IRWXU | S_IRWXG | S_IRWXO
const X_NOX = X_UGO & ~((S_IXUSR | S_IXGRP | S_IXOTH) & X_UGO)

const DIR1 = "."
const DIR2 = ".."
const DIRROOT = "/"
const ROOT_INO = 1

const DEFAULT_MODE = S_IFREG | X_UGO

"""
"""
function createnode(st::FStatus, path::AbstractString, mode::Integer=DEFAULT_MODE)
    path = normpath(path)
    dir, name = dirbase(path)
    if dir == DIRROOT && name == DIR1
        return create_rootnode(st, mode)
    elseif name == DIR2 || name == DIR1
        throw(ArgumentError("cannot create node named '$name'"))
    end
    dino = findnode(st, dir)
    if dino == 0
        throw(st.exception)
    end
    createnode(st, dino, name, mode)
end

function createnode(st::FStatus, dino::Integer, file::AbstractString, mode::Integer=DEFAULT_MODE)
    db = st.db
    mode = defaultmode(mode)
    rowit = DBInterface.execute(db, "SELECT mode from inode WHERE ino = ?", (dino,))
    dmode = first(rowit).mode
    if dmode & S_IFMT != S_IFDIR
        throw(ArgumentError("not a directory: $dir"))
    end
    ino = 0
    SQLite.transaction(db) do
        DBInterface.execute(db, "INSERT INTO inode (nlinks, mode) VALUES (0, ?)", (mode,))
        ino = SQLite.last_insert_rowid(db)
        DBInterface.execute(db, "INSERT INTO direntry
                                 (dino, name, ino) VALUES(?, ?, ?)", [dino, file, ino])
    end
    ino
end

function create_rootnode(st::FStatus, mode::Integer=X_UGO)
    db = st.db
    modef = defaultmode(S_IFDIR | (mode & ~S_IFMT))
    ino = findnode(st, DIRROOT)
    if ino == 0
        st.exception = nothing
        ino = ROOT_INO
        SQLite.transaction(db) do
            DBInterface.execute(db, "INSERT INTO inode (ino, nlinks, mode) VALUES (?, 0, ?)", (ino, modef))
            DBInterface.execute(db, "INSERT INTO direntry
                                     (dino, name, ino) VALUES(?, ?, ?)", [ino, DIRROOT, ino])
        end
    elseif ino != ROOT_INO
        throw(ArgumentError("invalide root node (ino = $ino)"))
    end
    ino
end

function Base.rm(st::FStatus, path::AbstractString; force::Bool=false, recursive::Bool=false)
    dir, name = dirbase(path)
    dino = findnode(st, dir)
    dino == 0 && throw(ArgumentError("dir $dir does not exist"))
    rm(st, dino, name; force, recursive)
end

function Base.rm(st::FStatus, dino::Integer, file::AbstractString; force::Bool=false, recursive::Bool=false)
    ino = findnode(st, dino, file)
    if ino == 0
        if !force
            throw(ArgumentError("file '$file' does not exist"))
        end
    else
        rm2(st, file; recursive)
    end
end

function rm2(st::FStatus, path::AbstractString; recursive::Bool=false)

    dir, name = dirbase(path)
    dino = findnode(st, dir)
    ino = findnode(st, path)
    if dino == 0 || ino == 0
        throw(ArgumentError("file $path does not exist"))
    end

    db = st.db
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

function Base.chmod(st::FStatus, mode::Integer, src::AbstractString)
    ino = findnode(st, src)
    ino == 0 && throw(ArgumentError("source file '$src' does not exist"))
    chmod(st, mode, ino)
end

function Base.chmod(st::FStatus, mode::Integer, ino::Integer)
    db = st.db
    DBInterface.execute(db, "UPDATE inode SET mode = updatemode(mode, ?) WHERE ino = ?", (mode, ino))
end

function Base.hardlink(st::FStatus, src::AbstractString, dst::AbstractString)
    ino = findnode(st, src)
    ino == 0 && throw(ArgumentError("source file '$src' does not exist"))
    hardlink(st, ino, dst)
end

function Base.hardlink(st::FStatus, inode::Integer, path::AbstractString)
    db = st.db
    dir, name = dirbase(path)
    dino = findnode(st, dir)
    if dino == 0
        throw(st.exception)
    end
    ino = Int(inode)
    DBInterface.execute(db, "INSERT INTO direntry (dino, name, ino) VALUES(?, ?, ?)", (dino, name, ino))
    dino
end

function Base.mv(st::FStatus, src::AbstractString, dst::AbstractString; force::Bool=false)

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
    mv(st, sdino, sname, ddino, dname,; force)
end

function Base.mv(st::FStatus, sdino::Integer, sname, ddino::Integer, dname; force::Bool=false)
    db = st.db
    DBInterface.execute(db,
                "UPDATE direntry SET dino = ?, name = ? WHERE dino = ? AND name = ?",
                (ddino, dname, sdino, sname)
    )
end

function Base.readdir(st::FStatus, dir::AbstractString=pwd(st); join::Bool=false, sort::Bool=true)
    db = st.db
    ino = findnode(st, dir)
    ino == 0 && throw(ArgumentError("destination dir $dir does not exist"))
    rowit = DBInterface.execute(db, "SELECT name FROM direntry WHERE dino = ? AND dino != ino", (ino,))
    entries = String[join ? joinpath(dir, r.name) : r.name for r in rowit]
    if sort
        sort!(entries)
    end
    entries
end

"""
    ls(st::FStatus[, dir])

Return `DataFrame` with readable file info for all files in `dir`.
Default to working directory.
"""
function ls(st::FStatus, dir::AbstractString=pwd(st))
    db = st.db
    dino = findnode(st, dir)
    dino == 0 && throw(ArgumentError("destination dir $dir does not exist"))
    rowit = DBInterface.execute(db, "
        SELECT modestring(mode) as mode, ino, nlinks,
        '.' FROM inode WHERE ino = ?
        UNION ALL 
        SELECT modestring(mode) as mode, ino, nlinks,
        '..' FROM inode WHERE ino = ( SELECT dino from direntry WHERE ino = ? )
        UNION ALL
        SELECT modestring(mode) as mode, inode.ino, nlinks,
        name FROM inode, direntry WHERE inode.ino = direntry.ino AND dino = ?
        AND dino != inode.ino",
        (dino, dino, dino))
     DataFrame(rowit)
end

"""
    findnode(st::FStatus, path)

Return inode number for given path or 0, if none exists.
"""
function findnode(st::FStatus, dir::AbstractString)
    dirs = splitpath(normpath(dir))
    ino = st.ino
    for d in dirs
        if d == DIR1
            continue
        elseif d == DIRROOT
            ino = ROOT_INO
            if length(dirs) > 1
                continue
            end
        end
        ino = findnode(st, ino, d)
        ino == 0 && break
    end
    ino
end

function findnode(st::FStatus, dino::Integer, name::AbstractString)
    ino = 0
    try
        row = if name == DIR2
            DBInterface.execute(st.db, "SELECT dino AS ino FROM direntry WHERE ino = ?", (dino,))
        else
            DBInterface.execute(st.db, "SELECT ino FROM direntry WHERE dino = ? AND name = ?", (dino, name))
        end
        ino = first(row).ino
    catch ex
        st.exception = ArgumentError("$name does not exist\n$ex")
        ino = 0
    end
    ino
end

"""
    dirbase(path)

Split `path` in `dir` and `base` part.
"""
function dirbase(path::AbstractString)
    path = normpath(path)
    dir, name = dirname(path), basename(path)
    if isempty(name)
        dir, name = dirname(dir), basename(dir)
    end
    if isempty(name)
        name = DIR1
    end
    dir, name
end

function defaultmode(x::Integer)
    perm = x & X_UGO
    noperm = x & ~X_UGO
    if 0 <= x < 16
        noperm =  perm << 12
        perm = noperm == S_IFDIR ? X_UGO : X_NOX
    end
    Int(noperm | (perm & ~UMASK))
end

function modestring(m::Integer)
  @inbounds begin
    N, r, w, x, s, S, t, T = UInt8.(('-', 'r', 'w', 'x', 's', 'S', 't', 'T'))
    ri, di, li, pi, ci, bi, si, ui = UInt8.(('-', 'd', 'l', 'p', 'c', 'b', 's', '?'))
    p = Vector{UInt8}(undef, 10)
    f = (m % UInt16) & S_IFMT
    p[1] = f == S_IFREG ? ri : f == S_IFDIR ? di : f == S_IFLNK ? li : f == S_IFIFO ? pi :
           f == S_IFCHR ? ci : f == S_IFBLK ? bi : f == S_IFSOCK ? si : ui

    p[2] = _select1(m, S_IRUSR, N, r)
    p[3] = _select1(m, S_IWUSR, N, w)
    p[4] = _select2(m, S_ISUID, S_IXUSR, N, x, S, s)
    p[5] = _select1(m, S_IRGRP, N, r)
    p[6] = _select1(m, S_IWGRP, N, w)
    p[7] = _select2(m, S_ISGID, S_IXGRP, N, x, S, s)
    p[8] = _select1(m, S_IROTH, N, r)
    p[9] = _select1(m, S_IWOTH, N, w)
    p[10] = _select2(m, S_ISVTX, S_IXOTH, N, x, T, t)
    String(p)
  end
end

@inline function _select1(x::T, m::Integer, a...) where T<:Integer
    z = UInt8(trailing_zeros(m))
    v = (x & T(m)) >>> z
    w = v & 0x1 + 0x1
    a[w]
end

@inline function _select2(x::T, m1::Integer, m2::Integer, a...) where T<:Integer
    z1 = UInt8(trailing_zeros(m1))
    z2 = UInt8(trailing_zeros(m2))
    y = x & T(m1 | m2)
    z = y >>> (z1 - z2 - 1)
    u = z | y
    v = u >>> z2
    w = v & 0x3 + 0x1
    a[w]
end

function updatemode(mode::T, update::Integer) where T<:Integer
    T((mode & S_IFMT) | (update & ~S_IFMT))
end
