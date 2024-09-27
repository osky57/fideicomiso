function executeFunctionByName( functionName, context /*, args */ ) {
    var args, namespaces, func;

    if( typeof functionName === 'undefined' ) { throw 'function name not specified'; }

    if( typeof eval( functionName ) !== 'function' ) { throw functionName + ' is not a function'; }

    if( typeof context !== 'undefined' ) { 
        if( typeof context === 'object' && context instanceof Array === false ) { 
            if( typeof context[ functionName ] !== 'function' ) {
                throw context + '.' + functionName + ' is not a function';
            }
            args = Array.prototype.slice.call( arguments, 2 );

        } else {
            args = Array.prototype.slice.call( arguments, 1 );
            context = window;
        }

    } else {
        context = window;
    }

    namespaces = functionName.split( "." );
    func = namespaces.pop();

    for( var i = 0; i < namespaces.length; i++ ) {
        context = context[ namespaces[ i ] ];
    }

    return context[ func ].apply( context, args );
}





///////////////////////////////////////////////////////////////////////////////
function formNume(nX){
	nDHt = nX*100/100;
	nDHt = (nDHt == 0) ? '' : nDHt.toLocaleString("es-ES");
	return nDHt;
}



//////////////////////////////////////////////////////////////////////////////
function armaConsuComprob(json){

	jsonC = json['comprob'];
	jsonP = json['pagos'];
	jsonA = json['aplicaciones'];

//	jsonC['totalmn']  =  jsonC['totalmn']  === undefined ? '' : new Intl.NumberFormat('de-DE').format(jsonC['totalmn'].replaceAll(',',''));
//	jsonC['totaldiv'] =  jsonC['totaldiv'] === undefined ? '' : new Intl.NumberFormat('de-DE').format(jsonC['totaldiv'].replaceAll(',',''));

	jsonC['totalmn']  =  new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(jsonC['totalmn']/1);
	jsonC['totaldiv'] =  new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(jsonC['totaldiv']/1);

	sinApli = jsonC['saldocomprob'];
	sinApli = sinApli.replace('(','');
	sinApli = sinApli.replace(')','');
	sinApliPesDol = sinApli.split(',');

debugger;

	for (let ii=0; ii < sinApliPesDol.length; ii++){
		sinApliPesDol[ii] = new Intl.NumberFormat('es-EE',{ minimumFractionDigits: 2 }).format(sinApliPesDol[ii]);
	}

//	xR1     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(jsonC['totalmn']);
//	xR2     = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(jsonC['totaldiv']);

	xR1     = jsonC['totalmn'];
	xR2     = jsonC['totaldiv'];

	$("#dialogMsg1").text("Entidad: "+jsonC['e_razon_social']+" ("+jsonC['cc_entidad_id']+") - Celular: "+jsonC['e_celular']+" -- Comentario: "+jsonC['ccc_comentario']);
	$("#dialogMsg2").text("Importe: $ "+xR1+" - U$S "+xR2+"   |  Sin aplicar: $ "+ sinApliPesDol[0]+" - U$S: "+ sinApliPesDol[1]  );
	$("#dialogMsg2").css({"background-color": "yellow", "font-size": "120%"});

	$("#dialog").dialog("option", "title", "Id: "+jsonC['cc_id']+" - Comprobante: "+jsonC['tc_num']+" - Fecha: "+jsonC['cc_fecha_dmy']);
	lF     = 0;
	lasA   = ""
	nTotMN = 0;
	nTotUS = 0;
	jsonA.forEach((unaA) => {
		if (lF == 0){
		    lasA  = "<b>Aplicaciones</b><br><table class='table table-sm'>";   // <caption>Aplicaciones</caption>"
		    lasA += "<thead><tr>";
		    lasA += "<th class='text-right'>Id</th>";
		    lasA += "<th class='text-right'>Fecha</th>";
		    lasA += "<th class='text-right'>Comprobante</th>";
		    lasA += "<th class='text-right'>Comentario</th>";
		    lasA += "<th class='text-right'>Importe $</th>";
		    lasA += "<th class='text-right'>Importe U$S</th>";
		    lasA += "</tr></thead><tbody>";
		    lF   = 1;
		}
		lasA += "<tr>"
		lasA += "<td>"+unaA.id+"</td>";
		lasA += "<td>"+unaA.fecha_dmy+"</td>";
		lasA += "<td>"+unaA.comp_nume+"</td>";
		lasA += "<td>"+unaA.comentario+"</td>";
		lasA += "<td>"+new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(unaA.rcc_monto_pesos)+"</td>";
		lasA += "<td>"+new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(unaA.rcc_monto_divisa)+"</td>";
		lasA += "</tr>"
//		nTotMN += Number(unaA.rcc_monto_pesos);
//		nTotUS += Number(unaA.rcc_monto_divisa);
		nTotMN += unaA.rcc_monto_pesos;
		nTotUS += unaA.rcc_monto_divisa;
	});
	if (lF == 1){
		lasA += "<tr>"
		lasA += "<td></td>";
		lasA += "<td></td>";
		lasA += "<td></td>";
		lasA += "<td><b>TOTAL</b></td>";
		lasA += "<td><b>"+new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(nTotMN)+"</b></td>";
		lasA += "<td><b>"+new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(nTotUS)+"</b></td>";
		lasA += "</tr>"
		lasA += "</tbody></table>"
	}
	$("#tablaApl").html(lasA);
	    lF     = 0;
	    lasA   = ""
	    nTotMN = 0;
	    nTotUS = 0;
	    jsonP.forEach((unP) => {
		if (lF == 0){
		    lasA  = "<b>Caja</b><br><table class='table table-sm'>";   // <caption>Aplicaciones</caption>"
		    lasA += "<thead><tr>";
		    lasA += "<th class='text-right'>Id</th>";
		    lasA += "<th class='text-right'>Tipo</th>";
		    lasA += "<th class='text-right'>Comentario</th>";
		    lasA += "<th class='text-right'>Banco - Chq.Nro.</th>";
		    lasA += "<th class='text-right'>Fecha Emi.</th>";
		    lasA += "<th class='text-right'>Fecha Acr.</th>";
		    lasA += "<th class='text-right'>Importe $</th>";
		    lasA += "<th class='text-right'>Importe U$S</th>";
		    lasA += "</tr></thead><tbody>";
		    lF   = 1;
		}
		if (unP.cb_denominacion == null){
		    banco = unP.banco;    //ba2_denominacion;
		}else{
		    banco = unP.cb_denominacion;
		}
		if (unP.serienro == null){
		    chq = "";
		}else{
		    chq = unP.serienro;
		}
		lasA += "<tr>"
		lasA += "<td>"+unP.ccc_id+"</td>";
		lasA += "<td>"+(unP.tmc_descripcion   == null?"":unP.tmc_descripcion)+"</td>";
		lasA += "<td>"+(unP.ccc_comentario    == null?"":unP.ccc_comentario)+"</td>";
		lasA += "<td>"+(banco == null?"":banco+" "+chq)+"</td>";

		lasA += "<td>"+(unP.f_emision         == null?"":unP.f_emision)+"</td>";
		lasA += "<td>"+(unP.f_acreditacion    == null?"":unP.f_acreditacion)+"</td>";

		xImporte = new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(unP.ccc_importe.replaceAll(',',''));
		nImporte = unP.ccc_importe.replaceAll(',','');
		lasA += "<td>"+(unP.mo1_simbolo == "$"?xImporte:"")+"</td>";
		lasA += "<td>"+(unP.mo1_simbolo != "$"?xImporte:"")+"</td>";
		lasA += "</tr>"
		nTotMN += unP.mo1_simbolo == "$"? Number(nImporte):0;
		nTotUS += unP.mo1_simbolo != "$"? Number(nImporte):0;

	    });
	    if (lF == 1){
		lasA += "<tr>"
		lasA += "<td></td>";
		lasA += "<td></td>";
		lasA += "<td></td>";
		lasA += "<td></td>";
		lasA += "<td></td>";
		lasA += "<td><b>TOTAL</b></td>";
		lasA += "<td><b>"+ new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(nTotMN)+"</b></td>";
		lasA += "<td><b>"+ new Intl.NumberFormat('es-ES',{ minimumFractionDigits: 2 }).format(nTotUS)+"</b></td>";
		lasA += "</tr>"
		lasA += "</tbody></table>"
	    }

	    return lasA;
}

///////////////////////////////////////////////////////////////////////////////////
function str2num(xx){
	if (typeof(xx) == 'number'){
	    xx = xx * 1.00;
	    xx = xx.toLocaleString("en-US");
	}
	if (typeof(xx) == 'string'){
	    if (xx == ''){
		xx = 0;
	    }
	    xx = xx.toString().replaceAll('.','');
	    xx = xx.toString().replaceAll(',','.');
	    xx = xx/1;
	}
	return xx;
}
