<?php

/*

// **->  indica linea a modificar en cada crud

*/

defined('BASEPATH') OR exit('No direct script access allowed');

class Presupuestos extends CI_Controller {								// **->

	///////////////////////////////////////////////////////////////////////////////////////////////
	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->config->load('crud_presupuestos');						// **->
		$this->load->model($this->config->item('modelo'));
		$this->load->database();
		$this->load->helper('url');
		$this->load->helper('funciones_helper');
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function index(){
	    $this->session->set_userdata( array('opMenu'   => isset($_GET['op']) ? $_GET['op'] : 0 ));
	    $this->session->set_userdata( array('laEntiCC' => -2));
	    $datos['campos']    = $this->config->item('camposGrilla');
	    $datos['elurl']     = $this->config->item('urlGrid');
	    $datos['urldel']    = $this->config->item('urlDel');
	    $datos['urlform']   = $this->config->item('urlForm');
	    $datos['entidades'] = dameEntiXTipo( $this->config->item('tipos_enti_provee'),0 ,1);
	    $datos['fHasta']    = date('Y-m-d');
	    $datos['fDesde']    = date('Y-m-d', strtotime('-365 day',strtotime($datos['fHasta'])));
	    $this->load->view($this->config->item('vista'),$datos );
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	// para q llame a esta funcion desde el url, primero indicar el controlador y despues la
	// funcion generica para usar con bootstrap-table, solo se debe indicar el nombre del modelo y la funcion 
	// dentro del modelo q se debe llamar 
	public function recuperaPagina(){
	    $offset =  isset($_GET['offset']) ? $_GET['offset'] : 0;
	    $limit  =  isset($_GET['limit'])  ? $_GET['limit']  : 10;
	    $order  =  isset($_GET['order'])  ? $_GET['order']  : ' ASC ';
	    $sort   =  isset($_GET['sort'])   ? $_GET['sort']   : ' 1 ';
	    $search =  isset($_GET['search']) ? $_GET['search'] : '';

	    $idEnti =  isset($_GET['idEnti']) ? $_GET['idEnti'] : -1;
	    $fHasta =  isset($_GET['fHasta']) ? $_GET['fHasta'] : date('Y-m-d');
	    $fDesde =  isset($_GET['fDesde']) ? $_GET['fDesde'] : date('Y-m-d', strtotime('-365 day',strtotime($datos['fHasta'])));

	    if ($idEnti == -1 && $this->session->userdata('laEntiCC')>=0){ //para volver a filtrar por la entidad si se ha registrado un mov.
		$idEnti = $this->session->userdata('laEntiCC');
	    }


	    //hasta q no se encuentre la forma de parametrizar lo q sigue, en cada crud se 
	    //debe colocar el nombre de la clase correspondiente
	    $enti    = new Presupuestos_model();							// **->
	    $data    = $enti->devuelveGrilla($offset,$limit,$sort,$order,$search,$this->config->item('searchGrilla'),$idEnti,$fDesde,$fHasta);	// **->

	    $this->session->set_userdata( array('laEntiCC' => $idEnti));

	    $retorno = array("total"            => $data[1],   //count($data),
			     "totalNotFiltered" => $data[1],   //count($data),
			     "rows"             => $data[0]);
	    echo json_encode($retorno);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function recuperaUnRegistro(){
	    $elId  = isset($_GET['id']) ? $_GET['id'] : 0;
//	    if ($elId > 0){
		$enti    = new Presupuestos_model();						// **->
		$data    = $enti->devuelveUnRegistro($elId);
//	    }
	    $data[idinv] = $_GET['frm_entidad_id'];

wh_log("recupera reg");
wh_log(json_encode($data));

	    echo json_encode($data);
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	public function cargaFormulario(){
		$elId  = isset($_GET['id']) ? $_GET['id'] : 0;
		$data  = '';
		if ($elId > 0){
		    $enti  = new Presupuestos_model();							// **->
		    $data  = $enti->devuelveUnRegistro($elId);
		    $data  = $data[0];
		    $data['frm_entidad_id'] = $data['entidad_id'];
		}else{
		    $data->frm_entidad_id = $_GET['frm_entidad_id'];
			$data->monedas        = dameMonedas();
		}
		$vista = $_GET['name'];

wh_log("get controlador");
wh_log(json_encode($_GET));
wh_log("data controlador");
wh_log(json_encode($data));
		$this->load->view($vista,$data);
	}

	//////////////////////////////////////////////////////////////////////////////////////////
	public function eliminaRegistro(){
		$elId  = isset($_GET['id']) ? $_GET['id'] : 0;
		$data='';
		// Si hay un id es porque estoy en una edicion
		if ($elId > 0){
			$enti  = new Presupuestos_model();						// **->
			$data  = $enti->eliminaUnRegistro($elId);
			$data  = $data[0];
		}
		redirect( $this->config->item('nombreCrud').'/index');
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function guardaRegistro(){
		$data = $_POST;

wh_log("data guardar controlador");
wh_log(json_encode($_POST));

		$enti = new Presupuestos_model();							// **->
		$enti->guardaUnRegistro($data);
		// en la vide real debe regornar un json con al menos dos parametros:
		//
		//	estado: 1 Significa que todo salio bien. 0 Significa que aparecio un error
		//	mensaje: Texto con mensaje para el usuario, tanto si todo salio bien como si hubo una falla.
		//
	}

}