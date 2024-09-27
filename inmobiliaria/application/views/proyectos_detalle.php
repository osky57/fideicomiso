<table
	    id="<?=$idtabla;?>_detalle"
	    class="<?=$idtabla;?>_detalle table table-bordered table-hover"
	    data-toggle="table"
	    data-height="500"
	    data-pagination="true"
	    data-side-pagination="server"
	    data-remember-order="true"
	    data-search="true"
	    data-page-list="[10, 25, 50, All]"
		data-url="<?=$urlDetalle;?>Ajax?id_maestro=<?=$id_maestro;?>"


	    <thead>
	    <tr>		
		    <th data-field="ptp_id">Id</th>
			<th data-field="tp_descripcion">Descripción</th>
			<th data-field="ptp_cantidad">Cantidad</th>
			<th data-field="ptp_comentario">Comentario</th>
	    </tr>
		
	    </thead>
		<tbody>
		
		<?php foreach ($detalle as $item){ ?>
			<tr>
			<td><?=$item['ptp_id'];?></td>
			<td><?=$item['tp_descripcion'];?></td>
			<td><?=$item['ptp_cantidad'];?></td>
			<td><?=$item['ptp_comentario'];?></td>
			</tr>
		<?php } ?>
		
		</tbody>
	</table>