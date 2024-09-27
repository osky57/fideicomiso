<?php

/*

// **->  indica linea a modificar en cada crud

*/

defined('BASEPATH') OR exit('No direct script access allowed');

class InformesCC extends CI_Controller {								// **->

	///////////////////////////////////////////////////////////////////////////////////////////////
	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->config->load('nocrud_informes_cc');						// **->
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
	    $datos['urlxInfoCC']= $this->config->item('urlInfoCC');
	    $datos['elurl']     = $this->config->item('urlGrid');
	    $datos['entidades'] = dameEntiProye($idProyecto,null,1);   // $this->config->item('tipos_enti_filtro'),1);
	    $datos['fHasta']    = date('Y-m-d');
	    $datos['fDesde']    = date('Y-m-d', strtotime('-365 day',strtotime($datos['fHasta'])));  //$this->session->inicio_proyecto_activo; //
//	    $vacioTP            = array( "e_id" => "0","e_razon_social" => "Todos los movimientos del proyecto","tipoentidad" => "","selectado" => " ");
//	    array_unshift($datos['entidades'], $vacioTP);

	    $this->load->view('informescc',$datos);
	}

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////
	public function informecc(){

	    $idProyecto = $this->session->id_proyecto_activo;
	    $info       = new Informecc_model();						// **->
//	    $data       = $info->devuelveInforme($_GET);

	    $data       = $info->devuelveInformeComp($_GET);

	    if ($idProyecto > 0){
		array_push($data,dameProyecto($idProyecto));
	    }


	    echo json_encode($data);

	}


	///////////////////////////////////////////////////////////////////////////////////////////////
	public function infoComp(){
		$compId  = isset($_GET['idcomp'])    ? $_GET['idcomp']    : 0;
		$enti    = new Informecc_model();						// **->
		$retorno = $enti->infoComp($compId);
		echo json_encode($retorno);
	}



}



