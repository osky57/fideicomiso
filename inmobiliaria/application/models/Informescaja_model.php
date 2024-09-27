<?php

class Informescaja_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('nocrud_informes_caja.php');				// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveCaInforme($elGet){
	$idProyecto = $this->session->id_proyecto_activo;
	$desde      = $elGet['fdesde'];
	$hasta      = $elGet['fhasta'];
	$soloProy   = $elGet['soloproy'];
	$filProy    = "";
	if ($soloProy == "true"){
	    $filProy = " AND COALESCE( cc_proyecto_origen_id, ccc_proyecto_id) = $idProyecto ";
	}

	$sql        = "SELECT
			SUM(CASE WHEN tmc_gestiona_cheques = 0 AND ccc_moneda_id = 1 THEN entradas_caja_mn - salidas_caja_mn
			    ELSE 0
			END) AS efectivomn,
			SUM(CASE WHEN tmc_gestiona_cheques = 0 AND ccc_moneda_id <> 1 THEN entradas_caja_us - salidas_caja_us
			    ELSE 0
			END) AS efectivous,
			SUM(CASE WHEN tmc_gestiona_cheques = 1 AND ccc_chq_a_depo = 1 THEN entradas_caja_mn - salidas_caja_mn
			    ELSE 0
			END) AS cheques,
			SUM(CASE WHEN tmc_gestiona_cheques = 1  AND ccc_chq_a_depo IS NULL THEN entradas_caja_mn - salidas_caja_mn
			    ELSE 0
			END) AS cheques_no_depo
			FROM vi_ctas_ctes_caja
			WHERE ccc_fecha_registro::date < '$desde' 
			  AND tmc_tipo_mov IN ( 1, 2, 3)
			$filProy";



//tmc_mov_en_banco NOT IN ( 2, 4, 5)
//no debe mostrar 2->chq y pagos x banco, 4->retenciones, 5->canjes 



	$queryC     = $this->db->query($sql);
	$querySC    = $queryC->result_array();
	$saldoMN    = ($querySC[0]['efectivomn']      == null) ? 0 : $querySC[0]['efectivomn']  ;
	$saldoUS    = ($querySC[0]['efectivous']      == null) ? 0 : $querySC[0]['efectivous'];
	$saldoChq   = ($querySC[0]['cheques']         == null) ? 0 : $querySC[0]['cheques'];
	$saldoChqND = ($querySC[0]['cheques_no_depo'] == null) ? 0 : $querySC[0]['cheques_no_depo'];

wh_log("--------------------------");

wh_log($sql);




wh_log($saldoMN);
wh_log($saldoUS);
wh_log($saldoChq);
wh_log($saldoChqND);
wh_log("--------------------------");

	$primRegC   = array(  'cc_fecha'                => ''
			    , 'tc_abreviadonume'        => '<b>Saldo Anterior</b>'
			    , 'tmc_descripcion'         => ''
			    , 'ccc_comentario'          => ''
			    , 'ccc_importe_divisa'      => ''
			    , 'efectivomn'              => $saldoMN
			    , 'efectivous'              => $saldoUS
			    , 'cheques'                 => $saldoChq
			    , 'cheques_no_depo'         => $saldoChqND
			    , 'el_chq'                  => ''
			    , 'ccc_fecha_emision'       => ''
			    , 'ccc_fecha_acreditacion'  => ''
			    , 'ccc_e_chq'               => ''
			    , 'cc_entidad_id'           => null
			    , 'en_razon_social'         => ''
			    , 'cc_proyecto_id'          => ''
			    , 'ccc_fecha_registro'      => '');


