<?php $id_form=uniqid();?>
<form id="<?=$id_form;?>" action="<?php echo base_url('index.php/cuentascorrientes/guardaRegistro') ?>" method="POST"  data-validation="valida_cta_cte">
	<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	<input type="hidden" class="form-control" id="frm_idx<?=$id_form;?>" name="frm_idx<?=$id_form;?>" value="0" >

	<div class="row mi_padd">
		<div class="col-sm-2">
			<label for="frm_fecha">Fecha</label>
			<input type="date" class="form-control" id="frm_fecha" name="frm_fecha" value="<?=$fecha;?>" >    
		</div>

		<div class="col-sm-3">
			<label for="frm_entidad_id">Entidad</label>
			<input type="text" class="custom-select" id="frm_entidad_id<?=$id_form;?>" name="frm_entidad_id">
		</div>
		<div class="col-sm-3">
			<label for="frm_tipo_comprobante_id">Tipo Comprobante</label>
			<select class="custom-select" id="frm_tipo_comprobante_id<?=$id_form;?>" name="frm_tipo_comprobante_id" onChange="llamaCambioComprob()">
			    <?php foreach($tiposcompr as $item){?>
				<option value="<?=$item['id'];?>|<?=$item['afecta_caja'];?>|<?=$item['tipos_entidad'];?>|<?=$item['signo'];?>|<?=$item['modelo'];?>"  <?=$item['selectado'];?> ><?=$item['descripcion'];?> </option>
			    <?php } ?>
			</select>
		</div>
		<div class="col-sm-4">
			<label for="frm_detalle_proyecto_tipo_propiedad_id">Aplica a</label>
			<select class="custom-select" id="frm_detalle_proyecto_tipo_propiedad_id<?=$id_form;?>" name="frm_detalle_proyecto_tipo_propiedad_id">
			    <?php foreach($tiposprop as $item){?>
				<option value="<?=$item['ptp_id'];?>"  <?=$item['selectado'];?> ><?=$item['tp_descripcion'];?> (Id <?=$item['ptp_id'];?> ) - (<?=$item['ptp_comentario'];?>) </option>
			    <?php } ?>
			</select>
		</div>
	</div>
	<div class="row">
		<div class="col-md-2">
			<label for="frm_importe">Importe</label>
			<input type="number" class="form-control" disabled  min="0" id="frm_importe<?=$id_form;?>" name="frm_importe" value="<?=$importe;?>"> 
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
		<div class="col-md-6 col-sm-12">
			<label for="exampleFormControlTextarea1" class="form-label">Observaciones</label>
			<textarea class="form-control" id="frm_comentario" name="frm_comentario" rows="2"><?=$comentario;?></textarea>
		</div> 
	</div>


	<font size=2>

	    <div class="container mi_padd">
		<div class="row" id="div_aplica" name="div_aplica" >
		    <div class="col-lg-10" id="div1">
			<table id="tabla_aplica" class="table table-condensed table-bordered">
			    <thead>
				<tr>
				    <th>Fecha</th>
				    <th>Comprobante</th>
				    <th>Saldo $</th>
				    <th>Saldo U$S</th>
				    <th>Aplica $</th>
				    <th>Aplica U$S</th>
				    <th>Comentario</th>
				</tr>
			    </thead>
			    <tbody class='tbodyalt' id="tbodydeuda" class="text-right">
			    </tbody>
			</table>
		    </div>
		    <div class="col-lg-2">
			<b><div>Total aplicaciones   <p style="text-align:right" id="aplica_totalmn"> </p></div>
			   <div> <p style="text-align:right" id="aplica_totaldi"> </p></div></b>
		    </div>
		</div>
	    </div>
	</font>

	<div class="table-responsive  mi_padd" id="div_caja<?=$id_form;?>" name="div_caja<?=$id_form;?>" >
<!--
	    <div  style='padding-bottom:5px;'  class="card-body d-flex justify-content-between align-items-center">
		<h5>Caja</h5>
	    </div>
