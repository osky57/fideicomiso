<?php

/*

// **->  indica linea a modificar en cada crud

*/

defined('BASEPATH') OR exit('No direct script access allowed');

class InformesProy extends CI_Controller {								// **->

	///////////////////////////////////////////////////////////////////////////////////////////////
	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->config->load('nocrud_informes_proy');						// **->
		$this->load->model($this->config->item('modelo'));
		$this->load->database();
		$this->load->helper('url');
		$this->load->helper('funciones_helper');
//		$this->load->helper('form');
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function index(){

	    $this->session->set_userdata( array('opMenu'   => isset($_GET['op']) ? $_GET['op'] : 0 ));

	    $idProyecto            = $this->session->id_proyecto_activo;
	    $datos['urlxInfoProy'] = $this->config->item('urlInfoProy');
	    $datos['elurl']        = $this->config->item('urlGrid');
//	    $datos['entidades']    = dameEntiProye($idProyecto,null,1);
	    $datos['fHasta']       = date('Y-m-d');
	    $datos['fDesde']       = date('Y-m-d', strtotime('-365 day',strtotime($datos['fHasta']))); //$this->session->inicio_proyecto_activo; 
	    $datos['urlinfocomp']  = $this->config->item('urlInfoComp');
	    $this->load->view('informesproy',$datos);
	}

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function informeproy(){

	    $idProyecto = $this->session->id_proyecto_activo;
	    $info       = new Informeproy_model();						// **->
	    $data       = $info->devuelveInforme($_GET);
	    array_push($data,dameProyecto($idProyecto));
	    array_push($data,$_GET['opcion']);
	    echo json_encode($data);

	}


	///////////////////////////////////////////////////////////////////////////////////////////////
	public function infoComp(){
		$compId  = isset($_GET['idcomp'])    ? $_GET['idcomp']    : 0;
		$enti    = new Informeproy_model();						// **->
		$retorno = $enti->infoComp($compId);
		echo json_encode($retorno);
	}





}



