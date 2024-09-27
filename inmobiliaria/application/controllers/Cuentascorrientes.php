<?php

/*

// **->  indica linea a modificar en cada crud

*/


defined('BASEPATH') OR exit('No direct script access allowed');

class Cuentascorrientes extends CI_Controller {								// **->

	///////////////////////////////////////////////////////////////////////////////////////////////
	function __construct(){
		parent::__construct();
		if(!is_loged_in()){
		    redirect( base_url('/index.php/Usuario') , 'refresh');
		}
		$this->config->load('crud_cuentascorrientes');						// **->
		$this->load->model($this->config->item('modelo'));
		$this->load->database();
		$this->load->helper('url');
		$this->load->helper('funciones_helper');
		
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function index(){
	    if (isset($_GET['op'])){
		$this->session->set_userdata( array('opMenu'   => isset($_GET['op']) ? $_GET['op'] : 0 ));
		$this->session->set_userdata( array('primera'  => $_GET['op']));
	    }else{
		$this->session->set_userdata( array('opMenu'   => $this->session->primera));
	    }
	    $this->session->set_userdata( array('laEntiCC' => -2));
	    $idProyecto             = $this->session->id_proyecto_activo;
	    $datos['campos']        = $this->config->item('camposGrilla');
	    $datos['elurl']         = $this->config->item('urlGrid');
	    $datos['urldel']        = $this->config->item('urlDel');
	    $datos['urlpdf']        = $this->config->item('urlPdf');
	    $datos['urlform']       = $this->config->item('urlForm');
	    $datos['urlValiMedPag'] = $this->config->item('urlValiMedPag');

//hay q filtrar entidades q no sean proveedores cuando opcion menu = 46
	    if ($this->session->opMenu == 46){
		$datos['entidades']    = dameEntiXTipo( $this->config->item('tipos_enti_provee'),0 ,1);
		$datos['titulo']       = 'Proveedores';
		$datos['sistema']      = 'P';

	    }else if ($this->session->opMenu == 49){  //prestamistas
		$datos['entidades']    = dameEntiXTipo( $this->config->item('tipos_enti_presta'),0 ,1);
		$datos['titulo']       = 'Prestamistas';
		$datos['sistema']      = 'E';

	    }else{     //32 -> inversores
		$datos['entidades']    = dameEntiProye($idProyecto, null, 1);   // para ctasctes inver. no muestra proveed. $this->config->item('tipos_enti_filtro')  ,1);
		$datos['titulo']       = 'Inversores';
		$datos['sistema']      = 'I';
	    }

	    $datos['opemenu']      = $this->session->opMenu; //paso q tipo de entidades debe operar

	    $datos['urlrecupag']   = $this->config->item('urlRecuPag');
	    $datos['urlinfocomp']  = $this->config->item('urlInfoComp');
	    $datos['fHasta']       = date('Y-m-d');
	    $datos['fDesde']       = date('Y-m-d', strtotime('-365 day',strtotime($datos['fHasta'])));
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
	    $fHasta =  isset($_GET['fHasta']) ? $_GET['fHasta'] : date('Y-m-d');
	    $fDesde =  isset($_GET['fDesde']) ? $_GET['fDesde'] : date('Y-m-d', strtotime('-365 day',strtotime($datos['fHasta'])));;
	    if ($idEnti == -1 && $this->session->userdata('laEntiCC')>=0){ //para volver a filtrar por la entidad si se ha registrado un mov.
		$idEnti = $this->session->userdata('laEntiCC');
	    }

	    //hasta q no se encuentre la forma de parametrizar lo q sigue, en cada crud se 
	    //debe colocar el nombre de la clase correspondiente
	    $enti    = new Cuentascorrientes_model();							// **->
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
		$enti    = new Cuentascorrientes_model();						// **->
		$data    = $enti->devuelveUnRegistro($elId);
	    }
	    echo json_encode($data);
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	public function cargaFormulario(){

wh_log("control cargaformu " );
wh_log( $this->session->userdata('laEntiCC'));

	    $lEdita = 1;
	    if (isset($_GET['ii'])){
		$lEdita = ( $_GET['ii']+0 == 0 ) ? 0 : 1;
	    }
	    if ($lEdita == 1){
		$elId  = isset($_GET['id']) ? $_GET['id'] : 0;
		$data  = '';
		$enti  = new Cuentascorrientes_model();							// **->
		$data  = $enti->devuelveUnRegistro($elId,$this->session->userdata('laEntiCC'));
		$data  = $data[0];
		$vista = $_GET['name'];
		$data['urlxClie']           = $this->config->item('urlRecuClie');
		$data['urlxChqCart']        = $this->config->item('urlRecuChqCart');
		$data['urlxChqCartADepo']   = $this->config->item('urlRecuChqCartADepo');
		$data['urlxChequeras']      = $this->config->item('urlRecuChequeras');
		$data['urlxRecuPropieEnti'] = $this->config->item('urlRecuPropieEnti');
		$data['urlxUnaEnti']        = $this->config->item('urlRecuUnaEnti');
		$data['urlxSaldoEnti']      = $this->config->item('urlRecuSaldoEnti');
		$data['idInv']              = isset($_GET['idinv']) ? $_GET['idinv']   : 0;
		$data['idFormu']            = isset($_GET['idFormu']) ? $_GET['idFormu'] : 0;
		$data['urlrecudeuda']       = $this->config->item('urlRecuDeuda');
		$data['urlValiMedPag']      = $this->config->item('urlValiMedPag');
		$data['idProyecto']         = $this->session->id_proyecto_activo;
		$data['urlxValiComp']       = $this->config->item('urlValiComp');
		$data['opmenu']             = $this->session->opMenu;
		$this->load->view($vista,$data);
	    }
	}

	//////////////////////////////////////////////////////////////////////////////////////////
	public function eliminaRegistro(){
		$elId   = isset($_GET['id'])   ? $_GET['id']   : 0;
		$data   = '';
		// Si hay un id es porque estoy en una edicion
		if ($elId > 0){
			$enti  = new Cuentascorrientes_model();						// **->
			$data  = $enti->eliminaUnRegistro($elId);
			$data  = $data[0];
		}
		$this->session->set_userdata( array('primera'  => $this->session->opMenu));
		redirect( $this->config->item('nombreCrud').'/index');
	}

	//////////////////////////////////////////////////////////////////////////////////////////
	public function filtraEntidad(){
		$elId   = isset($_GET['id'])   ? $_GET['id']   : 0;
		$data   = '';
		if ($elId > 0){
			$enti  = new Cuentascorrientes_model();						// **->
			//$data  = $enti->eliminaUnRegistro($elId);
			//$data  = $data[0];
		}
		redirect( $this->config->item('nombreCrud').'/index');
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function guardaRegistro(){
		$data      = $_POST;
		$enti      = new Cuentascorrientes_model();							// **->
		$dataGraba = $enti->guardaUnRegistro($data);

		$elId      = $dataGraba['id'];
		$datoscomp = $enti->infoComp( $elId );    //dataGraba['id'] ,0);
		wh_log("guardaRegistro ");
		wh_log("datoscomp[modelo]");
		wh_log($datoscomp["modelo"]);
		wh_log(json_encode($data));
		
		//$dompdf = new Dompdf();	 
		//---------------------------ESTA CARGA DE VISTA SE CONVIERTE EN STRING GRACIAS AL TERCER PARÁMETRO---------------------------//
		$html=$this->load->view("comprobantes/ordendepago",$datoscomp, TRUE);
		//---------------------------ESTA CARGA DE VISTA SE CONVIERTE EN STRING GRACIAS AL TERCER PARÁMETRO---------------------------//
// 2024-03-19 comento la generacion pdf por ahora
		if (array_search($datoscomp['modelo'], array(0,4,5) ) ){  //4 recibo, 5 orden pago
		    $pathPdf   = $this->config->item('path_pdfs');
		    $nombrePdf = str_pad($datoscomp['comprob']['cc_id'],7,"0",STR_PAD_LEFT)."_".substr($datoscomp['comprob']['cc_fecha_registro'],0,10)."_".$datoscomp['comprob']['cc_entidad_id'];
		    $tipoComp  = $pathPdf . "op_" . $nombrePdf;
		    if ($datoscomp['modelo'] == 4){
			$tipoComp = $pathPdf. "re_" . $nombrePdf;
		    }
		    $tipoComp = $pathPdf . str_pad($datoscomp['comprob']['cc_id'],8,"0",STR_PAD_LEFT);
		    generate_pdf($html, $tipoComp, $datoscomp);
		}
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function recuCliexTipo(){
		$elId    = isset($_GET['id'])    ? $_GET['id']    : 0;
		$elTipo  = isset($_GET['tipo'])  ? $_GET['tipo']  : '';
		$laPropi = isset($_GET['propi']) ? $_GET['propi'] : 0;
		$enti    = new Cuentascorrientes_model();						// **->
		$retorno = $enti->recuCliexTipo($elId,$elTipo,$laPropi);
		echo json_encode($retorno);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function recuChqCart(){
		$eChq    = isset($_GET['echq'])    ? $_GET['echq']    : null;
		$enti    = new Cuentascorrientes_model();						// **->
		if ($_GET['adepo'] == 1){
		    $retorno = $enti->recuChqsCarteraADepo($eChq);
		}else{
		    $retorno = $enti->recuChqsCartera($eChq);
		}
wh_log("cartera.....");
wh_log( json_encode($retorno));
		echo json_encode($retorno);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function recuChequeras(){
		$eChq    = isset($_GET['echq'])    ? $_GET['echq']    : 0;
		$eChq    = ($eChq == 0) ? 'N' : 'S';
		$allCtas = isset($_GET['otrasctas'])? $_GET['otrasctas']:0;
		$enti    = new Cuentascorrientes_model();						// **->
		$retorno = $enti->recuChequeras($eChq,$allCtas);
		echo json_encode($retorno);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function recuPropieEnti(){
		$entiId  = isset($_GET['enti'])    ? $_GET['enti']    : 0;
		$enti    = new Cuentascorrientes_model();						// **->
		$retorno = $enti->recuProyPropieEnti($entiId);
		echo json_encode($retorno);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function recuUnaEntidad(){
		$entiId  = isset($_GET['identi'])    ? $_GET['identi']    : 0;
		$enti    = dameEntidad($entiId);							// **->
		echo json_encode($enti);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function recuDeuda(){
		$entiId     = isset($_GET['identi'])    ? $_GET['identi']     : 0;
		$modeloComp = '(1,2)';
		if (isset($_GET['modelocomp'])){
		    $modeloComp = ( $_GET['modelocomp'] == 5 || $_GET['modelocomp']==3) ? '(1,2)': '(2)';  //si modelocomp = 5 (o/p) pasa 1,2 para recuperar fac/deb provee, sino es reci pasa 2 para traer deb inversor

		    if ($this->session->opMenu == 49){   //prestamista
			$modeloComp =  $_GET['modelocomp'] == 5 ? '(4)': '';  //si modelocomp = 5 (o/p) pasa 4 para traer recibos de prestamista
		    }

		}
		$enti       = new Cuentascorrientes_model();						// **->
		$retorno    = $enti->RecuCompAdeu($entiId,$modeloComp);



wh_log("entiId " . $entiId);
wh_log("modeloComp " . $modeloComp);
wh_log(json_encode($retorno));


		echo json_encode($retorno);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function recuProy(){
		$idProyecto = $this->session->id_proyecto_activo;
		$retorno    = dameProy( $idProyecto,1);  //trae los proyectos menos el activo
		echo json_encode($retorno);
	}

	//////////////////////////////////////////////////////////////////////////////////////////
	public function cargaGenCuo(){
		$data  = '';
		$data  = $data[0];
		$vista = $_GET['name'];
		$enti  = new Cuentascorrientes_model();							// **->
		$data  = $enti->cargaGenCuo();
		$data['urlxClie']           = $this->config->item('urlRecuClie');
		$data['urlxRecuPropieEnti'] = $this->config->item('urlRecuPropieEnti');
		$this->load->view($vista,$data);
	}

	//////////////////////////////////////////////////////////////////////////////////////////
	public function guardaGenCuo(){
		$data = $_POST;
		$enti = new Cuentascorrientes_model();							// **->
		$enti->guardaGenCuo($data);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function infoComp(){
		$compId  = isset($_GET['idcomp'])    ? $_GET['idcomp']    : 0;
		$enti    = new Cuentascorrientes_model();						// **->
		$retorno = $enti->infoComp($compId);
		echo json_encode($retorno);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function recuSaldoEntidad(){
		$idEnti      = isset($_GET['identi'])    ? $_GET['identi']    : 0;
		$tipoInvProv = isset($_GET['invprov'])   ? $_GET['invprov']   : 0;
		$hastaFecha  = isset($_GET['fecha'])     ? $_GET['fecha']     : '';
		$enti        = new Cuentascorrientes_model();						// **->
		$retorno     = $enti->saldoEnti($idEnti,$tipoInvProv,$hastaFecha);
		echo json_encode($retorno);
	}

	///////////////////////////////////////////////////////////////////////////////////////////////
	public function valiMedPag(){

	    wh_log("vali med pag");
	    wh_log($_POST["mediopago"]);

	    echo json_encode(array(111,222));


	}





	///////////////////////////////////////////////////////////////////////////////////////////////
	public function valiComp(){

	    $data    = $_GET;
	    $valida  = new Cuentascorrientes_model();							// **->
	    $retorno = $valida->validarComprob($data);
	    echo json_encode($retorno);

	}










}
