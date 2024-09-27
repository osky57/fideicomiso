<form action="<?php echo base_url('index.php/proyectos/guardaRegistro') ?>" method="POST" data-validation="valida_proye">

	<div class="col">
		<!--<label for="frm_id">Id</label>-->
		<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_nombre">Denominaci&oacute;nn</label>
			<input type="text"class="form-control" id="frm_" name="frm_nombre" value="<?=$nombre;?>" maxlength="100" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
		<div class="col">
			<label for="frm_tipo_obra_id">Tipo de obra</label>
			<select class="custom-select" id="frm_tipo_obra_id" name="frm_tipo_obra_id">
			<?php foreach($tipos_obras as $item){?>
				<option value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['descripcion'];?></option>
			<?php } ?>
			</select>
		</div>
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_calle">Calle</label>
			<input type="text" class="form-control" id="frm_calle"  name="frm_calle" value="<?=$calle;?>" maxlength="100" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
		<div class="col">
			<label for="frm_numero">Número</label>
			<input type="text" class="form-control" id="frm_numero" name="frm_numero" value="<?=$numero;?>"  maxlength="20" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" /> 
		</div>
		<div class="col">
			<label for="frm_localidad">Localidad</label>
			<!--<input type="number" class="form-control" id="frm_localidad" name="frm_localidad" value="<?=$localidad_id;?>">    -->
			<select class="custom-select" id="frm_localidad" name="frm_localidad">
			<?php foreach($localidades as $item){?>
				<option value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['nombre'];?></option>
			<?php } ?>
			</select>
		</div>
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_fecha_inicio">Fecha de inicio</label>
			<input type="date" class="form-control" id="frm_fecha_inicio" name="frm_fecha_inicio" value="<?=$fecha_inicio;?>">
		</div>
		<div class="col">
			<label for="frm_fecha_finalizacion">Fecha de finalizaci&oacute;n</label>
			<input type="date" class="form-control" id="frm_fecha_finalizacion" name="frm_fecha_finalizacion" value="<?=$fecha_finalizacion;?>">
		</div>
		<div class="col">
			<label for="frm_tipo_proyecto_id">Tipo de proyecto</label>
			<select class="custom-select" id="frm_tipo_proyecto_id" name="frm_tipo_proyecto_id">
			<?php foreach($tipos_proyectos as $item){?>
				<option value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['descripcion'];?></option>
			<?php } ?>
			</select>
		</div>
	</div>

	<div class="row">
		<div class="col">
			<label for="exampleFormControlTextarea1" class="form-label">Observaciones</label>
			<textarea class="form-control" id="frm_comentario" name="frm_comentario" rows="3"><?=$comentario;?></textarea>
		</div>
	</div>

</form>

<script>
function valida_proye(){
	console.log('valida proyecto');
    return true;
}
</script>

