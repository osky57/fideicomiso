<?php

class Informesreten_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('nocrud_informes_reten.php');				// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveRetInforme($elGet){
	$idProyecto = $this->session->id_proyecto_activo;
	$desde      = $elGet['fdesde'];
	$hasta      = $elGet['fhasta'];
	$soloProy   = $elGet['soloproy'];
	$filProy    = "";
	if ($soloProy == "true"){
	    $filProy = " AND COALESCE( cc_proyecto_id, ccc_proyecto_id) = $idProyecto ";
	}

	$sql        = "SELECT
			SUM(ccc_importe) AS saldo_ret
			FROM vi_ctas_ctes_caja
			WHERE ccc_fecha_registro::date < '$desde' 
			  AND tmc_mov_en_banco = 4
			$filProy";

	$queryC     = $this->db->query($sql);
	$querySC    = $queryC->result_array();
	$saldoRet   = $querySC[0]['saldo_ret'];
	$primRegC   = array(  'cc_fecha'                => ''
			    , 'tc_abreviadonume'        => '<b>Saldo Anterior</b>'
			    , 'tmc_descripcion'         => ''
			    , 'ccc_comentario'          => ''
			    , 'ccc_importe_divisa'      => ''
			    , 'importe_ret'             => '<b>'.number_format($saldoRet,2).'</b>'
			    , 'ccc_fecha_emision'       => ''
			    , 'cc_entidad_id'           => null
			    , 'en_razon_social'         => ''
			    , 'cc_proyecto_id'          => ''
			    , 'ccc_fecha_registro'      => ''
			    , 'pr_nombre'               => ''
			    , 'cc_id'                   => ''
			    , 'ccc_cuenta_corriente_id' => '');

	$sql        = "SELECT
			cc_fecha,
			tc_abreviado ||' '||cc_numero::text AS tc_abreviadonume,
			tc_signo,
			tmc_txt_info_caja AS tmc_descripcion,
			ccc_comentario,
			ccc_importe_divisa,
			ccc_importe AS importe_ret,
			ccc_fecha_emision,
			en_razon_social,
			ccc_proyecto_id,
			ccc_fecha_registro::date AS ccc_fecha_registro,
			ccc_id,
			ccc_cuenta_corriente_id,
			tc_abreviado,
			cc_entidad_id,
			COALESCE( cc_proyecto_id, ccc_proyecto_id) AS cc_proyecto_id,
			COALESCE( pr_nombre, prc_nombre) AS pr_nombre
			FROM vi_ctas_ctes_caja
			WHERE ccc_fecha_registro::date BETWEEN '$desde' AND '$hasta'
			  AND tmc_tipo_mov = 8
			$filProy
			ORDER BY ccc_fecha_registro, tc_abreviadonume ";
wh_log("info reten");
wh_log($sql);
	$queryC     = $this->db->query($sql);
	$queryRC    = $queryC->result_array();
	for($i = 0 ; $i < count($queryRC) ; $i++){
	    $saldoRet   += ($queryRC[$i]['importe_ret']+0);
	}
	array_unshift($queryRC, $primRegC);

	$ultRegC    = array(  'cc_fecha'                => ''
			    , 'tc_abreviadonume'        => '<b>Saldo Final</b>'
			    , 'tmc_descripcion'         => ''
			    , 'ccc_comentario'          => ''
			    , 'ccc_importe_divisa'      => ''
			    , 'importe_ret'             => '<b>'.number_format($saldoRet,2).'</b>'
			    , 'ccc_fecha_emision'       => ''
			    , 'cc_entidad_id'           => null
			    , 'en_razon_social'         => ''
			    , 'cc_proyecto_id'          => ''
			    , 'ccc_fecha_registro'      => ''
			    , 'pr_nombre'               => ''
			    , 'cc_id'                   => ''
			    , 'ccc_cuenta_corriente_id' => '');
	$queryRC[] = $ultRegC;


wh_log(json_encode($queryRC));



	return $queryRC;
    }
}