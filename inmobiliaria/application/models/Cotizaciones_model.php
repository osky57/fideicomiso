<?php

class Cotizaciones_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('crud_cotizaciones');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveGrilla($offset,$limit,$sort='',$order='',$search='',$elLike){

	$idProyecto = $this->session->id_proyecto_activo;

	$ordenar = ' ORDER BY c_fecha DESC, m_id ';
	if ($sort != '' && $order != ''){
//	    $ordenar = " ORDER BY $sort $order ";
	}

	$where = " 1 = 1 ";

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

	//////////////////////////agregado para este crud
	//////////////////////////////monedas
	$queryMo  = dameMonedas();
	//////////////////////////////////////////////

	if ($elId>0){
	    $sql      = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE id = $elId ";
	    $query    = $this->db->query($sql);  //trae campos del registro a editar
	    $queryR   = $query->result_array();


	    ////////////////////////////agregado para este crud
	    /////////////////////////////////////monedas
	    for($i = 0 ; $i < count($queryMo) ; $i++){
		$queryMo[$i]['selectado'] = $queryMo[$i]['id']==$queryR[0]['moneda_id'] ? ' selected ' : ' ' ;
	    }
	    ////////////////////////////

	}
	$queryR[0]['monedas']           = $queryMo;

	return $queryR;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaUnRegistro($datos){

	$data = array(  "fecha"               => $datos["frm_fecha"],							// **->
			"importe"             => empty($datos["frm_importe"])   ? null : $datos["frm_importe"],		// **->
			"moneda_id"           => empty($datos["frm_moneda_id"]) ? null : $datos["frm_moneda_id"]	// **->
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
