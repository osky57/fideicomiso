<!-- header -->
<?php $this->load->view('header');?>
<div class="row">
	
	<div class="main" style='padding-left:15px;'>

<h5><b>
Tipos de Comprobantes de Cuentas Corrientes
</b></h5>
    <div style='padding-top:20px;'>
	<a class="btn btn-success" onclick="abrirFormulario('/index.php/Tiposcomprob/cargaFormulario?name=frm-tiposcomprob','Nuevo Tipo de Comprobante')"><i class="material-icons">&#xE147;</i> <span>Agregar Tipo de Comprobante</span></a>
	</div>
	
	<table class="tbodyalt"
	    id="table"
	    data-toggle="table"
	    data-height="500"
	    data-pagination="true"
	    data-side-pagination="server"
	    data-remember-order="true"
	    data-search="true"
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

    retE  = '<a  class="btn btn-primary" onclick="abrirFormulario(\'<?php echo $urlform ?>?name=frm-tiposcomprob&id='+row.id+'\',\'Editar '+row.id+'\')" href="#"><i class="fa fa-edit"></i></a>' ;
    retD  = '<a  class="btn btn-danger"  onclick="return confirm(\'¿Confirma eliminar?\')" href="<?php echo $urldel ?>?id='+row.id+'"><i class="fa fa-trash"></i></a> ';

    return  retE + retD ;

}
</script>
<!-- footer -->
</div>
</div>
<?php $this->load->view('footer');?>
<!-- fin footer -->
