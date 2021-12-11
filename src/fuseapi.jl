
export FuseLowlevelOps, register, main_loop

import Base.CFunction

const CFu = Ptr{Cvoid}

struct FuseLoopConfig
    clone_fd::Cint
    max_idle_threads::Cuint
end

struct FuseArgs <: Layout
    argc::Cint
    argv::Ptr{LVarVector{Cstring, (x) -> x.argc}}
    allocated::Cint
end

struct FuseCmdlineOpts
    singlethread::Cint
    foreground::Cint
    debug::Cint
    nodefault_subtype::Cint
    mountpoint::Cstring
    show_version::Cint
    show_help::Cint
    clone_fd::Cint
    max_idle_threads::Cuint
end

struct FuseSession <: Layout
end
struct FuseLowlevelOps
    init::CFu
    destroy::CFu
    lookup::CFu
    forget::CFu
    getattr::CFu
    setattr::CFu
    readlink::CFu
    mknod::CFu
    mkdir::CFu
    unlink::CFu
    rmdir::CFu
    symlink::CFu
    rename::CFu
    link::CFu
    open::CFu
    read::CFu
    write::CFu
    flush::CFu
    release::CFu
    fsync::CFu
    opendir::CFu
    readdir::CFu
    releasedir::CFu
    fsyncdir::CFu
    statfs::CFu
    setxattr::CFu
    getxattr::CFu
    listxattr::CFu
    removexattr::CFu
    access::CFu
    create::CFu
    getlk::CFu
    setlk::CFu
    bmap::CFu
    ioctl::CFu
    poll::CFu
    write_buf::CFu
    retrieve_reply::CFu
    forget_multi::CFu
    flock::CFu
    fallocate::CFu
    readdirplus::CFu
    copy_file_range::CFu
    lseek::CFu
end

const FuseIno = UInt64
const FuseMode = UInt32
const FuseDev = UInt64

const Cuid_t = UInt32
const Cgid_t = UInt32
const Coff_t = Csize_t
const Coff64_t = UInt64
const Cpid_t = Cint
const Cfsblkcnt_t = UInt64
const Cfsfilcnt_t = UInt64

struct FuseBufFlags
    flag::Cint
end
const FUSE_BUF_IS_FD = FuseBufFlags(1 << 1)
const FUSE_BUF_FD_SEEK = FuseBufFlags(1 << 2)
const FUSE_BUF_FD_RETRY = FuseBufFlags(1 << 3)

struct FuseBufCopyFlags
    flag::Cint
end
const FUSE_BUF_NO_SPLICE = FuseBufCopyFlags(1 << 1)
const FUSE_BUF_FORCE_SPLICE = FuseBufCopyFlags(1 << 2)
const FUSE_BUF_SPLICE_MOVE = FuseBufCopyFlags(1 << 3)
const FUSE_BUF_SPLICE_NONBLOCK = FuseBufCopyFlags(1 << 4)

"""
    FuseReq

Opaque structure containing the pointer as obtained by fuselib.
"""
struct FuseReq
    pointer::Ptr{Nothing}
end

struct Timespec <: Layout
    seconds::Int64
    ns::Int64
end

struct FuseCtx <: Layout
    uid::UInt32
    gid::UInt32
    pid::UInt32
    umask::FuseMode
end

struct Cstat <: Layout
    dev     :: UInt64
    ino     :: UInt64
    nlink   :: UInt64
    mode    :: FuseMode
    uid     :: Cuid_t
    gid     :: Cgid_t
    pad0    :: UInt32
    rdev    :: UInt64
    size    :: Int64
    blksize :: Int64
    blocks  :: Int64
    atime   :: Timespec
    mtime   :: Timespec
    ctime   :: Timespec
end
struct FuseEntryParam <: Layout
    ino::FuseIno
    generation::UInt64
    attr::Cstat
    attr_timeout::Cdouble
    entry_timeout::Cdouble
end

# Capability bits for 'fuse_conn_info.capable' and 'fuse_conn_info.want'
 
