const mysql = require('mysql2/promise');

async function main() {
    const connection = await mysql.createConnection({
        host: 'localhost',
        user: 'root',
        password: 'transcow90',
        database: 'Qbox_1F39B9'
    });

    try {
        const [columns] = await connection.query('SHOW COLUMNS FROM police_incidents;');
        console.log("police_incidents columns:");
        console.log(columns.map(c => ({ Field: c.Field, Type: c.Type, Null: c.Null })));
    } catch (err) {
        console.error("Database query failed:", err);
    } finally {
        await connection.end();
    }
}

main();
