<?php

/*

// **->  indica linea a modificar en cada crud

*/

defined('BASEPATH') OR exit('No direct script access allowed');

class AplicarCCPR extends CI_Controller {								// **->

	///////////////////////////////////////////////////////////////////////////////////////////////
	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->config->load('nocrud_aplicar_ccpr');						// **->
		$this->load->model($this->config->item('modelo'));
		$this->load->database();
		$this->load->helper('url');
		$this->load->helper('funciones_helper');
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function index(){

	    $this->session->set_userdata( array('opMenu'   => isset($_GET['op']) ? $_GET['op'] : 0 ));

	    $idProyecto                = $this->session->id_proyecto_activo;
	    $datos['urlxApliCCPR']     = $this->config->item('urlApliCCPR');
	    $datos['urlxGraApliCCPR']  = $this->config->item('urlGrabaApliCCPR');
	    $datos['urlxValiApliCCPR'] = $this->config->item('urlValiApliCCPR');

	    $datos['elurl']     = $this->config->item('urlGrid');
	    $datos['entidades'] = dameEntiXTipo( $this->config->item('tipos_enti_presta'),0,0);
	    $datos['fHasta']    = date('Y-m-d');
	    $datos['fDesde']    = date('Y-m-d', strtotime('-365 day',strtotime($datos['fHasta'])));
	    $vacioTP            = array( "e_id" => "0","e_razon_social" => "Todos los movimientos del proyecto","tipoentidad" => "","selectado" => " ");
	    array_unshift($datos['entidades'], $vacioTP);

	    $this->load->view('aplicarccpr',$datos);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	// para q llame a esta funcion desde el url, primero indicar el controlador y despues la funcion
	// funcion generica para usar con bootstrap-table, solo se debe indicar el nombre del modelo y la funcion 
	// dentro del modelo q se debe llamar 
	public function aplicarcc(){
	    $info    = new Aplicarccpr_model();						// **->
	    $data    = $info->devuelveAplicar($_POST);
	    echo json_encode($data);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function grabaaplicarcc(){

wh_log("graba aplicar");
wh_log(json_encode($_POST));


	    $info    = new Aplicarccpr_model();						// **->
	    $data    = $info->grabaAplicar($_POST);
	    echo json_encode($data);

	}


	///////////////////////////////////////////////////////////////////////////////////////////////
	public function valiaplicc(){
	    $data  = $_GET;
	    $idTr1 = explode("_",$data['tr1']);
	    $idTr2 = explode("_",$data['tr2']);
	    $lRet  = validaApliOP($idTr1[2], $idTr2[2]);

wh_log($idTr1[2]);
wh_log($idTr2[2]);

	    echo json_encode($lRet);

	}

}
