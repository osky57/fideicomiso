<?php

class Moventreproy_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('crud_moventreproy');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveGrilla($offset,$limit,$sort='',$order='',$search='',$elLike,$fDesde,$fHasta){

	$idProyActu = $this->session->id_proyecto_activo;
/*
	$sqlPagina = "SELECT  ccROC.id AS ccROC_id
			    ,ccROC.fecha AS ccROC_fechax
			    ,to_char(ccROC.fecha, 'DD-MM-YYYY'::text) AS ccROC_fecha
			    ,ccROC.tipo_comprobante_id AS ccROC_tipo_comprobante_id
			    ,tcROC.abreviado || ' Nro.' || COALESCE(ccROC.docu_letra, ' ') || ' ' || COALESCE(ccROC.docu_sucu::text, ' ') || ' ' || COALESCE(ccROC.docu_nume::text, ccROC.numero::text) AS comp1_nume
			    ,ccROC.proyecto_origen_id AS ccROC_proyecto_origen_id
			    ,prROC.nombre AS prROC_nombre 
			    ,ccFD.id AS ccFD_id
			    ,ccFD.fecha AS ccFD_fechax
			    ,to_char(ccFD.fecha, 'DD-MM-YYYY'::text) AS ccFD_fecha
			    ,ccFD.tipo_comprobante_id AS ccFD_tipo_comprobante_id
			    ,tcFD.abreviado || ' Nro.' || COALESCE(ccFD.docu_letra, ' ') || ' ' || COALESCE(ccFD.docu_sucu::text, ' ') || ' ' || COALESCE(ccFD.docu_nume::text, ccFD.numero::text) AS comp2_nume
			    ,ccFD.proyecto_origen_id AS ccFD_proyecto_origen_id
			    ,prFD.nombre AS prFD_nombre 
			    ,rcc.monto_pesos AS rcc_monto_pesos
			    ,rcc.monto_divisa AS rcc_monto_divisa
		    FROM cuentas_corrientes ccROC
		    LEFT JOIN tipos_comprobantes tcROC     ON ccROC.tipo_comprobante_id = tcROC.id
		    LEFT JOIN proyectos prROC              ON ccROC.proyecto_origen_id  = prROC.id
		    LEFT JOIN relacion_ctas_ctes rcc       ON ccROC.id = rcc.relacion_id AND rcc.estado = 0
		    LEFT JOIN cuentas_corrientes ccFD      ON rcc.cuenta_corriente_id = ccFD.id AND ccFD.estado = 0
		    LEFT JOIN tipos_comprobantes tcFD      ON ccFD.tipo_comprobante_id = tcFD.id
		    LEFT JOIN proyectos prFD               ON ccFD.proyecto_origen_id  = prFD.id
		    WHERE ccROC.estado = 0
		      AND tcROC.modelo IN (5)
		      AND ccROC.proyecto_origen_id = $idProyActu
		      AND ccROC.fecha BETWEEN '$fDesde' AND '$fHasta'
		    ORDER BY ccFD.proyecto_origen_id,ccROC.fecha,ccROC.id ";

//		      AND ccFD.proyecto_origen_id  = $idProyDest
*/

