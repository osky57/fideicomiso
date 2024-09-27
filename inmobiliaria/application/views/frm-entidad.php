<form id="formenti" action="<?php echo base_url('index.php/entidades/guardaRegistro') ?>" method="POST" data-validation="valida_entidad">

	<div class="col">
		<!--<label for="frm_id">Id</label>-->
		<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	</div>
	<div class="row">
		<div class="col">
			<label for="frm_razon_social">Razón Social</label>
			<input type="text" class="form-control" id="frm_razon_social" name="frm_razon_social" value="<?=$razon_social;?>"   maxlength="100" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />		</div>
		<div class="col">
			<label for="frm_cuit">CUIT</label>
			<input type="number" class="form-control" id="frm_cuit" name="frm_cuit" value="<?=$cuit;?>">
		</div>
	</div>
	
	<div class="row">
		<div class="col">
			<label for="frm_calle">Calle</label>
			<input type="text" class="form-control" id="frm_calle"  name="frm_calle" value="<?=$calle;?>"  maxlength="100" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
		<div class="col">
			<label for="frm_numero">Número</label>
			<input type="text" class="form-control" id="frm_numero" name="frm_numero" value="<?=$numero;?>"  maxlength="20" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" /> 
		</div>
		<div class="col">
			<label for="frm_departamento">Departamento</label>
			<input type="text" class="form-control" id="frm_piso_departamento" name="frm_piso_departamento" value="<?=$piso_departamento;?>"  maxlength="20" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
	</div>
	
	<div class="row">
		<div class="col">
			<label for="frm_celular">Celular</label>
			<input type="text" class="form-control" id="frm_celular" name="frm_celular" value="<?=$celular;?>"  maxlength="20" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
		<div class="col">
			<label for="frm_whatsapp">Whatsapp</label>
			<input type="text" class="form-control" id="frm_whatsapp" name="frm_whatsapp" value="<?=$whatsapp;?>" maxlength="20" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" />
		</div>
	</div>
	
	<div class="row">
		<div class="col">
			<label for="frm_email">Email</label>
			<input type="email" class="form-control" id="frm_email" name="frm_email" value="<?=$email;?>"  maxlength="80" oninput="if(this.value.length > this.maxLength) this.value = this.value.slice(0, this.maxLength);" /> 
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
			<label for="exampleFormControlTextarea1" class="form-label">Observaciones</label>
			<textarea class="form-control" id="frm_observaciones" name="frm_observaciones" rows="3"><?=$observaciones;?></textarea>
		</div>
	</div>
	<div class="row">
		<div class="col">
			<label for="frm_tipo_ent">Tipo Entidad</label>
			<br>
			<?php foreach($tipo_entidad_arr as $item){?>
			    <input type="checkbox" class="xform-check-input"  id="frm_tipoe" name="frm_tipoe<?=$item['id'];?>" value="<?=$item['id'];?>" <?=$item['selectado'];?> > 
			    <label for="frm_tipo_ent"><?=$item['denominacion'];?>  </label>
			    <br>
			<?php } ?>
		</div>

		<div class="col" id="div_proyectos_noes" name="div_proyectos_noes" >
			<label for="frm_proyectos_noes">Proyectos</label>
			<select class="custom-select" id="frm_proyectos_noes" name="frm_proyectos_noes">
			<?php foreach($proyectos_noes as $item){?>
				<option value="<?=$item['p_id'];?>"  <?=$item['noes'];?> ><?=$item['p_nombre'];?></option>
			<?php } ?>
			</select>
		</div>
	</div>


<script>
var retValCuit = false;
$(document).ready(function(){

    xxx = $('input[name="frm_tipoe3"]').is(":checked");

debugger;

    if ($('input[name="frm_tipoe3"]').is(":checked") == false){
	$("#div_proyectos_noes").hide();
    }


//-----------------------------------------------------------------------------------
    $('input[name="frm_tipoe3"]').change(function(){
	if ($('input[name="frm_tipoe3"]').is(":checked") == true){
	    $("#div_proyectos_noes").show();
	}else{
	    $("#div_proyectos_noes").hide();
	}
    });





//-----------------------------------------------------------------------------------
    $("#frm_cuit").change(function(){
	var cCuit = $(this).val();
	if (!validarCuit(cCuit)){ // este es bueno
	    $("#frm_cuit").focus();
	}
    });

//-----------------------------------------------------------------------------------
    function validarCuit(cuit) {
	var nnId   = $("#frm_id").val() == '' ? 0 : $("#frm_id").val();
	retValCuit = false;
	if(cuit.length == 0) {
	    return true;
	}
	if(cuit.length < 7) {
	    alert("DEBE INGRESAR UN NUMERO DE DOCUMENTO VALIDO");
	    return false;
	}
	if(cuit.length == 8 || cuit.length == 7) {
	    retValCuit = true;
	}else{
	    if(cuit.length != 11) {
		alert("DEBE INGRESAR UN NUMERO DE CUIT VALIDO");
		return false;
	    }else{
		var acumulado   = 0;
		var digitos     = cuit.split("");
		var digito      = digitos.pop();
		for(var i = 0; i < digitos.length; i++) {
		    acumulado += digitos[9 - i] * (2 + (i % 6));
		}
		var verif = 11 - (acumulado % 11);
		if(verif == 11) {
		    verif = 0;
		} else if(verif == 10) {
		    verif = 9;
		}
		retValCuit = digito == verif;
	    }
	}
	if (retValCuit){
	    retValCuit = false;
	    $.ajax({
		url : "<?=$urlvalcuit;?>",
		type : 'GET',
		dataType : 'json',
		data : { identi : nnId, cuit : cuit },
		success : function(json) {
		    retValCuit = true;
		    if (json['estado'] > 0){
			alert(json['mensaje']);
			retValCuit = false;
			$("#frm_cuit").val('');
		    }
		},
		error : function(xhr, status) {
                        alert('Disculpe, existió un problema 3*');
                },
                complete : function(xhr, status) {
                        //    alert('Petición realizada');
                }
	    });
	}
	return retValCuit;
    }

});


//-----------------------------------------------------------------------------------
function valida_entidad(){
    if ($("#frm_cuit").val() > 0){
console.log("tiene docu");
    }else{
	alert("Debe ingresar un número de CUIT/CUIL/DNI");
	return false;
    }
    var nChk = 0;
    $('.xform-check-input:checked').each(function() {
	nChk++;
    });
    if (nChk == 0){
	alert("No se ha indicado TIPO ENTIDAD, debe indicar al menos una");
	return false;
    }
    return true;

}

</script>

</form>
