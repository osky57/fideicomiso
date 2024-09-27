<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Usuario extends CI_Controller {

	function __construct(){
		parent::__construct();  
		$this->load->model('usuarios_model', 'usuario');
		$this->load->helper('cookie');
	}

	public function index(){
	    if(is_loged_in()){
		redirect( base_url('/index.php/Panel') , 'refresh');
	    }else{
		$this->load->view('login');
	    }
	}
	
	public function entrar(){
	    $this->load->library('form_validation');
	    $this->form_validation->set_error_delimiters('', '');
	    $this->form_validation->set_rules('email', 'Cuenta de correo electrónico','trim|required',
		array(
			'required' => 'Debe completar con su cuenta de correo electrónico'					
		)
	    );
	    $this->form_validation->set_rules('password', 'Contraseña','trim|required',
		array(
			'required' => 'Debe completar el campo contraseña'
		)
	    );

	    $email=$this->security->xss_clean($this->input->post('email'));	
	    $password=$this->security->xss_clean($this->input->post('password'));	

	    //para usar en filtrado de cta cte por entidad cuando se registra un nuevo mov.
	    $this->session->set_userdata( array('laEntiCC' => -2));


	    if ($this->form_validation->run() == false){
		$data['entrar_error'] = validation_errors();
		$this->load->view('login',$data);
	    }else{	
		$result = $this->usuario->login($email,$password);
		if (!$result){
			$data['entrar_error'] = "Error en usuario o contraseña.";
			$this->load->view('login',$data);
		}else{
			$result=$result[0];
			$sess_array = array('id' => $result->id, 'nombre' => $result->nombre, 'nivel' => $result->nivel);
			$this->session->set_userdata('logged_in', $sess_array);
			 // Remember Me activado?
			$rememberme = $this->input->post('rememberme');
			if ($rememberme == 1){
				$password_hash = md5($password); // will result in a 32 characters hash
				setcookie ('rememberme', 'dni='.$dni.'&hash='.$password_hash, 2147483647,'/');
			}
			redirect( base_url('/index.php/Panel') , 'refresh');
		}
	    }
	}

	public function salir(){

		$this->session->unset_userdata('logged_in');
		unset($_COOKIE['rememberme']);
		setcookie ('rememberme', '', time()-3600,'/');
		redirect( base_url('/index.php') , 'refresh');
	}
}