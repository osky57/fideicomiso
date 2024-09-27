$(document).ready(function(){
	
	$.getJSON( "/index.php/Proyectos/recuperaPagina", function( data ) {
		
		var items = [];
		
		items.push( '<option value="">Seleccione Proyecto</option>' );
		
		$.each( data.rows, function( key, val ) {
			
			console.log(key+':'+val);
			items.push( '<option value="' + val.p_id + '">' + val.p_nombre + '</option>' );
		});
		
		$('#sel-proyecto').html(items.join( "\n" ));
	});
});