<?php

/*

// **->  indica linea a modificar en cada crud

*/

defined('BASEPATH') OR exit('No direct script access allowed');

class Moventreproy extends CI_Controller {								// **->

	///////////////////////////////////////////////////////////////////////////////////////////////
	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->config->load('crud_moventreproy');						// **->
		$this->load->model($this->config->item('modelo'));
		$this->load->database();
		$this->load->helper('url');
		$this->load->helper('funciones_helper');
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function index(){

	    $this->session->set_userdata( array('opMenu'   => isset($_GET['op']) ? $_GET['op'] : 0 ));
	    $this->session->set_userdata( array('laEntiCC' => -2));
	    $idProyecto            = $this->session->id_proyecto_activo;
	    $datos['campos']       = $this->config->item('camposGrilla');
	    $datos['elurl']        = $this->config->item('urlGrid');
	    $datos['urlform']      = $this->config->item('urlForm');
	    $datos['titulo']       = 'Movimientos entre Proyectos';
	    $datos['urlrecupag']   = $this->config->item('urlRecuPag');
	    $datos['urlinfocomp']  = $this->config->item('urlInfoComp');
	    $datos['fHasta']       = date('Y-m-d');
	    $datos['fDesde']       = date('Y-m-d', strtotime('-365 day',strtotime($datos['fHasta'])));   //  $this->session->inicio_proyecto_activo;
	    $datos['idProyecto']   = $this->session->id_proyecto_activo;
	    $this->load->view($this->config->item('vista'),$datos );
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	// para q llame a esta funcion desde el url, primero indicar el controlador y despues la funcion
	// funcion generica para usar con bootstrap-table, solo se debe indicar el nombre del modelo y la funcion 
	// dentro del modelo q se debe llamar 
	public function recuperaPagina(){
	    $offset =  isset($_GET['offset']) ? $_GET['offset'] : 0;
	    $limit  =  isset($_GET['limit'])  ? $_GET['limit']  : 10;
	    $order  =  isset($_GET['order'])  ? $_GET['order']  : ' DESC ';
	    $sort   =  isset($_GET['sort'])   ? $_GET['sort']   : ' 1 ';
	    $search =  isset($_GET['search']) ? $_GET['search'] : '';
	    $fHasta =  isset($_GET['fHasta']) ? $_GET['fHasta'] : date('Y-m-d');
	    $fDesde =  isset($_GET['fDesde']) ? $_GET['fDesde'] : date('Y-m-d', strtotime('-365 day',strtotime($datos['fHasta'])));  //$this->session->inicio_proyecto_activo;

	    //hasta q no se encuentre la forma de parametrizar lo q sigue, en cada crud se 
	    //debe colocar el nombre de la clase correspondiente
	    $enti    = new Moventreproy_model();							// **->
	    $data    = $enti->devuelveGrilla($offset,$limit,$sort,$order,$search,$this->config->item('searchGrilla'),$fDesde,$fHasta);

	    $this->session->set_userdata( array('laEntiCC' => $idEnti));

	    $retorno = array("total"            => $data[1],   //count($data),
			     "totalNotFiltered" => $data[1],   //count($data),
			     "rows"             => $data[0]);
	    echo json_encode($retorno);
	}


	///////////////////////////////////////////////////////////////////////////////////////////////
	public function infoComp(){
		$compId  = isset($_GET['idcomp']) ? $_GET['idcomp']    : 0;
		$enti    = new Moventreproy_model();							// **->
		$retorno = $enti->infoComp($compId);
		echo json_encode($retorno);
	}

}