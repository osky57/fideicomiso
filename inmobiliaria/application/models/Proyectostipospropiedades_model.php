<?php

class Proyectostipospropiedades_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('crud_proyectostipospropiedades');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveGrilla($offset,$limit,$sort='',$order='',$search='',$elLike){

	$idProyecto = $this->session->id_proyecto_activo;
	$ordenar    = '';
	if ($sort != '' && $order != ''){
	    $ordenar = " ORDER BY $sort $order ";
	}
	$where = " pr_id = $idProyecto ";        // **->  en este crud hay q filtrar por proyecto_id!!
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
	//////////////////////////////tipos de propiedades
	$queryCB  = dameTiposPropie();

	//////////////////////////
	if ($elId>0){
	    $sql      = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE id = $elId ";
	    $query    = $this->db->query($sql);  //trae campos del registro a editar
	    $queryR   = $query->result_array();


	    ///////////////////////////////////agregado para este crud
	    ///////////////////////////////////////tipos de propiedades
	    for($i = 0 ; $i < count($queryCB) ; $i++){
		$queryCB[$i]['selectado'] = $queryCB[$i]['id']==$queryR[0]['tipo_propiedad_id'] ? ' selected ' : ' ' ;
	    }

	}
	$queryR[0]['tipos_propiedades'] = $queryCB;
	return $queryR;

    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaUnRegistro($datos){

	$idProyecto = $this->session->id_proyecto_activo;

	$data = array(  "proyecto_id"       => empty($idProyecto) ? null : $idProyecto,							// **->
			"tipo_propiedad_id" => empty($datos["frm_tipo_propiedad_id"])  ? null : $datos["frm_tipo_propiedad_id"],	// **->
			"comentario"        => substr($datos["frm_comentario"]         ,0,1024),					// **->
			"coeficiente"       => empty($datos["frm_coeficiente"])        ? null : $datos["frm_coeficiente"]		// **->
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
    public function devuelvePropietariosPropiedad($elId = 0){

	$idProyecto = $this->session->id_proyecto_activo;
	$queryR     = null;
	//trae todos los inversores del proyecto y con coeficiente si participan de la propiedad
	$sql      = "SELECT e.id AS e_id,e.razon_social||' ('||fun_dameTiposEntidades(e.id,'E')||')' AS razon_social , dptp.coeficiente AS dptp_coeficiente
		    FROM entidades e
		    LEFT JOIN detalle_proyecto_tipos_propiedades dptp ON e.id = dptp.entidad_id  AND dptp.proyecto_tipo_propiedad_id = $elId AND dptp.estado = 0
		    WHERE fun_buscartiposentidades(e.id,array['1']) >= 1
		      AND e.estado = 0
		      AND e.id IN (SELECT entidad_id 
				    FROM proyectos_entidades 
				    WHERE  proyecto_id = $idProyecto
				      AND  estado = 0)
		    ORDER BY dptp_coeficiente DESC,UPPER(e.razon_social)";

wh_log("---------------------------------------------------");
wh_log($sql);


	$query    = $this->db->query($sql);   // trae entidades
	$retorno['entidades'] = $query->result_array();
	return $retorno;

    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaDetalleProyectoPropiedad($datos){
	$idProyecto = $this->session->id_proyecto_activo;
	$idDeta     = $datos['elid'];
	foreach($datos as $x => $val) {
	    if (preg_match('/^indice\_(\d+)$/',$x,$matches)){
		$coef = empty($val) ? 0 : $val;
		$data = array(  "proyecto_tipo_propiedad_id" => $idDeta,
				"entidad_id"                 => $matches[1],
				"coeficiente"                => $coef );
		$q    = $this->db->insert("detalle_proyecto_tipos_propiedades", $data);
		if ($q != true){
		    $sql  = "UPDATE detalle_proyecto_tipos_propiedades SET coeficiente = ?
			     WHERE proyecto_tipo_propiedad_id = ? AND entidad_id = ?";
		    $q = $this->db->query($sql,[$coef,$idDeta,$matches[1]]);
		}
	    }
	}

    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function error($mensaje){
	$this->mensaje= $mensaje;
	return false;
    }

}
