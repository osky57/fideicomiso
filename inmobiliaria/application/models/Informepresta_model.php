<?php

class Informepresta_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('nocrud_informes_prestamistas.php');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveInforme($elGet){
	$idProyecto = $this->session->id_proyecto_activo;
	$desde      = $elGet['fdesde'];
	$hasta      = $elGet['fhasta'];
	$laEnti     = $elGet['entidad'];
	$soloProy   = $elGet['soloproy'];
	$filProy    = "";
	if ($soloProy == 1){
	    $filProy = " AND cc_proyecto_id = $idProyecto ";
	}

	$sqlS= "SELECT  COUNT(debe_mn_tot  - haber_mn_tot)  AS saldoMN,
			COUNT(debe_div_tot - haber_div_tot) AS saldoDiv
		FROM vi_ctas_ctes
		WHERE cc_entidad_id = $laEnti
		  AND (tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ?| array['3']
		  AND cc_fecha < '$desde'
		$filProy ";

	$sql = "SELECT *
		FROM vi_ctas_ctes
		WHERE cc_entidad_id = $laEnti
		  AND (tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ?| array['3']
		  AND cc_fecha BETWEEN '$desde' AND '$hasta'
		$filProy
		ORDER BY cc_fecha";

wh_log($sqlS);
wh_log($sql);

	$query    = $this->db->query($sqlS);
	$queryS   = $query->result_array();

	$saldoMN  = (float)$queryS[0]['saldoMN'];
	$saldoDiv = (float)$queryS[0]['saldoDiv'];

	$arrRet[] = array(  'co_descripcion' => '',
			    'cc_id'          => '',
			    'cc_fecha'       => $desde,
			    'tc_abreviado'   =>  '',
			    'cc_numero'      =>  '',
			    'cc_comentario'  =>  '',
			    'impo_mn'        =>  '',
			    'impo_div'       => '',
			    'saldo_mn_tot'   => $saldoMN,
			    'saldo_div_tot'  => $saldoDiv,
			    'cc_entidad_id'  => 0,
			    'e_razon_social' => '',
			    'tipoentidad'    => '',
			    'id_debi'        => 0);

	$query       = $this->db->query($sql);
	$query       = $query->result_array();

wh_log(json_encode($query));


	for($i = 0 ; $i < count($query) ; $i++){

		$impoMN    = (float)$query[$i]['debe_mn_tot']  - (float)$query[$i]['haber_mn_tot'];
		$impoDiv   = (float)$query[$i]['debe_div_tot'] - (float)$query[$i]['haber_div_tot'];
		$saldoMN  += $impoMN;
		$saldoDiv += $impoDiv;

		$arrRet[]  = array( 'co_descripcion' => $query[$i]['co_descripcion'],
				    'cc_id'          => $query[$i]['cc_id'],
				    'cc_fecha'       => $query[$i]['cc_fecha_dmy'],
				    'tc_abreviado'   => $query[$i]['tc_abreviado'],
				    'cc_numero'      => $query[$i]['cc_numero'],
				    'cc_comentario'  => $query[$i]['cc_comentario'],
				    'impo_mn'        => $impoMN,
				    'impo_div'       => $impoDiv,
				    'saldo_mn_tot'   => $saldoMN,
				    'saldo_div_tot'  => $saldoDiv,
				    'cc_entidad_id'  => 0,
				    'e_razon_social' => '',
				    'tipoentidad'    => '',
				    'id_debi'        => $query[$i]['cc_id']);
	}

	return $arrRet;

    }
}