<?php

/*

// **->  indica linea a modificar en cada crud

*/

defined('BASEPATH') OR exit('No direct script access allowed');

class InformesCaja extends CI_Controller {								// **->

	///////////////////////////////////////////////////////////////////////////////////////////////
	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->config->load('nocrud_informes_caja');						// **->
		$this->load->model($this->config->item('modelo'));
		$this->load->database();
		$this->load->helper('url');
		$this->load->helper('funciones_helper');
//		$this->load->helper('form');
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function index(){

	    $this->session->set_userdata( array('opMenu'   => isset($_GET['op']) ? $_GET['op'] : 0 ));

	    $idProyecto           = $this->session->id_proyecto_activo;
	    $datos['urlxInfoCaja']= $this->config->item('urlInfoCaja');
	    $datos['elurl']       = $this->config->item('urlGrid');
	    $datos['fHasta']      = date('Y-m-d');
	    $datos['fDesde']      = date('Y-m-d',strtotime('-180 day',strtotime($datos['fHasta'])));
	    $datos['urlinfocomp'] = $this->config->item('urlInfoComp');
	    $datos['tieneproy']   = ($idProyecto > 0) ? 1 : 0;
	    $this->load->view('informescaja',$datos);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	// para q llame a esta funcion desde el url, primero indicar el controlador y despues la funcion
	// funcion generica para usar con bootstrap-table, solo se debe indicar el nombre del modelo y la funcion 
	// dentro del modelo q se debe llamar 
	public function informecaja(){
	    $idProyecto = $this->session->id_proyecto_activo;
	    $info       = new Informescaja_model();						// **->
	    $data       = $info->devuelveCaInforme($_GET);
	    if ($idProyecto > 0){
		array_push($data,dameProyecto($idProyecto));
	    }
	    echo json_encode($data);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function infoComp(){
		$compId  = isset($_GET['idcomp']) ? $_GET['idcomp']    : 0;
		$enti    = new Informescaja_model();							// **->
		$retorno = $enti->infoComp($compId);
		echo json_encode($retorno);
	}

}
