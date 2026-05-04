require('dotenv').config();
let sql = require('mssql');

if (process.env.USE_WINDOWS_AUTH === 'true') {
    sql = require('mssql/msnodesqlv8');
}

const config = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER || 'localhost',
    database: process.env.DB_NAME || 'LogisticGiaoDoAn',
    options: {
        encrypt: false, 
        trustServerCertificate: true 
    }
};

// Nếu dùng Windows Authentication (chỉ chạy được trên Windows với msnodesqlv8)
if (process.env.USE_WINDOWS_AUTH === 'true') {
    config.driver = 'msnodesqlv8';
    config.options.trustedConnection = true;
    delete config.user;
    delete config.password;
    // connectionString dành riêng cho msnodesqlv8
    config.connectionString = `Server=${config.server};Database=${config.database};Trusted_Connection=yes;Driver={ODBC Driver 18 for SQL Server};TrustServerCertificate=yes;`;
}

const poolPromise = new sql.ConnectionPool(config)
  .connect()
  .then(pool => {
    console.log('✅ Connected to MS SQL Server');
    return pool;
  })
  .catch(err => {
    console.error('❌ Database Connection Failed!', err);
    // process.exit(1);
  });

module.exports = {
  sql, poolPromise
};
