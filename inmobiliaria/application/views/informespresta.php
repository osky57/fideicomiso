
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

.headt td {
  min-width: 235px;
  height: 30px;
 }
 


table {
	border: Blue 3px solid;
	font-size:80%;	 
}

.tdclass {
	font-weight: bold;
	color: #0000ff;
	font-style: italic;
}

.tdclass1 {
	font-weight: bold;
	color: #ff0000;
	font-style: italic;
}


</style>




<div class="row" id="divinfocc" name="divinfocc">
    <div class="main" style='padding-left:15px;'>
<!-- fin header -->
	<h5><b>Informe de Prestamistas</b></h5>
	<div style='padding-top:20px;'>
	    <form action="<?php echo base_url('index.php/informescc/informeCC') ?>" method="POST">
		<div class="btn btn-success">
		    <div class="col-sm">
			Filtrar desde: <input type="date" name="frm_fdesde" id="frm_fdesde" value="<?=$fDesde;?>" >
			hasta:         <input type="date" name="frm_fhasta" id="frm_fhasta" value="<?=$fHasta;?>" >
		    </div>
		</div>

		<div class="col col-md-2">
		    <input class="form-check-input" type="checkbox" value="1" id="frm_solo_proyecto" name="frm_solo_proyecto">
		    <label class="form-check-label" for="flexCheckChecked">Proyecto actual</label>
		</div>

		<div class="btn btn-success">
		    <div class="col-sm">
			<label for="frm_entidad_id">Elegir entidad</label>
			<select class="custom-select" id="frm_entidad_id" name="frm_entidad_id" >
			<?php foreach($entidades as $item){?>
			<option value="<?=$item['e_id'];?>" <?=$item['selectado'];?> > 
				<?=$item['e_razon_social'];?> 
				-<?=$item['e_id'];?>-(<?=$item['tipoentidad'];?>)
			</option>
			<?php } ?>
			</select>
		    </div>
		</div>
		<div class="btn btn-success">
		    <div class="col-sm">
			<button type="button" class="btn btn-primary" id="printArea">Imprimir</button>
		    </div>
		</div>
	    </form>
	    <div class="window_scroll">
		<!-- class="table-bordered" -->
		
		<table  id="tableinfocc" name="tableinfocc" >
		</table>
	    </div>
	    <div class="container-fluid">
		<h4><p id="dialogMsg1"></p></h4>
	    </div>

<!-- footer -->
	</div>
    </div>
</div>

<script>

var nombProy;
var idProy;
var dirProy;
var localProy;

