
export FuseLowlevelOps

const CFunction = Ptr{Nothing}

struct FuseLowlevelOps
    init::CFunction
    destroy::CFunction
    lookup::CFunction
    forget::CFunction
    getattr::CFunction
    setattr::CFunction
    readlink::CFunction
    mknod::CFunction
    mkdir::CFunction
    unlink::CFunction
    rmdir::CFunction
    symlink::CFunction
    rename::CFunction
    link::CFunction
    open::CFunction
    read::CFunction
    write::CFunction
    flush::CFunction
    release::CFunction
    fsync::CFunction
    opendir::CFunction
    readdir::CFunction
    releasedir::CFunction
    fsyncdir::CFunction
    statfs::CFunction
    setxattr::CFunction
    getxattr::CFunction
    listxattr::CFunction
    removexattr::CFunction
    access::CFunction
    create::CFunction
    getlk::CFunction
    setlk::CFunction
    bmap::CFunction
    ioctl::CFunction
    poll::CFunction
    write_buf::CFunction
    retrieve_reply::CFunction
    forget_multi::CFunction
    flock::CFunction
    fallocate::CFunction
    readdirplus::CFunction
    copy_file_range::CFunction
    lseek::CFunction
end

function FuseLowlevelOps(src::FuseLowlevelOps, filter::AbstractVector{Symbol})
    ops = [p in filter ? (src, p) : CFunction(0) for p in fieldnames(FuseLowlevelOps)]
    FuseLowlevelOps(ops...)
end


const FuseIno = UInt64
const FuseMode = UInt32
const FuseDev = UInt64

struct FuseReq
end

struct Timespec
    seconds::Int64
    ns::Int32
end

struct FuseCtx
    uid::UInt32
    gid::UInt32
    pid::UInt32
    umask::FuseMode
end

struct FuseStat
    device  :: UInt64
    inode   :: UInt64
    mode    :: FuseMode
    nlink   :: UInt32
    uid     :: UInt32
    gid     :: UInt32
    rdev    :: UInt64
    size    :: Int64
    blksize :: Int64
    blocks  :: Int64
    atime   :: Timespec
    mtime   :: Timespec
    ctime   :: Timespec
end
struct FuseEntryParam
    ino::FuseIno
    generation::UInt64
    attr::FuseStat
    attr_timeout::Cdouble
    attr_entry_timeout::Cdouble
end
struct FuseConnInfo
    proto_major::Cuint
    proto_minor::Cuint
    max_write::Cuint
    max_read::Cuint
    max_readahead::Cuint
    capable::Cuint
    want::Cuint
    max_backgrount::Cuint
    congestion_threshold::Cuint
    time_gran::Cuint
    reserved::NTuple{22,Cuint}
end
struct FuseFileInfo
    flags::Int32
    bits::UInt64
    fh::UInt64
    lock_owner::UInt64
    poll_events::UInt32
end
struct FuseFileStruct
end
struct Flock
end
struct FusePollHandle
end
struct FuseBufvec
end
struct FuseForgetData
end

struct FuseFlock
end

# C- entrypoints for all lowlevel callback functions

F_INIT = 1
function Cinit(userdata::Ref{Nothing}, conn::FuseConnInfo)
    try
        fcallback(F_INIT, userdata, confn)
    finally
    end
end
F_DESTROY = 2
function Cdestroy(userdata::Ref{Nothing})
    try
        fcallback(F_DESTROY, userdata)
    finally
    end
end
F_LOOKUP = 3
function Clookup(req::Ptr{FuseReq}, parent::FuseIno, name::String)
    try
        fcallback(F_LOOKUP, req, parent, ino, name)
    finally
    end
end
F_FORGET = 4
function Cforget(req::Ptr{FuseReq}, ino::FuseIno, lookup::UInt64)
    try
        fcallback(F_FORGET, req, ino, lookup)
    finally
    end
end
F_GETATTR = 5
function Cgetattr(req::Ptr{FuseReq}, ino::FuseIno, fi::FuseFileInfo)
    try
        fcallback(F_GETATTR, req, ino, fi)
    finally
    end
end
F_SETATTR = 6
function Csetattr(req::Ptr{FuseReq}, ino::FuseIno, attr::FuseStat, to_set::Cint, fi::FuseFileInfo)
    try
        fcallback(F_SETATTR, req, ino, attr, to_set, fi)
    finally
    end
