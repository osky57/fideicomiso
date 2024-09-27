<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Tiposprop';

$config['nombreTabla']  = 'tipos_propiedades';
$config['nombreVista']  = 'vi_tipos_propiedades';

//componer los campos de acuerdo a la vista correspondiente para el crud
$config['camposGrilla'] = array(array("id"           ,'data-sortable="true"'      ,"ID"),
				array("descripcion"  ,'data-sortable="true"'      ,"Descripci&oacute;n"),
				array("tipo_obli"    ,'data-sortable="true"'      ,"Condici&oacute;n"),
				array("lo_id"        ,'data-formatter="fn_action"',"Acciones") );
$config['searchGrilla'] = "id::text,descripcion,c_obligatorio";


//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';


