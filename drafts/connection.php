<?php

$host = '127.0.0.1';
$port = 5135;

$link = mysql_connect( "$host:$port", 'msandbox', 'msandbox');
if (!$link) {
            die('Could not connect: ' . mysql_error());
}
echo "Connected successfully\n";

?>
