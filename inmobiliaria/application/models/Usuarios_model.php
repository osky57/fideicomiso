<?php
class Usuarios_model extends CI_Model{
	public $nombre;
	public $usuario;
	public $password;
	public $mensaje;

	public function __construct() {
	    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
	    ////////////////////////////////////////////////////////////////2022-06-13 agregado para el crud de usuarios
	    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
	    $this->config->load('crud_usuarios');						// **->

	    $this->load->database();
	}

	public function login($usuario, $password){
		if (!is_string($usuario)){
			return $this->error("Error usuario vacio.");
		}
		if (!is_string($password)){
			return $this->error("Error password vacio.");
		}
		$this->db->select('id, nombre, usuario, nivel');
		$this->db->from('usuarios');
		$this->db->where('usuario = ' . "'" . $usuario . "'");
		$this->db->where('password = ' . "'" . MD5($password) . "'");
		$this->db->limit(1);
		$query = $this->db->get();
		if ($query->num_rows() == 1){
		    return $query->result();
		} else {
		    return $this->error("Error en usuario o contraseña.");
		}
	}

	public function error($mensaje){
		$this->mensaje= $mensaje;
		return false;
	}


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////2022-06-13 agregado para el crud de usuarios
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

	if ($elId>0){

	    $sqlReg   = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE id = $elId ";
	    $query    = $this->db->query($sqlReg);  //trae campos del registro a editar
	    $queryR   = $query->result_array();


	    $queryR[0]['nivel'] = $queryR[0]['nivel'] == 1 ? 'checked' : '';


	    $queryR[0]['password'] = "";

	}

	return $queryR;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaUnRegistro($datos){
	$data = array(  "nombre"        => substr($datos["frm_nombre"] ,0, 40),			// **->
			"usuario"       => substr($datos["frm_usuario"],0, 40),			// **->
			"nivel"         => $datos["frm_nivel"]=="" ? 0 : $datos["frm_nivel"]	// **->
		);

wh_log($datos["frm_nivel"]);
wh_log($data["nivel"]);


	if (!empty($datos["frm_password"])){
	    $data["password"] = MD5($datos["frm_password"]);					// **->
	}

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





}