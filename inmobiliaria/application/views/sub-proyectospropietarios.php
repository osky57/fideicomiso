
<form action="<?php echo base_url('index.php/proyectostipospropiedades/guardaProyPropie')?>" method="POST"   data-validation="valida_proy_prop">
    <div class="table-responsive">
	<input type="hidden" id="elid" name="elid" value="<?=$elid;?>">
	<div class="table-wrapper-scroll-y my-custom-scrollbar">
	<table id="myTablaCaja" class="table table-bordered">
	    <thead>
		<tr>
		<td>Id</td>
		<td>Entidad</td>
		<td>Coeficiente</td>
		</tr>
	    </thead>
	    <tbody>
		<?php foreach($entidades as $item){?>
		    <tr>
			<td class="col-sm-4"><?=$item['e_id'];?></td>
			<td class="col-sm-4"><?=$item['razon_social'];?></td>
			<td class="col-sm-4"><input type="number" name="indice_<?=$item['e_id'];?>" id="indice_<?=$item['e_id'];?>"  value= <?=$item['dptp_coeficiente'];?> class="form-control laTd"/></td>
		    </tr>
		<?php } ?>
	    </tbody>
	    <tfoot>
	    </tfoot>
	</table>
	</div>
    </div>
</form>

<script>
function valida_proy_prop(){
    console.log('valida proy_prop');
    var totalCoe = 0;
    var ultObj;
    var breakP = false;
    $(".laTd").each(function(){
	if ($(this).val() > 100){
	    alert("Ningún coeficiente debe superar 100");
	    $(this).focus();
	    $(this).select();
	    breakP = true;
	    return false;
	}
	totalCoe += Number($(this).val());
	ultObj = $(this);
    })
    if (!breakP){
	if (totalCoe > 100){
	    alert("La suma de los coeficientes no debe superar 100 (" +totalCoe+")" );
	    $(ultObj).focus();
	    $(ultObj).select();
	}else{
	    return true;
	}
    }
}
</script>





