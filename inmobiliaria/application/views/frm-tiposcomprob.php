<form action="<?php echo base_url('index.php/tiposcomprob/guardaRegistro') ?>" method="POST"  data-validation="valida_tipos_comp">

	<div class="col">
		<!--<label for="frm_id">Id</label>-->
		<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	</div>
	<div class="row">
		<div class="col">
			<label for="frm_descripcion">Descripci&oacute;n</label>
			<input type="text"class="form-control" id="frm_descripcion" name="frm_descripcion" value="<?=$descripcion;?>"  maxlength="50" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
		<div class="col">
			<label for="frm_abreviado">Nombre Abreviado</label>
			<input type="text" class="form-control" id="frm_abreviado" name="frm_abreviado" value="<?=$abreviado;?>"  maxlength="25" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
		<div class="col">
			<label for="frm_concepto">Concepto afectado</label>
			<select class="custom-select" id="frm_concepto" name="frm_concepto">
			<?php foreach($concepto_arr as $item){?>
				<option value="<?=$item->id;?>"  <?=$item->selectado;?> ><?=$item->descripcion;?></option>
			<?php } ?>
			</select>
		</div>
	</div>
	<div class="row">
		<div class="col-md-4 ">
		    <label for="frm_signo"  class="col-auto col-form-label">Donde afecta la operaci&oacute;n     </label><br>
		    <input type="radio" id="frm_signo" name="frm_signo" value="1" <?=$checked1;?> >
		    <label for="frm_signo">Debe &nbsp;&nbsp;&nbsp;    </label>
		    <input type="radio" id="frm_signo" name="frm_signo" value="-1" <?=$checked2;?>>
		    <label for="frm_signo">Haber</label><br>
		</div>
		<div class="col-md-4 ">
		    <div class="row align-items-center">
			<label for="frm_afecta_caja"  class="col-auto col-form-label">Afecta Caja</label>
			<input type="checkbox" class="form-control" id="frm_afecta_caja"  name="frm_afecta_caja" value="1" <?=$afecta_caja;?>  >
		    </div> 
<!--			<div class="col-md-2 float-right" style="background-color:lavender;"/></div> -->
		</div>
		<div class="col-md-4 ">
		    <div class="row align-items-center">
			<label for="frm_aplica_impua"  class="col-auto col-form-label">Aplica</label>
			<input type="checkbox" class="form-control" id="frm_aplica_impu"  name="frm_aplica_impu" value="1" <?=$aplica_impu;?>  >
		    </div>
<!--			<div class="col-md-2 float-right" style="background-color:lavender;"/></div> -->
		</div>
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_modelo">Modelo de comprobante</label>
			<select class="custom-select" id="frm_modelo" name="frm_modelo">
			<?php foreach($modelo_arr as $item){?>
				<option value="<?=$item->id;?>"  <?=$item->selectado;?> ><?=$item->descripcion;?></option>
			<?php } ?>
			</select>
		</div>
		<div class="col">
			<label for="frm_numero">Numerador</label>
			<input type="number" min="0" max="9999999999" class="form-control" id="frm_numero" name="frm_numero" value="<?=$numero;?>" >    
		</div>
		<div class="col">
			<label for="frm_tipo_ent">Tipo Entidad que Aplica</label>
			<br>
			<?php foreach($tipo_entidad_arr as $item){?>
			    <input type="radio" id="frm_tipoe" name="frm_tipoe" value="<?=$item['id'];?>" <?=$item['selectado'];?> > 
			    <label for="frm_tipo_ent"><?=$item['denominacion'];?> | </label>
			<?php } ?>
			
		</div>
	</div>
</form>

<script>
function valida_tipos_comp(){
	console.log('valida tipos_comp');
    return true;
}
</script>



