<!doctype html>
<html lang="en">

<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
	<title>Orden de Pago</title>
	<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">
	<style>
		head {
			font-family: Arial, sans-serif;
		}
		body {
			font-family: Arial, sans-serif;
		}
		table {			
table-layout: fixed;
  width: 100%;
  
}
table, td {
        border: solid 1px black;
        border-collapse: collapse;
    }
table, th, td {
  border: 1px solid black;
}
</style>
</head>

<body>
  <div class="container mt-5">
	
	
	<table style="border-collapse: collapse;border: none;">	

	<tr style="border-collapse: collapse;border: none;">
	<td style="text-align:left;border-collapse: collapse;border: none;">
	<h2>
	<?php echo $comprob["tc_num"];?>
	</h2>	
	</td>
	<td style="text-align:right;border-collapse: collapse;border: none;">
	<h2>
	<?php echo $comprob["cc_fecha_dmy"];?>
	</h2>
	</td>	
	</tr>
	</table>
	
	<div>
	
	Proveedor:<?php echo $comprob["e_razon_social"];?>
	</div>
	<div>
	Concepto:
	</div>
	<br>
	<div>
	VENCIMIENTOS CANCELADOS:
<table>	

<tr>
	<th>
		Detalle
	</th>	
	<th> 
		Comprobante 
	</th>
	<th>
		Fecha
	</th>
	<th>
		Importe Pesos
	</th>
	<th>
		Importe Dólares
	</th>
</tr>
<?php foreach ($aplicaciones as $a){?>
<tr>
	<td style="font-size:10;"><?php echo $a["comentario"];?></td>
    
    <td style="font-size:10;"><?php echo $a["comp_nume"];?></td>
	<td style="font-size:10;text-align:center"><?php echo $a["fecha"];?></td>
	<?php if ($a["rcc_monto_divisa"]=="0.00"){?>
		<td style="font-size:10;text-align:right"><?php 	
	
		echo number_format($a["rcc_monto_pesos"], 2, ',', '.');
		
		?></td>
		<td>
		</td>
		<?php
	}
	else{	?>	
		<td>
		</td>
		<td style="font-size:10;text-align:right"><?php 	
		
		echo number_format($a["rcc_monto_divisa"], 2, ',', '.');
		
		?></td><?php
	}?>
</tr>
<?php } ?>
<tr>
<td>TOTALES</td>
<td></td>
<td></td>
<td style="text-align:right"><?php echo number_format($comprob["totalmn"], 2, ',', '.');?></td>
<td style="text-align:right"><?php echo number_format($comprob["totaldiv"], 2, ',', '.');?></td>
</tr>
</table>
</div>
<br></br>
<div>
PAGOS:
<table>	

<tr style="font-size:10;">
	<th>
		Descripción
	</th>
	<th>
		Cta. Bancaria
	</th>
	<th> 
		Banco 
	</th>
	<th> 
		Serie Nro.
	</th>
	<th> 
		Fecha emisión 
	</th>
	<th>
		Fecha acreditación
	</th>
	<th>
		Importe Pesos
	</th>
	<th>
		Importe Dólares
	</th>
</tr>
<?php foreach ($pagos as $p){?>
<tr>
	<td style="font-size:10;"><?php echo $p["tmc_descripcion"];?></td>    
    <td style="font-size:10;"><?php echo $p["banco"];?></td>
	<td style="font-size:10;"><?php echo $p["serienro"];?></td>
	<td style="font-size:10;text-align:center"><?php echo $p["f_emision"];?></td>
	<td style="font-size:10;text-align:center"><?php echo $p["f_acreditacion"];?></td>
	<?php if ($p["mo1_denominacion"]=="Peso"){?>
		<td style="font-size:10;text-align:right"><?php 	
	
		echo number_format($p["ccc_importe"], 2, ',', '.');
		
		?></td>
		<td>
		</td>
		<?php
	}
	else{	?>	
		<td>
		</td>
		<td style="font-size:10;text-align:right"><?php 	
		
		echo number_format($p["ccc_importe"], 2, ',', '.');
		
		?></td><?php
	}?>
</tr>
<?php } ?>
<tr>
<td>TOTALES</td>
<td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td style="text-align:right"><?php echo number_format($comprob["totalmn"], 2, ',', '.');?></td>
<td style="text-align:right"><?php echo number_format($comprob["totaldiv"], 2, ',', '.');?></td>
</tr>
</table>
</div>



<!--