	$sqlPagina = "SELECT
    '1' AS xx
    ,ccROC.id AS ccROC_id
    ,ccROC.fecha AS ccROC_fechax
    ,to_char(ccROC.fecha, 'DD-MM-YYYY'::text) AS ccROC_fecha
    ,ccROC.tipo_comprobante_id AS ccROC_tipo_comprobante_id
    ,tcROC.abreviado || ' Nro.' || COALESCE(ccROC.docu_letra, ' ') || ' ' || COALESCE(ccROC.docu_sucu::text, ' ') || ' ' || COALESCE(ccROC.docu_nume::text, ccROC.numero::text) AS comp1_nume
    ,ccROC.proyecto_origen_id AS ccROC_proyecto_origen_id
    ,prROC.nombre AS prROC_nombre
    ,ccFD.id AS ccFD_id
    ,ccFD.fecha AS ccFD_fechax
    ,to_char(ccFD.fecha, 'DD-MM-YYYY'::text) AS ccFD_fecha
    ,ccFD.tipo_comprobante_id AS ccFD_tipo_comprobante_id
    ,tcFD.abreviado || ' Nro.' || COALESCE(ccFD.docu_letra, ' ') || ' ' || COALESCE(ccFD.docu_sucu::text, ' ') || ' ' || COALESCE(ccFD.docu_nume::text, ccFD.numero::text) AS comp2_nume
    ,ccFD.proyecto_origen_id AS ccFD_proyecto_origen_id
    ,prFD.nombre AS prFD_nombre
    ,TO_CHAR(NULLIF(rcc.monto_pesos * -1, 0), '9G999G999G999G999D99'::text) AS rcc_monto_pesos
    ,TO_CHAR(NULLIF(rcc.monto_divisa * -1, 0), '9G999G999G999G999D99'::text) AS rcc_monto_divisa
    ,rcc.monto_pesos  AS rcc_monto_pesosnn
    ,rcc.monto_divisa AS rcc_monto_divisann
    FROM cuentas_corrientes ccROC
    LEFT JOIN tipos_comprobantes tcROC     ON ccROC.tipo_comprobante_id = tcROC.id
    LEFT JOIN proyectos prROC              ON ccROC.proyecto_origen_id  = prROC.id
    LEFT JOIN relacion_ctas_ctes rcc       ON ccROC.id = rcc.relacion_id AND rcc.estado = 0
    LEFT JOIN cuentas_corrientes ccFD      ON rcc.cuenta_corriente_id = ccFD.id AND ccFD.estado = 0
    LEFT JOIN tipos_comprobantes tcFD      ON ccFD.tipo_comprobante_id = tcFD.id
    LEFT JOIN proyectos prFD               ON ccFD.proyecto_origen_id  = prFD.id
    WHERE ccROC.estado = 0
      AND tcROC.modelo IN (5)
      AND ccROC.proyecto_origen_id = $idProyActu
      AND ccFD.proyecto_origen_id <> $idProyActu
      AND ccROC.fecha BETWEEN '$fDesde' AND '$fHasta'

UNION

SELECT  
    '2' AS xx
    ,ccROC.id AS ccROC_id
    ,ccROC.fecha AS ccROC_fechax
    ,to_char(ccROC.fecha, 'DD-MM-YYYY'::text) AS ccROC_fecha
    ,ccROC.tipo_comprobante_id AS ccROC_tipo_comprobante_id
    ,tcROC.abreviado || ' Nro.' || COALESCE(ccROC.docu_letra, ' ') || ' ' || COALESCE(ccROC.docu_sucu::text, ' ') || ' ' || COALESCE(ccROC.docu_nume::text, ccROC.numero::text) AS comp1_nume
    ,ccROC.proyecto_origen_id AS ccROC_proyecto_origen_id
    ,prROC.nombre AS prROC_nombre
    ,ccFD.id AS ccFD_id
    ,ccFD.fecha AS ccFD_fechax
    ,to_char(ccFD.fecha, 'DD-MM-YYYY'::text) AS ccFD_fecha
    ,ccFD.tipo_comprobante_id AS ccFD_tipo_comprobante_id
    ,tcFD.abreviado || ' Nro.' || COALESCE(ccFD.docu_letra, ' ') || ' ' || COALESCE(ccFD.docu_sucu::text, ' ') || ' ' || COALESCE(ccFD.docu_nume::text, ccFD.numero::text) AS comp2_nume
    ,ccFD.proyecto_origen_id AS ccFD_proyecto_origen_id
    ,prFD.nombre AS prFD_nombre
    ,TO_CHAR(NULLIF(rcc.monto_pesos * -1, 0), '9G999G999G999G999D99'::text) AS rcc_monto_pesos
    ,TO_CHAR(NULLIF(rcc.monto_divisa * -1, 0), '9G999G999G999G999D99'::text) AS rcc_monto_divisa
    ,rcc.monto_pesos * -1 AS rcc_monto_pesosnn
    ,rcc.monto_divisa * -1 AS rcc_monto_divisann
    FROM cuentas_corrientes ccROC
    LEFT JOIN tipos_comprobantes tcROC     ON ccROC.tipo_comprobante_id = tcROC.id
    LEFT JOIN proyectos prROC              ON ccROC.proyecto_origen_id  = prROC.id
    LEFT JOIN relacion_ctas_ctes rcc       ON ccROC.id = rcc.relacion_id AND rcc.estado = 0
    LEFT JOIN cuentas_corrientes ccFD      ON rcc.cuenta_corriente_id = ccFD.id AND ccFD.estado = 0
    LEFT JOIN tipos_comprobantes tcFD      ON ccFD.tipo_comprobante_id = tcFD.id
    LEFT JOIN proyectos prFD               ON ccFD.proyecto_origen_id  = prFD.id
    WHERE ccROC.estado = 0
      AND tcROC.modelo IN (5)
      AND ccROC.proyecto_origen_id <> $idProyActu
      AND ccFD.proyecto_origen_id = $idProyActu
      AND ccROC.fecha BETWEEN '$fDesde' AND '$fHasta'

   ORDER BY xx  ,ccFD_proyecto_origen_id ,ccROC_fecha,ccROC_id ";

