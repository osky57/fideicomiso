<?php
defined('BASEPATH') OR exit('No direct script access allowed');


//se debe colocar el nombre correspondiente al crud, una sola palabra y comenzando con mayuscula
$config['nombreCrud']   = 'Cuentascorrientes';

$config['nombreTabla']  = 'cuentas_corrientes';
$config['nombreVista']  = 'vi_ctas_ctes';

$config['camposGrilla'] = array(array("cc_id"            ,'data-sortable ="false"'  ,"ID"         ),
				array("cc_fecha"         ,'data-sortable ="false"'  ,"Fecha"      ),
				array("comp_nume"        ,'data-sortable ="false"'  ,"Tipo y Nro."),
				array("debe_mn_tot"  ,'data-sortable ="false"'  ,"Debe $"     ),
				array("haber_mn_tot" ,'data-sortable ="false"'  ,"Haber $"    ),
				array("saldo_mn"         ,'data-sortable ="false"'  ,"Saldo $"    ),
				array("debe_div_tot" ,'data-sortable ="false"'  ,"Debe U$S"   ),
				array("haber_div_tot",'data-sortable ="false"'  ,"Haber U$S"  ),
				array("saldo_div"        ,'data-sortable ="false"'  ,"Saldo U$S"  ),
				array("cc_comentario"    ,'data-sortable ="false"'  ,"Comentario" ),
				array("cc_entidad_id"    ,'data-sortable ="false"'  ,"Ent.Id"     ),
				array("e_razon_social"   ,'data-sortable ="false"'  ,"Nombre"     ),
				array("p_nombre"         ,'data-sortable ="false"'  ,"Proyecto"   ),
				array("tp_descripcion"   ,'data-sortable ="false"'  ," "          ),
				array("tiene_apli"       ,'data-visible  ="false"'  ,""           ),
				array("lo_id"            ,'data-formatter="fn_action"' ,"Acciones") );



//				array("debe_txt_mn_tot"  ,'data-sortable ="false"'  ,"Debe $"     ),
//				array("haber_txt_mn_tot" ,'data-sortable ="false"'  ,"Haber $"    ),
//				array("debe_txt_div_tot" ,'data-sortable ="false"'  ,"Debe U$S"   ),
//				array("haber_txt_div_tot",'data-sortable ="false"'  ,"Haber U$S"  ),



$config['searchGrilla']        = "cc_id::text,cc_fecha::text,tc_abreviado,debe::text,haber::text,cc_comentario,e_razon_social,tp_descripcion";
$config['urlRecuClie']         = '/index.php/'.$config['nombreCrud'].'/recuCliexTipo';
$config['urlRecuChqCart']      = '/index.php/'.$config['nombreCrud'].'/recuChqCart';
$config['urlRecuChqCartADepo'] = '/index.php/'.$config['nombreCrud'].'/recuChqCartADepo';
$config['urlRecuChequeras']    = '/index.php/'.$config['nombreCrud'].'/recuChequeras';
$config['urlRecuPropieEnti']   = '/index.php/'.$config['nombreCrud'].'/recuPropieEnti';
$config['urlRecuUnaEnti']      = '/index.php/'.$config['nombreCrud'].'/recuUnaEntidad';
$config['urlRecuSaldoEnti']    = '/index.php/'.$config['nombreCrud'].'/recuSaldoEntidad';
$config['urlValiMedioPago']    = '/index.php/'.$config['nombreCrud'].'/valiMedioPago';

//////////////////////////////////////////////////////////////////////////
//esto no se debe tocar, son configuraciones fijas para cualquier crud  //
//////////////////////////////////////////////////////////////////////////
$config['urlGrid']      = 'data-url="' . base_url('index.php/'.$config['nombreCrud'].'/recuperaPagina') . '"'; //url de la funcion q necesita la tabla para paginar, filtrar, ordenar
$config['modelo']       = $config['nombreCrud'].'_model';
$config['vista']        = strtolower($config['nombreCrud']);
//$config['vistarecibo']        = strtolower($config['nombreCrud']);
//$config['vistaordenpago']        = strtolower($config['nombreCrud']);
$config['urlDel']       = '/index.php/'.$config['nombreCrud'].'/eliminaRegistro';

$config['urlPdf']       = './pdf/';

$config['urlForm']      = '/index.php/'.$config['nombreCrud'].'/cargaFormulario';
$config['urlRecuPag']   = '/index.php/'.$config['nombreCrud'].'/recuperaPagina';
$config['urlRecuDeuda'] = '/index.php/'.$config['nombreCrud'].'/recuDeuda';
$config['urlInfoComp']  = '/index.php/'.$config['nombreCrud'].'/infoComp';
$config['urlValiMedPag']= '/index.php/'.$config['nombreCrud'].'/valiMedPag';
$config['urlValiComp']  = '/index.php/'.$config['nombreCrud'].'/valiComp';