-->
	    <table id="myTablaCaja_<?=$id_form;?>" name="myTablaCaja_<?=$id_form;?>" class="table table-bordered table-striped">
	    <thead>
		<tr >
		    <td class="col-sm-2">Medio de pago</td>
		    <td class="col-sm-1">Importe</td>
		    <td class="col-sm-1">Divisa</td>
		    <td class="col-sm-1">Cotización</td>
		    <td class="col-sm-2">Comentario</td>
		    <td class="col-sm-4"></td>
		    <td class="col-sm-1"></td>
		</tr>
	    </thead>
	    <tbody>
		<tr >
		    <td >
			<select id="tipomepa_0_<?=$id_form;?>" name="tipomepa[]"  class="form-control form-control-sm">
			    <?php foreach($mediospago as $item){?>
				<option class="option" value="<?=$item['id_gchq_gctab'];?> "  <?=$item['selectado'];?> ><?=$item['descripcion'];?> </option>
			    <?php } ?>
			</select>
		    </td>
		    <td ><input type="number"  id="importemepa_0_<?=$id_form;?>" name="importemepa[]" class="form-control form-control-sm impocaja<?=$id_form;?>"/></td>
		    <td >
			<select id="monedamepa_0_<?=$id_form;?>" name="monedamepa[]" class="form-control form-control-sm" >
			    <?php foreach($monedas as $item){?>
				<option class="option" value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['denominacion'];?></option>
			    <?php } ?>
			</select>
		    </td>
		    <td ><input type="number" id="cotizamepa_0_<?=$id_form;?>" name="cotizamepa[]"   class="form-control form-control-sm"/></td>
		    <td ><input type="text"   id="comenta_0_<?=$id_form;?>" name="comenta[]" class="form-control form-control-sm" /></td>
		    <td >
			<div id="conteaux_0_<?=$id_form;?>" name="contenido_0_<?=$id_form;?>">
			    <select id="ctabanc_0_<?=$id_form;?>" name="ctabanc[]" class="form-control form-control-sm" >
					<?php foreach($ctasbancarias as $item){?>
					<option class="option" value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['denominacion'];?></option>
					<?php } ?>
			    </select>
			    <select id="chequeras_0_<?=$id_form;?>" name="chequeras[]"     class="form-control form-control-sm chequeras"> </select>
			    <select id="banco_0_<?=$id_form;?>" name="banco[]" class="form-control form-control-sm" >
				<?php foreach($bancos as $item){?>
				    <option class="option" value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['denominacion'];?></option>
				<?php } ?>
			    </select>
			    <div class="row"   id="divchq_0_<?=$id_form;?>">
				<div class="col-sm-2 divchqserie_0_<?=$id_form;?>">
					<input type="hidden" id="chequera_id_0_<?=$id_form;?>" name="chequera_id[]"  class="form-control form-control-sm" value=""/>
				    <label for="chqserie_0_<?=$id_form;?>">Serie</label>
				    <input type="text"  id="chqserie_0_<?=$id_form;?>" name="chqserie[]" class="form-control form-control-sm" maxlength="2" size="2" pattern="[A-Za-z]{2}"/>
				</div>
				<div class="col-sm-3">
				    <label for="chqnro_0_<?=$id_form;?>">Número</label>
				    <input type="text"  id="chqnro_0_<?=$id_form;?>" name="chqnro[]"    class="form-control form-control-sm" maxlength="8" size="8" pattern="[0-9]{8}"/>
				</div>
				<div class="col-sm-4">
				    <label for="chqfemi_0_<?=$id_form;?>">Emisión</label>
				    <input type="date"  id="chqfemi_0_<?=$id_form;?>" name="chqfemi[]"  class="form-control form-control-sm"/>
				</div>
				<div class="col-sm-4">
				    <label for="chqfacre_0_<?=$id_form;?>">Acredita</label>
				    <input type="date"  id="chqfacre_0_<?=$id_form;?>" name="chqfacre[]"  class="form-control form-control-sm"/>
				</div>
			    </div>

			    <div class="row" id="divcartchq_0_<?=$id_form;?>">
				    <select id="carterachq_0_<?=$id_form;?>"    name="carterachq[]"    class="form-control form-control-sm cartera<?=$id_form;?>" >  </select>
				    <input type="hidden" id="cc_caja_ori_0_<?=$id_form;?>"  name="cc_caja_ori[]"  class="form-control form-control-sm" value=""/>
