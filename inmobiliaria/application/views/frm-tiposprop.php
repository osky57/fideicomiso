<form action="<?php echo base_url('index.php/tiposprop/guardaRegistro') ?>" method="POST"  data-validation="valida_tipos_prop">

	<div class="col">
		<!--<label for="frm_id">Id</label>-->
		<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	</div>
	<div class="row">
		<div class="col">
			<label for="frm_descripcion">Descripci&oacute;n</label>
			<input type="text"class="form-control" id="frm_descripcion" name="frm_descripcion" value="<?=$descripcion;?>"  maxlength="100" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
	</div>
	
	<div class="row">
		<div class="col">
			<div class="col-md-2 float-left">
			<label for="frm_obligatorio">Obligatorio</label>
			<input type="checkbox" class="form-control" id="frm_obligatorio"  name="frm_obligatorio" value="1" <?=$obligatorio;?>  >
			</div>
			<div class="col-md-2 float-right" style="background-color:lavender;"/></div> 
		</div>
	</div>

 </form>


<script>
function valida_tipos_prop(){
	console.log('valida tipos_prop');
    return true;
}
</script>

