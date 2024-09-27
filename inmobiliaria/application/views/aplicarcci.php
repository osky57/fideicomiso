
<!--     overflow-y: auto;
 header -->
<?php $this->load->view('header');?>

<style>
.container {
    gap: 10px;
    display: grid;
    height: 300px;
    width: 1550px;
    float:left;
}

table,th,td {
    border: 1px solid;
}

tables_uix{
    overflow: scroll;
    height: 200px;
    width: 1450px;
    float:left;
}

saldos {
  background-color: lightgrey;
  color: blue;
  font-weight: bold;
}





.xbox {
  border: 3px solid rebeccapurple;
  background-color: lightgray;
  padding: 10px;
  margin: 20px;
  width: 300px;
  height: 150px;
  border-top-style: dotted;
}

.box {
  border: 3px solid #333333;
  border-right-width: 20px;
  border-left-width: 20px;
  border-bottom-color: hotpink;
  background-color: lightgray;
}

.alternate {
  box-sizing: border-box;
}

</style>


<div id="dialog" title="Aplicaciones">
<p id="dialogMsg"></p>
<br>
<input type="number" id="montoApli" min="0" style="max-width:100px; width:100px;"/>
</div>

<div class="row" id="divaplicc" name="divaplicc" style='padding-left:15px;'>
    <div class="main" >
	<h5><b>
	Aplicaciones de Cuentas Corrientes Inversores
	</b></h5>


	<div class="row" id="divaplicc" name="divaplicc"  style='padding-left:15px;'>
	<div class="col-8 box"><p>En esta parte del sistema se podrán realizar tanto aplicaciones como revertir el proceso
	    de los pagos sobre movimientos deudores. Una vez elegido el período a filtrar y la entidad, se observarán
	    los movimientos deudores en la ventana superior. Y los pagos o créditos sin aplicar en la ventana inferior.
	    Las aplicaciones se realizan posicionándose con el mouse en el movimiento elegido pintado en color celeste de la ventana inferior
	    y presionando con el botón izquierdo del mouse y sin soltarlo, arrastrar hasta el movimiento duedor elegido de color gris en la ventana
	    superior, soltando el botón del mouse, se desplegará una ventana preguntando al operador cual es el importe a mover.
	    Si ocurre que no se puede realizar, el sistema informará cual es el problema ocurrido. La desaplicación es similar, se tomará
	    el movimiento en color amarillo de la ventana superior, se arrastrará y soltará en cualquier lugar de la ventana inferior.</p>
	</div>
	</div>


	<div style='padding-top:20px;'>
	    <form action="<?php echo base_url('index.php/aplicarcci/aplicarcc') ?>" method="POST" id="myForm">
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
	    </form>
	    <br>
	    <div class="container" style='float:left; margin-bottom: 10px' id="elcontainer">
		<div id="Dtableaplicc">
		    <table cellspacing="0" cellpadding="0" border="0" >
			<tr>
			    <td>
				<table class="tables_uix"  cellspacing="0" cellpadding="1" border="1" >
				    <tr id="th1" style="color:black;background-color:white">
					<th style=" width: 100px;" scope="col">Fecha</th>
					<th style=" width: 220px;" scope="col">Comprobante</th>
					<th style=" width: 280px;" scope="col">Comentario</th>
					<th style=" width: 115px;" align="right">Importe $</th>
					<th style=" width: 115px;" align="right">Aplicado $</th>
					<th style=" width: 115px;" align="right">Saldo $</th>
					<th style=" width: 115px;" align="right">Importe U$S</th>
					<th style=" width: 115px;" align="right">Aplicado U$S</th>
					<th style=" width: 115px;" align="right">Saldo U$S</th>
				    </tr>
				</table>
			    </td>
			</tr>
			<tr>
			    <td>
				<div style="width:1350px; height:250px; overflow:auto;">
				    <table  id="t_draggable1" class="tables_uix"></table>
				</div>
			    </td>
			</tr>
		    </table>
		</div>
	    </div>
	    <div class="container" style='float:left;  margin-bottom: 10px' id="elcontainer">
		<div class="row justify-content-start">
		    <div class="col-11">
			<div id="Dtablesinaplicc">
			    <table cellspacing="0" cellpadding="0" border="0" >
				<tr>
				    <td>
					<table class="tables_uix"  cellspacing="0" cellpadding="1" border="1" >
					    <tr id="th2" style="color:black;background-color:white">
						<th style=" width: 100px;" scope="col">Fecha</th>
						<th style=" width: 220px;" scope="col">Comprobante</th>
						<th style=" width: 280px;" scope="col">Comentario</th>
						<th style=" width: 150px;" align="right">Sin Aplicar $</th>
						<th style=" width: 150px;" align="right">Sin Aplicar U$S</th>
					    </tr>
					</table>
				    </td>
				</tr>
				<tr>
				    <td>
					<div class="dDraggable2" style="width:950px; height:220px; overflow:auto;">
					    <table  id="t_draggable2" class="tables_uix"></table>
					</div>
				    </td>
				</tr>
			    </table>
			</div>
		    </div>
		    <div class="col-1">
			<div class="btn btn-success row justify-content-center" id="elboton" style="display: none;">
			    <div class="col-sm" >
				<button type="button" class="btn btn-primary" id="grabamod">Grabar Modificaciones</button>
			    </div>
			</div>
		    </div> 
		</div> 
	    </div>
