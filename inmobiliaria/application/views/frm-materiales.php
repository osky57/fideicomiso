<form id="formmate" action="<?php echo base_url('index.php/materiales/guardaRegistro') ?>" method="POST" data-validation="valida_material">

	<div class="col">
		<!--<label for="frm_id">Id</label>-->
		<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	</div>
	<div class="row">
		<div class="col">
			<label for="frm_descripcion">Descripción</label>
			<input type="text" class="form-control" id="frm_descripcion" name="frm_descripcion" value="<?=$descripcion;?>"   maxlength="100" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
	</div>
	
	<div class="row">
		<div class="col">
			<label for="frm_unidad">Unidad</label>
			<input type="text" class="form-control" id="frm_unidad" name="frm_unidad" value="<?=$unidad;?>">
		</div>

		<div class="col">
			<label for="frm_ean13">EAN13</label>
			<input type="number" class="form-control" id="frm_ean13" name="frm_ean13" value="<?=$ean13;?>">
		</div>
	</div>
	
	<div class="row">
		<div class="col">
			<label for="frm_cant_uni_compra">Cantidad por unidad de compra</label>
			<input type="number" class="form-control" id="frm_cant_uni_compra"  name="frm_cant_uni_compra" value="<?=$cant_uni_compra;?>"/>
		</div>
		<div class="col">
			<label for="frm_peso_uni_compra">Peso por unidad de compra</label>
			<input type="number" class="form-control" id="frm_peso_uni_compra" name="frm_peso_uni_compra" value="<?=$peso_uni_compra;?>" />
		</div>
		<div class="col">
			<label for="frm_stock_minimo">Stock mínimo</label>
			<input type="number" class="form-control" id="frm_stock_minimo" name="frm_stock_minimo" value="<?=$stock_minimo;?>" />
		</div>
	</div>

<script>

function valida_material(){
	console.log('valida entidad');
	return true;
}

</script>



</form>
