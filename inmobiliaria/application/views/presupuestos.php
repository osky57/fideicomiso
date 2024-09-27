<!-- header -->
<?php $this->load->view('header');?>
<div class="row">
	
	<div class="main" style='padding-left:15px;'>
<h5><b>
Presupuestos
</b></h5>

<!-- fin header -->
    <div style='padding-top:20px;'>


	<div style='padding-top:10px;padding-bottom:10px;'>
	    <div class="row">
		<div class="col-md-10">
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
		    </div>
		</div>
		<div class="col-md-2">
		    <a id="llamaCC" class="btn btn-success" ><i class="material-icons">&#xE147;</i> <span>Nuevo Movimiento</span></a>
		</div>
	    </div>
	</div>

	<table
	    id="table"
	    data-locale="es-AR"
	    data-toggle="table"
	    data-height="500"
	    data-pagination="true"
	    data-side-pagination="server"
	    data-remember-order="true"
	    data-page-list="[10, 25, 50, All]"
	    <?php echo $elurl ?> >

	    <thead>
	    <tr>

		<?php foreach( $campos as $cr){ ?>
		    <th data-field="<?php echo $cr[0] ?>" <?php echo $cr[1] ?> ><?php echo $cr[2] ?></th>
		<?php } ?>

	    </tr>
	    </thead>
	</table>

<script>

    function fn_action(value, row) {
	retE  = '<a  class="btn btn-primary" onclick="abrirFormulario(\'<?php echo $urlform ?>?name=frm-presupuestos&id='+row.pre_id+'\',\'Editar '+row.pre_id+'\')" href="#"><i class="fa fa-edit"></i></a>' ;
	retD  = '<a  class="btn btn-danger"  onclick="return confirm(\'¿Confirma eliminar?\')" href="<?php echo $urldel ?>?id='+row.pre_id+'"><i class="fa fa-trash"></i></a> ';
	if (row.cant_cc == 0){
	    return  retE + retD;
	}
	return retE;
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
	var idEnti  = $("#frm_entidad_id").val();
	if (idEnti > 0){
	    abrirFormulario('/index.php/Presupuestos/cargaFormulario?name=frm-presupuestos&frm_entidad_id='+idEnti,'Nuevo Movimiento');
	}else{
	    alert("Debe indicar un proveedor");
	}
    });



</script>
<!-- footer -->
</div>
</div>
<?php $this->load->view('footer');?>
<!-- fin footer -->
