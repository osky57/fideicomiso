<?php

/*

// **->  indica linea a modificar en cada crud

*/

defined('BASEPATH') OR exit('No direct script access allowed');

class InformesPresu extends CI_Controller {								// **->

	///////////////////////////////////////////////////////////////////////////////////////////////
	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->config->load('nocrud_informes_presupuestos');					// **->
		$this->load->model($this->config->item('modelo'));
		$this->load->database();
		$this->load->helper('url');
		$this->load->helper('funciones_helper');
//		$this->load->helper('form');
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function index(){

	    $this->session->set_userdata( array('opMenu'   => isset($_GET['op']) ? $_GET['op'] : 0 ));

	    $idProyecto         = $this->session->id_proyecto_activo;
	    $datos['urlxInfoCC']= $this->config->item('urlInfoPresu');
	    $datos['elurl']     = $this->config->item('urlGrid');
	    $datos['entidades'] = dameEntiXTipo($this->config->item('tipos_enti_provee'),0,1);
	    $datos['fHasta']    = date('Y-m-d');
	    $datos['fDesde']    = date('Y-m-d', strtotime('-365 day',strtotime($datos['fHasta'])));
	    $this->load->view('informespresu',$datos);
	}

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function informepresu(){
	    $idProyecto = $this->session->id_proyecto_activo;
	    $info       = new Informepresu_model();						// **->
	    $data       = $info->devuelveInforme($_GET);
wh_log(json_encode($data));
	    echo json_encode($data);
	}

}



