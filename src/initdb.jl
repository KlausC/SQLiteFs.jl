"""
    initdb(name)

Initialize database in file ǹame`.
Accept only empty database or database with SQLiteFs specific tables.
All not-existing tables and other DB objects are created.
Returns the db-session handle needed in all database statements.
"""
function initdb(name::AbstractString)
    db = SQLite.DB(name)
    for command in CREATE_SQL
        DBInterface.execute(db, command)
    end
    SQLite.register(db, modestring)
    
    st = FStatus(db) # initialize home directory name and inode
    create_rootnode(st, 0o04) # S_IFDIR
    st
end

CREATE_SQL = ["""
    PRAGMA FOREIGN_KEYS = TRUE;
    """,
    """
    CREATE TABLE IF NOT EXISTS inode(
        ino INTEGER PRIMARY KEY,
        nlinks INTEGER DEFAULT 0,
        mode INTEGER,
        size INTEGER,
        atime INTEGER,
        btime INTEGER,
        ctime INTEGER,
        mtime INTEGER
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS data(
        ino INTEGER,
        data BLOB,
        FOREIGN KEY (ino) REFERENCES inode ON DELETE CASCADE
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS direntry(
        dino INTEGER NOT NULL,
        name TEXT NOT NULL,
        ino INTEGER NOT NULL,
        PRIMARY KEY (dino, name ASC),
        FOREIGN KEY (ino) REFERENCES inode ON DELETE CASCADE,
        FOREIGN KEY (dino) REFERENCES inode (ino) ON DELETE CASCADE
    );
    """,
    """
    CREATE TRIGGER IF NOT EXISTS nlinks_ins INSERT ON direntry
        BEGIN
            UPDATE inode SET nlinks = nlinks + 1 WHERE ino = new.ino;
        END
    ;
    """,
    """
    CREATE TRIGGER IF NOT EXISTS nlinks_del DELETE ON direntry
        BEGIN
            UPDATE inode SET nlinks = nlinks - 1 WHERE ino = old.ino;
        END
    ;
    """,
    """
    CREATE TRIGGER IF NOT EXISTS nlinks_up UPDATE of ino ON direntry
        BEGIN
            UPDATE inode SET nlinks = nlinks - 1 WHERE ino = old.ino;
            UPDATE inode SET nlinks = nlinks + 1 WHERE ino = new.ino;
        END
    ;
    """,
    """
    CREATE TRIGGER IF NOT EXISTS nlinks_zero UPDATE of nlinks ON inode
        WHEN new.nlinks = 0
        BEGIN
            DELETE FROM inode WHERE ino = old.ino;
        END
    ;
    """,
    """
    CREATE TRIGGER IF NOT EXISTS direntry_del DELETE ON direntry
        WHEN old.ino IN (SELECT dino from direntry)
        BEGIN
            SELECT RAISE(FAIL, 'ino used as dino in table direntry');
        END
    ;
    """,
    """
    CREATE VIEW IF NOT EXISTS pathes AS
    WITH RECURSIVE pathnames (path, ino) AS
    (
        SELECT name, ino from direntry where dino <= 1
            UNION ALL
        SELECT path || '/' || name, direntry.ino FROM pathnames, direntry
            WHERE pathnames.ino = dino AND dino > 1
    )
    SELECT * FROM pathnames;
    """,
    """
    CREATE VIEW IF NOT EXISTS ls_data AS
    SELECT mode, mtime, dino, inode.ino, nlinks, name FROM inode, direntry
    WHERE direntry.ino = inode.ino
    ORDER BY dino, name;
    """,
    """
    CREATE VIEW IF NOT EXISTS ls_data_r AS
    WITH RECURSIVE under_root(ino, name, level) AS (
        SELECT ino, name, 0 FROM direntry where ino = 1
        UNION ALL
        SELECT direntry.ino, direntry.name, under_root.level + 1
        FROM direntry, under_root
        WHERE dino = under_root.ino AND dino != direntry.ino
        ORDER BY 3 DESC
        )
    SELECT printf('%*s', level, '') || name
    FROM under_root;
    """,
    ]