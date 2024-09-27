<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreInfo']   = 'informesproy';


$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = 'Informeproy_model';
$config['urlInfoProy']  = '/index.php/'.$config['nombreInfo'].'/informeproy';
$config['urlInfoComp']  = '/index.php/'.$config['nombreInfo'].'/infoComp';
