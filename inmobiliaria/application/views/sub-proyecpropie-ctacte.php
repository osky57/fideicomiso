<?php $id_form=uniqid();?>
<form action="<?php echo base_url('index.php/proyectostipospropiedades/guardaProyPropieCtaCte') ?>" method="POST">
    <div class="container">
	<a class="btn btn-success" 
	    onclick="abrirFormulario('/index.php/Cuentascorrientes/cargaFormulario?name=frm-cuentascorrientes&idinv=<?php echo $idInv;?>&idFormu=<?php echo $id_form;?>' ,'Nuevo Movimiento')"><i class="material-icons">&#xE147;</i> <span>Nuevo Movimiento</span></a>
    </div>
    <div class="table-responsive">
	<input type="hidden" id="elid" name="elid" value="<?=$elid;?>">
	<div class="table-wrapper-scroll-y my-custom-scrollbar">
	<table id="myTablaCaja<?=$id_form;?>" class="table table-bordered">

<!--

	    <thead>
		<tr>
			<th>Fecha</th>
			<th>Tipo</th>
			<th><div class="text-right">Debe $</div></th>
			<th><div class="text-right">Haber $</div></th>
			<th><div class="text-right">Saldo $</div></th>
			<th><div class="text-right">Debe U$S</div></th>
			<th><div class="text-right">Haber U$S</div></th>
			<th><div class="text-right">Saldo U$S</div></th>
			<th>Comentario</th>
			<th>Acciones</th>
		</tr>
	    </thead>
	    <tbody>
		<?php foreach($cc as $item){?>
			<tr>
				<td class="col-sm-1"><?=$item['cc_fecha'];?></td>
				<td class="col-sm-2"><?=$item['tc_descripcion'];?></td>
				<td class="col-sm-1"><div class="text-right"><?=$item['debe_txt_mn_tot'];?></div></td>
				<td class="col-sm-1"><div class="text-right"><?=$item['haber_txt_mn_tot'];?></div></td>
				<td class="col-sm-1"><div class="text-right"><?=$item['saldo_mn'];?></div></td>
				<td class="col-sm-1"><div class="text-right"><?=$item['debe_txt_div_tot'];?></div></td>
				<td class="col-sm-1"><div class="text-right"><?=$item['haber_txt_div_tot'];?></div></td>
				<td class="col-sm-1"><div class="text-right"><?=$item['saldo_div'];?></div></td>
				<td class="col-sm-4"><?=$item['cc_comentario'];?></td>
				<td class="col-sm-4"><div class="text-right"</td>
			</tr>
		<?php } ?>
	    </tbody>
-->
	    <tfoot>
	    </tfoot>
	</table>
	</div>
    </div>
</form>


<script>

var idFormu =  '<?=$id_form;?>';

$(document).ready(function(e) { 
    CargaTabla(1);
});

$("#myTablaCaja"+idFormu).on('click', function(event) {
    CargaTabla(2);
});


function CargaTabla(ii){
    var element = document.getElementById("myTablaCaja"+idFormu);
    var idEnti  = '<?=$idInv;?>';
    $.ajax({
	url : "<?=$urlxResuCC;?>",
	data : { id : idEnti },
	type : 'GET',
	dataType : 'json',

	success : function(json) {
	    while (element.firstChild) {
		element.removeChild(element.firstChild);
	    }
	    primera = '<thead>';
	    primera +='<tr><th scope="col">Fecha</th>';
	    primera +='<th scope="col">Tipo</th>';
	    primera +='<th ><div class="text-right">Debe $</div></th>';
	    primera +='<th ><div class="text-right">Haber $</div></th>';
	    primera +='<th ><div class="text-right">Saldo $</div></th>';
	    primera +='<th ><div class="text-right">Debe U$S</div></th>';
	    primera +='<th ><div class="text-right">Haber U$S</div></th>';
	    primera +='<th ><div class="text-right">Saldo U$S</div></th>';
	    primera +='<th scope="col">Comentario</th>';
	    primera +='<th scope="col">Acciones</th>';
	    primera +='</tr>';
	    primera +='</thead>';   //<tbody>';
	    $("#myTablaCaja"+idFormu).append(primera);
	    json.forEach (function(item,index){
		fila = "<tr>";
		fila+="<td>"+item['cc_fecha']+"</td>";
		fila+="<td>"+item['tc_descripcion']+"</td>";
		fila+="<td><div class='text-right'>"+item['debe_txt_mn_tot']+"</div></td>";
		fila+="<td><div class='text-right'>"+item['haber_txt_mn_tot']+"</div></td>";
		fila+="<td><div class='text-right'>"+item['saldo_mn']+"</div></td>";
		fila+="<td><div class='text-right'>"+item['debe_txt_div_tot']+"</div></td>";
		fila+="<td><div class='text-right'>"+item['haber_txt_div_tot']+"</div></td>";
		fila+="<td><div class='text-right'>"+item['saldo_div']+"</div></td>";
		fila+="<td>"+item['cc_comentario']+"</td>";
		fila+="<td></td></tr>";
		$("#myTablaCaja"+idFormu).append(fila);
	    });
	},
	error : function(xhr, status) {
	    alert('Disculpe, existió un problema 1 ');
	},
    });
}

</script>


