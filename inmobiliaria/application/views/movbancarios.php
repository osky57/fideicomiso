<!-- header -->
<?php $this->load->view('header');?>

<div id="dialog">
<p id="dialogMsg1"></p>
<p id="dialogMsg2"></p>
<div id="tablaApl"></div>
<div id="tablaPag"></div>
</div>

<div class="row">
	
<div class="main" style='padding-left:15px;'>
<!-- fin header -->

    <h5><b><?php echo $titulo ?></b></h5>
    <div style='padding-top:10px;padding-bottom:10px;'>
	<div class="row">
	    <div class="col-md-8">
		<div class="row" style='padding-left:15px;'>
		    <div class="col-md-6 btn btn-success">
			    Filtrar desde: <input type="date" name="frm_fdesde" id="frm_fdesde" value="<?=$fDesde;?>" >
			    <br>Filtrar hasta:         <input type="date" name="frm_fhasta" id="frm_fhasta" value="<?=$fHasta;?>" >
		    </div>
		    <div class="col-md-6 btn btn_success"> 
			    <select class="custom-select" id="frm_cuentabanc_id" name="frm_cuentabanc_id">
			    <?php foreach($cuentasbanc as $item){?>
				<option value="<?=$item['id'];?>" ><?=$item['denominacion'];?>-<?=$item['id'];?></option>
			    <?php } ?>
			    </select>
		    </div>
		</div>
	    </div>

	    <div class="col-md-2">
		<a id="llamaCB" class="btn btn-success" ><i class="material-icons">&#xE147;</i> <span>Nuevo Movimiento</span></a>
	    </div>

	</div>
    </div>
<!--
	    data-remember-order="true"
	    data-side-pagination="server"
	    data-search="true"
	    data-page-list="[10, 25, 50, All]"
	    data-pagination="true"

-->

<div class="container-fluid">
    <div class="row">
        <div class="col-xs-12">

	<table class="tbodyalt"
	    id="table"
	    data-toggle="table"
	    data-height="500"
	    <?php echo $elurl ?> >

	    <thead>
	    <tr>

		<?php foreach( $campos as $cr){ ?>
		    <th class="text-right" data-field="<?php echo $cr[0] ?>" <?php echo $cr[1] ?>  ><?php echo $cr[2] ?></th>
		<?php } ?>

	    </tr>
	    </thead>
	</table>

        </div>
    </div>
</div>


<script>

var fConci;

////////////////////////////////////////////////////////////////////////////////////
function llamafconciliacion(laFecha,elId){

    if (confirm("Confirma la conciliación del movimiento")){
	console.log("SI");
	$.ajax({
	    url : "<?=$urlactuconci;?>",
	    data : { idcomp : elId, fechaconci : laFecha },
	    type : 'GET',
	    dataType : 'json',
	    success : function(json) {
		if (json == 1){
		    alert("Se concilió el movimiento");
		}else{
		    alert("Hubo un error al conciliar el movimiento!!!!");
		}
	    }
	});
    }else{
	console.log("NO se va a conciliar");
    }

}


////////////////////////////////////////////////////////////////////////////////////
function fn_in_date(value, row) {
    if (row.mb_id > 0){
	fConci = row.mb_conciliacion;
	if (fConci == null){
	    fConci = '';    //new Date().toLocaleDateString("fr-CA");;
	}
	ret = '<input type="date" id="f_conci" name="f_conci" value="'+fConci+'" onchange="llamafconciliacion(this.value,'+row.mb_id+')">';
	return ret;
    }
}


////////////////////////////////////////////////////////////////////////////////////
function fn_action(value, row) {
    if (row.mb_id > 0){
//	retE  = '<a href="#myModal" class="btn btn-primary" role="button" class="btn" data-toggle="modal"><i class="fa fa-edit"></i></a>';
//	retD  = '<a  class="btn btn-danger"  onclick="return confirm(\'¿Confirma eliminar?\')" href="<?php echo $urldel ?>?id='+row.mb_id+'"><i class="fa fa-trash"></i></a>';
//	return  retD;
    }
}




////////////////////////////////////////////////////////////////////////////////////

$(document).ready(function() {


////////////////////////////////////////////////////////////////////////////////////
    $("#frm_fdesde, #frm_fhasta, #frm_cuentabanc_id").on('change', function() {
	fdesde = $("#frm_fdesde").val();
	fhasta = $("#frm_fhasta").val();
	idEnti = $("#frm_cuentabanc_id").val();
	$('#table').bootstrapTable("refresh", {
	    url: "<?php echo $urlrecupag ?>",
	    query: { idEnti: idEnti, fDesde: fdesde, fHasta: fhasta }
	});
    });


////////////////////////////////////////////////////////////////////////////////////
    $("#llamaCB").click(function(){
	var idEnti = $("#frm_cuentabanc_id").val();
	if (idEnti > 0){
	    abrirFormulario('/index.php/Movbancarios/cargaFormulario?name=frm-movbancarios&identi='+idEnti,'Nuevo Movimiento');
	}else{
	    alert("Debe seleccionar una cuenta bancaria");
	}
    });


////////////////////////////////////////////////////////////////////////////////////
    $("#dialog").dialog({
	autoOpen: false,
	modal: true,
	buttons: {
	    "Cerrar": function () {
		$(this).dialog("close");
	    }
	}
    });


////////////////////////////////////////////////////////////////////////////////////
    $('#table').on('dblclick', 'tr', function (dato) {
	elId = dato.currentTarget.cells[0].textContent;
	if ( elId > 0){
	    $.ajax({
		url : "<?=$urlinfocomp;?>",
		data : { idcomp : elId },
		type : 'GET',
		dataType : 'json',
		success : function(json) {
		    armaConsuComprob(json);
		    $("#tablaPag").html(lasA);
		    $("#dialog").dialog("option", "width", 1300);
		    $("#dialog").dialog("option", "height", 600);
		    $("#dialog").dialog("option", "resizable", true);
		    $("#dialog").dialog("open");
		}
	    })
	}
    });
})



</script>
<!-- footer -->
</div>
</div>
<?php $this->load->view('footer');?>
<!-- fin footer -->
