<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">

	<title>FidetrustPrueba</title>
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<!-- styles -->
	<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.6.1/css/bootstrap.min.css" integrity="sha512-T584yQ/tdRR5QwOpfvDfVQUidzfgc2339Lc8uBDtcp/wYu80d7jwBgAxbyMh0a9YM9F8N3tdErpFI8iaGx6x5g==" crossorigin="anonymous" referrerpolicy="no-referrer" />
	
	<link href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css" rel="stylesheet" integrity="sha384-wvfXpqpZZVQGK6TAh5PVlGOfQNHSoD2xbE+QkPxCAFlNEevoEH3Sl0sibVcOQVnN" crossorigin="anonymous">
	
	<link rel="stylesheet" href="https://unpkg.com/bootstrap-table@1.20.0/dist/bootstrap-table.min.css">
	
	<link rel="stylesheet" type="text/css" href="<?php echo base_url('assets/css/styles.css') ?>">
	
	<!-- fonts -->
	<link href="https://fonts.googleapis.com/css?family=Roboto" rel="stylesheet"> 
	
	<!-- cargo jquery -->
	<script src="https://code.jquery.com/jquery-3.1.1.min.js" integrity="sha256-hVVnYaiADRTO2PzUGmuLJr8BLUSjGIZsDYGmIJLv2b8=" crossorigin="anonymous"></script>

	<link href="https://code.jquery.com/ui/1.12.1/themes/ui-lightness/jquery-ui.css" rel="stylesheet" />

	<script src="https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.12.1/jquery-ui.min.js"
	    integrity="sha512-uto9mlQzrs59VwILcLiRYeLKPPbS/bT71da/OEBYEwcdNUk8jYIy+D176RYoop1Da+f9mvkYrmj5MCLZWEtQuA=="
	    crossorigin="anonymous"
	    referrerpolicy="no-referrer">
	</script>
<script>

    ///////////////////////////////////////////////////////////////////////////////
    function formNume(nX){
	nDHt = nX*100/100;
	nDHt = (nDHt == 0) ? '' : nDHt.toLocaleString("es-ES");
	return nDHt;
    }

    //////////////////////////////////////////////////////////////////////////////
    function formFecha(nX){
	fF = '';
	if (nX){
	    fC = new Date(nX);
	    fF = fC.toLocaleDateString('es-ES', {  timeZone: 'UTC', });
	}
	return fF;
    }

    //////////////////////////////////////////////////////////////////////////////
    function formStr(nX){
	fF = nX;
	if (nX == null){
	    fF = '';
	}
	return fF;
    }

</script>




</script>

