const os = require("os");
const fs = require('fs');
const path = require('path');
const app = require('express')();
const jwt = require('jsonwebtoken');
const bodyParser = require('body-parser')
const server = require('http').Server(app);
const mysql = require('mysql');
const WebSocket = require('ws');
const wss = new WebSocket.Server({ 
    server, 
    // path: "/ws" 
});

const port = 7000;
app.use(bodyParser.json());       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({     // to support URL-encoded bodies
    extended: true
}));
const pool = mysql.createPool({
    host: '127.0.0.1',
    user: process.env.MYSQL_USER,
    password: process.env.MYSQL_PASSWORD,
    database: process.env.MYSQL_DATABASE
});

// some util functions begin-----------------------
function pad(num, size) {
    let s = num + "";
    while (s.length < size) s = "0" + s;
    return s;
}
const now_str =
    (dt = new Date()) =>
        `${dt.getFullYear()}-${dt.getMonth() + 1}-${dt.getDate()} ${dt.getHours()}:${dt.getMinutes()}:${dt.getSeconds()}.${pad(dt.getMilliseconds(), 3)}`
            .replace(/\b\d\b/g, '0$&');

console.logCopy = console.log.bind(console);
console.log = function (...args) {
    if (args.length) {
        this.logCopy(`[${now_str()}]`, ...args);
    }
};

app.use(require('express').static(path.join(__dirname, 'public')));
server.listen(port, () => {
    console.log(`express server listen on ${port}`);
});
app.get('/test', function (req, res) {

    res.end("Hello world from nodejs");
});
app.get('/test_db', function (req, res) {
    // pool.query('UPDATE aaa_orders SET name = ? WHERE id = ?', [name, 1], function (error, results, fields) {
    pool.query('SELECT * from wp_users', function (error, rows, fields) {
        if (error) return res.end(JSON.stringify({ ...error, ret: -1 }));
        //console.log('select return: ', rows);
        const ret = { ...rows[0], ret: 0 }
        res.end(JSON.stringify(ret));
    });
    // });
});
app.post('/test', function (req, res) {
    if (!req.body) return res.sendStatus(400);
    let data = req.body;
    res.json({ ret: 0 });
});
app.post('/wp_admin', function (req, res) {
    const data = req.body;
    console.log(`/wp_admin request data: `, data);
    if (!(data && data.token)) return res.sendStatus(400);

    jwt.verify(data.token, os.hostname(), (err, decoded) => {
        if (err) {
            res.json({ ret: -1 });
        } else {
            res.json({
                ret: 0,
                decoded
            });
        }

    });

});
wss.broadcast = data=> {
    wss.clients.forEach( client=> {
        if (client.readyState === WebSocket.OPEN) {
            client.send(data);
        }
    });
};
wss.on('connection', (ws) => {
    ws.on('message', message => {
        console.log('ws server received:' + message);
    });

    ws.send('something');
});