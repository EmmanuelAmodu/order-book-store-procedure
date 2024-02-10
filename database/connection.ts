import mysql from 'mysql';

export const connection = mysql.createConnection({
  host     : 'localhost',
  user     : 'localhost',
  password : 'secret',
  database : 'my_db'
});
