/* esta funcion muestra notificaciones en la barra de tareas
@mensaje: Mensaje a mostrar o accion a ejecutar. Accion permitida: hide
@tipo: tipo de mensaje a monstrar info, success, danger, warning
@icon: icono a mostrar en el mensaje. Ejemplo check-circle. Consultar en fontawesome para iconos disponibles https://fontawesome.com/v4/icons/
@autohide: Si esta en true el mensaje se oculta solo luego de 4 segundos. por defecto esta en false y debe ser ocultado por el usuario

*/
function notificar(mensaje,tipo='',icon='',autohide=false){
	
	/*acciones*/
	
	if (mensaje=='hide'){
		/* oculto el mensaje activo */
		$( "#message_box" ).delay(4000).animate({height: "0px"}, 100).html('');
		return true;
	}
	
	/* fin de acciones */
	
	 $("#message_box").html(''); // Elimino mensaje anterior
	 
	var fa='';
	
	if (icon !=''){
		fa='<i class="fa fa-'+icon+'" aria-hidden="true"></i> ';
	}
	
    var html = '<div class="alert alert-' + tipo + ' alert-dismissable page-alert">';    
    html += '<button type="button" class="close"><span aria-hidden="true">×</span><span class="sr-only">Close</span></button>';
    html += fa + mensaje;
    html += '</div>';    
    $("#message_box").html(html);
	
	$( "#message_box" ).css("height",0);
	$( "#message_box" ).animate({height: "55px"}, 200);
	
	if(autohide){
		$( "#message_box" ).delay(4000).animate({height: "0px"}, 100);
	}
	
	return true;
}