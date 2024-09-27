<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreInfo']   = 'aplicarccpr';


//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier informe  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']          = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']           = 'Aplicarccpr_model';
$config['urlApliCCPR']      = '/index.php/'.$config['nombreInfo'].'/aplicarcc';
$config['urlGrabaApliCCPR'] = '/index.php/'.$config['nombreInfo'].'/grabaaplicarcc';
$config['urlValiApliCCPR']  = '/index.php/'.$config['nombreInfo'].'/valiaplicc';
