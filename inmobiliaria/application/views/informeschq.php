
<!-- header -->
<?php $this->load->view('header');?>


<style>
thead {
    color: White;
    background-color: SlateBlue;
    position: sticky;
    top: 0;
    z-index: 10;
}
</style>



<div class="row" id="divinfocaja" name="divinfocaja">
    <div class="main" style='padding-left:15px;'>
	<h5><b>Informe de Cheques</b></h5>
	    <div style='padding-top:20px;'>
		<div class="btn btn-success">
		    <label for="frm_tipo_chq">Tipo de cheques</label>
		    <select class="custom-select" id="frm_tipo_chq" name="frm_tipo_chq">
			<option value="T"> Terceros en cartera</option>
			<option value="E"> Terceros entregados</option>
			<option value="P"> Propios  </option>
		    </select>
		</div>

		<div class="btn btn-success">
		    <label for="chqadepo">a Depositar</label>
		    <input type="checkbox"  id="chqadepo" name="chqadepo" value="1" class="form-control" checked/>
		</div>


		<div class="btn btn-success">
		    ordenado por: 
		    <select class="custom-select" id="frm_tipo_fecha" name="frm_tipo_fecha">
			<option value="A"> Fecha de acreditación</option>
			<option value="E"> Fecha de emisión</option>
		    </select>
		</div>

		<div class="btn btn-success">
			Filtrar desde: <input type="date" name="frm_fdesde" id="frm_fdesde" value="<?=$fDesde;?>" >
			hasta:         <input type="date" name="frm_fhasta" id="frm_fhasta" value="<?=$fHasta;?>" >
		</div>

		<div class="btn btn-success">
			<button type="button" class="btn btn-primary" id="buscar">Buscar</button>
			<button type="button" class="btn btn-primary" id="printArea">Imprimir</button>
		</div>

	    </div>

	    <div class="window_scroll" id="zonaPrint" > 
		<table class="table table-bordered table-sm" id="tableinfochq" name="tableinfochq"> </table>
	    </div>
	</div>
    </div>
</div>

<script>

var nombProy;
var idProy;
var dirProy;
var localProy;
var nomIdProy;