<!-- footer -->




	</div>



    </div>

</div>
<script>
    var modifico = false;
    var dragStart;
    var elDrop;
    var elId = 0;
    var trStart21;
    var trStart12;
    var strDrag;
    var nNuevaApli = 0;
    var nSaldoMN = 0;
    var nSaldoUS = 0;
    var posicion = 0;
    var saldo    = 0;
    var aplica   = 0;
    var moneda   = '';
    var laClassDrop = '';

    var t2Sty    = [' width: 100px;',						//0
		    ' width: 220px;',						//1
		    ' width: 280px;',						//2
		    ' width: 150px;',						//3
		    ' width: 150px;',						//4
		    ' width: 10px; display:none; visibility:collapse;',		//5
		    ' width: 10px; display:none; visibility:collapse;', 	//6
		    ' width: 10px; display:none; visibility:collapse;'];	//7

    var t1Sty    = [' width: 100px;',				//1
		    ' width: 220px;',				//2
		    ' width: 280px;',				//3
		    ' width: 115px;',				//4
		    ' width: 115px;',				//5
		    ' width: 115px;',				//6
		    ' width: 115px;',				//7
		    ' width: 115px;',				//8
		    ' width: 115px;'];				//9

////////////////////////////////////////////////////////////////////////////////////////////////////////
    function llamaDialog(msg){
	$("#dialogMsg").text(msg);
	$("#montoApli").val(aplica);
	$("#montoApli").attr("max",aplica);
	$("#montoApli").select();
	$("#dialog").dialog("option", "width", 600);
	$("#dialog").dialog("option", "height", 300);
	$("#dialog").dialog("option", "resizable", false);
	$("#dialog").dialog("open");
    }

////////////////////////////////////////////////////////////////////////////////////////////////////////
    $("#dialog").dialog({
	autoOpen: false,
	modal: true,
	buttons: {
	    "Confirma": function () {
		$(this).dialog("close");
		nMax  = $("#montoApli").attr("max");	//max del input
		nVal  = $("#montoApli").val();		//valor del input
		difer = nMax - nVal;
		nNuevaApli = $("#montoApli").val();
		if ( nVal*100 > nMax*100){
		    alert("El valor ingresado no debe superar el máximo de "+nMax+" ("+nVal+")");
		    nNuevaApli   = 0;
		}else if ( saldo*100 < nVal*100 ){
		    alert("Superó el valor del saldo de "+saldo+" ("+nVal+")");
		    nNuevaApli   = 0;
		}else{
		    GrabaDrop();
		}
	    },
	    "Cerrar": function () {
		$(this).dialog("close");
		nNuevaApli   = 0;
	    }
	}
    });