const FUSE_CAP_ASYNC_READ = Cuint(1 << 0)
const FUSE_CAP_POSIX_LOCKS = Cuint(1 << 1)
const FUSE_CAP_ATOMIC_O_TRUNC = Cuint(1 << 3)
const FUSE_CAP_EXPORT_SUPPORT = Cuint(1 << 4)
const FUSE_CAP_DONT_MASK = Cuint(1 << 6)
const FUSE_CAP_SPLICE_WRITE = Cuint(1 << 7)
const FUSE_CAP_SPLICE_MOVE = Cuint(1 << 8)
const FUSE_CAP_SPLICE_READ = Cuint(1 << 9)
const FUSE_CAP_FLOCK_LOCKS = Cuint(1 << 10)
const FUSE_CAP_IOCTL_DIR = Cuint(1 << 11)
const FUSE_CAP_AUTO_INVAL_DATA = Cuint(1 << 12)
const FUSE_CAP_READDIRPLUS = Cuint(1 << 13)
const FUSE_CAP_READDIRPLUS_AUTO = Cuint(1 << 14)
const FUSE_CAP_ASYNC_DIO = Cuint(1 << 15)
const FUSE_CAP_WRITEBACK_CACHE = Cuint(1 << 16)
const FUSE_CAP_NO_OPEN_SUPPORT = Cuint(1 << 17)
const FUSE_CAP_PARALLEL_DIROPS = Cuint(1 << 18)
const FUSE_CAP_POSIX_ACL = Cuint(1 << 19)
const FUSE_CAP_HANDLE_KILLPRIV = Cuint(1 << 20)
const FUSE_CAP_CACHE_SYMLINKS = Cuint(1 << 23) 
const FUSE_CAP_NO_OPENDIR_SUPPORT = Cuint(1 << 24)
const FUSE_CAP_EXPLICIT_INVAL_DATA = Cuint(1 << 25)

struct FuseConnInfo <: Layout
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
    reserved::LFixedVector{Cuint,22}
end

# bit masks for 2nd field of FuseFileInfo
const FUSE_FI_WRITEPAGE = Cuint(1 << 0)
const FUSE_FI_DIRECT_IO = Cuint(1 << 1)
const FUSE_FI_KEEP_CACHE = Cuint(1 << 2)
const FUSE_FI_FLUSH = Cuint(1 << 3)
const FUSE_FI_NONSEEKABLE = Cuint(1 << 4)
const FUSE_FI_CACHE_READDIR = Cuint(1 << 5)

struct FuseFileInfo <: Layout
    flags::Cint
    bits::Cuint
    fh::UInt64
    lock_owner::UInt64
    poll_events::UInt32
end

struct Cflock
    type::Cshort
    whence::Cshort
    start::Coff64_t
    len::Coff64_t
    pid::Cpid_t
end
struct Ciovec
    base::Ptr{Cvoid}
    len::Csize_t
end
struct Cstatvfs
    bsize::Culong
    frsize::Culong
    blocks::Cfsblkcnt_t
    bfree::Cfsblkcnt_t
    bavail::Cfsblkcnt_t
    files::Cfsfilcnt_t
    ffree::Cfsfilcnt_t
    favail::Cfsfilcnt_t
    fsid::Clong
    flag::Culong
    namemax::Culong
    __spare::NTuple{6,Cint}
end

struct FusePollHandle
end
struct FuseBuf <: Layout
    size::Csize_t
    flags::FuseBufFlags
    mem::Ptr{Cvoid}
    fd::Cint
    pos::Coff_t
end
struct FuseBufvec <: Layout
    count::Csize_t
    idx::Csize_t
    off::Csize_t
    buf::LVarVector{FuseBuf}
end
struct FuseForgetData
end

const FUSE_IOCTL_COMPAT = Cuint(1 << 0)
const FUSE_IOCTL_UNRESTRICTED = Cuint(1 << 1)
const FUSE_IOCTL_RETRY = Cuint(1 << 2)
const FUSE_IOCTL_DIR = Cuint(1 << 4)
const FUSE_IOCTL_MAX_IOV = 256

# C- entrypoints for all lowlevel callback functions

F_INIT = 1
function Cinit(userdata::Ptr{Nothing}, conn::Ptr{Nothing})
    try
        println("Cinit called")
        fcallback(F_INIT, userdata, CStruct{FuseConnInfo}(conn))
    finally
    end
