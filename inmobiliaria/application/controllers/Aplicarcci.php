<?php

/*

// **->  indica linea a modificar en cada crud

*/

defined('BASEPATH') OR exit('No direct script access allowed');

class AplicarCCI extends CI_Controller {								// **->

	///////////////////////////////////////////////////////////////////////////////////////////////
	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->config->load('nocrud_aplicar_cci');						// **->
		$this->load->model($this->config->item('modelo'));
		$this->load->database();
		$this->load->helper('url');
		$this->load->helper('funciones_helper');
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function index(){

	    $this->session->set_userdata( array('opMenu'   => isset($_GET['op']) ? $_GET['op'] : 0 ));

	    $idProyecto              = $this->session->id_proyecto_activo;
	    $datos['urlxApliCCI']    = $this->config->item('urlApliCCI');
	    $datos['urlxGraApliCCI'] = $this->config->item('urlGrabaApliCCI');

	    $datos['elurl']     = $this->config->item('urlGrid');
	    $datos['entidades'] = dameEntiProye($idProyecto);    //, $this->config->item('tipos_enti_filtro'));
	    $datos['fHasta']    = date('Y-m-d');
	    $datos['fDesde']    = date('Y-m-d', strtotime('-365 day',strtotime($datos['fHasta']))); //$this->session->inicio_proyecto_activo;   
	    $vacioTP            = array( "e_id" => "0","e_razon_social" => "Todos los movimientos del proyecto","tipoentidad" => "","selectado" => " ");
	    array_unshift($datos['entidades'], $vacioTP);

	    $this->load->view('aplicarcci',$datos);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	// para q llame a esta funcion desde el url, primero indicar el controlador y despues la funcion
	// funcion generica para usar con bootstrap-table, solo se debe indicar el nombre del modelo y la funcion 
	// dentro del modelo q se debe llamar 
	public function aplicarcci(){
	    $info    = new Aplicarcci_model();						// **->
	    $data    = $info->devuelveAplicar($_POST);
	    echo json_encode($data);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function grabaaplicarcci(){
	    $info    = new Aplicarcci_model();						// **->

	    $data    = $info->grabaAplicar($_POST);

	    echo json_encode($data);

	}




}