////////////////////////////////////////////////////////////////////////////////////////////////////////
    function GrabaDrop(){

	var debeElimi  = false;
	var filaElimi  = strDrag;
	var nuevoTD    = [];
	var nuevoSaldo = 0;
	var laClass    = '';
	if (dragStart[0] == 't2'){
	    $("#elboton").show();
	    modifico       = true;

	    strDrag        = strDrag.replace('t2','t1');
	    var dragDrop   = strDrag.split("_");
	    laClass        = elId+"_"+dragDrop[2];
	    laClass        = 'table-warning ui-sortable-handle '+elId+' '+dragDrop[2]+' '+laClass;
	    lExiste        = false;

	    $("#t_draggable1 tbody tr").each(function (index) {
		if ($(this).attr("class") == laClass){
		    lExiste = true;
		    if (moneda == 'P'){
			td3     = Number($(this).find("td:eq(4)").text());
			td3     = td3 + Number(nNuevaApli);     //Number(trStart21[3]);
			$(this).find("td:eq(4)").text(td3.toFixed(2));
		    }else{
			td4     = Number($(this).find("td:eq(7)").text());
			td4     = td4 + Number(nNuevaApli);     // Number(trStart21[4]);
			$(this).find("td:eq(7)").text(td4.toFixed(2));
		    }
		}
	    })

	    if (!lExiste){
		var nuevaFila  = t_draggable1.insertRow(posicion);
		nuevaFila.setAttribute("class",laClass);  //en class pone el id de la fila de t1
		nuevaFila.setAttribute("draggable",'true' );
		nuevaFila.setAttribute("id",strDrag );  //pone el id para la tabla t1
		for (i=0 ; i<9; i++){				//genera las td de la nueva fila
		    nuevoTD.push( nuevaFila.insertCell(i) );
		    nuevoTD[i].setAttribute("style",t1Sty[i]);
		}
		nuevoTD[0].innerHTML = trStart21[0]; //fecha
		nuevoTD[1].innerHTML = trStart21[1]; //tipo de comprobante (recibo/n.c.)
		nuevoTD[2].innerHTML = trStart21[2]; //comentario
	    }
	    if (moneda == 'P'){
		trStart21[3] = trStart21[3] - nNuevaApli;
		if (!lExiste){
		    nuevoTD[4].innerHTML = nNuevaApli==0 ? '' : Number.parseFloat(nNuevaApli).toFixed(2);   //trStart21[3];    si la apli es MN
		}
		debeElimi = (trStart21[3] <= 0 && trStart21[4] == '' );
		$("#"+filaElimi).find("td:eq(3)").text(trStart21[3]==0 ? '' : Number.parseFloat(trStart21[3]).toFixed(2));
	    }else if (moneda == 'D'){
		trStart21[4] = trStart21[4] - nNuevaApli;
		if (!lExiste){
		    nuevoTD[7].innerHTML = nNuevaApli==0 ? '' : Number.parseFloat(nNuevaApli).toFixed(2);   //trStart21[4];    si la apli es US
		}
		debeElimi = (trStart21[4] <= 0 && trStart21[3] == '');
		$("#"+filaElimi).find("td:eq(4)").text(trStart21[4]==0 ? '' : Number.parseFloat(trStart21[4]).toFixed(2));
	    }
	    if (debeElimi){
		$("#"+filaElimi).remove();
	    }
	    td0MN = $("#"+elId ).find("td:eq(3)").text();
	    td0US = $("#"+elId ).find("td:eq(6)").text();
	    $("#"+elId ).find("td:eq(5)").text('');
	    $("#"+elId ).find("td:eq(8)").text('');
	    $("."+laClass ).find("td:eq(5)").text('');
	    $("."+laClass ).find("td:eq(8)").text('');
	    $("."+elId).each(function(index){
		td0MN = td0MN - $(this).find("td:eq(4)").text();
		td0US = td0US - $(this).find("td:eq(7)").text();
		$(this).find("td:eq(5)").text( (td0MN==0 ? '' : Number.parseFloat(td0MN).toFixed(2)) );
		$(this).find("td:eq(8)").text( (td0US==0 ? '' : Number.parseFloat(td0US).toFixed(2)) );
		$(this).find("td:eq(5)").css("font-weight","bold" );
		$(this).find("td:eq(8)").css("font-weight","bold" );
	    })
	}
    }