end
F_READLINK = 7
function Creadlink(req::Ptr{FuseReq}, ino::FuseIno)
    try
        fcallback(F_READLINK, req, ino)
    finally
    end
end
F_MKNOD = 8
function Cmknod(req::Ptr{FuseReq}, parent::FuseIno, name::String, mode::FuseMode, rdev::FuseDev)
    try
        fcallback(F_MKNOD, req, parent, name, mode, rdev)
    finally
    end
end
F_MKDIR = 9
function Cmkdir(req::Ptr{FuseReq}, parent::FuseIno, name::String, mode::FuseMode) 
    try
        fcallback(F_MKDIR, req, parent, name, mode)
    finally
    end
end
F_UNLINK = 10
function Cunlink(req::Ptr{FuseReq}, parent::FuseIno, name::String)
    try
        fcallback(F_UNLINK, req, parent, name)
    finally
    end
end
F_RMDIR = 11
function Crmdir(req::Ptr{FuseReq}, parent::FuseIno, name::String)
    try
        fcallback(F_RMDIR, req, parent, name)
    finally
    end
end
F_SYMLINK = 12
function Csymlink(req::Ptr{FuseReq}, link::String, parent::FuseIno, name::String)
    try
        fcallback(F_SYMLINK, req, link, parent, name)
    finally
    end
end
F_RENAME = 13
function Crename(req::Ptr{FuseReq}, parent::FuseIno, name::String, newparent::FuseIno, newname::String, flags::Cuint)
    try
        fcallback(F_RENAME, req, parent, name, newparent, newname, flags)
    finally
    end
end
F_LINK = 14
function Clink(req::Ptr{FuseReq}, ino::FuseIno, newparent::FuseIno, newname::String)
    try
        fcallback(F_LINK, req, ino, newparent, newname)
    finally
    end
end
F_OPEN = 15
function Copen(req::Ptr{FuseReq}, ino::FuseIno, fi::FuseFileInfo)
    try
        fcallback(F_OPEN, req, ino, fi)
    finally
    end
end
F_READ = 16
function Cread(req::Ptr{FuseReq}, ino::FuseIno, size::Csize_t, off::Csize_t, fi::FuseFileInfo)
    try
        fcallback(F_READ, req, ino, size, off, fi)
    finally
    end
end
F_WRITE = 17
function Cwrite(req::Ptr{FuseReq}, ino::FuseIno, buf::Vector{UInt8}, size::Csize_t, off::Csize_t, fi::FuseFileInfo)
    try
        fcallback(F_WRITE, req, ino, buf, size, off, fi)
    finally
    end
end
F_FLUSH = 18
function Cflush(req::Ptr{FuseReq}, ino::FuseIno, fi::FuseFileInfo)
    try
        fcallback(F_FLUSH, req, ino, fi)
    finally
    end
end
F_RELEASE = 19
function Crelease(req::Ptr{FuseReq}, ino::FuseIno, fi::FuseFileInfo)
    try
        fcallback(F_RELEASE, req, ino, fi)
    finally
    end
end
F_FSYNC = 20
function Cfsync(req::Ptr{FuseReq}, ino::FuseIno, datasync::Cint, fi::FuseFileInfo)
    try
        fcallback(F_FSYNC, req, ino, datasync, fi)
    finally
    end
end
F_OPENDIR = 21
function Copendir(req::Ptr{FuseReq}, ino::FuseIno, fi::FuseFileInfo)
    try
        fcallback(F_OPENDIR, req, ino)
    finally
    end
end
F_READDIR = 22
function Creaddir(req::Ptr{FuseReq}, ino::FuseIno, size::Csize_t, off::Csize_t, fi::FuseFileInfo)
    try
        fcallback(F_READDIR, req, ino, size, off, fi)
    finally
    end
end
F_RELEASEDIR = 23
function Creleasedir(req::Ptr{FuseReq}, ino::FuseIno, fi::FuseFileInfo)
    try
        fcallback(F_RELEASEDIR, req, ino, fi)
    finally
    end
