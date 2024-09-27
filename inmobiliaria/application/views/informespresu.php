
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
	<h5><b>
	Informe de Presupuestos
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
		primera +='<th scope="col">Id</th>';
		primera +='<th scope="col"><div class="text-center">Fecha Presu.</div></th>';
		primera +='<th scope="col">Comentario</th>';
		primera +='<th scope="col"><div class="text-right">Moneda</div></th>';
		primera +='<th scope="col"><div class="text-right">Importe Inicial</div></th>';
		primera +='<th scope="col"><div class="text-center">Fecha Comp.</div></th>';
		primera +='<th scope="col">Comprobante</th>';
		primera +='<th scope="col"><div class="text-right">Importe</div></th>';
		primera +='<th scope="col"><div class="text-center">Fecha Pago</div></th>';
		primera +='<th scope="col">Comprobante</th>';
		primera +='<th ><div class="text-right">Importe</div></th>';
		primera +='<th ><div class="text-right">Saldo</div></th>';
		primera +='</tr>';
		primera +='</thead>';

		var elConce = '****';
		var muestraConce = '';
		var totales    =  {saldoMN:0, saldoUS:0 };
		var supTotales =  {saldoMN:0, saldoUS:0 };
		$("#tableinfocc").append(primera);
		$("#tableinfocc").append("<tbody>");         // class='tbodyalt' >");

debugger;


		nPreId = -1;
		nRpcId = 0;
		nRccId = 0;
		nRpcId = 0;
		aTotales = [0,0,0,0];

		json.forEach (function(item,index){
			nombProy     = item['pro_nombre'];
			idProy       = item['pre_proyecto_id'];
			impoPresu    = Number(item['pre_importe_inicial']);
			aTotales[0]  = impoPresu;
			impoPresuStr = impoPresu==0 ? '' : impoPresu.toLocaleString("es-ES");
			impoCC       = Number(item['cc_importe']);
			impoCCStr    = impoCC==0 ? '' : impoCC.toLocaleString("es-ES");

			if (item['cc_moneda_id'] == 1){
				impoRcc = Number(item['rcc_monto_pesos']);
			}else{
				impoRcc = Number(item['rcc_monto_divisa']);
			}
			aTotales[2] += impoRcc;
			impoRccStr   = impoRcc==0 ? '' :  impoRcc.toLocaleString("es-ES");
			aReg = [item['pre_id'],							//0
				formFecha(item['pre_fecha_inicio']),				//1
				item['pre_titulo'],						//2
				item['mo_denominacion'],					//3
				impoPresuStr,							//4 importe presupu
				formFecha(item['cc_fecha']),					//5
				formStr(item['tc_abreviado'])+"-"+formStr(item['cclsn']),	//6
				impoCCStr,								//7 importe fac/deb
				formFecha(item['ccc_fecha']),					//8
				formStr(item['ccclsn']),					//9
				impoRccStr,							//10 importe aplica
				0,								//11 poner saldo
				item['rpc_id'],							//13 fac/deb
				item['rcc_id'] ];						//14 pago

			
			if (nPreId == aReg[0]){
			    aReg[0] = '';
			    aReg[1] = '';
			    aReg[2] = '';
			    aReg[3] = '';
			    aReg[4] = '';
			}else{
				if (nPreId != -1){
					fila ="<tr><td colspan='7'></td>";
					fila+="<td><div class='text-right  tdclass'>"+(aTotales[1]==0 ? ' ' : aTotales[1].toLocaleString("es-ES"))+"</div></td>";
					fila+="<td colspan='2'></td>";
					fila+="<td><div class='text-right  tdclass'>"+(aTotales[2]==0 ? ' ' : aTotales[2].toLocaleString("es-ES"))+"</div></td>";
					fila+="<td><div class='text-right  tdclass1'>"+(aTotales[3]==0 ? ' ' : aTotales[3].toLocaleString("es-ES"))+"</div></td>";
					fila+="</tr>";
					$("#tableinfocc").append(fila);

				aTotales = [0,0,0,0];  //0 impo.ini., 1 facdeb, 2 pagos, 3 saldo

				}
				fila = "<tr  class='headt'><td colspan='12'></td></tr>";
				$("#tableinfocc").append(fila);
				nPreId   = item['pre_id'];
			}
			if (nRpcId == aReg[13]){
			    aReg[5] = '';
			    aReg[6] = '';
			    aReg[7] = '';
			}else{
			    nRpcId = aReg[12];
			}

			aTotales[1] += impoCC;
			aTotales[3] += impoCC - impoRcc;

			fila ="<tr id='id_"+item['pre_id']+"'  >";
			if (aReg[0]!=''){
			    fila+="<td><div class='text-right  tdclass'>"+aReg[0]+"</div></td>";
			    fila+="<td><div class='text-center tdclass'>"+aReg[1]+"</div></td>";
			    fila+="<td><div class='text-left   tdclass'>"+aReg[2]+"</div></td>";
			    fila+="<td><div class='text-right  tdclass'>"+aReg[3]+"</div></td>";
			    fila+="<td><div class='text-right  tdclass'>"+aReg[4]+"</div></td>";
			}else{
			    fila+="<td colspan='5'></td>";
			}
			if (aReg[5]!=''){
			    fila+="<td><div class='text-center'>" +aReg[5]+"</div></td>";
			    fila+="<td><div class='text-left'  >" +aReg[6]+"</div></td>";
			    fila+="<td><div class='text-right' >" +aReg[7]+"</div></td>";
			}else{
			    fila+="<td colspan='3'></td>";
			}
			if (aReg[8]!=''){
			    fila+="<td><div class='text-center' >"+aReg[8]+"</div></td>";
			    fila+="<td><div class='text-left' >"  +aReg[9]+"</div></td>";
			    fila+="<td><div class='text-right'>"  +aReg[10]+"</div></td>";
			}else{
			    fila+="<td colspan='3'></td>";
			}



			fila+="<td><div class='text-right tdclass1' >" +(aTotales[3].toLocaleString("es-ES"))+"</div></td>";
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







