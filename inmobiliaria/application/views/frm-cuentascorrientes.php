<?php $id_form=uniqid();?>
<form id="<?=$id_form;?>" action="<?php echo base_url('index.php/cuentascorrientes/guardaRegistro') ?>" method="POST"  data-validation="valida_cta_cte">
	<input type="hidden" readonly class="form-control" id="frm_id" name="frm_id" value="<?=$id;?>" >
	<input type="hidden" class="form-control" id="frm_idx<?=$id_form;?>" name="frm_idx<?=$id_form;?>" value="0" >
	<input type="hidden" id="frm_existecomp" name="frm_existecomp" value="0" >
	<input type="hidden" id="frm_lugval" name="frm_lugval" value="0" >
	<div class="row mi_padd">
		<div class="col-sm-2">
			<label for="frm_fecha">Fecha</label>
			<input type="date" class="form-control" id="frm_fecha" placeholder="dd-mm-yyyy" name="frm_fecha" value="<?=$fecha;?>" >    
		</div>
		<div class="col-sm-3">
			<label for="frm_entidad_id">Entidad</label>
			<select class="custom-select" id="frm_entidad_id<?=$id_form;?>" name="frm_entidad_id">
			    <?php foreach($entidades as $item){?>
				<option value="<?=$item['e_id'];?>"  <?=$item['selectado'];?> ><?=$item['e_razon_social'];?>(<?=$item['tipoentidad'];?>) </option>
			    <?php } ?>
			</select>
		</div>
		<div class="col-sm-3">
			<label for="frm_tipo_comprobante_id">Tipo Comprobante</label>
			<select class="custom-select" id="frm_tipo_comprobante_id<?=$id_form;?>" name="frm_tipo_comprobante_id" onChange="llamaCambioComprob()">
			    <?php foreach($tiposcompr as $item){?>
				<option value="<?=$item['id'];?>|<?=$item['afecta_caja'];?>|<?=$item['tipos_entidad'];?>|<?=$item['signo'];?>|<?=$item['modelo'];?>|<?=$item['aplica_impu'];?>"  <?=$item['selectado'];?> ><?=$item['descripcion'];?> </option>
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

			<div class="form-group row" id="comprob">
			    <div class="col-sm-2">
				<label for="frm_doculetra">Letra</label>
				<input class="form-control" id="frm_doculetra<?=$id_form;?>" name="frm_doculetra" type="text">
			    </div>
			    <div class="col-sm-3">
				<label for="frm_docusucu">Pto.Venta</label>
				<input class="form-control" id="frm_docusucu<?=$id_form;?>" name="frm_docusucu" type="text">
			    </div>
			    <div class="col-sm-3">
				<label for="frm_docunume">Número</label>
				<input class="form-control" id="frm_docunume<?=$id_form;?>" name="frm_docunume" type="text">
			    </div>
			    <div class="col-sm-4">
				<br>
				<button type="button" class="btn btn-primary" id="validarcomprob<?=$id_form;?>" >Validar</button>
			    </div>
			</div>
			<div class="form-group row" id="comprob1">

			    <div class="col-sm-6 " >
				<label for="frm_presupuesto_id">Presupuesto Aplicado</label>
				<select class="custom-select" id="frm_presupuesto_id<?=$id_form;?>" name="frm_presupuesto_id">
				    <?php foreach($presupuestos as $item){?>
				    <option value="<?=$item['pre_id'];?>|<?=$item['mo_id'];?>"  <?=$item['selectado'];?> ><?=$item['pre_titulo'];?> </option>
				    <?php } ?>
				</select>
			    </div>
			</div>

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
				    <th>Proyecto</th>
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
			<select id="tipomepa_0_<?=$id_form;?>" name="tipomepa[]"  class="form-control form-control-sm medipago">
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
		    <td ><input type="number" id="cotizamepa_0_<?=$id_form;?>" name="cotizamepa[]" class="form-control form-control-sm"/></td>
<!--
		    <td ><input type="text"   id="comenta_0_<?=$id_form;?>"    name="comenta[]"    class="form-control form-control-sm" /></td>
-->

		    <td><textarea class="form-control" id="comenta_0_<?=$id_form;?>" name="comenta[]" rows="2"></textarea></td>


		    <td >
			<div id="conteaux_0_<?=$id_form;?>" name="contenido_0_<?=$id_form;?>">

			    <select id="proyectos_0_<?=$id_form;?>" name="proyecto[]" class="form-control form-control-sm" >
				<?php foreach($proyectos as $item){?>
				<option class="option" value="<?=$item['p_id'];?>" ><?=$item['p_nombre'];?></option>
				<?php } ?>
			    </select>

			    <select id="ctabanc_0_<?=$id_form;?>" name="ctabanc[]" class="form-control form-control-sm ctabanc" >
				<?php foreach($ctasbancarias as $item){?>
				<option class="option" value="<?=$item['idproy'];?>" ><?=$item['denominacion'];?></option>
				<?php } ?>
			    </select>

			    <select id="chequeras_0_<?=$id_form;?>" name="chequeras[]"     class="form-control form-control-sm chequeras"> 
				<?php foreach($chequeras as $item){?>
				<option class="option" value="<?=$item['valor'];?>" ><?=$item['chq'];?></option>
				<?php } ?>
			    </select>

			    <select id="banco_0_<?=$id_form;?>" name="banco[]" class="form-control form-control-sm banco" >
				<?php foreach($bancos as $item){?>
				    <option class="option" value="<?=$item['id'];?>"  <?=$item['selectado'];?> ><?=$item['denominacion'];?></option>
				<?php } ?>
			    </select>

			    <div class="row"   id="divchq_0_<?=$id_form;?>">
				<div class="col-sm-2 divchqserie_0_<?=$id_form;?>">
				    <input type="hidden" id="chequera_id_0_<?=$id_form;?>" name="chequera_id[]"  class="form-control form-control-sm" value=""/>
				    <label for="chqserie_0_<?=$id_form;?>">Serie</label>
				    <input type="text"  id="chqserie_0_<?=$id_form;?>" name="chqserie[]" class="form-control form-control-sm chserie" maxlength="2" size="2" pattern="[A-Za-z]{2}"/>
				</div>
				<div class="col-sm-3">
				    <label for="chqnro_0_<?=$id_form;?>">Número</label>
				    <input type="text"  id="chqnro_0_<?=$id_form;?>" name="chqnro[]"    class="form-control form-control-sm chnro" maxlength="8" size="8" pattern="[0-9]{8}"/>
				</div>
				<div class="col-sm-4">
				    <label for="chqfemi_0_<?=$id_form;?>">Emisión</label>
				    <input type="date"  id="chqfemi_0_<?=$id_form;?>" placeholder="dd-mm-yyyy" name="chqfemi[]"  class="form-control form-control-sm chfemi"/>
				</div>
				<div class="col-sm-4">
				    <label for="chqfacre_0_<?=$id_form;?>">Acredita</label>
				    <input type="date"  id="chqfacre_0_<?=$id_form;?>"  placeholder="dd-mm-yyyy" name="chqfacre[]"  class="form-control form-control-sm chacre"/>
				</div>
			    </div>
			    <div class="row" id="divcartchq_0_<?=$id_form;?>">
				    <select id="carterachq_0_<?=$id_form;?>"                 name="carterachq[]"   class="form-control form-control-sm cartera<?=$id_form;?> cartera" >  </select>
				    <input type="hidden" id="cc_caja_ori_0_<?=$id_form;?>"   name="cc_caja_ori[]"  class="form-control form-control-sm" value=""/>
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

var aTiposEnti;
var iddFormu    = '<?=$idFormu;?>';
var UScotiza    = 0;
var lOtrosProy  = 0;
var idProy      = '<?=$idProyecto;?>';
var saldoInv    = [];
var elId        = '<?=$id_form;?>';
var txtError    = '';
var opMenu      = '<?=$opmenu;?>';


$(document).ready(function(e) { 

//debugger;


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


    $("#frm_lugval").val(0);
    $("#comprob").hide();
    $("#comprob1").hide();
    $("#div_aplica").hide();
    $("#frm_importe"+elId).prop('disabled',true);
    $("#frm_importe_divisa"+elId).prop('disabled',true);
    $("#frm_moneda_id"+elId).prop('disabled',true);
    $("#div_caja"+elId ).find("*").prop('disabled', true);
    $("#ctabanc_0_"+elId).hide();
    $("#proyectos_0_"+elId).hide();
    $("#banco_0_"+elId).hide();
    $("#divchq_0_"+elId).hide();
    $("#divcartchq_0_"+elId).hide();
    $("#chequeras_0_"+elId).hide();
    $("#tipomepa_0_"+elId).off();
    $("#tipomepa_0_"+elId).on('change', function(e){cambiaSelect(0,1)});
//    $("#importemepa_0_"+elId).on('change', function(e){modificaImpo(0,1)});
    $("#importemepa_0_"+elId).on('blur', function(e){modificaImpo(0,1)});
    $("#carterachq_0_"+elId).off();
    $("#carterachq_0_"+elId).on('change', function(e){cambiaChq3ro(0)});
    $("#chequeras_0_"+elId).off();
    $("#chequeras_0_"+elId).on('change', function(e){cambiaChequera(0)});
    $("#cotizamepa_0_"+elId).attr('value',UScotiza);
    $("#addrow<?=$id_form;?>").on("click", function () {
        var newRow = $("<tr>");
        var cols   = "";
	var cId    = counter.toString();

	cols += '<td ><select              id="tipomepa_'   +counter+'_'+elId+'" name="tipomepa[]"     class="form-control form-control-sm medipago"></select> </td>';
	cols += '<td ><input type="number" id="importemepa_'+counter+'_'+elId+'" name="importemepa[]"  class="form-control form-control-sm impocaja'+elId+'"  />         </td>';
	cols += '<td ><select              id="monedamepa_' +counter+'_'+elId+'" name="monedamepa[]"   class="form-control form-control-sm"></select> </td>';
	cols += '<td ><input type="number" id="cotizamepa_' +counter+'_'+elId+'" name="cotizamepa[]"   class="form-control form-control-sm" value="'+UScotiza+'"/> </td>';
//	cols += '<td ><input type="text"   id="comenta_'    +counter+'_'+elId+'" name="comenta[]"      class="form-control form-control-sm"/>         </td>';

	cols += '<td><textarea class="form-control" id="comenta_' +counter+'_'+elId+'" name="comenta[]" rows="2"></textarea> </td>';

	cols += '<td >';
	cols += '     <select id="proyectos_'  +counter+'_' +elId+'" name="proyectos[]"   class="form-control form-control-sm proyec"></select> ';
	cols += '     <select id="ctabanc_'    +counter+'_' +elId+'" name="ctabanc[]"     class="form-control form-control-sm ctabanc"></select> ';
//	cols += '     <select id="chequeras_'  +counter+'_'+elId+'"  name="chequeras[]"   class="form-control form-control-sm chequeras"></select> ';
	cols += '    <select id="chequeras_'   +counter+'_'+elId+'" name="chequeras[]"     class="form-control form-control-sm chequeras"> <?php foreach($chequeras as $item){?> <option class="option" value="<?=$item["valor"];?>" ><?=$item["chq"];?></option> <?php } ?>  </select> ';
	cols += '     <select id="banco_'      +counter+'_'+elId+'"  name="banco[]"       class="form-control form-control-sm banco"></select> ';
	cols += '     <div class="row"     id="divchq_'     +counter+'_'+elId+'">';
	cols += '          <div class="col-sm-2 divchqserie'+counter+'_'+elId+'">';
	cols += '             <input type="hidden" id="chequera_id_'+counter+'_'+elId+'" name="chequera_id[]"  class="form-control form-control-sm" value=""/> ';
	cols += '             <label for="chqserie_'+counter+'_'+elId+'">Serie</label>';
	cols += '             <input type="text"  id="chqserie_'+counter+'_'+elId+'" name="chqserie[]" class="form-control form-control-sm chserie" maxlength="2" size="2" pattern="[A-Za-z]{2}"/>';
	cols += '          </div>';
	cols += '          <div class="col-sm-3">';
	cols += '             <label for="chqnro_'+counter+'_'+elId+'">Número</label>';
	cols += '             <input type="text"  id="chqnro_'+counter+'_'+elId+'" name="chqnro[]" class="form-control form-control-sm chnro" maxlength="8" size="8" pattern="[0-9]{8}"/>';
	cols += '          </div>';
	cols += '          <div class="col-sm-4">';
	cols += '             <label for="chqfemi_'+counter+'_<?=$id_form;?>">Emisión</label>';
	cols += '             <input type="date"  id="chqfemi_'+counter+'_'+elId+'" placeholder="dd-mm-yyyy"  name="chqfemi[]"  class="form-control form-control-sm chfemi"/>';
	cols += '          </div>';
	cols += '          <div class="col-sm-4">';
	cols += '             <label for="chqfacre_'+counter+'_'+elId+'">Acredita</label>';
	cols += '             <input type="date"  id="chqfacre_'+counter+'_'+elId+'"  placeholder="dd-mm-yyyy" name="chqfacre[]"  class="form-control form-control-sm chacre"/>';
	cols += '          </div>';
	cols += '     </div>';
	cols += '     <div class="row"     id="divcartchq_'         +counter+'_'+elId+'">';
	cols += '             <select id="carterachq_'              +counter+'_'+elId+'" placeholder="dd-mm-yyyy" name="carterachq[]"   class="form-control form-control-sm cartera'+elId+' cartera"></select> ';
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
	$("#proyectos_0_" +elId+" .option").clone().appendTo("#proyectos_"+counter+"_"+elId);
	$("#tipomepa_"+counter+"_"+elId).off();
	$("#tipomepa_"+counter+"_"+elId).on('change', function(e){cambiaSelect(cId,1)});
	$("#monedamepa_"+counter+"_"+elId).off();
	$("#monedamepa_"+counter+"_"+elId).on('change',function(e){cambiaSelect(cId,2)});
	$("#banco_"+counter+"_"+elId).off();
	$("#banco_"+counter+"_"+elId).on('change', function(e){cambiaSelect(cId,3)});
	$("#proyectos_"+counter+"_"+elId).off();
	$("#proyectos_"+counter+"_"+elId).on('change', function(e){cambiaSelect(cId,4)});
	$("#ctabanc_"+counter+"_"+elId).off();
	$("#ctabanc_"+counter+"_"+elId).on('change', function(e){cambiaSelect(cId,4)});
	$("#carterachq_"+counter+"_"+elId).off();
	$("#carterachq_"+counter+"_"+elId).on('change', function(e){cambiaChq3ro(cId)});
	$("#chequeras_"+counter+"_"+elId).off();
	$("#chequeras_"+counter+"_"+elId).on('change', function(e){cambiaChequera(cId)});
//	$("#importemepa_"+counter+"_"+elId).on('change', function(e){modificaImpo(cId)});
	$("#importemepa_"+counter+"_"+elId).on('blur', function(e){modificaImpo(cId)});
	$("#proyectos_"+counter+"_"+elId).hide();
	$("#ctabanc_"+counter+"_"+elId).hide();
	$("#banco_"+counter+"_"+elId).hide();
	$("#divchq_"    +counter+"_"+elId).hide();
	$("#divcartchq_"+counter+"_"+elId).hide();
	$("#chequeras_"+counter+"_"+elId).hide();

	calcTotal(22);

        counter++;
    });

    $("#myTablaCaja_"+elId).on("click", ".ibtnDel", function (event) {
	$(this).closest("tr").remove();
    });

    $("#div_caja"+elId ).change(function(){
	calcTotal(2);  //()
    });

    $("#tbodydeuda").change(function(){
	calcTotal(3); //()
    });

    $("#frm_entidad_id"+elId ).change(function(){
	//debe recuperar tipos comprob. y propiedades
	recuTiposComp($(this).val());
	recuPropie($(this).val());
    });


    $("#validarcomprob"+elId).click(function(){
	if (!ValidarComp()){;
	    $("#frm_doculetra"+elId).focus();
	    $("#frm_doculetra"+elId).select();
	}
    });



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
	var proyec     = "#proyectos_" +nnId+"_"+elId;
	var Bancos     = "#banco_"   +nnId+"_"+elId;
	var divChq     = "#divchq_"  +nnId+"_"+elId;
	var chqCart    = "#divcartchq_"+nnId+"_"+elId;
	var chequeras  = "#chequeras_"+nnId+"_"+elId;
	var opciCCSel  = elStr.split("|");
//	var elTipo     = $("#frm_tipo_comprobante_id"+elId+" option:selected").val();
//	var opciTipo   = elTipo.split("|");

	saldoInv       = [];

//debugger;

	if (opciSel[8]!=9){		//si no es canje(9) va a validar la mezcla de proy
	    if (opciSel[6] != 0){	//==1 permite entre proyectos
		if (lOtrosProy == 0){	//no permite otros proy en fac
//		    alert("NO SE PUEDE INDICAR OTROS PROYECTOS");
//		    $("#tipomepa_"+parseInt(nI,10)+"_"+elId).val( $("#tipomepa_"+parseInt(nI,10)+"_"+elId+" option:first-child").val() );
//		    return false;
		}
	    }
	}


	if (opciSel[8] == 9){  // debe traer saldo deudor del proveedor para validar el importe a ingresar en el canje(9)
		$(ctaBanc).hide();
		$(Bancos).hide();
		$(divChq).hide();
		$(chqCart).hide();
		$(chequeras).hide();
		$(proyec).hide();
		var fechaHasta = new Date().toISOString().split('T')[0];
		$.ajax({
			url : "<?=$urlxSaldoEnti;?>",
			type : 'GET',
			dataType : 'json',
			data : { identi : idInv , invprov : 32 , fecha : fechaHasta},
			success : function(json) {
			    saldoInv   = json;
			}
		});

	}else if (opciSel[1] == 1){ //gestinona chqs(1) 9,13,10,14
	    if (opciSel[3].trim() === 'S'){ //Salida(S) chq egreso, puede ser cartera (abre cartera y muestra chqs sin salir) o propio (muestra ctas banc. y chequeras de la cta) 10,14  (9,13 carteras)
		$(divChq).hide();
		$(Bancos).hide();
		if (opciSel[2] == 0){  // no gestiona cta.banc.(0), muestra cartera
			$(ctaBanc).hide();
			$.ajax({
				url : "<?=$urlxChqCart;?>",
				type : 'GET',
				dataType : 'json',
				data : { echq : opciSel[5], adepo : opciSel[11] },
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
					var cCarteras = document.getElementsByClassName("cartera_"+nnId+"_"+elId);  //select en la celda de la grilla
					if (typeof json === 'object'){
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
					}
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
			//console.log(lOtrosProy); //1->permite, 0->no permite
			$.ajax({
				url : "<?=$urlxChequeras;?>",
				type : 'GET',
				dataType : 'json',
				data : { echq : opciSel[5], otrasctas : lOtrosProy},
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
					var cCarteras = document.getElementsByClassName("chequeras_"+nnId+"_"+elId);  //select en la celda de la grilla
					if (typeof json === 'object'){
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
					}
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

	}else if (opciSel[2] == 1){ //gestiona ctas banc(1) 3,4 pago/cobro x banco
		$(ctaBanc).show();
		//si es de otros proy o del propio, show o hide de las options
		$(ctaBanc+" option").each(function(){
		    xStr      = $(this).attr('value');
		    opciXStr  = xStr.split("|");
		    $(this).hide();
		    if (opciSel[6] != 0){   //para ctas de otros proy
			if (opciXStr[1] != idProy  ){
			    $(this).show();
			}
		    }else{                 //para ctas del proy selectado
			if (opciXStr[1] == idProy  ){
			    $(this).show();
			}
		    }
		});
		$(Bancos).hide();
		$(divChq).hide();
		$(chqCart).hide();
		$(chequeras).hide();
		if (opciSel[3].trim === "S"){ //[S]alida pago egreso 4
		}else{  //[E]ntradapago ingreso 3
		}

	}else if (opciSel[3].trim() == 'X'){  // efectivo(1)
		$(ctaBanc).hide();
		$(Bancos).hide();
		$(divChq).hide();
		$(chqCart).hide();
		$(chequeras).hide();

	}else if (opciSel[7] == 1){  // retenciones de otros proyectos
		$(ctaBanc).hide();
		$(Bancos).hide();
		$(divChq).hide();
		$(chqCart).hide();
		$(chequeras).hide();
		$(proyec).show();

	}
    }
});


////////////////////////////////////////////////////////////////////////////////////////////
    function modificaImpo(nI){   //  nI puntero de la fila (tr) 
	var nnId       = parseInt(nI);
	var elStr      = "#tipomepa_"+parseInt(nI,10)+"_"+elId+" option:selected"
	var valSel     = $(elStr).val();
	var opciSel    = valSel.split("|");
	var totPagos   = [0,0];
	var lR         = 1;

	if (opciSel[8] == 9){

//debugger;

	    $("#div_caja"+elId+" tbody tr").each(function (index) {
		valSel   = $(this).find("td").eq(0).find("select").val();   //medio pago
		var si89 = valSel.split("|");
		var mone = $(this).find("td").eq(2).find("select").val();
		if (si89[8] == 9){
		    totPagos[mone - 1] += Number($(this).find("td").eq(1).find("input").val());
		}
	    });
	    var ultSaldo = saldoInv[saldoInv.length-1];

//	    console.log("saldoInv");  //saldo del proveedor-inversor como inversor
//	    console.log(saldoInv);  //saldo del proveedor-inversor como inversor
//	    console.log(totPagos);

	    //analizar proyecto actual y provee
	    //fact bl solo acepta saldo proy actual 
	    //fact nn acepta saldo de todos proy
	    //idProy  proy actual

	    $("#tabla_aplica tbody tr").each(function (index) {
		var tipoComp  = $(this).attr("class"); //1 fac, 0 remi
		var elProy    = $(this).find("td").eq(7).attr("class");
		var impoApli  = 0;


		if ($(this).find("td").eq(4).find("input").length > 0){  //input mn
		    impoApli += Number($(this).find("td").eq(4).find("input").val());
		}

		if ($(this).find("td").eq(5).find("input").length > 0){  //input div
		    impoApli += Number($(this).find("td").eq(5).find("input").val());
		}

		if (impoApli > 0){
		    if (tipoComp == 1){  //si es fac, solo acepta canje del proy

			if (elProy != idProy){
			    alert("NO SE PUEDE REALIZAR CANJE SOBRE DIFERENTES PROYECTOS");
			    lR = 0;
			}
/*no va
			for (var ii = 0 ; ii < saldoInv.length-1 ; ii++){
			    if (elProy != saldoInv[ii].proyecto){
				alert("NO SE PUEDE REALIZAR CANJE SOBRE DIFERENTES PROYECTOS");
				lR      = 0;
//				$("#importemepa_"+parseInt(nI,10)+"_"+elId).focus();
//				$("#importemepa_"+parseInt(nI,10)+"_"+elId).select();
				break;
			    }
			}
*/
		    }
		    if (lR == 0){
			return false;
		    }
		}
	    });

	    if (lR == 1){
		if (ultSaldo['saldo_mn']<totPagos[0] || ultSaldo['saldo_div']<totPagos[1]){
		    lR = 0;
		    if (confirm("SUPERA LOS SALDOS PARA APLICAR CANJE: \nSaldo $: "+ultSaldo['saldo_mn']+"\nSaldo u$s: "+ultSaldo['saldo_div']+"\nAplica igualmente el importe?")){
			lR = 1;
		    }
		}
	    }else{

//			$(this).find("td").eq(i).find("input").focus();
//			$(this).find("td").eq(i).find("input").select();

	    }
	}
	return lR;
    }




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
    //z[2] es el tipo de entidad del comprobante 1->inversor, 2->proveedor
    //z[3] signo
    //z[4] modelo
    //z[5] aplica

    $("#comprob").hide();
    $("#comprob1").hide();


    if (opMenu != 49){
	if (z[2] == 2 && z[4] <= 3){
	    $("#comprob").show();
	    $("#comprob1").show();
	}
    }

//debugger

    traeDeuda(idInv,z);
    //filtra medios de pago de acuerdo cuando es rec u o/p, hay q filtrar el canje si la entidad no es inver y provee y rec

    var invprov  = 0;
    var tipoEnti = $("#frm_entidad_id"+elId+" option:selected").text();
    if (tipoEnti.includes('Inversor')){
	if (tipoEnti.includes('Proveedor')){
	    invprov = 1;
	}
    }


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


//	if (bb[8] == 9 && invprov == 0){   //es canje y no es inv+prov, no lo muestra

	if (bb[8] == 9 && z[4] == 4){   //es canje y recibo, no lo muestra

	}else if (bb[3]=='X'){             //medio de pago X (Entrada/Salida) siempre lo muestra
	    $(this).show();
	}else if (bb[3]=='E'){             //medio de pago de Entrada 
	    if (z[2] != 2 && z[3] == -1){  //no es proveedor y va al haber (recibos)
		$(this).show();
	    }
	}else if (bb[3]=='S'){             //medio de pago de Salida
	    if (z[2] = 2 && z[3] == 1){    //es proveedor y va al debe (O/P)
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

    var aTiposOPRE = [4,5,3];
    //z[0] id
    //z[1] afecta caja
    //z[2] es el tipo de entidad del comprobante 1->inversor, 2->proveedor
    //z[3] signo
    //z[4] modelo
    //z[5] aplica
    //si es o/p z[2]->1, si es recibo z[2]->2
    $("#div_aplica").hide();
    $("#tabla_aplica > tbody").empty();

//debugger;

console.log(opMenu);
console.log(parseInt(z[4],10));



    if (opMenu == 49 && parseInt(z[4],10) === 4){  //filtra cuando es recibo de prestamista, no recupera nada


    }else{

	if (aTiposOPRE.find(element => element === parseInt(z[4],10))){

	    $.ajax({
		url : "<?=$urlrecudeuda;?>",
		type : 'GET',
		dataType : 'json',
		data : { identi : idInv, modelocomp : z[4] },
		success : function(json) {

console.log(json);

		    if (json.length >0){
			json.forEach (function(item,index){
			    const numFor = new Intl.NumberFormat("en-US", {style: "currency",currency: "USD", });       //'es-ES');   //,{style:"currency",currency:"$"});
			    filaPesos = "<td></td>";
			    filaDolar = "<td></td>";

			    if (item['saldopesos'] > 0){
				filaPesos = "<td><input type='number' id='aplicapesos' name='aplicapesos_"+item['cc_id']+"_1' min='0' max='"+item['saldopesos']+"'></td>";
			    }
			    if (item['saldodolar'] > 0){
				filaDolar = "<td><input type='number' id='aplicadolar' name='aplicadolar_"+item['cc_id']+"_2 min='0' max='"+item['saldodolar']+"'></td>";
			    }

			    var unaFila =   "<tr class='"+item['tc_aplica_impu']+"'>"+
					    "<td>"+item['cc_fecha_dmy']+"</td>"+
					    "<td>"+item['tc_descripcion']+" ("+item['cc_id']+"-"+item['cc_numero']+")</td>"+
					    "<td><div class='text-right'>"+numFor.format(item['saldopesos'])+"</div></td>"+
					    "<td><div class='text-right'>"+numFor.format(item['saldodolar'])+"</div></td>"+
					    filaPesos+        //"<td><input type='number' id='aplicapesos' name='aplicapesos_"+item['cc_id']+"' min='0' max='"+item['saldopesos']+"'></td>"+
					    filaDolar+        //"<td><input type='number' id='aplicadolar' name='aplicadolar_"+item['cc_id']+"' min='0' max='"+item['saldodolar']+"'></td>"+
					    "<td>"+item['cc_comentario']+"</td>"+
					    "<td class='"+item['cc_proyecto_id']+"'>"+item['p_nombre']+"</td>"+
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

//    $("#cc_caja_ori_"+cId+"_"+elId).val(opciSel[0]);  //id del mov orig de caja de ingreso del chq

//2023-04-17 arrastro todos los valores del chq selectado
    $("#cc_caja_ori_"+cId+"_"+elId).val(valSel);  //id del mov orig de caja de ingreso del chq




    $("#importemepa_"+cId+"_"+elId).prop('readonly',true);
    $("#cotizamepa_" +cId+"_"+elId).prop('readonly',true);
    $("#monedamepa_" +cId+"_"+elId+" option:not(:selected)").attr('disabled',true); //genial!
//    $("#carterachq_" +cId+"_"+elId+" option:not(:selected)").attr('disabled',true); //genial!
    calcTotal(4); //()

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
    calcTotal(5); //()
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function calcTotal(nn){
    var elId       = '<?=$id_form;?>';
    var nTotalMN   = 0;
    var nTotalDi   = 0;
    var nAplicaMN  = 0;
    var nAplicaDi  = 0;
    var apliValida = 0; 
    var lC1 = false;
    var lC0 = false;
    var lA1 = false;
    var lA0 = false;
    var lValiPago      = true;
    var elStr          = $("#frm_tipo_comprobante_id"+elId+" option:selected").val();
    var opciCCSel      = elStr.split("|");
    var aApli          = [];
    var aPagos         = [];
    var celda          = [];
    var aTipoMov       = [];  //0->no usados,1-> efectivo,2-> chq 3ro,3-> echq 3ro,4-> chq propio,5-> echq propio,6-> cobro/pago por banco,7-> gastos bancarios,8-> retenciones
    var aTipoCompl     = [];  //0->no usados,1-> efectivo,2-> chq 3ro,3-> echq 3ro,4-> chq propio,5-> echq propio,6-> cobro/pago por banco,7-> gastos bancarios,8-> retenciones
    var aFacRem        = [0,0];
    var aPagOtr        = [0,0];   //0-> 1: tiene pagos proy prop, 1-> 1: tiene pagos otros proy
    var nImporte       = 0;

console.log("calcTotal");

//debugger;

//totales caja
    $("#div_caja"+elId+" tbody tr").each(function (index) {
	if ( $(this).find("td").eq(2).find("select").val() == '1' ){
	    nTotalMN += Number($(this).find("td").eq(1).find("input").val());
	}else{
	    nTotalDi += Number($(this).find("td").eq(1).find("input").val());
	}

//buscar chqs
	if (opciCCSel[4] == 5){   // O/P
	    //el eq(3) indica q el 3er elemento dentro del td es el select de la cartera, 
	    //OJO!!! con cambiar posiciones de los objs
	    aAtrChq = $(this).find("td").eq(5).find("select").eq(3).val();
	    if (aAtrChq != null){
		aAtrChq = aAtrChq.split('|');
		//                      0 3ro, 1 a depo
		celda   = [ aAtrChq[6], aAtrChq[5] ];
		aPagos.push(celda);
	    }
	    var valSel   = $(this).find('td').eq(0).find("select").val();
	    var opciSel  = valSel.split("|");
	    if (opciSel[6] == 0){ 
		aPagOtr[0] = 1;   //pago proy propio
	    }else{
		aPagOtr[1] = 1;   //pago otro proy
	    }
	    aArrOpci = opciSel[10].trim().split("");
	    aTipoMov.push([opciSel[8],opciSel[7], aArrOpci ]);  //8->tipo_mov ,7->pide_proyectos 
	    aTipoCompl.push([opciSel, Number($(this).find("td").eq(1).find("input").val())]);
	}

    });

    totalMNForm = new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'PES' }).format(nTotalMN);
    totalDiForm = new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'USD' }).format(nTotalDi);
    $("#impo_totalmn_"+elId).text(totalMNForm);
    $("#impo_totaldi_"+elId).text(totalDiForm);

//totales aplicaciones

//debugger;

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
			nAplicaMN += nValor;   //Number($(this).find("td").eq(i).find("input").val());
		    }else{
			nAplicaDi += nValor;   //Number($(this).find("td").eq(i).find("input").val());
		    }
		}
	    }
	    if (nValor > 0){   //detecta si la aplicacion es una fac. o un remito
		//        --------------proyecto---------------   -----tipo comprob---
		celda = [ $(this).find("td").eq(7).attr("class"), $(this).attr("class") ] ;
		aApli.push(celda);
		aFacRem[$(this).attr("class")] = 1;  // attr class:  0->remi, 1->fact
	    }
	}
    })
    aplicaMNForm = new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'PES' }).format(nAplicaMN);
    aplicaDiForm = new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'USD' }).format(nAplicaDi);
    if (nAplicaMN > 0){
	$("#aplica_totalmn").text(aplicaMNForm);
    }
    if (nAplicaDi > 0){
	$("#aplica_totaldi").text(aplicaDiForm);
    }

    //--> 2023-10-16 ojo q lo comento por prueba de mezclar chequeras    lOtrosProy = (aFacRem[0]==1 && aFacRem[1]==0) ? 1 : 0; //permite o no mezclar proyectos

    if (opciCCSel[4] == 5){   //es O/P, debe validar
	lOtrosProy    = 1;
	arrApliValida = [0,0,0,0];
	aApli.forEach(function(unaApl){
	    if (unaApl[0] == idProy){ //aplica compr.mismo proy
		if (unaApl[1]==1){    //aplica compr.c/impu   1
		    arrApliValida[0] = 1;
		}else{                 //aplica compr.s/impu  2
		    arrApliValida[1] = 1;
		}
	    }else{                     ////aplica compr.distinto proy
		if (unaApl[1]==1){    //aplica compr.c/impu   4
		    arrApliValida[2] = 1;
		}else{                 //aplica compr.s/impu  8
		    arrApliValida[3] = 1;
		}
	    }
	});
	lFlag = 0;
	aTipoMov.forEach(function(aArr){
	    xArr2 = aArr[2]; //
	    for(i = 0; i < xArr2.length; i++){
		if (xArr2[i] == 0 && arrApliValida[i] == 1){
		    console.log("pago incorrecto");
		    if(nn != 1){
			alert("VERIFIQUE LAS APLICACIONES Y LOS PAGOS, HAY COMBINACIONES INCORRECTAS");
		    }
		    lFlag  = 25;
		}
	    }
	})
	if (lFlag > 0){
	    return lFlag;
	}
    }

    lFlag      = 0;
    aPagos.forEach(function(unPago){
	aApli.forEach(function(unaApl){
	    if (unaApl[1] == 0 && unPago[1] == 1){   //bloquea si comp es remi y chq a depo
		lFlag = 1;
	    }else if (unaApl[0] == unPago[0]){ //mismo proyecto en comp y chq
		//no bloquea 
	    }else{       //chq y comp. mismo proyecto
		if ( !(unaApl[1] == 0 && unPago[1] == 0) ){ //distintos tipos compr. y chqs 
		    lFlag = 2;
		}
	    }
	});
    });

    lFlag = 0;
    aPagos.forEach(function(unPago){
	aApli.forEach(function(unaApl){
	    //chq a depo          el proyecto del chq no es el de la aplicacion
	    if (unPago[1] == 1 && unPago[0] != unaApl[0]){
		lFlag = 1;
		return;
	    }
	});
	if (lFlag == 1){
	    return;
	}
    });

    lFlag = 0;
    //valida q una ret se aplique solo a fact y si es ret sin pedir proy, no puede aplicar a fac de otros proy
    aTipoMov.forEach(function(unMov){
	if (unMov[0] == 8){
	    aApli.forEach(function(unaApl){
		if (unaApl[1] == 0){
		    lFlag = 8;
		}
	    });
	}
    });

    switch (lFlag){
	case 0:
	    break;
	case 1:
	    alert("Verifique que está pagando un remito con chq a depositar " + nn);
	    break;
	case 2:
	    alert("Verifique, la combinación de pago no está permitida " + nn);
	    break;
	case 8:
	    alert("Verifique, no puede aplicar una retención a comprobantes que no sean facturas!! ");
	    break;
    }

    if (nn == 1){  //valida totales
	var aArray = [ nTotalMN , nTotalDi , nAplicaMN , nAplicaDi, lFlag ];
	return aArray;
    }
    return lFlag
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function valida_medios_pago(){
    var elId      = '<?=$id_form;?>';
    var elStr          = $("#frm_tipo_comprobante_id"+elId+" option:selected").val();
    var opciCCSel      = elStr.split("|");
    var aApli          = [];
    var aPagos         = [];
    var celda          = [];
    var aTipoMov       = [];  //0->no usados,1-> efectivo,2-> chq 3ro,3-> echq 3ro,4-> chq propio,5-> echq propio,6-> cobro/pago por banco,7-> gastos bancarios,8-> retenciones
    var aFacRem        = [0,0];
    var aPagOtr        = [0,0];   //0-> 1: tiene pagos proy prop, 1-> 1: tiene pagos otros proy
    var lRet           = 20;
    var aArrReOP       = ['4','5'];
    var aArrCart       = ['2','3'];
    txtError = '';

//debugger;

    $("#div_caja"+elId+" tbody tr").each(function (index) {
	medioPago = $(this).find("td").eq(0).find(".medipago").val();
	if ( medioPago != ''){
	    if (lRet == 20){
		aMedioPago = medioPago.split('|');
		if ( aArrReOP.includes(opciCCSel[4]) ){      // si es rec u o/p
		    lRet = 0;
		    if (opciCCSel[4]==4){  //recibo
			if (aMedioPago[2] == 1 ){  //rec gestiona cta.banc.
			    lRet = 20;
			    if ($(this).find("td").eq(5).find(".ctabanc").val() == '0|0' ){   //no tiene cta.banc.
				lRet = 9;
				console.log($(this).find("td").eq(5).find(".ctabanc").val());
				txtError = "No se indicó cuenta bancaria";
			    }
			}else if (aMedioPago[1] == 1 ){  //reci pide banco porq es chq recibido
			    if ($(this).find("td").eq(5).find(".banco").val() < 1 ){               //no tiene banco
				lRet = 1;
				console.log($(this).find("td").eq(5).find(".banco").val());
				txtError = "No se indicó banco";
			    }
			    if (lRet==0){
				lRet = validaChq(this);  //si el chq ok, devuelve 20
			    }
			}else{ lRet = 20 }
		    }else{       // o/p
xx=1;
			if (aMedioPago[2] == 1 && aMedioPago[1] == 0){  //rec gestiona cta.banc.
			    lRet = 20;
			    if ($(this).find("td").eq(5).find(".ctabanc").val() == '0|0' ){   //no tiene cta.banc.
				lRet = 9;
				console.log($(this).find("td").eq(5).find(".ctabanc").val());
				txtError = "No se indicó cuenta bancaria";
			    }
			}else if ( aArrCart.includes(aMedioPago[8].trim()) ){  //cartera
			    lRet = 20;
			    if ($(this).find("td").eq(5).find(".cartera").val() == -1){
				lRet = 10;
				console.log($(this).find("td").eq(5).find(".cartera").val());
				txtError = "No se indicó cheque en cartera";
			    }
			}else if (aMedioPago[1] == 1 ){  // o/p chequera
			    if ($(this).find("td").eq(5).find(".chequeras").val() == -1 ){          //no chequera
				lRet = 8;
				console.log($(this).find("td").eq(5).find(".chequeras").val());
				txtError = "No se indicó chequera";
			    }
			    if (lRet==0){
				lRet = validaChq(this);  //si el chq ok, devuelve 20
			    }
			}else{ lRet = 20 }
		    }
		}
	    }
	}else{ lRet = 7;
	    console.log(medioPago);
	    txtError = "No se indicó medio pago";
	}
    });
    return lRet;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function validaChq(xx){

    var lRet = 20;
    if ($(xx).find("td").eq(5).find(".chserie").val() != ""){ //tiene serie
	if ($(xx).find("td").eq(5).find(".chnro").val() > 0){   //tiene nro
	    fechaFemi = $(xx).find("td").eq(5).find(".chfemi").val();
	    if ( fechaFemi != "" ){                               //tiene fecha emi
		fechaAcre = $(xx).find("td").eq(5).find(".chacre").val();
		if ( fechaAcre != "" ){                           //tiene fecha acre
		    if ( fechaFemi <= fechaAcre ){                //tiene fecha emi <= fecha acre
			lRet = 20;
		    }else{ lRet = 6 ;
			console.log("fecha emi > fecha acre");
			txtError = "No puede haber una fecha de emisión mayor que la de acreditación";
		    }
		}else{ lRet = 5 ;
		    console.log($(xx).find("td").eq(5).find(".chacre").val());
		    txtError = "No se indicó fecha de acreditación";
		}
	    }else{ lRet = 4 ;
		console.log($(xx).find("td").eq(5).find(".chfemi").val());
		txtError = "No se indicó fecha de emisión";
	    }
	}else{ lRet = 3 ;
	    console.log($(xx).find("td").eq(5).find(".chnro").val());
	    txtError = "No se indicó número";
	}
    }else{ lRet = 2;
	console.log($(xx).find("td").eq(5).find(".chserie").val());
	txtError = "No se indicó serie";
    }
    return lRet;
}


////////////////////////////////////////////////////////////////////////////////////////////////////
function ValidarComp(){
	elComp    = $("#frm_tipo_comprobante_id"+elId+" option:selected").val();
	$tipoComp = elComp.split("|");

debugger;

	elFrmImporte = $("#frm_importe"+elId).val();
	if (elFrmImporte > 0){
		var elFrmPresu   = $("#frm_presupuesto_id"+elId+" option:selected").val();
		var laMoneda     = $("#frm_moneda_id"+elId+" option:selected").val();
		var xyz          = elFrmPresu.split("|");
		if (xyz[0] != 0){
			if (xyz[1] != laMoneda){
				alert("NO COINCIDE EL TIPO DE DIVISA DEL COMPROBANTE CON EL DEL PRESUPUESTO");
				$("#frm_moneda_id"+elId).focus();
				$("#frm_moneda_id"+elId).select();
				return false;
			}
		}
		//$("#frm_presupuesto_id"+elId).val(xyz[0]);
	}

	if ($tipoComp[2] == 2 &&  $tipoComp[4] <= 3){ 
	    if ($("#frm_doculetra"+elId).val() != ''){
		if ($("#frm_docusucu"+elId).val() != 0){
		    if ($("#frm_docunume"+elId).val() != 0){
			elCli  = $("#frm_entidad_id"+elId ).val();
			elDocu = $("#frm_tipo_comprobante_id"+elId+" option:selected").val();
			elComp =   [$("#frm_doculetra"+elId).val(),
				    $("#frm_docusucu" +elId).val(),
				    $("#frm_docunume" +elId).val()];
			$("#frm_existecomp").val(0);
			$.ajax({url      : "<?=$urlxValiComp;?>",
			    type     : 'GET',
			    dataType : 'json',
			    async    : false,
			    data     : {  identi   : $("#frm_entidad_id"+elId ).val()
					, docul    : $("#frm_doculetra"+elId).val()
					, docus    : $("#frm_docusucu"+elId).val()
					, docun    : $("#frm_docunume"+elId).val()
					, tipocomp : $("#frm_tipo_comprobante_id"+elId+" option:selected").val() },
			    success  : function(json) {
				if (json > 0){
				    $("#frm_existecomp").val(1);
				    alert("EXISTE EL COMPROBANTE!");
				}else{
				    if ($("#frm_lugval").val() == 0){
					alert("NO EXISTE EL COMPROBANTE!");
					$("#frm_lugval").val(0);
				    }
				}
			    }
			});
			return true;
		    }
		}
	    }
	    alert("Faltan datos en el comprobante!");

//debugger;

	    return false;
	}
	return true;
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
		    console.log($(this).find("td").eq(5));
		});

		if (lRet == false){
			alert("VERIFIQUE, FALTA INGRESAR UN IMPORTE!");
			lRet = false;
		}else{
		    var aArray = calcTotal(1);  //(1)
		    if (typeof aArray == 'number'){
			if (aArray > 0){ 
			    alert("EL COMPROBANTE NO SE PUEDE REGISTRAR PORQUE HAY INCONSISTENCIAS ENTRE LOS PAGOS Y LAS APLICACIONES");
			    lRet = false;
			}
		    }else if (aArray[0]<aArray[2] || aArray[1]<aArray[3]){
			alert("Verifique los totales, lo aplicado no puede ser superior a lo registrado en caja");
			lRet = false;
		    }else if (aArray[0]+aArray[1]+aArray[2]+aArray[3] == 0){
			alert("No se ha ingresado ni aplicaciones ni medios de pago");
			lRet = false;
		    }else if (aArray[4] == 8){ //esta aplicando ret a no fac
			lRet = false;
		    }
		}

		if (valida_medios_pago()<20){
		    alert("FALTAN DATOS EN MEDIOS DE PAGO "+txtError);
		    return false;
		}

		$("#div_caja"+nId+" tbody tr").each(function (index) {
			var nR = modificaImpo(index);
			if ( nR == 0 ){  //valida si hay canjes > q los saldos como inver.
//			    $(this).find("td").eq(1).find("input").focus();
//			    $(this).find("td").eq(1).find("input").select();
			    lRet = false;
			}

		});
		if (!lRet){ 
			return lRet;
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

	if (lRet){
	    $("#frm_lugval").val(1);
	    lR = ValidarComp();
	    if ( $("#frm_existecomp").val() == 1 || !lR){
		$("#frm_doculetra"+elId).focus();
		$("#frm_doculetra"+elId).select();
		return false;
	    }
	}
	return lRet;
}

</script>
