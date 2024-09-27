
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




<div class="row" id="divinfocc" name="divinfocc">
    <div class="main" style='padding-left:15px;'>
<!-- fin header -->
	<h5><b>
	Informes de Cuentas Corrientes
	</b></h5>
	<div style='padding-top:20px;'>
	    <form action="<?php echo base_url('index.php/informescc/informeCC') ?>" method="POST">
		<div class="btn btn-success">
		    <div class="col-sm">
			Filtrar desde: <input type="date" name="frm_fdesde" id="frm_fdesde" value="<?=$fDesde;?>" >
			hasta:         <input type="date" name="frm_fhasta" id="frm_fhasta" value="<?=$fHasta;?>" >
		    </div>
		</div>
		<div class="btn btn-success">
		    <div class="col-sm">
			<label for="frm_entidad_id">Elegir entidad</label>
			<select class="custom-select" id="frm_entidad_id" name="frm_entidad_id" >
			<?php foreach($entidades as $item){?>
			<option value="<?=$item['e_id'];?>" <?=$item['selectado'];?> > 
				<?=$item['e_razon_social'];?> 
				-(<?=$item['tipoentidad'];?>)
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
		<table class="table-bordered" id="tableinfocc" name="tableinfocc">
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
	var elTitulo = '<h3>Informe de cuentas corrientes desde el '+desde+' hasta el '+hasta+'<br>Entidad: '+laEnti+' - Proyecto: '+nombProy+' ('+idProy+')</h3><br>';
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

/************************************************************* original sin pautado por concepto
    $("#frm_fdesde, #frm_fhasta, #frm_entidad_id").on('change', function() {
	var desde = document.getElementById("frm_fdesde").value;
	var hasta = document.getElementById("frm_fhasta").value;
	var enti  = document.getElementById("frm_entidad_id").value;
	var element = document.getElementById("tableinfocc");
	$.ajax({
	    url : "<?=$urlxInfoCC;?>",
	    data : { fdesde : desde, fhasta : hasta , entidad : enti },
	    type : 'GET',
	    dataType : 'json',
	    success : function(json) {
		while (element.firstChild) {
		    element.removeChild(element.firstChild);
		}
		primera = '<thead>';
		primera +='<tr><th scope="col">Fecha</th>';
		primera +='<th scope="col">Comprobante</th>';
		primera +='<th scope="col">Comentario</th>';
		primera +='<th ><div class="text-right">Debe $</div></th>';
		primera +='<th ><div class="text-right">Haber $</div></th>';
		primera +='<th ><div class="text-right">Saldo $</div></th>';
		primera +='<th ><div class="text-right">Debe U$S</div></th>';
		primera +='<th ><div class="text-right">Haber U$S</div></th>';
		primera +='<th ><div class="text-right">Saldo U$S</div></th>';
		primera +='<th scope="col">Entidad</th>';
		primera +='<th scope="col">Tipo</th>';
		primera +='</tr>';
		primera +='</thead>';
		$("#tableinfocc").append(primera);
		$("#tableinfocc").append("<tbody class='tbodyalt' >");
		json.forEach (function(item,index){
		    if (item['saldo_mn_tot']){
			elNro = (item['cc_numero']>0) ? " (Nro."+item['cc_numero']+")" : '';
			fila = "<tr id='id_"+item['cc_id']+"'>";
			fila+="<td>"+item['cc_fecha']+"</td>";
			fila+="<td>"+item['tc_abreviado']+elNro+"</td>";
			fila+="<td>"+item['cc_comentario']+"</td>";
			fila+="<td><div class='text-right'>"+item['debe_mn_tot'] +"</div></td>";
			fila+="<td><div class='text-right'>"+item['haber_mn_tot']+"</div></td>";
			fila+="<td><div class='text-right'>"+item['saldo_mn_tot']+"</div></td>";
			fila+="<td><div class='text-right'>"+item['debe_div_tot']+"</div></td>";
			fila+="<td><div class='text-right'>"+item['haber_div_tot']+"</div></td>";
			fila+="<td><div class='text-right'>"+item['saldo_div_tot']+"</div></td>";
			fila+="<td>"+item['e_razon_social']+"</td>";
			fila+="<td>"+item['tipoentidad']+"</td></tr>";
			$("#tableinfocc").append(fila);
		    }else{
			nombProy  = item['p_nombre'];
			idProy    = item['p_id']
			dirProy   = item['direccion'];
			localProy = item['local_prov'];
		    }

		    $('#printArea').attr('disabled', false);

		});
		$("#tableinfocc").append("</tbody>");
	    },
	    error : function(xhr, status) {
		alert('Disculpe, existió un problema 1 ');
	    },
	});
    })
*/


    $("#frm_fdesde, #frm_fhasta, #frm_entidad_id").on('change', function() {
	var desde = document.getElementById("frm_fdesde").value;
	var hasta = document.getElementById("frm_fhasta").value;
	var enti  = document.getElementById("frm_entidad_id").value;
	var element = document.getElementById("tableinfocc");
	$.ajax({
	    url : "<?=$urlxInfoCC;?>",
	    data : { fdesde : desde, fhasta : hasta , entidad : enti },
	    type : 'GET',
	    dataType : 'json',
	    success : function(json) {

console.log(json);

		while (element.firstChild) {
		    element.removeChild(element.firstChild);
		}
		primera = '<thead>';
		primera +='<tr>';
		primera +='<th scope="col"></th>';
		primera +='<th scope="col">Fecha</th>';
		primera +='<th scope="col">Comprobante</th>';
		primera +='<th scope="col">Comentario</th>';
		primera +='<th ><div class="text-right">Debe $</div></th>';
		primera +='<th ><div class="text-right">Haber $</div></th>';
		primera +='<th ><div class="text-right">Saldo $ Comprob.</div></th>';
		primera +='<th ><div class="text-right">Saldo $ Total</div></th>';
		primera +='<th ><div class="text-right">Debe U$S</div></th>';
		primera +='<th ><div class="text-right">Haber U$S</div></th>';
		primera +='<th ><div class="text-right">Saldo U$S Comprob.</div></th>';
		primera +='<th ><div class="text-right">Saldo U$S Total</div></th>';
//		primera +='<th scope="col">Entidad</th>';
//		primera +='<th scope="col">Tipo</th>';
		primera +='</tr>';
		primera +='</thead>';
		var elConce = '****';
		var muestraConce = '';

		var totales    =  {saldoMN:0, saldoUS:0 };
		var supTotales =  {saldoMN:0, saldoUS:0 };
		$("#tableinfocc").append(primera);
		$("#tableinfocc").append("<tbody>");         // class='tbodyalt' >");

debugger;

		json.forEach (function(item,index){
		    if (Object.prototype.hasOwnProperty.call(item, 'id_debi')){
			if (elConce != item['co_descripcion']){
			    if (elConce != '****'){
				fila ="<tr>";
				fila+="<td></td>";
				fila+="<td></td>";
				fila+="<td><b><h5>SALDO "+elConce+"</h5></b></td>";
				fila+="<td></td>";
				fila+="<td></td>";
				fila+="<td></td>";
				fila+="<td></td>";
				fila+="<td><b><h5>"+  str2num(totales.saldoMN)  +"</h5></b></td>";
				fila+="<td></td>";
				fila+="<td></td>";
				fila+="<td></td>";
				fila+="<td><b><h5>"+ str2num(totales.saldoUS)  +"</h5></b></td>";
				fila+="<td></td>";
				fila+="</tr>";
				$("#tableinfocc").append(fila);
				totales =  {saldoMN:0, saldoUS:0 };
			    }
			    elConce = item['co_descripcion'];
			    muestraConce = "<b><h5>"+item['co_descripcion']+"</h5></b>";
			}else{
				muestraConce = '';
			}
			elNro               = (item['cc_numero']>0) ? " (Nro."+item['cc_numero']+")" : '';
			classTr             = (item['cc_id'] != item['id_debi'] ? "table-warning" : "table-active");


console.log(item['debe_mn_tot']);
console.log(item['haber_mn_tot']);

			totales.saldoMN    += str2num(item['debe_mn_tot'])  - str2num(item['haber_mn_tot']);
			totales.saldoUS    += str2num(item['debe_div_tot']) - str2num(item['haber_div_tot']);
			supTotales.saldoMN += str2num(item['debe_mn_tot'])  - str2num(item['haber_mn_tot']);
			supTotales.saldoUS += str2num(item['debe_div_tot']) - str2num(item['haber_div_tot']);

			fila ="<tr id='id_"+item['cc_id']+"' class='"+classTr+"'  >";
			fila+="<td>"+muestraConce+"</td>";
			fila+="<td>"+formFecha(item['cc_fecha'])+"</td>";
			fila+="<td>"+item['tc_abreviado']+elNro+"</td>";
			fila+="<td>"+item['cc_comentario']+"</td>";

			fila+="<td><div class='text-right'>"+item['debe_mn_tot'] +"</div></td>";
			fila+="<td><div class='text-right'>"+item['haber_mn_tot']+"</div></td>";
			fila+="<td><div class='text-right'>"+item['saldo_mn_tot']+"</div></td>";
//			fila+="<td style='background:blue;color:white'><div class='text-right'>"+item['saldo_mn_gen']+"</div></td>";
			fila+="<td style='background:blue;color:white'><div class='text-right'>"+str2num(totales.saldoMN)+"</div></td>";

			fila+="<td><div class='text-right'>"+item['debe_div_tot']+"</div></td>";
			fila+="<td><div class='text-right'>"+item['haber_div_tot']+"</div></td>";
			fila+="<td><div class='text-right'>"+item['saldo_div_tot']+"</div></td>";
//			fila+="<td style='background:blue;color:white'><div class='text-right'>"+item['saldo_div_gen']+"</div></td>";
			fila+="<td style='background:blue;color:white'><div class='text-right'>"+str2num(totales.saldoUS)+"</div></td>";







//			fila+="<td>"+item['e_razon_social']+"</td>";
//			fila+="<td>"+item['tipoentidad']+"</td>
			fila+="</tr>";

			$("#tableinfocc").append(fila);
		    }else{
			nombProy  = item['p_nombre'];
			idProy    = item['p_id']
			dirProy   = item['direccion'];
			localProy = item['local_prov'];
		    }

		    $('#printArea').attr('disabled', false);

		});

		fila ="<tr>";
		fila+="<td></td>";
		fila+="<td></td>";
		fila+="<td><b><h5>SALDO "+elConce+"</h5></b></td>";
		fila+="<td></td>";
		fila+="<td></td>";
		fila+="<td></td>";
		fila+="<td></td>";
		fila+="<td><b><h5>"+ str2num(totales.saldoMN)  +"</h5></b></td>";

//		fila+="<td><b><h5>"+ (totales.saldoMN.toLocaleString("en-US"))  +"</h5></b></td>";

		fila+="<td></td>";
		fila+="<td></td>";
		fila+="<td></td>";
		fila+="<td><b><h5>"+ str2num(totales.saldoUS)  +"</h5></b></td>";

//		fila+="<td><b><h5>"+ (totales.saldoUS.toLocaleString("en-US"))  +"</h5></b></td>";
		fila+="<td></td>";
		fila+="</tr>";
		$("#tableinfocc").append(fila);
		$("#tableinfocc").append("</tbody>");

		$("#dialogMsg1").text("Totales:   $"+str2num(supTotales.saldoMN)+"    U$S"+str2num(supTotales.saldoUS));

//		$("#dialogMsg1").text("Totales:   $"+(supTotales.saldoMN)+"    U$S"+(supTotales.saldoUS));


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
		xx = xx.toString().replaceAll('.','');
		xx = xx.toString().replaceAll(',','.');
	    }
	    return xx;
	}

    })
})

</script>

<?php $this->load->view('footer');?>
<!-- fin footer -->