////////////////////////////////////////////////////////////////////////////////////////////////////////
    document.addEventListener('DOMContentLoaded', (event) => {

	//------------------------------------------------------------------------------------------------
	function handleDragStart(e) {
	    var laClass;
	    var trPadre;
	    strDrag   = e.target.id;
	    dragStart = strDrag.split("_");
	    if (dragStart[0] == 't2'){
		trStart21 = [];
		$("#"+strDrag+" td").each(function(xx,zz){
		    trStart21.push($(this).html());
		})
		trStart21.push(strDrag);
	    }else if (dragStart[0] == 't1'){
		laTr      = $(e.target).closest('tr');
		laClass   = $(laTr).attr("class");
		laClass   = laClass.split(" ");
		trPadre   = laClass[2];
		trStart12 = [];
		trStart12.push($(laTr).find("td:eq(0)").text());	//0
		trStart12.push($(laTr).find("td:eq(1)").text());	//1
		trStart12.push($(laTr).find("td:eq(2)").text());	//2
		trStart12.push($(laTr).find("td:eq(4)").text());	//3
		trStart12.push($(laTr).find("td:eq(7)").text());	//4
		trStart12.push("t2_"+dragStart[1]+"_"+dragStart[2]);	//5
		trStart12.push($(e.target).closest('tr').index());	//6
		trStart12.push(trPadre);				//7
	    }
	}

	//------------------------------------------------------------------------------------------------
	function handleDrop(e) {
	    var strDrop  = e.target.id;
	    var losImpor = [];
	    var msg1     = "Máximo que puede aplicar ";
	    elDrop       = strDrop.split("_");
	    if (elDrop[0] == 't1'){    //va de t2 a t1 --> aplica
		if (!e.target.parentNode.attributes.draggable){
		    elId     = e.target.parentNode.attributes[1].textContent;
		    nFilas   = $("#t_draggable1 tr").length;
		    idFila   = elId;     //e.path[1].id; 2023-01-16 ojo el e.path da error, hay q probar bien
		    posicion = $("#"+idFila).index() +1;
		    j        = 0;
		    $("#"+idFila).each(function(){
			//console.log($(this));
			j++;
		    });
		    nApliMN  = 0;
		    nApliUS  = 0;
		    nTotMN   = $("#"+idFila).find("td:eq(3)").html();
		    nTotUS   = $("#"+idFila).find("td:eq(6)").html();
		    $("#t_draggable1 tr").each(function(){	//calcula aplicaciones
			laClase = $(this).attr("class");
			if (laClase.includes(idFila)){
			    nNum     = $(this).find("td:eq(4)").text();
			    nNum     = Number(nNum);   //.parseFloat(nNum).toFixed(2);
			    nApliMN  = nApliMN + nNum;   //(Number.isNaN(nNum)) ? 0 : nNum;
			    nNum     = $(this).find("td:eq(7)").text();
			    nNum     = Number(nNum);     //.parseFloat(nNum).toFixed(2);
			    nApliUS  = nApliUS + nNum;   //(Number.isNaN(nNum)) ? 0 : nNum;
			}
		    })
		    nSaldoMN   = nTotMN-nApliMN;
		    nSaldoUS   = nTotUS-nApliUS;
		    nNuevaApli = 0;
		    if (nTotMN >0 && trStart21[3] == 0){
			alert("La aplicación no puede realizarse por ser de diferente moneda." + nTotMN+" "+trStart21[3]);
		    }else if (nTotUS >0 && trStart21[4] == 0){
			alert("La aplicación no puede realizarse por ser de diferente moneda.."+nTotUS+" "+trStart21[4]);
		    }else{
			if (nSaldoMN >0){  // && nSaldoMN >= trStart21[3]){
			    saldo    = nSaldoMN;
			    aplica   = trStart21[3];
			    moneda   = 'P';
			    llamaDialog(msg1+" $"+nSaldoMN);
			}else if (nSaldoUS >0){ // && nSaldoUS >= trStart21[4]){
			    saldo    = nSaldoUS;
			    aplica   = trStart21[4];
			    moneda   = 'D';
			    llamaDialog(msg1+" U$S"+nSaldoUS);
			}
		    }
		}
	    }else{     //va de t1 a t2  --> desaplica
		if (strDrag.includes('t1_id')){
		    if (e.target.className == 'dDraggable2'){
			if (!strDrag.includes('t2_id')){
			    var nuevoTD    = [];
			    elId           = trStart12[5];   //.at(-2);    //[trStart12.length -2 esta el id);
			    td3            = Number(trStart12[3]);
			    td4            = Number(trStart12[4]);
			    nPtr           = -1;
			    $("#t_draggable2 tbody tr").each(function (index) {
				if ($(this).attr("id") == elId){
				    nPtr = index;
				    td3 = td3 + Number($(this).find("td:eq(3)").text());
				    td4 = td4 + Number($(this).find("td:eq(4)").text());
				    $(this).find("td:eq(3)").text(td3.toFixed(2));
				    $(this).find("td:eq(4)").text(td4.toFixed(2));
				}
			    })
			    if (nPtr == -1){
				var nuevaFila  = t_draggable2.insertRow(-1);
				nuevaFila.setAttribute("class",'table-primary ui-sortable-handle');  //en class pone el id de la fila de t2
				nuevaFila.setAttribute("draggable",'true' );
				nuevaFila.setAttribute("id",elId);  //pone el id para la tabla t2
				for (i=0 ; i<trStart12.length; i++){	//genera las td de la nueva fila
				    nuevoTD.push( nuevaFila.insertCell(i) );
				    nuevoTD[i].innerHTML = trStart12[i];
				    nuevoTD[i].setAttribute("style",t2Sty[i]);
				}
			    }
			    document.getElementById("t_draggable1").deleteRow(trStart12[6]);
			    $("#elboton").show();
			    modifico = true;
			    trId     = '';
			    $("#t_draggable1 tbody tr").each(function (index) {  //recalculando saldos
				if ($(this).attr("class") == 'table-active'){    //tr comprobante
				    trId  = $(this).attr("id");
				    totMN = Number($(this).find("td:eq(3)").text());
				    totUS = Number($(this).find("td:eq(6)").text());
				    $(this).find("td:eq(5)").text((totMN===0?'':totMN.toFixed(2)));
				    $(this).find("td:eq(8)").text((totUS===0?'':totUS.toFixed(2)));
				    $(this).find("td:eq(5)").css({ 'font-weight': 'bold' });
				    $(this).find("td:eq(8)").css({ 'font-weight': 'bold' });
				}else{              //tr aplicacion sobre trId
				    totMN = totMN - Number($(this).find("td:eq(4)").text());
				    totUS = totUS - Number($(this).find("td:eq(7)").text());
				}
				$(this).find("td:eq(5)").text((totMN===0?'':totMN.toFixed(2)));
				$(this).find("td:eq(8)").text((totUS===0?'':totUS.toFixed(2)));
				$(this).find("td:eq(5)").css({ 'font-weight': 'bold' });
				$(this).find("td:eq(8)").css({ 'font-weight': 'bold' });
			    })
			}
		    }
		}
	    }
	    e.stopPropagation(); // stops the browser from redirecting.
	    return false;
	}

	//------------------------------------------------------------------------------------------------
	function handleDragEnd(e) {
	    this.style.opacity = '1';
	    items.forEach(function (item) {
		item.classList.remove('over');
	    });
	}
	//------------------------------------------------------------------------------------------------
	function handleDragOver(e) {
	    if (e.preventDefault) {
		e.preventDefault();
	    }
	    return false;
	}
	//------------------------------------------------------------------------------------------------
	function handleDragEnter(e) {
	    this.classList.add('over');
	}
	//------------------------------------------------------------------------------------------------
	function handleDragLeave(e) {
	    this.classList.remove('over');
	}

	//------------------------------------------------------------------------------------------------
	let items = document.querySelectorAll('.container');
	items.forEach(function(item) {
	    item.addEventListener('dragstart', handleDragStart);
	    item.addEventListener('dragover', handleDragOver);
	    item.addEventListener('dragenter', handleDragEnter);
	    item.addEventListener('dragleave', handleDragLeave);
	    item.addEventListener('dragend', handleDragEnd);
	    item.addEventListener('drop', handleDrop);
	});
    })

