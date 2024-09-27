<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Proyectosentidades';

$config['nombreTabla']  = 'proyectos_entidades';
$config['nombreVista']  = 'vi_proyectos_entidades';

//componer los campos de acuerdo a la vista correspondiente para el crud
$config['camposGrilla'] = array(array("pe_id"              ,'data-sortable="true"'      ,"ID"),
				array("e_id"               ,'data-sortable="true"'      ,"Ent.ID"),
				array("e_razon_social"     ,'data-sortable="true"'      ,"Nombre"),
				array("direccion1"         ,'data-sortable="true"'      ,"Dirección"),
				array("local_prov1"        ,'data-sortable="true"'      ,"Localidad"),
				array("e_celular"          ,'data-sortable="true"'      ,"Celular"),
				array("e_whatsapp"         ,'data-sortable="true"'      ,"Whatsapp"),
				array("e_email"            ,'data-sortable="true"'      ,"Email"),
				array("tipoentidad"        ,'data-sortable="true"'      ,"Tipo Entidad"),
				array("lo_id"              ,'data-formatter="fn_action"',"Acciones") );
$config['searchGrilla'] = "id::text,e_razon_social,direccion1,local_prov1,e_celular,e_whatsapp,e_email,tipoentidad";


//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';
$config['urlSubForm']   = '/index.php/'.$config['nombreCrud'].'/cargaSubFormulario';
$config['urlRecuCC']    = '/index.php/'.$config['nombreCrud'].'/recargaCC';

