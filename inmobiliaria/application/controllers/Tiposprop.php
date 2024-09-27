<?php

/*

// **->  indica linea a modificar en cada crud

*/

defined('BASEPATH') OR exit('No direct script access allowed');

class Tiposprop extends CI_Controller {								// **->

	///////////////////////////////////////////////////////////////////////////////////////////////
	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->config->load('crud_tiposprop');						// **->
		$this->load->model($this->config->item('modelo'));
		$this->load->database();
		$this->load->helper('url');
		$this->load->helper('funciones_helper');
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function index(){

	    $this->session->set_userdata( array('opMenu'   => isset($_GET['op']) ? $_GET['op'] : 0 ));

	    $datos['campos']  = $this->config->item('camposGrilla');
	    $datos['elurl']   = $this->config->item('urlGrid');
	    $datos['urldel']  = $this->config->item('urlDel');
	    $datos['urlform'] = $this->config->item('urlForm');
	    $this->load->view($this->config->item('vista'),$datos );
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	// para q llame a esta funcion desde el url, primero indicar el controlador y despues la funcion
	// funcion generica para usar con bootstrap-table, solo se debe indicar el nombre del modelo y la funcion 
	// dentro del modelo q se debe llamar 
	public function recuperaPagina(){
	    $offset =  isset($_GET['offset']) ? $_GET['offset'] : 0;
	    $limit  =  isset($_GET['limit'])  ? $_GET['limit']  : 10;
	    $order  =  isset($_GET['order'])  ? $_GET['order']  : ' ASC ';
	    $sort   =  isset($_GET['sort'])   ? $_GET['sort']   : ' 1 ';
	    $search =  isset($_GET['search']) ? $_GET['search'] : '';

	    //hasta q no se encuentre la forma de parametrizar lo q sigue, en cada crud se 
	    //debe colocar el nombre de la clase correspondiente
	    $enti    = new Tiposprop_model();							// **->
	    $data    = $enti->devuelveGrilla($offset,$limit,$sort,$order,$search,$this->config->item('searchGrilla'));

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
		$enti    = new Tiposprop_model();						// **->
		$data    = $enti->devuelveUnRegistro($elId);

	    }
	    echo json_encode($data);
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	public function cargaFormulario(){
		$elId  = isset($_GET['id']) ? $_GET['id'] : 0;
		$data  = '';
		$enti  = new Tiposprop_model();						// **->
		$data  = $enti->devuelveUnRegistro($elId);
		$data  = $data[0];
		$vista = $_GET['name'];
		$this->load->view($vista,$data);
	}

	//////////////////////////////////////////////////////////////////////////////////////////
	public function eliminaRegistro(){
		$elId  = isset($_GET['id']) ? $_GET['id'] : 0;

		$data='';
		// Si hay un id es porque estoy en una edicion
		if ($elId > 0){

			$enti  = new Tiposprop_model();						// **->
			$data  = $enti->eliminaUnRegistro($elId);
			$data  = $data[0];

		}

		redirect( $this->config->item('nombreCrud').'/index');

	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function guardaRegistro(){
		$data = $_POST;
		$enti = new Tiposprop_model();						// **->
		$enti->guardaUnRegistro($data);

		// en la vide real debe regornar un json con al menos dos parametros:
		//
		//	estado: 1 Significa que todo salio bien. 0 Significa que aparecio un error
		//	mensaje: Texto con mensaje para el usuario, tanto si todo salio bien como si hubo una falla.
		//
	}

}