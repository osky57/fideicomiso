<?php

class Informeproy_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('nocrud_informes_proy.php');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveInforme($elGet){
	$idProyecto = $this->session->id_proyecto_activo;
	$desde      = $elGet['fdesde'];
	$hasta      = $elGet['fhasta'];

	if ($elGet['opcion'] == 1){ //informe completo

	    $sql        = "SELECT
		      SUM( CASE WHEN ((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '1' AND tc_modelo <> 4) OR
				     ((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '2' AND tc_modelo =  5)
				THEN fun_calcimportecomprob(cc_id,1,$idProyecto)
			        ELSE 0
			   END) AS saldoDmn,
		      SUM( CASE WHEN ((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '2' AND tc_modelo <> 5) OR
				     ((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '1' AND tc_modelo =  4)
				THEN fun_calcimportecomprob(cc_id,1,$idProyecto)
				ELSE 0
			   END) AS saldoHmn,
		      SUM( CASE WHEN ((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '1' AND tc_modelo <> 4) OR
				     ((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '2' AND tc_modelo =  5)
				THEN fun_calcimportecomprob(cc_id,2,$idProyecto)
				ELSE 0
			   END) AS saldoDdiv,
		      SUM( CASE WHEN ((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '2' AND tc_modelo <> 5) OR
				     ((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '1' AND tc_modelo =  4)
				THEN fun_calcimportecomprob(cc_id,2,$idProyecto)
				ELSE 0
			   END) AS saldoHdiv
		    FROM vi_ctas_ctes
		    WHERE (cc_proyecto_id = $idProyecto OR cc_proyecto_id IS NULL) 
		      AND cc_estado = 0
		      AND cc_fecha < '$desde' ";

wh_log("sql saldo...................................................");
wh_log($sql);

	    $query      = $this->db->query($sql);
	    $queryS     = $query->result_array();
	    $saldoMN    = $queryS[0]['saldodmn']  - $queryS[0]['saldohmn'];
	    $saldoDiv   = $queryS[0]['saldoddiv'] - $queryS[0]['saldohdiv'];

	    $primReg    = array(  'cc_id'           => ''
			    , 'cc_fecha'        => ''
			    , 'tc_abreviado'    => '<b>Saldo Anterior</b>'
			    , 'cc_numero'       => ''
			    , 'cc_comentario'   => ''
			    , 'debe_mn_tot'     => ''
			    , 'haber_mn_tot'    => ''
			    , 'saldo_mn_tot'    => '<b>'.number_format($saldoMN,2,',','.').'</b>'
			    , 'debe_div_tot'    => ''
			    , 'haber_div_tot'   => ''
			    , 'saldo_div_tot'   => '<b>'.number_format($saldoDiv,2,',','.').'</b>'
			    , 'cc_entidad_id'   => ''
			    , 'e_razon_social'  => ''
			    , 'tipoentidad'     => '' );

	    $sql       = "SELECT cc_id,
			cc_fecha,
			tc_abreviado,
			case when cc_numero is null then '' else cc_numero::text end,
			cc_comentario,

			CASE WHEN  ((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '1' AND tc_modelo <> 4) OR
					((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '2' AND tc_modelo =  5)
				THEN fun_calcimportecomprob(cc_id,1,$idProyecto)
			        ELSE 0
			END AS debe_mn_tot,

			CASE WHEN  ((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '2' AND tc_modelo <> 5) OR
					((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '1' AND tc_modelo =  4)
				THEN fun_calcimportecomprob(cc_id,1,$idProyecto)
				ELSE 0
			 END AS haber_mn_tot,

			CASE WHEN  ((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '1' AND tc_modelo <> 4) OR
					((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '2' AND tc_modelo =  5)
				THEN fun_calcimportecomprob(cc_id,2,$idProyecto)
				ELSE 0
			END AS debe_div_tot,

			CASE WHEN  ((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '2' AND tc_modelo <> 5) OR
					((tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '1' AND tc_modelo =  4)
				THEN fun_calcimportecomprob(cc_id,2,$idProyecto)
				ELSE 0
			END AS haber_div_tot,

			0 AS saldo_mn_tot,
			0 AS saldo_div_tot,
			cc_entidad_id,
			e_razon_social,
			tipoentidad
			FROM vi_ctas_ctes
			WHERE (cc_proyecto_id = $idProyecto OR cc_proyecto_id IS NULL) 
			  AND cc_estado = 0
			  AND cc_fecha BETWEEN '$desde' AND '$hasta'
			ORDER BY cc_fecha, cc_id ";

wh_log("sql movimientos ..........................................................");
wh_log($sql);

	    $query      = $this->db->query($sql);
	    $queryR     = $query->result_array();
	    for($i = 0 ; $i < count($queryR) ; $i++){

		$saldoDiv += ($queryR[$i]['debe_div_tot']+0) - ($queryR[$i]['haber_div_tot']+0);
		$saldoMN  += ($queryR[$i]['debe_mn_tot']+0)  - ($queryR[$i]['haber_mn_tot']+0);

		$queryR[$i]['debe_mn_tot']  = ($queryR[$i]['debe_mn_tot']>0)  ? number_format($queryR[$i]['debe_mn_tot'] ,2,',','.'):'';
		$queryR[$i]['haber_mn_tot'] = ($queryR[$i]['haber_mn_tot']>0) ? number_format($queryR[$i]['haber_mn_tot'],2,',','.'):'';
		$queryR[$i]['saldo_mn_tot'] = '<b>'.number_format($saldoMN,2,',','.').'</b>';
		$saldoDiv += ($queryR[$i]['debe_div_tot']+0) - ($queryR[$i]['haber_div_tot']+0);
		$queryR[$i]['debe_div_tot']  = ($queryR[$i]['debe_div_tot']>0) ? number_format($queryR[$i]['debe_div_tot'] ,2,',','.'):'';
		$queryR[$i]['haber_div_tot'] = ($queryR[$i]['haber_div_tot']>0)? number_format($queryR[$i]['haber_div_tot'],2,',','.'):'';
		$queryR[$i]['saldo_div_tot'] = '<b>'.number_format($saldoDiv,2,',','.').'</b>';

	    }
	    array_unshift($queryR, $primReg);

	    $ultReg     = array(  'cc_id'       => ''
			    , 'cc_fecha'        => ''
			    , 'tc_abreviado'    => '<b>Saldo Final</b>'
			    , 'cc_numero'       => ''
			    , 'cc_comentario'   => ''
			    , 'debe_mn_tot'     => ''
			    , 'haber_mn_tot'    => ''
			    , 'saldo_mn_tot'    => '<b>'.number_format($saldoMN,2,',','.').'</b>'
			    , 'debe_div_tot'    => ''
			    , 'haber_div_tot'   => ''
			    , 'saldo_div_tot'   => '<b>'.number_format($saldoDiv,2,',','.').'</b>'
			    , 'cc_entidad_id'   => ''
			    , 'e_razon_social'  => ''
			    , 'tipoentidad'     => '' );


	    $queryR[] = $ultReg;


	}elseif ($elGet['opcion'] == 2){   //solo recibos y o/p

	    $sql = "SELECT   SUM(COALESCE(haber_mn_tot,0)  - COALESCE(debe_mn_tot,0)) AS mn
			    ,SUM(COALESCE(haber_div_tot,0) - COALESCE(debe_div_tot,0)) AS div
		    FROM vi_ctas_ctes
		    WHERE cc_tipo_comprobante_id IN (4,9)
		      AND cc_estado = 0
		      AND COALESCE(cc_proyecto_id,cc_proyecto_origen_id) = $idProyecto
		      AND  cc_fecha < '$desde' ";
	    $query      = $this->db->query($sql);
	    $queryS     = $query->result_array();
	    $saldoMN    = $queryS[0]['mn'];
	    $saldoDiv   = $queryS[0]['div'];

	    $primReg    = array(  'cc_id'           => ''
			    , 'cc_fecha'        => ''
			    , 'tc_abreviado'    => '<b>Saldo Anterior</b>'
			    , 'cc_numero'       => ''
			    , 'cc_comentario'   => ''
			    , 'debe_mn_tot'     => ''
			    , 'haber_mn_tot'    => ''
			    , 'saldo_mn_tot'    => $saldoMN
			    , 'mn'              => ($saldoMN+0)
			    , 'debe_div_tot'    => ''
			    , 'haber_div_tot'   => ''
			    , 'saldo_div_tot'   => $saldoDiv
			    , 'div'             => ($saldoDiv+0)
			    , 'cc_entidad_id'   => ''
			    , 'e_razon_social'  => ''
			    , 'tipoentidad'     => '' );

//'<b>'.number_format($saldoMN,2,',','.').'</b>'
//'<b>'.number_format($saldoDiv,2,',','.').'</b>'



	    $sql = "SELECT   cc_id
			    ,cc_tipo_comprobante_id
			    ,cc_moneda_id
			    ,cc_cotizacion_divisa
			    ,cc_entidad_id
			    ,COALESCE(cc_proyecto_id,cc_proyecto_origen_id) AS proyec
			    ,cc_fecha
			    ,comp_nume
			    ,COALESCE(haber_mn_tot,0)  - COALESCE(debe_mn_tot,0) AS mn
			    ,COALESCE(haber_div_tot,0) - COALESCE(debe_div_tot,0) AS div
			    ,tc_signo
			    ,e_razon_social
			    ,comp_nume AS tc_abreviado
			    ,cc_comentario
		    FROM vi_ctas_ctes
		    WHERE cc_tipo_comprobante_id IN (4,9)
		      AND cc_estado = 0
		      AND COALESCE(cc_proyecto_id,cc_proyecto_origen_id) = $idProyecto
		      AND cc_fecha BETWEEN '$desde' AND '$hasta'
		    ORDER BY cc_fecha,cc_id";

	    $query      = $this->db->query($sql);
	    $queryR     = $query->result_array();

	    for($i = 0 ; $i < count($queryR) ; $i++){
		$saldoMN  += ($queryR[$i]['mn']+0);
		$saldoDiv += ($queryR[$i]['div']+0);
//		$queryR[$i]['debe_mn_tot']   = number_format($queryR[$i]['mn'] ,2,',','.');
//		$queryR[$i]['saldo_mn_tot']  = '<b>'.number_format($saldoMN,2,',','.').'</b>';
//		$queryR[$i]['debe_div_tot']  = number_format($queryR[$i]['div'] ,2,',','.');
//		$queryR[$i]['saldo_div_tot'] = '<b>'.number_format($saldoDiv,2,',','.').'</b>';


		$queryR[$i]['debe_mn_tot']   = $queryR[$i]['mn'];
		$queryR[$i]['saldo_mn_tot']  = $saldoMN;
		$queryR[$i]['debe_div_tot']  = $queryR[$i]['div'];
		$queryR[$i]['saldo_div_tot'] = $saldoDiv;


	    }

	    array_unshift($queryR, $primReg);

	    $ultReg     = array(  'cc_id'           => ''
			    , 'cc_fecha'        => ''
			    , 'tc_abreviado'    => '<b>Saldo Final</b>'
			    , 'cc_numero'       => ''
			    , 'cc_comentario'   => ''
			    , 'debe_mn_tot'     => ''
			    , 'haber_mn_tot'    => ''
			    , 'saldo_mn_tot'    => $saldoMN
			    , 'mn'              => $saldoMN
			    , 'debe_div_tot'    => ''
			    , 'haber_div_tot'   => ''
			    , 'saldo_div_tot'   => $saldoDiv
			    , 'div'             => $saldoDiv
			    , 'cc_entidad_id'   => ''
			    , 'e_razon_social'  => ''
			    , 'tipoentidad'     => '' );

	}
wh_log("queryR..................................................................");
wh_log(json_encode($queryR));

	return $queryR;

    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function infoComp($compId){

	wh_log(json_encode($compId));
	$aComp = dameInfoComp($compId);
	wh_log(json_encode($aComp));
	return $aComp;

    }

}

