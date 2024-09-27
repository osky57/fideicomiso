<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Proyectostipospropiedades';

$config['nombreTabla']  = 'proyectos_tipos_propiedades';
$config['nombreVista']  = 'vi_proyectos_tipos_propiedades';

//componer los campos de acuerdo a la vista correspondiente para el crud
$config['camposGrilla'] = array(array("ptp_id"           ,'data-sortable="true"'      ,"ID"),
				array("tp_id"            ,'data-sortable="true"'      ,"TP.ID"),
				array("tp_descripcion"   ,'data-sortable="true"'      ,"Descripción"),
				array("tipo_obli"        ,'data-sortable="true"'      ,"Obligatorio"),
				array("ptp_coeficiente"  ,'data-sortable="true"'      ,"Coeficiente"),
				array("ptp_comentario"   ,'data-sortable="true"'      ,"Observaciones"),
				array("lo_id"            ,'data-formatter="fn_action"',"Acciones") );
$config['searchGrilla'] = "id::text,tp_descripcion,tipo_obli,ptp_coeficiente::text";



//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';
$config['urlSubForm']   = '/index.php/'.$config['nombreCrud'].'/cargaSubFormulario';


