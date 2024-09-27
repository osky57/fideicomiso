<?php

class Informepresu_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('nocrud_informes_presupuestos.php');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveInforme($elGet){
	$idProyecto = $this->session->id_proyecto_activo;
	$desde      = $elGet['fdesde'];
	$hasta      = $elGet['fhasta'];
	$laEnti     = $elGet['entidad'] > 0 ? " AND pre.entidad_id = ".$elGet['entidad'] : "";


//to_char(NULLIF(fun_calcimportecaja(cc.id, 1), 0::numeric), '9999,999,999D99'::text)


	$sql = "SELECT   pre.id AS pre_id
			,pre.fecha_inicio AS pre_fecha_inicio
			,pre.titulo AS pre_titulo
			,pre.comentario AS pre_comentario
			,pre.importe_inicial AS pre_importe_inicial
			,to_char(COALESCE(pre.importe_inicial, 0), '9,999,999,999,999D99'::text) AS pre_importe_inicialxx
			,pre.moneda_id	AS pre_moneda_id 
			,mo.denominacion AS mo_denominacion
			,pre.proyecto_id AS pre_proyecto_id
			,pro.nombre AS pro_nombre
			,pre.estado pre_estado
			,e.id AS e_id
			,e.razon_social AS e_razon_social
			,rpc.id AS rpc_id
			,rpc.cuenta_corriente_id AS rpc_cuenta_corriente_id
			,rpc.presupuesto_id AS rpc_presupuesto_id
			,rpc.estado AS rpc_estado
			,cc.id AS cc_id
			,cc.tipo_comprobante_id AS cc_tipo_comprobante_id
			,cc.importe AS cc_importe 
			,to_char(COALESCE(cc.importe, 0), '9,999,999,999,999D99'::text) AS cc_importexx
			,cc.fecha AS cc_fecha
			,cc.numero AS cc_numero
			,cc.moneda_id AS cc_moneda_id
			,tc.abreviado AS tc_abreviado
			,cc.docu_letra||cc.docu_sucu::text||' '||cc.docu_nume::text AS cclsn
			,cc.estado AS cc_estado
			,rcc.id AS rcc_id
			,rcc.monto_pesos AS rcc_monto_pesos
			,to_char(COALESCE(rcc.monto_pesos, 0), '9,999,999,999,999D99'::text) AS rcc_monto_pesosxx
			,rcc.monto_divisa AS rcc_monto_divisa
			,to_char(COALESCE(rcc.monto_divisa, 0), '9,999,999,999,999D99'::text) AS rcc_monto_divisaxx
			,rcc.estado AS rcc_estado
			,ccc.id AS ccc_id
			,ccc.fecha AS ccc_fecha
			--	,tcc.abreviado AS tcc_abreviado
			,tcc.abreviado || ' '|| ccc.numero  AS ccclsn
			--	,ccc.docu_letra||ccc.docu_sucu::text||' '||ccc.docu_nume::text AS ccclsnn
			,ccc.numero AS ccc_numero
			,ccc.estado AS ccc_estado
		FROM presupuestos pre
		LEFT JOIN entidades e            ON pre.entidad_id = e.id
		LEFT JOIN proyectos pro          ON pre.proyecto_id = pro.id
		LEFT JOIN monedas mo             ON pre.moneda_id = mo.id
		LEFT JOIN relacion_presu_ctactes rpc ON pre.id = rpc.presupuesto_id
		LEFT JOIN cuentas_corrientes cc  ON rpc.cuenta_corriente_id = cc.id
		LEFT JOIN tipos_comprobantes tc  ON cc.tipo_comprobante_id = tc.id
		LEFT JOIN relacion_ctas_ctes rcc ON cc.id = rcc.cuenta_corriente_id
		LEFT JOIN cuentas_corrientes ccc ON rcc.relacion_id = ccc.id
		LEFT JOIN tipos_comprobantes tcc ON ccc.tipo_comprobante_id = tcc.id
		WHERE pre.estado = 0
		  AND COALESCE(rpc.estado,0) = 0
		  AND COALESCE(cc.estado,0)  = 0
		  AND COALESCE(rcc.estado,0) = 0
		  AND COALESCE(ccc.estado,0) = 0
		  AND pre.fecha_inicio BETWEEN '$desde' AND '$hasta'
		$laEnti
		ORDER BY pre.entidad_id, pre.fecha_inicio DESC";

wh_log($sql);

	$query      = $this->db->query($sql);
	$queryS     = $query->result_array();
	return $queryS;

    }


}