//			    , 'efectivomn'              => '<b>'.number_format($saldoMN,2).'</b>'
//			    , 'efectivous'              => '<b>'.number_format($saldoUS,2).'</b>'
//			    , 'cheques'                 => '<b>'.number_format($saldoChq,2).'</b>'
//			    , 'cheques_no_depo'         => '<b>'.number_format($saldoChqND,2).'</b>'





	$sql        = "SELECT
			ccc_id,
			ccc_cuenta_corriente_id,
			tc_abreviado ||' '||cc_numero::text AS tc_abreviadonume,
			tmc_txt_info_caja AS tmc_descripcion,
			ccc_comentario,
			cc_fechax,
			tc_abreviado,
			cc_entidad_id,
			ccc_proyecto_id,

			COALESCE( cc_proyecto_id, ccc_proyecto_id) AS xcc_proyecto_id,
			COALESCE( pr_nombre, prc_nombre) AS pr_nombre,

			en_razon_social,
			ccc_importe,
			tc_signo,
			tmc_e_chq,
			substring(' E' ,ccc_e_chq+1,1) AS ccc_e_chq,
			ba2_denominacion ||' '||ccc_serie||ccc_numero::text||' '||substring(' E' ,ccc_e_chq+1,1)  AS el_chq,
			ccc_fecha_emision,
			ccc_fecha_acreditacion,
			ccc_importe_divisa,

			CASE WHEN tmc_gestiona_cheques = 0 AND ccc_moneda_id = 1 THEN entradas_caja_mn - salidas_caja_mn
			    ELSE 0
			END AS efectivomn,

			CASE WHEN tmc_gestiona_cheques = 0 AND ccc_moneda_id = 2 THEN entradas_caja_us - salidas_caja_us
			    ELSE 0
			END AS efectivous,


			CASE WHEN tmc_gestiona_cheques = 1 AND ccc_chq_a_depo = 1 THEN entradas_caja_mn - salidas_caja_mn
			    ELSE 0
			END AS cheques,

			CASE WHEN tmc_gestiona_cheques = 1  AND ccc_chq_a_depo IS NULL THEN entradas_caja_mn - salidas_caja_mn
			    ELSE 0
			END AS cheques_no_depo,

			ccc_fecha_registro::date AS ccc_fecha_registro

			FROM vi_ctas_ctes_caja
			WHERE ccc_fecha_registro::date BETWEEN '$desde' AND '$hasta'
			  AND tmc_tipo_mov IN ( 1, 2, 3)

			$filProy
			ORDER BY ccc_fecha_registro, tc_abreviadonume ";
wh_log("info caja");
wh_log($sql);



	$queryC     = $this->db->query($sql);
	$queryRC    = $queryC->result_array();
	for($i = 0 ; $i < count($queryRC) ; $i++){
	    $saldoMN    += ($queryRC[$i]['efectivomn']+0) - ($queryRC[$i]['salidasmn']+0);
	    $saldoUS    += ($queryRC[$i]['efectivous']+0) - ($queryRC[$i]['salidasus']+0);
	    $saldoChq   += ($queryRC[$i]['cheques']+0);
	    $saldoChqND += ($queryRC[$i]['cheques_no_depo']+0);
	}
	array_unshift($queryRC, $primRegC);

	$ultRegC    = array(  'cc_fecha'                => ''
			    , 'tc_abreviadonume'        => '<b>Saldo Final</b>'
			    , 'tmc_descripcion'         => ''
			    , 'ccc_comentario'          => ''
			    , 'ccc_importe_divisa'      => ''
			    , 'efectivomn'              => $saldoMN
			    , 'efectivous'              => $saldoUS
			    , 'cheques'                 => $saldoChq
			    , 'cheques_no_depo'         => $saldoChqND
			    , 'el_chq'                  => ''
			    , 'ccc_fecha_emision'       => ''
			    , 'ccc_fecha_acreditacion'  => ''
			    , 'ccc_e_chq'               => ''
			    , 'cc_entidad_id'           => null
			    , 'en_razon_social'         => ''
			    , 'cc_proyecto_id'          => ''
			    , 'ccc_fecha_registro'      => ''
			    , 'pr_nombre'               => '');

//			    , 'efectivomn'              => '<b>'.number_format($saldoMN,2).'</b>'
//			    , 'efectivous'              => '<b>'.number_format($saldoUS,2).'</b>'
//			    , 'cheques'                 => '<b>'.number_format($saldoChq,2).'</b>'
//			    , 'cheques_no_depo'         => '<b>'.number_format($saldoChqND,2).'</b>'


	$queryRC[] = $ultRegC;


wh_log(json_encode($queryRC));



	return $queryRC;
    }





    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function infoComp($compId){
	return dameInfoComp($compId);       //no pasando 2do param., significa q $compId es el id en cuentas_corrientes
    }

}