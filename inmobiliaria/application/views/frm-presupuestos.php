<form id="formenti" action="<?php echo base_url('index.php/presupuestos/guardaRegistro') ?>" method="POST" data-validation="valida_presu">
	<div class="row">
		<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
		<input type="hidden" readonly class="form-control" id="frm_entidad_id" name="frm_entidad_id" value="<?=$frm_entidad_id;?>" >
	</div>

	<div class="row">
		<div class="col-md-4">
			<label for="frm_fecha_inicio">Fecha</label>
			<input type="date" class="form-control" id="frm_fecha_inicio" name="frm_fecha_inicio" value="<?=$fecha_inicio;?>"/>
		</div>
		<div class="col-md-8">
			<label for="frm_descripcion">Descripción</label>
			<input type="text" class="form-control" id="frm_descripcion"  name="frm_descripcion" value="<?=$titulo;?>"  maxlength="100" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
	</div>

	<div class="row">
		<div class="col col-md-4">
			<label for="frm_importe_inicial">Importe</label>
			<input type="number" class="form-control" id="frm_importe_inicial" name="frm_importe_inicial" value="<?=$importe_inicial;?>"/>
		</div>

		<div class="col-md-8"> 
			<label for="frm_moneda_id">Divisa</label>
			<select class="custom-select" id="frm_moneda_id<?=$id_form;?>" name="frm_moneda_id">
			    <?php foreach($monedas as $item){?>
				<option value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['denominacion'];?></option>
			    <?php } ?>
			</select>
		</div>

	</div>

	<div class="row">
		<div class="col">
			<label for="frm_comentario" class="form-label">Observaciones</label>
			<textarea class="form-control" id="frm_comentario" name="frm_comentario" rows="5"><?=$comentario;?></textarea>
		</div>
	</div>

<script>


$(document).ready(function(){

});

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function valida_presu(){
	var lRet        = true;
	var nId         = '<?=$id_form;?>';
	var dFechaIni   = $("#frm_fecha_inicio").val();
	var nImporteIni = $("#frm_importe_inicial").val();
debugger;
	if (dFechaIni == ""){
	    alert("Debe indicar una fecha");
	    lRet = false;
	    $("#frm_fecha_inicio").focus();
	    $("#frm_fecha_inicio").select();
	    return false;
	}
	if (nImporteIni == ""){
	    alert("Debe indicar un importe");
	    lRet = false;
	    $("#frm_importe_inicial").focus();
	    $("#frm_importe_inicial").select();
	    return false;
	}
	return lRet;
}

</script>

</form>
