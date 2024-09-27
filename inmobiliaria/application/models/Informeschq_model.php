<?php

class Informeschq_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('nocrud_informes_chq.php');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveInforme($elGet){
	$idProyecto  = $this->session->id_proyecto_activo;
	$desde       = $elGet['fdesde'];
	$hasta       = $elGet['fhasta'];
	$tipoChq     = $elGet['tipochq'];
	$tipoFecha   = $elGet['tipofecha'];
	$chqADepo    = " AND ccc_chq_a_depo " . (($elGet['chqadepo'] == 1) ? ' = 1' : ' IS NULL ') ;
	$estado3ro   = " "; 
	$gestCtasBan = 0;

	//2023-02-08 saco filtro de proyecto para recuperar chqs
	$elProy = ''; // AND cc_proyecto_id = $idProyecto


	if ($tipoChq === 'T'){    //en cartera
	    $estado3ro = "  AND fun_chq_asignado(ccc_id) = 0 ";
	}else if ($tipoChq === 'E'){    //entregados
	    $estado3ro = " AND fun_chq_asignado(ccc_id) > 0 ";
	}else if ($tipoChq === 'P'){    //propios
	    $gestCtasBan = 1;
	    $chqADepo    = "";
	}
	$filtroFecha = " BETWEEN '".$desde."' AND '".$hasta."' ";
	$elOrder = " ORDER BY ccc_fecha_emision ";
	if ($tipoFecha === 'E'){
	    $filtroFecha = " ccc_fecha_emision ".$filtroFecha;
	}else{
	    $filtroFecha = " ccc_fecha_acreditacion ".$filtroFecha;
	    $elOrder = " ORDER BY ccc_fecha_acreditacion ";
	}
	$sql        = "SELECT  ccc_id
			      ,ccc_cuenta_corriente_id
			      ,ccc_importe
			      ,ccc_moneda_id
			      ,mo1_simbolo
			      ,mo1_denominacion
			      ,RPAD(ba2_denominacion,25)||' | '||ccc_serie||LPAD(ccc_numero::text,8,'0') AS banco_nro
			      ,ccc_fecha_acreditacion
			      ,ccc_fecha_emision
			      ,ccc_importe_divisa
			      ,ccc_e_chq
			      ,CASE WHEN ccc_moneda_id =  1 THEN ccc_importe ELSE 0 END AS importemn
			      ,CASE WHEN ccc_moneda_id <> 1 THEN ccc_importe ELSE 0 END AS importeus
			      ,ccc_comentario
			      ,tmc_descripcion
			      ,cc_fecha
			      ,en_id
			      ,en_razon_social
			      ,tc_abreviado
			      ,cc_numero
			      ,tc_abreviado||' | '||LPAD(cc_numero::text,8,'0') AS tc_abre_nro
			      ,tch_abreviado
			      ,cch_numero
			      ,tch_abreviado||' | '||LPAD(cch_numero::text,8,'0') AS tch_abre_nro
			      ,COALESCE(tch_abreviado,tc_abreviado) AS abreviado
			      ,COALESCE(ba3_denominacion,ba2_denominacion) AS banco
			      ,to_char(ccc_fecha_emision,'dd-mm-yyyy') AS f_emision
			      ,to_char(ccc_fecha_acreditacion,'dd-mm-yyyy') AS f_acreditacion
			      ,enh_id
			      ,enh_razon_social
			      ,cc_proyecto_origen_id AS cc_proyecto_id
			      ,prori_nombre AS pr_nombre
			    FROM vi_cheques
			    WHERE  $filtroFecha
			      AND ccc_numero > 0
			      $estado3ro 
			      $estadoGestion
			      $chqADepo
			      AND tmc_gestiona_ctas_bancarias = $gestCtasBan
			      $elProy
			    $elOrder " ;
wh_log("info chq");
wh_log($sql);


	$query      = $this->db->query($sql);
	$queryS     = $query->result_array();
	$queryR[]   = $queryS;
	return $queryR;

    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveRF($elGet){
	$idProyecto  = $this->session->id_proyecto_activo;
	$tipoChq     = $elGet['tipochq'];
	$tipoFecha   = $elGet['tipofecha'];
	$chqADepo    = $elGet['chqadepo'];
	$chqADepo    = " AND ccc_chq_a_depo = " . (($elGet['chqadepo'] == 1) ? '1' : '0') ;
	$gestCtasBan = 0;

	$elProy      = "";
	if ($idProyecto > 0){
	    $elProy  = " AND cc_proyecto_id = $idProyecto ";
	}

	if ($tipoChq === 'T'){    //en cartera
	    $estado3ro = "  AND fun_chq_asignado(ccc_id) = 0 ";
	}else if ($tipoChq === 'E'){    //entregados
	    $estado3ro = " AND fun_chq_asignado(ccc_id) > 0 ";
	}else if ($tipoChq === 'P'){    //propios
	    $gestCtasBan = 1;
	    $chqADepo    = "";
	}
	$sql        = "SELECT  MIN(ccc_fecha_acreditacion) AS f_acre_min 
			      ,MIN(ccc_fecha_emision)      AS f_emi_min
			      ,MAX(ccc_fecha_acreditacion) AS f_acre_max 
			      ,MAX(ccc_fecha_emision)      AS f_emi_max
			    FROM vi_cheques
			    WHERE ccc_numero > 0
			      $estado3ro 
			      $estadoGestion
			      $chqADepo
			      AND tmc_gestiona_ctas_bancarias = $gestCtasBan
			      $elProy " ;

	$query      = $this->db->query($sql);
	$queryS     = $query->result_array();
	return $queryS;

    }
}