<!--				    <input type="text"   readonly id="carterachqtxt_0_<?=$id_form;?>" name="carterachqtxt[]" class="form-control form-control-sm"/> -->

			    </div>

			</div>
		    </td>
		    <td><a class="deleteRow"></a></td>
		</tr>
	    </tbody>
	    </table>

	    <div class="row">
		<div class="col"> 
		    <input type="button" class="btn btn-primary btn-sm"  id="addrow<?=$id_form;?>" name="addrow<?=$id_form;?>" value="Agregar medio de pago" />
		</div>
		<div class="col"> 
		</div>
		<div class="col"> 
		</div>
		<div class="col"> 
		    <h6><b>Importe total</b></h6>
		</div>
		<div class="col"> 
		    <h6><b><p style="text-align:right" id="impo_totalmn_<?=$id_form;?>"> </p>
		           <p style="text-align:right" id="impo_totaldi_<?=$id_form;?>"> </p></b></h6>
		</div>
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
	$("#frm_entidad_id"+elId).val(idInv);
	$("#frm_entidad_id"+elId+" option:not(:selected)").hide();
	recuTiposComp(idInv);
	recuPropie(idInv);
    }

    $("#div_aplica").hide();
    $("#frm_importe"+elId).prop('disabled',true);
    $("#frm_importe_divisa"+elId).prop('disabled',true);
    $("#frm_moneda_id"+elId).prop('disabled',true);
    $("#div_caja"+elId ).find("*").prop('disabled', true);
    $("#ctabanc_0_"+elId).hide();
    $("#banco_0_"+elId).hide();
    $("#divchq_0_"+elId).hide();
    $("#divcartchq_0_"+elId).hide();
    $("#chequeras_0_"+elId).hide();

    $("#tipomepa_0_"+elId).off();
    $("#tipomepa_0_"+elId).on('change', function(e){cambiaSelect(0,1)});
    $("#carterachq_0_"+elId).off();
    $("#carterachq_0_"+elId).on('change', function(e){cambiaChq3ro(0)});
    $("#chequeras_0_"+elId).off();
    $("#chequeras_0_"+elId).on('change', function(e){cambiaChequera(0)});
    $("#cotizamepa_0_"+elId).attr('value',UScotiza);
    $("#addrow<?=$id_form;?>").on("click", function () {
        var newRow = $("<tr>");
        var cols   = "";
	var cId    = counter.toString();
	cols += '<td ><select              id="tipomepa_'   +counter+'_'+elId+'" name="tipomepa[]"     class="form-control form-control-sm"></select> </td>';
	cols += '<td ><input type="number" id="importemepa_'+counter+'_'+elId+'" name="importemepa[]"  class="form-control form-control-sm impocaja'+elId+'"  />         </td>';
	cols += '<td ><select              id="monedamepa_' +counter+'_'+elId+'" name="monedamepa[]"   class="form-control form-control-sm"></select> </td>';
	cols += '<td ><input type="number" id="cotizamepa_' +counter+'_'+elId+'" name="cotizamepa[]"   class="form-control form-control-sm" value="'+UScotiza+'"/> </td>';
	cols += '<td ><input type="text"   id="comenta_'    +counter+'_'+elId+'" name="comenta[]"      class="form-control form-control-sm"/>         </td>';
	cols += '<td >';
	cols += '     <select id="ctabanc_'    +counter+'_' +elId+'" name="ctabanc[]"                   class="form-control form-control-sm"></select> ';
	cols += '     <select              id="banco_'      +counter+'_'+elId+'" name="banco[]"        class="form-control form-control-sm"></select> ';
	cols += '     <select              id="chequeras_'  +counter+'_'+elId+'" name="chequeras[]"     class="form-control form-control-sm chequeras"></select> ';
	cols += '     <div class="row"     id="divchq_'     +counter+'_'+elId+'">';
	cols += '          <div class="col-sm-2 divchqserie'+counter+'_'+elId+'">';
	cols += '             <input type="hidden" id="chequera_id_'+counter+'_'+elId+'" name="chequera_id[]"  class="form-control form-control-sm" value=""/> ';
	cols += '             <label for="chqserie_'+counter+'_'+elId+'">Serie</label>';
	cols += '             <input type="text"  id="chqserie_'+counter+'_'+elId+'" name="chqserie[]" class="form-control form-control-sm" maxlength="2" size="2" pattern="[A-Za-z]{2}"/>';
	cols += '          </div>';
	cols += '          <div class="col-sm-3">';
	cols += '             <label for="chqnro_'+counter+'_'+elId+'">Número</label>';
	cols += '             <input type="text"  id="chqnro_'+counter+'_'+elId+'" name="chqnro[]" class="form-control form-control-sm" maxlength="8" size="8" pattern="[0-9]{8}"/>';
	cols += '          </div>';
	cols += '          <div class="col-sm-4">';
	cols += '             <label for="chqfemi_'+counter+'_<?=$id_form;?>">Emisión</label>';
	cols += '             <input type="date"  id="chqfemi_'+counter+'_'+elId+'" name="chqfemi[]"  class="form-control form-control-sm"/>';
	cols += '          </div>';
	cols += '          <div class="col-sm-4">';
	cols += '             <label for="chqfacre_'+counter+'_'+elId+'">Acredita</label>';
	cols += '             <input type="date"  id="chqfacre_'+counter+'_'+elId+'" name="chqfacre[]"  class="form-control form-control-sm"/>';
	cols += '          </div>';
	cols += '     </div>';
	cols += '     <div class="row"     id="divcartchq_'         +counter+'_'+elId+'">';
	cols += '             <select id="carterachq_'              +counter+'_'+elId+'" name="carterachq[]"   class="form-control form-control-sm cartera'+elId+'"></select> ';
	cols += '             <input type="hidden" id="cc_caja_ori_'+counter+'_'+elId+'" name="cc_caja_ori[]"  class="form-control form-control-sm" value=""/> ';
	cols += '     </div>';
	cols += '</td>';
	//	cols += '             <input type="hidden" readonly id="carterachqid_'   +counter+'_'+elId+'" name="carterachqid[]"  class="form-control form-control-sm"/>';
	//	cols += '             <input type="text"   readonly id="carterachqtxt_'  +counter+'_'+elId+'" name="carterachqtxt[]" class="form-control form-control-sm"/>';
		cols += '<td ><input type="button" class="ibtnDel btn btn-md btn-danger "  value="&#xE107;"></td>';
        newRow.append(cols);

	$("#myTablaCaja_" +elId+" tbody").append(newRow);
	$("#tipomepa_0_"  +elId+" .option").clone().appendTo("#tipomepa_"+counter+"_"+elId);
	$("#monedamepa_0_"+elId+" .option").clone().appendTo("#monedamepa_"+counter+"_"+elId);
	$("#banco_0_"     +elId+" .option").clone().appendTo("#banco_"+counter+"_"+elId);
	$("#ctabanc_0_"   +elId+" .option").clone().appendTo("#ctabanc_"+counter+"_"+elId);
	$("#tipomepa_"+counter+"_"+elId).off();
	$("#tipomepa_"+counter+"_"+elId).on('change', function(e){cambiaSelect(cId,1)});
	$("#monedamepa_"+counter+"_"+elId).off();
	$("#monedamepa_"+counter+"_"+elId).on('change',function(e){cambiaSelect(cId,2)});
	$("#banco_"+counter+"_"+elId).off();
	$("#banco_"+counter+"_"+elId).on('change', function(e){cambiaSelect(cId,3)});
	$("#ctabanc_"+counter+"_"+elId).off();
	$("#ctabanc_"+counter+"_"+elId).on('change', function(e){cambiaSelect(cId,4)});
	$("#carterachq_"+counter+"_"+elId).off();
	$("#carterachq_"+counter+"_"+elId).on('change', function(e){cambiaChq3ro(cId)});
	$("#chequeras_"+counter+"_"+elId).off();
	$("#chequeras_"+counter+"_"+elId).on('change', function(e){cambiaChequera(cId)});
	$("#ctabanc_"+counter+"_"+elId).hide();
	$("#banco_"+counter+"_"+elId).hide();
	$("#divchq_"    +counter+"_"+elId).hide();
	$("#divcartchq_"+counter+"_"+elId).hide();
        counter++;
    });

    $("#myTablaCaja_"+elId).on("click", ".ibtnDel", function (event) {
	$(this).closest("tr").remove();
    });

    $("#div_caja"+elId ).change(function(){
	calcTotal();
    });

    $("#tbodydeuda").change(function(){
	calcTotal();
    });

    $("#frm_entidad_id"+elId ).change(function(){
	//debe recuperar tipos comprob. y propiedades
	recuTiposComp($(this).val());
	recuPropie($(this).val());
    });