{"comprob":{"cc_id":"682","tc_num":"ORD.PAGO.PROVEEDOR Nro.167","cc_fecha_dmy":"02-04-2024","cc_entidad_id":"62","e_razon_social":"Aceros Dahir","e_celular":"","local_prov":"BAHIA BLANCA Buenos Aires","e_observaciones":"","p_nombre":null,"debe_txt_mn_tot":"       21,000.00","cc_importe":null,"cc_moneda_id":null,"cc_importe_divisa":"0.00","u_nombre":"Oscar  Ru","cc_fecha_registro":"2024-04-02 16:06:04.393065","ptp_comentario":null,"ptp_coeficiente":null,"tp_descripcion":null,"ccc_comentario":"  -   ","tc_modelo":"5","haber_txt_mn_tot":null,"debe_txt_div_tot":null,"haber_txt_div_tot":null,"totalmnx":"          21,000.00","totaldivx":"                .00","totalmn":"21000.00","totaldiv":"0.00","sinaplicar":"(0.00,0.00)","saldocomprob":"(0.00,0.00)"},"pagos":[{"ccc_importex":"          10,000.00","ccc_importe":"10000.00","ccc_importe_divisa":"484.00","mo1_denominacion":"Peso","mo1_simbolo":"$","tmc_descripcion":"Pago por banco","ccc_comentario":"","ccc_id":"532","ba2_denominacion":null,"ccc_f_emi_dmy":null,"ccc_f_acre_dmy":"02-04-2024","serienrox":null,"cb_denominacion":"Fideicomiso Rhodas","banco":null,"serienro":null,"f_emision":null,"f_acreditacion":"02-04-2024"},{"ccc_importex":"          11,000.00","ccc_importe":"11000.00","ccc_importe_divisa":"484.00","mo1_denominacion":"Peso","mo1_simbolo":"$","tmc_descripcion":"Efectivo","ccc_comentario":"","ccc_id":"531","ba2_denominacion":null,"ccc_f_emi_dmy":null,"ccc_f_acre_dmy":"02-04-2024","serienrox":null,"cb_denominacion":null,"banco":null,"serienro":null,"f_emision":null,"f_acreditacion":"02-04-2024"}],"modelo":"5","aplicaciones":[{"comentario":"Fideicomiso Rhodas ","fecha":"28-02-2024","fecha_dmy":"28-02-2024","id":"599","comp_nume":"FACT.PROVEEDOR Nro.a 123 123","rcc_monto_divisa":"0.00","rcc_monto_pesos":"1000.00"},{"comentario":"Fideicomiso Rhodas ","fecha":"28-02-2024","fecha_dmy":"28-02-2024","id":"606","comp_nume":"FACT.PROVEEDOR Nro.a 1 1","rcc_monto_divisa":"0.00","rcc_monto_pesos":"2000.00"},{"comentario":"Fideicomiso Rhodas ","fecha":"28-02-2024","fecha_dmy":"28-02-2024","id":"608","comp_nume":"FACT.PROVEEDOR Nro.a 1 3","rcc_monto_divisa":"0.00","rcc_monto_pesos":"3000.00"},{"comentario":"Fideicomiso Rhodas ","fecha":"28-02-2024","fecha_dmy":"28-02-2024","id":"609","comp_nume":"FACT.PROVEEDOR Nro.a 1 4","rcc_monto_divisa":"0.00","rcc_monto_pesos":"4000.00"},{"comentario":"Fideicomiso Rhodas ","fecha":"28-02-2024","fecha_dmy":"28-02-2024","id":"610","comp_nume":"FACT.PROVEEDOR Nro.a 1 6","rcc_monto_divisa":"0.00","rcc_monto_pesos":"5000.00"},{"comentario":"Fideicomiso Rhodas ","fecha":"28-02-2024","fecha_dmy":"28-02-2024","id":"611","comp_nume":"FACT.PROVEEDOR Nro.a 1 7","rcc_monto_divisa":"0.00","rcc_monto_pesos":"6000.00"}]}
{"comprob":{"cc_id":"680","tc_num":"ORD.PAGO.PROVEEDOR Nro.166","cc_fecha_dmy":"27-03-2024","cc_entidad_id":"62","e_razon_social":"Aceros Dahir","e_celular":"","local_prov":"BAHIA BLANCA Buenos Aires","e_observaciones":"","p_nombre":null,"debe_txt_mn_tot":"        1,500.00","cc_importe":null,"cc_moneda_id":null,"cc_importe_divisa":"0.00","u_nombre":"Oscar  Ru","cc_fecha_registro":"2024-03-27 10:21:54.684189","ptp_comentario":null,"ptp_coeficiente":null,"tp_descripcion":null,"ccc_comentario":"  -   observaciones general","tc_modelo":"5","haber_txt_mn_tot":null,"debe_txt_div_tot":null,"haber_txt_div_tot":null,"totalmnx":"           1,500.00","totaldivx":"                .00","totalmn":"1500.00","totaldiv":"0.00","sinaplicar":"(0.00,0.00)","saldocomprob":"(0.00,0.00)"},"pagos":[{"ccc_importex":"           1,500.00","ccc_importe":"1500.00","ccc_importe_divisa":"484.00","mo1_denominacion":"Peso","mo1_simbolo":"$","tmc_descripcion":"Efectivo","ccc_comentario":"pliplipli","ccc_id":"529","ba2_denominacion":null,"ccc_f_emi_dmy":null,"ccc_f_acre_dmy":"27-03-2024","serienrox":null,"cb_denominacion":null,"banco":null,"serienro":null,"f_emision":null,"f_acreditacion":"27-03-2024"}],"modelo":"5","aplicaciones":[{"comentario":"Fideicomiso Rhodas ","fecha":"28-02-2024","fecha_dmy":"28-02-2024","id":"599","comp_nume":"FACT.PROVEEDOR Nro.a 123 123","rcc_monto_divisa":"0.00","rcc_monto_pesos":"1500.00"}]}


-->

<br>
ORIGINAL
<br>
<div>
	FIRMA DEL QUE RECIBE:................................................																	
	<br>															
																	
	ACLARACION:....................................................... 
		</div>
</body>
</html>