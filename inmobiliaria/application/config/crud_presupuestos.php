<?php
defined('BASEPATH') OR exit('No direct script access allowed');

//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Presupuestos';

$config['nombreTabla']  = 'presupuestos';
$config['nombreVista']  = 'vi_presupuestos';

//componer los campos de acuerdo a la vista correspondiente para el crud
$config['camposGrilla'] = array(array("pre_id"               ,'data-sortable="true"'       ,"ID"),
				array("pre_titulo"           ,'data-sortable="true"'       ,"Descripci&oacuten"),
				array("pre_fecha_inicio_dmy" ,'data-sortable="true"'       ,"Fecha"),
				array("pre_importe_inicial"  ,'data-sortable="true"'       ,"Importe"),
				array("mo_denominacion"      ,'data-sortable="true"'       ,"Moneda"),
				array("e_id"                 ,'data-sortable="true"'       ,"ID Prov."),
				array("e_razon_social"       ,'data-sortable="true"'       ,"Proveedor"),
				array("pro_nombre"           ,'data-sortable="true"'       ,"Proyecto"),
				array("cant_cc"              ,'data-visible  ="false"'     ,""        ),
				array("lo_id"                ,'data-formatter="fn_action"' ,"Acciones") );



$config['searchGrilla'] = "pre_id::text,pre_titulo,pre_fecha_inicio,e_id,e_razon_social,pro_nombre,mo_denominacion";


//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';