////////////////////////////////////////////////////////////////////////////////////////////////////////
$(document).ready(function() {

    $( "#grabamod" ).click(function() {
	if (modifico){
	    if (confirm("Confirma la grabación de las modificaciones?")){
		var enti     = document.getElementById("frm_entidad_id").value;
		var htr1     = [];
		$("#t_draggable1 tr").each(function (index) {
		    var htd     = [];
		    var laClase = $(this).attr("class");
		    if (laClase.includes('table-warning')){
			$(this).children("td").each(function (index2) {
			    htd.push($(this).text());
			})
			htd.push(laClase);
			htr1.push(htd);
		    }
		})
		var htr2     = [];
		$("#t_draggable2 tr").each(function (index) {
		    htd         = [];
		    var laClase = $(this).attr("class");
		    if (laClase.includes('table-primary')){
			$(this).children("td").each(function (index2) {
			    htd.push($(this).text());
			})
			htd.push($(this).attr("id"));
			htr2.push(htd);
		    }
		})
		$.ajax({
			url : "<?=$urlxGraApliCCI;?>",
			type : 'POST',
			data : { tr1 : htr1, tr2 : htr2, entidad : enti },
			dataType : 'json',
			success : function(json) {
			    console.log("se registró");
			    modifico = false;
			    $("#elboton").hide();
			}
		})
	    }
	}
    });
///////////////////////////////////////////////////////////////////////////////////////////////////////
    $('#frm_fdesde, #frm_fhasta, #frm_entidad_id').on('change', function() {
	var desde = document.getElementById("frm_fdesde").value;
	var hasta = document.getElementById("frm_fhasta").value;
	var enti  = document.getElementById("frm_entidad_id").value;
	var t1    = document.getElementById("t_draggable1");
	var t2    = document.getElementById("t_draggable2");
	$.ajax({
	    url : "<?=$urlxApliCCI;?>",
	    data : { fdesde : desde, fhasta : hasta , entidad : enti },
	    type : 'POST',
	    dataType : 'json',
	    success : function(json) {
		modifico = false;
		$("#elboton").hide();
		while (t1.firstChild) {
		    t1.removeChild(t1.firstChild);
		}
		while (t2.firstChild) {
		    t2.removeChild(t2.firstChild);
		}
		$("#t_draggable1").append("<tbody class='t_sortable' >");
		losComp = json['comprob'];
		anteTr  = '';
		if (!$.isEmptyObject(losComp)){
		    losComp.forEach (function(item,index){
			var laClaseTr = "class='table-warning ui-sortable-handle t1_id_"+ anteTr+" "+item['vcc_cc_id']+" t1_id_"+anteTr+"_"+item['vcc_cc_id']+"' draggable='true' ";
			if (item['xxx'] == '00'){
			    laClaseTr = "class='table-active'"; 
			    anteTr = item['vcc_cc_id'];
			}
			fila ="<tr "+laClaseTr+" id='t1_id_"+item['vcc_cc_id']+"'>";
			fila+="<td style='"+t1Sty[0]+"' id='t1_td0_"+item['vcc_cc_id']+"'>"+item['vcc_cc_fecha_dmy']+"</td>";
			fila+="<td style='"+t1Sty[1]+"' id='t1_td1_"+item['vcc_cc_id']+"'>"+item['comprob_deb']+"</td>";
			fila+="<td style='"+t1Sty[2]+"' id='t1_td2_"+item['vcc_cc_id']+"'>"+item['vcc_cc_comentario']+"</td>";
			fila+="<td style='"+t1Sty[3]+"' id='t1_td3_"+item['vcc_cc_id']+"' align='right'>"+item['importe_mn'] +"</td>";
			fila+="<td style='"+t1Sty[4]+"' id='t1_td4_"+item['vcc_cc_id']+"' align='right'>"+item['aplica_mn']+"</td>";
			fila+="<td style='"+t1Sty[5]+"' id='t1_td5_"+item['vcc_cc_id']+"' align='right'><b>"+item['saldo_mn']+"</b></td>";
			fila+="<td style='"+t1Sty[6]+"' id='t1_td6_"+item['vcc_cc_id']+"' align='right'>"+item['importe_div']+"</td>";
			fila+="<td style='"+t1Sty[7]+"' id='t1_td7_"+item['vcc_cc_id']+"' align='right'>"+item['aplica_div']+"</td>";
			fila+="<td style='"+t1Sty[8]+"' id='t1_td8_"+item['vcc_cc_id']+"' align='right'><b>"+item['saldo_div']+"</b></td>";
			fila+="</tr>";
			$("#t_draggable1").append(fila);
		    });
		}
		$("#t_draggable1").append("</tbody>");
		$("#t_draggable2").append("<tbody class='t_sortable'>" );
		losSApli = json['sinapli'];
		if (!$.isEmptyObject(losSApli)){
		    losSApli.forEach (function(item,index){
			var laClaseTr = "class='table-primary ui-sortable-handle'  draggable='true'";
			fila ="<tr  "+laClaseTr+" id='t2_id_"+item['vcc_cc_id']+"'>";
			fila+="<td style='"+t2Sty[0]+"' id='t2_td0_"+item['vcc_cc_id']+"'>"+item['vcc_cc_fecha_dmy']+"</td>";
			fila+="<td style='"+t2Sty[1]+"' id='t2_td1_"+item['vcc_cc_id']+"'>"+item['comprob_deb']+"</td>";
			fila+="<td style='"+t2Sty[2]+"' id='t2_td2_"+item['vcc_cc_id']+"'>"+item['vcc_cc_comentario']+"</td>";
			fila+="<td style='"+t2Sty[3]+"' id='t2_td3_"+item['vcc_cc_id']+"' align='right'>"+item['noaplicado_mn']+"</td>";
			fila+="<td style='"+t2Sty[4]+"' id='t2_td4_"+item['vcc_cc_id']+"' align='right'>"+item['noaplicado_div']+"</td>";
			fila+="<td style='"+t2Sty[5]+"' id='t2_td5_"+item['vcc_cc_id']+"' align='right'></td>";
			fila+="<td style='"+t2Sty[6]+"' id='t2_td6_"+item['vcc_cc_id']+"' align='right'></td>";
			fila+="<td style='"+t2Sty[7]+"' id='t2_td7_"+item['vcc_cc_id']+"' align='right'></td>";
			fila+="</tr>";
			$("#t_draggable2").append(fila);
		    });
		}
		$("#t_draggable2").append("</tbody>");
	    },
	    error : function(xhr, status) {
		alert('Disculpe, existió un problema 1 ');
	    },
	});
    })

})

</script>

<?php $this->load->view('footer');?>
<!-- fin footer -->