/*
    $("#aplicapesos").change(function(){

console.log("*****");

	$("#aplicapesos").each(function (index) {

console.log($(this));


	})
//	$("#tabla_aplica tbody tr").each(function (index) {
//	    if ($(this).find("td").eq(4).find("input").val() > 0 ){
//		nAplicaMN += Number($(this).find("td").eq(4).find("input").val());

    })
//aplicadolar

*/

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
			    recuPropie(idEnti);
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
////////////////////////////////////////////////////////////////////////////////////////////////////////
    function recuPropie(idEnti){
	var Propie = "#frm_detalle_proyecto_tipo_propiedad_id"+elId;
	$(Propie).hide();
	$.ajax({
		url : "<?=$urlxRecuPropieEnti;?>",
		type : 'GET',
		dataType : 'json',
		data : { enti : idEnti },
		success : function(json) {
			var element = document.getElementById("frm_detalle_proyecto_tipo_propiedad_id"+elId);
			var option  = document.createElement("option");
			while (element.firstChild) {
				element.removeChild(element.firstChild);
			}
			option       = document.createElement("option");
			option.value = "-1";
			option.text  = "No aplica(Id 0) - ()";
			element.add(option);
			if (json.length >0){
			    json.forEach (function(item,index){
				option       = document.createElement("option");
				option.value = item['ptp_id'];
				option.text  = item['tp_descripcion']+" (Id "+item['ptp_id']+") - ("+item['ptp_comentario']+")";
				element.add(option);
			    })
			}
		},
		error : function(xhr, status) {
			alert('Disculpe, existió un problema 3*');
		},
		complete : function(xhr, status) {
			//    alert('Petición realizada');
		}
	});
	$(Propie).show();
    }


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function cambiaSelect(nI,nS){
	var nnId       = parseInt(nI);
	var elStr      = "#tipomepa_"+parseInt(nI,10)+"_"+elId+" option:selected"
	var valSel     = $(elStr).val();
	var opciSel    = valSel.split("|");
	var ctaBanc    = "#ctabanc_" +nnId+"_"+elId;
	var Bancos     = "#banco_"   +nnId+"_"+elId;
	var divChq     = "#divchq_"  +nnId+"_"+elId;
	var chqCart    = "#divcartchq_"+nnId+"_"+elId;
	var chequeras  = "#chequeras_"+nnId+"_"+elId;
	elStr          = $("#frm_tipo_comprobante_id"+elId+" option:selected").val();
	var opciCCSel  = elStr.split("|");
	if (opciSel[1] == 1){ //chqs 9,13,10,14
	    if (opciSel[3].trim() === 'S'){ //[S]alida chq egreso, puede ser cartera (abre cartera y muestra chqs sin salir) o propio (muestra ctas banc. y chequeras de la cta) 10,14  (9,13 carteras)
		$(divChq).hide();
		$(Bancos).hide();
		if (opciSel[2] == 0){  // no gestiona cta.banc., muestra cartera
			$(ctaBanc).hide();
			$.ajax({
				url : "<?=$urlxChqCart;?>",
				type : 'GET',
				dataType : 'json',
				data : { echq : opciSel[5] },
				success : function(json) {
					var element = document.getElementById("carterachq_"+nnId+"_"+elId);
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
			$(chqCart).show();
		}else{                 // gestiona cta.banc., pide chequera
			$(ctaBanc).hide();
			$.ajax({
				url : "<?=$urlxChequeras;?>",
				type : 'GET',
				dataType : 'json',
				data : { echq : opciSel[5] },
				success : function(json) {
					var element = document.getElementById("chequeras_"+nnId+"_"+elId);
					var option  = document.createElement("option");
					while (element.firstChild) {
						element.removeChild(element.firstChild);
					}
					option       = document.createElement("option");
					option.value = "-1";
					option.text  = "Selecte una chequera disponible";
					element.add(option);
					var cCarteras = document.getElementsByClassName("chequeras"+elId);  //select en la celda de la grilla
					json.forEach (function(item,index){
						var esta = true;
						for(i=0;i<cCarteras.length;i++){
							if (cCarteras[i].value == item['valor']){
								esta = false;
							}
						}
						if (esta){
							option       = document.createElement("option");
							option.value = item['valor'];
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
			$(chqCart).hide();
			$(chequeras).show();
			$("#chqserie_"+nnId+"_"+elId).hide();
		}
	    }else{  //[E]ntrada chq ingreso a cartera, muestra bancos y pide datos chq 9,13
		$(ctaBanc).hide();
		$(Bancos).show();
		$(divChq).show();
		$(chqCart).hide();
		$(chequeras).hide();
	    }
	}else if (opciSel[2] == 1){ //ctas banc 3,4 pago/cobro x banco
		$(ctaBanc).show();
		$(Bancos).hide();
		$(divChq).hide();
		$(chqCart).hide();
		$(chequeras).hide();
		if (opciSel[3].trim === "S"){ //[S]alida pago egreso 4
		}else{  //[E]ntradapago ingreso 3
		}
	}else if (opciSel[3].trim() == 'X'){  // efectivo 1
		$(ctaBanc).hide();
		$(Bancos).hide();
		$(divChq).hide();
		$(chqCart).hide();
		$(chequeras).hide();
	}
    }
});

//////////////////////////////////////////////////////////////////////////////////////////////////////////
function llamaCambioComprob(){
    var idInv    = '<?=$idInv;?>';
    var elId     = '<?=$id_form;?>';
    var x = document.getElementById("frm_tipo_comprobante_id"+elId);
    var z = x.value.split("|");
    //cambia tipo comprob.pone en 0 las propiedades
    //document.getElementById("frm_detalle_proyecto_tipo_propiedad_id"+elId).value = "0";
    //afecta o no caja
    var importeStatus = true;
    var divCaja = false;
    $("#frm_importe_divisa<?=$id_form;?>").attr('value','');
    if (z[1] != 1){
	importeStatus = false;
	divCaja       = true;
	$("#frm_importe_divisa<?=$id_form;?>").attr('value',UScotiza);
    }
    //z[0] id
    //z[1] afecta caja
    //z[2] es el tipo de entidad del comprobante 1->inversor, 2->proveedor, 3->prestamista
    //z[3] signo
    //z[4] modelo

    traeDeuda(idInv,z);

    $("#tipomepa_0_"+elId+" option").each(function(){
	var aa = $(this).attr('value');
	var bb = aa.split('|');
	//bb[0] id
	//bb[1] gestiona chq
	//bb[2] gestiona cuentas bcos
	//bb[3] X E S
	//bb[4] entidades afectadas
	//bb[5] echq
	$(this).hide();
	//medio de pago X (Entrada/Salida) siempre lo muestra
	if (bb[3]=='X'){
	    $(this).show();
	//medio de pago de Entrada 
	}else if (bb[3]=='E'){
	    //no es proveedor y va al haber (recibos)
	    if (z[2] != 2 && z[3] == -1){
		$(this).show();
	    }
	//medio de pago de Salida
	}else if (bb[3]=='S'){
	    //es proveedor y va al debe (O/P)
	    if (z[2] = 2 && z[3] == 1){
		$(this).show();
//	    }else if (z[2] == 2 && z[3] == 1){
//		$(this).show();
	    }
	}

    });
    // necesita si es chq recibido y tipo de comprob. afec.caja y es de prov. trae chq/echq en cartera
    //          si es chq emitido y tipo de comprob. afec.caja muestra ctas banc.c.c. talonarios chqs
    $("#frm_importe"+elId).prop('disabled',importeStatus);
    $("#frm_importe_divisa"+elId).prop('disabled',importeStatus);
    $("#frm_moneda_id"+elId).prop('disabled',importeStatus);
    $("#div_caja"+elId ).find("*").prop('disabled', divCaja);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function traeDeuda(idInv,z){

    var aTiposOPRE = [4,5];
    //z[0] id
    //z[1] afecta caja
    //z[2] es el tipo de entidad del comprobante 1->inversor, 2->proveedor, 3->prestamista
    //z[3] signo
    //z[4] modelo
    $("#div_aplica").hide();
    $("#tabla_aplica > tbody").empty();

    if (aTiposOPRE.find(element => element === parseInt(z[4],10))){
	$.ajax({
		url : "<?=$urlrecudeuda;?>",
		type : 'GET',
		dataType : 'json',
		data : { identi : idInv, tipoenti : z[2] },
		success : function(json) {
		    if (json.length >0){
			json.forEach (function(item,index){
			    const numFor = new Intl.NumberFormat("en-US", {style: "currency",currency: "USD", });       //'es-ES');   //,{style:"currency",currency:"$"});
			    filaPesos = "<td></td>";
			    filaDolar = "<td></td>";
			    if (item['cc_moneda_id'] == 1){
				filaPesos = "<td><input type='number' id='aplicapesos' name='aplicapesos_"+item['cc_id']+"_"+item['cc_moneda_id']+"' min='0' max='"+item['saldopesos']+"'></td>";
			    }else{
				filaDolar = "<td><input type='number' id='aplicadolar' name='aplicadolar_"+item['cc_id']+"_"+item['cc_moneda_id']+"' min='0' max='"+item['saldodolar']+"'></td>";
			    }
			    var unaFila =   "<tr>"+
					    "<td>"+item['cc_fecha_dmy']+"</td>"+
					    "<td>"+item['tc_descripcion']+" ("+item['cc_id']+"-"+item['cc_numero']+")</td>"+
					    "<td><div class='text-right'>"+numFor.format(item['saldopesos'])+"</div></td>"+
					    "<td><div class='text-right'>"+numFor.format(item['saldodolar'])+"</div></td>"+
					    filaPesos+        //"<td><input type='number' id='aplicapesos' name='aplicapesos_"+item['cc_id']+"' min='0' max='"+item['saldopesos']+"'></td>"+
					    filaDolar+        //"<td><input type='number' id='aplicadolar' name='aplicadolar_"+item['cc_id']+"' min='0' max='"+item['saldodolar']+"'></td>"+
					    "<td>"+item['cc_comentario']+"</td>"+
					    "</tr>";
			    $('#tabla_aplica tbody').append(unaFila);
			})
			$("#div_aplica").show();
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
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function cambiaChq3ro(cId){

    var elId     = '<?=$id_form;?>';
    var elStr    = "#carterachq_"+parseInt(cId,10)+"_"+elId+" option:selected"
    var valSel   = $(elStr).val();
    var opciSel  = valSel.split("|");
    var nTotalMN = 0;
    var nTotalDi = 0;

    $("#importemepa_"+cId+"_"+elId).val(opciSel[3]);
    $("#monedamepa_" +cId+"_"+elId).val(opciSel[2]);
    $("#cotizamepa_" +cId+"_"+elId).val(opciSel[4]);

    $("#banco_" +cId+"_"+elId).val(0);

    $("#cc_caja_ori_"+cId+"_"+elId).val(opciSel[0]);  //id del mov orig de caja de ingreso del chq

    $("#importemepa_"+cId+"_"+elId).prop('readonly',true);
    $("#cotizamepa_" +cId+"_"+elId).prop('readonly',true);
    $("#monedamepa_" +cId+"_"+elId+" option:not(:selected)").attr('disabled',true); //genial!
    $("#carterachq_" +cId+"_"+elId+" option:not(:selected)").attr('disabled',true); //genial!

    calcTotal();

}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function cambiaChequera(cId){
    var elId     = '<?=$id_form;?>';
    var elStr    = "#chequeras_"+parseInt(cId,10)+"_"+elId+" option:selected"
    var valSel   = $(elStr).val();
    var opciSel  = valSel.split("|");
	var divChq   = "#divchq_"  +parseInt(cId,10)+"_"+elId;

	$(".divchqserie_"+parseInt(cId,10)+"_"+elId).hide();   //val(opciSel[2]);
	$("#chqnro_"     +parseInt(cId,10)+"_"+elId).val(opciSel[5]);
	$("#chqserie_"   +parseInt(cId,10)+"_"+elId).val(opciSel[2]);
	$("#chequera_id_"+parseInt(cId,10)+"_"+elId).val(opciSel[0]);

	$(divChq).show();

	calcTotal();
}	


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function calcTotal(nn){
    var elId      = '<?=$id_form;?>';
    var nTotalMN  = 0;
    var nTotalDi  = 0;
    var nAplicaMN = 0;
    var nAplicaDi = 0;

//totales caja
    $("#div_caja"+elId+" tbody tr").each(function (index) {
	if ( $(this).find("td").eq(2).find("select").val() == '1' ){
	    nTotalMN += Number($(this).find("td").eq(1).find("input").val());
	}else{
	    nTotalDi += Number($(this).find("td").eq(1).find("input").val());
	}
    });

    if (nn == undefined){
	totalMNForm = new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'PES' }).format(nTotalMN);
	totalDiForm = new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'USD' }).format(nTotalDi);
	$("#impo_totalmn_"+elId).text(totalMNForm);
	$("#impo_totaldi_"+elId).text(totalDiForm);
    }

//totales aplicaciones
    $("#tabla_aplica tbody tr").each(function (index) {
	for (i = 4; i <= 5; i++){
	    nMax   = Number($(this).find("td").eq(i).find("input").attr("max"));
	    nMin   = Number($(this).find("td").eq(i).find("input").attr("min"));
	    nValor = Number($(this).find("td").eq(i).find("input").val());
	    if (nValor > 0){
		if (nValor < nMin){
		    if (nn == undefined){
			alert("No debe ser menor a "+nMin);
			$(this).find("td").eq(i).find("input").focus();
			$(this).find("td").eq(i).find("input").select();
		    }
		}else if (nValor > nMax){
		    if (nn == undefined){
			alert("No debe ser mayor a "+nMax);
			$(this).find("td").eq(i).find("input").focus();
			$(this).find("td").eq(i).find("input").select();
		    }
		}else{
		    if ( i === 4){
			nAplicaMN += nValor;   // Number($(this).find("td").eq(i).find("input").val());
		    }else{
			nAplicaDi += nValor;   //Number($(this).find("td").eq(i).find("input").val());
		    }
		}
	    }
	}
    })
    if (nn == undefined){
	aplicaMNForm = new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'PES' }).format(nAplicaMN);
	aplicaDiForm = new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'USD' }).format(nAplicaDi);
	if (nAplicaMN > 0){
	    $("#aplica_totalmn").text(aplicaMNForm);
	}
	if (nAplicaDi > 0){
	    $("#aplica_totaldi").text(aplicaDiForm);
	}
    }else{
	var aArray = [ nTotalMN , nTotalDi , nAplicaMN , nAplicaDi ];
	return aArray;
    }


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