end
F_DESTROY = 2
function Cdestroy(userdata::Ptr{Nothing})
    try
        fcallback(F_DESTROY, userdata)
    finally
    end
end
F_LOOKUP = 3
function Clookup(req::FuseReq, parent::FuseIno, name::Cstring)
    error = Base.UV_ENOTSUP
    name = unsafe_string(name)
    try
        println("Clookup called req=$req parent=$parent name=$name")
        entry = CStruct{FuseEntryParam}(pointer_from_vector(create_bytes(FuseEntryParam, ())))
        error = fcallback(F_LOOKUP, req, parent, name, entry)
        println("back from lookup entry=$(error == 0 ? entry : "")")
        error == 0 && fuse_reply_entry(req, entry)
        error == 0 && println("after fuse_reply_entry")
    finally
        error != 0 && fuse_reply_err(req, -error)
        error != 0 && println("fuse_reply_err(req, $(-error))")
    end
    nothing
end
F_FORGET = 4
function Cforget(req::Ptr{Nothing}, ino::FuseIno, lookup::UInt64)
    try
        fcallback(F_FORGET, CStruct{FuseReq}(req), ino, lookup)
    finally
    end
end
F_GETATTR = 5
function Cgetattr(req::Ptr{Nothing}, ino::FuseIno, fi::FuseFileInfo)
    try
        fcallback(F_GETATTR, CStruct{FuseReq}(req), ino, fi)
        # fuse_reply_attr(req, attr, attr_timeout)
    finally
    end
end
F_SETATTR = 6
function Csetattr(req::Ptr{Nothing}, ino::FuseIno, attr::Cstat, to_set::Cint, fi::FuseFileInfo)
    try
        fcallback(F_SETATTR, CStruct{FuseReq}(req), ino, attr, to_set, fi)
        # fuse_reply_attr(req, attr, attr_timeout)
    finally
    end
end
F_READLINK = 7
function Creadlink(req::Ptr{Nothing}, ino::FuseIno)
    try
        fcallback(F_READLINK, CStruct{FuseReq}(req), ino)
    finally
    end
end
F_MKNOD = 8
function Cmknod(req::Ptr{Nothing}, parent::FuseIno, name::String, mode::FuseMode, rdev::FuseDev)
    try
        fcallback(F_MKNOD, CStruct{FuseReq}(req), parent, name, mode, rdev)
    finally
    end
end
F_MKDIR = 9
function Cmkdir(req::Ptr{Nothing}, parent::FuseIno, name::String, mode::FuseMode) 
    try
        fcallback(F_MKDIR, CStruct{FuseReq}(req), parent, name, mode)
    finally
    end
end
F_UNLINK = 10
function Cunlink(req::Ptr{Nothing}, parent::FuseIno, name::String)
    try
        fcallback(F_UNLINK, CStruct{FuseReq}(req), parent, name)
    finally
    end
end
F_RMDIR = 11
function Crmdir(req::Ptr{Nothing}, parent::FuseIno, name::String)
    try
        fcallback(F_RMDIR, CStruct{FuseReq}(req), parent, name)
    finally
    end
end
F_SYMLINK = 12
function Csymlink(req::Ptr{Nothing}, link::String, parent::FuseIno, name::String)
    try
        fcallback(F_SYMLINK, CStruct{FuseReq}(req), link, parent, name)
    finally
    end
end
F_RENAME = 13
function Crename(req::Ptr{Nothing}, parent::FuseIno, name::String, newparent::FuseIno, newname::String, flags::Cuint)
    try
        fcallback(F_RENAME, CStruct{FuseReq}(req), parent, name, newparent, newname, flags)
    finally
    end
end
F_LINK = 14
function Clink(req::Ptr{Nothing}, ino::FuseIno, newparent::FuseIno, newname::String)
    try
        fcallback(F_LINK, CStruct{FuseReq}(req), ino, newparent, newname)
    finally
    end
end
F_OPEN = 15
function Copen(req::Ptr{Nothing}, ino::FuseIno, fi::FuseFileInfo)
    try
        fcallback(F_OPEN, CStruct{FuseReq}(req), ino, fi)
    finally
    end
