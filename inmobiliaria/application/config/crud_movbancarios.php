<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Movbancarios';

$config['nombreTabla']  = 'movimientos_bancarios';
$config['nombreVista']  = 'vi_mov_bancarios';

$config['camposGrilla'] = array(array("mb_id"            ,'data-sortable ="false"'     ,"ID"           ),
				array("mb_fecha"         ,'data-sortable ="false"'     ,"Fecha"        ),
				array("tmc_descripcion"  ,'data-sortable ="false"'     ,"Tipo mov."    ),
				array("mb_numero"        ,'data-sortable ="false"'     ,"Nro."         ),
				array("importe_c_signo"  ,'data-sortable ="false"'     ,"Importe"      ),
				array("mo_denominacion"  ,'data-sortable ="false"'     ,"Moneda"       ),
				array("mb_comentario"    ,'data-sortable ="false"'     ,"Comentario"   ),
				array("mb_conciliacion"  ,'data-formatter="fn_in_date"',"Conciliación" ),
				array("lo_id"            ,'data-formatter="fn_action"' ,"Acciones"     ) );


$config['searchGrilla']       = "mb_id::text,mb_fecha::text,tmc_descripcion,mb_numero,importe_c_signo::text,mb_comentario";
//$config['urlRecuCueBan']    = '/index.php/'.$config['nombreCrud'].'/recuCueBanca';
//$config['urlRecuClie']      = '/index.php/'.$config['nombreCrud'].'/recuCliexTipo';
$config['urlRecuChqCart']     = '/index.php/'.$config['nombreCrud'].'/recuChqCart';
$config['urlActuConci']       = '/index.php/'.$config['nombreCrud'].'/actuConci';
//$config['urlRecuPropieEnti']= '/index.php/'.$config['nombreCrud'].'/recuPropieEnti';
//$config['urlRecuUnaEnti']   = '/index.php/'.$config['nombreCrud'].'/recuUnaEntidad';

//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);

$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';
$config['urlRecuPag']   = '/index.php/'.$config['nombreCrud'].'/recuperaPagina';
//$config['urlRecuDeuda'] = '/index.php/'.$config['nombreCrud'].'/recuDeuda';
$config['urlInfoComp']  = '/index.php/'.$config['nombreCrud'].'/infoComp';



