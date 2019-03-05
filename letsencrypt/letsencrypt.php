<?php
/**
 *
 * Plugin is used to manage SSL for the wordpress site.
 *
 * Plugin Name:       Letsencrypt SSL Certificate
 * Plugin URI:        https://wwpp.date
 * Description:       Secure your website with a free SSL certificate.
 * Version:           1.0
 * Author:            Novice
 * Author URI:        https://wwpp.date
 * License:           GNU General Public License v3.0
 * License URI:       http://www.gnu.org/licenses/gpl-3.0.html
 * Text Domain:       le-ssl
 * Domain Path:       le_ssl/languages
 *
 * @author      Novice
 * @category    Plugin
 * @license     http://www.gnu.org/licenses/gpl-3.0.html GNU General Public License v3.0
 *
 */

/**
 * Exit if accessed directly
 */
if( ! defined( 'ABSPATH' ) ) {
    die('Access Denied');
}
define( 'letsencrypt_DIR', plugin_dir_path(__FILE__) . 'letsencrypt/' );
define( 'letsencrypt_URL', plugin_dir_url(__FILE__) . 'letsencrypt/' );
define( 'letsencrypt_BASEFILE', plugin_basename( __FILE__ ) );
    
require_once "vendor/autoload.php";
use \Firebase\JWT\JWT;


function log_it($msg){
    $dt = new DateTime( "NOW" );
    $dt = $dt->format( "m-d-Y H:i:s.u" );
    // $dt = date('Y-m-d H:i:s.u', time());
    error_log("[$dt] $msg\n", 3, dirname( __FILE__ ) . "/debug.log");
}
function apply( $req ) {    
    $data = $req->get_json_params();

    $domain = $data['domain'];
    $email = $data['email'];
    $cmd = "letsencrypt certonly --webroot \
    -w /usr/local/lsws/ssl-proof/ \
    --work-dir /usr/local/lsws/ssl-proof/ \
    --logs-dir /usr/local/lsws/ssl-proof/ \
    --agree-tos --email $email \
    -d $domain";
    log_it("apply,cmd=$cmd");
    exec("$cmd 2>&1", $output, $return);
    $output = array_slice($output, -15);
    // file_put_contents(dirname( __FILE__ )."/aaa.html", $aaa);
    return [
        'ret' => $return,
        'msg' => $output
    ];
}
function renew( $req ) {    
    $para = $req->get_json_params();
    exec("letsencrypt renew 2>&1", $output, $return);
    $output = implode("\n", $output);
    log_it("renew,output=$output");
    $output = array_slice($output, -15);
    return [
        'ret' => $return,
        'msg' => $output
    ];
}
// for reference
function login($req){
    $para = $req->get_json_params();
    $creds = array();
    $creds['user_login'] = $para["username"];
    // plain password
    $creds['user_password'] =  $para["password"];
    $creds['remember'] = true;
    $user = wp_signon( $creds, false );

    if ( is_wp_error($user) )
      echo $user->get_error_message();
      
    $key = "freego_2019";
    $jwt = JWT::encode($user, $key);
    return $jwt;
}
add_action( 'rest_api_init', function () {
    register_rest_route( 'letsencrypt/v1', '/login', array(
        'methods' => 'POST',
        'callback' => 'login',
    ) );
    register_rest_route( 'letsencrypt/v1', '/apply', array(
        'methods' => 'POST',
        'callback' => 'apply',
        'permission_callback' => function () {
            return current_user_can( 'edit_others_posts' );
        }
    ) );
    register_rest_route( 'letsencrypt/v1', '/renew', array(
        'methods' => 'POST',
        'callback' => 'renew',
        'permission_callback' => function () {
            return current_user_can( 'edit_others_posts' );
        }
    ) );
});
function letsencrypt_page() {
    // check user capabilities
    if ( ! current_user_can( 'manage_options' ) ) {
        return;
    }
    $ls = shell_exec('ls /etc/letsencrypt/');
    $ls = explode("\n", trim($ls) );
    $loader = new \Twig\Loader\FilesystemLoader(dirname( __FILE__ )."/templates");
    $twig = new \Twig\Environment($loader, [
        // 'cache' => dirname( __FILE__ ).'/compilation_cache',
    ]);
    $ssl_dir = '/etc/letsencrypt/live';
    $certs = [];
    if( is_dir($ssl_dir) ){
        foreach (new DirectoryIterator($ssl_dir) as $file) {
            if ( ! $file->isDot() && $file->isDir() ) {
                $certs[] = $file;
            }
        }
    }
    
    echo $twig->render('index.html', [
        'readme' => "readme: todo", 
        'certs' => $certs,
        'renew_ssl' => 'renew_ssl',
        'apply_ssl' => 'apply_ssl',
    ]);
}
function letsencrypt_options_page() {
    add_menu_page(
        'SSL证书管理',
        'SSL证书',
        'manage_options',
        'letsencrypt',
        'letsencrypt_page',
        plugin_dir_url(__FILE__) . 'images/icon.png',
        20
    );
}
add_action( 'admin_menu', 'letsencrypt_options_page' );
add_action( 'admin_enqueue_scripts', function( $hook ) {
    // log_it("in admin_enqueue_scripts,hook=$hook");
    if( 'toplevel_page_letsencrypt' != $hook ) return;
    // $user_id = get_current_user_id();
    $user_info = wp_get_current_user();
    $wp_scripts = wp_scripts();
    wp_enqueue_style( 'style-css', plugins_url( '/css/style.css', __FILE__ ) );
    wp_enqueue_style( 'notify-css', plugins_url( '/css/notify.css', __FILE__ ) );
    wp_enqueue_style( 'prettify-css', plugins_url( '/css/prettify.css', __FILE__ ) );
    // wp_enqueue_style( 'jquery-ui-css', plugins_url( '/css/jquery-ui.css', __FILE__ ) );   
    wp_enqueue_script( 'app-js',
        plugins_url( '/js/app.js', __FILE__ ),
        array( 'jquery', 'moment' )
    );
    wp_enqueue_script( 'prettify-js',plugins_url( '/js/prettify.js', __FILE__ ));
    wp_enqueue_script( 'notify-js',
        plugins_url( '/js/notify.js', __FILE__ ),
        array( 'jquery' )
    );
    static $token = null;
    if ($token === null) {
        $key = gethostname();
        $token = JWT::encode($user_info->data, $key);
    }
    wp_localize_script( 'app-js', 'wpObj', array(
        'token' => $token,
        // 'user_info' => $user_info->data,
        'apply_url' => esc_url_raw( rest_url() . 'letsencrypt/v1/apply' ),
        'renew_url' => esc_url_raw( rest_url() . 'letsencrypt/v1/renew' ),
        'nonce'    => wp_create_nonce( 'wp_rest' ),
    ) );
} );

add_action( 'init', function (){
    date_default_timezone_set('Asia/Chongqing');
});
// register_activation_hook( __FILE__, function (){

// } );
// register_deactivation_hook( __FILE__, function (){
    
// } );