end
F_READ = 16
function Cread(req::Ptr{Nothing}, ino::FuseIno, size::Csize_t, off::Csize_t, fi::FuseFileInfo)
    try
        fcallback(F_READ, CStruct{FuseReq}(req), ino, size, off, fi)
    finally
    end
end
F_WRITE = 17
function Cwrite(req::Ptr{Nothing}, ino::FuseIno, buf::Vector{UInt8}, size::Csize_t, off::Csize_t, fi::FuseFileInfo)
    try
        fcallback(F_WRITE, CStruct{FuseReq}(req), ino, buf, size, off, fi)
    finally
    end
end
F_FLUSH = 18
function Cflush(req::Ptr{Nothing}, ino::FuseIno, fi::FuseFileInfo)
    try
        fcallback(F_FLUSH, CStruct{FuseReq}(req), ino, fi)
    finally
    end
end
F_RELEASE = 19
function Crelease(req::Ptr{Nothing}, ino::FuseIno, fi::FuseFileInfo)
    try
        fcallback(F_RELEASE, CStruct{FuseReq}(req), ino, fi)
    finally
    end
end
F_FSYNC = 20
function Cfsync(req::Ptr{Nothing}, ino::FuseIno, datasync::Cint, fi::FuseFileInfo)
    try
        fcallback(F_FSYNC, CStruct{FuseReq}(req), ino, datasync, fi)
    finally
    end
end
F_OPENDIR = 21
function Copendir(req::Ptr{Nothing}, ino::FuseIno, fi::FuseFileInfo)
    try
        fcallback(F_OPENDIR, CStruct{FuseReq}(req), ino)
    finally
    end
end
F_READDIR = 22
function Creaddir(req::Ptr{Nothing}, ino::FuseIno, size::Csize_t, off::Csize_t, fi::FuseFileInfo)
    try
        fcallback(F_READDIR, CStruct{FuseReq}(req), ino, size, off, fi)
    finally
    end
end
F_RELEASEDIR = 23
function Creleasedir(req::Ptr{Nothing}, ino::FuseIno, fi::FuseFileInfo)
    try
        fcallback(F_RELEASEDIR, CStruct{FuseReq}(req), ino, fi)
    finally
    end
end
F_FSYNCDIR = 24
function Cfsyncdir(req::Ptr{Nothing}, ino::FuseIno, datasync::Cint, fi::FuseFileInfo)
    try
        fcallback(F_FSYNCDIR, CStruct{FuseReq}(req), ino, datasync, fi)
    finally
    end
end
F_STATFS = 25
function Cstatfs(req::Ptr{Nothing}, ino::FuseIno)
    try
        fcallback(F_STATFS, CStruct{FuseReq}(req), ino)
    finally
    end
end
F_SETXATTR = 26
function Csetxattr(req::Ptr{Nothing}, ino::FuseIno, name::String, value::String, size::Csize_t, flags::Cint)
    try
        fcallback(F_SETXATTR, CStruct{FuseReq}(req), ino, name, value, size, flags)
    finally
    end
end
F_GETXATTR = 27
function Cgetxattr(req::Ptr{Nothing}, ino::FuseIno, name::String, size::Csize_t)
    try
        fcallback(F_GETXATTR, CStruct{FuseReq}(req), ino, name, size)
    finally
    end
end
F_LISTXATTR = 28
function Clistxattr(req::Ptr{Nothing}, ino::FuseIno, size::Csize_t)
    try
        fcallback(F_LISTXATTR, CStruct{FuseReq}(req), ino, size)
    finally
    end
end
F_REMOVEXATTR = 29
function Cremovexattr(req::Ptr{Nothing}, ino::FuseIno, name::String)
    try
        fcallback(F_REMOVEXATTR, CStruct{FuseReq}(req), ino, name)
    finally
    end
end
F_ACCESS = 30
function Caccess(req::Ptr{Nothing}, ino::FuseIno, mask::Cint)
    try
        fcallback(F_ACCESS, CStruct{FuseReq}(req), ino, mask)
    finally
    end
