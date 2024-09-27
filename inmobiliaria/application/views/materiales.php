<!-- header -->
<?php $this->load->view('header');?>
<div class="row">
	<div class="main">
<!-- fin header -->
<h5><b>
Cuentas Bancarias
</b></h5>
    <div style='padding-top:20px;'>
	<a class="btn btn-success" onclick="abrirFormulario('/index.php/Materiales/cargaFormulario?name=frm-materiales','Nuevo Material')"><i class="material-icons">&#xE147;</i> <span>Agregar Material</span></a>
	</div>
	
	<table
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
    retE  = '<a  class="btn btn-primary" onclick="abrirFormulario(\'<?php echo $urlform ?>?name=frm-materiales&id='+row.m_id+'\',\'Editar '+row.m_id+'\')" href="#"><i class="fa fa-edit"></i></a>' ;
    retD  = '<a  class="btn btn-danger"  onclick="return confirm(\'¿Confirma eliminar?\')" href="<?php echo $urldel ?>?id='+row.m_id+'"><i class="fa fa-trash"></i></a> ';
    return  retE + retD ;

}
</script>
<!-- footer -->
</div>
</div>
<?php $this->load->view('footer');?>
<!-- fin footer -->
