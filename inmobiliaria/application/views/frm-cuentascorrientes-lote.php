<?php $id_form=uniqid();?>
<form id="<?=$id_form;?>" action="<?php echo base_url('index.php/cuentascorrientes/guardaGenCuo') ?>" method="POST"  data-validation="valida_gen_cuo">
	<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	<input type="hidden" class="form-control" id="frm_idx<?=$id_form;?>" name="frm_idx<?=$id_form;?>" value="0" >
	<div class="row mi_padd">
		<div class="col-sm-2">
			<label for="frm_fecha">Fecha Inicio</label>
			<input type="date" class="form-control" id="frm_fecha<?=$id_form;?>" name="frm_fecha">
		</div>
		<div class="col-sm-3">
			<label for="frm_periodo">Período de Cuotas</label>
			<select class="custom-select" id="frm_periodo_id<?=$id_form;?>" name="frm_periodo_id" >
				<option value="1"> Mensual      </option>
				<option value="2"> Bimestral    </option>
				<option value="3"> Trimestral   </option>
				<option value="4"> Cuatrimestral</option>
				<option value="6"> Semestral    </option>
				<option value="12"> Anual       </option>
			</select>
		</div>
		<div class="col-md-2">
			<label for="frm_cant_cuotas">Cantidad de Cuotas</label>
			<input type="number" class="form-control" min="0" max="48" id="frm_cant_cuotas<?=$id_form;?>" name="frm_cant_cuotas"> 
		</div>
		<div class="col-sm-4">
			<label for="frm_tipo_comprobante_id">Tipo Comprobante</label>
			<select class="custom-select" id="frm_tipo_comprobante_id<?=$id_form;?>" name="frm_tipo_comprobante_id">
			    <?php foreach($tiposcompr as $item){?>
				<option value="<?=$item['id'];?>|<?=$item['afecta_caja'];?>|<?=$item['tipos_entidad'];?>|<?=$item['signo'];?>|<?=$item['modelo'];?>"  <?=$item['selectado'];?> ><?=$item['descripcion'];?> </option>
			    <?php } ?>
			</select>
		</div>
	</div>
	<div class="row">


		<div class="col-md-2 form-check">
			<label for="numecuota">Numerar las cuotas</label>
			<input type="checkbox" class="form-control" id="numecuota"  name="numecuota" value="1" >
		</div>
		<div class="col-md-2">
			<label class="form-label" for="nro1cuota">Nro.1ra.Cuota</label>
			<input class="form-control" type="number" id="nro1cuota" name="nro1cuota" value="0" min="0" />
		</div>

		<div class="col-md-2">
			<label for="frm_importe">Importe de la Cuota</label>
			<input type="number" class="form-control" min="0" id="frm_importe<?=$id_form;?>" name="frm_importe" > 
		</div>
		<div class="col-md-2"> 
			<label for="frm_moneda_id">Divisa</label>
			<select class="custom-select" id="frm_moneda_id<?=$id_form;?>" name="frm_moneda_id" >
			    <?php foreach($monedas as $item){?>
				<option value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['denominacion'];?></option>
			    <?php } ?>
			</select>
		</div>
		<div class="col-md-2">
			<label for="frm_importe_divisa">Importe Divisa</label>
			<input type="number" class="form-control" min="0" id="frm_importe_divisa<?=$id_form;?>" name="frm_importe_divisa" value=<?=$cotizacion[0]['importe'];?> > 
		</div>

	</div>
	<div class="row">
		<div class="col-md-7">
		    <div class="window_scroll" id="zonaPrint" > 
			<table class="table-bordered" id="tabledetalleprop" name="tabledetalleprop">
			    <tr id="th1" style="color:black;background-color:white">
				<th style=" width:  50px;text-align: center;"  scope="col">
				    <input class = "chktodos" type="checkbox">Todos

				</th>
				<th style=" width: 250px;text-align: right;" scope="col">Entidad</th>
				<th style=" width: 500px;text-align: right;" scope="col">Propiedad</th>
			    </tr>
			    <tbody>
			    <?php foreach($proypropenti as $item){?>
				<tr id="tr_<?=$item['dptpid_eid'];?>">
				    <td><input class = "chkinversores" type="checkbox" id="chk_<?=$item['dptpid_eid'];?>" name="chk_<?=$item['dptpid_eid'];?>" value="<?=$item['dptpid_eid'];?>"></td>
				    <td><?=$item['e_razon_social'];?> (<?=$item['e_id'];?>) </td>
				    <td><?=$item['tp_descripcion'];?> - Id <?=$item['ptp_id'];?> - (<?=$item['ptp_comentario'];?>) </td>
				</tr>
			    <?php } ?>
			    </tbody>
			</table>
		    </div>
		</div>

		<div class="col-md-5">
			<label for="exampleFormControlTextarea1" class="form-label">Comentario</label>
			<textarea class="form-control" id="frm_comentario<?=$id_form;?>" name="frm_comentario" rows="3"></textarea>
		</div>

	</div>