end
F_CREATE = 31
function Ccreate(req::Ptr{Nothing}, parent::FuseIno, name::String, mode::FuseMode, fi::FuseFileInfo)
    try
        fcallback(F_CREATE, CStruct{FuseReq}(req), parent, name, mode, fi)
    finally
    end
end
F_GETLK = 32
function Cgetlk(req::Ptr{Nothing}, ino::FuseIno, fi::FuseFileInfo, lock::Cflock)
    try
        fcallback(F_GETLK, CStruct{FuseReq}(req), ino, fi, lock)
    finally
    end
end
F_SETLK = 33
function Csetlk(req::Ptr{Nothing}, ino::FuseIno, fi::FuseFileInfo, lock::Cflock, sleep::Cint)
    try
        fcallback(F_SETLK, CStruct{FuseReq}(req), ino, fi, lock, sleep)
    finally
    end
end
F_BMAP = 34
function Cbmap(req::Ptr{Nothing}, ino::FuseIno)
    try
        fcallback(F_BMAP, CStruct{FuseReq}(req), ino)
    finally
    end
end
F_IOCTL = 35
function Cioctl(req::Ptr{Nothing}, ino::FuseIno)
    try
        fcallback(F_IOCTL, CStruct{FuseReq}(req), ino)
    finally
    end
end
F_POLL = 36
function Cpoll(req::Ptr{Nothing}, ino::FuseIno)
    try
        fcallback(F_POLL, CStruct{FuseReq}(req), ino)
    finally
    end
end
F_WRITE_BUF = 37
function Cwrite_buf(req::Ptr{Nothing}, ino::FuseIno)
    try
        fcallback(F_WRITE_BUF, CStruct{FuseReq}(req), ino)
    finally
    end
end
F_RETRIEVE_REPLY = 38
function Cretrieve_reply(req::Ptr{Nothing}, ino::FuseIno)
    try
        fcallback(F_RETRIEVE_REPLY, CStruct{FuseReq}(req), ino)
    finally
    end
end
F_FORGET_MULTI = 39
function Cforget_multi(req::Ptr{Nothing}, ino::FuseIno)
    try
        fcallback(F_FORGET_MULTI, CStruct{FuseReq}(req), ino)
    finally
    end
end
F_FLOCK = 40
function Cflock(req::Ptr{Nothing}, ino::FuseIno)
    try
        fcallback(F_FLOCK, CStruct{FuseReq}(req), ino)
    finally
    end
end
F_FALLOCATE = 41
function Cfallocate(req::Ptr{Nothing}, ino::FuseIno)
    try
        fcallback(F_FALLOCATE, CStruct{FuseReq}(req), ino)
    finally
    end
end
F_READDIRPLUS = 42
function Creaddirplus(req::Ptr{Nothing}, ino::FuseIno)
    try
        fcallback(F_READDIRPLUS, CStruct{FuseReq}(req), ino)
    finally
    end
end
F_COPY_FILE_RANGE = 43
function Ccopy_file_range(req::Ptr{Nothing}, ino::FuseIno)
    try
        fcallback(F_COPY_FILE_RANGE, CStruct{FuseReq}(req), ino)
    finally
    end
end
F_LSEEK = 44
function Clseek(req::Ptr{Nothing}, ino::FuseIno)
    try
        fcallback(F_LSEEK, CStruct{FuseReq}(req), ino)
    finally
    end
end

F_SIZE = 44

