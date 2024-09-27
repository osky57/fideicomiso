<?php if (!defined('BASEPATH'))
    exit('No direct script access allowed');

if (!function_exists('is_loged_in')){
    function is_loged_in(){
        $ci = &get_instance();
        if ($ci->session->userdata('logged_in')){
	    // La session ya estaba iniciada
	    return true;
	} else {
	    // La session no esta iniciada, Existe la cookie de rememberme?
	    if(isSet($_COOKIE['rememberme'])){
		parse_str($_COOKIE['rememberme']);
		// verifico integridad basica de la cookie
		if (isset($usr) && isset($hash)){
			$ci -> db -> select('id, nombre,usuario, password, nivel');
			$ci -> db -> from('usuarios');
			$ci -> db -> where('usuario = ' . "'" . $usr . "'"); 
			$ci -> db -> where('password = ' . "'" . $hash . "'"); 
			$ci -> db -> limit(1);
			$query = $ci -> db -> get();
			// verifico la existencia del usuario y la contraseña
			if($query -> num_rows() == 1){
				$result=$query->result();
				// armo la session de login
				foreach ($result as $row){
				    $sess_array = array('id'       => $row->id, 
							'username' => $row->username,
							'nivel'    => $row->nivel);
				    $ci->session->set_userdata('logged_in', $sess_array);
				}
				return true;
			}else{
				return false;
			}
		}else{
			// cookie mal formada
			return false;
		}
	    }
	    return false;
        }
    }
}
//filtra las opciones de menu si esta activo un proyecto y de acuerdo al nivel del usuario
function mmenu($kmenu){
	$ci = &get_instance();
	//$kmenu=$kmenu + ' ';
	// no hay proyecto seleccionado
	if(!is_numeric($ci->session->userdata('id_proyecto_activo'))){
		$menu = $ci->config->item('menu_permisos');
		if (strpos($menu,$kmenu)!==false){
			echo 'd-none';
		}
	}
	if ($ci->session->logged_in['nivel'] < 1){
	    $menuNoAdmin = $ci->config->item('menu_no_admin');
	    if (strpos($menuNoAdmin,$kmenu)==false){
		echo 'd-none';
	    }
	}
}

/* esta funcion retorna el id del usuario que esta logueado en el sistema*/
function user_id(){
	$ci = &get_instance();
	$a=$ci->session->userdata('logged_in');
	if (is_array($a)){
		return $a['id'];
	 }
}

