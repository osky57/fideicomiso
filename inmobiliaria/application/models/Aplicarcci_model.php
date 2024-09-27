<?php

class Aplicarcci_model extends CI_Model {						// **->

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function __construct() {
	$this->config->load('nocrud_aplicar_cci.php');						// **->
	$this->load->database();
	$this->load->helper('funciones_helper');
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function devuelveAplicar($elGet){
	$idProy = $this->session->id_proyecto_activo;
	$desde  = $elGet['fdesde'];
	$hasta  = $elGet['fhasta'];
	$idEnti = $elGet['entidad'];
	$aRet   = array();
	$aArray = array();
	if ($idEnti > 0){
	    $sql = "SELECT  vcc.cc_id AS vcc_cc_id,
			    vcc.cc_comentario AS vcc_cc_comentario,
			    vcc.cc_fecha_dmy AS vcc_cc_fecha_dmy,
			    vcc.tc_abreviado || ' ' || vcc.cc_numero AS comprob_deb,
			    CASE WHEN vcc.cc_moneda_id =  1 THEN vcc.cc_importe  ELSE 0 END  AS importe_mn,
			    CASE WHEN vcc.cc_moneda_id <> 1 THEN vcc.cc_importe  ELSE 0 END  AS importe_div,
			    ccc.cc_id AS ccc_cc_id,
			    ccc.cc_comentario AS ccc_cc_comentario,
			    ccc.cc_fecha_dmy AS ccc_cc_fecha_dmy,
			    ccc.tc_abreviado || ' ' || ccc.cc_numero AS comprob_hab,
			    rcc.monto_divisa AS rcc_monto_divisa,
			    rcc.monto_pesos AS rcc_monto_pesos
		FROM vi_ctas_ctes vcc
		left join relacion_ctas_ctes rcc on vcc.cc_id = rcc.cuenta_corriente_id AND rcc.estado = 0
		left join vi_ctas_ctes ccc on rcc.relacion_id = ccc.cc_id
		WHERE vcc.cc_entidad_id = $idEnti
		AND vcc.cc_proyecto_id = $idProy
		AND vcc.tc_modelo IN (1,2)
		AND (vcc.tc_tipos_entidad->>'tipos_entidad'::text)::jsonb ? '1'
		AND vcc.cc_estado = 0
		AND vcc.cc_fecha BETWEEN '$desde' AND '$hasta'
		ORDER BY vcc.cc_fecha DESC, vcc.cc_id DESC";

wh_log($sql);


	    $query      = $this->db->query($sql);
	    $queryS     = $query->result_array();
	    if (count($queryS) > 0){
		$anteCompr = -1;
		for($i = 0 ; $i < count($queryS) ; $i++){
		    if ($queryS[$i]['vcc_cc_id'] != $anteCompr){
			if ($anteCompr != -1){
			    $nUlt = count($aArray)-1;
			    $aArray[$nUlt]['saldo_mn']  = ($saldoMN != 0) ? number_format($saldoMN,2,'.','') : '';
			    $aArray[$nUlt]['saldo_div'] = ($saldoDiv != 0) ? number_format($saldoDiv,2,'.','') : '';
			}
			$anteCompr = $queryS[$i]['vcc_cc_id'];
			$saldoMN   = $queryS[$i]['importe_mn'];
			$saldoDiv  = $queryS[$i]['importe_div'];
			$aArray[]  = array( 'xxx'              => '00',
					    'vcc_cc_id'        => $queryS[$i]['vcc_cc_id'],
					    'vcc_cc_fecha_dmy' => $queryS[$i]['vcc_cc_fecha_dmy'],
					    'comprob_deb'      => $queryS[$i]['comprob_deb'],
					    'vcc_cc_comentario'=> $queryS[$i]['vcc_cc_comentario'],
					    'importe_mn'       => ($queryS[$i]['importe_mn'] != 0) ? $queryS[$i]['importe_mn'] : '',
					    'importe_div'      => ($queryS[$i]['importe_div'] != 0) ? $queryS[$i]['importe_div'] : '',
					    'aplica_mn'        => '',
					    'aplica_div'       => '',
					    'saldo_mn'         => ($saldoMN  == 0) ? '' : $saldoMN,
					    'saldo_div'        => ($saldoDiv == 0) ? '' : $saldoDiv);
		    }
		    if (!is_null($queryS[$i]['ccc_cc_id'])){
			$saldoMN   -= $queryS[$i]['rcc_monto_pesos'];
			$saldoDiv  -= $queryS[$i]['rcc_monto_divisa'];
			$aArray[]   = array('xxx'              => $anteCompr,
					    'vcc_cc_id'        => $queryS[$i]['ccc_cc_id'],
					    'vcc_cc_fecha_dmy' => $queryS[$i]['ccc_cc_fecha_dmy'],
					    'comprob_deb'      => $queryS[$i]['comprob_hab'],
					    'vcc_cc_comentario'=> $queryS[$i]['ccc_cc_comentario'],
					    'importe_mn'       => '',
					    'importe_div'      => '',
					    'aplica_mn'        => ($queryS[$i]['rcc_monto_pesos'] != 0) ? $queryS[$i]['rcc_monto_pesos'] : '',
					    'aplica_div'       => ($queryS[$i]['rcc_monto_divisa'] != 0) ? $queryS[$i]['rcc_monto_divisa'] : '',
					    'saldo_mn'         => ($saldoMN   == 0) ? '' : number_format($saldoMN ,2,'.',''),
					    'saldo_div'        => ($saldoDiv  == 0) ? '' : number_format($saldoDiv,2,'.',''));
		    }
		}
		$nUlt = count($aArray)-1;
		$aArray[$nUlt]['saldo_mn']  = ($saldoMN  != 0) ? number_format($saldoMN ,2,'.','') : '';
		$aArray[$nUlt]['saldo_div'] = ($saldoDiv != 0) ? number_format($saldoDiv,2,'.','') : '';
		$aRet['comprob'] = $aArray;
		$aArray = array();
		$sql = "SELECT    cc_id
				, cc_fecha_dmy
				, comp_nume
				, saldopesos
				, saldodolar
			FROM vi_ctas_ctes vcc
			WHERE vcc.cc_entidad_id = $idEnti
			AND vcc.cc_proyecto_id = $idProy
			AND vcc.tc_modelo NOT IN (1,2,5)
			AND vcc.cc_estado = 0
			AND (fun_comprobsinaplicar(vcc.cc_id,1)>0 OR fun_comprobsinaplicar(vcc.cc_id,2)>0)
			ORDER BY vcc.cc_fecha, vcc.cc_id";


////en modelo hay q indicar si son proveedores no muestre recibos (4) y si son clientes no muestre o/p (5)




		$query      = $this->db->query($sql);
		$queryS     = $query->result_array();
		if (count($queryS) > 0){
		    for($i = 0 ; $i < count($queryS) ; $i++){
			$aArray[]  = array( 'xxx'              => 'xx',
					    'vcc_cc_id'        => $queryS[$i]['cc_id'],
					    'vcc_cc_fecha_dmy' => $queryS[$i]['cc_fecha_dmy'],
					    'comprob_deb'      => $queryS[$i]['comp_nume'],
					    'vcc_cc_comentario'=> '',
					    'importe_mn'       => '',
					    'importe_div'      => '',
					    'aplica_mn'        => '',
					    'aplica_div'       => '',
					    'saldo_mn'         => '',
					    'saldo_div'        => '',
					    'noaplicado_mn'    => ($queryS[$i]['saldopesos'] != 0) ? $queryS[$i]['saldopesos'] : '',
					    'noaplicado_div'   => ($queryS[$i]['saldodolar'] != 0) ? $queryS[$i]['saldodolar'] : '' );
		    }
		}
		$aRet['sinapli'] = $aArray;
		return $aRet;
	    }
	}
	return 0;
    }

/***
{"tr1":
    [
             0                 1           2  3     4           5      6   7        8         9
                                                 aplica MN                aplica US                                      id deb.   id reci.
	["25-09-2022","RECI.CUOTA INV. 47","","","10000.00","10000.00","",""       ,"","table-warning ui-sortable-handle t1_id_257 296       t1_id_257_296"],
	["17-10-2022","RECI.CUOTA INV. 52","","", "2000.00", "8000.00","",""       ,"","table-warning ui-sortable-handle t1_id_257 343       t1_id_257_343"],
	["25-09-2022","RECI.CUOTA INV. 47","","", "5000.00", "5000.00","",""       ,"","table-warning ui-sortable-handle t1_id_136 296       t1_id_136_296"]
    ],
 "tr2":
    [
             0                 1           2  3          4            5
                                              MN         US        id rec.   
	["15-09-2022","RECI.APOR.INV. 55" ,"","10000.00",""       ,"t2_id_281"],
	["17-09-2022","RECI.CUOTA INV. 38","", "2222.00","1111.00","t2_id_282"],
	["25-09-2022","RECI.CUOTA INV. 47","", ""       ,"2000.00","t2_id_296"]]}

[9] explode
     0                1             2       3             4
table-warning ui-sortable-handle t1_id_257 296       t1_id_257_296

0  1  2   3
t1_id_257_296


["25-09-2022","RECI.CUOTA INV. 47","","","","","","2000.00","","table-warning ui-sortable-handle t1_id_258 296 t1_id_258_296"]
[{"id":"31","cuenta_corriente_id":"258","relacion_id":"296","estado":"0","monto_pesos":"0.00","monto_divisa":"2000.00"}]


["25-09-2022","RECI.CUOTA INV. 47","","","10000.00","10000.00","","","","table-warning ui-sortable-handle t1_id_257 296 t1_id_257_296"]
[{"id":"30","cuenta_corriente_id":"257","relacion_id":"296","estado":"0","monto_pesos":"10000.00","monto_divisa":"0.00"}]

["17-10-2022","RECI.CUOTA INV. 52","","","2000.00","8000.00","","","","table-warning ui-sortable-handle t1_id_257 343 t1_id_257_343"]
[{"id":"39","cuenta_corriente_id":"257","relacion_id":"343","estado":"0","monto_pesos":"2000.00","monto_divisa":"0.00"}]

["15-09-2022","RECI.APOR.INV. 55","","","5000.00","5000.00","","","","table-warning ui-sortable-handle t1_id_136 281 t1_id_136_281"]
[]

["25-09-2022","RECI.CUOTA INV. 47","","","5000.00","","","","","table-warning ui-sortable-handle t1_id_136 296 t1_id_136_296"]
[{"id":"29","cuenta_corriente_id":"136","relacion_id":"296","estado":"0","monto_pesos":"5000.00","monto_divisa":"0.00"}]


***/
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public function grabaAplicar($elPost){

wh_log($elPost);
wh_log(json_encode($elPost));
wh_log(json_decode($elPost));


	$idEntidad = $elPost['entidad'];
	$idProy    = $this->session->id_proyecto_activo;

	$sqlS = "SELECT id
		, cuenta_corriente_id
		, relacion_id
		, estado
		, monto_pesos
		, monto_divisa
		FROM relacion_ctas_ctes
		WHERE cuenta_corriente_id = ?
		AND relacion_id           = ?
		AND estado = 0
		ORDER BY id";

	$sqlU = "UPDATE relacion_ctas_ctes SET estado = ?
					     , monto_pesos = ?
					     , monto_divisa = ?
		WHERE id = ?";

	$sqlD = "UPDATE relacion_ctas_ctes SET estado = 1
		WHERE id = ?";

	$sqlI = "INSERT INTO relacion_ctas_ctes ( cuenta_corriente_id
						, relacion_id
						, monto_pesos
						, monto_divisa )
		VALUES (?,?,?,?)";

	//anula todos los mov. de la entidad de acuerdo si es inversor o proveedor en el proyecto activo
	$sql1 = "UPDATE relacion_ctas_ctes SET estado = 1 
		WHERE cuenta_corriente_id IN (SELECT cc.id  AS id
					    FROM cuentas_corrientes cc
					    JOIN tipos_comprobantes tc ON cc.tipo_comprobante_id = tc.id
					    WHERE cc.entidad_id = ? 
					      AND cc.proyecto_id = ? 
					      AND tc.tipos_entidad->>'tipos_entidad'::text LIKE '%1%' )";

//					      AND (tc.tipos_entidad->>'tipos_entidad'::text)::jsonb ?& array['1'] )";

wh_log("enti $idEntidad   proy  $idProy");
wh_log($sql1);

	$q    = $this->db->query($sql1,[$idEntidad,$idProy]);

wh_log("q  ");
wh_log(json_encode($q));



	//va activando los mov.anulados de acuerdo a la composicion
	foreach($elPost['tr1'] as $unTr){
	    $ultF  = explode(" ",$unTr[9]);
	    $losId = explode("_",$ultF[4]);
	    for($i = 3; $i <= 8; $i++){ //convierte los "" en 0
		$unTr[$i] = empty($unTr[$i]) ? 0 : $unTr[$i];
	    }
	    $query      = $this->db->query($sqlS,[$losId[2],$losId[3]]);
	    $queryS     = $query->result_array();

wh_log("sqlS ".$losId[2]."    ".$losId[2]);

	    if (count($queryS) == 1){

wh_log("sqlU   4  ".$unTr[4]."  7 ".$unTr[7]."   0id  ".$queryS[0]['id']);

		$query  = $this->db->query($sqlU,[0,$unTr[4] ,$unTr[7],$queryS[0]['id']]);
	    }else{

wh_log("$sqlI   2 ".$losId[2]."  3 ".$losId[3]."  4  ".$unTr[4]."   7  ".$unTr[7]);

		$query  = $this->db->query($sqlI,[$losId[2],$losId[3],$unTr[4],$unTr[7]]);
	    }

	}

/*
	foreach($elPost['tr2'] as $unTr){
	    if (!empty($unTr[7])){
		if ($unTr[7] != $unTr[8]){
		    $debId   = explode("_",$unTr[7]);
		    $recId   = explode("_",$unTr[8]);
		    $query   = $this->db->query($sqlS,[$debId[2],$recId[2]]);
		    $queryS  = $query->result_array();
		    $unTr[3] = empty($unTr[3])?0:$unTr[3];
		    $unTr[4] = empty($unTr[4])?0:$unTr[4];
		    foreach ($queryS as $unQ){
			if ($unQ['monto_pesos'] == $unTr[3]){
			    if ($unQ['monto_divisa'] == $unTr[4]){
				log_message('error', "ELIMINAR " .$unQ['id']);
				$query   = $this->db->query($sqlD,[$unQ['id']]);
				log_message('error', json_encode($query));
			    }else{
				log_message('error', "ACTUALIZAR divisa, usar el id de relacion_ctas_ctes porq esta en en query");
			    }
			}else{
			    log_message('error', "ACTUALIZAR pesos, usar el id de relacion_ctas_ctes porq esta en en query");
			}
		    }
		}
	    }else{
		////////////////// VALIDAR LOS REGISTROS Q NO FUERON DROPEADOS
		////////////////// no es necesario porq si hubo mov.creado en t1 con valores parciales de los de t2
		////////////////// ya se generaron los mov.correspondientes
	    }
	}
*/

    }



}