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
	
<div class="main">
<!-- fin header -->

    <h5><b><?php echo $titulo ?></b></h5>

    <div style='padding-top:10px;padding-bottom:10px;'>
	<div class="row">
	    <div class="col-md-8">
		<div class="row">
		    <div class="col-md-12 btn btn-success">
			    Filtrar desde: <input type="date" name="frm_fdesde" id="frm_fdesde" value="<?=$fDesde;?>" >
			    Filtrar hasta:         <input type="date" name="frm_fhasta" id="frm_fhasta" value="<?=$fHasta;?>" >
		    </div>
		</div>
	    </div>
	    <div class="col-md-2">
		<button type="button" class="btn btn-primary" id="buscar">Buscar</button>
	    </div>
	    <div class="col-md-2">

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
	    data-show-columns="false"
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

<div  id="totales">
    <table class="table table-condensed table-bordered" id="tablatot">
	<thead>
	    <tr>
		<td><b>Id</b></td>
		<td><b>Proyecto Acreedor</b></td>
		<td><b>Id</b></td>
		<td><b>Proyecto Deudor</b></td>
		<td><b>Saldo $</b></td>
		<td><b>Saldo U$S</b></td>
	    </tr>
	</thead>
	<tbody  id="tbodytotales">
	</tbody>
    </table>

</div>


<script>

var idProy      = '<?=$idProyecto;?>';

$(document).ready(function() {

    $( "#buscar" ).click(function() {
	fdesde = $("#frm_fdesde").val();
	fhasta = $("#frm_fhasta").val();
	$('#table').bootstrapTable("refresh", {
	    url: "<?php echo $urlrecupag ?>",
	    query: { fDesde: fdesde, fHasta: fhasta }
	});
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
	elId = dato.currentTarget.cells[0].innerText;
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


    $('#table').on('load-success.bs.table', function (e) {
	aTotalMN   = 0;
	aTotalUS   = 0;
	xx         = '';
	celda      = ''; 
	aTotalProy = new Array();
	$('.tbodyalt').find("tr").each(function() {
	    proyAcr = $(this).find("td:eq(1)").html();
	    proyDeu = $(this).find("td:eq(8)").html();
	    if (proyAcr != undefined){ 
		$(this).find("td:eq(10)").each(function(){
		    celda = $(this).html();  
		    xx    = celda.replace('.','');
		    xx    = xx.replace(',','.');
		    aTotalMN += Number(xx);
		});
		$(this).find("td:eq(11)").each(function(){
		    celda = $(this).html();  
		    xx    = celda.replace('.','');
		    xx    = xx.replace(',','.');
		    aTotalUS += Number(xx);
		});

		laKey = proyDeu.padStart(3, '0') +  proyAcr.padStart(3, '0');
		unReg = [   proyDeu, 
			    $(this).find("td:eq(2)").html(),
			    proyAcr,
			    $(this).find("td:eq(9)").html(),
			    0,
			    0];

		if (idProy == proyAcr){
		    laKey = proyAcr.padStart(3, '0') +  proyDeu.padStart(3, '0');
		    unReg = [   proyAcr, 
				$(this).find("td:eq(9)").html(),
				proyDeu,
				$(this).find("td:eq(2)").html(),
				0,
				0];
		}
		if (aTotalProy.indexOf(laKey) == -1){
		    aTotalProy[laKey] = unReg;
		}
		aTotalProy[laKey][4]+=aTotalMN;
		aTotalProy[laKey][5]+=aTotalUS;
	    }
	});

	var element = document.getElementById("tbodytotales");
	while (element.firstChild) {
	    element.removeChild(element.firstChild);
	}
	for (var clave in aTotalProy){
	    var nuevafila= "<tr><td>" +
		    aTotalProy[clave][2] + "</td><td>" +
		    aTotalProy[clave][3] + "</td><td>" +
		    aTotalProy[clave][0] + "</td><td>" +
		    aTotalProy[clave][1] + "</td><td>" +
		    new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(aTotalProy[clave][4]) + "</td><td>" +
		    new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(aTotalProy[clave][5]) + "</td></tr>"
	    $("#tablatot").append(nuevafila)
	}
    });
})



</script>
<!-- footer -->
</div>
</div>
<?php $this->load->view('footer');?>
<!-- fin footer -->
