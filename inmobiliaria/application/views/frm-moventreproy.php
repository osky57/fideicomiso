<?php $id_form=uniqid();?>
<form id="<?=$id_form;?>" action="<?php echo base_url('index.php/moventreproy/guardaRegistro') ?>" method="POST"  data-validation="valida_cta_cte">
	<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	<input type="hidden" class="form-control" id="frm_cta_banc<?=$id_form;?>" name="frm_cta_banc" value="<?=$idEnti;?>" >
	<div class="row mi_padd">
		<div class="col-sm-2">
			<label for="frm_fecha">Fecha</label>
			<input type="date" class="form-control" id="frm_fecha" name="frm_fecha" value="<?=$fecha;?>" >    
		</div>

		<div class="col-sm-2">
			<label for="frm_proyecto_id">Proyectos destino</label>
			<select class="custom-select" id="frm_proyecto_id<?=$id_form;?>" name="frm_proyecto_id" ">
			    <?php foreach($proyectos as $item){?>
				<option value="<?=$item['id'];?>"  ><?=$item['nombre'];?> </option>
			    <?php } ?>
			</select>
		</div>

		<div class="col-sm-3">
			<label for="frm_tipo_comprobante_id">Concepto</label>
			<select class="custom-select" id="frm_tipo_comprobante_id<?=$id_form;?>" name="frm_tipo_comprobante_id" onChange="llamaCambioComprob()">
			    <?php foreach($tiposcompr as $item){?>
				<option value="<?=$item['id_gchq_gctab'];?>"  <?=$item['selectado'];?> ><?=$item['descripcion'];?> </option>
			    <?php } ?>
			</select>
		</div>
		<div class="col-md-5 col-sm-12">
			<label for="exampleFormControlTextarea1" class="form-label">Observaciones</label>
			<textarea class="form-control" id="frm_comentario" name="frm_comentario" rows="2"><?=$comentario;?></textarea>
		</div> 

	</div>
	<div class="row">
		<div class="col-md-2">
			<label for="frm_importe">Importe</label>
			<input type="number" class="form-control" disabled  min="0" id="frm_importe<?=$id_form;?>" name="frm_importe" > 
		</div>
		<div class="col-md-2"> 
			<label for="frm_moneda_id">Divisa</label>
			<select class="custom-select" id="frm_moneda_id<?=$id_form;?>" name="frm_moneda_id" disabled>
			    <?php foreach($monedas as $item){?>
				<option value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['denominacion'];?></option>
			    <?php } ?>
			</select>
		</div>
		<div class="col-md-2">
			<label for="frm_importe_divisa">Importe Divisa</label>
			<input type="number" disabled class="form-control" min="0" id="frm_importe_divisa<?=$id_form;?>" name="frm_importe_divisa" value="<?=$importe_divisa;?>"> 
		</div>


		<div class="col-md-6" id="divcartchq_0_<?=$id_form;?>">
		    <label for="carterachq_0_<?=$id_form;?>">Cheques a Depositar</label>
		    <select disabled id="carterachq_0_<?=$id_form;?>"    name="carterachq[]"    class="form-control form-control-sm cartera<?=$id_form;?>" >  </select>
		</div>


	</div>
	<br>


	<div class="row">
		<div class="col"> 
		</div>
		<div class="col"> 
		</div>
		<div class="col"> 
		    <h5><b>Importe total</b></h5>
		</div>
		<div class="col"> 
		    <h5><b><p style="text-align:right" id="impo_totalmn_<?=$id_form;?>"> </p>
		           <p style="text-align:right" id="impo_totaldi_<?=$id_form;?>"> </p></b></h5>
		</div>
	</div>


</form>

<script>

var iddFormu = '<?=$idFormu;?>';
var aTiposEnti;
var UScotiza = 0;
$(document).ready(function(e) { 
    var elId     = '<?=$id_form;?>';
    var idInv    = '<?=$idInv;?>';
    var counter  = 1;
    UScotiza     = <?=$cotizacion[0]['importe'];?>;

    if (idInv > 0){
	$("#frm_idx"+elId).val("1");
	recuTiposComp(idInv);
    }

    $("#frm_importe"+elId).prop('disabled',true);
    $("#frm_importe_divisa"+elId).prop('disabled',true);
    $("#frm_moneda_id"+elId).prop('disabled',true);
    $("#carterachq_0_"+elId).prop('disabled',true);
    $("#carterachq_0_"+elId).on('change', function(e){cambiaChq3ro(0)});
    $("#frm_importe"+elId).on('change', function(e){calcTotal()});
    $("#frm_moneda_id"+elId).on('change', function(e){calcTotal()});

////////////////////////////////////////////////////////////////////////////////////////////
    function recuTiposComp(idEnti){
	$.ajax({
		url : "<?=$urlxUnaEnti;?>",
		type : 'GET',
		dataType : 'json',
		data : { identi : idEnti },
		success : function(json) {
		    tipoEntidad = json['tipos_entidad'];
		    aTiposEnti  = tipoEntidad.split(',');

		    $("#frm_tipo_comprobante_id"+elId+" option").each(function(){
			var aa = $(this).attr('value');
			var bb = aa.split('|');
			$(this).hide();
			if (bb[2]==1){  //si es inversor trae propiedades q le pertenecen

			}
			if (aTiposEnti.find(element => element === bb[2])){
			    $(this).show();
			}
		    })
		},
		error : function(xhr, status) {
			alert('Disculpe, existió un problema 3*');
		}
	})
    }

});

