<form action="<?php echo base_url('index.php/cuentasbancarias/guardaRegistro') ?>" method="POST"  data-validation="valida_ctas_banc">

	<div class="col">
		<!--<label for="frm_id">Id</label>-->
		<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	</div>
	<div class="row">
		<div class="col">
			<label for="frm_denominacion">Denominaci&oacute;n</label>
			<input type="text"class="form-control" id="frm_denominacion" name="frm_denominacion" value="<?=$denominacion;?>"  maxlength="80" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
	</div>
	<div class="row">
		<div class="col">
			<label for="frm_cbu">CBU</label>
			<input type="text" class="form-control" id="frm_cbu"  name="frm_cbu" value="<?=$cbu;?>"  maxlength="22" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
		<div class="col">
			<label for="frm_alias">Alias</label>
			<input type="text" class="form-control" id="frm_alias" name="frm_alias" value="<?=$alias;?>"  maxlength="20" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" /> 
		</div>
	</div>

	<div class="row">
		<div class="col">
		    <label for="frm_tipo">Tipo de Cuenta </label><br>
		    <input type="radio" id="frm_tipo" name="frm_tipo" value="C" <?=$checked1;?> >
		    <label for="frm_tipo">Cuenta Corriente&nbsp;&nbsp;&nbsp;&nbsp;    </label>
		    <input type="radio" id="frm_tipo" name="frm_tipo" value="A" <?=$checked2;?>>
		    <label for="frm_tipo">Caja de Ahorro</label><br>
		</div>
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_bancos">Banco</label>
			<select class="custom-select" id="frm_banco_id" name="frm_banco_id">
			<?php foreach($bancos as $item){?>
				<option value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['denominacion'];?></option>
			<?php } ?>
			</select>
		</div>
	</div>


</form>


<script>
function valida_ctas_banc(){
	console.log('valida ctas_banc');
    return true;
}
</script>





