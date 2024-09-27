<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Usuarios';

$config['nombreTabla']  = 'usuarios';
$config['nombreVista']  = 'vi_usuarios';

//componer los campos de acuerdo a la vista correspondiente para el crud
$config['camposGrilla'] = array(array("id"           ,'data-sortable="true"'      ,"ID"),
				array("nombre"       ,'data-sortable="true"'      ,"Nombre"),
				array("usuario"      ,'data-sortable="true"'      ,"Usuario"),
				array("nivel"        ,'data-sortable="true"'      ,"Nivel"),
				array("lo_id"        ,'data-formatter="fn_action"',"Acciones") );

//				array("password"     ,'data-sortable="true"'      ,"Passwd"),

$config['searchGrilla'] = "id::text,nombre,usuario";




//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';


