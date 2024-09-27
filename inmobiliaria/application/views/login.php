<?php $this->load->view('header');?>
<div class="row" >
			
	<div class="col-md-4">
	</div>
	
	<div class="col-md-4">
	
		<div class="loginmodal-container">
					<h1>Fidetrust</h1>
					<p>Panel de Control</p><br>
					<?= $entrar_error; ?>
				  <form action="<?php echo base_url('/index.php/Usuario/entrar') ?>" method="post" role="form" >
					<input type="text" name="email" placeholder="Tu cuenta de email">
					<input type="password" name="password" placeholder="Contraseña">
					<input type="submit" name="login" class="login loginmodal-submit" value="Entrar">
				  </form>
					
					
				  
				</div>
				
	</div>
	
    <div class="col-md-4">
	</div>			

</div>
<?php $this->load->view('footer');?>