# to become const
ALL_FLO() = [
    (@cfunction Cinit Cvoid (Ptr{Nothing}, Ptr{Nothing})),
    (@cfunction Cdestroy Cvoid (Ptr{Nothing},)),
    (@cfunction Clookup  Cvoid (FuseReq, FuseIno, Cstring)),
    (@cfunction Cforget Cvoid (FuseReq, FuseIno, Culong)),
    (@cfunction Cgetattr Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Csetattr Cvoid (FuseReq, FuseIno, Ptr{Cstat}, Cint, Ptr{FuseFileInfo})),
    (@cfunction Creadlink Cvoid (FuseReq, FuseIno)),
    (@cfunction Cmknod Cvoid (FuseReq, FuseIno, Cstring, FuseMode, FuseDev)),
    (@cfunction Cmkdir Cvoid (FuseReq, FuseIno, Cstring, FuseMode)),
    (@cfunction Cunlink Cvoid (FuseReq, FuseIno, Cstring)),
    (@cfunction Crmdir Cvoid (FuseReq, FuseIno, Cstring)),
    (@cfunction Csymlink Cvoid (FuseReq, Cstring, FuseIno, Cstring)),
    (@cfunction Crename Cvoid (FuseReq, FuseIno, Cstring, FuseIno, Cstring)),
    (@cfunction Clink Cvoid (FuseReq, FuseIno, FuseIno, Cstring)),
    (@cfunction Copen Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Cread Cvoid (FuseReq, FuseIno, Culong, Culong)),
    (@cfunction Cwrite Cvoid (FuseReq, FuseIno, Cstring, Culong, Culong, Ptr{FuseFileInfo})),
    (@cfunction Cflush Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Crelease Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Cfsync Cvoid (FuseReq, FuseIno, Cint, Ptr{FuseFileInfo})),
    (@cfunction Copendir Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Creaddir Cvoid (FuseReq, FuseIno, Culong, Culong, Ptr{FuseFileInfo})),
    (@cfunction Creleasedir Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Cfsyncdir Cvoid (FuseReq, FuseIno, Cint, Ptr{FuseFileInfo})),
    (@cfunction Cstatfs Cvoid (FuseReq, FuseIno)),
    (@cfunction Csetxattr Cvoid (FuseReq, FuseIno, Cstring, Cstring, Culong, Cint)),
    (@cfunction Cgetxattr Cvoid (FuseReq, FuseIno, Cstring, Culong)),
    (@cfunction Clistxattr Cvoid (FuseReq, FuseIno, Culong)),
    (@cfunction Cremovexattr Cvoid (FuseReq, FuseIno, Cstring)),
    (@cfunction Caccess Cvoid (FuseReq, FuseIno, Cint)),
    (@cfunction Ccreate Cvoid (FuseReq, FuseIno, Cstring, FuseMode, Ptr{FuseFileInfo})),
    (@cfunction Cgetlk Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Ptr{Cflock})),
    (@cfunction Csetlk Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Ptr{Cflock}, Cint)),
    (@cfunction Cbmap Cvoid (FuseReq, FuseIno, Culong, Culong)),
    (@cfunction Cioctl Cvoid (FuseReq, FuseIno, Cuint, Ptr{Cvoid}, Ptr{FuseFileInfo}, Cuint, Ptr{Cvoid}, Culong, Culong)),
    (@cfunction Cpoll Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo}, Ptr{FusePollHandle})),
    (@cfunction Cwrite_buf Cvoid (FuseReq, FuseIno, Ptr{FuseBufvec}, Culong, Ptr{FuseFileInfo})),
    (@cfunction Cretrieve_reply Cvoid (FuseReq, Ptr{Cvoid}, FuseIno, Culong, Ptr{FuseBufvec})),
    (@cfunction Cforget_multi Cvoid (FuseReq, Culong, Ptr{FuseForgetData})),
    (@cfunction Cflock Cvoid (FuseReq, FuseIno, Ptr{FuseFileInfo})),
    (@cfunction Cfallocate Cvoid (FuseReq, FuseIno, Cint, Culong, Culong, Ptr{FuseFileInfo})),
    (@cfunction Creaddirplus Cvoid (FuseReq, FuseIno, Culong, Culong,Ptr{FuseFileInfo})),
    (@cfunction Ccopy_file_range Cvoid (FuseReq, FuseIno, Culong, Ptr{FuseFileInfo}, FuseIno, Culong, Ptr{FuseFileInfo}, Culong, Cint)),
    (@cfunction Clseek Cvoid (FuseReq, FuseIno, Culong, Cint, Ptr{FuseFileInfo}))
]


# dummy function - should never by actually called
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
function register(which::Symbol, f::Function)
    index = findfirst(isequal(which), fieldnames(FuseLowlevelOps))
    register(index, f)
end
register(f::Function) = register(nameof(f), f)

function FuseLowlevelOps(all::FuseLowlevelOps, reg::Vector{Function})
    FuseLowlevelOps(filter_ops(all, reg)...)
end
function filter_ops(all::Vector, reg::Vector{Function})
    [reg[i] == noop ? C_NULL : all[i] for i in eachindex(all)]