$(document).ready(function() {
    traeFechas();

    // ------------------------------------------------------------------------------------------------------

    function traeFechas(){
	var tipoChq   = document.getElementById("frm_tipo_chq").value;
	var tipoFecha = document.getElementById("frm_tipo_fecha").value;
	var chqADdepo = ($('#chqadepo').is(':checked') ? 1 : 0 );
	$.ajax({
	    url  : "<?=$urlxInfoChqRF;?>",
	    data : { tipochq: tipoChq, tipofecha: tipoFecha, chqadepo: chqADdepo},
	    type : 'GET',
	    dataType : 'json',
	    success : function(json) {
		var lF = true;
		$.each(json[0], (index, value) =>{
		    if (value == null){lF = false };
		});
		if (lF){
		    if (tipoFecha == 'A'){
			$("#frm_fdesde").val(json[0].f_acre_min);
			$("#frm_fhasta").val(json[0].f_acre_max);
		    }else{
			$("#frm_fdesde").val(json[0].f_emi_max);
			$("#frm_fhasta").val(json[0].f_emi_min);
		    }
		}
	    }
	})
    }

    // ------------------------------------------------------------------------------------------------------
    $("#chqadepo").change(function() {
//	traeFechas();
    });

    // ------------------------------------------------------------------------------------------------------
    $("#frm_tipo_chq").on('change',function(){
	$('#chqadepo').attr('disabled', false);
	if ( $("#frm_tipo_chq option:selected").val() == 'P' ){
	    $('#chqadepo').prop('checked',  false);
	    $('#chqadepo').attr('disabled', true);
	}
	traeFechas();
    });

    // ------------------------------------------------------------------------------------------------------
    $('#printArea').attr('disabled', true);

    // ------------------------------------------------------------------------------------------------------
    $( "#buscar" ).click(function() {
	var desde     = document.getElementById("frm_fdesde").value;
	var hasta     = document.getElementById("frm_fhasta").value;
	var tipoChq   = document.getElementById("frm_tipo_chq").value;
	var tipoFecha = document.getElementById("frm_tipo_fecha").value;
	var element   = document.getElementById("tableinfochq");
	var chqADdepo = ($('#chqadepo').is(':checked') ? 1 : 0 );



	$.ajax({
	    url  : "<?=$urlxInfoChq;?>",
	    data : { fdesde: desde, fhasta: hasta, tipochq: tipoChq, tipofecha: tipoFecha, chqadepo: chqADdepo},
	    type : 'GET',
	    dataType : 'json',
	    success : function(json) {

		nomIdProy = '';
		if (json[1] != null){
		    nombProy  = json[1]['p_nombre'];
		    idProy    = json[1]['p_id'];
		    nomIdProy = ' Proyecto '+nombProy+' ('+idProy+')';
		}

		while (element.firstChild) {
		    element.removeChild(element.firstChild);
		}
		primera = '<thead>';
		primera +='<tr>';
		primera +='<th scope="col">Fecha Emisi.</th>';
		primera +='<th scope="col">Fecha Acred.</th>';
		primera +='<th scope="col">Banco y número</th>';
		primera +='<th ><div class="text-right">Cotización</div></th>';
		primera +='<th ><div class="text-right">Importe $</div></th>';
		primera +='<th ><div class="text-right">Importe U$S</div></th>';
		if(tipoChq != 'P'){   //T E
		    primera +='<th scope="col" >Mov.de Ingreso</th>';
		    primera +='<th scope="col" >Entidad</th>';
		}
		if(tipoChq != 'T'){   //P E
		    primera +='<th scope="col" >Mov.de Egreso</th>';
		    primera +='<th scope="col" >Entidad</th>';
		}
		primera +='<th scope="col" >Comentario</th>';
		primera +='<th scope="col" >Proyecto</th>';
		primera +='</tr>';
		primera +='</thead>';
		$("#tableinfochq").append(primera);
		$("#tableinfochq").append("<tbody >");  //class='tbodyalt' >");
		saltoFecha = "";
		campoFecha = tipoFecha == 'A' ? 'f_acreditacion' : 'f_emision';
		json[0].forEach (function(item,index){
			aFecha = item[campoFecha].split('-');
			if (aFecha[2]+'-'+aFecha[1] != saltoFecha){
			    saltoFecha = aFecha[2]+'-'+aFecha[1];
			    if (tipoFecha == "A"){
				fila = "<tr class='table-primary'><td></td><td><b><h5>"+saltoFecha+"</h5></b></td></tr>";
			    }else{
				fila = "<tr class='table-primary'><td><b><h5>"+saltoFecha+"</h5></b></td><td></td></tr>";
			    }
			    $("#tableinfochq").append(fila);
			}
			entidad1 = '';
			if (item['cc_entidad_id'] !== null){
			    entidad1 = "("+item['en_id']+") "+item['en_razon_social'];
			}
			entidad2 = '';
			if (item['enh_razon_social'] !== null){
			    entidad2 = "("+item['enh_id']+") "+item['enh_razon_social'];
			}
			fila ="<tr id='id_"+item['ccc_cuenta_corriente_id']+"'>";


			fila+="<td>"+formFecha(item['ccc_fecha_emision'])+"</td>";
			fila+="<td>"+formFecha(item['ccc_fecha_acreditacion'])+"</td>";

//			fila+="<td>"+item['f_emision']+"</td>";
//			fila+="<td>"+item['f_acreditacion']+"</td>";
			fila+="<td>"+item['banco_nro']+"</td>";
			fila+="<td><div class='text-right'>"+formNume(item['ccc_importe_divisa']) +"</div></td>";
			fila+="<td><div class='text-right'>"+formNume(item['importemn']) +"</div></td>";

//			fila+="<td><div class='text-right'>"+item['ccc_importe_divisa'] +"</div></td>";
//			fila+="<td><div class='text-right'>"+item['importemn'] +"</div></td>";

			fila+="<td><div class='text-right'>"+formNume(item['importeus'])+"</div></td>";
			if (item['tc_abre_nro']==null){
			    item['tc_abre_nro'] = '';
			}
			if (item['tch_abre_nro']==null){ 
			    item['tch_abre_nro'] = '';
			}
			if(tipoChq != 'P'){   //T E
			    fila+="<td>"+item['tc_abre_nro']+"</td>";
			    fila+="<td>"+entidad1+"</td>";
			}
			if(tipoChq != 'T'){   //P E
			    if(tipoChq == 'E'){   //P E
				fila+="<td>"+item['tch_abre_nro']+"</td>";
				fila+="<td>"+entidad2+"</td>";
			    }else{
				fila+="<td>"+item['tc_abre_nro']+"</td>";
				fila+="<td>"+entidad1+"</td>";
			    }
			}
			fila+="<td>"+item['ccc_comentario']+"</td>";
			fila+="<td>"+item['pr_nombre']+"</td>";        //cc_proyecto_id']+"</td>";
			fila+="</tr>";
			$("#tableinfochq").append(fila);
		    $('#printArea').attr('disabled', false);
		});
		$("#tableinfochq").append("</tbody>");
	    },
	    error : function(xhr, status) {
		alert('Disculpe, existió un problema 1 ');
	    },
	});
    })

    // ------------------------------------------------------------------------------------------------------
    $( "#printArea" ).click(function() {
	var desde = document.getElementById("frm_fdesde").value;
	var hasta = document.getElementById("frm_fhasta").value;
	var elTitulo   = '<h3>Informe de cheques desde el '+desde+' hasta el '+hasta+' - ' + nomIdProy + '</h3><br>';
	var divToPrint = document.getElementById("tableinfochq");
	var elEstilo = "<style>";
	elEstilo += "h3 {  font-family: Arial, Helvetica, sans-serif; border-collapse: collapse;  width: 100%; font-size: medium}";
	elEstilo += "#tableinfochq {  font-family: Arial, Helvetica, sans-serif; border-collapse: collapse;  width: 100%; font-size: 8px}";
	elEstilo += "#tableinfochq td, #tableinfochq th {  border: 1px solid #ddd;  padding: 4px;  text-align: right;}";
	elEstilo += "#tableinfochq tr:nth-child(even){background-color: #f2f2f2;}";
	elEstilo += "#tableinfochq tr:hover {background-color: #ddd;}";
	elEstilo += "#customers th {  padding-top: 8px;  padding-bottom: 8px;  text-align: right;  background-color: #04AA6D;  color: white;}";
	elEstilo += "</style> ";
	newWin= window.open("");
	newWin.document.write(elEstilo);
	newWin.document.write(elTitulo);
	newWin.document.write(divToPrint.outerHTML);
	newWin.print();
	newWin.close();
    })
})

</script>

<?php $this->load->view('footer');?>
<!-- fin footer -->

