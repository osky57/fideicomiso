<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Entidades';

$config['nombreTabla']  = 'entidades';
$config['nombreVista']  = 'vi_entidades';

//componer los campos de acuerdo a la vista correspondiente para el crud
$config['camposGrilla'] = array(array("e_id"           ,'data-sortable="true"'      ,"ID"),
				array("e_razon_social" ,'data-sortable="true"'      ,"Raz&oacute;n Social"),
				array("direccion"      ,'data-sortable="true"'      ,"Direcci&oacute;n"),
				array("local_prov"     ,'data-sortable="true"'      ,"Localidad"),
				array("e_cuit"         ,'data-sortable="true"'      ,"CUIT / DNI"),
				array("e_celular"      ,'data-sortable="true"'      ,"Celular"),
				array("e_whatsapp"     ,'data-sortable="true"'      ,"Whatsapp"),
				array("e_email"        ,'data-sortable="true"'      ,"Email"),
				array("cant_cc"        ,'data-visible="false"'      ,""),
				array("lo_id"          ,'data-formatter="fn_action"',"Acciones") );
$config['searchGrilla'] = "e_id::text,e_razon_social,direccion,e_celular,e_whatsapp,e_email,local_prov,tipoentidad";


//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';
$config['urlValCuit']   = '/index.php/'.$config['nombreCrud'].'/validaCuit';













/***
$config['camposGrillaX'] = array(' <th data-field="e_id" data-sortable="true">ID</th>',
			    ' <th data-field="e_razon_social" data-sortable="true">Raz&oacute;n Social</th>',
			    ' <th data-field="direccion" data-sortable="true">Direcci&oacute;n</th>',
			    ' <th data-field="e_celular" data-sortable="true">Celular</th>',
			    ' <th data-field="e_whatsapp" data-sortable="true">Whatsapp</th>',
			    ' <th data-field="e_email" data-sortable="true">Email</th>',
			    ' <th data-field="local_prov" data-sortable="true">Localidad</th>',
			    ' <th data-field="lo_id" data-formatter="fn_action">Acciones</th>');
***/