

<form action="<?php echo base_url('index.php/proyectostipospropiedades/guardaRegistro') ?>" method="POST"  data-validation="valida_proye_t_p">

	<div class="col">
		<!--<label for="frm_id">Id</label>-->
		<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_tipo_propiedad_id">Tipo de propiedad a agregar al proyecto</label>
			<select class="custom-select" id="frm_tipo_propiedad_id" name="frm_tipo_propiedad_id">
			<?php foreach($tipos_propiedades as $item){?>
				<option value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['descripcion'];?></option>
			<?php } ?>
			</select>
		</div>
		<div class="col">
			<label for="frm_coeficiente">Coeficiente</label>
			<input type="number" min="0" class="form-control" id="frm_coeficiente" name="frm_coeficiente" value="<?=$coeficiente;?>" >
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
function valida_proye_t_p(){
    var $valCoef = $("#frm_coeficiente").val();
    if ($valCoef >= 0 && $valCoef <=100){
	console.log('valida proye_t_p');
	return true;
    }
    alert("El coeficiente deber ser mayor o igual a 0 y menor o igual a 100");
    $("#frm_coeficiente").focus();
    $("#frm_coeficiente").select();
}
</script>

