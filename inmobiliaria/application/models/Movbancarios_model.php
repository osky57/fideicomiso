<?php

class Movbancarios_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('crud_movbancarios');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveGrilla($offset,$limit,$sort='',$order='',$search='',$elLike,$idEnti=0,$fDesde,$fHasta){

	$idProyecto = $this->session->id_proyecto_activo;
	$ordenar    = '';
	if ($sort != '' && $order != ''){
	    $ordenar = " ORDER BY cc_fecha_registro ";   //$sort $order ";
	}
	$where = " AND ccc_cuenta_bancaria_id = $idEnti ";
	if ($search != '' ){
	    $search = strtoupper($search);
	    //hay q concatenar los campos q se usan para el where id + razon_social + direccion + celular etc
	    $where .= " AND UPPER(CONCAT(".$this->config->item('searchGrilla').")) LIKE '%$search%' ";
	}

	$sqlSaldo = "SELECT SUM(entradas_banco_mn - salidas_banco_mn)  AS importe_c_signo
		    FROM vi_ctas_ctes_caja
		    WHERE ccc_fecha_registro::date < '$fDesde' 
		    $where";

	$query     = $this->db->query($sqlSaldo);
	$aArray    = $query->result();
	$saldo     = $aArray[0]->importe_c_signo;

wh_log("saldo inicial");
wh_log($saldo);

	$sqlCount  = "SELECT COUNT(*) AS cant_reg FROM vi_ctas_ctes_caja WHERE  1=1 $where ";
	$sqlPagina = "SELECT ccc_id AS mb_id,
			    ccc_fecha_registro::date AS mb_fecha,
			    tmc_descripcion || '(' || tmc_mov_en_banco::text ||')' AS tmc_descripcion ,
			    ccc_serie||ccc_numero::text AS mb_numero,
			    entradasmn - salidasmn AS xximporte_c_signo,
			    '' AS mo_denominacion,
			    ccc_comentario ||'  '||cb_denominacion AS mb_comentario,
			    entradas_banco_mn - salidas_banco_mn  AS importe_c_signo,
			    ccc_fecha_conciliacion::date AS mb_conciliacion
		    FROM vi_ctas_ctes_caja
		    WHERE ccc_fecha_registro::date BETWEEN '$fDesde' AND '$fHasta' $where
		    ORDER BY ccc_fecha_registro";

	$query     = $this->db->query($sqlCount);
	$cantReg   = $query->result();
	$query     = $this->db->query($sqlPagina);
	$aArray    = $query->result();

	$unReg     = array( 'mb_id' => '',
			    'mb_fecha' => '',
			    'tmc_descripcion' => '<h5><b>Saldo Anterior</b></h5>',
			    'mb_numero' => '',
			    'xximporte_c_signo' => 0,
			    'mo_denominacion' => '',
			    'mb_comentario' => '',
			    'importe_c_signo' => '<h5><b>'.number_format($saldo,2,',','.').'</b></h5>',
			    'mb_conciliacion' => '');
	array_unshift($aArray,$unReg);