end

function create_args(CMD::String, ARGS::AbstractVector{String})
    argc = length(ARGS)
    data = create_bytes(FuseArgs, argc + 2)
    args = CStruct{FuseArgs}(pointer_from_vector(data))
    argv = args.argv
    args.argc = argc + 1
    argv[1] = CMD
    for i = 1:argc
        argv[i+1] = ARGS[i]
    end
    data
end

function main_loop(args::AbstractVector{String})

    fuseargs = CStructGuided{FuseArgs}(create_args("command", args))
    opts = fuse_parse_cmdline(fuseargs)

    callbacks = filter_ops(ALL_FLO(), regops())

    se = ccall((:fuse_session_new, :libfuse3), Ptr{Nothing},
        (Ptr{FuseArgs}, Ptr{CFu}, Cint, Ptr{Nothing}),
        fuseargs, callbacks, length(callbacks), C_NULL)

    se == C_NULL && throw(ArgumentError("fuse_session_new failed"))

    rc = ccall((:fuse_session_mount, :libfuse3), Cint, (Ptr{Nothing}, Cstring), se, opts.mountpoint)
    rc != 0 && throw(ArgumentError("fuse_session_mount failed"))

    rc = ccall((:fuse_session_loop, :libfuse3), Cint, (Ptr{Nothing},), se)
    rc != 0 && throw(ArgumentError("fuse_session_loop failed"))

    ccall((:fuse_session_unmount, :libfuse3), Cvoid, (Ptr{Nothing},), se)
    ccall((:fuse_session_destroy, :libfuse3), Cvoid, (Ptr{Nothing},), se)
end

# reply functions to be called inside callback functions

function fuse_reply_attr(req::FuseReq, attr::CStruct{Cstat}, attr_timeout::Real)
    ccall((:fuse_reply_attr, :libfuse3), Cint, (FuseReq, Ptr{Cstat}, Cdouble), req, attr, attr_timeout)
end
function fuse_reply_bmap(req::FuseReq, idx::Integer)
    ccall((:fuse_reply_bmap, :libfuse3), Cint, (FuseReq, UInt64), req, idx)
end
function fuse_reply_buf(req::FuseReq, buf::Vector{UInt8}, size::Integer)
    ccall((:fuse_reply_entry, :libfuse3), Cint, (FuseReq, Ptr{UInt8}, Csize_t), req, buf, size)
end
function fuse_reply_create(req::FuseReq, e::CStruct{FuseEntryParam}, fi::CStruct{FuseFileInfo})
    ccall((:fuse_reply_create, :libfuse3), Cint, (FuseReq, Ptr{FuseEntryParam}, Ptr{FuseFileInfo}), req, e, fi)
end
function fuse_reply_data(req::FuseReq, bufv::CStruct{FuseBufvec}, flags::FuseBufCopyFlags)
    ccall((:fuse_reply_data, :libfuse3), Cint, (FuseReq, Ptr{FuseBufvec}, Cint), req, bufv, flags)
end
function fuse_reply_entry(req::FuseReq, entry::CStruct{FuseEntryParam})
    ccall((:fuse_reply_entry, :libfuse3), Cint, (FuseReq, Ptr{FuseEntryParam}), req, entry)
end
function fuse_reply_err(req::FuseReq, err::Integer)
    ccall((:fuse_reply_err, :libfuse3), Cint, (FuseReq, Cint), req, err)
end
function fuse_reply_ioctl(req::FuseReq, result::Integer, buf::CStruct, size::Integer)
    ccall((:fuse_reply_ioctl, :libfuse3), Cint, (FuseReq, Cint, Ptr{Nothing}, Csize_t), req, result, buf, size)
end
function fuse_reply_ioctl_iov(req::FuseReq, result::Integer, iov::CStruct{Ciovec}, count::Integer)
    ccall((:fuse_reply_ioctl_iov, :libfuse3), Cint, (FuseReq, Cint, Ptr{Ciovec}, Cint), req, result, iov, count)
