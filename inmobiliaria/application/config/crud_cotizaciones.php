<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Cotizaciones';
//se indica el nombre de la tabla de la base de datos que se usa en el crud
$config['nombreTabla']  = 'cotizaciones';
//se indica el nombre de la vista de la base de datos que se usa en el browse del crud
$config['nombreVista']  = 'vi_cotizaciones';
// se debe indicar un nombre unico para la tabla para usarse como id
$config['idtabla']='proyectos';
//componer los campos de acuerdo a la vista correspondiente para el crud
$config['camposGrilla'] = array(array("c_id"          ,'data-sortable="true"'      ,"ID"),
				array("c_fecha"       ,'data-sortable="true"'      ,"Fecha"),
				array("c_importe"     ,'data-sortable="true"'      ,"Importe"),
				array("m_id"          ,'data-sortable="true"'      ,"Divisa Id"),
				array("m_denominacion",'data-sortable="true"'      ,"Divisa"),
				array("lo_id"          ,'data-formatter="fn_action"',"Acciones") );
//se indica la concatenación de campos de la tabla que se usarán para hacer búsquedas en el browse
$config['searchGrilla'] = "c_id::text,c_fecha::text,c_importe::text,m_id::text,m_denominacion";


//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';

$config['detail']= ($config['urlDetalle']!='') ? 'true' : 'false'; // si hay definida una urlDetalle activo la vista subgrid en la tabla bootstrap

