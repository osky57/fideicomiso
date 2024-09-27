<?php

class Informecc_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('nocrud_informes_cc.php');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveInforme($elGet){
	$idProyecto = $this->session->id_proyecto_activo;
	$desde      = $elGet['fdesde'];
	$hasta      = $elGet['fhasta'];
	$laEnti     = $elGet['entidad'] > 0 ? " AND cc_entidad_id = ".$elGet['entidad'] : "";
	$sql        = "SELECT
			 SUM(debe_mn_tot)   AS saldoDmn
			,SUM(haber_mn_tot)  AS saldoHmn
			,SUM(debe_div_tot)  AS saldoDdiv
			,SUM(haber_div_tot) AS saldoHdiv
			FROM vi_ctas_ctes
			WHERE cc_proyecto_id = $idProyecto
			  AND cc_estado = 0
			  AND cc_fecha < '$desde'
			$laEnti";
	$query      = $this->db->query($sql);
	$queryS     = $query->result_array();
	$saldoMN    = $queryS[0]['saldodmn']  - $queryS[0]['saldohmn'];
	$saldoDiv   = $queryS[0]['saldoddiv'] - $queryS[0]['saldohdiv'];

	$primReg    = array(  'cc_id'           => ''
			    , 'cc_fecha'        => ''
			    , 'tc_descripcion'  => '<b>Saldo Anterior</b>'
			    , 'tc_abreviado'    => ''
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


//'<b>'.number_format($saldoMN,2).'</b>'
//'<b>'.number_format($saldoDiv,2).'</b>'




	$sql        = "SELECT cc_id
			, cc_fecha
			, tc_descripcion
			, tc_abreviado
			, case when cc_numero is null then '' else cc_numero::text end
			, cc_comentario
			, case when debe_mn_tot   is null OR debe_mn_tot = 0  then '' else debe_mn_tot::text end
			, case when haber_mn_tot  is null OR haber_mn_tot = 0 then '' else haber_mn_tot::text end
			, 0 AS saldo_mn_tot
			, case when debe_div_tot  is null OR debe_div_tot  = 0 then '' else debe_div_tot::text end
			, case when haber_div_tot is null OR haber_div_tot = 0 then '' else haber_div_tot::text end
			, 0 AS saldo_div_tot
			, cc_entidad_id
			, e_razon_social
			, tipoentidad
			FROM vi_ctas_ctes
			WHERE cc_proyecto_id = $idProyecto
			  AND cc_estado = 0
			  AND cc_fecha BETWEEN '$desde' AND '$hasta'
			$laEnti
			ORDER BY cc_fecha ";

	$query      = $this->db->query($sql);
	$queryR     = $query->result_array();
	for($i = 0 ; $i < count($queryR) ; $i++){

	    $saldoMN  += ($queryR[$i]['debe_mn_tot']+0)  - ($queryR[$i]['haber_mn_tot']+0);
	    $saldoDiv += ($queryR[$i]['debe_div_tot']+0) - ($queryR[$i]['haber_div_tot']+0);

	    $queryR[$i]['debe_mn_tot']  = ($queryR[$i]['debe_mn_tot']>0)  ? number_format($queryR[$i]['debe_mn_tot'] ,2,',','.'):'';
	    $queryR[$i]['haber_mn_tot'] = ($queryR[$i]['haber_mn_tot']>0) ? number_format($queryR[$i]['haber_mn_tot'],2,',','.'):'';
	    $queryR[$i]['saldo_mn_tot'] = '<b>'.number_format($saldoMN,2,',','.').'</b>';

	    $queryR[$i]['debe_div_tot']  = ($queryR[$i]['debe_div_tot']>0) ? number_format($queryR[$i]['debe_div_tot'] ,2,',','.'):'';
	    $queryR[$i]['haber_div_tot'] = ($queryR[$i]['haber_div_tot']>0)? number_format($queryR[$i]['haber_div_tot'],2,',','.'):'';
	    $queryR[$i]['saldo_div_tot'] = '<b>'.number_format($saldoDiv,2,',','.').'</b>';

	}
	array_unshift($queryR, $primReg);
	$ultReg     = array(  'cc_id'           => ''
			    , 'cc_fecha'        => ''
			    , 'tc_descripcion'  => '<b>Saldo Final</b>'
			    , 'tc_abreviado'    => ''
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
	if ($elGet['entidad'] > 0 ){ //recupera comprob sin aplicar
	    $aCompCSaldo = dameCompCSaldo($idProyecto, $elGet['entidad']);
	    $aParaApli   = dameParaApli($idProyecto, $elGet['entidad']);
	}
	return $queryR;

    }




    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveInformeCompXXXXX($elGet){
	$idProyecto = $this->session->id_proyecto_activo;
	$desde      = $elGet['fdesde'];
	$hasta      = $elGet['fhasta'];
	$fechaRango = " BETWEEN '$desde' AND '$hasta' ";
	$laEnti     = $elGet['entidad'];
	$sql        = "SELECT   cc.fecha AS cc_fecha,           cc.id AS cc_id,                 cc.numero AS cc_numero,
				tc.abreviado AS tc_abreviado,   tc.concepto  AS tc_concepto,    co.descripcion AS co_descripcion,
				cc.moneda_id AS cc_moneda_id,   cca.fecha AS cca_fecha,         cca.id AS cca_id, 
				cc.comentario AS cc_comentario, en.id AS cc_entidad_id,         en.razon_social AS e_razon_social,
				cca.numero AS cca_numero,       tca.abreviado AS tca_abreviado, tc.descripcion AS tc_descripcion,
				fun_dametiposentidades(en.id, 'E') AS tipoentidad,              cca.comentario AS cca_comentario,
				CASE WHEN cc.moneda_id = 1 THEN COALESCE(cc.importe,0) ELSE 0 END AS debe_mn_tot,
				CASE WHEN cc.moneda_id = 2 THEN COALESCE(cc.importe,0) ELSE 0 END AS debe_div_tot,
				0 AS saldo_mn_tot, 0 AS saldo_div_tot,
				COALESCE(rcc.monto_pesos,0)  AS haber_mn_tot,
				COALESCE(rcc.monto_divisa,0) AS haber_div_tot
			FROM cuentas_corrientes      cc
			LEFT JOIN relacion_ctas_ctes rcc ON cc.id = rcc.cuenta_corriente_id
			LEFT JOIN tipos_comprobantes tc  ON cc.tipo_comprobante_id = tc.id
			LEFT JOIN conceptos          co  ON tc.concepto = co.id
			LEFT JOIN cuentas_corrientes cca ON rcc.relacion_id = cca.id
			LEFT JOIN tipos_comprobantes tca ON cca.tipo_comprobante_id = tca.id
			LEFT JOIN entidades          en  ON cc.entidad_id = en.id
			WHERE tc.modelo = 2
			  AND cc.entidad_id = xxEntixx
			  AND cc.proyecto_id = xxProyexx
			  AND cc.estado = 0
			  AND COALESCE(rcc.estado,0) = 0
			  AND cc.fecha xxFechaxx
			ORDER BY co.orden,cc.fecha,cc.id";

	$sqlComposi = preg_replace('/xxEntixx/' ,$laEnti    ,$sql);
	$sqlComposi = preg_replace('/xxProyexx/',$idProyecto,$sqlComposi);
	$sqlComposi = preg_replace('/xxFechaxx/',$fechaRango,$sqlComposi);
	$query      = $this->db->query($sqlComposi);
	$queryR     = $query->result_array();
	$arrRet     = array();
	$concDes    = '';
	$elId       = 0;
	for($i = 0 ; $i < count($queryR) ; $i++){
	    if ($elId != $queryR[$i]['cc_id']){
		$elId     = $queryR[$i]['cc_id'];
		$arrRet[] = array(  'co_descripcion' => $queryR[$i]['co_descripcion'],
				    'cc_id'          => $queryR[$i]['cc_id'],
				    'cc_fecha'       => $queryR[$i]['cc_fecha'],
				    'tc_abreviado'   => $queryR[$i]['tc_abreviado'],
				    'cc_numero'      => $queryR[$i]['cc_numero'],
				    'cc_comentario'  => $queryR[$i]['cc_comentario'],
				    'debe_mn_tot'    => $queryR[$i]['debe_mn_tot'],
				    'debe_div_tot'   => $queryR[$i]['debe_div_tot'],
				    'haber_mn_tot'   => 0,
				    'haber_div_tot'  => 0,
				    'saldo_mn_tot'   => 0,
				    'saldo_div_tot'  => 0,
				    'cc_entidad_id'  => $queryR[$i]['cc_entidad_id'],
				    'e_razon_social' => $queryR[$i]['e_razon_social'],
				    'tipoentidad'    => $queryR[$i]['tipoentidad'],
				    'saldo_mn_gen'   => 0,
				    'saldo_div_gen'  => 0,
				    'id_debi'        => $elId);
	    }
	    if ($queryR[$i]['haber_mn_tot'] + $queryR[$i]['haber_div_tot'] > 0){
		$arrRet[] = array(  'co_descripcion' => $queryR[$i]['co_descripcion'],
				    'cc_id'          => $queryR[$i]['cca_id'],
				    'cc_fecha'       => $queryR[$i]['cca_fecha'],
				    'tc_abreviado'   => $queryR[$i]['tca_abreviado'],
				    'cc_numero'      => $queryR[$i]['cca_numero'],
				    'cc_comentario'  => $queryR[$i]['cca_comentario'],
				    'debe_mn_tot'    => 0,
				    'debe_div_tot'   => 0,
				    'haber_mn_tot'   => $queryR[$i]['haber_mn_tot'],
				    'haber_div_tot'  => $queryR[$i]['haber_div_tot'],
				    'saldo_mn_tot'   => 0,
				    'saldo_div_tot'  => 0,
				    'cc_entidad_id'  => $queryR[$i]['cc_entidad_id'],
				    'e_razon_social' => $queryR[$i]['e_razon_social'],
				    'tipoentidad'    => $queryR[$i]['tipoentidad'],
				    'saldo_mn_gen'   => 0,
				    'saldo_div_gen'  => 0,
				    'id_debi'        => $elId);
	    }
	}
	$saldoMN     = 0;
	$saldoDiv    = 0;
	$saldoMNGen  = 0;
	$saldoDivGen = 0;
	for($i = 0 ; $i < count($arrRet) ; $i++){
	    $saldoMN    += (float)$arrRet[$i]['debe_mn_tot'] - (float)$arrRet[$i]['haber_mn_tot'];
	    $saldoMNGen += (float)$arrRet[$i]['debe_mn_tot'] - (float)$arrRet[$i]['haber_mn_tot'];
	    $arrRet[$i]['debe_mn_tot']  = ($arrRet[$i]['debe_mn_tot']>0)  ? number_format($arrRet[$i]['debe_mn_tot'] ,2):'';
	    $arrRet[$i]['haber_mn_tot'] = ($arrRet[$i]['haber_mn_tot']>0) ? number_format($arrRet[$i]['haber_mn_tot'],2):'';
	    $arrRet[$i]['saldo_mn_tot'] = '<b>'.number_format($saldoMN,2).'</b>';
	    $arrRet[$i]['saldo_mn_gen'] = '<b>'.number_format($saldoMNGen,2).'</b>';
	    $saldoDiv    += (float)$arrRet[$i]['debe_div_tot'] - (float)$arrRet[$i]['haber_div_tot'];
	    $saldoDivGen += (float)$arrRet[$i]['debe_div_tot'] - (float)$arrRet[$i]['haber_div_tot'];
	    $arrRet[$i]['debe_div_tot']  = ($arrRet[$i]['debe_div_tot']>0) ? number_format($arrRet[$i]['debe_div_tot'] ,2):'';
	    $arrRet[$i]['haber_div_tot'] = ($arrRet[$i]['haber_div_tot']>0)? number_format($arrRet[$i]['haber_div_tot'],2):'';
	    $arrRet[$i]['saldo_div_tot'] = '<b>'.number_format($saldoDiv,2).'</b>';
	    $arrRet[$i]['saldo_div_gen'] = '<b>'.number_format($saldoDivGen,2).'</b>';
	    if ($i+1 < count($arrRet)){
		if ($arrRet[$i+1]['id_debi'] != $arrRet[$i]['id_debi']){
		    $saldoMN  = 0;
		    $saldoDiv = 0;
		}
	    }
	}

	$sqlSA = "SELECT 'SIN APLICAR' AS co_descripcion , cc_id , cc_fecha , tc_abreviado , cc_numero 
			, cc_comentario , saldopesos AS haber_mn_tot , saldodolar AS haber_div_tot 
		    FROM vi_ctas_ctes
		    WHERE cc_entidad_id =  xxEntixx
		      AND cc_proyecto_id = xxProyexx
		      AND tc_modelo NOT IN (1,2)
		      AND cc_estado = 0
		      AND cc_fecha xxFechaxx
		      AND (fun_comprobsinaplicar(cc_id,1)>0 OR fun_comprobsinaplicar(cc_id,2)>0 )
		    ORDER BY cc_fecha, cc_id";
	$sqlComposi = preg_replace('/xxEntixx/' ,$laEnti    ,$sqlSA);
	$sqlComposi = preg_replace('/xxProyexx/',$idProyecto,$sqlComposi);
	$sqlComposi = preg_replace('/xxFechaxx/',$fechaRango,$sqlComposi);
	$query      = $this->db->query($sqlComposi);
	$queryR     = $query->result_array();
	for($i = 0 ; $i < count($queryR) ; $i++){

		$saldoMNGen  -= (float)$arrRet[$i]['haber_mn_tot'];
		$saldoDivGen -= (float)$arrRet[$i]['haber_div_tot'];

		$arrRet[] = array(  'co_descripcion' => $queryR[$i]['co_descripcion'],
				    'cc_id'          => $queryR[$i]['cc_id'],
				    'cc_fecha'       => $queryR[$i]['cc_fecha'],
				    'tc_abreviado'   => $queryR[$i]['tc_abreviado'],
				    'cc_numero'      => $queryR[$i]['cc_numero'],
				    'cc_comentario'  => $queryR[$i]['cc_comentario'],
				    'debe_mn_tot'    => '',
				    'debe_div_tot'   => '',
				    'haber_mn_tot'   => ($queryR[$i]['haber_mn_tot']>0  ? number_format($queryR[$i]['haber_mn_tot'],2) :''),
				    'haber_div_tot'  => ($queryR[$i]['haber_div_tot']>0 ? number_format($queryR[$i]['haber_div_tot'],2):''),
				    'saldo_mn_tot'   => '<b>'.number_format($queryR[$i]['haber_mn_tot'],2).'</b>',
				    'saldo_div_tot'  => '<b>'.number_format($queryR[$i]['haber_div_tot'],2).'</b>',
				    'cc_entidad_id'  => 0,
				    'e_razon_social' => '',
				    'tipoentidad'    => '',
				    'saldo_mn_gen'   => '<b>'.number_format($saldoMNGen,2).'</b>',
				    'saldo_div_gen'  => '<b>'.number_format($saldoDivGen,2).'</b>',
				    'id_debi'        => $queryR[$i]['cc_id']);

	}



wh_log("*****************************************************");
wh_log(json_encode($arrRet));

	return $arrRet;

    }







    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveInformeComp($elGet){
	$idProyecto = $this->session->id_proyecto_activo;
	$desde      = $elGet['fdesde'];
	$hasta      = $elGet['fhasta'];
	$fechaRango = " BETWEEN '$desde' AND '$hasta' ";
	$laEnti     = $elGet['entidad'];
	$sql        = "SELECT   cc.fecha AS cc_fecha,           cc.id AS cc_id,                 cc.numero AS cc_numero,
				tc.abreviado AS tc_abreviado,   tc.concepto  AS tc_concepto,    co.descripcion AS co_descripcion,
				cc.moneda_id AS cc_moneda_id,   cca.fecha AS cca_fecha,         cca.id AS cca_id, 
				cc.comentario AS cc_comentario, en.id AS cc_entidad_id,         en.razon_social AS e_razon_social,
				cca.numero AS cca_numero,       tca.abreviado AS tca_abreviado, tc.descripcion AS tc_descripcion,
				fun_dametiposentidades(en.id, 'E') AS tipoentidad,              cca.comentario AS cca_comentario,
				CASE WHEN cc.moneda_id = 1 THEN COALESCE(cc.importe,0) ELSE 0 END AS debe_mn_tot,
				CASE WHEN cc.moneda_id = 2 THEN COALESCE(cc.importe,0) ELSE 0 END AS debe_div_tot,
				0 AS saldo_mn_tot, 0 AS saldo_div_tot,
				COALESCE(rcc.monto_pesos,0)  AS haber_mn_tot,
				COALESCE(rcc.monto_divisa,0) AS haber_div_tot
			FROM cuentas_corrientes      cc
			LEFT JOIN relacion_ctas_ctes rcc ON cc.id = rcc.cuenta_corriente_id
			LEFT JOIN tipos_comprobantes tc  ON cc.tipo_comprobante_id = tc.id
			LEFT JOIN conceptos          co  ON tc.concepto = co.id
			LEFT JOIN cuentas_corrientes cca ON rcc.relacion_id = cca.id
			LEFT JOIN tipos_comprobantes tca ON cca.tipo_comprobante_id = tca.id
			LEFT JOIN entidades          en  ON cc.entidad_id = en.id
			WHERE tc.modelo = 2
			  AND cc.entidad_id = xxEntixx
			  AND cc.proyecto_id = xxProyexx
			  AND cc.estado = 0
			  AND COALESCE(rcc.estado,0) = 0
			  AND cc.fecha xxFechaxx
			ORDER BY co.orden,cc.fecha,cc.id";
	$sqlComposi = preg_replace('/xxEntixx/' ,$laEnti    ,$sql);
	$sqlComposi = preg_replace('/xxProyexx/',$idProyecto,$sqlComposi);
	$sqlComposi = preg_replace('/xxFechaxx/',$fechaRango,$sqlComposi);

wh_log("sqlcomposi");
wh_log($sqlComposi);

	$query      = $this->db->query($sqlComposi);
	$queryR     = $query->result_array();
	$arrRet     = array();
	$concDes    = '';
	$elId       = 0;
	for($i = 0 ; $i < count($queryR) ; $i++){
	    if ($elId != $queryR[$i]['cc_id']){
		$elId     = $queryR[$i]['cc_id'];
		$arrRet[] = array(  'co_descripcion' => $queryR[$i]['co_descripcion'],
				    'cc_id'          => $queryR[$i]['cc_id'],
				    'cc_fecha'       => $queryR[$i]['cc_fecha'],
				    'tc_abreviado'   => $queryR[$i]['tc_abreviado'],
				    'cc_numero'      => $queryR[$i]['cc_numero'],
				    'cc_comentario'  => $queryR[$i]['cc_comentario'],
				    'debe_mn_tot'    => $queryR[$i]['debe_mn_tot'],
				    'debe_div_tot'   => $queryR[$i]['debe_div_tot'],
				    'haber_mn_tot'   => 0,
				    'haber_div_tot'  => 0,
				    'saldo_mn_tot'   => 0,
				    'saldo_div_tot'  => 0,
				    'cc_entidad_id'  => $queryR[$i]['cc_entidad_id'],
				    'e_razon_social' => $queryR[$i]['e_razon_social'],
				    'tipoentidad'    => $queryR[$i]['tipoentidad'],
				    'saldo_mn_gen'   => 0,
				    'saldo_div_gen'  => 0,
				    'id_debi'        => $elId);
	    }
	    if ($queryR[$i]['haber_mn_tot'] + $queryR[$i]['haber_div_tot'] > 0){
		$arrRet[] = array(  'co_descripcion' => $queryR[$i]['co_descripcion'],
				    'cc_id'          => $queryR[$i]['cca_id'],
				    'cc_fecha'       => $queryR[$i]['cca_fecha'],
				    'tc_abreviado'   => $queryR[$i]['tca_abreviado'],
				    'cc_numero'      => $queryR[$i]['cca_numero'],
				    'cc_comentario'  => $queryR[$i]['cca_comentario'],
				    'debe_mn_tot'    => 0,
				    'debe_div_tot'   => 0,
				    'haber_mn_tot'   => $queryR[$i]['haber_mn_tot'],
				    'haber_div_tot'  => $queryR[$i]['haber_div_tot'],
				    'saldo_mn_tot'   => 0,
				    'saldo_div_tot'  => 0,
				    'cc_entidad_id'  => $queryR[$i]['cc_entidad_id'],
				    'e_razon_social' => $queryR[$i]['e_razon_social'],
				    'tipoentidad'    => $queryR[$i]['tipoentidad'],
				    'saldo_mn_gen'   => 0,
				    'saldo_div_gen'  => 0,
				    'id_debi'        => $elId);
	    }
	}
	$saldoMN     = 0;
	$saldoDiv    = 0;
	$saldoMNGen  = 0;
	$saldoDivGen = 0;
	for($i = 0 ; $i < count($arrRet) ; $i++){
	    $saldoMN    += $arrRet[$i]['debe_mn_tot'] - $arrRet[$i]['haber_mn_tot'];
	    $saldoMNGen += $arrRet[$i]['debe_mn_tot'] - $arrRet[$i]['haber_mn_tot'];

//	    $saldoMN    += (float)$arrRet[$i]['debe_mn_tot'] - (float)$arrRet[$i]['haber_mn_tot'];
//	    $saldoMNGen += (float)$arrRet[$i]['debe_mn_tot'] - (float)$arrRet[$i]['haber_mn_tot'];

//	    $arrRet[$i]['debe_mn_tot']  = ($arrRet[$i]['debe_mn_tot']>0)  ? number_format($arrRet[$i]['debe_mn_tot'] ,2):'';
//	    $arrRet[$i]['haber_mn_tot'] = ($arrRet[$i]['haber_mn_tot']>0) ? number_format($arrRet[$i]['haber_mn_tot'],2):'';

	    $arrRet[$i]['saldo_mn_tot'] = $saldoMN;
	    $arrRet[$i]['saldo_mn_gen'] = $saldoMNGen;

//	    $arrRet[$i]['saldo_mn_tot'] = number_format($saldoMN,2);
//	    $arrRet[$i]['saldo_mn_gen'] = number_format($saldoMNGen,2);



	    $saldoDiv    += $arrRet[$i]['debe_div_tot'] - $arrRet[$i]['haber_div_tot'];
	    $saldoDivGen += $arrRet[$i]['debe_div_tot'] - $arrRet[$i]['haber_div_tot'];

//	    $saldoDiv    += (float)$arrRet[$i]['debe_div_tot'] - (float)$arrRet[$i]['haber_div_tot'];
//	    $saldoDivGen += (float)$arrRet[$i]['debe_div_tot'] - (float)$arrRet[$i]['haber_div_tot'];

//	    $arrRet[$i]['debe_div_tot']  = ($arrRet[$i]['debe_div_tot']>0) ? number_format($arrRet[$i]['debe_div_tot'] ,2):'';
//	    $arrRet[$i]['haber_div_tot'] = ($arrRet[$i]['haber_div_tot']>0)? number_format($arrRet[$i]['haber_div_tot'],2):'';


	    $arrRet[$i]['saldo_div_tot'] = $saldoDiv;
	    $arrRet[$i]['saldo_div_gen'] = $saldoDivGen;

//	    $arrRet[$i]['saldo_div_tot'] = number_format($saldoDiv,2);
//	    $arrRet[$i]['saldo_div_gen'] = number_format($saldoDivGen,2);


	    if ($i+1 < count($arrRet)){
		if ($arrRet[$i+1]['id_debi'] != $arrRet[$i]['id_debi']){
		    $saldoMN  = 0;
		    $saldoDiv = 0;
		}
	    }
	}

	$sqlSA = "SELECT 'SIN APLICAR' AS co_descripcion , cc_id , cc_fecha , tc_abreviado , cc_numero 
			, cc_comentario , saldopesos AS haber_mn_tot , saldodolar AS haber_div_tot 
		    FROM vi_ctas_ctes
		    WHERE cc_entidad_id =  xxEntixx
		      AND cc_proyecto_id = xxProyexx
		      AND tc_modelo NOT IN (1,2)
		      AND cc_estado = 0
		      AND cc_fecha xxFechaxx
		      AND (fun_comprobsinaplicar(cc_id,1)>0 OR fun_comprobsinaplicar(cc_id,2)>0 )
		    ORDER BY cc_fecha, cc_id";
	$sqlComposi = preg_replace('/xxEntixx/' ,$laEnti    ,$sqlSA);
	$sqlComposi = preg_replace('/xxProyexx/',$idProyecto,$sqlComposi);
	$sqlComposi = preg_replace('/xxFechaxx/',$fechaRango,$sqlComposi);


wh_log("sqlSA*****************************************************");
wh_log($sqlComposi);


	$query      = $this->db->query($sqlComposi);
	$queryR     = $query->result_array();
	for($i = 0 ; $i < count($queryR) ; $i++){

		$saldoMNGen  -= (float)$arrRet[$i]['haber_mn_tot'];
		$saldoDivGen -= (float)$arrRet[$i]['haber_div_tot'];

		$arrRet[] = array(  'co_descripcion' => $queryR[$i]['co_descripcion'],
				    'cc_id'          => $queryR[$i]['cc_id'],
				    'cc_fecha'       => $queryR[$i]['cc_fecha'],
				    'tc_abreviado'   => $queryR[$i]['tc_abreviado'],
				    'cc_numero'      => $queryR[$i]['cc_numero'],
				    'cc_comentario'  => $queryR[$i]['cc_comentario'],
				    'debe_mn_tot'    => 0,
				    'debe_div_tot'   => 0,
				    'haber_mn_tot'   => $queryR[$i]['haber_mn_tot'],
				    'haber_div_tot'  => $queryR[$i]['haber_div_tot'],
				    'saldo_mn_tot'   => $queryR[$i]['haber_mn_tot'],
				    'saldo_div_tot'  => $queryR[$i]['haber_div_tot'],
				    'cc_entidad_id'  => 0,
				    'e_razon_social' => '',
				    'tipoentidad'    => '',
				    'saldo_mn_gen'   => $saldoMNGen,
				    'saldo_div_gen'  => $saldoDivGen,
				    'id_debi'        => $queryR[$i]['cc_id']);
	}


wh_log("..................................................");

	$lo = count($arrRet);

	for ($i=0; $i<$lo; $i++){

	    $arrRet[$i]['debe_mn_tot']  = number_format($arrRet[$i]['debe_mn_tot'] ,2,',','.');
	    $arrRet[$i]['haber_mn_tot'] = number_format($arrRet[$i]['haber_mn_tot'],2,',','.');
	    $arrRet[$i]['saldo_mn_tot'] = number_format($arrRet[$i]['saldo_mn_tot'],2,',','.');
	    $arrRet[$i]['saldo_mn_gen'] = number_format($arrRet[$i]['saldo_mn_gen'],2,',','.');

	    $arrRet[$i]['debe_div_tot']  = number_format($arrRet[$i]['debe_div_tot'] ,2,',','.');
	    $arrRet[$i]['haber_div_tot'] = number_format($arrRet[$i]['haber_div_tot'],2,',','.');
	    $arrRet[$i]['saldo_div_tot'] = number_format($arrRet[$i]['saldo_div_tot'],2,',','.');
	    $arrRet[$i]['saldo_div_gen'] = number_format($arrRet[$i]['saldo_div_gen'],2,',','.');


wh_log('saldo_mn_gen   ' . $arrRet[$i]['saldo_mn_gen']);
wh_log('saldo_div_gen   ' . $arrRet[$i]['saldo_div_gen']);


	}

wh_log(json_encode($arrRet));

wh_log("..................................................");




//				    'haber_mn_tot'   => ($queryR[$i]['haber_mn_tot']>0  ? number_format($queryR[$i]['haber_mn_tot'],2) :''),
//				    'haber_div_tot'  => ($queryR[$i]['haber_div_tot']>0 ? number_format($queryR[$i]['haber_div_tot'],2):''),
//				    'saldo_mn_tot'   => number_format($queryR[$i]['haber_mn_tot'],2),
//				    'saldo_div_tot'  => number_format($queryR[$i]['haber_div_tot'],2),
//				    'saldo_mn_gen'   => number_format($saldoMNGen,2),
//				    'saldo_div_gen'  => number_format($saldoDivGen,2),





///wh_log("*****************************************************");
//wh_log(json_encode($arrRet));

	return $arrRet;

    }






}