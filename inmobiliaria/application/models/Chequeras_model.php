<?php

class Chequeras_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('crud_chequeras');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveGrilla($offset,$limit,$sort='',$order='',$search='',$elLike){

	$idProyecto = $this->session->id_proyecto_activo;

	$ordenar = '';
	if ($sort != '' && $order != ''){
	    $ordenar = " ORDER BY $sort $order ";
	}

	$where = " cb_proyecto_id = $idProyecto "; // **->  en este crud hay q filtrar por proyecto_id!!

	if ($search != '' ){
	    $search = strtoupper($search);
	    //hay q concatenar los campos q se usan para el where id + razon_social + direccion + celular etc
	    $where .= " AND UPPER(CONCAT(".$this->config->item('searchGrilla').")) LIKE '%$search%' ";
	}
	$sqlCount  = "SELECT COUNT(*) AS cant_reg FROM ".$this->config->item('nombreVista')." WHERE  $where ";
	$sqlPagina = "SELECT * FROM ".$this->config->item('nombreVista')." WHERE $where $ordenar LIMIT $limit OFFSET $offset";
	$query     = $this->db->query($sqlCount);
	$cantReg   = $query->result();
	$query     = $this->db->query($sqlPagina);
	return array($query->result(), $cantReg[0]->cant_reg);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveUnRegistro($elId = 0){
	$idProyecto = $this->session->id_proyecto_activo;
	$queryR     = null;

	//////////////////////////agregado para este crud, las funciones estan en helper
	//////////////////////////////cuentas bancarias
	$queryCB  = dameCtasBancarias($idProyecto,'C');
	//////////////////////////////monedas
	$queryMo  = dameMonedas();
	//////////////////////////////////////////

	if ($elId>0){
	    $sql      = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE id = $elId ";
	    $query    = $this->db->query($sql);  //trae campos del registro a editar
	    $queryR   = $query->result_array();

	    ////////////////////////////agregado para este crud
	    /////////////////////////////////////cuentas bancarias
	    for($i = 0 ; $i < count($queryCB) ; $i++){
		$queryCB[$i]['selectado'] = $queryCB[$i]['id']==$queryR[0]['cuenta_bancaria_id'] ? ' selected ' : ' ' ;
	    }
	    /////////////////////////////////////monedas
	    for($i = 0 ; $i < count($queryMo) ; $i++){
		$queryMo[$i]['selectado'] = $queryMo[$i]['id']==$queryR[0]['moneda_id'] ? ' selected ' : ' ' ;
	    }
	    /////////////////////////////tipo de cheque
	    if ($queryR[0]['echeque'] == 'S'){
		$queryR[0]['selected'] = 'checked';
	    }
	    ////////////////////////////

	}
	$queryR[0]['cuentas_bancarias'] = $queryCB;
	$queryR[0]['monedas']           = $queryMo;
	return $queryR;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaUnRegistro($datos){

	$data = array(  "cuenta_bancaria_id"  => empty($datos["frm_cuenta_bancaria_id"]) ? null : $datos["frm_cuenta_bancaria_id"],	// **->
			"echeque"             => empty($datos["frm_echeque"])            ? 'N'  : $datos["frm_echeque"],		// **->
			"serie"               => $datos["frm_serie"],									// **->
			"desde_nro"           => $datos["frm_desde_nro"],								// **->
			"hasta_nro"           => $datos["frm_hasta_nro"],								// **->
			"fecha_solicitud"     => $datos["frm_fecha_solicitud"],								// **->
			"moneda_id"           => empty($datos["frm_moneda_id"])          ? null : $datos["frm_moneda_id"]		// **->
			);

	if ( !empty($datos["frm_id"]) ){				//actualizar
	    $this->db->where("id",intval($datos["frm_id"]));
	    return $this->db->update($this->config->item('nombreTabla'), $data);
	}else{								//ingresar
	    return $this->db->insert($this->config->item('nombreTabla'), $data);
	}
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function eliminaUnRegistro($elId = 0){

	if ($elId>0){

	    $data = array("estado" => 1);
	    $this->db->where("id",intval($elId));
	    return $this->db->update($this->config->item('nombreTabla'), $data);

	}

	return false;
    }



    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function error($mensaje){
	$this->mensaje= $mensaje;
	return false;
    }

}