end
F_FSYNCDIR = 24
function Cfsyncdir(req::Ptr{FuseReq}, ino::FuseIno, datasync::Cint, fi::FuseFileInfo)
    try
        fcallback(F_FSYNCDIR, req, ino, datasync, fi)
    finally
    end
end
F_STATFS = 25
function Cstatfs(req::Ptr{FuseReq}, ino::FuseIno)
    try
        fcallback(F_STATFS, req, ino)
    finally
    end
end
F_SETXATTR = 26
function Csetxattr(req::Ptr{FuseReq}, ino::FuseIno, name::String, value::String, size::Csize_t, flags::Cint)
    try
        fcallback(F_SETXATTR, req, ino, name, value, size, flags)
    finally
    end
end
F_GETXATTR = 27
function Cgetxattr(req::Ptr{FuseReq}, ino::FuseIno, name::String, size::Csize_t)
    try
        fcallback(F_GETXATTR, req, ino, name, size)
    finally
    end
end
F_LISTXATTR = 28
function Clistxattr(req::Ptr{FuseReq}, ino::FuseIno, size::Csize_t)
    try
        fcallback(F_LISTXATTR, req, ino, size)
    finally
    end
end
F_REMOVEXATTR = 29
function Cremovexattr(req::Ptr{FuseReq}, ino::FuseIno, name::String)
    try
        fcallback(F_REMOVEXATTR, req, ino, name)
    finally
    end
end
F_ACCESS = 30
function Caccess(req::Ptr{FuseReq}, ino::FuseIno, mask::Cint)
    try
        fcallback(F_ACCESS, req, ino)
    finally
    end
end
F_CREATE = 31
function Ccreate(req::Ptr{FuseReq}, parent::FuseIno, name::String, mode::FuseMode, fi::FuseFileInfo)
    try
        fcallback(F_CREATE, req, parent, name, mode, fi)
    finally
    end
end
F_GETLK = 32
function Cgetlk(req::Ptr{FuseReq}, ino::FuseIno, fi::FuseFileInfo, lock::FuseFlock)
    try
        fcallback(F_GETLK, req, ino, fi, lock)
    finally
    end
end
F_SETLK = 33
function Csetlk(req::Ptr{FuseReq}, ino::FuseIno, fi::FuseFileInfo, lock::FuseFlock, sleep::Cint)
    try
        fcallback(F_SETLK, req, ino, fi, lock, sleep)
    finally
    end
end
F_BMAP = 34
function Cbmap(req::Ptr{FuseReq}, ino::FuseIno)
    try
        fcallback(F_BMAP, req, ino)
    finally
    end
end
F_IOCTL = 35
function Cioctl(req::Ptr{FuseReq}, ino::FuseIno)
    try
        fcallback(F_IOCTL, req, ino)
    finally
    end
end
F_POLL = 36
function Cpoll(req::Ptr{FuseReq}, ino::FuseIno)
    try
        fcallback(F_POLL, req, ino)
    finally
    end
end
F_WRITE_BUF = 37
function Cwrite_buf(req::Ptr{FuseReq}, ino::FuseIno)
    try
        fcallback(F_WRITE_BUF, req, ino)
    finally
    end
end
F_RETRIEVE_REPLY = 38
function Cretrieve_reply(req::Ptr{FuseReq}, ino::FuseIno)
    try
        fcallback(F_RETRIEVE_REPLY, req, ino)
    finally
    end
end
F_FORGET_MULTI = 39
function Cforget_multi(req::Ptr{FuseReq}, ino::FuseIno)
    try
        fcallback(F_FORGET_MULTI, req, ino)
    finally
    end
end
F_FLOCK = 40
function Cflock(req::Ptr{FuseReq}, ino::FuseIno)
    try
        fcallback(F_FLOCK, req, ino)
    finally
    end
end
F_FALLOCATE = 41
function Cfallocate(req::Ptr{FuseReq}, ino::FuseIno)
    try
        fcallback(F_FALLOCATE, req, ino)
    finally
    end
end
F_READDIRPLUS = 42
function Creaddirplus(req::Ptr{FuseReq}, ino::FuseIno)
    try
        fcallback(F_READDIRPLUS, req, ino)
    finally
    end
end
F_COPY_FILE_RANGE = 43
function Ccopy_file_range(req::Ptr{FuseReq}, ino::FuseIno)
    try
        fcallback(F_COPY_FILE_RANGE, req, ino)
    finally
    end
