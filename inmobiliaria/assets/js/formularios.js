var frmModal;
var Modal;
var id_Modal; // id del modal activo
var anteModal = 0;
function abrirFormulario(src_view='',titulo='Formulario'){
	
	/*
	src_data=url de donde obtener los datos para llenar el formulario DEPRECADO
	src_view=url de donde obtener el html para rellenar el modal
	*/

	if (anteModal > 0){
	    console.log("anteModal " + anteModal);
	    $('div.modal').empty();
	}
	
	var id_modal=Math.round(Math.random()*10000);
	var class_titulo=titulo.replace(/\s+/g, '-').toLowerCase();
	var html=`<div class="modal" tabindex="-1">
		<div class="modal-dialog ${class_titulo}">
			<div class="modal-content">
				<div class="modal-header">
					<h5 class="modal-title">${titulo}</h5>
					<button type="button" class="close" data-dismiss="modal" aria-label="Close">
					<span aria-hidden="true">&times;</span>
					</button>
				</div>
				<div id="modal_body_${id_modal}" class="modal-body">
				<i class="fa fa-spinner fa-spin fa-2x fa-fw"></i>
				<span class="sr-only">Loading...</span>
				</div>
				<div class="modal-footer">
					<button type="button" class="btn btn-secondary" data-dismiss="modal" onclick="cierremodal('${id_modal}')">Cerrar</button>
					<button id="guardar" type="button" class="btn btn-primary" onclick="submitAjaxModal('${id_modal}')">Guardar</button>
				</div>
			</div>
		</div>
	</div>`;
	
	frmModal=$(html);
	Modal=$('#modal_body_'+id_modal); // instancia jquery del modal
	id_Modal=id_modal; 
	
	frmModal.modal();
	
	if (src_view != ''){
		
		$('#modal_body_'+id_modal).load(src_view);
	}
	
	// cuando se oculta el modal lo destruyo con un null
	Modal.on('hidden', function(){
		$(this).data('modal', null);
	});

}

/* para las notificaciones 

https://bootsnipp.com/snippets/6ax7
*/


function cierremodal(id_modal){
    anteModal = id_modal;
}


function submitAjaxModal(id_modal){
	
	 if(!confirm('¿Desea guardar la información?')){
		 return false;
	 }

	cierremodal(id_modal);

//	$('#guardar').attr('disabled','disabled'); // desactivo el boton de guardar para el usuario 
	var form=$('#modal_body_'+id_modal+' form');
	
	// recupero parametros del formulario
	var action= form.attr('action');
	var method= form.attr('method');
	var validation=form.data('validation');
	// recupero datos del formulario
	var data =  form.serializeArray() ;
	
	if (validation !=''){
		var r= executeFunctionByName(validation);
		if(!r){
			return false;
		}
	}
	//cambio lugar de desactivar boton guardar para q lo deje activado si vuelvo al formulario por un error orc
	$('#guardar').attr('disabled','disabled'); // desactivo el boton de guardar para el usuario 

	
	notificar("Guardando información","info","spinner fa-spin");
	
	// envio ajax
	$.ajax({
		'type': method,
		'url':action,
		'data':data		
	}).done(function( data ) {
		
		 $('#guardar').removeAttr('disabled');
		 
		 notificar("Guardado con éxito","info","fa-check-circle",true);
		 
		 frmModal.modal('hide');
		 $('body').find('table').bootstrapTable('refresh');
		 
		//data=$.parseJSON(data);

	});
	
	console.log(id_modal);
}



// para los detalles del maestro
function detailFormatter(index, row) {
    
	console.log(index);
	
	console.log(row);
	
	var url=$('.proyectos#table').data('detail-url');
	
	var id=Object.values(row)[0]; // como el valor de la primera columna como id de maestro
	
	url=url + '?id_maestro=' + id;
	
	//$('#detalle-'+row.p_id).load(url);
	
    return $.ajax({
        type: "GET",
        url: url,
        cache: false,
        async: false
    }).responseText;
  }
  
 

  /*
  function getURL(url){
    return $.ajax({
        type: "GET",
        url: url,
        cache: false,
        async: false
    }).responseText;
}


//example use
var msg=getURL("message.php");
alert(msg);
  */