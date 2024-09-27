<?php


defined('BASEPATH') OR exit('No direct script access allowed');

class Vistas extends CI_Controller {

	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		
	}
		
	public function index(){
		
		$vista=$_GET['name'];
		
		 $this->load->view($vista);
	}
}