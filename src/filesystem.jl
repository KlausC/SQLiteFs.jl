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

const UMASK = _umask()

"""
"""
function createnode(st::FStatus, path::AbstractString, mode::Integer=0o10)
    db = st.db
    modef = defaultmode(mode)
    path = normpath(path)
    dir, name = dirbase(path)
    if dir == DIRROOT && name == DIR1
        return create_rootnode(st, modef)
    elseif name == DIR2
        throw(ArgumentError("cannot create node named '$name'"))
    end 
    dino = findnode(st, dir)
    if dino == 0
        throw(st.exception)
    end
    ino = 0
    SQLite.transaction(db) do
        DBInterface.execute(db, "INSERT INTO inode (nlinks, mode) VALUES (0, ?)", (modef,))
        ino = SQLite.last_insert_rowid(db)
        DBInterface.execute(db, "INSERT INTO direntry
                                 (dino, name, ino) VALUES(?, ?, ?)", [dino, name, ino])
    end
    ino
end

function create_rootnode(st::FStatus, mode::Integer=0o040777)
    db = st.db
    modef = defaultmode(S_IFDIR | (mode & X_UGO))
    ino = findnode(st, DIRROOT)
    if ino == 0
        st.exception = nothing
        ino = 1
        SQLite.transaction(db) do
            DBInterface.execute(db, "INSERT INTO inode (ino, nlinks, mode) VALUES (?, 0, ?)", (ino, modef))
            DBInterface.execute(db, "INSERT INTO direntry
                                     (dino, name, ino) VALUES(?, ?, ?)", [ino, DIRROOT, ino])
        end
    elseif ino != 1
        throw(ArgumentError("invalide root node (ino = $ino)"))
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
        rm2(st, path; recursive)
    end
end

function rm2(st::FStatus, path::AbstractString; recursive::Bool=false)
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

function ls(st::FStatus, dir::AbstractString=pwd(st))
    db = st.db
    dino = findnode(st, dir)
    dino == 0 && throw(ArgumentError("destination dir $dir does not exist"))
    rowit = DBInterface.execute(db, "
        SELECT modestring(mode) as mode, inode.ino, nlinks,
        '.' FROM inode, direntry WHERE inode.ino = direntry.ino AND inode.ino = ?
        UNION ALL 
        SELECT modestring(mode) as mode, inode.ino, nlinks,
        '..' FROM inode, direntry WHERE inode.ino = direntry.ino AND inode.ino =
        ( SELECT dino from direntry WHERE ino = ? )
        UNION ALL
        SELECT modestring(mode) as mode, inode.ino, nlinks,
        name FROM inode, direntry WHERE inode.ino = direntry.ino AND dino = ?
        AND dino != inode.ino",
        (dino, dino, dino))
     DataFrame(rowit)
end

function findnode(st::FStatus, dir::AbstractString)
    dirs = splitpath(normpath(dir))
    ino = st.ino
    for d in dirs
        if d == DIR1
            continue
        elseif d == DIRROOT
            ino = 1
            if length(dirs) > 1
                continue
            end
        end
        try
            row = if d == DIR2
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
    if isempty(name)
        name = DIR1
    end
    dir, name
end

function defaultmode(x::Integer)
    perm = x & X_UGO
    noperm = x & ~X_UGO
    if noperm == 0
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
