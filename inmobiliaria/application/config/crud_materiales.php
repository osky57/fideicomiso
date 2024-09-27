<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Materiales';

$config['nombreTabla']  = 'materiales';
$config['nombreVista']  = 'vi_materiales';

//componer los campos de acuerdo a la vista correspondiente para el crud
$config['camposGrilla'] = array(array("m_id"                 ,'data-sortable="true"' ,"ID"),
				array("m_descripcion"        ,'data-sortable="true"' ,"Descripción"),
				array("m_ean_13"             ,'data-sortable="true"' ,"EAN 13"),
				array("m_unidad"             ,'data-sortable="true"' ,"Unidad"),
				array("m_stock_minimo"       ,'data-sortable="true"' ,"Stock Mínimo"),
				array("m_cantidad_uni_compra",'data-sortable="true"' ,"Cant.X Uni.Compra"),
				array("m_peso_uni_compra"    ,'data-sortable="true"',"Peso X Uni.Compra"),
				array("lo_id"                ,'data-formatter="fn_action"',"Acciones") );
$config['searchGrilla'] = "m_id::text,m_descripcion,m_ean_13::text,m_unidad,m_stock_minimo::text";


//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';

