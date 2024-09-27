<?php

class Materiales_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('crud_materiales');						// **->
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
	$where = " 1 = 1 ";      //cb_proyecto_id = $idProyecto "; // **->  en este crud hay q filtrar por proyecto_id!!

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

	$queryR   = null;
	if ($elId>0){
	    $sql      = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE id = $elId ";
	    $query    = $this->db->query($sql);  //trae campos del registro a editar
	    $queryR   = $query->result_array();
wh_log(json_encode($queryR)); 
	}
	return $queryR;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaUnRegistro($datos){

	$data = array(  "descripcion"  => substr($datos["frm_descripcion"],0, 100),							// **->
			"unidad"       => substr($datos["frm_unidad"],0,20),								// **->
			"ean_13"       => empty($datos["frm_ean13"])        ? null : $datos["frm_ean13"],				// **->
			"stock_minimo" => empty($datos["frm_stock_minimo"]) ? null : $datos["frm_stock_minimo"],			// **->
			"cantidad_uni_compra" => empty($datos["frm_cant_uni_compra"]) ? null : $datos["frm_cant_uni_compra"],		// **->
			"peso_uni_compra"     => empty($datos["frm_peso_uni_compra"]) ? null : $datos["frm_frm_peso_uni_compra"]	// **->
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
