
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

<div id="dialog">
<p id="dialogMsg1"></p>
<p id="dialogMsg2"></p>
<div id="tablaApl"></div>
<div id="tablaPag"></div>
</div>


<div class="row" id="divinfocc" name="divinfocc">
    <div class="main" style='padding-left:15px;'>
	<h5><b>
	Informes de Proyectos
	</b></h5>
	<div style='padding-top:20px;'>
	    <form action="<?php echo base_url('index.php/informescc/informeCC') ?>" method="POST">
		<div class="btn btn-success">
<!--		    <div class="col-sm"> -->
			Filtrar desde: <input type="date" name="frm_fdesde" id="frm_fdesde" value="<?=$fDesde;?>" >
			hasta:         <input type="date" name="frm_fhasta" id="frm_fhasta" value="<?=$fHasta;?>" >
		    </div>
<!--		</div> -->
		<div class="btn btn-success">

		    <div class="col-sm">
			<select id="opciones" name="opciones">
			    <option value="1">Informe completo</option>
			    <option value="2">Recibos y Ordenes de Pago</option>
			</select>
		    </div>

		    <div class="col-sm">
			<button type="button" class="btn btn-primary" id="buscar">Buscar</button>
			<button type="button" class="btn btn-primary" id="printArea">Imprimir</button>
		    </div>
		</div>
	    </form>
	    <div class="window_scroll">
		<table class="table-bordered" id="tableinfocc" name="tableinfocc">
		</table>
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

    $("#dialog").dialog({
	autoOpen: false,
	modal: true,
	buttons: {
	    "Cerrar": function () {
		$(this).dialog("close");
	    }
	}
    });

    $('#tableinfocc').on('dblclick', 'tr', function (dato) {
	aelId =  dato.currentTarget.id;
	aelId =  aelId.match(/\d+/gi);
	elId  =  aelId[0];
	if ( elId > 0){
	    $.ajax({
		url : "<?=$urlinfocomp;?>",
		data : { idcomp : elId },
		type : 'GET',
		dataType : 'json',
		success : function(json) {
		    jsonC = json['comprob'];
		    jsonP = json['pagos'];
		    jsonA = json['aplicaciones'];

		    jsonC['totalmn']  =  jsonC['totalmn']/1;    //  === undefined ? '' : jsonC['totalmn'];
		    jsonC['totaldiv'] =  jsonC['totaldiv']/1;   // === undefined ? '' : jsonC['totaldiv'];

		    sinApli = jsonC['saldocomprob'];
		    sinApli = sinApli.replace('(','');
		    sinApli = sinApli.replace(')','');
		    sinApliPesDol = sinApli.split(','); //separa sin apli $ de los u$s, porq vienen en array

		    xR1     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(jsonC['totalmn']);
		    xR2     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(jsonC['totaldiv']);
		    xR3     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(sinApliPesDol[0]);
		    xR4     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(sinApliPesDol[1]);

		    $("#dialogMsg1").text("Entidad: "+jsonC['e_razon_social']+" ("+jsonC['cc_entidad_id']+") - Celular: "+jsonC['e_celular']+" -- Comentario: "+jsonC['ccc_comentario']);
		    $("#dialogMsg2").text("Importe: $ "+xR1+" - U$S "+xR2+"   |  Sin aplicar: $ "+ xR3+" - U$S: "+ xR4  );
		    $("#dialogMsg2").css({"background-color": "yellow", "font-size": "120%"});

		    $("#dialog").dialog("option", "title", "Id: "+jsonC['cc_id']+" - Comprobante: "+jsonC['tc_num']+" - Fecha: "+jsonC['cc_fecha_dmy']);
		    lF     = 0;
		    lasA   = ""
		    nTotMN = 0;
		    nTotUS = 0;
		    jsonA.forEach((unaA) => {
			if (lF == 0){
			    lasA  = "<b>Aplicaciones</b><br><table class='table table-sm'>";   // <caption>Aplicaciones</caption>"
			    lasA += "<thead><tr>";
			    lasA += "<th class='text-right'>Id</th>";
			    lasA += "<th class='text-right'>Fecha</th>";
			    lasA += "<th class='text-right'>Comprobante</th>";
			    lasA += "<th class='text-right'>Comentario</th>";
			    lasA += "<th class='text-right'>Importe $</th>";
			    lasA += "<th class='text-right'>Importe U$S</th>";
			    lasA += "</tr></thead><tbody>";
			    lF   = 1;
			}

			xR1     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(unaA.rcc_monto_pesos);
			xR2     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(unaA.rcc_monto_divisa);

			lasA += "<tr>"
			lasA += "<td>"+unaA.id+"</td>";
			lasA += "<td>"+unaA.fecha_dmy+"</td>";
			lasA += "<td>"+unaA.comp_nume+"</td>";
			lasA += "<td>"+unaA.comentario+"</td>";
			lasA += "<td>"+xR1+"</td>";
			lasA += "<td>"+xR2+"</td>";
			lasA += "</tr>"
			nTotMN += unaA.rcc_monto_pesos/1;
			nTotUS += unaA.rcc_monto_divisa/1;
		    });
		    if (lF == 1){

			xR1     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(nTotMN);
			xR2     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(nTotUS);

			lasA += "<tr>"
			lasA += "<td></td>";
			lasA += "<td></td>";
			lasA += "<td></td>";
			lasA += "<td><b>TOTAL</b></td>";
			lasA += "<td><b>"+xR1+"</b></td>";
			lasA += "<td><b>"+xR2+"</b></td>";
			lasA += "</tr>"
			lasA += "</tbody></table>"
		    }
		    $("#tablaApl").html(lasA);

		    lF     = 0;
		    lasA   = ""
		    nTotMN = 0;
		    nTotUS = 0;
		    jsonP.forEach((unP) => {
			if (lF == 0){
			    lasA  = "<b>Caja</b><br><table class='table table-sm'>";   // <caption>Aplicaciones</caption>"
			    lasA += "<thead><tr>";
			    lasA += "<th class='text-right'>Id</th>";
			    lasA += "<th class='text-right'>Tipo</th>";
			    lasA += "<th class='text-right'>Comentario</th>";
			    lasA += "<th class='text-right'>Banco - Chq.Nro.</th>";
			    lasA += "<th class='text-right'>Fecha Emi.</th>";
			    lasA += "<th class='text-right'>Fecha Acr.</th>";
			    lasA += "<th class='text-right'>Importe $</th>";
			    lasA += "<th class='text-right'>Importe U$S</th>";
			    lasA += "</tr></thead><tbody>";
			    lF   = 1;
			}
			if (unP.cb_denominacion == null){
			    banco = unP.banco;    //ba2_denominacion;
			}else{
			    banco = unP.cb_denominacion;
			}

			if (unP.serienro == null){
			    chq = "";
			}else{
			    chq = unP.serienro;
			}

			xR1     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(unP.ccc_importe/1);

			lasA += "<tr>"
			lasA += "<td>"+unP.ccc_id+"</td>";
			lasA += "<td>"+(unP.tmc_descripcion   == null?"":unP.tmc_descripcion)+"</td>";
			lasA += "<td>"+(unP.ccc_comentario    == null?"":unP.ccc_comentario)+"</td>";
			lasA += "<td>"+(banco == null?"":banco+" "+chq)+"</td>";
			lasA += "<td>"+(unP.f_emision         == null?"":unP.f_emision)+"</td>";
			lasA += "<td>"+(unP.f_acreditacion    == null?"":unP.f_acreditacion)+"</td>";
			lasA += "<td>"+(unP.mo1_simbolo == "$"?xR1:"")+"</td>";
			lasA += "<td>"+(unP.mo1_simbolo != "$"?xR1:"")+"</td>";
			lasA += "</tr>"
			nTotMN += unP.mo1_simbolo == "$"?unP.ccc_importe/1:0;
			nTotUS += unP.mo1_simbolo != "$"?unP.ccc_importe/1:0;
		    });
		    if (lF == 1){

			xR1     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(nTotMN/1);
			xR2     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(nTotUS/1);

			lasA += "<tr>"
			lasA += "<td></td>";
			lasA += "<td></td>";
			lasA += "<td></td>";
			lasA += "<td></td>";
			lasA += "<td></td>";
			lasA += "<td><b>TOTAL</b></td>";
			lasA += "<td><b>"+xR1+"</b></td>";
			lasA += "<td><b>"+xR2+"</b></td>";
			lasA += "</tr>"
			lasA += "</tbody></table>"
		    }
		    $("#tablaPag").html(lasA);
		    $("#dialog").dialog("option", "width", 1300);
		    $("#dialog").dialog("option", "height", 600);
		    $("#dialog").dialog("option", "resizable", true);
		    $("#dialog").dialog("open");
		}
	    })
	}
    });

