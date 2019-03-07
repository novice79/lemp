
let ws;
const ws_url = "ws://" + window.location.host + location.pathname + '/ws';
+function init() {
    console.log(`ws_url=${ws_url}`);
    ws = new WebSocket(ws_url);
    ws.onmessage = on_message;
    ws.onclose = on_close;
    ws.onerror = on_error;
    ws.onopen = on_open;
}();
function send(data) {
    ws.send(JSON.stringify(data));
}
function on_message(evt) {
    const data = evt.data;
    console.log('recieved:' + data)
}
function on_error(err) {
    console.log('onerror', err)
}
function on_close() {
    init()
    console.log('onclose')
}
function on_open() {
    send({
        cmd: 'reg_cli_id',
        data: 'cli_id'
    })
    console.log('onopen')
}

function test_post() {
    $.ajax({
        type: "POST",
        url: '/ajax_relay',
        timeout: 3000,
        contentType: "application/json; charset=utf-8",
        data: JSON.stringify({
            url: 'http://ny.cninone.com/index.php?route=api/equipment',
            data: {

            }
        }),
        dataType: "json"
    }).done((resp) => {
        console.log('success', resp);
    }).fail((err) => {
        console.log('failed: ', err);
    })
}

function log(str) {
    $(".logs").prepend(`${moment().format("YYYY-MM-DD HH:mm:ss")}: <i>${str}</i><br>`);
}
