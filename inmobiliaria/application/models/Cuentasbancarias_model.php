<?php

class Cuentasbancarias_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('crud_cuentasbancarias');						// **->
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
	$queryR   = null;


	//////////////////////////agregado para este crud
	//////////////////////////////bancos
	$queryBa  = dameBancos();
	/////////////////////////////////////////////

	if ($elId>0){
	    $sql      = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE id = $elId ";
	    $query    = $this->db->query($sql);  //trae campos del registro a editar
	    $queryR   = $query->result_array();


	    ////////////////////////////agregado para este crud
	    /////////////////////////////////////banco
	    for($i = 0 ; $i < count($queryBa) ; $i++){
		$queryBa[$i]['selectado'] = $queryBa[$i]['id']==$queryR[0]['banco_id'] ? ' selected ' : ' ' ;
	    }
	    /////////////////////////////tipo de cuenta
	    if ($queryR[0]['tipo'] == 'C'){
		$queryR[0]['checked1'] = 'checked';
	    }else if ($queryR[0]['tipo'] == 'A'){
		$queryR[0]['checked2'] = 'checked';
	    }
	    ////////////////////////////

	}
	$queryR[0]['bancos']      = $queryBa;

	return $queryR;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaUnRegistro($datos){

	$idProyecto = $this->session->id_proyecto_activo;

	$data = array(  "proyecto_id"   => empty($idProyecto) ? null : $idProyecto,				// **->
			"denominacion"  => substr($datos["frm_denominacion"],0, 100),				// **->
			"banco_id"      => empty($datos["frm_banco_id"])    ? null : $datos["frm_banco_id"],	// **->
			"cbu"           => substr($datos["frm_cbu"]         ,0, 100),				// **->
			"alias"         => substr($datos["frm_alias"]       ,0,  20),				// **->
			"tipo"          => empty($datos["frm_tipo"])        ? null : $datos["frm_tipo"]		// **->
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
