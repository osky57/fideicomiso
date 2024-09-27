<?php 

    use CodeIgniter\Database\Query;
    use CodeIgniter\HTTP\RequestInterface;
    use CodeIgniter\HTTP\ResponseInterface;
    use CodeIgniter\Filters\FilterInterface;
	require_once APPPATH.'third_party/dompdf/autoload.inc.php';
	use Dompdf\Dompdf;
    //---------------------------------------------------------------------------------------------
    function wh_log($log_msg, $fileLog = null){
	$log_filename = ".";
	$log_file_data = $log_filename.'/log_' . date('d-M-Y') . '.log';
	if ($fileLog != null){
	    $log_file_data = $fileLog;
	}
	$DH =  date("Y-m-d H:i:s");
	file_put_contents($log_file_data, $DH ." ---> ".$log_msg . "\n", FILE_APPEND);
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('utf8ize')){
	function utf8ize($mixed) {
		
		if (is_array($mixed)) {
			foreach ($mixed as $key => $value) {
				$mixed[$key] = utf8ize($value);
			}
		} 
		elseif (is_string($mixed)) {
			return mb_convert_encoding($mixed, "UTF-8", "UTF-8");
		}
		//print_r($mixed);
		return $mixed;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('grabaLogDB')){
	function grabaLogDB($msg = '' ,$tipo = 1){
	    $sqlInLog = "INSERT INTO logs (tipo, comentario) VALUES ( ?, ?)";
	    $db       = \Config\Database::connect();
	    $rs       = $db->query($sqlInLog, array( $tipo, $msg));
	    return 1;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('leeLogDB')){
	function leeLogDB($limitReg = 20){
	    $db   = \Config\Database::connect();
	    $sql  = "SELECT * FROM logs ORDER BY fecha DESC LIMIT $limitReg";
	    $logs = $db->query($sql);
	    return $logs;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameLocali')){
	function dameLocali(){
	    $ci = &get_instance();
	    $ci->db->select("lo_id AS id, loca_prov AS nombre, '' AS selectado");
	    $ci->db->from("vi_localidades");
	    $ci->db->where("lo_estado = 1 ");
	    $ci->db->order_by("loca_prov");
	    $query = $ci->db->get();
	    if ($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
                    $miArray[] = array( 'id'        => $row->id,
					'nombre'    => $row->nombre,
					'selectado' => $row->selectado);
		}
		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameTipoEntiNomb')){
	function dameTipoEntiNomb($tipoId = 0){
	    $denominacion = "";
	    $ci = &get_instance();
	    $ci->db->select('denominacion');
	    $ci->db->from('tipos_entidades');
	    $ci->db->where('id  = ' . $tipoId);
	    $query = $ci->db->get();
	    if($query->num_rows() == 1)	{
		$result = $query->result();
		foreach ($result as $row){
		    $denominacion = $row->denominacion;
		}
	    }
	    return $denominacion;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameTipoEntiId')){
	function dameTipoEntiId($tipoDe = ''){
	    $tipoDe = strtoupper($tipoDe);
	    $elId   = 0;
	    $ci     = &get_instance();
	    $ci->db->select('id');
	    $ci->db->from('tipos_entidades');
	    $ci->db->where(" UPPER(denominacion) LIKE '$tipoDe%' ");
	    $query = $ci->db->get();
	    if($query->num_rows() == 1)	{
		$result = $query->result();
		foreach ($result as $row){
		    $elId = $row->id;
		}
	    }
	    return $elId;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameCtasBancarias')){
	function dameCtasBancarias($idProyecto = 0, $cTipo = '', $poneElija = 0, $proyNoHid = 0){
	    $cualProy = ($idProyecto == 0) ? "" : "AND proyecto_id = $idProyecto ";
	    $cTipo    = (empty($cTipo)) ? "" : " AND tipo = '$cTipo' ";
	    $ci       = &get_instance();
	    $ci->db->select("id, denominacion, ' ' AS selectado, proyecto_id");
	    $ci->db->from("cuentas_bancarias");
	    $ci->db->where("estado = 0 $cualProy $cTipo");
	    $ci->db->order_by("denominacion");
	    $query = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();

		if ($poneElija > 0){
		    $miArray[] = array( 'id'           => 0,
					'idproy'       => '0|0', 
					'denominacion' => 'Elija una cuenta bancaria',
					'selectado'      => '');
		}

		foreach ($result as $row){
                    $miArray[] = array( 'id'           => $row->id, 
					'idproy'       => $row->id.'|'.$row->proyecto_id, 
					'denominacion' => $row->denominacion, 
					'selectado'    => $row->selectado,
					'hidden'       => ($proyNoHid > 0) ? (($proyNoHid != $row->id) ? 'hidden':'' ):'' );  //esconde cuentas q no son del proyecto
		}
		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameMonedas')){
	function dameMonedas(){
	    $ci     = &get_instance();
	    $ci->db->select("id,denominacion,' ' AS selectado");
	    $ci->db->from("monedas");
	    $ci->db->where("estado = 0");
	    $ci->db->order_by("id");
	    $query = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
                    $miArray[] = array('id'            => $row->id, 
					'denominacion' => $row->denominacion, 
					'selectado'    => $row->selectado);
		}
		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameBancos')){
	function dameBancos(){
	    $ci     = &get_instance();
	    $ci->db->select("id,denominacion,' ' AS selectado");
	    $ci->db->from("bancos");
	    $ci->db->order_by("denominacion");
	    $query = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
                    $miArray[] = array('id'            => $row->id, 
					'denominacion' => $row->denominacion, 
					'selectado'    => $row->selectado);
		}
		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameCotizaciones')){
	function dameCotizaciones(){
	    $desde  = date("Y-m-d");
	    $desde  = date("Y-m-d",strtotime($desde." - 1 week")); 
	    $ci     = &get_instance();
	    $ci->db->select("c_id,c_fecha,m_codigo_afip,c_importe,' ' AS selectado");
	    $ci->db->from("vi_cotizaciones");
	    $ci->db->where("c_fecha <= '$desde'");
	    $ci->db->order_by("c_fecha DESC");
	    $query  = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
		    $miArray[] = array( 'c_id'          => $row->c_id, 
					'c_fecha'       => $row->c_fecha,
					'm_codigo_afip' => $row->m_codigo_afip,
					'c_importe'     => $row->c_importe,
					'selectado'     => $row->selectado);
		}
		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameCotizacion')){
	function dameCotizacion($fecha = 0, $moneda = 2)  {
	    if ($fecha === 0){
		$fecha = date("Y-m-d");
	    }
	    $ci     = &get_instance();
	    $ci->db->select("fecha,importe");
	    $ci->db->from("cotizaciones");
	    $ci->db->where("fecha <= '$fecha' AND moneda_id = $moneda ");
	    $ci->db->order_by("fecha DESC");
	    $ci->db->limit(1);
	    $query  = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
		    $miArray[] = array( 'fecha'       => $row->fecha,
					'importe'     => $row->importe);
		}
		return $miArray;
	    }
	    return 0;
	}
    }


    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameProyTiposProp')){
	function dameProyTiposProp($idProyecto = 0, $pone0 = false){
	    $ci     = &get_instance();
	    $ci->db->select("ptp_id,tp_descripcion,ptp_comentario,' ' AS selectado");
	    $ci->db->from("vi_proyectos_tipos_propiedades");
	    $ci->db->where("pr_id = $idProyecto");
	    $ci->db->order_by("tp_descripcion");
	    $query  = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		if ($pone0){
		    $miArray[] = array( 'ptp_id'         => -1, 
					'tp_descripcion' => 'Las cuotas no se aplicaran a ninguna propiedad',
					'ptp_comentario' => 'Las cuotas no se aplicaran a ninguna propiedad',
					'selectado'      => '');
		}
		foreach ($result as $row){
		    $miArray[] = array( 'ptp_id'         => $row->ptp_id, 
					'tp_descripcion' => $row->tp_descripcion,
					'ptp_comentario' => $row->ptp_comentario,
					'selectado'      => $row->selectado);
		}
		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameTiposComprob')){
	function dameTiposComprob($tipoEnti = '', $filtro = ''){

//	    if ($filtro == ''){
//		$filtro = "estado = 0 ";
//	    }else{
		$filtro = "estado = 0 $filtro ";
//	    }

	    $ci     = &get_instance();

/*
	    $ci->db->select("id,afecta_caja,abreviado,descripcion,tipos_entidad,signo,modelo,aplica_impu,' ' AS selectado");
	    $ci->db->from("tipos_comprobantes");
	    $ci->db->where("estado = 0 ")->where($filtro);
	    $ci->db->order_by("descripcion");
*/

	    $sql = "SELECT id,afecta_caja,abreviado,descripcion,tipos_entidad,signo,modelo,aplica_impu,' ' AS selectado FROM tipos_comprobantes WHERE $filtro ORDER BY descripcion";

	    $elQuery = $ci->db->query($sql);
	    $result  = $elQuery->result_array();
	    if (count($result) > 0){
		foreach ($result as $row){
		    $xx = json_decode($row['tipos_entidad']);
		    $xx = $xx->tipos_entidad;
		    if ($tipoEnti == '' || preg_match("/".$xx[0]."/i", $tipoEnti) ) {
			$miArray[] = array( 'id'            => $row['id'],
					    'descripcion'   => $row['descripcion'],
					    'afecta_caja'   => $row['afecta_caja'],
					    'abreviado'     => $row['abreviado'],
					    'tipos_entidad' => $xx[0],   //$row->tipos_entidad,
					    'signo'         => $row['signo'],
					    'modelo'        => $row['modelo'],
					    'aplica_impu'   => $row['aplica_impu'],
					    'selectado'     => $row['selectado']);
		    }
		}
		return $miArray;
	    }



/************************************ esto es para codeigniter 4, y no funca el where con los json
wh_log(json_encode($xquery->result_array()));

	    $query  = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
		    $xx = json_decode($row->tipos_entidad);
		    $xx = $xx->tipos_entidad;
		    if ($tipoEnti == '' || preg_match("/".$xx[0]."/i", $tipoEnti) ) {
			$miArray[] = array( 'id'            => $row->id,
					'descripcion'   => $row->descripcion,
					'afecta_caja'   => $row->afecta_caja,
					'abreviado'     => $row->abreviado,
					'tipos_entidad' => $xx[0],   //$row->tipos_entidad,
					'signo'         => $row->signo,
					'modelo'        => $row->modelo,
					'selectado'     => $row->selectado);
		    }
		}
		return $miArray;
	    }
*********************************/

	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameEntiProye')){
	function dameEntiProye($idProyecto = 0, $agregaProvee = null, $poneElija = 0){
	    $ci     = &get_instance();
	    $ci->db->select("e_id,e_razon_social,tipoentidad,' ' AS selectado,e_tipos_entidad");
	    $ci->db->from("vi_proyectos_entidades");
	    $ci->db->where("e_estado = 0 AND p_id = $idProyecto  ");
	    $ci->db->order_by("e_razon_social");
	    $queryEn = $ci->db->get();
	    if($queryEn->num_rows() >= 1){
		$result = $queryEn->result();
		foreach ($result as $row){
		    $xx = json_decode($row->e_tipos_entidad);
		    $xx = implode(',',$xx->tipos_entidad);
		    $miArray[] = array( 'e_id'           => $row->e_id,
					'e_razon_social' => $row->e_razon_social,
					'tipoentidad'    => $row->tipoentidad,
					'selectado'      => $row->selectado,
					'tipos_entidad'  => $xx);
		}
		if ($agregaProvee != null){
		    $ci->db->select("id AS e_id,razon_social AS e_razon_social,fun_dameTiposEntidades(id,'E') AS tipoentidad,' ' AS selectado");
		    $ci->db->from("entidades");
		    $ci->db->where("fun_buscarTiposEntidades(id,$agregaProvee) >= 1 AND estado = 0");
		    $ci->db->order_by("razon_social");
		    $queryPr = $ci->db->get();
		    if($queryPr->num_rows() >= 1){
			$result = $queryPr->result();
			foreach ($result as $row){
			    $miArray[] = array( 'e_id'           => $row->e_id,
						'e_razon_social' => $row->e_razon_social,
						'tipoentidad'    => $row->tipoentidad,
						'selectado'      => $row->selectado);
			}
		    }
		}
		usort($miArray,'sortByOption');
		if ($poneElija > 0){
		    array_unshift($miArray,array(   'e_id'           => 0,
						    'e_razon_social' => 'Elija una entidad',
						    'tipoentidad'    => '',
						    'selectado'      => '',
						    'tipos_entidad'  => '') );
		}
		return $miArray;
	    }
	    return 0;
	}
    }

    function sortByOption($a, $b){
	return strcmp($a['e_razon_social'], $b['e_razon_social']);
    }

    //el filtro debe ser por ej "array['2','1']" -> este filtro trae proveedores e inversores
    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameEntiXTipo')){
	function dameEntiXTipo($tipos = '', $idProyecto = 0, $poneElija = 0){
	    $ci     = &get_instance();
	    if ($poneElija > 0){
		$miArray[] = array( 'e_id'           => 0,
				    'e_razon_social' => 'Elija una entidad',
				    'tipoentidad'    => '',
				    'selectado'      => '',
				    'tipos_entidad'  => '');
	    }
	    if ($tipos != ''){
		    $ci->db->select("e_id,e_razon_social,fun_dameTiposEntidades(e_id,'E') AS tipoentidad,' ' AS selectado");
		    $ci->db->from("vi_entidades");
		    $cWhere = "fun_buscarTiposEntidades(e_id,$tipos) >= 1 ";
		    if ($idProyecto > 0){
			$cWhere = "fun_buscarTiposEntidades(e_id,$tipos) >= 1 AND fun_dameentidadproyecto(e_id, $idProyecto) > 0 ";
		    }
		    $ci->db->where($cWhere);
		    $ci->db->group_by(["e_id","e_razon_social","tipoentidad","selectado"]);  //esto queda a verificar
		    $ci->db->order_by("e_razon_social");
		    $queryPr = $ci->db->get();
		    if($queryPr->num_rows() >= 1){
			$result = $queryPr->result();
			foreach ($result as $row){
			    $miArray[] = array( 'e_id'           => $row->e_id,
						'e_razon_social' => $row->e_razon_social,
						'tipoentidad'    => $row->tipoentidad,
						'selectado'      => $row->selectado);
			}
		    }
		    return $miArray;
	    }
	    return 0;
	}
    }




    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameEntidad')){
	function dameEntidad($idEnti = 0){
	    $ci     = &get_instance();
	    $ci->db->select("e_id,e_razon_social,e_cuit,direccion,e_celular,e_whatsapp,e_email,local_prov,tipoentidad,e_tipos_entidad,' ' AS selectado");
	    $ci->db->from("vi_entidades");
	    $ci->db->where("e_id = $idEnti");
	    $queryEn = $ci->db->get();
	    if($queryEn->num_rows() >= 1){
		$result  = $queryEn->result_array();
		$miArray = array( 'e_id'           => $result[0]['e_id'],
				'e_razon_social' => $result[0]['e_razon_social'],
				'direccion'      => $result[0]['direccion'],
				'local_prov'     => $result[0]['local_prov'],
				'e_celular'      => $result[0]['e_celular'],
				'e_whatsapp'     => $result[0]['e_whatsapp'],
				'e_email'        => $result[0]['e_email'],
				'tipoentidad'    => $result[0]['tipoentidad'],
				'selectado'      => $result[0]['selectado'],
				'tipos_entidad'  => $result[0]['e_tipos_entidad']);

		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameTiposEnti')){
	function dameTiposEnti(){
	    $ci     = &get_instance();
	    $ci->db->select("id, denominacion,' ' AS selectado");
	    $ci->db->from("tipos_entidades");
	    $ci->db->where("estado = 0");
	    $ci->db->order_by("denominacion");
	    $query  = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
                    $miArray[] = array( 'id'           => $row->id, 
					'denominacion' => $row->denominacion,
					'selectado'    => $row->selectado);
		}
		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameTiposProy')){
	function dameTiposProy(){
	    $ci     = &get_instance();
	    $ci->db->select("id, descripcion,' ' AS selectado");
	    $ci->db->from("tipos_proyectos");
	    $query  = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
                    $miArray[] = array( 'id'          => $row->id, 
					'descripcion' => $row->descripcion,
					'selectado'   => $row->selectado);
		}
		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameTiposObras')){
	function dameTiposObras(){
	    $ci     = &get_instance();
	    $ci->db->select("id, descripcion,' ' AS selectado");
	    $ci->db->from("tipos_obras");
	    $query  = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
                    $miArray[] = array( 'id'          => $row->id, 
					'descripcion' => $row->descripcion,
					'selectado'   => $row->selectado);
		}
		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameTiposPropie')){
	function dameTiposPropie(){
	    $ci     = &get_instance();
	    $ci->db->select("id, descripcion,' ' AS selectado");
	    $ci->db->from("tipos_propiedades");
	    $ci->db->where("estado = 0");
	    $ci->db->order_by("id");
	    $query  = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
                    $miArray[] = array( 'id'          => $row->id, 
					'descripcion' => $row->descripcion,
					'selectado'   => $row->selectado);
		}
		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameMediosPago')){
	function dameMediosPago(){
	    $ci     = &get_instance();
	    $ci->db->select("id, descripcion,gestiona_cheques,gestiona_ctas_bancarias,movimiento,afec_enti,e_chq,entre_proyectos,pide_proyectos,tipo_mov,chq_a_depo
			    ,CAST(fidei_otr_s_impu AS text)||CAST(fidei_otr_c_impu AS text)||CAST(fidei_act_s_impu AS text)||CAST(fidei_act_c_impu AS text) AS validacion, ' ' AS selectado,
			    ,CAST(fidei_act_c_impu AS text)||CAST(fidei_act_s_impu AS text)||CAST(fidei_otr_c_impu AS text)||CAST(fidei_otr_s_impu AS text) AS validacion2");
	    $ci->db->from("tipos_movimientos_caja");
	    $ci->db->where("estado = 0");
	    $ci->db->order_by("orden,id");
	    $query  = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
                    $miArray[] = array( 'id'              => $row->id, 
					'descripcion'     => $row->descripcion,
					'selectado'       => $row->selectado,
					'gest_chq'        => $row->gestiona_cheques,
					'gest_cta_bca'    => $row->gestiona_ctas_bancarias,
					'movimiento'      => $row->movimiento,
					'afec_enti'       => $row->afec_enti,
					'e_chq'           => $row->e_chq,
					'id_gchq_gctab'   => $row->id."|".
							     $row->gestiona_cheques."|".
							     $row->gestiona_ctas_bancarias."|".
							     $row->movimiento."|".
							     $row->afec_enti."|".
							     $row->e_chq."|".
							     $row->entre_proyectos."|".
							     $row->pide_proyectos."|".
							     $row->tipo_mov."|".
							     bindec($row->validacion)."|".
							     $row->validacion2."|".
							     $row->chq_a_depo );
		}
/*

tipo_mov:
0-> no utilizados
1-> efectivo
2-> chq 3ro
3-> echq 3ro
4-> chq propio
5-> echq propio
6-> cobro/pago por banco
7-> gastos bancarios
8-> retenciones
9-> canje

*/
		return $miArray;
	    }
	    return 0;
	}
    }


    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameMediosBanco')){
	function dameMediosBanco(){
	    $ci     = &get_instance();
	    $ci->db->select("id, descripcion,gestiona_cheques,gestiona_ctas_bancarias,movimiento,afec_enti,e_chq,gestiona_banco,mov_en_banco,' ' AS selectado");
	    $ci->db->from("tipos_movimientos_caja");
	    $ci->db->where(" mov_en_banco = 6");  //solo muestro gastos bancarios
	    $ci->db->order_by("orden");
	    $query  = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){

		    if ($row->id == 9){
			$row->descripcion .= " depósito";
		    }

                    $miArray[] = array( 'id'              => $row->id, 
					'descripcion'     => $row->descripcion,
					'selectado'       => $row->selectado,
					'gest_chq'        => $row->gestiona_cheques,
					'gest_cta_bca'    => $row->gestiona_ctas_bancarias,
					'movimiento'      => $row->movimiento,
					'afec_enti'       => $row->afec_enti,
					'e_chq'           => $row->e_chq,
					'gestiona_banco'  => $row->gestiona_banco,
					'mov_en_banco'    => $row->mov_en_banco,
					'id_gchq_gctab'   => $row->id."|".
							     $row->gestiona_cheques."|".
							     $row->gestiona_ctas_bancarias."|".
							     $row->movimiento."|".
							     $row->afec_enti."|".
							     $row->e_chq."|".
							     $row->gestiona_banco."|".
							     $row->mov_en_banco);
		}

		return $miArray;
	    }
	    return 0;
	}
    }


    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameMediosInternos')){
	function dameMediosInternos(){
	    $ci     = &get_instance();
	    $ci->db->select("id, descripcion,gestiona_cheques,gestiona_ctas_bancarias,movimiento,afec_enti,e_chq,gestiona_banco,mov_en_banco,' ' AS selectado");
	    $ci->db->from("tipos_movimientos_caja");
	    $ci->db->where(" mov_internos = 1");  //estado = 1 AND
	    $ci->db->order_by("orden");
	    $query  = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
		    $miArray[] = array( 'id'              => $row->id, 
					'descripcion'     => $row->descripcion,
					'selectado'       => $row->selectado,
					'gest_chq'        => $row->gestiona_cheques,
					'gest_cta_bca'    => $row->gestiona_ctas_bancarias,
					'movimiento'      => $row->movimiento,
					'afec_enti'       => $row->afec_enti,
					'e_chq'           => $row->e_chq,
					'gestiona_banco'  => $row->gestiona_banco,
					'mov_en_banco'    => $row->mov_en_banco,
					'id_gchq_gctab'   => $row->id."|".
							     $row->gestiona_cheques."|".
							     $row->gestiona_ctas_bancarias."|".
							     $row->movimiento."|".
							     $row->afec_enti."|".
							     $row->e_chq."|".
							     $row->gestiona_banco."|".
							     $row->mov_en_banco);

		}

		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameChqsCartera')){
	function dameChqsCartera($idProy = 0, $eChq, $aDepo = 0){
//	    $qWhe   = '';
	    $elProy = $idProy > 0 ? "AND cc_proyecto_id = $idProy " : "";
	    $ci     = &get_instance();

	    $qSel   = "mo1_simbolo|| ccc_importe::text||' '||RPAD(ba2_denominacion,20)||' '||ccc_serie||ccc_numero::text||' ('||ccc_cartel_a_depo||') '||ccc_fecha_acreditacion::text||' Proy '||RPAD(pr_nombre,18) AS chq
			    ,ccc_id,ccc_cuenta_corriente_id,' ' AS selectado, ccc_importe, ccc_moneda_id 
			    ,ccc_importe_divisa,ccc_e_chq,tmc_e_chq,ccc_chq_a_depo,cc_proyecto_id ";
	    $ci->db->select($qSel);
	    $ci->db->from("vi_ctas_ctes_caja");

	    $qWhe = "   ccc_cta_cte_caja_origen_id IS NULL 
		    AND tmc_gestiona_cheques = 1 
		    AND tmc_gestiona_ctas_bancarias = 0 
		    $elProy 
		    AND ccc_e_chq = $eChq 
		    AND fun_chq_asignado(ccc_id) = 0 ";


	    if ($aDepo == 0){       //todos los chqs de un proy o de todos
/*
		$qWhe = "ccc_cta_cte_caja_origen_id IS NULL 
				AND tmc_gestiona_cheques = 1 
				AND tmc_gestiona_ctas_bancarias = 0 
				$elProy
				AND ccc_e_chq = $eChq 
				AND fun_chq_asignado(ccc_id) = 0 ";
*/
	    }else if ($aDepo == 1){ //solo chqs a depo.del proy.corriente
/*
		$qWhe = "ccc_cta_cte_caja_origen_id IS NULL 
				AND tmc_gestiona_cheques = 1 
				AND tmc_gestiona_ctas_bancarias = 0 
				$elProy
				AND ccc_e_chq = $eChq 
				AND fun_chq_asignado(ccc_id) = 0 
*/
		$qWhe .= "	AND COALESCE(ccc_chq_a_depo,0) = 1
				AND ccc_fecha_depositado IS NULL ";

	    }else if ($aDepo == 2){ //todos los chqs3ros. y los a depo del proy.corriente
/*
		$qWhe = "ccc_cta_cte_caja_origen_id IS NULL 
				AND tmc_gestiona_cheques = 1
				AND tmc_gestiona_ctas_bancarias = 0
				AND ccc_e_chq = $eChq 
				AND fun_chq_asignado(ccc_id) = 0
				AND ((ccc_chq_a_depo = 1 AND cc_proyecto_id = $idProy ) OR ccc_chq_a_depo IS NULL)
				AND ccc_fecha_depositado IS NULL ";
*/
		$qWhe .= "	AND ccc_fecha_depositado IS NULL ";

	    }else if ($aDepo == 3){ //todos los chqs3ros. NO A DEPO
/*
		$qWhe = "ccc_cta_cte_caja_origen_id IS NULL 
			AND tmc_gestiona_cheques = 1
			AND tmc_gestiona_ctas_bancarias = 0
			AND ccc_e_chq = $eChq 
			AND fun_chq_asignado(ccc_id) = 0
			AND (ccc_chq_a_depo IS NULL OR ccc_chq_a_depo = 0)
			AND cc_proyecto_id = $idProy
			AND ccc_fecha_depositado IS NULL ";
*/
		$qWhe .= "AND COALESCE(ccc_chq_a_depo,0) = 0 
			AND ccc_fecha_depositado IS NULL ";

	    }

	    $qWhe = preg_replace("/[\n|\t]+/"," ",$qWhe);
	    $ci->db->where($qWhe);
	    $ci->db->order_by("ccc_fecha_acreditacion");
	    $query = $ci->db->get();

	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
		    $aDd = $row->ccc_chq_a_depo == '' ?'0' : $row->ccc_chq_a_depo;
		    $miArray[] = array( 'ccc_id'                  => $row->ccc_id, 				//0
					'ccc_cuenta_corriente_id' => $row->ccc_cuenta_corriente_id,		//1
					'chq'                     => $row->chq,					//2
					'selectado'               => $row->selectado,				//3
					'caja_ctacte'             => $row->ccc_id."|".				//4 0
								     $row->ccc_cuenta_corriente_id."|".		//5 1
								     $row->ccc_moneda_id."|".			//4 2
								     $row->ccc_importe."|".			//4 3
								     $row->ccc_importe_divisa."|".		//4 4
								     $aDd."|".					//4 5
								     $row->cc_proyecto_id,			//4 6
					'proyecto'                => $row->cc_proyecto_id);			//5
		}


wh_log(json_encode($miArray));

		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameChequeras')){
	function dameChequeras($idProy, $eChq = null, $allCtas = 0){
	    $ci     = &get_instance();
	    $selx   = "cb_denominacion||' Nro.'|| numeracion ||' Mone.'|| mo_denominacion AS chq
			    ,ch_id,ch_cuenta_bancaria_id,' ' AS selectado, ch_moneda_id
			    ,ch_serie, ch_desde_nro,ch_hasta_nro,echeq,ultimo_emitido,cb_banco_id ";
	    $esNull = " = '$eChq'";
	    if ($eChq == null){
		$esNull = " IS NULL";
	    }
	    $ci->db->select($selx);
	    $ci->db->from("vi_chequeras");

	    $elProy = " ";
	    if ($allCtas == 0){
		$elProy = " AND cb_proyecto_id = $idProy ";
	    }elseif($allCtas == 1){
		" AND cb_proyecto_id <> $idProy ";
	    }

	    $whex = "ultimo_emitido IS NOT NULL
			    AND ch_estado = 0 
			    $elProy 
			    AND ch_echeque $esNull  ";
	    $ci->db->where($whex);
	    $query  = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
                    $miArray[] = array( 'chq'                     => $row->chq,				//0
					'ch_id'                   => $row->ch_id,			//1
					'ch_cuenta_bancaria_id'   => $row->ch_cuenta_bancaria_id,	//2
					'selectado'               => $row->selectado,			//3
					'ch_moneda_id'            => $row->ch_moneda_id,		//4
					'ch_serie'                => $row->ch_serie,			//5
					'ch_desde_nro'            => $row->ch_desde_nro,		//6
					'ch_hasta_nro'            => $row->ch_hasta_nro,		//7
					'echeq'                   => $row->echeq,			//8
					'ultimo_emitido'          => $row->ultimo_emitido,		//9
					'valor'                   => $row->ch_id.'|'.				//0
								     $row->ch_cuenta_bancaria_id.'|'.		//1
								     $row->ch_serie.'|'.			//2
								     $row->ch_desde_nro.'|'.			//3
								     $row->ch_hasta_nro.'|'.			//4
								     ($row->ultimo_emitido + 1).'|'.		//5
								     $row->cb_banco_id );		//10	//6
		}

//wh_log(json_encode($miArray));


		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameConceptoComprob')){
	function dameConceptoComprob($orden = 0){
	    $ci     = &get_instance();
	    class MiObjC{
		public $id;
		public $descripcion;
		public $selectado;

		public function __construct($id, $descripcion, $selectado){
		    $this->id          = $id;
		    $this->descripcion = $descripcion;
		    $this->selectado   = $selectado;
		}
	    }
	    //para acceder a los campos:  $conceptos[$i]->selectado
	    $ci->db->select("id,descripcion");
	    $ci->db->from("conceptos");
	    $ci->db->order_by($orden == 0 ? "id" : "orden");
	    $query  = $ci->db->get();
	    if($query->num_rows() >= 1){
		$result = $query->result();
		foreach ($result as $row){
		    $conceptos[] = new miObjC( $row->id, $row->descripcion, ' ');
		}
	    }
	    return $conceptos;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameModeloComprob')){
	function dameModeloComprob(){
	    class MiObjM{
		public $id;
		public $descripcion;
		public $selectado;

		public function __construct($id, $descripcion, $selectado){
		    $this->id          = $id;
		    $this->descripcion = $descripcion;
		    $this->selectado   = $selectado;
		}
	    }
	    //para acceder a los campos:  $modelos[$i]->selectado
	    $modelos[] = new miObjM( '1', 'FACTURA'   , ' ');
	    $modelos[] = new miObjM( '2', 'N.DEBITO'  , ' ');
	    $modelos[] = new miObjM( '3', 'N.CREDITO' , ' ');
	    $modelos[] = new miObjM( '4', 'RECIBO'    , ' ');
	    $modelos[] = new miObjM( '5', 'ORDEN PAGO', ' ');
	    return $modelos;
	}
    }


/*
inversionista   -> recibo    -> recupera -> factura, n.debito      enti 1 modelo comprob 4, recupera modelo 1 y 2
                -> n.credito -> recupera -> factura, n.debito      enti 1 modelo comprob 3, recupera modelo 1 y 2
proveedor       -> o/p       -> recupera -> factura, n.debito      enti 2 modelo comprob 5, recupera modelo 1 y 2
		-> n.credito -> recupera -> factura, n.debito      enti 2 modelo comprob 5, recupera modelo 1 y 2
prestamista     -> recibo    -> recupera -> factura, n.debito      enti 3 modelo comprob 4, recupera modelo 1 y 2
                -> n.credito -> recupera -> factura, n.debito      enti 3 modelo comprob 3, recupera modelo 1 y 2
*/



    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameProyPropEnti')){
	function dameProyPropEnti($idProy = 0, $idPropie = 0, $idEnti = 0, $coef = 0){
	    $ci     = &get_instance();
	    if ($idProy > 0){
		$elWhere = " pr_id = $idProy AND dptp_estado = 0 AND e_estado = 0 ";
		if ($idPropie > 0){
		    $elWhere .= " AND ptp_id = $idPropie ";
		}
		if ($idEnti > 0){
		    $elWhere .= " AND e_id = $idEnti ";
		}
		if ($coef > 0){
		    $elWhere .= " AND dptp_coeficiente > 0 ";
		}
		$selx    = "pr_id, ptp_id, e_id, dptp_coeficiente, ' ' AS selectado, tp_descripcion,
			    e_razon_social, ptp_comentario, tpr_descripcion, tpr_id, tp_id,
			    dptp_id::text||'|'|| e_id::text||'|'|| ptp_coeficiente::text AS dptpid_eid ";
		$ci->db->select($selx);
		$ci->db->from("vi_detalle_proyectos_tipos_propiedades");
		$ci->db->where($elWhere);
		$ci->db->order_by("e_razon_social ASC , e_id ASC, ptp_comentario ASC");
		$query  = $ci->db->get();
		if($query->num_rows() >= 1){
		    $result = $query->result();
		    foreach ($result as $row){
			$miArray[] = array( 'pr_id'            =>  $row->pr_id,
					    'ptp_id'           =>  $row->ptp_id,
					    'e_id'             =>  $row->e_id,
					    'dptp_coeficiente' =>  $row->dptp_coeficiente,
					    'dptp_id'          =>  $row->dptp_id,
					    'dptpid_eid'       =>  $row->dptpid_eid,
					    'selectado'        =>  $row->selectado,
					    'tp_descripcion'   =>  $row->tp_descripcion,
					    'e_razon_social'   =>  $row->e_razon_social,
					    'ptp_comentario'   =>  $row->ptp_comentario,
					    'tpr_descripcion'  =>  $row->tpr_descripcion,
					    'tpr_id'           =>  $row->tpr_id,
					    'tp_id'            =>  $row->tp_id,
					    'ptp_coeficiente'  =>  $row->ptp_coeficiente  );
		    }
		    return $miArray;
		}
	    }
	    return 0;
	}
    }


    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameCompCSaldo')){
	function dameCompCSaldo($idProy = 0, $idEnti = 0){
	    $ci  = &get_instance();
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
		    left join relacion_ctas_ctes rcc on vcc.cc_id = rcc.cuenta_corriente_id
		    left join vi_ctas_ctes ccc on rcc.relacion_id = ccc.cc_id
		    WHERE vcc.cc_entidad_id = $idEnti
		    AND vcc.cc_proyecto_id = $idProy
		    AND vcc.tc_modelo IN (1,2)
		    AND rcc.estado = 0
		    ORDER BY vcc.cc_fecha, vcc.cc_id";
	    $query      = $ci->db->query($sql);
	    $queryR     = $query->result_array();
	    if (count($queryR)>0){
		for($i = 0 ; $i < count($queryR) ; $i++){
		    $miArray[] = array( "vcc_cc_id"        => $queryR[$i]['vcc_cc_id'],
					"vcc_cc_fecha_dmy" => $queryR[$i]['vcc_cc_fecha_dmy'],
					"comprob_deb"      => $queryR[$i]['comprob_deb'],
					"importe_mn"       => $queryR[$i]['importe_mn'],
					"importe_div"      => $queryR[$i]['importe_div']);
		}
		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameParaApli')){
	function dameParaApli($idProy = 0, $idEnti = 0){
	    $ci  = &get_instance();
	    $sql = "SELECT    vcc.cc_id  AS vcc_cc_id
			    , vcc.cc_fecha_dmy AS vcc_cc_fecha_dmy
			    , comp_nume
			    , saldopesos
			    , saldodolar
		    FROM vi_ctas_ctes vcc
		    WHERE vcc.cc_entidad_id = $idEnti
		    AND vcc.cc_proyecto_id = $idProy
		    AND vcc.tc_modelo NOT IN (1,2)
		    AND vcc.cc_estado = 0
		    AND (fun_comprobsinaplicar(vcc.cc_id,1)>0 OR fun_comprobsinaplicar(vcc.cc_id,2)>0)
		    ORDER BY vcc.cc_fecha, vcc.cc_id";
	    $query      = $ci->db->query($sql);
	    $queryR     = $query->result_array();
	    if (count($queryR)>0){
		for($i = 0 ; $i < count($queryR) ; $i++){
		    $miArray[] = array( "vcc_cc_id"        => $queryR[$i]['vcc_cc_id'],
					"vcc_cc_fecha_dmy" => $queryR[$i]['vcc_cc_fecha_dmy'],
					"comp_nume"        => $queryR[$i]['comp_nume'],
					"saldopesos"       => $queryR[$i]['saldopesos'],
					"saldodolar"       => $queryR[$i]['saldodolar']);
		}
		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameProyecto')){
	function dameProyecto($idProy = 0, $excluye = 0){
	    $iguDis = ($excluye == 0) ? '=': '<>';
	    $ci  = &get_instance();
	    $sql = "SELECT *
		    FROM vi_proyectos
		    WHERE p_id $iguDis $idProy";
	    $query  = $ci->db->query($sql);
	    $queryR = $query->result_array();
	    if (count($queryR)>0){
		if ($excluye < 2){
		    return $queryR[0];
		}else{
		    for($i = 0 ; $i < count($queryR) ; $i++){
			$miArray[] = array( "p_id"     => $queryR[$i]['p_id'],
					    "p_nombre" => $queryR[$i]['p_nombre']);
		    }
		    return $miArray;
		}
	    }
	    return 0;
	}
    }


    //---------------------------------------------------------------------------------------------
    //devuelve proyectos q no estan indicados como entidades
    if (!function_exists('dameProyectoNoEnti')){
	function dameProyectoNoEnti($entiId = 0, $poneVacio = 0){
	    $ci  = &get_instance();

	    $sql = "SELECT pr.id AS p_id,pr.nombre AS p_nombre, '' AS noes
		    FROM proyectos pr
		    LEFT JOIN entidades en ON pr.id = en.proyecto_id
		    WHERE pr.estado = 0
		      AND en.id IS NULL ";
	    if ($entiId != 0){
		$sql .= "UNION
			SELECT pr.id AS p_id,pr.nombre AS p_nombre, 'selected' AS noes
			FROM proyectos pr
			LEFT JOIN entidades en ON pr.id = en.proyecto_id
			WHERE pr.estado = 0
			  AND en.id = $entiId ";
	    }
	    $sql .= "ORDER BY 1";
wh_log($sql);
	    $query  = $ci->db->query($sql);
	    $queryR = $query->result_array();

	    $miArray[] = array( "p_id"     => 0,
				"p_nombre" => "No indica proyecto",
				"noes"     => "");

	    if (count($queryR)>0){
		for($i = 0 ; $i < count($queryR) ; $i++){
		    $miArray[] = array( "p_id"     => $queryR[$i]['p_id'],
					"p_nombre" => $queryR[$i]['p_nombre'],
					"noes"     => $queryR[$i]['noes']);
		}
wh_log(json_encode($miArray));
		return $miArray;
	    }
	    return 0;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameProxNumeTal')){
	function dameProxNumeTal($tipoCom){
	    $ci       = &get_instance();
	    $sql      = "UPDATE tipos_comprobantes SET numero = numero + 1 WHERE id = ".$tipoCom."  RETURNING numero";
	    $query    = $ci->db->query($sql);
	    $queryNro = $query->result_array();
	    return $queryNro[0]['numero'];
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('damePresupuesto')){
	function damePresupuesto($idEnti = 0,$tipoDato = 0){
	    $ci       = &get_instance();

	    $sql      = "SELECT pre_id
				,pre_titulo
				,pre_comentario
				,pre_importe_inicial
				,mo_id
				,mo_denominacion
				,pre_fecha_inicio
				,e_razon_social
				,pro_id
				,pro_nombre
				,cant_cc
			FROM vi_presupuestos
			WHERE e_id = ? ORDER BY pre_id";

	    $query    = $ci->db->query($sql,array($idEnti));
	    $queryR   = $query->result_array();
	    if ($tipoDato == 1 || $tipoDato == 3){   //poner cartel al principio
		$regVacio = array(   "pre_id"           => "0"
				    ,"pre_titulo"       => "Presupuestos del proveedor"
				    ,"pre_comentario"   => ""
				    ,"pre_importe_inicial" => "0"
				    ,"mo_id"            => "0"
				    ,"mo_denominacion"  => ""
				    ,"pre_fecha_inicio" => ""
				    ,"e_razon_social"   => ""
				    ,"pro_id"           => "0"
				    ,"pro_nombre"       => ""
				    ,"cant_cc"          => "0" );
		array_unshift($queryR,$regVacio);
	    }
wh_log(json_encode($queryR));
	    return $queryR;
	}
    }

    //---------------------------------------------------------------------------------------------
    if (!function_exists('dameInfoComp')){
	function dameInfoComp($compId,$idFROp = 0,$filtTipoEnti = 1){
	    $ci   = &get_instance();
	    if ($idFROp == 1){  //$compId es el id en la tabla cuentas_corrientes_caja, hay q recuperar el campo cuenta_corriente_id
		$query = $ci->db->query("SELECT cuenta_corriente_id FROM cuentas_corrientes_caja WHERE id = $compId LIMIT 1");
		$row = $query->row();
		$compId = $row->cuenta_corriente_id;
	    }
	    $sqlC = "SELECT cc_id, tc_abreviado|| ' Nro.' || cc_numero::text AS tc_num, cc_fecha_dmy, 
			cc_entidad_id, e_razon_social,e_celular, local_prov, e_observaciones, 
			p_nombre, debe_txt_mn_tot,cc_importe, cc_moneda_id, cc_importe_divisa,
			u_nombre, cc_fecha_registro,ptp_comentario, ptp_coeficiente, tp_descripcion,
			ccc_comentario , tc_modelo,
			debe_txt_mn_tot, 
			haber_txt_mn_tot,
			debe_txt_div_tot, 
			haber_txt_div_tot,
			to_char(coalesce(debe_mn_tot,0)  + coalesce(haber_mn_tot,0) , '999,999,999,999D99') AS totalMNx,
			to_char(coalesce(debe_div_tot,0) + coalesce(haber_div_tot,0), '999,999,999,999D99') AS totalDIVx,
			coalesce(debe_mn_tot,0)  + coalesce(haber_mn_tot,0) AS totalMN,
			coalesce(debe_div_tot,0) + coalesce(haber_div_tot,0) AS totalDIV,
			fun_comprobsinaplicar(cc_id) AS sinaplicar, 
			fun_comprobsaldo(cc_id)      AS saldocomprob
		FROM vi_ctas_ctes WHERE cc_id = ?";
	    wh_log('sqlC-------------dameInfoComp------------------------------------------');
	    wh_log($sqlC);
	    wh_log($compId);
	    $query          = $ci->db->query($sqlC,[$compId]);
	    $query          = $query->result_array();
	    $ret['comprob'] = $query[0];

	    $sqlP = "SELECT  to_char(ccc_importe, '999,999,999,999D99') AS ccc_importex
			,ccc_importe
			,ccc_importe_divisa
			,mo1_denominacion
			,mo1_simbolo, tmc_descripcion, ccc_comentario,ccc_id
			,ba2_denominacion, to_char(ccc_fecha_emision,'dd-mm-yyyy') AS ccc_f_emi_dmy
			,to_char(ccc_fecha_acreditacion,'dd-mm-yyyy') AS ccc_f_acre_dmy
			,ccc_serie||' '||LPAD(ccc_numero::text,8,'0')||' ('||ccc_cartel_a_depo||')' AS serienroX
			,cb_denominacion 
			,COALESCE(ba3_denominacion,ba2_denominacion) AS banco
			,CASE WHEN ccc_numero IS NOT NULL THEN ccc_serie||LPAD(ccc_numero::text,8,'0')||' ('||ccc_cartel_a_depo||')'
			      WHEN ccch_numero IS NOT NULL THEN ccch_serie||LPAD(ccch_numero::text,8,'0')||' ('||ccch_cartel_a_depo||')' 
			 END AS serienro
			,to_char(COALESCE(ccch_fecha_emision,ccc_fecha_emision),'dd-mm-yyyy') AS f_emision
			,to_char(COALESCE(ccch_fecha_acreditacion,ccc_fecha_acreditacion),'dd-mm-yyyy') AS f_acreditacion
		FROM vi_ctas_ctes_caja WHERE ccc_cuenta_corriente_id = ?";
	    wh_log('sqlP-------------dameInfoComp-----------------------------------------------');
	    wh_log($sqlP);
	    wh_log($compId);
	    $query          = $ci->db->query($sqlP,[$compId]);
	    $query          = $query->result_array();
	    $ret['pagos']   = $query;

	    $ret['modelo']  = $ret['comprob']['tc_modelo'];
	    $c12            = strstr('453',$ret['comprob']['tc_modelo']) !== false ? '2' : '1';
	    $c21            = strstr('453',$ret['comprob']['tc_modelo']) !== false ? '1' : '2';

	    if ($filtTipoEnti == 3 && $ret['comprob']['tc_modelo'] != 5){   // para hacer efectivo q se vean bien los comprob con prestamistas
		$c12            = '1';   //strstr('453',$ret['comprob']['tc_modelo']) !== false ? '2' : '1';
		$c21            = '2';   //strstr('453',$ret['comprob']['tc_modelo']) !== false ? '1' : '2';
	    }

	    $sqlA           = "SELECT * FROM vi_aplicaciones_ctas_ctes WHERE cc".$c12."_id = ".$compId;
	    $query          = $ci->db->query($sqlA);
	    wh_log('sqlA-------------dameInfoComp-----------------------------------------------');
	    wh_log($sqlA);
	    $query          = $query->result_array();
	    $todosQ         = array();
	    foreach($query as $unQ){
		$todosQ[]   = array('comentario' => $unQ["pr".$c21."_nombre"]." ".$unQ["cc".$c21."_comentario"],   //nombre proyecto + comentario
				'fecha'      => $unQ["cc".$c21."_fecha"],
				'fecha_dmy'  => $unQ["cc".$c21."_fecha_dmy"],
				'id'         => $unQ["cc".$c21."_id"],
				'comp_nume'  => $unQ["comp".$c21."_nume"],
				'rcc_monto_divisa' => $unQ['rcc_monto_divisa'],
				'rcc_monto_pesos'  => $unQ['rcc_monto_pesos']);
	    }
	    $ret['aplicaciones'] = $todosQ;
	    wh_log(json_encode($ret));
	    return $ret;
	}
    }






    //---------------------------------------------------------------------------------------------
    if (!function_exists('validaApliOP')){
	function validaApliOP($Id1,$Id2){
	    $ci   = &get_instance();
	    $sqlC = "SELECT * FROM vi_ctas_ctes WHERE cc_id = ?";
	    $query          = $ci->db->query($sqlC,[$Id1]);
	    $query          = $query->result_array();
	    $comprobId1     = $query[0];
	    wh_log("proyecto " . $comprobId1['cc_proyecto_id'] );
	    wh_log("aplica impu " . $comprobId1['tc_aplica_impu']);
	    $sqlP = "SELECT * FROM vi_ctas_ctes_caja WHERE ccc_cuenta_corriente_id = ?";
	    $query          = $ci->db->query($sqlP,[$Id2]);
	    $query          = $query->result_array();
	    $lRet           = 1;
	    foreach($query as $unPa){
		wh_log("proy ori  " . $unPa['cc_proyecto_origen_id']);
		wh_log("fidei act c " . $unPa['tmc_fidei_act_c_impu']);
		wh_log("fidei act s " . $unPa['tmc_fidei_act_s_impu']);
		wh_log("fidei otr c " . $unPa['tmc_fidei_otr_c_impu']);
		wh_log("fidei otr s " . $unPa['tmc_fidei_otr_s_impu']);

		//el proyecto de la fact. == al proyecto orig. de la o/p
		if ($comprobId1['cc_proyecto_id'] == $unPa['cc_proyecto_origen_id']){
		    if ($comprobId1['tc_aplica_impu'] == 1){ //aplica impues
			if ($unPa['tmc_fidei_act_c_impu'] == 0){
			    $lRet = 0;
			    break;
			}
		    }else{ //no aplica impues
			if ($unPa['tmc_fidei_act_s_impu'] == 0){
			    $lRet = 0;
			    break;
			}
		    }
		}else{ //el proyecto de la fact. != al proyecto orig. de la o/p

		    if ($comprobId1['tc_aplica_impu'] == 1){ //aplica impues
			if ($unPa['tmc_fidei_otr_c_impu'] == 0){
			    $lRet = 0;
			    break;
			}
		    }else{ //no aplica impues
			if ($unPa['tmc_fidei_otr_s_impu'] == 0){
			    $lRet = 0;
			    break;
			}
		    }
		}
	    }

	    return $lRet;

	}
    }


	//---------------------------------------------------------------------------------------------
	
    if ( ! function_exists('generate_pdf')){
	function generate_pdf($html, $filename='', $data) {
	    $dompdf = new Dompdf();
	    $dompdf->loadHtml($html);
	    $dompdf->setPaper('A4', 'portrait');
	    $dompdf->render();
	    $output = $dompdf->output();
	    $pdfFilePath = $filename . '.pdf';
	    file_put_contents($pdfFilePath, $output);
	    return true;
	}
    }










