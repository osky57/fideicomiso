<?php

class Deudaconcaja_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('nocrud_deuda_con_caja.php');				// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveDeudaCCaja($elGet){
	$idProyecto = $this->session->id_proyecto_activo;
	$desde      = $elGet['fdesde'];
	$hasta      = $elGet['fhasta'];

	$sql        = "	SELECT   'REC'                               AS tipoComp
				,cc1.id                              AS cc1_id
				,cc1.tipo_comprobante_id             AS cc1TipoComp
				,cc1.entidad_id                      AS cc1_entidad_id
				,e.razon_social                      AS e_razon_social
				,cc1.fecha                           AS cc1_fecha
				,cc1.fecha_registro                  AS f_registro
				,cc1.numero                          AS cc1_numero
				,ccc.id                              AS ccc_id
				,ccc.importe                         AS ccc_importe
				,ccc.moneda_id                       AS ccc_moneda_id
				,ccc.cotizacion_divisa               AS ccc_cotizacion_divisa_id
				,ccc.tipo_movimiento_caja_id         AS ccc_tipo_movimiento_caja_id 
				,ccc.fecha_emision                   AS ccc_fecha_emision 
				,ccc.fecha_acreditacion              AS ccc_fecha_acreditacion 
				,CONCAT(ccc.serie , ccc.numero::VARCHAR,' ', b.denominacion) AS cheque
				,ccc.banco_id                        AS ccc_banco_id  
				,ccc.e_chq                           AS ccc_e_chq  
				,ccc.chq_a_depo                      AS ccc_chq_a_depo  
				,ccc.fecha_registro                  AS  ccc_fecha_registro   
				,ccc.signo_caja                      AS ccc_signo_caja  
				,ccc.signo_banco                     AS ccc_signo_banco
			FROM cuentas_corrientes cc1                                                    -- apunta a los recibos
			LEFT JOIN entidades e                  ON cc1.entidad_id = e.id                -- obtiene los importes de los pagos
			LEFT JOIN cuentas_corrientes_caja ccc  ON cc1.id = ccc.cuenta_corriente_id     -- obtiene los importes de los pagos
			LEFT JOIN tipos_movimientos_caja  tmc  ON ccc.tipo_movimiento_caja_id = tmc.id -- obtiene los tipos movimientos caja
			LEFT JOIN bancos b                     ON ccc.banco_id = tmc.id                -- obtiene el banco
			WHERE cc1.tipo_comprobante_id IN (9)     -- 9 recibo, 4 o/p
			  AND cc1.proyecto_origen_id = $idProyecto
			  AND tmc.tipo_mov in (1,2,3)            -- 1 efectivo, 2 y 3 chqs de 3ros
			  AND cc1.estado = 0
			  AND CAST(cc1.fecha_registro AS date) BETWEEN '$desde' AND '$hasta' 
			UNION
			SELECT
				'O/P'
				,cc1.id
				,cc1.tipo_comprobante_id
				,cc1.entidad_id 
				,e.razon_social                      AS e_razon_social
				,cc1.fecha 
				,cc1.fecha_registro           AS f_registro
				,cc1.numero
				,ccc.id  
				,ccc.importe  
				,ccc.moneda_id 
				,ccc.cotizacion_divisa 
				,ccc.tipo_movimiento_caja_id 
				,ccc1.fecha_emision 
				,ccc1.fecha_acreditacion 
				,CONCAT(ccc1.serie , ccc1.numero::VARCHAR,' ', b.denominacion) AS cheque
				,ccc1.banco_id  
				,ccc1.e_chq  
				,ccc1.chq_a_depo  
				,ccc.fecha_registro   
				,ccc.signo_caja  
				,ccc.signo_banco 
			FROM cuentas_corrientes cc1                                                     -- apunta a los recibos
			LEFT JOIN entidades e                   ON cc1.entidad_id = e.id                -- obtiene los importes de los pagos
			LEFT JOIN  cuentas_corrientes_caja ccc  ON cc1.id = ccc.cuenta_corriente_id     -- obtiene los importes de los pagos
			LEFT JOIN  tipos_movimientos_caja  tmc  ON ccc.tipo_movimiento_caja_id = tmc.id -- obtiene los tipos movimientos caja
			LEFT JOIN  cuentas_corrientes_caja ccc1 ON ccc.cta_cte_caja_origen_id = ccc1.id -- busca los datos del chq
			LEFT JOIN bancos b                      ON ccc.banco_id = tmc.id                -- obtiene el banco
			WHERE cc1.tipo_comprobante_id IN (4)     -- 9 recibo, 4 o/p
			  AND cc1.proyecto_origen_id = $idProyecto
			  AND tmc.tipo_mov in (1,2,3)            -- 1 efectivo, 2 y 3 chqs de 3ros
			  AND cc1.estado = 0
			  AND CAST(cc1.fecha_registro AS date) BETWEEN '$desde' AND '$hasta' 
			ORDER by f_registro   ";

wh_log("--------------------------");

wh_log($sql);



	$queryC     = $this->db->query($sql);
	$querySC    = $queryC->result_array();
	$saldoMN    = ($querySC[0]['efectivomn']      == null) ? 0 : $querySC[0]['efectivomn']  ;
	$saldoUS    = ($querySC[0]['efectivous']      == null) ? 0 : $querySC[0]['efectivous'];
	$saldoChq   = ($querySC[0]['cheques']         == null) ? 0 : $querySC[0]['cheques'];
	$saldoChqND = ($querySC[0]['cheques_no_depo'] == null) ? 0 : $querySC[0]['cheques_no_depo'];




//wh_log($saldoMN);
//wh_log($saldoUS);
//wh_log($saldoChq);
//wh_log($saldoChqND);
//wh_log("--------------------------");

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
			  AND tmc_mov_en_banco NOT IN ( 2, 4, 5)

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

	return $queryRC;
    }


}