<form action="<?php echo base_url('index.php/chequeras/guardaRegistro') ?>" method="POST"  data-validation="valida_chequera">

	<div class="col">
		<!--<label for="frm_id">Id</label>-->
		<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_cuenta_bancaria_id">Cuenta Bancaria</label>
			<select class="custom-select" id="frm_cuenta_bancaria_id" name="frm_cuenta_bancaria_id">
			<?php foreach($cuentas_bancarias as $item){?>
				<option value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['denominacion'];?></option>
			<?php } ?>
			</select>
		</div>
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_serie">Serie</label>
			<input type="text" class="form-control" id="frm_serie" name="frm_serie" value="<?=$serie;?>" maxlength="3" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>

		<div class="col">
			<label for="frm_desde_nro">Primer N&uacute;mero</label>
			<input type="number" min="0" max="9999999999" class="form-control" id="frm_desde_nro" name="frm_desde_nro" value="<?=$desde_nro;?>" >
		</div>

		<div class="col">
			<label for="frm_hasta_nro">Ultimo N&uacute;mero</label>
			<input type="number" min="0" max="9999999999" class="form-control" id="frm_hasta_nro" name="frm_hasta_nro" value="<?=$hasta_nro;?>" >
		</div>
	</div>
	<div class="row">
		<div class="col">
			<div class="col-md-2 float-left">
			<label for="frm_echeque">Echeq</label>
			<input type="checkbox" class="form-control" id="frm_echeque"  name="frm_echeque" value="S" <?=$selected;?>  >
			</div>
			<div class="col-md-2 float-right" style="background-color:lavender;"/></div> 
		</div>
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_moneda_id">Moneda</label>
			<select class="custom-select" id="frm_moneda_id" name="frm_moneda_id">
			<?php foreach($monedas as $item){?>
				<option value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['denominacion'];?></option>
			<?php } ?>
			</select>
		</div>
		<div class="col">
			<label for="frm_fecha_solicitud">Fecha de Solicitud</label>
			<input type="date" class="form-control" id="frm_fecha_solicitud"  name="frm_fecha_solicitud" value="<?=$fecha_solicitud;?>" >
		</div>
	</div>

</form>

<script>
function valida_chequera(){
    if (Number($("#frm_desde_nro").val()) < 1){
	alert("El número inicial debe ser mayor que 0");
	$("#frm_desde_nro").focus();
	$("#frm_desde_nro").select();
    }else if (Number($("#frm_desde_nro").val()) > 999999999){
	alert("El número inicial debe ser menor que 999999999");
	$("#frm_desde_nro").focus();
	$("#frm_desde_nro").select();

    }else if (Number($("#frm_hasta_nro").val()) < 1){
	alert("El número final debe ser mayor que 0");
	$("#frm_hasta_nro").focus();
	$("#frm_hasta_nro").select();

    }else if (Number($("#frm_hasta_nro").val()) > 999999999){
	alert("El número final debe ser menor que 999999999");
	$("#frm_hasta_nro").focus();
	$("#frm_hasta_nro").select();

    }else if (Number($("#frm_hasta_nro").val()) < Number($("#frm_desde_nro").val())){
	alert("El número final debe ser mayor que el número inicial");
	$("#frm_hasta_nro").focus();
	$("#frm_hasta_nro").select();
    }else{
	return true;
    }
}
</script>



