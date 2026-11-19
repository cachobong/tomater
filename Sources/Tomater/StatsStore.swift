import Foundation
import SQLite3

/// Local SQLite log of completed work timers.
/// File: ~/Library/Application Support/Tomater/tomater.sqlite
final class StatsStore {
    private var db: OpaquePointer?

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Tomater", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let path = dir.appendingPathComponent("tomater.sqlite").path

        if sqlite3_open(path, &db) != SQLITE_OK {
            NSLog("Tomater: cannot open database at \(path)")
            db = nil
            return
        }
        sqlite3_exec(db, """
            CREATE TABLE IF NOT EXISTS pomodoros (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                completed_at REAL NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_pomodoros_completed_at ON pomodoros(completed_at);
            """, nil, nil, nil)
    }

    deinit { sqlite3_close(db) }

    func add(_ date: Date) {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "INSERT INTO pomodoros (completed_at) VALUES (?)", -1, &stmt, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_double(stmt, 1, date.timeIntervalSince1970)
        sqlite3_step(stmt)
    }

    func count(from start: Date, to end: Date) -> Int {
        var stmt: OpaquePointer?
        let sql = "SELECT COUNT(*) FROM pomodoros WHERE completed_at >= ? AND completed_at < ?"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_double(stmt, 1, start.timeIntervalSince1970)
        sqlite3_bind_double(stmt, 2, end.timeIntervalSince1970)
        return sqlite3_step(stmt) == SQLITE_ROW ? Int(sqlite3_column_int64(stmt, 0)) : 0
    }

    func countToday() -> Int {
        let start = Calendar.current.startOfDay(for: Date())
        return count(from: start, to: Calendar.current.date(byAdding: .day, value: 1, to: start)!)
    }

    /// Seven daily counts, starting at `weekStart`.
    func dailyCounts(weekStart: Date) -> [Int] {
        let cal = Calendar.current
        return (0..<7).map { offset in
            let start = cal.date(byAdding: .day, value: offset, to: weekStart)!
            let end = cal.date(byAdding: .day, value: 1, to: start)!
            return count(from: start, to: end)
        }
    }
}