end
F_LSEEK = 44
function Clseek(req::Ptr{FuseReq}, ino::FuseIno)
    try
        fcallback(F_LSEEK, req, ino)
    finally
    end
end
F_SIZE = 44

# to become const
ALL_FLO = FuseLowlevelOps(
    (@cfunction Cinit Cvoid (Ptr{Nothing}, Ptr{FuseConnInfo})),
    (@cfunction Cdestroy Cvoid (Ptr{Nothing},)),
    (@cfunction Clookup Cvoid (Ptr{FuseReq}, FuseIno, Cstring)),
    (@cfunction Cforget Cvoid (Ptr{FuseReq}, FuseIno, Culong)),
    (@cfunction Cgetattr Cvoid (Ptr{FuseReq}, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Csetattr Cvoid (Ptr{FuseReq}, FuseIno, Ptr{FuseStat}, Cint, Ptr{FuseFileInfo})),
    (@cfunction Creadlink Cvoid (Ptr{FuseReq}, FuseIno)),
    (@cfunction Cmknod Cvoid (Ptr{FuseReq}, FuseIno, Cstring, FuseMode, FuseDev)),
    (@cfunction Cmkdir Cvoid (Ptr{FuseReq}, FuseIno, Cstring, FuseMode)),
    (@cfunction Cunlink Cvoid (Ptr{FuseReq}, FuseIno, Cstring)),
    (@cfunction Crmdir Cvoid (Ptr{FuseReq}, FuseIno, Cstring)),
    (@cfunction Csymlink Cvoid (Ptr{FuseReq}, Cstring, FuseIno, Cstring)),
    (@cfunction Crename Cvoid (Ptr{FuseReq}, FuseIno, Cstring, FuseIno, Cstring)),
    (@cfunction Clink Cvoid (Ptr{FuseReq}, FuseIno, FuseIno, Cstring)),
    (@cfunction Copen Cvoid (Ptr{FuseReq}, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Cread Cvoid (Ptr{FuseReq}, FuseIno, Culong, Culong)),
    (@cfunction Cwrite Cvoid (Ptr{FuseReq}, FuseIno, Cstring, Culong, Culong, Ptr{FuseFileInfo})),
    (@cfunction Cflush Cvoid (Ptr{FuseReq}, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Crelease Cvoid (Ptr{FuseReq}, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Cfsync Cvoid (Ptr{FuseReq}, FuseIno, Cint, Ptr{FuseFileInfo})),
    (@cfunction Copendir Cvoid (Ptr{FuseReq}, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Creaddir Cvoid (Ptr{FuseReq}, FuseIno, Culong, Culong, Ptr{FuseFileInfo})),
    (@cfunction Creleasedir Cvoid (Ptr{FuseReq}, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Cfsyncdir Cvoid (Ptr{FuseReq}, FuseIno, Cint, Ptr{FuseFileInfo})),
    (@cfunction Cstatfs Cvoid (Ptr{FuseReq}, FuseIno)),
    (@cfunction Csetxattr Cvoid (Ptr{FuseReq}, FuseIno, Cstring, Cstring, Culong, Cint)),
    (@cfunction Cgetxattr Cvoid (Ptr{FuseReq}, FuseIno, Cstring, Culong)),
    (@cfunction Clistxattr Cvoid (Ptr{FuseReq}, FuseIno, Culong)),
    (@cfunction Cremovexattr Cvoid (Ptr{FuseReq}, FuseIno, Cstring)),
    (@cfunction Caccess Cvoid (Ptr{FuseReq}, FuseIno, Cint)),
    (@cfunction Ccreate Cvoid (Ptr{FuseReq}, FuseIno, Cstring, FuseMode, Ptr{FuseFileStruct})),
    (@cfunction Cgetlk Cvoid (Ptr{FuseReq}, FuseIno, Ptr{FuseFileInfo}, Ptr{Flock})),
    (@cfunction Csetlk Cvoid (Ptr{FuseReq}, FuseIno, Ptr{FuseFileInfo}, Ptr{Flock}, Cint)),
    (@cfunction Cbmap Cvoid (Ptr{FuseReq}, FuseIno, Culong, Culong)),
    (@cfunction Cioctl Cvoid (Ptr{FuseReq}, FuseIno, Cuint, Ptr{Cvoid}, Ptr{FuseFileInfo}, Cuint, Ptr{Cvoid}, Culong, Culong)),
    (@cfunction Cpoll Cvoid (Ptr{FuseReq}, FuseIno, Ptr{FuseFileInfo}, Ptr{FusePollHandle})),
    (@cfunction Cwrite_buf Cvoid (Ptr{FuseReq}, FuseIno, Ptr{FuseBufvec}, Culong, Ptr{FuseFileInfo})),
    (@cfunction Cretrieve_reply Cvoid (Ptr{FuseReq}, Ptr{Cvoid}, FuseIno, Culong, Ptr{FuseBufvec})),
    (@cfunction Cforget_multi Cvoid (Ptr{FuseReq}, Culong, Ptr{FuseForgetData})),
    (@cfunction Cflock Cvoid (Ptr{FuseReq}, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Cfallocate Cvoid (Ptr{FuseReq}, FuseIno, Cint, Culong, Culong, Ptr{FuseFileInfo})),
    (@cfunction Creaddirplus Cvoid (Ptr{FuseReq}, FuseIno, Culong, Culong,Ptr{FuseFileInfo})),
    (@cfunction Ccopy_file_range Cvoid (Ptr{FuseReq}, FuseIno, Culong, Ptr{FuseFileInfo}, FuseIno, Culong, Ptr{FuseFileInfo}, Culong, Cint)),
    (@cfunction Clseek Cvoid (Ptr{FuseReq}, FuseIno, Culong, Cint, Ptr{FuseFileInfo}))
)


# Capability bits for 'fuse_conn_info.capable' and 'fuse_conn_info.want'
 
const FUSE_CAP_ASYNC_READ = (1 << 0)
const FUSE_CAP_POSIX_LOCKS = (1 << 1)
const FUSE_CAP_ATOMIC_O_TRUNC = (1 << 3)
const FUSE_CAP_EXPORT_SUPPORT = (1 << 4)
const FUSE_CAP_DONT_MASK = (1 << 6)
const FUSE_CAP_SPLICE_WRITE = (1 << 7)
const FUSE_CAP_SPLICE_MOVE = (1 << 8)
const FUSE_CAP_SPLICE_READ = (1 << 9)
const FUSE_CAP_FLOCK_LOCKS = (1 << 10)
const FUSE_CAP_IOCTL_DIR = (1 << 11)
const FUSE_CAP_AUTO_INVAL_DATA = (1 << 12)
const FUSE_CAP_READDIRPLUS = (1 << 13)
const FUSE_CAP_READDIRPLUS_AUTO = (1 << 14)
const FUSE_CAP_ASYNC_DIO = (1 << 15)
const FUSE_CAP_WRITEBACK_CACHE = (1 << 16)
const FUSE_CAP_NO_OPEN_SUPPORT = (1 << 17)
const FUSE_CAP_PARALLEL_DIROPS = (1 << 18)
const FUSE_CAP_POSIX_ACL = (1 << 19)
const FUSE_CAP_HANDLE_KILLPRIV = (1 << 20)
const FUSE_CAP_CACHE_SYMLINKS = (1 << 23) 
const FUSE_CAP_NO_OPENDIR_SUPPORT = (1 << 24)
const FUSE_CAP_EXPLICIT_INVAL_DATA = (1 << 25)
 
const FUSE_IOCTL_COMPAT = (1 << 0)
const FUSE_IOCTL_UNRESTRICTED = (1 << 1)
const FUSE_IOCTL_RETRY = (1 << 2)
const FUSE_IOCTL_DIR = (1 << 4)
const FUSE_IOCTL_MAX_IOV = 256

noop(args...) = nothing
const REGISTERED = Function[noop for i = 1:F_SIZE]
regops() = REGISTERED
# utility functions
function fcallback(which::Int, args...)
    regops()[which](args...)
end
function register(which::Int, f::Function)
    regops()[which] = f
end

function FuseLowlevelOps(all::FuseLowlevelOps, reg::Vector{Function})
    ip = enumerate(fieldnames(FuseLowlevelOps))
    ops = [reg[i] == noop ? CFunction(0) : getfield(all, p) for (i, p) in ip]
    FuseLowlevelOps(ops...)
end

