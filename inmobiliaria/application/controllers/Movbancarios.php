<?php

/*

// **->  indica linea a modificar en cada crud

*/

defined('BASEPATH') OR exit('No direct script access allowed');

class Movbancarios extends CI_Controller {								// **->

	///////////////////////////////////////////////////////////////////////////////////////////////
	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->config->load('crud_movbancarios');						// **->
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
	    $datos['urldel']       = $this->config->item('urlDel');
	    $datos['urlform']      = $this->config->item('urlForm');
	    $datos['cuentasbanc']  = dameCtasBancarias( $idProyecto, '', 1 );
	    $datos['titulo']       = 'Movimientos Bancarios';
	    $datos['urlrecupag']   = $this->config->item('urlRecuPag');
	    $datos['urlinfocomp']  = $this->config->item('urlInfoComp');
	    $datos['urlactuconci'] = $this->config->item('urlActuConci');
	    $datos['fHasta']       = date('Y-m-d');
	    $datos['fDesde']       = date('Y-m-d', strtotime('-365 day',strtotime($datos['fHasta'])));  //$this->session->inicio_proyecto_activo; 

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
	    $idEnti =  isset($_GET['idEnti']) ? $_GET['idEnti'] : -1;
	    $fDesde =  isset($_GET['fDesde']) ? $_GET['fDesde'] :$this->session->inicio_proyecto_activo;
	    $fHasta =  isset($_GET['fHasta']) ? $_GET['fHasta'] : date('Y-m-d');

	    if ($idEnti == -1 && $this->session->userdata('laEntiCC')>=0){ //para volver a filtrar por la entidad si se ha registrado un mov.
		$idEnti = $this->session->userdata('laEntiCC');
	    }

	    //hasta q no se encuentre la forma de parametrizar lo q sigue, en cada crud se 
	    //debe colocar el nombre de la clase correspondiente
	    $enti    = new Movbancarios_model();							// **->
	    $data    = $enti->devuelveGrilla($offset,$limit,$sort,$order,$search,$this->config->item('searchGrilla'),$idEnti,$fDesde,$fHasta);

	    $this->session->set_userdata( array('laEntiCC' => $idEnti));

	    $retorno = array("total"            => $data[1],   //count($data),
			     "totalNotFiltered" => $data[1],   //count($data),
			     "rows"             => $data[0]);
	    echo json_encode($retorno);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function recuperaUnRegistro(){
	    $elId  = isset($_GET['id']) ? $_GET['id'] : 0;
	    $data  = '';
	    if ($elId > 0){
		//hasta q no se encuentre la forma de parametrizar lo q sigue, en cada crud se 
		//debe colocar el nombre de la clase correspondiente
		$enti  = new Movbancarios_model();							// **->
		$data  = $enti->devuelveUnRegistro($elId);
	    }
	    echo json_encode($data);
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	public function cargaFormulario(){
	    $lEdita = 1;
	    if (isset($_GET['ii'])){
		$lEdita = ( $_GET['ii']+0 == 0 ) ? 0 : 1;
	    }
	    if ($lEdita == 1){
		$elId  = isset($_GET['id']) ? $_GET['id'] : 0;
		$data  = '';
		$enti  = new Movbancarios_model();							// **->
		$data  = $enti->devuelveUnRegistro($elId);
		$data  = $data[0];
		$vista = $_GET['name'];
		$data['urlxChqCart']        = $this->config->item('urlRecuChqCart');
		$data['urlxChequeras']      = $this->config->item('urlRecuChequeras');
		$data['idInv']              = isset($_GET['idinv']) ? $_GET['idinv']   : 0;
		$data['idFormu']            = isset($_GET['idFormu']) ? $_GET['idFormu'] : 0;
		$data['idEnti']             = isset($_GET['identi']) ? $_GET['identi'] : 0;  // cod cta banco
		$this->load->view($vista,$data);
	    }
	}

	//////////////////////////////////////////////////////////////////////////////////////////
	public function eliminaRegistro(){
		$elId   = isset($_GET['id'])   ? $_GET['id']   : 0;
		$data   = '';
		// Si hay un id es porque estoy en una edicion
		if ($elId > 0){
			$enti  = new Movbancarios_model();							// **->
			$data  = $enti->eliminaUnRegistro($elId);
			$data  = $data[0];
		}
		redirect( $this->config->item('nombreCrud').'/index');
	}

	//////////////////////////////////////////////////////////////////////////////////////////
	public function filtraEntidad(){
		$elId   = isset($_GET['id'])   ? $_GET['id']   : 0;
		$data   = '';
		if ($elId > 0){
			$enti  = new Movbancarios_model();							// **->
			//$data  = $enti->eliminaUnRegistro($elId);
			//$data  = $data[0];
		}
		redirect( $this->config->item('nombreCrud').'/index');
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function guardaRegistro(){
		$data = $_POST;
		$enti = new Movbancarios_model();							// **->
		$enti->guardaUnRegistro($data);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function actuConci(){
		$idReg    = isset($_GET['idcomp'])    ? $_GET['idcomp']      : null;
		$fecConci = isset($_GET['fechaconci'])? $_GET['fechaconci']  : null;
		$enti     = new Movbancarios_model();							// **->
		$retorno  = $enti->actuConci($idReg,$fecConci);
		echo json_encode($retorno);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function recuChqCart(){
		$eChq    = isset($_GET['echq'])    ? $_GET['echq']    : null;
		$enti    = new Movbancarios_model();							// **->
		$retorno = $enti->recuChqsCartera($eChq);
		echo json_encode($retorno);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function recuChequeras(){
		$eChq    = isset($_GET['echq'])    ? $_GET['echq']    : 0;
		$eChq    = ($eChq == 0) ? 'N' : 'S';
		$enti    = new Movbancarios_model();							// **->
		$retorno = $enti->recuChequeras($eChq);
		echo json_encode($retorno);
	}


	///////////////////////////////////////////////////////////////////////////////////////////////
	public function infoComp(){
		$compId  = isset($_GET['idcomp']) ? $_GET['idcomp']    : 0;
		$enti    = new Movbancarios_model();							// **->
		$retorno = $enti->infoComp($compId);
		echo json_encode($retorno);
	}

}