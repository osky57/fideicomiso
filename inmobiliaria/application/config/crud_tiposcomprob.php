<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Tiposcomprob';

$config['nombreTabla']  = 'tipos_comprobantes';
$config['nombreVista']  = 'vi_tipos_comprobantes';

//componer los campos de acuerdo a la vista correspondiente para el crud
$config['camposGrilla'] = array(array("id"             ,'data-sortable="true"'      ,"ID"),
				array("descripcion"    ,'data-sortable="true"'      ,"Descripci&oacute;n"),
				array("tiposigno"      ,'data-sortable="true"'      ,"Afecta al"),
				array("abreviado"      ,'data-sortable="true"'      ,"Nombre abreviado"),
				array("numero"         ,'data-sortable="true"'      ,"Numeraci&oacute;n"),
				array("afectacaja"     ,'data-sortable="true"'      ,"Caja"),
				array("tipoentidad"    ,'data-sortable="true"'      ,"Entidad Aplicada"),
				array("modelocomprob"  ,'data-sortable="true"'      ,"Modelo Comprobante"),
				array("conceptocomprob",'data-sortable="true"'      ,"Concepto Comprobante"),
				array("aplica"         ,'data-sortable="true"'      ,"Situación"),
				array("lo_id"        ,'data-formatter="fn_action"',"Acciones") );
$config['searchGrilla'] = "id::text,descripcion,signo::text,abreviado,numero::text,afectacaja,modelocomprob,conceptocomprob";


//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';


