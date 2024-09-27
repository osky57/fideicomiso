<?php

class Presupuestos_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('crud_presupuestos');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveGrilla($offset,$limit,$sort='',$order='',$search='',$elLike,$idEnti=0,$fDesde,$fHasta){
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

	if ($idEnti > 0){
	    $where .= " AND e_id = $idEnti ";
	}

	$where .= " AND pre_fecha_inicio >= '$fDesde' AND pre_fecha_final <= '$fHasta' ";

	$sqlCount  = "SELECT COUNT(*) AS cant_reg FROM ".$this->config->item('nombreVista')." WHERE  $where ";                    // **->
	$sqlPagina = "SELECT * FROM ".$this->config->item('nombreVista')." WHERE $where $ordenar LIMIT $limit OFFSET $offset";    // **->
	$query     = $this->db->query($sqlCount);
	$cantReg   = $query->result();
	$query     = $this->db->query($sqlPagina);
	$aArray    = $query->result();
	for($i = 0; $i < count($aArray); $i++){
	    $aArray[$i]->pre_importe_inicial = "<b>".number_format($aArray[$i]->pre_importe_inicial,2,',','.')."</b>";
	}
	return array($aArray, $cantReg[0]->cant_reg);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveUnRegistro($elId = 0){
wh_log("devuelveUnRegistro");
	//////////////////////////////monedas
	$queryMo  = dameMonedas();


//	$queryR       = null;

wh_log("model elId " . $elId);

	if ($elId>0){
	    $sql      = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE id = $elId ";
	    $query    = $this->db->query($sql);  //trae campos del registro a editar
	    $queryR   = $query->result_array();

/////////////////////////////////////monedas
	    for($i = 0 ; $i < count($queryMo) ; $i++){
			$queryMo[$i]['selectado'] = $queryMo[$i]['id']==$queryR[0]['moneda_id'] ? ' selected ' : ' ' ;
	    }



	}

	$queryR[0]['monedas']        = $queryMo;



wh_log("queryR ");
wh_log(json_encode($queryR));

	return $queryR;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaUnRegistro($datos){

wh_log("data en model");

	$data = array(  "fecha_inicio"    => $datos["frm_fecha_inicio"],			// **->
			"fecha_final"     => $datos["frm_fecha_inicio"],			// **->
			"comentario"      => $datos["frm_comentario"],				// **->
			"importe_inicial" => $datos["frm_importe_inicial"],			// **->
			"importe_final"   => $datos["frm_importe_inicial"],			// **->
			"entidad_id"      => $datos["frm_entidad_id"],				// **->
			"moneda_id"       => $datos["frm_moneda_id"],				// **->
			"proyecto_id"     => $this->session->id_proyecto_activo,	// **->
			"titulo"          => $datos["frm_descripcion"]				// **->
			);

wh_log(json_encode($data));

	if ( !empty($datos["frm_id"]) ){				//actualizar
	    $this->db->where("id",intval($datos["frm_id"]));
	    return $this->db->update($this->config->item('nombreTabla'), $data);
	}else{								//ingresar
	    return $this->db->insert($this->config->item('nombreTabla'), $data);
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
}