end
function fuse_reply_ioctl_retry(req::FuseReq, in_iov::CStruct{Ciovec}, in_count::Integer, out_iov::CStruct{Ciovec}, out_count::Integer)
    ccall((:fuse_reply_ioctl_retry, :libfuse3), Cint, (FuseReq, Ptr{Ciovec}, Csize_t, Ptr{Ciovec}, Csize_t), req, in_iov, in_count, out_iov, out_count)
end
function fuse_reply_iov(req::FuseReq, iov::CStruct{Ciovec}, count::Integer)
    ccall((:fuse_reply_iov, :libfuse3), Cint, (FuseReq, Ptr{Ciovec}, Cint), req, iov, count)
end
function fuse_reply_lock(req::FuseReq, lock::CStruct{Cflock})
    ccall((:fuse_reply_lock, :libfuse3), Cint, (FuseReq, Ptr{Cflock}), req, lock)
end
function fuse_reply_lseek(req::FuseReq, off::Integer)
    ccall((:fuse_reply_lseek, :libfuse3), Cint, (FuseReq, Coff_t), req, off)
end
function fuse_reply_none(req::FuseReq)
    ccall((:fuse_reply_none, :libfuse3), Cint, (FuseReq, ), req)
end
function fuse_reply_open(req::FuseReq, fi::CStruct{FuseFileInfo})
    ccall((:fuse_reply_open, :libfuse3), Cint, (FuseReq, Ptr{FuseFileInfo}), req, fi)
end
function fuse_reply_poll(req::FuseReq, revents::Integer )
    ccall((:fuse_reply_entry, :libfuse3), Cint, (FuseReq, Cuint), req, revents)
end
function fuse_reply_readlink(req::FuseReq, link::String)
    ccall((:fuse_reply_readlink, :libfuse3), Cint, (FuseReq, Cstring), req, link)
end
function fuse_reply_statfs(req::FuseReq, stbuf::CStruct{Cstatvfs})
    ccall((:fuse_reply_statfs, :libfuse3), Cint, (FuseReq, Ptr{Cstatvfs}), req, stbuf)
end
function fuse_reply_write(req::FuseReq, count::Integer)
    ccall((:fuse_reply_write, :libfuse3), Cint, (FuseReq, Csize_t), req, count)
end
function fuse_reply_xattr(req::FuseReq, count::Integer)
    ccall((:fuse_reply_xattr, :libfuse3), Cint, (FuseReq, Csize_t), req, count)
end

# accessors for req
function fuse_req_ctx(req::FuseReq)
    CStruct{FuseCtx}(ccall((:fuse_req_ctx, :libfuse3), Ptr{FuseCtx}, (FuseReq,), req))
end
function fuse_req_getgroups(req::FuseReq, list::Vector{Cgid_t})
    ccall((:fuse_req_getgroups, :libfuse3), Cint, (FuseReq, Cint, Ptr{Cgid_t}), req, length(list), pointer_from_vector(list))
end
function fuse_req_interrupt_func(req::FuseReq, func::Ptr{Nothing}, data::Any)
    ccall((:fuse_req_ctx, :libfuse3), Cvoid, (FuseReq, Ptr{Nothing}, Ptr{Nothing}), req, func, data)
end
function fuse_req_interrupted(req::FuseReq)
    ccall((:fuse_req_interrupted, :libfuse3), Cint, (FuseReq,), req)
end
function fuse_req_userdata(req::FuseReq)
    ccall((:fuse_req_userdata, :libfuse3), Ptr{Nothing}, (FuseReq,), req)
end
function fuse_req_userdata(req::FuseReq, ::Type{T}) where T
    unsafe_pointer_to_objref(ccall((:fuse_req_userdata, :libfuse3), Ptr{T}, (FuseReq,), req))
end

function fuse_parse_cmdline(args::CStructAccess{FuseArgs})
    opts = create_bytes(FuseCmdlineOpts, ())
    popts = pointer_from_vector(opts)
    ccall((:fuse_parse_cmdline, :libfuse3), Cint, (Ptr{FuseArgs}, Ptr{UInt8}), args, popts)
    CStructGuided{FuseCmdlineOpts}(opts)
end




# Base.unsafe_convert(::Type{Ptr{FuseReq}}, cs::FuseReq) where T = Ptr{FuseReq}(cs.pointer)
