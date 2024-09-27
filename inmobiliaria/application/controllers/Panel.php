<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Panel extends CI_Controller {

	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->load->database();
		$this->load->helper('url');
		//$this->load->library('grocery_CRUD');    
		$this->load->model('usuarios_model', 'usuario');
		$this->load->helper('cookie');
	}
	
	public function index(){
		/*
		$crud = new grocery_CRUD();
		
		 //$crud->set_theme('twitter-bootstrap');
		$crud->set_language('spanish');
		$crud->set_subject('Cliente');
		
		$crud->set_table('clientes');
		$crud->columns('nombre','apellido','ciudad','dirección');
 
		$output = $crud->render();
		*/
		
		
		//$this->session->set_userdata('id_proyecto_activo', 3); // prueba de session para seleccion de proyecto
		$this->load->view('escritorio',$output );
	}
}