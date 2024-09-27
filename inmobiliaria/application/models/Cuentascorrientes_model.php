<?php
require(APPPATH.'third_party/dompdf/autoload.inc.php');
use Dompdf\Dompdf;
use Dompdf\Options;

class Cuentascorrientes_model extends CI_Model {						// **->
	//2024-02-28 instancia de controlador protegida
	protected $CI;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('crud_cuentascorrientes');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveGrilla($offset,$limit,$sort='',$order='',$search='',$elLike,$idEnti=0,$fDesde,$fHasta){

	$idProyecto = $this->session->id_proyecto_activo;

	$ordenar = '';
	if ($sort != '' && $order != ''){
	    $ordenar = " ORDER BY ccc_fecha_registro ";   //$sort $order ";
	}
	$where = $this->session->opMenu > 0 ? " " : " AND cc_proyecto_id = $idProyecto ";

	//2023-01-31 prueba de separar inversores de proveedores y prestamistas
	//2023-06-07 el filtrado para la separacion se hace con los tipos de entidades sobre los tipos de comprobantes
	$filtTipoEnti = 1;
	if ($this->session->opMenu == 46){ //recupera proveedores solamente
	    $filtTipoEnti = 2;
	}else if ($this->session->opMenu == 49){
	    $filtTipoEnti = 3;
	}else{
	    $where .= " AND cc_proyecto_id = $idProyecto ";  //??
	}
	$where .= " AND POSITION('".$filtTipoEnti."' IN fun_dametiposentidades(cc_tipo_comprobante_id, 'X') ) > 0 ";   //muestra mov.cliente

/*
	if ($this->session->opMenu == 46){ //recupera proveedores solamente
	    $where = " AND POSITION('2' in fun_dametiposentidades(cc_tipo_comprobante_id, 'X') ) > 0 ";   //muestra mov.cliente
	}else if ($this->session->opMenu == 49){ //recupera prestamistas solamente
	    $where = " AND POSITION('3' in fun_dametiposentidades(cc_tipo_comprobante_id, 'X') ) > 0 ";   //muestra mov.cliente
	}else{
	    $where .= " AND cc_proyecto_id = $idProyecto ";  //??
	}
*/
	if ($idEnti > 0){
	    $where .= " AND cc_entidad_id = $idEnti ";
	}
	if ($search != '' ){
	    $search = strtoupper($search);
	    //hay q concatenar los campos q se usan para el where id + razon_social + direccion + celular etc
	    $where .= " AND UPPER(CONCAT(".$this->config->item('searchGrilla').")) LIKE '%$search%' ";
	}
	$sqlCount  = "SELECT COUNT(*) AS cant_reg FROM ".$this->config->item('nombreVista')." WHERE  1=1 $where ";
//	$sqlPagina = "SELECT * FROM ".$this->config->item('nombreVista')." WHERE $where $ordenar "; //LIMIT $limit OFFSET $offset";
//			    current_date - interval '1 year'               AS cc_fecha,
//			    (current_date - interval '1 year')::date      AS cc_fecha,

	$sqlPagina = "SELECT null              AS cc_id,
			    ('$fDesde'::date - interval '1 day')::date AS cc_fecha,
			    '<b>Saldo anterior </b>'  AS comp_nume,
			    null               AS debe_txt_mn_tot,
			    null               AS haber_txt_mn_tot,
			    SUM(tc_signo * fun_calcimportecaja(cc_id, 1)) AS saldo_mn,
			    null               AS debe_txt_div_tot,
			    null               AS haber_txt_div_tot,
			    SUM(tc_signo * fun_calcimportecaja(cc_id, 2)) AS saldo_div,
			    null               AS cc_comentario,
			    null               AS cc_entidad_id,
			    null               AS e_razon_social,
			    null               AS tp_descripcion,
			    null               AS lo_id,
			    0                  AS debe_mn_tot,
			    0                  AS haber_mn_tot,
			    0                  AS debe_div_tot,
			    0                  AS haber_div_tot,
			    -1                 AS tiene_apli,
			    null               AS p_nombre,
			    null               AS tc_modelo
		    FROM vi_ctas_ctes
		    WHERE cc_fecha_registro::date < '$fDesde' $where
		    UNION
		    SELECT  cc_id,
			    cc_fecha ,
			    comp_nume,
			    debe_txt_mn_tot,
			    haber_txt_mn_tot,
			    0 AS saldo_mn,
			    debe_txt_div_tot,
			    haber_txt_div_tot,
			    0 AS saldo_div,
			    ccc_comentario AS cc_comentario,
			    cc_entidad_id,
			    e_razon_social,
			    tp_descripcion,
			    null AS lo_id,
			    debe_mn_tot,
			    haber_mn_tot,
			    debe_div_tot,
			    haber_div_tot,
			    tiene_apli,
			    po_nombre AS p_nombre,
			    tc_modelo
		    FROM vi_ctas_ctes
		    WHERE cc_fecha_registro::date BETWEEN '$fDesde' AND '$fHasta' $where
		    ORDER BY cc_fecha,cc_id";

wh_log("sqlPagina");
wh_log($sqlPagina);

	$query      = $this->db->query($sqlCount);
	$cantReg    = $query->result();
	$query      = $this->db->query($sqlPagina);
	$aArray     = $query->result();
	$saldoPesos = $aArray[0]->saldo_mn;
	$saldoDolar = $aArray[0]->saldo_div;
	for($i = 0; $i < count($aArray); $i++){
	    $saldoPesos += $aArray[$i]->debe_mn_tot  - $aArray[$i]->haber_mn_tot;
	    $saldoDolar += $aArray[$i]->debe_div_tot - $aArray[$i]->haber_div_tot;
	    $aArray[$i]->saldo_mn       = "<b>".number_format($saldoPesos,2,',','.')."</b>";
	    $aArray[$i]->saldo_div      = "<b>".number_format($saldoDolar,2,',','.')."</b>";

	    $aArray[$i]->debe_mn_tot    = number_format($aArray[$i]->debe_mn_tot  ,2,',','.');
	    $aArray[$i]->haber_mn_tot   = number_format($aArray[$i]->haber_mn_tot ,2,',','.');
	    $aArray[$i]->debe_div_tot   = number_format($aArray[$i]->debe_div_tot ,2,',','.');
                                                                                                                                                                                	    $aArray[$i]->haber_div_tot  = number_format($aArray[$i]->haber_div_tot,2,',','.');

	    $dd                         = date_create($aArray[$i]->cc_fecha);
	    $aArray[$i]->cc_fecha       = date_format($dd,"d/m/Y");
	}
	$unItem = array('cc_id'             => '',
			'cc_fecha'          => '',
			'comp_nume'         => '<b>Saldo Final</b>',
			'debe_mn_tot'       => '',
			'haber_mn_tot'      => '',
			'debe_div_tot'      => '',
			'haber_div_tot'     => '',
			'cc_comentario'     => '',
			'debe_txt_mn_tot'   => '',
			'haber_txt_mn_tot'  => '',
			'debe_txt_div_tot'  => '',
			'haber_txt_div_tot' => '',
			'saldo_mn'          => "<b>".number_format($saldoPesos,2,',','.')."</b>" ,
			'saldo_div'         => "<b>".number_format($saldoDolar,2,',','.')."</b>" );
	$aArray[] = $unItem;
//	$aArray   = array_reverse($aArray);  2022-11-02 pidio q se ordenen por fecha de manor a mayor
	return array($aArray, $cantReg[0]->cant_reg);
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveUnRegistro($elId = 0,$idEnti = 0){

	//por defecto trae los de inversores

	$filtTipoEnti = 1;
	if ($this->session->opMenu == 46){  //para proveedores (46) debe traer solo los comprob.de proveedores
	    $filtTipoEnti = 2;
	}else if ($this->session->opMenu == 49){  //para prestamistas (49) debe traer solo los comprob.de prestamistas
	    $filtTipoEnti = 3;
	}

	$filtroTipComp = " AND (tipos_entidad->>'tipos_entidad'::text)::jsonb ?| array['".$filtTipoEnti."'] ";

	$idProyecto = $this->session->id_proyecto_activo;
	$queryR     = null;

	//////////////////////////agregado para este crud
	//////////////////////////////tipos comprobantes
	$queryTC  = dameTiposComprob( null, $filtroTipComp);

	//////////////////////////////proyectos-tipos de propiedades
	$queryTP  = dameProyTiposProp($idProyecto);

	//////////////////////////////proyectos excluye el activo
	$queryPr  = dameProyecto($idProyecto,2);

	//////////////////////////////monedas
	$queryMo  = dameMonedas();

	//////////////////////////////cotizaciones
	$queryCo  = dameCotizaciones();

	//////////////////////////////cotizacion del u$s
	$queryCo1 = dameCotizacion();


	//////////////////////////////presupuestos de la entidad
	$queryPresupu = damePresupuesto($idEnti,1); //1->poner cartel busca presupuesto, 2->buscar presu.no finalizados, 3-> 1+2

	//////////////////////////////entidades, devuelve las entidades del proyecto mas los proveedores

//cuando es pago a proveedores (46) debe traer solo proveedores

	if ($this->session->opMenu == 46){  //para pagos a proveedores (46) debe traer solo los proveed
	    $queryEn  = dameEntiXTipo( $this->config->item('tipos_enti_provee'),0 ,1);
	}elseif ($this->session->opMenu == 49){  //solo prestamistas
	    $queryEn  = dameEntiXTipo( $this->config->item('tipos_enti_presta'),0 ,1);
	}else{
//	    $queryEn  = dameEntiProye($idProyecto, null); //$this->config->item('tipos_enti_filtro'));
	    $queryEn  = dameEntiProye($idProyecto, "'{3}'"); //$this->config->item('tipos_enti_filtro'));
	}

	//////////////////////////////tipos de medios de pago
	$queryMP  = dameMediosPago();

	//////////////////////////////cuentas bancarias del proyecto
	$queryCB  = dameCtasBancarias(0,'',1,$idProyecto);   //$idProyecto, tipo cta, pone cartel "elija cuenta");

	//////////////////////////////bancos
	$queryBa  = dameBancos();

	//////////////////////////////chequeras
	$queryCa  = dameChequeras($idProyecto,"N",0);

	//////////////////////////
	$queryR[0]['fecha'] = date("Y-m-d");

	if ($elId>0){
	    $sql      = "SELECT * FROM ".$this->config->item('nombreTabla')." WHERE id = $elId ";
	    $query    = $this->db->query($sql);  //trae campos del registro a editar
	    $queryR   = $query->result_array();


	    ////////////////////////////agregado para este crud
	    /////////////////////////////////////tipos comprobantes

	    $tipoEntiComp = '';
	    for($i = 0 ; $i < count($queryTC) ; $i++){
		$queryTC[$i]['selectado'] = $queryTC[$i]['id']==$queryR[0]['tipo_comprobante_id'] ? ' selected ' : ' ' ;
		if ($queryTC[$i]['id']==$queryR[0]['tipo_comprobante_id']){
		    $tipoEntiComp = json_decode($queryTC[$i]['tipos_entidad']);
		    $tipoEntiComp = $tipoEntiComp->tipos_entidad[0];
		}
	    }

	    //////////////////////////////detalle tipos comprobantes en el proyecto para asociarlo a la entidad
	    if (!empty($queryR[0]['detalle_proyecto_tipo_propiedad_id'])){
		$sql      = "SELECT proyecto_tipo_propiedad_id AS ptp_id FROM detalle_proyecto_tipos_propiedades WHERE id = ".$queryR[0]['detalle_proyecto_tipo_propiedad_id'];
		$query    = $this->db->query($sql);
		$queryDP  = $query->result_array();
		for($i = 0 ; $i < count($queryTP) ; $i++){      //todos los tipos de propi
		    //busca el tipo de propiedad del detalle en tipos de propiedades
		    if ($queryDP[0]['ptp_id'] == $queryTP[$i]['ptp_id']){
			$queryTP[$i]['selectado'] =  ' selected ';
		    }
		}
	    }

	    /////////////////////////////////////monedas
	    for($i = 0 ; $i < count($queryMo) ; $i++){
		$queryMo[$i]['selectado'] = $queryMo[$i]['id']==$queryR[0]['moneda_id'] ? ' selected ' : ' ' ;
	    }
	    /////////////////////////////////////cotizaciones                  **** hay q ver como solucionar
	    for($i = 0 ; $i < count($queryCo) ; $i++){
		$queryCo[$i]['selectado'] = $queryCo[$i]['id']==$queryR[0]['tipo_comprobante_id'] ? ' selected ' : ' ' ;
	    }

	    /////////////////////////////////////entidades
	    for($i = 0 ; $i < count($queryEn) ; $i++){
		$queryEn[$i]['selectado'] = $queryEn[$i]['e_id']==$queryR[0]['entidad_id'] ? ' selected ' : ' ' ;
	    }
	    ////////////////////////////
	}

	$vacioTP = array( "ptp_id" => "0","tp_descripcion" => "No aplica","ptp_comentario" => "","selectado" => " ");
	array_unshift($queryTP, $vacioTP);

	$vacioTC = array( "id" => "0","descripcion" => "Elija un tipo de comprobante","abreviado" => "     ","afecta_caja"=>"0","selectado" => " ");
	array_unshift($queryTC, $vacioTC);

	$queryR[0]['entidades']      = $queryEn;
	$queryR[0]['cotizaciones']   = $queryCo;
	$queryR[0]['monedas']        = $queryMo;
	$queryR[0]['tiposprop']      = $queryTP;
	$queryR[0]['tiposcompr']     = $queryTC;
	$queryR[0]['mediospago']     = $queryMP;
	$queryR[0]['ctasbancarias']  = $queryCB;
	$queryR[0]['bancos']         = $queryBa;
	$queryR[0]['chequeras']      = $queryCa;
	$queryR[0]['cotizacion']     = $queryCo1;
	$queryR[0]['proyectos']      = $queryPr;
	$queryR[0]['presupuestos']   = $queryPresupu;

	return $queryR;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaUnRegistro($datos){


wh_log("DATOS.......................................guarda reg");
wh_log(json_encode($datos));
wh_log("---------------------------------------guarda reg");


	$transOk     = false;
	$idProyecto  = $this->session->id_proyecto_activo;
	$idUsuario   = $this->session->logged_in['id'];
	$tipoCom     = explode('|', $datos["frm_tipo_comprobante_id"]);  //0-> id tipo comp., 1->   , 2->tipo enti., 3-> , 4-> modelo
	$detaTipoPro = $datos["frm_detalle_proyecto_tipo_propiedad_id"];
	if (!empty($detaTipoPro)){
	    if ($detaTipoPro == 0){
		$detaTipoPro = null;
	    }
	}
	// hay q recuperar id en detalle_proyecto_tipos_propiedades con $datos["frm_entidad_id"] y $datos["frm_detalle_proyecto_tipo_propiedad_id"]
	// para grabarlo en detalle_proyecto_tipo_propiedad_id de cuentas_corrientes
	if ($datos["frm_detalle_proyecto_tipo_propiedad_id"]>0){
	    $sql      = "SELECT id FROM detalle_proyecto_tipos_propiedades WHERE proyecto_tipo_propiedad_id = ".$datos["frm_detalle_proyecto_tipo_propiedad_id"]." AND entidad_id = ".$datos["frm_entidad_id"] ;
	    $query    = $this->db->query($sql);
	    $queryDe  = $query->result_array();
	}

	$proyOP = $idProyecto;
	if ($tipoCom[2] == 2 && $tipoCom[4] == 5){  //[2](tipo entidad) -> 2 proveedor, [4](modelo) -> 5 o/p
	    $proyOP = null;
	}


	$data = array(  "tipo_comprobante_id"                => empty($tipoCom[0]) ? null : $tipoCom[0],
			"fecha"                              => $datos["frm_fecha"],
			"entidad_id"                         => empty($datos["frm_entidad_id"]) ? null : $datos["frm_entidad_id"],
			"detalle_proyecto_tipo_propiedad_id" => empty($queryDe[0]['id']) ? null : $queryDe[0]['id'],   //datos["frm_detalle_proyecto_tipo_propiedad_id"]) ? null : $datos["frm_detalle_proyecto_tipo_propiedad_id"],
			"importe"                            => $datos["frm_importe"],
			"moneda_id"                          => empty($datos["frm_moneda_id"]) ? null : $datos["frm_moneda_id"] ,
			"cotizacion_divisa"                  => empty($datos["frm_cotizacion_divisa"]) ? 0 : $datos["frm_cotizacion_divisa"],
			"importe_divisa"                     => empty($datos["frm_importe_divisa"]) ? 0 : $datos["frm_importe_divisa"],
			"comentario"                         => $datos["frm_comentario"],
			"proyecto_id"                        => $proyOP,   //$idProyecto,
			"usuario_id"                         => $idUsuario,
			"docu_letra"                         => empty($datos["frm_doculetra"]) ? null : $datos["frm_doculetra"] ,
			"docu_sucu"                          => empty($datos["frm_docusucu"])  ? null : $datos["frm_docusucu"] ,
			"docu_nume"                          => empty($datos["frm_docunume"])  ? null : $datos["frm_docunume"] ,
			"proyecto_origen_id"                 => $idProyecto);


	$movRelaXX = array();
	$movCajaXX = array();
	$dataCanXX = array();

	if ( !empty($datos["frm_id"]) ){				//actualizar
	    $this->db->where("id",intval($datos["frm_id"]));
	    return $this->db->update($this->config->item('nombreTabla'), $data);
	}else{								//ingresar
	    if (!empty($tipoCom[0])){
		$data['numero'] = dameProxNumeTal($tipoCom[0]);
	    }

	    /****** lo q sigue no puede ir, porq puede haber mov.de caja de diferentes monedas, el total debe salir por una funcion en la BD
	    if (isset($datos["tipomepa"])){
		$totalImporte = 0;
		for($i = 0; $i < count($datos["tipomepa"]); $i++){
		    $totalImporte += $datos["importemepa"][$i];
		}
		$data["importe"] = $totalImporte;
	    }
	    *******/

	    $this->db->trans_begin();
	    $sql        = "SELECT nextval('cuentas_corrientes_id_seq'::regclass) AS nuevoid" ;
	    $query      = $this->db->query($sql);
	    $queryIdCCC = $query->result_array();
	    $data["id"] = $queryIdCCC[0]["nuevoid"];
	    if ( $this->db->insert('cuentas_corrientes', $data) ){  //graba cabeza comprob
		$transOk  = true;

		//registra aplicaciones
		$r = '/aplica(pesos|dolar)\_(\d+)\_(\d+)/';                 //graba relaciones entre comprob.
		foreach($datos as $kk => $dd){
		    if ($dd > 0){
			if ( preg_match($r  , $kk, $match) ){
			    $movRela = array("cuenta_corriente_id" => $match[2],
					 "relacion_id"         => $data["id"],
					 "monto_divisa"        => ($match[3] != 1) ? $dd+0 : 0,
					 "monto_pesos"         => ($match[3] == 1) ? $dd+0 : 0);

			    $movRelaXX[] = $movRela;

			    $transOk = $this->db->insert('relacion_ctas_ctes', $movRela);
			    if (!$transOk){
				break;
			    }
			}
		    }
		}


wh_log("frm_presupuesto_id");
wh_log($datos["frm_presupuesto_id"]);

		$exPresu     = explode("|",$datos["frm_presupuesto_id"]);    
		if ($exPresu[0]>0){   //se aplico a un presupuesto
		    $aplicaPresu = array("cuenta_corriente_id" => $data["id"],
					 "presupuesto_id"      => $exPresu[0]);
		    $transOk     = $this->db->insert('relacion_presu_ctactes', $aplicaPresu);
		}

		if (isset($datos["tipomepa"])){

wh_log("11111111111111................................................");
wh_log(json_encode($datos["tipomepa"] ));
wh_log("22222222222222222222................................................");

		    if ($transOk){
			for($i = 0; $i < count( $datos["tipomepa"] ) ; $i++){

			    //efectivo y $tipoCom[2]==2 (provee), es Salida de efectivo porq el unico medio pago para provee. es O/P  
			    $tiposMov = explode("|",$datos["tipomepa"][$i]);

			    $elSigno  = 0;
			    if ($tipoCom[4] == 4){   //recibo
				$elSigno = 1;
			    }else if ($tipoCom[4] == 5){   //o/p
				$elSigno = -1;
			    }

			    $elChqSel = explode("|",$datos["cc_caja_ori"][$i]);
			    $aDepo    = empty($datos["chqadepo"][$i]) ? $elChqSel[5] : $datos["chqadepo"][$i];

			    if (in_array($tiposMov[0], array(20,21))){ //2023-04-18 tuve q poner separados los chqs a depo
				$tiposMov[0] -= 10; //para q los chqs a depo sean chqs
				$aDepo        = 1;  //fuerzo a depo
			    }

			    $movCaja = array("cuenta_corriente_id"     => empty($data["id"])               ? null : $data["id"],
					     "tipo_movimiento_caja_id" => empty($tiposMov[0])              ? null : $tiposMov[0],
					     "importe"                 => empty($datos["importemepa"][$i]) ? null : $datos["importemepa"][$i],
					     "moneda_id"               => empty($datos["monedamepa"][$i])  ? null : $datos["monedamepa"][$i],
					     "cotizacion_divisa"       => empty($datos["cotizamepa"][$i])  ? 0    : $datos["cotizamepa"][$i],
					     "importe_divisa"          => empty($datos["cotizamepa"][$i])  ? 0    : $datos["cotizamepa"][$i],
					     "comentario"              => $datos["comenta"][$i],
					     "cta_cte_caja_origen_id"  => empty($elChqSel[0]) ? null : $elChqSel[0],    //  $datos["cc_caja_ori"][$i]) ? null : $datos["cc_caja_ori"][$i],  //si es aplicacion de chq.3ro., indica id del mov.de ingreso del chq
					     "caja_id"                 => 1,
					     "e_chq"                   => $tiposMov[5],
					     "signo_caja"              => $elSigno,     //indica como opera el registro en caja, 
					     "signo_banco"             => $elSigno);    //1 -> recibo, incrementa monto, -1 -> o/p decrementa monto
											//0 otras operaciones q no estan en caja
											//esta parte solo incluyen los movimentos de inversores y proveedores 

wh_log("tipos mov ...........................................................");
wh_log(json_encode($tiposMov));
			    if ($tiposMov[2] == 1){     //gestiona cta.bancaria
				//tomo el primer dato q es la cta bancaria, el 2do es el proyecto de esa cuenta
				$xCtaBanc = explode('|', $datos["ctabanc"][$i]);
				$movCaja["cuenta_bancaria_id"] = $xCtaBanc[0];
			    }

			    if ($tiposMov[1] == 1){     //gestiona chqs
				$movCaja["fecha_emision"]      = empty($datos["chqfemi"][$i])      ? null : $datos["chqfemi"][$i];
				$movCaja["fecha_acreditacion"] = empty($datos["chqfacre"][$i])     ? null : $datos["chqfacre"][$i];
				$movCaja["serie"]              = $datos["chqserie"][$i];
				$movCaja["numero"]             = empty($datos["chqnro"][$i])       ? null : $datos["chqnro"][$i];
				$movCaja["chequera_id"]        = empty($datos["chequera_id"][$i])  ? null : $datos["chequera_id"][$i];

//2023-04-17 lo q sigue es por el problema de chq a depo. si viene de registrar un chq o tomar uno de cartera
//				$movCaja["chq_a_depo"]         = empty($datos["chqadepo"][$i])     ? null : $datos["chqadepo"][$i];
				$movCaja["chq_a_depo"]         = empty($aDepo)                     ? null : $aDepo;

//				if (empty($datos["chequeras"][$i])){
//2024-03-06 parche para q defina si es chq de 3ro de cualquier tipo y no de chequera porq los nros de chequera siempre vienen desde la pagina
//$tiposMov[1]==1 --> gestiona chqs,  $tiposMov[2]==0 --> no gestiona cuenta bancaria){
				if ($tiposMov[1]==1 && $tiposMov[2]==0){
				    $movCaja["banco_id"]           = $datos["banco"][$i];
				}else{
				    $xCtaBanc                      = explode('|', $datos["chequeras"][$i]);
				    $movCaja["cuenta_bancaria_id"] = $xCtaBanc[1];
				    $movCaja["banco_id"]           = $xCtaBanc[6];
				}

				if ($tiposMov[2] == 0){     //no gestiona cta.bancaria
				    $movCaja["cuenta_bancaria_id"] = null;
				}
			    }else{
				$movCaja["fecha_acreditacion"] = $datos["frm_fecha"]; //todo mov q no es chq la f.acreditacion = f.registro
			    }

			    $movCajaXX[] = $movCaja;

wh_log(" movCaja *********************************************************");
wh_log(json_encode($movCaja));
			    $transOk = $this->db->insert('cuentas_corrientes_caja', $movCaja);
//wh_log('------------cuentas_corrientes_caja');
//wh_log($transOk);

			    if ($tiposMov[8] == 9){ //es canje, generar recibo
				    $sqlMo      = "SELECT id FROM tipos_comprobantes WHERE modelo = 4 LIMIT 1";  //modelo 4->recibo
				    $qMo        = $this->db->query($sqlMo);
				    $queryMo    = $qMo->result_array();
				    $tipoReci   = $queryMo[0]["id"];
//wh_log("gen rec   $recId");
				    $dataCan       = $data;
				    $movCajaCan    = $movCaja;
				    $sql           = "SELECT nextval('cuentas_corrientes_id_seq'::regclass) AS nuevoid" ;
				    $query         = $this->db->query($sql);
				    $queryIdCCC    = $query->result_array();
				    $dataCan["id"] = $queryIdCCC[0]["nuevoid"];
				    $dataCan["tipo_comprobante_id"] = $tipoReci;
				    $dataCan["importe"]             = null;
				    $dataCan["moneda_id"]           = null;
				    $dataCan["cotizacion_divisa"]   = 0;
				    $dataCan["importe_divisa"]      = 0;
				    $dataCan["comentario"]          = "Recibo por canje - " .  $movCaja["comentario"];
				    $dataCan["numero"]              = dameProxNumeTal($tipoReci);
				    $dataCan["proyecto_id"]         = $idProyecto;
				    $transOk = $this->db->insert('cuentas_corrientes', $dataCan);
//wh_log('-------------cuentas_corrientes');
//wh_log($transOk);
				    $movCajaCan = array();
				    if ($transOk){
//wh_log("gen impo rec");
					$movCajaCan["cuenta_corriente_id"]     = $dataCan["id"];
					$movCajaCan["cta_cte_caja_origen_id"]  = null;
//					$movCajaCan["importe"]                *= -1;
					$transOk = $this->db->insert('cuentas_corrientes_caja', $movCajaCan);
//wh_log('----------------cuentas_corrientes_caja2');
//wh_log($transOk);
				    }

				    $dataCanXX[] = $dataCan;
				    $dataCanXX[] = $movCanCan;

			    }

			    if (!$transOk){
				break;
			    }
			}
		    }
		}
	    }
	    if ($transOk){

	    wh_log("commit");

		$this->db->trans_commit();
	    }else{

	    wh_log("rollback");

		$this->db->trans_rollback();
	    }
	}

	$data['datos']       = $datos;
	$data['transaccion'] = $transOk;
	$data['movrela']     = $movRelaXX;
	$data['movcaja']     = $movCajaXX;
	$data['movcajacan']  = $dataCajaXX;

	return $data;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function eliminaUnRegistro($elId = 0){
	if ($elId>0){
	    $transOk = false;
	    $data    = array("estado" => 1);
	    $this->db->trans_begin();
	    $this->db->where("id",intval($elId));
	    if ($this->db->update($this->config->item('nombreTabla'), $data)){
		$this->db->where("cuenta_corriente_id",intval($elId));
		if ($this->db->update("cuentas_corrientes_caja", $data)){
		    $this->db->where("cuenta_corriente_id",intval($elId));
		    if ($this->db->update("relacion_ctas_ctes", $data)){
			$this->db->where("relacion_id",intval($elId));
			if ($this->db->update("relacion_ctas_ctes", $data)){
			    $this->db->where("cuenta_corriente_id",intval($elId));
			    if ($this->db->update("relacion_ctas_ctes", $data)){
				$transOk = true;
			    }
			}
		    }
		}
	    }
	    if ($transOk){
		$this->db->trans_commit();
		wh_log("eliminado $elId");
	    }else{
		$this->db->trans_rollback();
		wh_log("NO PUDO SER eliminado $elId");
	    }
	    return $transOk;
	}
	return false;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function recuCliexTipo($elId = 0, $elTipo = '', $laPropi = 0){

	//$elId es tipo de comprobante
	//$elTipo = 'C' -> viene de cambiar tipo de comprobante, = 'P' -> viene de cambiar tipo de propiedad
	//$laPropi es el id del detalle de propiedades en el proyecto

	$idProyecto = $this->session->id_proyecto_activo;

	if ($elId > 0){
	    ////////////////////////////////tipos de entidades de acuerdo al tipo de comprobante
	    $sql      = "SELECT (tipos_entidad->>'tipos_entidad'::text)::text AS tipo
			FROM tipos_comprobantes
			WHERE id = $elId";
	    $query    = $this->db->query($sql);
	    $queryTC  = $query->result_array();
	    preg_match('/(\d+)/',$queryTC[0]['tipo'],$matches);

//1 -> inversor, 2 -> proveedor, 3 -> prestamista
//si el comprobante es para inversor y no aplica propiedad, devuelve todos los inversores
//si el comprobante es para inversor y aplica a una propiedad, devuelve los propietarios

//si el comprobante es para prestamista y no aplica propiedad, devuelve todos los prestamistas
//si el comprobante es para prestamista y aplica a una propiedad, devuelve todos los prestamistas

//si el comprobante es para proveedor y no aplica propiedad, devuelve todos los proveedores
//si el comprobante es para proveddor y aplica a una propiedad, devuelve todos los proveedores

//$matches[1] == 1 && $laPropi >0  comprob.inversor e indica una propiedad
//    trae propietarios
//$matches[1] == 1 && $laPropi == 0  comprob.inversor y no indica una propiedad
//    trae todos inversores
//
//$matches[1] == 2 && $laPropi >0  comprob.proveedor e indica una propiedad
//    trae proveedores
//$matches[1] == 2 && $laPropi == 0  comprob.proveedor y no indica una propiedad
//    trae proveedores
//
//$matches[1] == 3 && $laPropi >0  comprob.prestamista e indica una propiedad
//    trae prestamistas
//$matches[1] == 3 && $laPropi == 0  comprob.prestamista y no indica una propiedad
//    trae prestamistas
//

	    if ($elTipo == 'C'){ //cambio de tipo de comprobante

		//////////////////////////////entidades
		$sql      = "SELECT DISTINCT e_id,e_razon_social,tipoentidad,' ' AS selectado  
			    FROM vi_proyectos_entidades 
			    WHERE p_id = $idProyecto AND fun_buscarTiposEntidades(e_id,array['".$matches[1]."']) >= 1 ";
		if ($matches[1] == '2'){  //si el tipo de comprob es de proveedores, trae a todos los proveedores
		    $sql .= " UNION SELECT id,razon_social,fun_dameTiposEntidades(id,'E') AS tipoentidad,' ' AS selectado
			    FROM entidades WHERE fun_buscarTiposEntidades(id,array['2']) >= 1 ";
		}
		$sql     .= " ORDER BY e_razon_social";

	    }else{  //P  cambio de propiedad

		if ($matches[1] == '1'){  //si el tipo de comprob es de inversor, hay 2 posibilidades 

		    if ($laPropi == 0){  //si no fue selectada una propiedad, trae todos los inversores
			$sql      = "SELECT id AS e_id,razon_social AS e_razon_social,fun_dameTiposEntidades(id,'E') AS tipoentidad,' ' AS selectado
				FROM entidades WHERE fun_buscarTiposEntidades(id,array['1']) >= 1 
				ORDER BY razon_social";
		    }else{ //indico una propiedad, trae los porpietarios
			$sql      = "SELECT e_id,e_razon_social,fun_dameTiposEntidades(e_id,'E') AS tipoentidad, ' ' AS selectado
				FROM vi_detalle_proyectos_tipos_propiedades
				WHERE pr_id = $idProyecto 
				  AND ptp_id = $laPropi 
				  AND (dptp_coeficiente IS NOT NULL AND dptp_coeficiente > 0)
				ORDER BY e_razon_social";
		    }

		}else if ($matches[1] == '2'){  //si el tipo de comprob es de proveedores, trae a todos los proveedores
			$sql      = "SELECT id AS e_id,razon_social AS e_razon_social,fun_dameTiposEntidades(id,'E') AS tipoentidad,' ' AS selectado
				FROM entidades WHERE fun_buscarTiposEntidades(id,array['2']) >= 1 
				ORDER BY razon_social";

		}else if ($matches[1] == '3'){ //si el tipo de comprob es de prestamistas, trae a todos los prestamistas

			$sql      = "SELECT id AS e_id,razon_social AS e_razon_social,fun_dameTiposEntidades(id,'E') AS tipoentidad,' ' AS selectado
				FROM entidades WHERE fun_buscarTiposEntidades(id,array['3']) >= 1
				ORDER BY razon_social";
		}
	    }

	    $query    = $this->db->query($sql);
	    $queryEn  = $query->result_array();
	    return $queryEn;
	}
	return false;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function RecuChqsCartera($eChq = 0){
	$idProyecto = $this->session->id_proyecto_activo;
	$chqsDispo  = dameChqsCartera($idProyecto,$eChq,3); //3-> no a depo  proy corriente
	return $chqsDispo;

    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function RecuChqsCarteraADepo($eChq = 0){
	$idProyecto = $this->session->id_proyecto_activo;
	$chqsDispo  = dameChqsCartera($idProyecto,$eChq,1); //1-> a depositar proy corriente
	return $chqsDispo;

    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function RecuChequeras($eChq = null,$allCtas = 0){
	$idProyecto = $this->session->id_proyecto_activo;
	$chqsDispo  = dameChequeras($idProyecto,$eChq,2);       //// 2-> trae todas las chqueras de todos los proy.     $allCtas);
	return $chqsDispo;

    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function RecuProyPropieEnti($entiId){
	$idProyecto   = $this->session->id_proyecto_activo;
	$proyPropEnti = dameProyPropEnti($idProyecto,0 , $entiId, 1);
	return $proyPropEnti;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function RecuCompAdeu($entiId,$modeloComp){

wh_log('modeloComp');
wh_log($modeloComp);

	$idProyecto = $this->session->id_proyecto_activo;
	$filtro     = " AND cc_proyecto_id = $idProyecto ";
	$invProv    = 1;
	$filtro2    = " AND tc_modelo IN $modeloComp ";
	if ($this->session->opMenu == 46){  //> 0){ //hay q sacar filtro entidades y proyectos q no sean proveedores cuando opcion menu = 46
	    $filtro  = "";
	    $invProv = 2;
	}else if ($this->session->opMenu == 49){  // tiene q recuperar los mov de prestamista
	    $filtro     = "";
	    $invProv    = 3;
	    if ($modeloComp == ''){
		$filtro2 = '';
	    }
	}
	$sql          = "SELECT cc_id, cc_tipo_comprobante_id, cc_importe, cc_moneda_id, cc_entidad_id, cc_comentario,
				cc_proyecto_id, p_nombre, cc_fecha, cc_fecha_dmy, cc_fecha_registro, cc_numero, mo_simbolo,
				tc_descripcion, tc_signo, tc_abreviado, tc_modelo, saldopesos, saldodolar, tc_aplica_impu
			FROM vi_ctas_ctes 
			WHERE saldopesos + saldodolar > 0
			  AND cc_entidad_id = $entiId 
			  $filtro
			  $filtro2
			  AND (tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ?| array['$invProv']
			ORDER BY cc_fecha ";
wh_log($sql);

	$query    = $this->db->query($sql);
	$queryCA  = $query->result_array();
	return $queryCA;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function error($mensaje){
	$this->mensaje= $mensaje;
	return false;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function cargaGenCuo(){

	$idProyecto             = $this->session->id_proyecto_activo;
	$queryR['entidades']    = dameEntiProye($idProyecto);     //entidades, devuelve las entidades del proyecto
	$queryR['monedas']      = dameMonedas();                  //monedas
	$queryR['tiposprop']    = dameProyTiposProp($idProyecto,true); //proyectos-tipos de propiedades
	$queryR['tiposcompr']   = dameTiposComprob('1|3','AND signo = 1');  //tipos comprobantes
	$queryR['proypropenti'] = dameProyPropEnti($idProyecto,0,0,1);
	$queryR['cotizacion']   = dameCotizacion();
	return $queryR;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function guardaGenCuo($datos){

	$transOk     = false;
	$dateIni     = date('d-m-Y',strtotime( $datos["frm_fecha"]));
	$periodo     = $datos["frm_periodo_id"];
	$cuotas      = $datos["frm_cant_cuotas"];
	$tipoCom     = explode('|', $datos["frm_tipo_comprobante_id"]);  //0-> id tipo comp., 1->   ,2->tipo enti.
	$nPriCuota   = $datos["nro1cuota"];
	$idProyecto  = $this->session->id_proyecto_activo;
	$idUsuario   = $this->session->logged_in['id'];
	$this->db->trans_begin();
	foreach($datos as $clave => $unIt){ 
	    if (substr($clave,0,4) == 'chk_'){
		$dptpEid = explode("|",$unIt);
		for ($j = 1; $j <= $datos["frm_cant_cuotas"]; $j++){
		    $k       = ($j-1) * $periodo;
		    $dateFut = strtotime("+$k month", strtotime($dateIni));
		    $dateFut = date('Y-m-d', $dateFut);
		    $comenta  = ($nPriCuota > 0) ? "Cuota Nro.: " . ($nPriCuota+ $j-1) :"" ;
		    $comenta .= "  " . $datos["frm_comentario"];
		    $data = array(  "tipo_comprobante_id"                => $tipoCom[0] ,
				    "detalle_proyecto_tipo_propiedad_id" => $dptpEid[0],
				    "fecha"                              => $dateFut,
				    "entidad_id"                         => $dptpEid[1],
				    "importe"                            => $datos["frm_importe"] * $dptpEid[2],
				    "moneda_id"                          => empty($datos["frm_moneda_id"]) ? null : $datos["frm_moneda_id"] ,
				    "cotizacion_divisa"                  => empty($datos["frm_importe_divisa"]) ? 0 : $datos["frm_importe_divisa"],
				    "importe_divisa"                     => empty($datos["frm_importe_divisa"]) ? 0 : $datos["frm_importe_divisa"],
				    "comentario"                         => $comenta,
				    "proyecto_id"                        => $idProyecto,
				    "usuario_id"                         => $idUsuario);
		    if (!empty($tipoCom[0])){
			$sql            = "UPDATE tipos_comprobantes SET numero = numero + 1 WHERE id = ".$tipoCom[0]."  RETURNING numero";
			$query          = $this->db->query($sql);
			$queryNro       = $query->result_array();
			$data['numero'] = $queryNro[0]['numero'];
		    }
		    $transOk = $this->db->insert('cuentas_corrientes', $data); 
		    if (!$transOk){
			break;
		    }
		}
	    }
	}
	if ($transOk){
	    $this->db->trans_commit();
	    wh_log("eliminado $elId");
	}else{
	    $this->db->trans_rollback();
	    wh_log("NO PUDO SER eliminado $elId");
	}
	return $transOk;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function infoComp($compId){

wh_log("model infocomp $compId");

	$filtTipoEnti = 1;
	if ($this->session->opMenu == 46){  //para proveedores (46) debe traer solo los comprob.de proveedores
	    $filtTipoEnti = 2;
	}else if ($this->session->opMenu == 49){  //para prestamistas (49) debe traer solo los comprob.de prestamistas
	    $filtTipoEnti = 3;
	}

	return dameInfoComp($compId,0,$filtTipoEnti);


    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function saldoEnti($idEnti,$tipoEnti,$hasta){  //$tipoEnti = 32, trae saldo de cliente, 46, trae saldo de proveedor

	$idProyecto = $this->session->id_proyecto_activo;
	$where = " AND POSITION('1' in fun_dametiposentidades(cc_tipo_comprobante_id, 'X') ) > 0 ";   //muestra mov.cliente
	if ($tipoEnti == 46){ //recupera proveedores solamente
	    $where  = " AND POSITION('2' in fun_dametiposentidades(cc_tipo_comprobante_id, 'X') ) > 0 ";   //muestra mov.provee
	}
//	$where .= " AND cc_proyecto_id = $idProyecto ";
	if ($idEnti > 0){
	    $where .= " AND cc_entidad_id = $idEnti ";
	}
	$sql = "SELECT  cc_proyecto_id,
			SUM(tc_signo * fun_calcimportecaja(cc_id, 1)) AS saldo_mn,
			SUM(tc_signo * fun_calcimportecaja(cc_id, 2)) AS saldo_div
		FROM vi_ctas_ctes
		WHERE cc_fecha_registro::date <= '$hasta'
		$where 
		GROUP BY cc_proyecto_id";
//wh_log($sql);
	$query      = $this->db->query($sql);
	$aArray     = $query->result();
//	$aArray[0]->saldo_mn  = ($aArray[0]->saldo_mn  == null)?0:$aArray[0]->saldo_mn;
//	$aArray[0]->saldo_div = ($aArray[0]->saldo_div == null)?0:$aArray[0]->saldo_div;
//	return array('saldo_mn'     => $aArray[0]->saldo_mn,
//		     'saldo_div'    => $aArray[0]->saldo_div);

	$arrRet   = array();
	$saldoMn  = 0;
	$saldoDiv = 0;

	foreach($aArray as $xx){
	    $saldoMn  += ($xx->saldo_mn   == null) ? 0 : $xx->saldo_mn;
	    $saldoDiv += ($xx->saldo_div  == null) ? 0 : $xx->saldo_div;

	    $arrRet[] = array(  'proyecto'  => $xx->cc_proyecto_id,
				'saldo_mn'  => ($xx->saldo_mn   == null) ? 0 : $xx->saldo_mn,
				'saldo_div' => ($xx->saldo_div  == null) ? 0 : $xx->saldo_div);
	}
	$arrRet[] = array(  'total'     => 0,
			    'saldo_mn'  => ($saldoMn   == null) ? 0 : $saldoMn,
			    'saldo_div' => ($saldoDiv  == null) ? 0 : $saldoDiv);
	return $arrRet;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function validarComprob($data){

	$tipoComp  = explode('|', $data['tipocomp']);
	$sql = "SELECT COUNT(*) AS nreg FROM cuentas_corrientes
		WHERE estado = 0
		  AND tipo_comprobante_id = ".$tipoComp[0] ."
		  AND entidad_id = ".$data['identi']."
		  AND docu_letra = '".$data['docul']."'
		  AND docu_sucu  = ".$data['docus']."
		  AND docu_nume  = ".$data['docun']  ;

	$query  = $this->db->query($sql);
	$aArray = $query->result();

	return $aArray[0]->nreg;

    }
}
