<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Moventreproy';

$config['nombreTabla']  = 'moventreproy';
$config['nombreVista']  = 'vi_moventreproy';

//componer los campos de acuerdo a la vista correspondiente para el crud
$config['camposGrilla'] = array(array("ccroc_id"                ,'data-sortable ="false"'     ,"ID O/P"     ),
				array("ccroc_proyecto_origen_id",'data-sortable ="false"'     ,"ID Pro."    ),
				array("prroc_nombre"            ,'data-sortable ="false"'     ,"Proyecto Acreedor"   ),
				array("ccroc_fecha"             ,'data-sortable ="false"'     ,"Fecha"      ),
				array("comp1_nume"              ,'data-sortable ="false"'     ,"O/P"        ),
				array("ccfd_id"                 ,'data-sortable ="false"'     ,"ID Fac"     ),
				array("ccfd_fecha"              ,'data-sortable ="false"'     ,"Fecha"      ),
				array("comp2_nume"              ,'data-sortable ="false"'     ,"Fac."       ),
				array("ccfd_proyecto_origen_id" ,'data-sortable ="false"'     ,"ID Pro."    ),
				array("prfd_nombre"             ,'data-sortable ="false"'     ,"Proyecto Deudor"   ),
				array("rcc_monto_pesos"         ,'data-sortable ="false"'     ,"Importe $"  ),
				array("rcc_monto_divisa"        ,'data-sortable ="false"'     ,"Importe u$s") );
//				array("lo_id"                   ,'data-formatter="fn_action"' ,"Acciones"   ) );

$config['searchGrilla']     = "mb_id::text,mb_fecha::text,importe_c_signo::text,mb_comentario";

//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';
$config['urlInfoComp']  = '/index.php/'.$config['nombreCrud'].'/infoComp';