	$query     = $this->db->query($sqlPagina);
	$cantReg   = 0;  //count($query->result());
	$aArray    = $query->result();

	for($i=0; $i<count($aArray); $i++){ 
	    $aArray[$i]->rcc_monto_pesos  = number_format($aArray[$i]->rcc_monto_pesosnn ,2,',','.');
	    $aArray[$i]->rcc_monto_divisa = number_format($aArray[$i]->rcc_monto_divisann,2,',','.');
	}

wh_log($sqlPagina);
wh_log(json_encode($aArray));

	return array($aArray, $cantReg);
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function error($mensaje){
	$this->mensaje= $mensaje;
	return false;
    }



    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function infoComp($compId){
	$sqlC = "SELECT cc_id, tc_abreviado|| ' Nro.' || cc_numero::text AS tc_num, cc_fecha_dmy, 
			cc_entidad_id, e_razon_social,e_celular, local_prov, e_observaciones, 
			p_nombre, debe_txt_mn_tot,cc_importe, cc_moneda_id, cc_importe_divisa,
			u_nombre, cc_fecha_registro,ptp_comentario, ptp_coeficiente, tp_descripcion,
			cc_comentario, tc_modelo,debe_txt_mn_tot, haber_txt_mn_tot,
			debe_txt_div_tot, haber_txt_div_tot,
			coalesce(debe_mn_tot,0)  + coalesce(haber_mn_tot,0)  AS totalMN,
			coalesce(debe_div_tot,0) + coalesce(haber_div_tot,0) AS totalDIV,
			fun_comprobsinaplicar(cc_id) AS sinaplicar, fun_comprobsaldo(cc_id) AS saldocomprob
		FROM vi_ctas_ctes WHERE cc_id = ?";
	$query          = $this->db->query($sqlC,[$compId]);
	$query          = $query->result_array();
	$ret['comprob'] = $query[0];
	$sqlP = "SELECT  ccc_importe, ccc_importe_divisa, mo1_denominacion
			,mo1_simbolo, tmc_descripcion, ccc_comentario,ccc_id
			,ba2_denominacion, to_char(ccc_fecha_emision,'dd-mm-yyyy') AS ccc_f_emi_dmy
			,to_char(ccc_fecha_acreditacion,'dd-mm-yyyy') AS ccc_f_acre_dmy
			,ccc_serie||' '||LPAD(ccc_numero::text,8,'0')||' ('||ccc_cartel_a_depo||')' AS serienroX
			,cb_denominacion 
			,COALESCE(ba3_denominacion,ba2_denominacion) AS banco
			,CASE WHEN ccc_numero IS NOT NULL THEN ccc_serie||LPAD(ccc_numero::text,8,'0')||' ('||ccc_cartel_a_depo||')'
			      WHEN ccch_numero IS NOT NULL THEN ccch_serie||LPAD(ccch_numero::text,8,'0')||' ('||ccch_cartel_a_depo||')' 
			 END AS serienro
			,to_char(COALESCE(ccch_fecha_emision,ccc_fecha_emision),'dd-mm-yyyy') AS f_emision
			,to_char(COALESCE(ccch_fecha_acreditacion,ccc_fecha_acreditacion),'dd-mm-yyyy') AS f_acreditacion
		FROM vi_ctas_ctes_caja WHERE ccc_cuenta_corriente_id = ?";
	$query          = $this->db->query($sqlP,[$compId]);
	$query          = $query->result_array();
	$ret['pagos']   = $query;

	$ret['modelo']  = $ret['comprob']['tc_modelo'];
	$c12            = strstr('45',$ret['comprob']['tc_modelo']) !== false ? '2' : '1';
	$c21            = strstr('45',$ret['comprob']['tc_modelo']) !== false ? '1' : '2';
	$sqlA           = "SELECT * FROM vi_aplicaciones_ctas_ctes WHERE cc".$c12."_id = ".$compId;
	$query          = $this->db->query($sqlA);
	$query          = $query->result_array();
	$todosQ         = array();
	foreach($query as $unQ){
	    $todosQ[]   = array('comentario' => $unQ["cc".$c21."_comentario"],
				'fecha'      => $unQ["cc".$c21."_fecha"],
				'fecha_dmy'  => $unQ["cc".$c21."_fecha_dmy"],
				'id'         => $unQ["cc".$c21."_id"],
				'comp_nume'  => $unQ["comp".$c21."_nume"],
				'rcc_monto_divisa' => $unQ['rcc_monto_divisa'],
				'rcc_monto_pesos'  => $unQ['rcc_monto_pesos']);
	}
	$ret['aplicaciones'] = $todosQ;
	return $ret;
    }

}
