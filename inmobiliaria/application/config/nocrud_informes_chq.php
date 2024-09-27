<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreInfo']   = 'informeschq';


//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier informe  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = 'Informeschq_model';
$config['urlInfoChq']   = '/index.php/'.$config['nombreInfo'].'/informechq';
$config['urlInfoChqRF'] = '/index.php/'.$config['nombreInfo'].'/informechqrf';
