<?php

class Tiposcomprob_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('crud_tiposcomprob');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveGrilla($offset,$limit,$sort='',$order='',$search='',$elLike){
	$ordenar = '';
	if ($sort != '' && $order != ''){
	    $ordenar = " ORDER BY $sort $order ";
	}
	$where = ' 1 = 1 ';
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

	/////////////////////////////////////////agregado para este crud
	/////////////////////////////////tipos de entidades
	$queryTE  = dameTiposEnti();

	/////////////////////////////////modelos de comprobantes
	$queryMC  = dameModeloComprob();

	/////////////////////////////////conceptos de comprobantes
	$queryCC  = dameConceptoComprob();

	if ($elId>0){

	    $sqlReg   = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE id = $elId ";
	    $query    = $this->db->query($sqlReg);  //trae campos del registro a editar
	    $queryR   = $query->result_array();

	    /////////////////////////////////////////////////////////agregado para este crud
	    //////////////////////////signo
	    if ($queryR[0]['signo'] == 1){
		$queryR[0]['checked1'] = 'checked';
	    }else if ($queryR[0]['signo'] == -1){
		$queryR[0]['checked2'] = 'checked';
	    }

	    //////////////////////////si afecta a caja
	    $queryR[0]['afecta_caja'] = $queryR[0]['afecta_caja'] == 1 ? 'checked' : '';

	    //////////////////////////si aplica impu
	    $queryR[0]['aplica_impu'] = $queryR[0]['aplica_impu'] == 1 ? 'checked' : '';

	    /////////////////////////tipos entidad
	    $tipoEntArr = json_decode($queryR[0]['tipos_entidad']);
	    $tiposEnt   = $tipoEntArr->tipos_entidad;
	    for($i = 0 ; $i < count($queryTE) ; $i++){
		$queryTE[$i]['selectado'] = in_array($queryTE[$i]['id'],$tiposEnt) ? ' checked ' : ' ' ;
	    }

	    ///////////////////////////////////////modelo de comprobante
	    for($i = 0 ; $i < count($queryMC) ; $i++){
		$queryMC[$i]->selectado = $queryMC[$i]->id==$queryR[0]['modelo'] ? ' selected ' : ' ' ;
	    }
	    //

	    ///////////////////////////////////////concepto afectado
	    for($i = 0 ; $i < count($queryCC) ; $i++){
		$queryCC[$i]->selectado = $queryCC[$i]->id==$queryR[0]['concepto'] ? ' selected ' : ' ' ;
	    }

	}
	$queryR[0]['tipo_entidad_arr'] = $queryTE;
	$queryR[0]['modelo_arr']       = $queryMC;
	$queryR[0]['concepto_arr']     = $queryCC;
	return $queryR;

    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaUnRegistro($datos){
	//esto q sigue es exclusivo para este crud, pero es base para trabajar con campos json
	foreach($datos as $k => $v){
	    if (preg_match("/^frm_tipoe/",$k)){
		$tipoEnt[] = $v;
	    }
	}
	$datos["tipoEntidadArr"] = array("tipos_entidad" => $tipoEnt);
	if ($datos["tipoEntidadArr"]["tipos_entidad"] == null){
	    $datos["tipoEntidadArr"]["tipos_entidad"] = ["1"];
	}
	$data = array(  "descripcion"   => substr($datos["frm_descripcion"] ,0, 100),				// **->
			"signo"         => empty($datos["frm_signo"])       ? null : $datos["frm_signo"],	// **->
			"abreviado"     => empty($datos["frm_abreviado"])   ? null : $datos["frm_abreviado"],	// **->
			"afecta_caja"   => empty($datos["frm_afecta_caja"]) ? 0    : $datos["frm_afecta_caja"],	// **->
			"aplica_impu"   => empty($datos["frm_aplica_impu"]) ? 0    : $datos["frm_aplica_impu"],	// **->
			"numero"        => empty($datos["frm_numero"])      ? 0    : $datos["frm_numero"],	// **->
			"modelo"        => empty($datos["frm_modelo"])      ? 0    : $datos["frm_modelo"],	// **->
			"concepto"      => empty($datos["frm_concepto"])    ? 0    : $datos["frm_concepto"],	// **->
			"tipos_entidad" => json_encode($datos["tipoEntidadArr"])				// **->
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
