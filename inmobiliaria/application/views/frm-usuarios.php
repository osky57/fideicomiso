<form action="<?php echo base_url('index.php/usuarios/guardaRegistro') ?>" method="POST"  data-validation="valida_usua">

	<div class="col">
		<!--<label for="frm_id">Id</label>-->
		<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_nombre">Nombre</label>
			<input type="text" class="form-control" id="frm_nombre" name="frm_nombre" value="<?=$nombre;?>"  maxlength="80" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_usuario">Usuario</label>
			<input type="text" class="form-control" id="frm_usuario" name="frm_usuario" value="<?=$usuario;?>" maxlength="40" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
	</div>

	<div class="row">
		<div class="col">
			<label for="frm_password">Password</label>
			<input type="password" class="form-control"  id="frm_password" name="frm_password" value="<?=$password;?>" maxlength="40" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
	</div>



	<div class="row">
		<div class="col">
			<label for="frm_nivel">Administrador</label>
			<input type="checkbox" id="frm_nivel" name="frm_nivel" value="1" <?=$nivel;?> >
		</div>
	</div>

 </form>


<script>
function valida_usua(){
	console.log('valida usua');
    return true;
}
</script>