/////////////////////////////////////////////////////////////////////////////////////////////////////////
    $("#printArea").attr("disabled", true);

    $( "#printArea" ).click(function() {
	var laEnti = $("#frm_entidad_id  option:selected").text();
	var desde = document.getElementById("frm_fdesde").value;
	var hasta = document.getElementById("frm_fhasta").value;
	var elTitulo = '<h3>Informe del proyecto '+nombProy+' ('+idProy+')<br>Desde el '+desde+' hasta el '+hasta+'</h3><br>';
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

/////////////////////////////////////////////////////////////////////////////////////////////////////////
    $( "#buscar" ).click(function() {
	var desde   = document.getElementById("frm_fdesde").value;
	var hasta   = document.getElementById("frm_fhasta").value;
	var element = document.getElementById("tableinfocc");
	var opcion  = document.getElementById("opciones").value;
debugger;
	$.ajax({
	    url : "<?=$urlxInfoProy;?>",
	    data : { fdesde : desde, fhasta : hasta, opcion: opcion  },
	    type : 'GET',
	    dataType : 'json',
	    success : function(json) {
		element.innerHTML = "";

		primera = '<thead>';
		primera +='<tr>';
		primera +='<th scope="col">Fecha</th>';
		primera +='<th scope="col">Comprobante</th>';
		primera +='<th scope="col">Comentario</th>';
		primera +='<th ><div class="text-right">Importe $</div></th>';
		primera +='<th ><div class="text-right">Saldo $</div></th>';
		primera +='<th ><div class="text-right">Importe U$S</div></th>';
		primera +='<th ><div class="text-right">Saldo U$S</div></th>';
		primera +='<th scope="col">Entidad</th>';
		primera +='</tr>';
		primera +='</thead>';
		var totales    =  {saldoMN:0.00, saldoUS:0.00 };
		var registro   =  {valorMN:0.00, valorUS:0.00 };
		$("#tableinfocc").append(primera);
		$("#tableinfocc").append("<tbody>");         // class='tbodyalt' >");

		if (opcion == 1){
		    json.forEach (function(item,index){
			if (Object.prototype.hasOwnProperty.call(item, 'saldo_mn_tot')){
			    registro['valorMN'] = str2num(item['debe_mn_tot']) -str2num(item['haber_mn_tot']);
			    registro['valorUS'] = str2num(item['debe_div_tot'])-str2num(item['haber_div_tot']);

			    if (registro['valorMN'] + registro['valorUS'] > 0){

				totales['saldoMN'] += registro['valorMN']
				totales['saldoUS'] += registro['valorUS']
				xR1     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(registro['valorMN']);
				xR2     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(registro['valorUS']);
				xT1     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(totales['saldoMN']);
				xT2     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(totales['saldoUS']);
				elNro   = (item['cc_numero']>0) ? " (Nro."+item['cc_numero']+")" : '';
				classTr = (item['cc_id'] != item['id_debi'] ? "table-warning" : "table-active");
				fila ="<tr id='id_"+item['cc_id']+"' class='"+classTr+"'  >";
				fila+="<td>"+formFecha(item['cc_fecha'])+"</td>";
				fila+="<td>"+item['tc_abreviado']+elNro+"</td>";
				fila+="<td>"+item['cc_comentario']+"</td>";
				fila+="<td><div class='text-right'>"+xR1 +"</div></td>";
				fila+="<td style='background:blue;color:white'><div class='text-right'>"+xT1+"</div></td>";
				fila+="<td><div class='text-right'>"+xR2 +"</div></td>";
				fila+="<td style='background:blue;color:white'><div class='text-right'>"+xT2+"</div></td>";
				fila+="<td>"+item['e_razon_social']+"("+item['cc_entidad_id']+")</td>";
				fila+="</tr>";
			        $("#tableinfocc").append(fila);
			    }
			}else{
			    nombProy  = item['p_nombre'];
			    idProy    = item['p_id']
			    dirProy   = item['direccion'];
			    localProy = item['local_prov'];
			}
			$('#printArea').attr('disabled', false);
		    });
		}else if (opcion == 2){

		    json.forEach (function(item,index){
			if (Object.prototype.hasOwnProperty.call(item, 'saldo_mn_tot')){
			    registro['valorMN'] = item['mn']/1; //str2num(item['mn']);
			    registro['valorUS'] = item['div']/1; //str2num(item['div']);

			    if (registro['valorMN'] + registro['valorUS'] > 0){

				totales['saldoMN'] += registro['valorMN']
				totales['saldoUS'] += registro['valorUS']
				xR1     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(registro['valorMN']);
				xR2     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(registro['valorUS']);
				xT1     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(totales['saldoMN']);
				xT2     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(totales['saldoUS']);
				elNro   = (item['cc_numero']>0) ? " (Nro."+item['cc_numero']+")" : '';
			        classTr = (item['cc_id'] != item['id_debi'] ? "table-warning" : "table-active");
			        fila ="<tr id='id_"+item['cc_id']+"' class='"+classTr+"'  >";
			        fila+="<td>"+formFecha(item['cc_fecha'])+"</td>";
			        fila+="<td>"+item['tc_abreviado']+elNro+"</td>";
			        fila+="<td>"+item['cc_comentario']+"</td>";
			        fila+="<td><div class='text-right'>"+xR1 +"</div></td>";
			        fila+="<td style='background:blue;color:white'><div class='text-right'>"+xT1+"</div></td>";
			        fila+="<td><div class='text-right'>"+xR2 +"</div></td>";
			        fila+="<td style='background:blue;color:white'><div class='text-right'>"+xT2+"</div></td>";
			        fila+="<td>"+item['e_razon_social']+"("+item['cc_entidad_id']+")</td>";
			        fila+="</tr>";
			        $("#tableinfocc").append(fila);
			    }
			}else{
			    nombProy  = item['p_nombre'];
			    idProy    = item['p_id']
			    dirProy   = item['direccion'];
			    localProy = item['local_prov'];
			}
			$('#printArea').attr('disabled', false);
		    });
		}
		$("#tableinfocc").append("</tbody>");
		$("#dialogMsg1").text("Totales:   $"+(totales['valorMN'])+"  ---   U$S"+(totales['valorUS']));
	    },
	    error : function(xhr, status) {
		alert('Disculpe, existió un problema 1 ');
	    },
	});
    })
})

</script>

<?php $this->load->view('footer');?>
