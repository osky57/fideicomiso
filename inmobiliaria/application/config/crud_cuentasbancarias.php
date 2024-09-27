<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Cuentasbancarias';

$config['nombreTabla']  = 'cuentas_bancarias';
$config['nombreVista']  = 'vi_cuentas_bancarias';

//componer los campos de acuerdo a la vista correspondiente para el crud
$config['camposGrilla'] = array(array("cb_id"            ,'data-sortable="true"'      ,"ID"),
				array("cb_denominacion"  ,'data-sortable="true"'      ,"Descripci&oacute;n"),
				array("tipocuenta"       ,'data-sortable="true"'      ,"Tipo de Cuenta"),
				array("cb_banco_id"      ,'data-sortable="true"'      ,"Id del Banco"),
				array("ba_denominacion"  ,'data-sortable="true"'      ,"Denominaci&oacute;n del Banco"),
				array("cb_cbu"           ,'data-sortable="true"'      ,"CBU"),
				array("cb_alias"         ,'data-sortable="true"'      ,"Alias"),
				array("lo_id"            ,'data-formatter="fn_action"',"Acciones") );
$config['searchGrilla'] = "id::text,cb_denominacion,ba_denominacion,tipocuenta,cb_cbu,cb_alias";


//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';


