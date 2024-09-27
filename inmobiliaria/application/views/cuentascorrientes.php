<!-- header -->
<?php $this->load->view('header');?>

<!--
<style>
  p {
    color: blue;
    margin: 12px;
  }
  b {
    color: red;
  }
</style>
-->



<div id="dialog">
<p id="dialogMsg1"></p>
<p id="dialogMsg2"></p>
<div id="tablaApl"></div>
<div id="tablaPag"></div>
</div>

<div class="row">
	
<div class="main" style='padding-left:15px;'>
<!-- fin header -->

<div style='padding-left:20px;'>
    <h5><b><?php echo $titulo ?></b></h5>
    <div style='padding-top:10px;padding-bottom:10px;'>
	<div class="row">
	    <div class="col-md-8">
		<div class="row" style='padding-left:15px;'>
		    <div class="col-md-5 btn btn-success">
			    Filtrar desde: <input type="date" name="frm_fdesde" id="frm_fdesde" value="<?=$fDesde;?>" >
			    <br>Filtrar hasta:         <input type="date" name="frm_fhasta" id="frm_fhasta" value="<?=$fHasta;?>" >
		    </div>
		    <div class="col-md-5 btn btn_success"> 
			    <select class="custom-select" id="frm_entidad_id" name="frm_entidad_id">
			    <?php foreach($entidades as $item){?>
				<option value="<?=$item['e_id'];?>" ><?=$item['e_razon_social'];?>-<?=$item['e_id'];?>-(<?=$item['tipoentidad'];?>)</option>
			    <?php } ?>
			    </select>
		    </div>
<!--
		    <div class="col col-md-2" id="div_proye" name="div_proye" >
			<input class="form-check-input" type="checkbox" value="1" id="frm_solo_proyecto" name="frm_solo_proyecto">
			<label class="form-check-label" for="flexCheckChecked">Proyecto actual</label>
		    </div>
-->
		</div>

	    </div>
	    <div class="col-md-2">
		<a id="llamaCC" class="btn btn-success" ><i class="material-icons">&#xE147;</i> <span>Nuevo Movimiento</span></a>
	    </div>
	    <?php if ( $titulo == 'Inversores'){ ?>
		<div class="col-md-2" align="right">
		    <a id="llamaGenCuo" class="btn btn-success" ><i class="material-icons">&#xE147;</i> <span>Generar Cuotas</span></a>
		</div>
	    <?php } ?>
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
	    data-page-list="[10, 25, 50, All]"
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
</div>



<script>

function fn_action(value, row) {
debugger;
    if (row.cc_id > 0){
	retD  = '<a  class="btn btn-danger"  onclick="return confirm(\'¿Confirma eliminar?\')" href="<?php echo $urldel ?>?ii='+row.cc_entidad_id+'&id='+row.cc_id+'"><i class="fa fa-trash"></i></a>';
	aB    = ['4','5'];
	cRet  = ''; 
	cNum  = row.cc_id.padStart(8,'0');
	if (aB.includes(row.tc_modelo)){
	    cRet = '<a  class="btn btn-info" onclick="return confirm(\'¿Descarga el PDF?\')" href="<?php echo base_url('pdf')?>/'+cNum+'.pdf" download><i class="fa fa-save"></i></a>';
	}
	if (row.tiene_apli == 0){
	    cRet +=  retD;
	}
	return cRet;
    }
}

$(document).ready(function() {
    if ('<?php echo $sistema ?>' == 'I'){
        $("#div_proye").hide();
    }
    $("#frm_fdesde, #frm_fhasta, #frm_entidad_id").on('change', function() {
	fdesde = $("#frm_fdesde").val();
	fhasta = $("#frm_fhasta").val();
	idEnti = $("#frm_entidad_id").val();
	$('#table').bootstrapTable("refresh", {
	    url: "<?php echo $urlrecupag ?>",
	    query: { idEnti: idEnti, fDesde: fdesde, fHasta: fhasta }
	});
    });

    $("#llamaCC").click(function(){
	var opeMenu = <?php echo $opemenu ?>;
	var idEnti  = $("#frm_entidad_id").val();
	if (idEnti > 0){
	    abrirFormulario('/index.php/Cuentascorrientes/cargaFormulario?name=frm-cuentascorrientes&opemenu='+opeMenu+'&idinv='+idEnti,'Nuevo Movimiento');
	}else{
	    alert("Debe indicar una entidad");
	}
    });

    $("#llamaGenCuo").click(function(){
	abrirFormulario('/index.php/Cuentascorrientes/cargaGenCuo?name=frm-cuentascorrientes-lote','Generar Cuotas');
    });

    $("#dialog").dialog({
	autoOpen: false,
	modal: true,
	buttons: {
	    "Cerrar": function () {
		$(this).dialog("close");
	    }
	}
    });

    $('#table').on('dblclick', 'tr', function (dato) {
	elId = dato.currentTarget.cells[0].textContent;
	if ( elId > 0){
	    $.ajax({
		url : "<?=$urlinfocomp;?>",
		data : { idcomp : elId },
		type : 'GET',
		dataType : 'json',
		success : function(json) {

debugger;
		    armaConsuComprob(json);

//console.log(armaConsuComprob(json));
//console.log(formNume(1234));



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
