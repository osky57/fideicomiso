<form action="<?php echo base_url('index.php/cotizaciones/guardaRegistro') ?>" method="POST"  data-validation="valida_cotiza">

	<div class="col">
		<!--<label for="frm_id">Id</label>-->
		<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
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
	</div>


	<div class="row">
		<div class="col">
			<label for="frm_fecha">Fecha de la Cotización</label>
			<input type="date" class="form-control" id="frm_fecha"  name="frm_fecha" value="<?=$fecha;?>" >
		</div>
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_importe">Importe en Pesos</label>
			<input type="number" min="0" max="9999999999" class="form-control" id="frm_importe" name="frm_importe" value="<?=$importe;?>" >
		</div>
	</div>
</form>

<script>
function valida_cotiza(){
	console.log('valida cotiza');
    return true;
}
</script>