	for($i=0; $i<count($aArray); $i++){ 
	    $saldo     = $aArray[$i]->importe_c_signo;
	    $aArray[$i]->importe_c_signo = number_format($aArray[$i]->importe_c_signo ,2,',','.');
	}
	$unReg['tmc_descripcion'] = '<h5><b>Saldo</b></h5>';
	$unReg['importe_c_signo'] = '<h5><b>'.number_format($saldo,2,',','.').'</b></h5>';
	$aArray[] = $unReg;

wh_log("saldo final");
wh_log($saldo);

wh_log("bancos");
wh_log($sqlPagina);
wh_log(json_encode($aArray));




/*
	$saldo     = 0;
	for($i = 0; $i < count($aArray); $i++){
	    $saldo += $aArray[$i]->importe_c_signo;
	}

	$unItem = array('mb_id'             => '',
			'mb_fecha'          => '',
			'tmc_descripcion'   => '<b>Saldo Final</b>',
			'mb_numero'         => '',
			'importe_c_signo'   => "<b>".number_format($saldo,2)."</b>" ,
			'mo_denominacion'   => '',
			'mb_comentario'     => '' );
	$aArray[] = $unItem;
*/
	return array($aArray, $cantReg[0]->cant_reg);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveGrillaOld($offset,$limit,$sort='',$order='',$search='',$elLike,$idEnti=0,$fDesde,$fHasta){

	$idProyecto = $this->session->id_proyecto_activo;
	$ordenar    = '';
	if ($sort != '' && $order != ''){
	    $ordenar = " ORDER BY mb_fecha ";   //$sort $order ";
	}
	$where = " AND cb_proyecto_id = $idProyecto AND cb_id = $idEnti ";
	if ($search != '' ){
	    $search = strtoupper($search);
	    //hay q concatenar los campos q se usan para el where id + razon_social + direccion + celular etc
	    $where .= " AND UPPER(CONCAT(".$this->config->item('searchGrilla').")) LIKE '%$search%' ";
	}
	$sqlCount  = "SELECT COUNT(*) AS cant_reg FROM ".$this->config->item('nombreVista')." WHERE  1=1 $where ";

	$sqlPagina = "SELECT * 
		    FROM vi_mov_bancarios
		    WHERE mb_fecha BETWEEN '$fDesde' AND '$fHasta' $where
		    ORDER BY mb_fecha,mb_id";

	$query     = $this->db->query($sqlCount);
	$cantReg   = $query->result();
	$query     = $this->db->query($sqlPagina);
	$aArray    = $query->result();
	$saldo     = 0;
	for($i = 0; $i < count($aArray); $i++){
	    $saldo += $aArray[$i]->importe_c_signo;
	}
	$unItem = array('mb_id'             => '',
			'mb_fecha'          => '',
			'tmc_descripcion'   => '<b>Saldo Final</b>',
			'mb_numero'         => '',
			'importe_c_signo'   => "<b>".number_format($saldo,2)."</b>" ,
			'mo_denominacion'   => '',
			'mb_comentario'     => '' );
	$aArray[] = $unItem;

	return array($aArray, $cantReg[0]->cant_reg);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveUnRegistro($elId = 0){

	$idProyecto = $this->session->id_proyecto_activo;
	$queryR     = null;

	//////////////////////////agregado para este crud
	//////////////////////////////tipos comprobantes
	$queryTC  = dameMediosBanco();

	//////////////////////////////monedas
	$queryMo  = dameMonedas();

	//////////////////////////////cotizaciones
	$queryCo  = dameCotizaciones();

	//////////////////////////////cotizacion del u$s
	$queryCo1 = dameCotizacion();


	//////////////////////////////tipos de medios de pago
//	$queryMP  = dameMediosPago();

	//////////////////////////////cuentas bancarias del proyecto
//	$queryCB  = dameCtasBancarias($idProyecto);

	//////////////////////////////bancos
//	$queryBa  = dameBancos();


	//////////////////////////
	$queryR[0]['fecha'] = date("Y-m-d");

	if ($elId>0){
	    $sql      = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE id = $elId ";
	    $query    = $this->db->query($sql);  //trae campos del registro a editar
	    $queryR   = $query->result_array();
	    ////////////////////////////agregado para este crud
	    /////////////////////////////////////tipos comprobantes
	    $tipoEntiComp = '';
	    for($i = 0 ; $i < count($queryTC) ; $i++){
		$queryTC[$i]['selectado'] = $queryTC[$i]['id']==$queryR[0]['tipo_comprobante_id'] ? ' selected ' : ' ' ;
		if ($queryTC[$i]['id']==$queryR[0]['tipo_comprobante_id']){
		    $tipoEntiComp = json_decode($queryTC[$i]['tipos_entidad']);
		    $tipoEntiComp = $tipoEntiComp->tipos_entidad[0];
		}
	    }
	    //////////////////////////////detalle tipos comprobantes en el proyecto para asociarlo a la entidad
	    if (!empty($queryR[0]['detalle_proyecto_tipo_propiedad_id'])){
		$sql      = "SELECT proyecto_tipo_propiedad_id AS ptp_id FROM detalle_proyecto_tipos_propiedades WHERE id = ".$queryR[0]['detalle_proyecto_tipo_propiedad_id'];
		$query    = $this->db->query($sql);
		$queryDP  = $query->result_array();
		for($i = 0 ; $i < count($queryTP) ; $i++){      //todos los tipos de propi
		    //busca el tipo de propiedad del detalle en tipos de propiedades
		    if ($queryDP[0]['ptp_id'] == $queryTP[$i]['ptp_id']){
			$queryTP[$i]['selectado'] =  ' selected ';
		    }
		}
	    }
	    /////////////////////////////////////monedas
	    for($i = 0 ; $i < count($queryMo) ; $i++){
		$queryMo[$i]['selectado'] = $queryMo[$i]['id']==$queryR[0]['moneda_id'] ? ' selected ' : ' ' ;
	    }
	    /////////////////////////////////////cotizaciones                  **** hay q ver como solucionar
	    for($i = 0 ; $i < count($queryCo) ; $i++){
		$queryCo[$i]['selectado'] = $queryCo[$i]['id']==$queryR[0]['tipo_comprobante_id'] ? ' selected ' : ' ' ;
	    }
	    ////////////////////////////
	}

	$vacioTP = array( "ptp_id" => "0","tp_descripcion" => "No aplica","ptp_comentario" => "","selectado" => " ");
	array_unshift($queryTP, $vacioTP);

	$vacioTC = array( "id" => "0","descripcion" => "Elija un tipo de comprobante","abreviado" => "     ","afecta_caja"=>"0","selectado" => " ");
	array_unshift($queryTC, $vacioTC);

	$queryR[0]['cotizaciones']   = $queryCo;
	$queryR[0]['monedas']        = $queryMo;
//	$queryR[0]['tiposprop']      = $queryTP;
	$queryR[0]['tiposcompr']     = $queryTC;
	$queryR[0]['mediospago']     = $queryMP;
//	$queryR[0]['ctasbancarias']  = $queryCB;
//	$queryR[0]['bancos']         = $queryBa;
//	$queryR[0]['chequeras']      = $queryCa;
	$queryR[0]['cotizacion']     = $queryCo1;


wh_log(json_encode($queryR[0]['tiposcompr']));


	return $queryR;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaUnRegistro($datos){

	$transOk     = false;
	$idProyecto  = $this->session->id_proyecto_activo;
	$idUsuario   = $this->session->logged_in['id'];
	$tipoCom     = explode('|', $datos["frm_tipo_comprobante_id"]);  //0-> id tipo comp., 1->   , 2->tipo enti., 3-> , 4-> modelo
	$detaTipoPro = null;

/*

$tipoCom
 9 efectivo (deposito cuando va al banco) toca caja   1
10 chq.3ro recibido
11 echq.3ro recibido
12 chq.3ro disponible			 toca caja    1
13 echq.3ro disponible			 toca caja    1
14 chq propio emitido                                -1
15 echq propio emitido                               -1
16 cobro por banco			 toca caja    1
17 pago por banco                                    -1
18 gastos bancarios                                  -1
19 efectivo retiro 			 toca caja   -1

*/


	$this->db->trans_begin();
	if (isset($datos["frm_tipo_comprobante_id"])){
	    $tiposMov = explode("|",$datos["frm_tipo_comprobante_id"]);
	    if (array_search($tiposMov[0],$this->config->item('concepto_toca_caja')) !== NULL){

		$arrNeg  = array(-1,14,15,17,18,19);
		$arrPos  = array(-1, 9,12,13,16);
		$elSigno = 0;
		if (array_search($tiposMov[0], $arrNeg) != NULL){       //mov q indican retiro del banco
		    $elSigno = -1;
		}elseif (array_search($tiposMov[0], $arrPos) != NULL){   //mov q indican ingreso al banco
		    $elSigno = 1;
		}
		$movCaja = array("cuenta_corriente_id"     => null,
				 "cuenta_bancaria_id"      => $datos["frm_cta_banc"],
				 "tipo_movimiento_caja_id" => empty($tiposMov[0])                 ? null : $tiposMov[0],
				 "importe"                 => empty($datos["frm_importe"])        ? null : $datos["frm_importe"],
				 "moneda_id"               => empty($datos["frm_moneda_id"])      ? null : $datos["frm_moneda_id"],
				 "cotizacion_divisa"       => empty($datos["frm_importe_divisa"]) ? 0    : $datos["frm_importe_divisa"],
				 "importe_divisa"          => empty($datos["frm_importe_divisa"]) ? 0    : $datos["frm_importe_divisa"],
				 "comentario"              => $datos["frm_comentario"],
				 "caja_id"                 => 1,
				 "proyecto_id"             => $idProyecto,
				 "e_chq"                   => $tiposMov[5],
				 "fecha_registro"          => $datos["frm_fecha"],
				 "signo_caja"              => -$elSigno,    //en mov bancarios el signo caja lleva signo contrario
				 "signo_banco"             => $elSigno );   //indica como opera el registro en caja, 
									    //1 -> recibo, incrementa monto, -1 -> o/p decrementa monto
									    //0 otras operaciones q no estan en caja
									    //esta parte solo incluyen los movimentos de inversores y proveedores 
		if ($datos["carterachq"] != null){
		    $elChq = explode("|",$datos["carterachq"][0]);
		    $movCaja["cta_cte_caja_origen_id"]  = $elChq[0];
		    $movCaja["chq_a_depo"]         = 1;
		    $movCaja["importe"]            = $elChq[3];
		    $movCaja["moneda_id"]          = $elChq[2];
		    $movCaja["cotizacion_divisa"]  = $elChq[4];
		    $movCaja["importe_divisa"]     = $elChq[4];
		}
		$transOk = $this->db->insert('cuentas_corrientes_caja', $movCaja);
		if ($transOk){
		    $this->db->trans_commit();
		}else{
		    $this->db->trans_rollback();
		}
	    }
	}

	return $transOk;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function eliminaUnRegistro($elId = 0){
	if ($elId>0){
	    $transOk = false;
	    $data    = array("estado" => 1);
	    $this->db->trans_begin();
	    $this->db->where("id",intval($elId));

wh_log($this->config->item('nombreTabla'));


	    if ($this->db->update("cuentas_corrientes_caja", $data)){

//		$this->db->where("cuenta_corriente_id",intval($elId));
//		if ($this->db->update("cuentas_corrientes_caja", $data)){
//		    $this->db->where("cuenta_corriente_id",intval($elId));
//		    if ($this->db->update("relacion_ctas_ctes", $data)){
//			$this->db->where("relacion_id",intval($elId));
//			if ($this->db->update("relacion_ctas_ctes", $data)){
//			    $this->db->where("cuenta_corriente_id",intval($elId));
//			    if ($this->db->update("relacion_ctas_ctes", $data)){
				$transOk = true;
//			    }
//			}
//		    }
//		}
	    }
	    if ($transOk){
		$this->db->trans_commit();
		wh_log("eliminado $elId");
	    }else{
		$this->db->trans_rollback();
		wh_log("NO PUDO SER eliminado $elId");
	    }
	    return $transOk;
	}
	return false;
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function ActuConci($elId = 0, $fechaConci = null){
	$lRet = 0;
	if ($elId > 0){      // && $fechaConci != null){
	    if ($fechaConci == null){ $data    = array("fecha_conciliacion" => null); }
	    else{$data    = array("fecha_conciliacion" => $fechaConci);}
	    $this->db->where("id",intval($elId));
	    if ($this->db->update("cuentas_corrientes_caja", $data)){
		$lRet = 1;
	    }
	}
	return $lRet;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function RecuChqsCartera($eChq = 0){
	$idProyecto = $this->session->id_proyecto_activo;
	$aDepo      = 1;   //recupera solamente los a depositar del proyecto actual
	$chqsDispo  = dameChqsCartera($idProyecto, $eChq, $aDepo);
	return $chqsDispo;

    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function error($mensaje){
	$this->mensaje= $mensaje;
	return false;
    }



    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function infoComp($compId){


	return dameInfoComp($compId,1);     //1 indica q $compId es el id de la tabla cuentas_corrientes_caja y debe buscar el campo
					    //cuenta_corriente_id para recuperar el comprobante


    }


}
