<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Chequeras';

$config['nombreTabla']  = 'chequeras';
$config['nombreVista']  = 'vi_chequeras';

//componer los campos de acuerdo a la vista correspondiente para el crud
$config['camposGrilla'] = array(array("ch_id"                  ,'data-sortable="true"'      ,"ID"),
				array("ch_cuenta_bancaria_id"  ,'data-sortable="true"'      ,"Id"),
				array("cb_denominacion"        ,'data-sortable="true"'      ,"Cuenta Bancaria"),
				array("cb_banco_id"            ,'data-sortable="true"'      ,"Id"),
				array("ba_denominacion"        ,'data-sortable="true"'      ,"Banco"),
				array("numeracion"             ,'data-sortable="true"'      ,"Serie y Numeración"),
				array("ch_fecha_solicitud"     ,'data-sortable="true"'      ,"F.Solicitud"),
				array("mo_denominacion"        ,'data-sortable="true"'      ,"Moneda"),
				array("echeq"                  ,'data-sortable="true"'      ," "),
				array("lo_id"                  ,'data-formatter="fn_action"',"Acciones") );
$config['searchGrilla'] = "id::text,cb_denominacion,ba_denominacion,numeracion,mo_denominacion,echeq";


//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';


