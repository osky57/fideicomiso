
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
    <div class="main" style='padding-left:15px;'>
	<h5><b>Informes de Retenciones</b></h5>
	<div style='padding-top:20px;'> 
		<div class="btn btn-success">
		    <div class="container">

			<div class="row">
			    <div class="col col-md-4">
				Filtrar desde: <input type="date" name="frm_fdesde" id="frm_fdesde" value="<?=$fDesde;?>" >
				<br>hasta:         <input type="date" name="frm_fhasta" id="frm_fhasta" value="<?=$fHasta;?>" >
			    </div>
			    <div class="col col-md-4">
				<?php if ( $tieneproy == 1){ ?>
				    <input class="form-check-input" type="checkbox" value="1" id="frm_solo_proyecto" name="frm_solo_proyecto">
				    <label class="form-check-label" for="flexCheckChecked">Proyecto actual</label>
				<?php } ?>
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
	var desde    = document.getElementById("frm_fdesde").value;
	var hasta    = document.getElementById("frm_fhasta").value;
	var element  = document.getElementById("tableinfocaja");
	var soloProy = $("#frm_solo_proyecto").is(":checked");
	$.ajax({
	    url  : "<?=$urlxInfoReten;?>",
	    data : { fdesde: desde, fhasta: hasta, soloproy: soloProy},
	    type : 'GET',
	    dataType : 'json',
	    success : function(json) {
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
		primera +='<th scope="col">Entidad</th>';
		primera +='<th scope="col">Proyecto</th>';
		primera +='</tr>';
		primera +='</thead>';
		$("#tableinfocaja").append(primera);
		$("#tableinfocaja").append("<tbody class='tbodyalt' >");
		json.forEach (function(item,index){
			fila ="<tr id='id_"+item['ccc_cuenta_corriente_id']+"'>";
			fila+="<td>"+formFecha(item['ccc_fecha_registro'])+"</td>";
			fila+="<td>"+(item['tc_abreviadonume'] == null ?'':item['tc_abreviadonume'])+"</td>";
			fila+="<td>"+(item['ccc_comentario']   == null ?'':item['ccc_comentario'])+"</td>";
			fila+="<td>"+item['tmc_descripcion']+"</td>";
			fila+="<td><div class='text-right'>"+item['ccc_importe_divisa'] +"</div></td>";
			fila+="<td><div class='text-right'><b>"+(item['importe_ret']     == 0?'':item['importe_ret'])+"</b></div></td>";
			fila+="<td><div class='text-center'>"+(item['en_razon_social'] == null?'':item['en_razon_social'])+"</div></td>";
			fila+="<td><div class='text-center'>"+(item['ccc_proyecto_id'] == null?'':item['ccc_proyecto_id'])+"</div></td>";
			fila+="</tr>";
			$("#tableinfocaja").append(fila);
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