//////////////////////////////////////////////////////////////////////////////////////////////////////////
function llamaCambioComprob(){
    var idInv    = '<?=$idInv;?>';
    var elId     = '<?=$id_form;?>';
    var x = document.getElementById("frm_tipo_comprobante_id"+elId);
    var z = x.value.split("|");

console.log("cambia comprob");
//console.log( <?=$urlxChqCart;?> );

    $("#frm_importe_divisa"+elId).attr('value','');
    $("#frm_importe"+elId).attr('value','');

    if (z[1] != 1){                  //no es chq

	$("#frm_importe_divisa"+elId).attr('value',UScotiza);
	$("#frm_importe"+elId).attr('value','');
	$("#frm_importe"+elId).prop('disabled',false);
	$("#frm_importe_divisa"+elId).prop('disabled',false);
	$("#frm_moneda_id"+elId).prop('disabled',false);
	$("#carterachq_0_"+elId).empty();
	$("#carterachq_0_"+elId).prop('disabled',true);

    }else{		//es chq o echq
	$("#frm_importe_divisa"+elId).attr('value','');
	$("#frm_importe"+elId).attr('value','');
	$("#frm_importe"+elId).prop('disabled',true);
	$("#frm_importe_divisa"+elId).prop('disabled',true);
	$("#frm_moneda_id"+elId).prop('disabled',true);
	$.ajax({
		url : "<?=$urlxChqCart;?>",
		type : 'GET',
		dataType : 'json',
		data : { echq : z[5] },
		success : function(json) {
			var element = document.getElementById("carterachq_0_"+elId);
			var option  = document.createElement("option");
			while (element.firstChild) {
				element.removeChild(element.firstChild);
			}
			option       = document.createElement("option");
			option.value = "-1";
			option.text  = "Selecte un cheque disponible en cartera";
			element.add(option);
			var cCarteras = document.getElementsByClassName("cartera"+elId);  //select en la celda de la grilla

			json.forEach (function(item,index){
				var esta = true;
				for(i=0;i<cCarteras.length;i++){
					if (cCarteras[i].value == item['caja_ctacte']){
						esta = false;
					}
				}
				if (esta){
					option       = document.createElement("option");
					option.value = item['caja_ctacte'];
					option.text  = item['chq'];
					element.add(option);
				}
			})
		},
		error : function(xhr, status) {
			alert('Disculpe, existió un problema 3');
		},
		complete : function(xhr, status) {
			//    alert('Petición realizada');
		}
	});
	$("#carterachq_0_"+elId).prop('disabled',false);

    }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function cambiaChq3ro(cId){

    var elId     = '<?=$id_form;?>';
    var elStr    = "#carterachq_"+parseInt(cId,10)+"_"+elId+" option:selected"
    var valSel   = $(elStr).val();
    var opciSel  = valSel.split("|");
    var nTotalMN = 0;
    var nTotalDi = 0;

    $("#frm_importe"        +elId).val(opciSel[3]);
    $("#frm_moneda_id"      +elId).val(opciSel[2]);
    $("#frm_importe_divisa" +elId).val(opciSel[4]);

    $("#frm_importe"        +elId).prop('readonly',true);
    $("#frm_moneda_id"      +elId+" option:not(:selected)").attr('disabled',true); //genial!
    $("#frm_importe_divisa" +elId).prop('readonly',true);
    $("#carterachq_" +cId+"_"+elId+" option:not(:selected)").attr('disabled',true); //genial!

    calcTotal();

}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function calcTotal(){
    var elId      = '<?=$id_form;?>';
    var nTotalMN  = 0;
    var nTotalDi  = 0;
    var nAplicaMN = 0;
    var nAplicaDi = 0;
console.log("....................................");
console.log($("#frm_importe"+elId).val());

//totales caja
	if ( $("#frm_moneda_id"+elId).val() == '1' ){
	    nTotalMN += Number($("#frm_importe"+elId).val());
	}else{
	    nTotalDi += Number($("#frm_importe"+elId).val());
	}


    totalMNForm = new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'PES' }).format(nTotalMN);
    totalDiForm = new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'USD' }).format(nTotalDi);
    $("#impo_totalmn_"+elId).text(totalMNForm);
    $("#impo_totaldi_"+elId).text(totalDiForm);

}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function valida_cta_cte(){
	var lRet = true;
	var nId  = '<?=$id_form;?>';
	if ($("#div_caja"+nId).find("*").is(':enabled')) {
		$("#div_caja"+nId+" tbody tr").each(function (index) {
			if (Number($(this).find("td").eq(1).find("input").val()) == 0){
				lRet = false;
			}
		});
		if (lRet == false){
			alert("VERIFIQUE, FALTA INGRESAR UN IMPORTE!");
		}else{
		    var aArray = calcTotal(1);
		    if (aArray[0]<aArray[2] || aArray[0]<aArray[2]){
			alert("Verifique los totales, lo aplicado no puede ser superior a lo registrado en caja");
			lRet = false;
		    }
		}
	}
	if ($("#frm_importe"+nId).is(':enabled')) {
		if ($("#frm_importe"+nId).val() == 0){
			alert("VERIFIQUE, FALTA INGRESAR EL IMPORTE!");
			lRet = false;
		}else{
		    if ($("#frm_importe_divisa"+nId).val() == 0){
			alert("VERIFIQUE, FALTA INGRESAR LA COTIZACION DE LA DIVISA!");
			lRet = false;
		    }
		}
	}
	if ($("#frm_idx"+nId).val() == 1){
	    $("#myTablaCaja"+iddFormu).trigger('click');
	}
	return lRet;
}

</script>
