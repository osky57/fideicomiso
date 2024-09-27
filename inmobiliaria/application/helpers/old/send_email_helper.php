<?php if (!defined('BASEPATH'))
    exit('No direct script access allowed');

if (!function_exists('send_email'))
{
	
	function send_email($to,$subject,$template,$data,$attach=false){
		
		$ci = &get_instance();
		
		$ci->load->library('email');

		$config['mailtype'] = 'html';
		$ci->email->initialize($config);

		$ci->email->from('no-reply@leblaboratorio.com.ar', 'LEB Laboratorio');
		$ci->email->to($to);		
		$ci->email->subject($subject);
		
		$message = $ci->load->view('email/'.$template, $data, TRUE);
		
		$ci->email->message($message);
		
		if ($attach){
			$ci->email->attach($attach);
		}
		
		 
		return $ci->email->send();
		
		
	}
	
}
?>