</head>
<!-- sistema prueba <body style="background-color:rgb(20,20,20,0.2);"> -->
<body style="background-color:rgb(255,224,51,0.2);">
<div class="container-fluid">
<?php if(is_loged_in()){ 
$user=$this->session->userdata('logged_in');
?>
<div class="row adminbar-top">
	<div class="col">
		<div class="float-right">
           <i class="fa fa-user-circle" aria-hidden="true"></i> <?= $user['nombre'];?> | <a href="<?php echo base_url('index.php/Usuario/salir') ?>"><i class="fa fa-sign-out" aria-hidden="true"></i> Salir</a> 
        </div>
	</div>
</div>

<div class="row adminbar">
	<div class="col">
		<nav class="navbar navbar-expand-lg">
			<a class="navbar-brand" href="#">Fidetrust</a>
			<button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
				<span class="navbar-toggler-icon"></span>
			</button>

			<div class="collapse navbar-collapse" id="navbarSupportedContent">
				<ul class="navbar-nav mr-auto">
				  <li class="nav-item dropdown">
					<a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-expanded="false">Proyectos</a>
					<div class="dropdown-menu" aria-labelledby="navbarDropdown">
					    <a class="dropdown-item <?php mmenu('1.1')?>" href="<?php echo base_url('index.php/proyectos')?>">Proyectos</a>
					    <a class="dropdown-item <?php mmenu('1.2')?>" href="<?php echo base_url('index.php/tiposprop')?>">Tipos de propiedades</a>
					    <a class="dropdown-item <?php mmenu('1.3')?>" href="<?php echo base_url('index.php/proyectosentidades')?>">Entidades en el proyecto</a>
					    <a class="dropdown-item <?php mmenu('1.4')?>" href="<?php echo base_url('index.php/proyectostipospropiedades')?>">Composición del proyecto</a>
					</div>
				  </li>

				  <li class="nav-item dropdown">
					<a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-expanded="false">Entidades</a>
					<div class="dropdown-menu" aria-labelledby="navbarDropdown">
					    <a class="dropdown-item <?php mmenu('2.1')?>" href="<?php echo base_url('index.php/entidades')?>" >Entidades</a>
					</div>
				  </li>

				  <li class="nav-item dropdown">
					<a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-expanded="false">Cuentas Corrientes</a>
					<div class="dropdown-menu" aria-labelledby="navbarDropdown">
					    <a class="dropdown-item <?php mmenu('3.1')?>"  href="<?php echo base_url('index.php/tiposcomprob')?>">Tipos de comprobantes</a>
					    <a class="dropdown-item <?php mmenu('3.2')?>"  href="<?php echo base_url('index.php/cuentascorrientes?op=32')?>">Inversores</a>
					    <a class="dropdown-item <?php mmenu('4.6')?>"  href="<?php echo base_url('index.php/cuentascorrientes?op=46')?>">Proveedores</a>
					    <a class="dropdown-item <?php mmenu('4.9')?>"  href="<?php echo base_url('index.php/cuentascorrientes?op=49')?>">Prestamistas</a>
					    <a class="dropdown-item <?php mmenu('3.9')?>"  href="<?php echo base_url('index.php/presupuestos')?>">Presupuestos</a>
					    <a class="dropdown-item <?php mmenu('3.3')?>"  href="<?php echo base_url('index.php/aplicarcci')?>">Aplicaciones Ctas.Ctes.Inversores</a>
					    <a class="dropdown-item <?php mmenu('3.6')?>"  href="<?php echo base_url('index.php/aplicarccp')?>">Aplicaciones Ctas.Ctes.Proveedores</a>
					    <a class="dropdown-item <?php mmenu('3.8')?>"  href="<?php echo base_url('index.php/aplicarccpr')?>">Aplicaciones Ctas.Ctes.Prestamistas</a>
					    <a class="dropdown-item <?php mmenu('3.4')?>"  href="<?php echo base_url('index.php/informescc')?>">Informe Entidad</a>
					    <a class="dropdown-item <?php mmenu('3.5')?>"  href="<?php echo base_url('index.php/informesproy')?>">Informe Proyecto</a>
					    <a class="dropdown-item <?php mmenu('3.7')?>"  href="<?php echo base_url('index.php/moventreproy')?>">Informe Movimientos entre Proyecto</a>
					    <a class="dropdown-item <?php mmenu('3.11')?>" href="<?php echo base_url('index.php/informespresta')?>">Informe Prestamistas</a>
					    <a class="dropdown-item <?php mmenu('3.10')?>" href="<?php echo base_url('index.php/informespresu')?>">Informe Presupuestos</a>
					</div>
				  </li>

				  <li class="nav-item dropdown">
					<a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-expanded="false">Caja y Bancos</a>
					<div class="dropdown-menu" aria-labelledby="navbarDropdown">
					    <a class="dropdown-item <?php mmenu('4.1')?>" href="<?php echo base_url('index.php/cuentasbancarias')?>">Cuentas Bancarias</a>
					    <a class="dropdown-item <?php mmenu('4.2')?>" href="<?php echo base_url('index.php/chequeras')?>">Chequeras</a>
					    <a class="dropdown-item <?php mmenu('4.7')?>" href="<?php echo base_url('index.php/movbancarios')?>">Movimientos Bancarios</a>
					    <a class="dropdown-item <?php mmenu('4.5')?>" href="<?php echo base_url('index.php/cotizaciones')?>">Cotizaciones de Divisas</a>
					    <a class="dropdown-item <?php mmenu('4.3')?>" href="<?php echo base_url('index.php/informescaja')?>">Informes Caja</a>
					    <a class="dropdown-item <?php mmenu('4.4')?>" href="<?php echo base_url('index.php/informeschq')?>">Informes de Cheques</a>
					    <a class="dropdown-item <?php mmenu('4.8')?>" href="<?php echo base_url('index.php/informesreten')?>">Informes de Retenciones</a>
					</div>
				  </li>

				  <li class="nav-item dropdown">
					<a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-expanded="false">Usuarios</a>
					<div class="dropdown-menu" aria-labelledby="navbarDropdown">
					    <a class="dropdown-item <?php mmenu('5.1')?>" href="<?php echo base_url('index.php/usuarios')?>" >Usuarios</a>
<!--					    <a class="dropdown-item <?php mmenu('5.2')?>" href="<?php echo base_url('index.php/materiales')?>" >Materiales</a> -->
					</div>
				  </li>

				</ul>
				<?php if (!is_numeric($this->session->userdata('id_proyecto_activo'))){ ?>
				<form class="form-inline my-2 my-lg-0" action="<?=base_url('index.php/Proyectos/cambiarProyecto')?>" method="post">
					<select id="sel-proyecto"class="form-control" name="id_proyecto">
					</select>
					<input type="hidden" name="url_actual" value="<?=current_url();?>">
					<button class="btn btn-light my-2 my-sm-0 ml-2" type="submit">Aplicar</button>
				</form>
				<?php }else { ?>
				<form class="form-inline my-2 my-lg-0" action="<?=base_url('index.php/Proyectos/cambiarProyecto')?>" method="post">
					<span class="titulo-proyecto">Proyecto activo:<strong> <?=$this->session->userdata('nombre_proyecto_activo');?> </strong></span> 
					<input type="hidden" name="sel-proyecto" value="">
					<input type="hidden" name="url_actual" value="<?=current_url();?>">
					<button class="btn btn-light my-2 my-sm-0 ml-2" type="submit">Dejar Proyecto</button>
				</form>
				<?php } ?>
			</div>
		</nav>
	</div>
</div>
<?php } ?>



