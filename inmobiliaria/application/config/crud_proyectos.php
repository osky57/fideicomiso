<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Proyectos';
//se indica el nombre de la tabla de la base de datos que se usa en el crud
$config['nombreTabla']  = 'proyectos';
//se indica el nombre de la vista de la base de datos que se usa en el browse del crud
$config['nombreVista']  = 'vi_proyectos';
// se debe indicar un nombre unico para la tabla para usarse como id
$config['idtabla']='proyectos';
//componer los campos de acuerdo a la vista correspondiente para el crud
$config['camposGrilla'] = array(array("p_id"           ,'data-sortable="true"'      ,"ID"),
				array("p_nombre"       ,'data-sortable="true"'      ,"Denominaci&oacute;n"),
				array("t_descripcion"  ,'data-sortable="true"'      ,"Tipo de proyecto"),
				array("tob_descripcion",'data-sortable="true"'      ,"Tipo de obra"),
				array("direccion"      ,'data-sortable="true"'      ,"Direcci&oacute;n"),
				array("local_prov"     ,'data-sortable="true"'      ,"Localidad"),
				array("p_fecha_inicio" ,'data-sortable="true"'      ,"Fecha Inicio"),
				array("p_fecha_finalizacion",'data-sortable="true"',"Fecha Finalizaci&oacute;n"),
				array("lo_id"          ,'data-formatter="fn_action"',"Acciones") );
//se indica la concatenación de campos de la tabla que se usarán para hacer búsquedas en el browse
$config['searchGrilla'] = "p_id::text,p_nombre,direccion,local_prov,t_descripcion,tob_descripcion";
// url de donde se obtiene el detalle (opcional solo para tablas master detail)
$config['urlDetalle']=base_url('index.php/'.$config['nombreCrud'].'/recuperaDetalle') ;







//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';
$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';

$config['detail']= ($config['urlDetalle']!='') ? 'true' : 'false'; // si hay definida una urlDetalle activo la vista subgrid en la tabla bootstrap

/*****
vista
SELECT p.id      AS p_id
 p.nombre        AS p_nombre 
,p.fecha_inicio  AS p_fecha_inicio
,p.fecha_finalizacion AS p_fecha_finalizacion
,p.comentario    AS p_comentario
,p.calle         AS p_calle
,p.numero        AS p_numero
,p.calle || ' ' || p.numero AS direccion
,p.localidad_id  AS p_localidad_id
,l.nombre ||' '||pr.nombre AS local_prov
,l.id            AS l_id
,l.nombre        AS l_nombre
,pr.id           AS p_id
,pr.nombre       AS p_nombre

***/