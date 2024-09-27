<?php

class Proyectosentidades_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('crud_proyectosentidades');						// **->
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
	$where = " p_id = $idProyecto AND e_estado = 0 "; // **->  en este crud hay q filtrar por proyecto_id!!
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
	//////////////////////////////entidades, solo traigo inversores
	$sql      = "SELECT id,razon_social||' ('||fun_dameTiposEntidades(id,'E')||')' AS razon_social ".
		    "FROM entidades ".
		    "WHERE fun_buscartiposentidades(id,array['1']) >= 1 ".
		    "  AND id NOT IN (SELECT entidad_id FROM ".$this->config->item('nombreTabla')." WHERE  proyecto_id = $idProyecto AND estado = 0) ".
		    "  AND estado = 0 ".
		    "ORDER BY razon_social";
	$query    = $this->db->query($sql);   // trae entidades
	$queryCB  = $query->result_array();
	//////////////////////////

	if ($elId>0){
	    $sql      = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE id = $elId ";
	    $query    = $this->db->query($sql);  //trae campos del registro a editar
	    $queryR   = $query->result_array();
	    ////////////////////////////agregado para este crud
	    /////////////////////////////////////entidades
	    foreach($queryR as $reg){
		for($i = 0 ; $i < count($queryCB) ; $i++){
		    if ($queryCB[$i]['id']==$queryR[0]['id']){
			unset($queryCB[$i]);
		    }
		}
	    }
	    ////////////////////////////
	}
	$queryR[0]['entidades'] = $queryCB;

	return $queryR;

    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaUnRegistro($datos){
	$idProyecto = $this->session->id_proyecto_activo;
	$data = array(  "proyecto_id"  => empty($idProyecto) ? null : $idProyecto,		// **->
			"entidad_id"   => empty($datos["frm_entidad_id"])  ? null : $datos["frm_entidad_id"]		// **->
			);
	$sql      = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE entidad_id = ".$datos["frm_entidad_id"] ." AND proyecto_id = $idProyecto";
	$query    = $this->db->query($sql);  //trae campos del registro a editar
	$queryR   = $query->result_array();

	if (count($queryR) == 0){
	    return $this->db->insert($this->config->item('nombreTabla'), $data);
	}else{
	    $data  = array('estado' => 0);
	    $where = array('id' => $queryR[0]['id']);
	    return $this->db->update($this->config->item('nombreTabla'), $data, $where);
	}

    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function eliminaUnRegistro($elId = 0){
	if ($elId>0){
	    $idProyecto = $this->session->id_proyecto_activo;
	    $data = array("estado" => 1);
	    $this->db->where("id",intval($elId));
	    $this->db->update($this->config->item('nombreTabla'), $data);
	    $sql = "UPDATE detalle_proyecto_tipos_propiedades SET estado = 1 
		    WHERE id IN (SELECT id
				FROM detalle_proyecto_tipos_propiedades
				WHERE entidad_id = (SELECT entidad_id 
						    FROM proyectos_entidades 
						    WHERE id = $elId)
				AND proyecto_tipo_propiedad_id IN (SELECT id 
								   FROM proyectos_tipos_propiedades
								   WHERE proyecto_id = $idProyecto)  )";

////////////////////////////falta eliminar en algun lugar mas


	    $query = $this->db->query($sql);
	    return true;
	}
	return false;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function error($mensaje){
	$this->mensaje= $mensaje;
	return false;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveCtaCte($entiCC = 0){

	$idProyecto = $this->session->id_proyecto_activo;
	if ($entiCC > 0){
		/*no borrar porq tengo los campos de la vista
		$sql = "SELECT cc_id, cc_tipo_comprobante_id, cc_importe, cc_moneda_id, cc_importe_divisa,
				cc_entidad_id, cc_detalle_proyecto_tipo_propiedad_id, cc_comentario, cc_proyecto_id,
				cc_usuario_id, cc_fecha, cc_fecha_dmy, cc_fecha_registro, cc_numero, mo_simbolo,
				debe_txt_mn_tot, haber_txt_mn_tot, debe_txt_div_tot, haber_txt_div_tot, 
				tc_descripcion, tc_signo, tc_abreviado 
		*/
		$sql = "SELECT   cc_fecha
				,cc_fecha_dmy
				,tc_descripcion
				,debe_mn_tot
				,haber_mn_tot
				,debe_div_tot
				,haber_div_tot
				,cc_comentario
				,cc_id
				,CASE WHEN debe_txt_mn_tot  is null THEN '' ELSE debe_txt_mn_tot  END 
				,CASE WHEN haber_txt_mn_tot is null THEN '' ELSE haber_txt_mn_tot END 
				,CASE WHEN debe_txt_div_tot  is null THEN '' ELSE debe_txt_div_tot  END
				,CASE WHEN haber_txt_div_tot is null THEN '' ELSE haber_txt_div_tot END
				,saldo_mn
				,saldo_div
				FROM vi_ctas_ctes 
				WHERE cc_proyecto_id = $idProyecto AND cc_entidad_id = $entiCC 
				ORDER BY cc_fecha,cc_id ";

		$query  = $this->db->query($sql);   // trae entidades
		$aArray = $query->result_array();
		$saldoPesos = 0;
		$saldoDolar = 0;
		for($i = 0; $i < count($aArray); $i++){
		    $saldoPesos += $aArray[$i]['debe_mn_tot'] -$aArray[$i]['haber_mn_tot'];
		    $saldoDolar += $aArray[$i]['debe_div_tot']-$aArray[$i]['haber_div_tot'];
		    $aArray[$i]['saldo_mn']  = number_format($saldoPesos,2);
		    $aArray[$i]['saldo_div'] = number_format($saldoDolar,2);
		}
		$unItem = array('cc_fecha'          => '<b>Saldo Final</b>',
				'cc_fecha_dmy'      => '',
				'tc_descripcion'    => '',
				'debe_mn_tot'       => '',
				'haber_mn_tot'      => '',
				'debe_div_tot'      => '',
				'haber_div_tot'     => '',
				'cc_comentario'     => '',
				'cc_id'             => '',
				'debe_txt_mn_tot'   => '',
				'haber_txt_mn_tot'  => '',
				'debe_txt_div_tot'  => '',
				'haber_txt_div_tot' => '',
				'saldo_mn'          => "<b>".number_format($saldoPesos,2)."</b>" ,
				'saldo_div'         => "<b>".number_format($saldoDolar,2)."</b>" );
		$aArray[] = $unItem;
		$aArray   = array_reverse($aArray);
		return $aArray;
	}
    }
}