$(document).ready(function() {

    $('#tableinfocc').on('dblclick', 'tr', function (dato) {
	elId =  dato.currentTarget.id;
	elId =  elId.match(/\d+/gi);
    });

    $("#printArea").attr("disabled", true);

    $( "#printArea" ).click(function() {
	var laEnti = $("#frm_entidad_id  option:selected").text();
	var desde = document.getElementById("frm_fdesde").value;
	var hasta = document.getElementById("frm_fhasta").value;
	var elTitulo = '<h3>Informe de presupuestos desde el '+desde+' hasta el '+hasta+'<br>Entidad: '+laEnti +' - Proyecto: '+nombProy+' ('+idProy+')</h3><br>';
	var divToPrint=document.getElementById("tableinfocc");
	var elEstilo = "<style>";
	elEstilo += "h3 {  font-family: Arial, Helvetica, sans-serif; border-collapse: collapse;  width: 100%; font-size: medium}";
	elEstilo += "#tableinfocc {  font-family: Arial, Helvetica, sans-serif; border-collapse: collapse;  width: 100%; font-size: 8px}";
	elEstilo += "#tableinfocc td, #tableinfocc th {  border: 1px solid #ddd;  padding: 4px;  text-align: right;}";
	elEstilo += "#tableinfocc tr:nth-child(even){background-color: #f2f2f2;}";
	elEstilo += "#tableinfocc tr:hover {background-color: #ddd;}";
	elEstilo += "#customers th {  padding-top: 8px;  padding-bottom: 12px;  text-align: right;  background-color: #04AA6D;  color: white;}";
	elEstilo += "</style> ";
	newWin= window.open("");
	newWin.document.write(elEstilo);
	newWin.document.write(elTitulo);
	newWin.document.write(divToPrint.outerHTML);
	newWin.print();
	newWin.close();

    })



    $("#frm_fdesde, #frm_fhasta, #frm_entidad_id").on('change', function() {
	var desde    = document.getElementById("frm_fdesde").value;
	var hasta    = document.getElementById("frm_fhasta").value;
	var enti     = document.getElementById("frm_entidad_id").value;
	var soloProy =  document.getElementById("frm_solo_proyecto").value;
	var element  = document.getElementById("tableinfocc");
	$.ajax({
	    url : "<?=$urlxInfoCC;?>",
	    data : { fdesde : desde, fhasta : hasta , entidad : enti, soloproy : soloProy },
	    type : 'GET',
	    dataType : 'json',
	    success : function(json) {

console.log(json);
		while (element.firstChild) {
		    element.removeChild(element.firstChild);
		}
		primera = '<thead>';
		primera +='<tr>';
		primera +='<th scope="col">Id</th>';
		primera +='<th scope="col"><div class="text-center">Fecha</div></th>';
		primera +='<th scope="col">Comprobante</th>';
		primera +='<th scope="col">Comentario</th>';
		primera +='<th scope="col"><div class="text-right">Importe $</div></th>';
		primera +='<th ><div class="text-right">Saldo $</div></th>';
		primera +='<th scope="col"><div class="text-right">Importe U$S</div></th>';
		primera +='<th ><div class="text-right">Saldo U$S</div></th>';
		primera +='</tr>';
		primera +='</thead>';

		var elConce = '****';
		var muestraConce = '';
		var totales    =  {saldoMN:0, saldoUS:0 };
		var supTotales =  {saldoMN:0, saldoUS:0 };
		$("#tableinfocc").append(primera);
		$("#tableinfocc").append("<tbody>");         // class='tbodyalt' >");

debugger;

		aTotales = [0,0];

		json.forEach (function(item,index){

			aTotales[0] += Number(item['impo_mn']);
			aTotales[1] += Number(item['impo_div']);

			aReg = [item['cc_id'],							//0
				item['cc_fecha'],						//1
				item['tc_abreviado'] + " - " + item['cc_numero'],		//2
				item['cc_comentario'],						//3
				item['impo_mn'].toLocaleString("es-ES"),			//4
				aTotales[0].toLocaleString("es-ES"),				//5
				item['impo_div'].toLocaleString("es-ES"),			//6
				aTotales[1].toLocaleString("es-ES")];				//7

			fila ="<tr id='id_"+aReg[0]+"'>";
			fila+="<td><div class='text-right  tdclass'>"+aReg[0]+"</div></td>";
			fila+="<td><div class='text-center tdclass'>"+aReg[1]+"</div></td>";
			fila+="<td><div class='text-left   tdclass'>"+aReg[2]+"</div></td>";
			fila+="<td><div class='text-right  tdclass'>"+aReg[3]+"</div></td>";
			fila+="<td><div class='text-right  tdclass'>"+aReg[4]+"</div></td>";
			fila+="<td><div class='text-right  tdclass'>"+aReg[5]+"</div></td>";
			fila+="<td><div class='text-right  tdclass'>"+aReg[6]+"</div></td>";
			fila+="<td><div class='text-right  tdclass'>"+aReg[7]+"</div></td>";
			fila+="</tr>";
			$("#tableinfocc").append(fila);
			$('#printArea').attr('disabled', false);
		});
		fila ="<tr><td colspan='7'></td>";
		fila+="<td><div class='text-right  tdclass'>"+(aTotales[1]==0 ? ' ' : aTotales[1].toLocaleString("es-ES"))+"</div></td>";
		fila+="<td colspan='2'></td>";
		fila+="<td><div class='text-right  tdclass'>"+(aTotales[2]==0 ? ' ' : aTotales[2].toLocaleString("es-ES"))+"</div></td>";
		fila+="<td><div class='text-right  tdclass tdclass1'>"+(aTotales[3]==0 ? ' ' : aTotales[3].toLocaleString("es-ES"))+"</div></td>";
		fila+="</tr>";
		$("#tableinfocc").append(fila);


	    },
	    error : function(xhr, status) {
		alert('Disculpe, existió un problema 1 ');
	    },
	});

///////////////////////////////////////////////////////////////////////////////////
	function str2num(xx){
	    if (typeof(xx) == 'number'){
		xx = xx * 1.00;
		xx = xx.toLocaleString("en-US");
	    }
	    if (typeof(xx) == 'string'){
		xx = xx.toString().replaceAll('.','*');
		xx = xx.toString().replaceAll(',','.');
		xx = xx.toString().replaceAll('*',',');
		if (xx.trim(" ") == ",00"){
		    xx = "";
		}
	    }
	    return xx;
	}
    })
})

</script>

<?php $this->load->view('footer');?>
<!-- fin footer -->







