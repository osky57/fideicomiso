<?php

class Entidades_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('crud_entidades');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveGrilla($offset,$limit,$sort='',$order='',$search='',$elLike){
	$ordenar = '';
	$queryTE  = dameTiposEnti();
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
	return array($query->result(), $cantReg[0]->cant_reg, $queryTE);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveUnRegistro($elId = 0){
	$queryR   = null;
	/////////////////////////////////////agregado para este crud
	//////////////////////////// localidades
	$queryL   = dameLocali();
	//////////////////////////// tipos de entidades
	$queryTE  = dameTiposEnti();
	//////////////////////////// proyectos, campo noes = 1 si la entidad es un proyecto
	$queryNE  = dameProyectoNoEnti($elId);

	if ($elId>0){
	    $sql      = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE id = $elId ";
	    $query    = $this->db->query($sql);  //trae campos del registro a editar
	    $queryR   = $query->result_array();

	    //agregado para este crud
	    //localidad
	    for($i = 0 ; $i < count($queryL) ; $i++){
		$queryL[$i]['selectado'] = $queryL[$i]['id']==$queryR[0]['localidad_id'] ? ' selected ' : ' ' ;
	    }
	    //tipos entidad
	    $tipoEntArr = json_decode($queryR[0]['tipos_entidad']);
	    $tiposEnt   = $tipoEntArr->tipos_entidad;
	    for($i = 0 ; $i < count($queryTE) ; $i++){
		$queryTE[$i]['selectado'] = in_array($queryTE[$i]['id'],$tiposEnt) ? ' checked ' : ' ' ;
	    }
	}

	$queryR[0]['localidades']      = $queryL;
	$queryR[0]['tipo_entidad_arr'] = $queryTE;
	$queryR[0]['proyectos_noes']   = $queryNE;

	return $queryR;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaUnRegistro($datos){

	//esto q sigue es exclusivo para este crud, pero es base para trabajar con campos json
	$tienePerfil = 0;
	foreach($datos as $k => $v){
	    if (preg_match("/^frm_tipoe/",$k)){
		$tipoEnt[]   = $v;
		$tienePerfil = 1;
	    }
	}
	if ($tienePerfil > 0){
	    $datos["tipoEntidadArr"] = array("tipos_entidad" => $tipoEnt);
	    $xcx  = $datos["tipoEntidadArr"]["tipos_entidad"];
	    $idTE = in_array("3",$xcx ) ? $datos["frm_proyectos_noes"] : null;
	    $data = array(  "razon_social"      => substr($datos["frm_razon_social"]       ,0, 100),	// **->
			    "cuit"              => empty($datos["frm_cuit"])               ? null : $datos["frm_cuit"],	// **->
			    "calle"             => substr($datos["frm_calle"]              ,0, 100),	// **->
			    "numero"            => substr($datos["frm_numero"]             ,0,  20),	// **->
			    "piso_departamento" => substr($datos["frm_piso_departamento"]  ,0,  20),	// **->
			    "celular"           => substr($datos["frm_celular"]            ,0,  20),	// **->
			    "whatsapp"          => substr($datos["frm_whatsapp"]           ,0,  20),	// **->
			    "email"             => substr($datos["frm_email"]              ,0,  80),	// **->
			    "localidad_id"      => empty($datos["frm_localidad"])          ? null : $datos["frm_localidad"],	// **->
			    "observaciones"     => substr($datos["frm_observaciones"]      ,0,1024),	// **->
			    "tipos_entidad"     => json_encode($datos["tipoEntidadArr"]),		// **->
			    "proyecto_id"       => $datos["frm_proyectos_noes"]==0 ? null : $idTE            //datos["frm_proyectos_noes"]	// **->
			    );






	    if ( !empty($datos["frm_id"]) ){				//actualizar
		$this->db->where("id",intval($datos["frm_id"]));
		return $this->db->update($this->config->item('nombreTabla'), $data);
	    }else{								//ingresar
		return $this->db->insert($this->config->item('nombreTabla'), $data);
	    }
	}
	return 0;
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


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function validaCuit($elId = 0, $cuit = 0){
	$ret = array('estado' => 0, 'mensaje' => '');
	if ($cuit > 0){
	    $sql    = "SELECT id,razon_social FROM entidades WHERE estado = 0 AND cuit = $cuit";
	    $query  = $this->db->query($sql);
	    $aArray = $query->result();
	    foreach($aArray as $xx){
		if ($elId == 0){			//es alta de entidad y el cuit ya existe
		    $ret['estado']  = 1;
		    $ret['mensaje'] = 'El nro de documento '.$cuit.' existe en la entidad '.$xx->id.'  '.$xx->razon_social;
		}else{					//es modificacion de entidad
		    if ($elId != $xx->id){		//el cuit existe en otra entidad
			$ret['estado']  = 2;
			$ret['mensaje'] = 'El nro de documento '.$cuit.' existe en la entidad '.$xx->id.'  '.$xx->razon_social;
		    }
		}
	    }
	    return $ret;
	}
    }
}










