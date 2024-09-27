<?php

/*

// **->  indica linea a modificar en cada crud

*/

defined('BASEPATH') OR exit('No direct script access allowed');

class InformesChq extends CI_Controller {								// **->

	///////////////////////////////////////////////////////////////////////////////////////////////
	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->config->load('nocrud_informes_chq');						// **->
		$this->load->model($this->config->item('modelo'));
		$this->load->database();
		$this->load->helper('url');
		$this->load->helper('funciones_helper');
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function index(){
	    $this->session->set_userdata( array('opMenu'   => isset($_GET['op']) ? $_GET['op'] : 0 ));
	    $idProyecto             = $this->session->id_proyecto_activo;
	    $datos['urlxInfoChq']   = $this->config->item('urlInfoChq');
	    $datos['urlxInfoChqRF'] = $this->config->item('urlInfoChqRF');
	    $datos['elurl']         = $this->config->item('urlGrid');
	    $datos['fHasta']        = date('Y-m-d');
	    $datos['fDesde']        = $this->session->inicio_proyecto_activo;

	    if (empty($datos['fDesde']) ){
		$datos['fDesde']    = date('Y-m-d', strtotime('-365 day',strtotime($datos['fHasta'])));
	    }
wh_log(json_encode($datos));

	    $this->load->view('informeschq',$datos);
	}

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function informechq(){
	    $idProyecto = $this->session->id_proyecto_activo;
	    $info       = new Informeschq_model();						// **->
	    $data       = $info->devuelveInforme($_GET);
	    if ($idProyecto > 0){
		array_push($data,dameProyecto($idProyecto));
	    }
	    echo json_encode($data);
	}

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function informechqrf(){
	    $idProyecto = $this->session->id_proyecto_activo;
	    $info       = new Informeschq_model();						// **->
	    $data       = $info->devuelveRF($_GET);
	    if ($idProyecto > 0){
		array_push($data,dameProyecto($idProyecto));
	    }
	    echo json_encode($data);
	}

}



