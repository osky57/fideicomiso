
<?php $this->load->view('header');?>

<!--
<style>
@page {
    size: 25cm 35.7cm;
    margin: 5mm 5mm 5mm 5mm; /* change the margins as you want them to be. */
}
</style>
-->

<div class="row" id="divinfocaja" name="divinfocaja">
    <div class="main">
	<h5><b>Deudas con Caja</b></h5>
	<div style='padding-top:20px;'> 
		<div class="btn btn-success">
		    <div class="container">

			<div class="row">
			    <div class="col col-md-4">
				Filtrar desde: <input type="date" name="frm_fdesde" id="frm_fdesde" value="<?=$fDesde;?>" >
				<br>hasta:         <input type="date" name="frm_fhasta" id="frm_fhasta" value="<?=$fHasta;?>" >
			    </div>
			    <div class="col col-md-4">
				<button type="button" class="btn btn-primary" id="buscar">Buscar</button>
				<button type="button" class="btn btn-primary" id="printArea">Imprimir</button>
			    </div>
			</div>
		    </div>

		</div>
		<div class="window_scroll" id="zonaPrint" > 
		    <table class="table-bordered" id="tableinfocaja" name="tableinfocaja"> </table>
		</div>
	</div>
    </div>
</div>

<script>

var nombProy;
var idProy;
var dirProy;
var localProy;

$(document).ready(function() {

    $('#printArea').attr('disabled', true);


    $( "#buscar" ).click(function() {

debugger;


	var desde    = document.getElementById("frm_fdesde").value;
	var hasta    = document.getElementById("frm_fhasta").value;
	var element  = document.getElementById("tableinfocaja");
	$.ajax({
	    url  : "<?=$urlxDeudaCCaja;?>",
	    data : { fdesde: desde, fhasta: hasta },
	    type : 'GET',
	    dataType : 'json',
	    success : function(json) {

console.log(json);

		while (element.firstChild) {
		    element.removeChild(element.firstChild);
		}
		primera = '<thead>';
		primera +='<tr>';
		primera +='<th scope="col">Fecha Reg.</th>';
		primera +='<th scope="col">Comprobante</th>';
		primera +='<th scope="col">Comentario</th>';
		primera +='<th scope="col">Tipo</th>';
		primera +='<th scope="col">Cotización</th>';
		primera +='<th ><div class="text-right">Importe $</div></th>';
		primera +='<th ><div class="text-right">Importe U$S</div></th>';
		primera +='<th ><div class="text-right">Importe <br>Chq.a Depo</div></th>';
		primera +='<th ><div class="text-right">Importe <br>Chq.No Depo</div></th>';
		primera +='<th scope="col">Datos Banco y/o Cheque</th>';
		primera +='<th scope="col">Entidad</th>';
		primera +='<th scope="col">Proyecto</th>';
		primera +='</tr>';
		primera +='</thead>';


		$("#tableinfocaja").append(primera);
		$("#tableinfocaja").append("<tbody class='tbodyalt' >");
		json.forEach (function(item,index){

		    if (item['efectivomn']){
			banco = '';
			if (item['banco'] !== null){
			    banco = item['banco'];
			}
			cheque = '';
			if (item['tc_abreviadonume'] != null){
			    if( !item['tc_abreviadonume'].includes('Anterior')){
				if (item['ccc_fecha_emision'] !== undefined){
				    if (item['ccc_fecha_emision'] !== null){
					if (item['el_chq'] !== ''){
					    cheque =item['el_chq']+"<br> F.E. "+item['ccc_fecha_emision']+" F.A. "+item['ccc_fecha_acreditacion']+" "+item['ccc_e_chq'];
					}
				    }
				}
			    }
			}
			entidad = '';
			if (item['cc_entidad_id'] != null){
			    entidad = "("+item['cc_entidad_id']+") "+item['en_razon_social'];
			}
			fila ="<tr id='id_"+item['ccc_cuenta_corriente_id']+"'>";
			fila+="<td>"+formFecha(item['ccc_fecha_registro'])+"</td>";

//			fila+="<td>"+item['ccc_fecha_registro']+"</td>";
			fila+="<td>"+(item['tc_abreviadonume'] == null ?'':item['tc_abreviadonume'])+"</td>";
			fila+="<td>"+(item['ccc_comentario']   == null ?'':item['ccc_comentario'])  +"</td>";
			fila+="<td>"+item['tmc_descripcion']+"</td>";

			fila+="<td><div class='text-right'>"+formNume(item['ccc_importe_divisa'])+"</div></td>";
			fila+="<td><div class='text-right'><b>"+formNume(item['efectivomn']        )+"</b></div></td>";
			fila+="<td><div class='text-right'><b>"+formNume(item['efectivous']        )+"</b></div></td>";
			fila+="<td><div class='text-right'><b>"+formNume(item['cheques']           )+"</b></div></td>";
			fila+="<td><div class='text-right'><b>"+formNume(item['cheques_no_depo']   )+"</b></div></td>";

//			fila+="<td><div class='text-right'><b>"+item['ccc_importe_divisa'] +"</div></td>";
//			fila+="<td><div class='text-right'><b>"+(item['efectivomn']      == 0?'':item['efectivomn'])     +"</b></div></td>";
//			fila+="<td><div class='text-right'><b>"+(item['efectivous']      == 0?'':item['efectivous'])     +"</b></div></td>";
//			fila+="<td><div class='text-right'><b>"+(item['cheques']         == 0?'':item['cheques'])        +"</b></div></td>";
//			fila+="<td><div class='text-right'><b>"+(item['cheques_no_depo'] == 0?'':item['cheques_no_depo'])+"</b></div></td>";

			fila+="<td>"+cheque+"</td>";
			fila+="<td>"+entidad+"</td>";
			fila+="<td><div class='text-center'>"+(item['pr_nombre'] == null?'':item['pr_nombre'])+"</div></td>";
			fila+="</tr>";
			$("#tableinfocaja").append(fila);
//			fila+="<td><div class='text-center'>"+(item['cc_proyecto_id'] == null?'':item['cc_proyecto_id'])+"</div></td>";


		    }else{
			nombProy  = item['p_nombre'];
			idProy    = item['p_id']
			dirProy   = item['direccion'];
			localProy = item['local_prov'];
		    }

		    $('#printArea').attr('disabled', false);
		});
		$("#tableinfocaja").append("</tbody>");
	    },
	    error : function(xhr, status) {
		alert('Disculpe, existió un problema 1 ');
	    },
	});
    })

    $( "#printArea" ).click(function() {
	var desde = document.getElementById("frm_fdesde").value;
	var hasta = document.getElementById("frm_fhasta").value;
	var elTitulo   = '<h3>Informe de caja desde el '+desde+' hasta el '+hasta+' - Proyecto: '+nombProy+' ('+idProy+')</h3><br>';
	var divToPrint = document.getElementById("tableinfocaja");
	var elEstilo = "<style>";
	elEstilo += "h3 {  font-family: Arial, Helvetica, sans-serif; border-collapse: collapse;  width: 100%; font-size: medium}";
	elEstilo += "#tableinfocaja {  font-family: Arial, Helvetica, sans-serif; border-collapse: collapse;  width: 100%; font-size: 8px}";
	elEstilo += "#tableinfocaja td, #tableinfocaja th {  border: 1px solid #ddd;  padding: 4px;  text-align: right;}";
	elEstilo += "#tableinfocaja tr:nth-child(even){background-color: #f2f2f2;}";
	elEstilo += "#tableinfocaja tr:hover {background-color: #ddd;}";
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







