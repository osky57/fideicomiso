<?php

class Proyectos_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('crud_proyectos');						// **->
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
	$sqlCount  = "SELECT COUNT(*) AS cant_reg FROM ".$this->config->item('nombreVista')." WHERE  $where ";                    // **->
	$sqlPagina = "SELECT * FROM ".$this->config->item('nombreVista')." WHERE $where $ordenar LIMIT $limit OFFSET $offset";    // **->
	$query     = $this->db->query($sqlCount);
	$cantReg   = $query->result();
	$query     = $this->db->query($sqlPagina);
	return array($query->result(), $cantReg[0]->cant_reg);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveUnRegistro($elId = 0){
	$queryR   = null;

	/////////////////////////////////////////////////////agregado para este crud
	////////////////////////////localidades
	$queryL   = dameLocali();
	////////////////////////////tipos de proyectos
	$queryTP  = dameTiposProy();
	////////////////////////////tipos de obra
	$queryOb  = dameTiposObras();
	//

	if ($elId>0){
	    $sqlReg   = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE id = $elId ";
	    $query    = $this->db->query($sqlReg);  //trae campos del registro a editar
	    $queryR   = $query->result_array();

	    //agregado para este crud
	    for($i = 0 ; $i < count($queryL) ; $i++){
		$queryL[$i]['selectado'] = $queryL[$i]['id']==$queryR[0]['localidad_id'] ? ' selected ' : ' ' ;
	    }
	    for($i = 0 ; $i < count($queryTP) ; $i++){
		$queryTP[$i]['selectado'] = $queryTP[$i]['id']==$queryR[0]['tipo_proyecto_id'] ? ' selected ' : ' ' ;
	    }
	    for($i = 0 ; $i < count($queryOb) ; $i++){
		$queryOb[$i]['selectado'] = $queryOb[$i]['id']==$queryR[0]['tipo_obra_id'] ? ' selected ' : ' ' ;
	    }
	    //

	}
	$queryR[0]['localidades']     = $queryL;
	$queryR[0]['tipos_proyectos'] = $queryTP;
	$queryR[0]['tipos_obras']     = $queryOb;
	return $queryR;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaUnRegistro($datos){
	$data = array(  "nombre"             => substr($datos["frm_nombre"]             ,0, 100),				 // **->
			"calle"              => substr($datos["frm_calle"]              ,0, 100),				 // **->
			"numero"             => substr($datos["frm_numero"]             ,0,  20),				 // **->
			"tipo_proyecto_id"   => empty($datos["frm_tipo_proyecto_id"])   ? null : $datos["frm_tipo_proyecto_id"], // **->
			"tipo_obra_id"       => empty($datos["frm_tipo_obra_id"])       ? null : $datos["frm_tipo_obra_id"],	 // **->
			"localidad_id"       => empty($datos["frm_localidad"])          ? null : $datos["frm_localidad"],	 // **->
			"comentario"         => substr($datos["frm_comentario"]         ,0,1024),				 // **->
			"fecha_inicio"       => empty($datos["frm_fecha_inicio"])       ? null : $datos["frm_fecha_inicio"],	 // **->
			"fecha_finalizacion" => empty($datos["frm_fecha_finalizacion"]) ? null : $datos["frm_fecha_finalizacion"]// **->
		);
		//falta la definicion del campo características (tipo json)

	if ( !empty($datos["frm_id"]) ){				//actualizar
	    $this->db->where("id",intval($datos["frm_id"]));
	    return $this->db->update($this->config->item('nombreTabla'), $data);
	}else{								//ingresar
	    return $this->db->insert($this->config->item('nombreTabla'), $data);
	}
    }

    //procedimiento exclusivo de este crud
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelvePropiedadesProyecto($elId = 0){
	$queryR   = null;
	if ($elId>0){
	    $sqlReg   = "SELECT tp_descripcion,
				ptp_cantidad,
				ptp_comentario,
				ptp_id,tp_id 
			FROM vi_proyectos_tipos_propiedades 
			WHERE pr_id = $elId ";
	    $query    = $this->db->query($sqlReg);
	    $queryR   = $query->result_array();
	}
	return $queryR;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveProyecto($elId = 0){

	$queryR   = null;
	if ($elId > 0){
	    $sqlReg   = "SELECT * FROM proyectos WHERE id = $elId ";
	    $query    = $this->db->query($sqlReg);
	    $queryR   = $query->result_array();
	}
	return $queryR;

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
