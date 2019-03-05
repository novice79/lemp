
function is_valid_domain(domain) { 
    const re = new RegExp(/^((?:(?:(?:\w[\.\-\+]?)*)\w)+)((?:(?:(?:\w[\.\-\+]?){0,62})\w)+)\.(\w{2,6})$/); 
    return domain.match(re);
} 
jQuery(function ($) {
    function log(str) {
        $(".logs").prepend(`${moment().format("YYYY-MM-DD HH:mm:ss")}: <i>${str}</i><br>`);
    }
    $('#renew').click(() => {
        $.ajax({
            type: "POST",
            url: wpObj.renew_url,
            beforeSend: function ( xhr ) {
                xhr.setRequestHeader( 'X-WP-Nonce', wpObj.nonce );
            },
            timeout: 3000,
            contentType: "application/json; charset=utf-8",
            data: JSON.stringify({
                'cmd': 'renew'
            }),
            dataType: "json"
        }).done(resp => {
            console.log("success", resp);
            const msg = resp.msg.replace(/\n/g, '<br>');
            log(msg);
            $.notify( msg, {type:"info", align:"center", verticalAlign:"middle"});
        }).fail(err => {
            console.log("failed: ", err);
            log(JSON.stringify(err));
            $.notify( JSON.stringify(err), {type:"info", align:"center", verticalAlign:"middle"});
        });
        
    })
    // console.log('loaded my script', wpObj);
    $('#apply').click(() => {
        let dn = $('#domain').val().trim();
        let em = $('#email').val().trim();
        if( !(dn && em) ){
            return $.notify( '域名或邮箱不能为空', {type:"info", align:"center", verticalAlign:"middle"});
        }
        if( !is_valid_domain(dn) ){
            return $.notify( '域名格式非法', {type:"info", align:"center", verticalAlign:"middle"});
        }
        $("#apply").attr("disabled", true);
        $.notify( "申请SSL证书中，请稍等……", {delay:0, type:"info", align:"center", verticalAlign:"middle"});
        $.ajax({
            type: "POST",
            url: wpObj.apply_url,
            beforeSend: function ( xhr ) {
                xhr.setRequestHeader( 'X-WP-Nonce', wpObj.nonce );
            },
            // timeout: 3000,
            contentType: "application/json; charset=utf-8",
            data: JSON.stringify({
                'domain': dn,
                'email': em,
            }),
            dataType: "json"
        }).done(resp => {
            console.log("success", resp);
            const msg = resp.msg.replace(/\n/g, '<br>');
            $.notify( msg, {type:"info", align:"center", verticalAlign:"middle"});
            log(msg);
            $("#apply").removeAttr("disabled");
        }).fail(err => {
            console.log("failed: ", err);
            log(JSON.stringify(err));
            $.notify( JSON.stringify(err), {type:"info", align:"center", verticalAlign:"middle"});
            $("#apply").removeAttr("disabled");
        });
    })
}.bind(null, jQuery) );

