<form action="<?php echo base_url('index.php/proyectosentidades/guardaRegistro') ?>" method="POST"  data-validation="valida_proye_enti">
	<div class="col">
		<!--<label for="frm_id">Id</label>-->
		<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_entidad_id">Entidad a agregar al proyecto</label>
			<select class="custom-select" id="frm_entidad_id" name="frm_entidad_id">
			<?php foreach($entidades as $item){?>
				<option value="<?=$item['id'];?>" ><?=$item['razon_social'];?>(<?=$item['id'];?>)</option>
			<?php } ?>
			</select>
		</div>
	</div>
</form>

<script>
function valida_proye_enti(){
    console.log('valida proye_enti');
    return true;
}
</script>