</form>

<script>

$(document).ready(function(e) { 
    var elId     = '<?=$id_form;?>';
    var today = new Date().toISOString().split('T')[0];

    $("#frm_fecha<?=$id_form;?>").val(today);

    $("#nro1cuota").attr("disabled",true);

    $("#numecuota").on( 'change', function() {
	if( $(this).is(':checked') ) {
	    $("#nro1cuota").attr("disabled",false);
	} else {
	    $("#nro1cuota").attr("disabled",true);
	    $("#nro1cuota").val(0);
	}
    })


    $(".chktodos").on('change', function(e) {
	self = $(this);
	if(self.is(':checked')){
	    $(".chkinversores").prop('checked',true);
	}else{
	    $(".chkinversores").prop('checked',false);
	}
    });




})

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function valida_gen_cuo(){
	var lRet = true;

	if ($("#frm_fecha<?=$id_form;?>").val() == ""){
	    alert("DEBE INGRESAR UNA FECHA DE INICIO DE LAS CUOTAS!");
	    $("#frm_fecha<?=$id_form;?>").focus();
	    $("#frm_fecha<?=$id_form;?>").select();
	    lRet = false;
	}else if ($("#frm_cant_cuotas<?=$id_form;?>").val() == "" || $("#frm_cant_cuotas<?=$id_form;?>").val() <= 0){
	    alert("DEBE INGRESAR UNA CANTIDAD CORRECTA DE CUOTAS!");
	    $("#frm_cant_cuotas<?=$id_form;?>").focus();
	    $("#frm_cant_cuotas<?=$id_form;?>").select();
	    lRet = false;
	}else if ($("#frm_entidad_id<?=$id_form;?>").val() == '') {
	    alert("DEBE INDICAR AL MENOS UNA ENTIDAD!");
	    $("#frm_entidad_id<?=$id_form;?>").focus();
	    $("#frm_entidad_id<?=$id_form;?>").select();
	    lRet = false;
	}else if ($("#frm_importe<?=$id_form;?>").val() == "" || $("#frm_importe<?=$id_form;?>").val() <= 0){
	    alert("DEBE INGRESAR UN IMPORTE CORRECTO DE CUOTA!");
	    $("#frm_importe<?=$id_form;?>").focus();
	    $("#frm_importe<?=$id_form;?>").select();
	    lRet = false;
	}else if ($("#frm_importe_divisa<?=$id_form;?>").val() == "" || $("#frm_importe_divisa<?=$id_form;?>").val() <= 0){
	    alert("DEBE INGRESAR UNA COTIZACION CORRECTA DE LA DIVISA!");
	    $("#frm_importe_divisa<?=$id_form;?>").focus();
	    $("#frm_importe_divisa<?=$id_form;?>").select();
	    lRet = false;
	}else if (!confirm("ESTA SEGURO DE QUE LOS DATOS INGRESADOS SON LOS CORRECTOS?")){
	    $("#frm_fecha<?=$id_form;?>").focus();
	    $("#frm_fecha<?=$id_form;?>").select();
	    lRet = false;
	}
	return lRet;
}

</script>
