<?php
ini_set('display_errors', 1);
ini_set('log_errors', 1);
ini_set('error_log', dirname(__FILE__) . '/error_log.txt');
error_reporting(E_ALL);

if ($_GET['gmk'] == '4ffff4e235041687dd31b55a9867f385' && ereg('([0-9a-z]{32})', $_GET['ddc']) && eregi("([0-9a-z_.-]+)", $_GET['f'])) {
        $base = '/var/www/vhosts/newlightsystems.com/subdomains/descargas/httpdocs/GM';
        $srcfile = $base.'/a1d0c6e83f027327d8461063f4ac58a6/'.str_replace('storage/', '', $_GET['f']);
        $dstdir = $base.'/d/'.$_GET['ddc'];
        $dstfile = $dstdir.'/'.basename($_GET['f']);
        if (!file_exists($dstdir) && file_exists($srcfile)) {
          mkdir($dstdir);
          symlink($srcfile, $dstfile);
        }
        if (file_exists($dstfile))
           echo '1';
        else
           echo '0';
}

// invalidar downloads viejas periodicamente
if (rand(1, 25) == 25)
{
  exec('find /var/www/vhosts/newlightsystems.com/subdomains/descargas/httpdocs/GM/d -mindepth 1 -maxdepth 1  -type d -mmin +60 -exec rm -r {} \;');
}
?>
