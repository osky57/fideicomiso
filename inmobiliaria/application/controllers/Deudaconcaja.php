<?php

/*

// **->  indica linea a modificar en cada crud

*/

defined('BASEPATH') OR exit('No direct script access allowed');

class DeudaConCaja extends CI_Controller {								// **->

	///////////////////////////////////////////////////////////////////////////////////////////////
	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->config->load('nocrud_deuda_con_caja');						// **->
		$this->load->model($this->config->item('modelo'));
		$this->load->database();
		$this->load->helper('url');
		$this->load->helper('funciones_helper');
//		$this->load->helper('form');
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function index(){

	    $this->session->set_userdata( array('opMenu'   => isset($_GET['op']) ? $_GET['op'] : 0 ));

	    $idProyecto             = $this->session->id_proyecto_activo;
	    $datos['urlxDeudaCCaja']= $this->config->item('urlDeudaCCaja');
	    $datos['elurl']         = $this->config->item('urlGrid');
	    $datos['fHasta']        = date('Y-m-d');
	    $datos['fDesde']        = date('Y-m-d'); //, strtotime('-270 day',strtotime($datos['fHasta'])));
	    $this->load->view('deudasconcaja' ,$datos);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	// para q llame a esta funcion desde el url, primero indicar el controlador y despues la funcion
	// funcion generica para usar con bootstrap-table, solo se debe indicar el nombre del modelo y la funcion 
	// dentro del modelo q se debe llamar 
	public function deudaconcaja(){
	    $idProyecto = $this->session->id_proyecto_activo;
	    $info       = new Deudaconcaja_model();						// **->
	    $data       = $info->devuelveDeudaCCaja($_GET);
	    array_push($data,dameProyecto($idProyecto));
	    echo json_encode($data);
	}
}
