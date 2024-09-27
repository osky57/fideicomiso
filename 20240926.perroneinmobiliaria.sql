--
-- PostgreSQL database dump
--

-- Dumped from database version 13.3 (Ubuntu 13.3-1.pgdg18.04+1)
-- Dumped by pg_dump version 13.3 (Ubuntu 13.3-1.pgdg18.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fecha_baja_trigger(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.fecha_baja_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--	raise notice '***prueba % % % %', NEW.estado,NEW.id, OLD.fecha_baja,NEW.fecha_baja;
--	raise info '***prueba ....';
    IF NEW.estado = 1 THEN
	-- raise notice 'prueba % %', NEW.estado,NEW.id;
	NEW.fecha_baja := now();
--		raise notice 'prueba % % % %', NEW.estado,NEW.id, OLD.fecha_baja,NEW.fecha_baja;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fecha_baja_trigger() OWNER TO root;

--
-- Name: fun_aplicaacomprob(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fun_aplicaacomprob(integer, integer, integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$
DECLARE
    nId               ALIAS FOR $1;
    nIdMone           ALIAS FOR $2;
	nIdProyec         ALIAS FOR $3;
    nTotPesos         Numeric(16,2) := 0;
    nTotDolar         Numeric(16,2) := 0;
    nAplica           Numeric(16,2) := 0;
    cAplica           RECORD;
    cRecCaja          RECORD;
    cCC               RECORD;

BEGIN
	-- recupera los importes q la o/p aplica en un proyecto o en general
    SELECT importe,moneda_id,importe_divisa,signo,modelo INTO cCC
    FROM cuentas_corrientes cc
    JOIN tipos_comprobantes tc ON cc.tipo_comprobante_id = tc.id 
    WHERE cc.id = nId AND cc.estado = 0;

    IF (cCC.modelo IN ( 5, 4 )) THEN   -- o/p, rec

		IF nIdProyec > 0 THEN 

			FOR cAplica IN SELECT rcc.monto_pesos AS rcc_monto_pesos,rcc.monto_divisa AS rcc_monto_divisa ,rcc.importe_divisa AS rcc_importe_divisa
					FROM relacion_ctas_ctes rcc
					JOIN cuentas_corrientes cc  ON rcc.cuenta_corriente_id = cc.id
					WHERE rcc.relacion_id  = nId 
						AND rcc.estado = 0 
						AND cc.proyecto_id = nIdProyec 	LOOP

				IF cAplica.rcc_monto_pesos > 0 THEN 
					nTotPesos = nTotPesos + cAplica.rcc_monto_pesos;
				END IF;
				IF cAplica.rcc_monto_divisa > 0 THEN 
					nTotDolar = nTotDolar + cAplica.rcc_monto_divisa;
				END IF;
			END LOOP;

		ELSE
		
			FOR cAplica IN SELECT rcc.monto_pesos AS rcc_monto_pesos,rcc.monto_divisa AS rcc_monto_divisa ,rcc.importe_divisa AS rcc_importe_divisa
					FROM relacion_ctas_ctes rcc
					WHERE rcc.relacion_id  = nId 
						AND rcc.estado = 0 	LOOP

				IF cAplica.rcc_monto_pesos > 0 THEN 
					nTotPesos = nTotPesos + cAplica.rcc_monto_pesos;
				END IF;
				IF cAplica.rcc_monto_divisa > 0 THEN 
					nTotDolar = nTotDolar + cAplica.rcc_monto_divisa;
				END IF;
			END LOOP;

		END IF;
    END IF;

    IF nIdMone = 1 THEN 
		nAplica := nTotPesos;
    ELSE
		nAplica := nTotDolar;
    END IF;

    RETURN nAplica;
END
$_$;


ALTER FUNCTION public.fun_aplicaacomprob(integer, integer, integer) OWNER TO postgres;

--
-- Name: fun_buscartiposentidades(integer, character varying[]); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.fun_buscartiposentidades(id integer, lostipos character varying[]) RETURNS integer
    LANGUAGE plpgsql
    AS $_$

DECLARE
    nId ALIAS FOR $1;
    cTipos ALIAS FOR $2;    

    nTipo integer := 0;
    cDeno varchar(30) := '';
    cuantos integer = 0;
BEGIN
    -- ?| actua como or, ?& actua como and
    SELECT COUNT(*) INTO cuantos 
    FROM entidades e
    WHERE e.id = nId 
      AND (e.tipos_entidad->>'tipos_entidad'::text)::jsonb ?| cTipos  ;

    IF (cuantos IS NULL) THEN 
        cuantos := 0;
    END IF;

    RETURN cuantos;
END;
$_$;


ALTER FUNCTION public.fun_buscartiposentidades(id integer, lostipos character varying[]) OWNER TO root;

--
-- Name: fun_calcimportecaja(integer, integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.fun_calcimportecaja(integer, integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$

DECLARE
    nId     ALIAS FOR $1;
    nMoneda ALIAS FOR $2;
    nTotal  numeric(16,2) := 0;
    nImpo   numeric(16,2) := 0;
    nMone   numeric(16,2) := 0;

BEGIN

    SELECT importe, moneda_id INTO nImpo, nMone
    FROM cuentas_corrientes
    WHERE id = nId;
    IF (nImpo IS NULL) THEN 
	SELECT SUM(importe) INTO nTotal
	FROM cuentas_corrientes_caja 
	WHERE cuenta_corriente_id = nId
	  AND moneda_id = nMoneda;

	IF (nTotal IS NULL ) THEN 
	    nTotal := 0;
	END IF;

    ELSE
	IF (nMone = nMoneda) THEN
	    nTotal := nImpo;
	END IF;
    END IF;

    RETURN nTotal;

END;
$_$;


ALTER FUNCTION public.fun_calcimportecaja(integer, integer) OWNER TO root;

--
-- Name: fun_calcimportecomprob(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fun_calcimportecomprob(integer, integer, integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$DECLARE
    nId       ALIAS FOR $1;
    nMoneda   ALIAS FOR $2;
	nProyecto ALIAS FOR $3;
    nTotal  numeric(16,2) := 0;
    nImpo   numeric(16,2) := 0;
    nMone   numeric(16,2) := 0;
	
    nTotPesos         Numeric(16,2) := 0;
    nTotDolar         Numeric(16,2) := 0;
    nAplica           Numeric(16,2) := 0;
    cAplica           RECORD;
    cRecCaja          RECORD;
    cCC               RECORD;
	

BEGIN

    SELECT importe,moneda_id,importe_divisa,signo,modelo INTO cCC
	FROM cuentas_corrientes cc
	JOIN tipos_comprobantes tc ON cc.tipo_comprobante_id = tc.id 
	WHERE cc.id = nId AND cc.estado = 0;

    IF (cCC.importe IS NULL) THEN                 --si es null, es rec u o/p

		IF (cCC.modelo IN ( 5,4 )) THEN   -- verifica q sea 5o/p  4rec
			IF nProyecto > 0 THEN         -- si es 0 calcula sin importar el proy
				FOR cAplica IN SELECT rcc.monto_pesos AS rcc_monto_pesos,rcc.monto_divisa AS rcc_monto_divisa ,rcc.importe_divisa AS rcc_importe_divisa
					FROM relacion_ctas_ctes rcc
					JOIN cuentas_corrientes cc  ON rcc.cuenta_corriente_id = cc.id
					WHERE rcc.relacion_id  = nId 
					  AND rcc.estado = 0 
					  AND cc.proyecto_id = nProyecto 	LOOP

					IF cAplica.rcc_monto_pesos > 0 THEN 
						nTotPesos = nTotPesos + cAplica.rcc_monto_pesos;
					END IF;
					IF cAplica.rcc_monto_divisa > 0 THEN 
						nTotDolar = nTotDolar + cAplica.rcc_monto_divisa;
					END IF;
				END LOOP;
				
			END IF;
		ELSE

			FOR cAplica IN SELECT rcc.monto_pesos AS rcc_monto_pesos,rcc.monto_divisa AS rcc_monto_divisa ,rcc.importe_divisa AS rcc_importe_divisa
					FROM relacion_ctas_ctes rcc
					WHERE rcc.relacion_id  = nId 
						AND rcc.estado = 0 	LOOP

				IF cAplica.rcc_monto_pesos > 0 THEN 
					nTotPesos = nTotPesos + cAplica.rcc_monto_pesos;
				END IF;
				IF cAplica.rcc_monto_divisa > 0 THEN 
					nTotDolar = nTotDolar + cAplica.rcc_monto_divisa;
				END IF;
			END LOOP;

		END IF;

		IF nMoneda = 1 THEN 
			nTotal = nTotPesos;
		ELSE
			nTotal = nTotDolar;
		END IF;

	ELSE
		SELECT importe, moneda_id INTO nImpo, nMone
		FROM cuentas_corrientes
		WHERE id = nId;
		IF (nMone = nMoneda) THEN
			nTotal := nImpo;
		END IF;
	END IF;

    RETURN nTotal;

END

$_$;


ALTER FUNCTION public.fun_calcimportecomprob(integer, integer, integer) OWNER TO postgres;

--
-- Name: fun_calcimportecomprob_1(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fun_calcimportecomprob_1(integer, integer, integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$DECLARE
    nId       ALIAS FOR $1;
    nMoneda   ALIAS FOR $2;
	nProyecto ALIAS FOR $3;
    nTotal  numeric(14,2) := 0;
    nImpo   numeric(14,2) := 0;
    nMone   numeric(14,2) := 0;
	
    nTotPesos         Numeric(14,2) := 0;
    nTotDolar         Numeric(14,2) := 0;
    nAplica           Numeric(14,2) := 0;
    cAplica           RECORD;
    cRecCaja          RECORD;
    cCC               RECORD;

BEGIN

    SELECT importe,moneda_id,importe_divisa,signo,modelo INTO cCC
	FROM cuentas_corrientes cc
	JOIN tipos_comprobantes tc ON cc.tipo_comprobante_id = tc.id 
	WHERE cc.id = nId AND cc.estado = 0;

    IF (cCC.modelo IN ( 5,4 )) THEN   -- verifica q sea 5o/p  4rec
		IF nProyecto > 0 THEN         -- si es 0 calcula sin importar el proy

			SELECT SUM(xccc.importe) INTO nTotal
			FROM cuentas_corrientes_caja xccc
			LEFT JOIN cuentas_corrientes xcc ON xccc.cuenta_corriente_id = xcc.id
			WHERE xccc.cuenta_corriente_id = nId 
			  AND xccc.estado = 0 
			  AND xcc.proyecto_id = nProyecto
			  AND xccc.moneda_id  = nMoneda;

		ELSE
			SELECT SUM(xccc.importe) INTO nTotal
			FROM cuentas_corrientes_caja xccc
			LEFT JOIN cuentas_corrientes xcc ON xccc.cuenta_corriente_id = xcc.id
			WHERE xccc.cuenta_corriente_id = nId 
			  AND xccc.estado = 0 
			  AND xccc.moneda_id  = nMoneda;

		END IF;

	ELSE
		SELECT importe, moneda_id INTO nImpo, nMone
		FROM cuentas_corrientes
		WHERE id = nId;
		IF (nMone = nMoneda) THEN
			nTotal := nImpo;
		END IF;
	END IF;
	IF (nTotal IS NULL) THEN
		nTotal := 0;
	END IF;
    RETURN nTotal;

END

$_$;


ALTER FUNCTION public.fun_calcimportecomprob_1(integer, integer, integer) OWNER TO postgres;

--
-- Name: fun_chq_asignado(integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.fun_chq_asignado(integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$

DECLARE
    nId    ALIAS FOR $1;
    nRet   INTEGER := 0;

BEGIN
    /*function_body*/
    SELECT id INTO nRet
    FROM cuentas_corrientes_caja
    WHERE cta_cte_caja_origen_id = nId
	  AND estado = 0;
    
    IF (nRet IS NULL) THEN 
        nRet := 0;
    END IF;
    RETURN nRet;
END;
$_$;


ALTER FUNCTION public.fun_chq_asignado(integer) OWNER TO root;

--
-- Name: fun_comprobaplicado(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fun_comprobaplicado(integer) RETURNS record
    LANGUAGE plpgsql
    AS $_$
DECLARE
    nId               ALIAS FOR $1;
    nTotPesos         Numeric(16,2) := 0;
    nTotDolar         Numeric(16,2) := 0;
    nAplica           RECORD;
    cAplica           RECORD;
    cRecCaja          RECORD;
    cCC               RECORD;

BEGIN

    SELECT importe,moneda_id,importe_divisa,signo INTO cCC
    FROM cuentas_corrientes cc
    JOIN tipos_comprobantes tc ON cc.tipo_comprobante_id = tc.id 
    WHERE cc.id = nId AND cc.estado = 0;

    IF (cCC.signo = 1) THEN 

	IF cCC.moneda_id = 1 THEN
	    nTotPesos := cCC.importe;
	ELSE
	    nTotDolar := cCC.importe;
	END IF;

	FOR cAplica IN SELECT monto_pesos,monto_divisa,importe_divisa
                   FROM relacion_ctas_ctes
                   WHERE cuenta_corriente_id  = nId AND estado = 0 LOOP
	    IF cAplica.monto_pesos > 0 THEN 
		nTotPesos = nTotPesos - cAplica.monto_pesos;
	    END IF;
	    IF cAplica.monto_divisa > 0 THEN 
		nTotDolar = nTotDolar - cAplica.monto_divisa;
	    END IF;
	END LOOP;

    ELSE

        FOR cRecCaja IN SELECT importe,importe_divisa,moneda_id
		    FROM cuentas_corrientes_caja 
		    WHERE cuenta_corriente_id = nId AND estado = 0 LOOP
	    IF cRecCaja.moneda_id = 1 THEN
		nTotPesos := nTotPesos + cRecCaja.importe;
	    ELSE
		nTotDolar := nTotDolar + cRecCaja.importe;
	    END IF;
	END LOOP;

        FOR cAplica IN SELECT monto_pesos,monto_divisa,importe_divisa
                   FROM relacion_ctas_ctes
                   WHERE relacion_id = nId AND estado = 0 LOOP
	    IF cAplica.monto_pesos > 0 THEN 
		nTotPesos = nTotPesos - cAplica.monto_pesos;
	    END IF;
	    IF cAplica.monto_divisa > 0 THEN 
		nTotDolar = nTotDolar - cAplica.monto_divisa;
	    END IF;
	END LOOP;

    END IF;

    SELECT  nTotPesos, nTotDolar INTO nAplica;
    RETURN nAplica;
END
$_$;


ALTER FUNCTION public.fun_comprobaplicado(integer) OWNER TO postgres;

--
-- Name: fun_comprobsaldo(integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.fun_comprobsaldo(integer) RETURNS record
    LANGUAGE plpgsql
    AS $_$
DECLARE
    nId               ALIAS FOR $1;
    nTotPesos         Numeric(16,2) := 0;
    nTotDolar         Numeric(16,2) := 0;
    nAplica           RECORD;
    cAplica           RECORD;
    cRecCaja          RECORD;
    cCC               RECORD;

BEGIN

    SELECT importe,moneda_id,importe_divisa,signo,modelo INTO cCC
    FROM cuentas_corrientes cc
    JOIN tipos_comprobantes tc ON cc.tipo_comprobante_id = tc.id 
    WHERE cc.id = nId AND cc.estado = 0;

--    IF (cCC.signo = 1) THEN 
    IF (cCC.modelo IN ( 1,6,2 )) THEN 

	IF cCC.moneda_id = 1 THEN
	    nTotPesos := cCC.importe;
	ELSE
	    nTotDolar := cCC.importe;
	END IF;

	FOR cAplica IN SELECT monto_pesos,monto_divisa,importe_divisa
                   FROM relacion_ctas_ctes
                   WHERE cuenta_corriente_id  = nId AND estado = 0 LOOP
	    IF cAplica.monto_pesos > 0 THEN
		nTotPesos := nTotPesos - cAplica.monto_pesos;
	    END IF;
	    IF cAplica.monto_divisa > 0 THEN 
		nTotDolar := nTotDolar - cAplica.monto_divisa;
	    END IF;
	END LOOP;

    ELSE

        FOR cRecCaja IN SELECT importe,importe_divisa,moneda_id
		    FROM cuentas_corrientes_caja 
		    WHERE cuenta_corriente_id = nId AND estado = 0 LOOP
	    IF cRecCaja.moneda_id = 1 THEN
		nTotPesos := nTotPesos + cRecCaja.importe;
	    ELSE
		nTotDolar := nTotDolar + cRecCaja.importe;
	    END IF;
	END LOOP;

        FOR cAplica IN SELECT monto_pesos,monto_divisa,importe_divisa
                   FROM relacion_ctas_ctes
                   WHERE relacion_id = nId AND estado = 0 LOOP
	    IF cAplica.monto_pesos > 0 THEN 
		nTotPesos := nTotPesos - cAplica.monto_pesos;
	    END IF;
	    IF cAplica.monto_divisa > 0 THEN 
		nTotDolar := nTotDolar - cAplica.monto_divisa;
	    END IF;
	END LOOP;

    END IF;

    SELECT  nTotPesos, nTotDolar INTO nAplica;
    RETURN nAplica;
END
$_$;


ALTER FUNCTION public.fun_comprobsaldo(integer) OWNER TO root;

--
-- Name: fun_comprobsaldo(integer, integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.fun_comprobsaldo(integer, integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$
DECLARE
    nId               ALIAS FOR $1;
    nIdMone           ALIAS FOR $2;
    nTotPesos         Numeric(16,2) := 0;
    nTotDolar         Numeric(16,2) := 0;
    nAplica           Numeric(16,2) := 0;
    aArr              INTEGER[];
    cAplica           RECORD;
    cRecCaja          RECORD;
    cCC               RECORD;
BEGIN
    aArr[1] = 1;   --fact
    aArr[2] = 2;   --deb
    aArr[3] = 6;   --si es prestamista cambiar codigo a 4

    SELECT   importe
	    ,moneda_id
	    ,importe_divisa
	    ,signo
	    ,modelo
	    ,json_array_elements_text("tipos_entidad"->'tipos_entidad') AS ti_enti
    INTO cCC
    FROM cuentas_corrientes cc
    JOIN tipos_comprobantes tc ON cc.tipo_comprobante_id = tc.id 
    WHERE cc.id = nId AND cc.estado = 0;

    --reemplaza el 6 por 4 q es el recibo de los prestamos
    IF (cCC.ti_enti = '3') THEN 
	aArr[3] = 4;  
    END IF;

    --6 ?? 1 fac, 2 deb de provee

    IF (array_position(aArr,cCC.modelo) IS NOT NULL ) THEN
	IF aArr[3] <> 4 THEN    --no es recibo de presta.
		IF cCC.moneda_id = 1 THEN
		    nTotPesos := cCC.importe;
		ELSE
		    nTotDolar := cCC.importe;
		END IF;
	ELSE

	    nTotPesos := fun_calcimportecaja(nId,1);
	    nTotDolar := fun_calcimportecaja(nId,2);


	END IF;

	FOR cAplica IN 
		    SELECT monto_pesos,monto_divisa,importe_divisa
		    FROM relacion_ctas_ctes
		    WHERE cuenta_corriente_id  = nId AND estado = 0 LOOP

	    IF cAplica.monto_pesos > 0 THEN 
		nTotPesos = nTotPesos - cAplica.monto_pesos;
	    END IF;
	    IF cAplica.monto_divisa > 0 THEN 
		nTotDolar = nTotDolar - cAplica.monto_divisa;
	    END IF;
	END LOOP;
    ELSE

	IF (cCC.modelo IN ( 3 )) THEN    --3 cred de provee
	    IF cCC.moneda_id = 1 THEN
		nTotPesos := cCC.importe;
	    ELSE
		nTotDolar := cCC.importe;
	    END IF;
	ELSE
	    FOR cRecCaja IN SELECT importe,importe_divisa,moneda_id
	    FROM cuentas_corrientes_caja 
	    WHERE cuenta_corriente_id = nId AND estado = 0 LOOP

		IF cRecCaja.moneda_id = 1 THEN
		    nTotPesos := nTotPesos + cRecCaja.importe;
		ELSE
		    nTotDolar := nTotDolar + cRecCaja.importe;
		END IF;
	    END LOOP;
	END IF;

	FOR cAplica IN SELECT monto_pesos,monto_divisa,importe_divisa
	    FROM relacion_ctas_ctes
	    WHERE relacion_id = nId AND estado = 0 LOOP

		IF cAplica.monto_pesos > 0 THEN 
		    nTotPesos = nTotPesos - cAplica.monto_pesos;
		END IF;
		IF cAplica.monto_divisa > 0 THEN 
		    nTotDolar = nTotDolar - cAplica.monto_divisa;
		END IF;
	    END LOOP;

    END IF;

    IF nIdMone = 1 THEN 
		nAplica := nTotPesos;
    ELSE
		nAplica := nTotDolar;
    END IF;

    RETURN nAplica;
END
$_$;


ALTER FUNCTION public.fun_comprobsaldo(integer, integer) OWNER TO root;

--
-- Name: fun_comprobsinaplicar(integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.fun_comprobsinaplicar(integer) RETURNS record
    LANGUAGE plpgsql
    AS $_$
DECLARE
    nId               ALIAS FOR $1;
    nTotPesos         Numeric(16,2) := 0;
    nTotDolar         Numeric(16,2) := 0;
    nAplica           RECORD;
    cAplica           RECORD;
    cRecCaja          RECORD;
    cCC               RECORD;

BEGIN

    SELECT importe,moneda_id,importe_divisa,signo,tc.modelo AS tc_modelo INTO cCC
    FROM cuentas_corrientes cc
    JOIN tipos_comprobantes tc ON cc.tipo_comprobante_id = tc.id 
    WHERE cc.id = nId AND cc.estado = 0;


    IF cCC.tc_modelo = 3 THEN --si es N.C.
	IF cCC.moneda_id = 1 THEN
	    nTotPesos := nTotPesos + cCC.importe;
	ELSE
	    nTotDolar := nTotDolar + cCC.importe;
	END IF;

    ELSIF (cCC.tc_modelo IN ( 4,5 ))  THEN --si es rec. u o/p 

        FOR cRecCaja IN SELECT importe,importe_divisa,moneda_id
		    FROM cuentas_corrientes_caja 
		    WHERE cuenta_corriente_id = nId AND estado = 0 LOOP
	    IF cRecCaja.moneda_id = 1 THEN
		nTotPesos := nTotPesos + cRecCaja.importe;
	    ELSE
		nTotDolar := nTotDolar + cRecCaja.importe;
	    END IF;
	END LOOP;

    END IF;

    FOR cAplica IN SELECT monto_pesos,monto_divisa,importe_divisa
                   FROM relacion_ctas_ctes
                   WHERE relacion_id = nId AND estado = 0 LOOP
	IF cAplica.monto_pesos > 0 THEN 
	    nTotPesos := nTotPesos - cAplica.monto_pesos;
	END IF;
	IF cAplica.monto_divisa > 0 THEN 
	    nTotDolar := nTotDolar - cAplica.monto_divisa;
	END IF;
    END LOOP;

    SELECT  nTotPesos, nTotDolar INTO nAplica;
    RETURN nAplica;
END
$_$;


ALTER FUNCTION public.fun_comprobsinaplicar(integer) OWNER TO root;

--
-- Name: fun_comprobsinaplicar(integer, integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.fun_comprobsinaplicar(integer, integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$
DECLARE
    nId               ALIAS FOR $1;
    nIdMone           ALIAS FOR $2;
    nTotPesos         Numeric(16,2) := 0;
    nTotDolar         Numeric(16,2) := 0;
    nAplica           Numeric(16,2) := 0;
    cAplica           RECORD;
    cRecCaja          RECORD;
    cCC               RECORD;
BEGIN
    SELECT importe,moneda_id,importe_divisa,signo,tc.modelo AS tc_modelo INTO cCC
    FROM cuentas_corrientes cc
    JOIN tipos_comprobantes tc ON cc.tipo_comprobante_id = tc.id 
    WHERE cc.id = nId AND cc.estado = 0;
    IF cCC.tc_modelo = 3 THEN --si es N.C.
	IF cCC.moneda_id = 1 THEN
	    nTotPesos := nTotPesos + cCC.importe;
	ELSE
	    nTotDolar := nTotDolar + cCC.importe;
	END IF;
    ELSIF (cCC.tc_modelo IN ( 4, 5))  THEN --si es rec. u o/p 
        FOR cRecCaja IN SELECT importe,importe_divisa,moneda_id
		    FROM cuentas_corrientes_caja 
		    WHERE cuenta_corriente_id = nId AND estado = 0 LOOP
	    IF cRecCaja.moneda_id = 1 THEN
		nTotPesos := nTotPesos + cRecCaja.importe;
	    ELSE
		nTotDolar := nTotDolar + cRecCaja.importe;
	    END IF;
	END LOOP;
    END IF;
    FOR cAplica IN SELECT monto_pesos,monto_divisa,importe_divisa
                   FROM relacion_ctas_ctes
                   WHERE relacion_id = nId AND estado = 0 LOOP
	IF cAplica.monto_pesos > 0 THEN 
	    nTotPesos := nTotPesos - cAplica.monto_pesos;
	END IF;
	IF cAplica.monto_divisa > 0 THEN 
	    nTotDolar := nTotDolar - cAplica.monto_divisa;
	END IF;
    END LOOP;
    IF nIdMone = 1 THEN 
	nAplica := nTotPesos;
    ELSE
	nAplica := nTotDolar;
    END IF;
    RETURN nAplica;
END
$_$;


ALTER FUNCTION public.fun_comprobsinaplicar(integer, integer) OWNER TO root;

--
-- Name: fun_dameconceptocomprob(integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.fun_dameconceptocomprob(integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$DECLARE
    nId    ALIAS FOR $1;
    cRet varchar(30) := '';
BEGIN
	SELECT descripcion INTO cRet
	FROM conceptos WHERE id = nId;
	IF cRet IS NULL THEN 
		cRet := '';
	END IF;

--	CASE WHEN nId = 0 THEN cRet := 'SIN CONCEPTO';
--    	 WHEN nId = 1 THEN cRet := 'TERRENO';
--	 WHEN nId = 2 THEN cRet := 'MATERIALES';
--	 WHEN nId = 3 THEN cRet := 'OBRA';
--	 ELSE cRet := ' ';
 --   END CASE;

    RETURN cRet;
END;
$_$;


ALTER FUNCTION public.fun_dameconceptocomprob(integer) OWNER TO root;

--
-- Name: fun_dameentidadproyecto(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fun_dameentidadproyecto(integer, integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
    nIdEnti     ALIAS FOR $1;
    nIdProy     ALIAS FOR $2;
	nRet        integer := 0;

BEGIN

    SELECT COUNT(*) INTO nRet
    FROM proyectos_entidades
    WHERE entidad_id  = nIdEnti
      AND proyecto_id = nIdProy
      AND estado      = 0;

    RETURN nRet;

END;
$_$;


ALTER FUNCTION public.fun_dameentidadproyecto(integer, integer) OWNER TO postgres;

--
-- Name: fun_damemodelocomprob(integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.fun_damemodelocomprob(integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$

DECLARE
    nId    ALIAS FOR $1;
    cRet varchar(30) := '';
BEGIN

    CASE    WHEN nId = 1 THEN cRet := 'FACTURA';
	    WHEN nId = 2 THEN cRet := 'N.DEBITO';
	    WHEN nId = 3 THEN cRet := 'N.CREDITO';
	    WHEN nId = 4 THEN cRet := 'RECIBO';
	    WHEN nId = 5 THEN cRet := 'ORD.PAGO';
		WHEN nId = 6 THEN cRet := 'N.DEB.PROVEE.';
	    ELSE cRet := ' ';
    END CASE;

    RETURN cRet;
END;
$_$;


ALTER FUNCTION public.fun_damemodelocomprob(integer) OWNER TO root;

--
-- Name: fun_dametiposentidades(integer, character varying); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.fun_dametiposentidades(integer, character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $_$

DECLARE
    nId      ALIAS FOR $1;
    cTabla   ALIAS FOR $2;
    cRet     varchar(100) := '';
    nTipo    integer := 0;
    cDeno    varchar(30) := '';
    cNumeEnt varchar(30) := '';
BEGIN


    IF (cTabla = 'E' OR cTabla = 'N') THEN
        FOR nTipo IN SELECT json_array_elements_text("tipos_entidad"->'tipos_entidad')
                 FROM entidades e
                 WHERE e.id = nId LOOP


	    	cNumeEnt := cNumeEnt || ',' || nTipo::text;

            SELECT t.denominacion INTO cDeno
            FROM tipos_entidades t
            WHERE t.id = nTipo;

            cRet := cRet || ' ' || cDeno;

        END LOOP;

		IF (cTabla = 'N') THEN 
		    cRet := TRIM(BOTH FROM cNumeEnt, ',');
		END IF;

    ELSE
        FOR nTipo IN SELECT json_array_elements_text("tipos_entidad"->'tipos_entidad')
                 FROM tipos_comprobantes e
                 WHERE e.id = nId LOOP

			cNumeEnt := cNumeEnt || ',' || nTipo::text;

            SELECT t.denominacion INTO cDeno
            FROM tipos_entidades t
            WHERE t.id = nTipo;

            cRet := cRet || ' ' || cDeno;

        END LOOP;

		IF (cTabla = 'X') THEN 
		    cRet := TRIM(BOTH FROM cNumeEnt, ',');
		END IF;

	END IF;  

    RETURN cRet;
END;
$_$;


ALTER FUNCTION public.fun_dametiposentidades(integer, character varying) OWNER TO root;

--
-- Name: fun_importecomprob(integer, integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.fun_importecomprob(integer, integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $_$
DECLARE
    nId               ALIAS FOR $1;
    nIdMone           ALIAS FOR $2;
    nTotal            Numeric(16,2) := 0;

    nTotPesos         Numeric(16,2) := 0;
    nTotDolar         Numeric(16,2) := 0;
    nAplica           Numeric(16,2) := 0;
    cAplica           RECORD;
    cRecCaja          RECORD;
    cCC               RECORD;
BEGIN
    SELECT importe,moneda_id,importe_divisa,signo,tc.modelo AS tc_modelo INTO cCC
    FROM cuentas_corrientes cc
    JOIN tipos_comprobantes tc ON cc.tipo_comprobante_id = tc.id 
    WHERE cc.id = nId AND cc.estado = 0;

    IF cCC.moneda_id = nIdMone THEN 
	IF cCC.importe IS NOT NULL THEN
	    nTotal := cCC.importe;
	END IF;
    END IF;

    IF cCC.tc_modelo = 4 OR cCC.tc_modelo = 5  THEN --si es rec. u o/p 
        FOR cRecCaja IN SELECT importe,importe_divisa,moneda_id
		    FROM cuentas_corrientes_caja 
		    WHERE cuenta_corriente_id = nId AND estado = 0 LOOP
	    IF cRecCaja.moneda_id = nIdMone THEN 
		IF cRecCaja.importe IS NOT NULL THEN
		    nTotal := nTotal + cRecCaja.importe;
		END IF;
	    END IF;
	END LOOP;
    END IF;
    RETURN nTotal;
END
$_$;


ALTER FUNCTION public.fun_importecomprob(integer, integer) OWNER TO root;

--
-- Name: fun_ultimo_chq_emi(integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION public.fun_ultimo_chq_emi(integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
    nId     ALIAS FOR $1;
    nRet    INTEGER := 0;
    nUltimo INTEGER := 0;
    nDesde  INTEGER := 0;
BEGIN
    
    SELECT MAX(ccc.numero), ch.hasta_nro, ch.desde_nro  INTO nRet, nUltimo, nDesde
    FROM chequeras ch
    LEFT JOIN cuentas_corrientes_caja ccc ON ch.id = ccc.chequera_id 
    WHERE ch.id = nId
    GROUP BY ch.hasta_nro,ch.desde_nro;
    
    IF (nDesde IS NOT NULL) THEN
        IF (nRet IS NOT NULL) THEN 
            IF (nRet >= nUltimo) THEN
                nRet := NULL;
            END IF;
        ELSE 
            nRet := nDesde - 1;
        END IF;    
    ELSE
        nRet := NULL;
    END IF;
    RETURN nRet;
END;
$_$;


ALTER FUNCTION public.fun_ultimo_chq_emi(integer) OWNER TO root;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bancos; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.bancos (
    id integer NOT NULL,
    denominacion character varying(80),
    estado integer DEFAULT 0
);


ALTER TABLE public.bancos OWNER TO root;

--
-- Name: cajas; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.cajas (
    id integer NOT NULL,
    denominacion character varying(50),
    estado integer DEFAULT 0
);


ALTER TABLE public.cajas OWNER TO root;

--
-- Name: cajas_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.cajas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cajas_id_seq OWNER TO root;

--
-- Name: cajas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.cajas_id_seq OWNED BY public.cajas.id;


--
-- Name: chequeras; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.chequeras (
    id integer NOT NULL,
    cuenta_bancaria_id integer,
    echeque character varying(1),
    serie character varying(3),
    desde_nro integer,
    hasta_nro integer,
    fecha_solicitud date,
    moneda_id integer,
    estado integer DEFAULT 0
);


ALTER TABLE public.chequeras OWNER TO root;

--
-- Name: COLUMN chequeras.fecha_solicitud; Type: COMMENT; Schema: public; Owner: root
--

COMMENT ON COLUMN public.chequeras.fecha_solicitud IS 'fecha de cuando se solicito la chequera';


--
-- Name: chequeras_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.chequeras_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chequeras_id_seq OWNER TO root;

--
-- Name: chequeras_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.chequeras_id_seq OWNED BY public.chequeras.id;


--
-- Name: conceptos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conceptos (
    id integer NOT NULL,
    descripcion character varying(20),
    orden integer
);


ALTER TABLE public.conceptos OWNER TO postgres;

--
-- Name: conceptos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.conceptos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.conceptos_id_seq OWNER TO postgres;

--
-- Name: conceptos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.conceptos_id_seq OWNED BY public.conceptos.id;


--
-- Name: cotizaciones; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.cotizaciones (
    id integer NOT NULL,
    fecha date,
    importe numeric(16,2),
    moneda_id integer,
    estado integer DEFAULT 0,
    oficial_compra numeric(16,2),
    oficial_venta numeric(16,2),
    blue_compra numeric(16,2),
    blue_venta numeric(16,2),
    hora time without time zone,
    fecha_baja timestamp without time zone
)
WITH (autovacuum_enabled='true');


ALTER TABLE public.cotizaciones OWNER TO root;

--
-- Name: cotizaciones_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.cotizaciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cotizaciones_id_seq OWNER TO root;

--
-- Name: cotizaciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.cotizaciones_id_seq OWNED BY public.cotizaciones.id;


--
-- Name: cuentas_bancarias; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.cuentas_bancarias (
    id integer NOT NULL,
    denominacion character varying(80),
    banco_id integer,
    cbu character varying(22),
    alias character varying(20),
    tipo character varying(1),
    estado integer DEFAULT 0,
    proyecto_id integer,
    fecha_baja timestamp without time zone
);


ALTER TABLE public.cuentas_bancarias OWNER TO root;

--
-- Name: COLUMN cuentas_bancarias.tipo; Type: COMMENT; Schema: public; Owner: root
--

COMMENT ON COLUMN public.cuentas_bancarias.tipo IS 'cuenta Corriente caja de Ahorro';


--
-- Name: cuentas_bancarias_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.cuentas_bancarias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cuentas_bancarias_id_seq OWNER TO root;

--
-- Name: cuentas_bancarias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.cuentas_bancarias_id_seq OWNED BY public.cuentas_bancarias.id;


--
-- Name: cuentas_corrientes; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.cuentas_corrientes (
    id integer NOT NULL,
    tipo_comprobante_id integer,
    importe numeric(16,2),
    moneda_id integer,
    cotizacion_divisa numeric(16,2),
    importe_divisa numeric(16,2),
    entidad_id integer,
    detalle_proyecto_tipo_propiedad_id integer,
    comentario character varying(4096),
    proyecto_id integer,
    estado integer DEFAULT 0,
    usuario_id integer,
    fecha date,
    fecha_registro timestamp without time zone DEFAULT now(),
    numero integer,
    docu_letra character varying(1),
    docu_sucu integer,
    docu_nume integer,
    proyecto_origen_id integer,
    fecha_baja timestamp without time zone
);


ALTER TABLE public.cuentas_corrientes OWNER TO root;

--
-- Name: COLUMN cuentas_corrientes.numero; Type: COMMENT; Schema: public; Owner: root
--

COMMENT ON COLUMN public.cuentas_corrientes.numero IS 'lo debe traer del tipo de comprobante';


--
-- Name: cuentas_corrientes_caja; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.cuentas_corrientes_caja (
    id integer NOT NULL,
    cuenta_corriente_id integer,
    importe numeric(16,2),
    moneda_id integer,
    cotizacion_divisa numeric(16,2),
    importe_divisa numeric(16,2),
    estado integer DEFAULT 0,
    tipo_movimiento_caja_id integer,
    cuenta_bancaria_id integer,
    caja_id integer,
    comentario character varying(4096),
    cta_cte_caja_origen_id integer,
    fecha_emision date,
    fecha_acreditacion date,
    serie character varying(3),
    numero integer,
    chequera_id integer,
    banco_id integer,
    e_chq integer DEFAULT 0,
    chq_a_depo integer,
    fecha_conciliacion date,
    fecha_depositado date,
    fecha_registro timestamp without time zone DEFAULT now(),
    signo_caja integer DEFAULT 1,
    signo_banco integer DEFAULT 1,
    proyecto_id integer,
    relacion_id integer,
    fecha_baja timestamp without time zone
);


ALTER TABLE public.cuentas_corrientes_caja OWNER TO root;

--
-- Name: cuentas_corrientes_caja_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.cuentas_corrientes_caja_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cuentas_corrientes_caja_id_seq OWNER TO root;

--
-- Name: cuentas_corrientes_caja_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.cuentas_corrientes_caja_id_seq OWNED BY public.cuentas_corrientes_caja.id;


--
-- Name: cuentas_corrientes_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.cuentas_corrientes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cuentas_corrientes_id_seq OWNER TO root;

--
-- Name: cuentas_corrientes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.cuentas_corrientes_id_seq OWNED BY public.cuentas_corrientes.id;


--
-- Name: detalle_proyecto_tipos_propiedades; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.detalle_proyecto_tipos_propiedades (
    id integer NOT NULL,
    coeficiente numeric(8,4),
    proyecto_tipo_propiedad_id integer,
    entidad_id integer,
    estado integer DEFAULT 0,
    fecha_baja timestamp without time zone
);


ALTER TABLE public.detalle_proyecto_tipos_propiedades OWNER TO root;

--
-- Name: detalle_proyecto_tipos_propiedades_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.detalle_proyecto_tipos_propiedades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.detalle_proyecto_tipos_propiedades_id_seq OWNER TO root;

--
-- Name: detalle_proyecto_tipos_propiedades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.detalle_proyecto_tipos_propiedades_id_seq OWNED BY public.detalle_proyecto_tipos_propiedades.id;


--
-- Name: entidades; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.entidades (
    id integer NOT NULL,
    razon_social character varying(100),
    calle character varying(100),
    numero character varying(20),
    piso_departamento character varying(20),
    celular character varying(20),
    whatsapp character varying(20),
    email character varying(80),
    observaciones character varying(1024),
    cuit bigint,
    situacion_iva integer,
    datos_varios json,
    localidad_id integer,
    tipos_entidad json,
    estado integer DEFAULT 0,
    fecha_baja timestamp without time zone,
    proyecto_id integer
);


ALTER TABLE public.entidades OWNER TO root;

--
-- Name: COLUMN entidades.situacion_iva; Type: COMMENT; Schema: public; Owner: root
--

COMMENT ON COLUMN public.entidades.situacion_iva IS 'Monotributista
Responsable Inscripto (RI)
Exento
Consumidor Final';


--
-- Name: entidades_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.entidades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entidades_id_seq OWNER TO root;

--
-- Name: entidades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.entidades_id_seq OWNED BY public.entidades.id;


--
-- Name: informes_proyectos; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.informes_proyectos (
    id integer NOT NULL,
    proyecto_id integer,
    estado integer DEFAULT 0,
    entidad_id integer,
    fecha_baja timestamp without time zone
);


ALTER TABLE public.informes_proyectos OWNER TO root;

--
-- Name: informes_proyectos_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.informes_proyectos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.informes_proyectos_id_seq OWNER TO root;

--
-- Name: informes_proyectos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.informes_proyectos_id_seq OWNED BY public.informes_proyectos.id;


--
-- Name: localidades; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.localidades (
    id integer NOT NULL,
    nombre character varying(80),
    cp character varying(30),
    estado integer,
    provincia_id integer
);


ALTER TABLE public.localidades OWNER TO root;

--
-- Name: localidades_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.localidades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.localidades_id_seq OWNER TO root;

--
-- Name: localidades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.localidades_id_seq OWNED BY public.localidades.id;


--
-- Name: materiales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.materiales (
    id integer NOT NULL,
    descripcion character varying(100),
    unidad character varying(20),
    stock_minimo numeric(16,2),
    ean_13 bigint,
    cantidad_uni_compra numeric(16,2),
    peso_uni_compra numeric(16,2),
    estado integer DEFAULT 0,
    fecha_baja timestamp without time zone
);


ALTER TABLE public.materiales OWNER TO postgres;

--
-- Name: materiales_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.materiales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.materiales_id_seq OWNER TO postgres;

--
-- Name: materiales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.materiales_id_seq OWNED BY public.materiales.id;


--
-- Name: monedas; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.monedas (
    id integer NOT NULL,
    denominacion character varying(40),
    codigo_afip character(10),
    estado integer DEFAULT 0,
    simbolo character varying(15)
);


ALTER TABLE public.monedas OWNER TO root;

--
-- Name: COLUMN monedas.codigo_afip; Type: COMMENT; Schema: public; Owner: root
--

COMMENT ON COLUMN public.monedas.codigo_afip IS 'PES , DOL, 060 (euro)';


--
-- Name: monedas_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.monedas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.monedas_id_seq OWNER TO root;

--
-- Name: monedas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.monedas_id_seq OWNED BY public.monedas.id;


--
-- Name: movimientos_bancarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movimientos_bancarios (
    id integer NOT NULL,
    fecha date,
    importe numeric(16,2),
    cuenta_bancaria_id integer,
    tipo_movimiento_caja_id integer,
    cuenta_corriente_id integer,
    estado integer DEFAULT 0,
    moneda_id integer,
    cotizacion_divisa numeric(16,2),
    importe_divisa numeric(16,2),
    numero character varying(20),
    comentario character varying(4096)
);


ALTER TABLE public.movimientos_bancarios OWNER TO postgres;

--
-- Name: movimientos_bancarios_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.movimientos_bancarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.movimientos_bancarios_id_seq OWNER TO postgres;

--
-- Name: movimientos_bancarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.movimientos_bancarios_id_seq OWNED BY public.movimientos_bancarios.id;


--
-- Name: movimientos_cheques; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.movimientos_cheques (
    id integer NOT NULL,
    cuenta_corriente_caja_id integer,
    banco_id integer,
    fecha_emision date,
    fecha_acreditacion date,
    importe numeric(16,2),
    cotizacion numeric(16,2),
    chequera_id integer,
    estado integer DEFAULT 0,
    serie character varying(2),
    numero integer,
    moneda_id integer
);


ALTER TABLE public.movimientos_cheques OWNER TO root;

--
-- Name: COLUMN movimientos_cheques.chequera_id; Type: COMMENT; Schema: public; Owner: root
--

COMMENT ON COLUMN public.movimientos_cheques.chequera_id IS 'si este campo en null, indica q es chq de 3ros';


--
-- Name: movimientos_cheques_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.movimientos_cheques_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.movimientos_cheques_id_seq OWNER TO root;

--
-- Name: movimientos_cheques_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.movimientos_cheques_id_seq OWNED BY public.movimientos_cheques.id;


--
-- Name: permisos; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.permisos (
    id integer NOT NULL,
    denominacion character varying(80),
    estado integer DEFAULT 0
);


ALTER TABLE public.permisos OWNER TO root;

--
-- Name: permisos_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.permisos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.permisos_id_seq OWNER TO root;

--
-- Name: permisos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.permisos_id_seq OWNED BY public.permisos.id;


--
-- Name: permisos_usuarios; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.permisos_usuarios (
    id integer NOT NULL,
    usuario_id integer,
    permiso_id integer,
    estado integer DEFAULT 0
);


ALTER TABLE public.permisos_usuarios OWNER TO root;

--
-- Name: permisos_usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.permisos_usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.permisos_usuarios_id_seq OWNER TO root;

--
-- Name: permisos_usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.permisos_usuarios_id_seq OWNED BY public.permisos_usuarios.id;


--
-- Name: presupuestos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.presupuestos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.presupuestos_id_seq OWNER TO postgres;

--
-- Name: presupuestos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.presupuestos (
    id integer DEFAULT nextval('public.presupuestos_id_seq'::regclass) NOT NULL,
    fecha_inicio date,
    fecha_final date,
    comentario character varying(2048),
    importe_inicial numeric(18,2),
    importe_final numeric(18,2),
    entidad_id integer,
    proyecto_id integer,
    titulo character varying(100),
    estado integer DEFAULT 0,
    moneda_id integer
);


ALTER TABLE public.presupuestos OWNER TO postgres;

--
-- Name: provincias; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.provincias (
    id integer NOT NULL,
    nombre character varying(50)
);


ALTER TABLE public.provincias OWNER TO root;

--
-- Name: provincias_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.provincias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.provincias_id_seq OWNER TO root;

--
-- Name: provincias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.provincias_id_seq OWNED BY public.provincias.id;


--
-- Name: proyectos; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.proyectos (
    id integer NOT NULL,
    nombre character varying(100),
    caracteristicas json,
    fecha_inicio date,
    fecha_finalizacion date,
    comentario character varying(4096),
    calle character varying(100),
    numero character varying(20),
    localidad_id integer,
    tipo_proyecto_id integer,
    tipo_obra_id integer,
    estado integer DEFAULT 0,
    fecha_baja timestamp without time zone
);


ALTER TABLE public.proyectos OWNER TO root;

--
-- Name: proyectos_entidades; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.proyectos_entidades (
    id integer NOT NULL,
    entidad_id integer,
    proyecto_id integer,
    estado integer DEFAULT 0,
    fecha_baja timestamp without time zone
)
WITH (autovacuum_enabled='true');


ALTER TABLE public.proyectos_entidades OWNER TO root;

--
-- Name: proyectos_entidades_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.proyectos_entidades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.proyectos_entidades_id_seq OWNER TO root;

--
-- Name: proyectos_entidades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.proyectos_entidades_id_seq OWNED BY public.proyectos_entidades.id;


--
-- Name: proyectos_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.proyectos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.proyectos_id_seq OWNER TO root;

--
-- Name: proyectos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.proyectos_id_seq OWNED BY public.proyectos.id;


--
-- Name: proyectos_tipos_propiedades; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.proyectos_tipos_propiedades (
    id integer NOT NULL,
    cantidad integer,
    tipo_propiedad_id integer,
    proyecto_id integer,
    comentario character varying(4096),
    estado integer DEFAULT 0,
    coeficiente numeric(8,4),
    fecha_baja timestamp without time zone
);


ALTER TABLE public.proyectos_tipos_propiedades OWNER TO root;

--
-- Name: proyectos_tipos_propiedades_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.proyectos_tipos_propiedades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.proyectos_tipos_propiedades_id_seq OWNER TO root;

--
-- Name: proyectos_tipos_propiedades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.proyectos_tipos_propiedades_id_seq OWNED BY public.proyectos_tipos_propiedades.id;


--
-- Name: relacion_ctas_ctes; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.relacion_ctas_ctes (
    id integer NOT NULL,
    cuenta_corriente_id integer,
    relacion_id integer,
    estado integer DEFAULT 0,
    fecha timestamp without time zone DEFAULT now(),
    importe_divisa numeric(16,2) DEFAULT 0,
    monto_divisa numeric(16,2) DEFAULT 0,
    monto_pesos numeric(16,2) DEFAULT 0,
    fecha_baja timestamp without time zone
);


ALTER TABLE public.relacion_ctas_ctes OWNER TO root;

--
-- Name: relacion_ctas_ctes_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.relacion_ctas_ctes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.relacion_ctas_ctes_id_seq OWNER TO root;

--
-- Name: relacion_ctas_ctes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.relacion_ctas_ctes_id_seq OWNED BY public.relacion_ctas_ctes.id;


--
-- Name: relacion_presu_ctactes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.relacion_presu_ctactes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.relacion_presu_ctactes_id_seq OWNER TO postgres;

--
-- Name: relacion_presu_ctactes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.relacion_presu_ctactes (
    id integer DEFAULT nextval('public.relacion_presu_ctactes_id_seq'::regclass) NOT NULL,
    cuenta_corriente_id integer,
    presupuesto_id integer,
    estado integer DEFAULT 0
);


ALTER TABLE public.relacion_presu_ctactes OWNER TO postgres;

--
-- Name: tipos_comprobantes; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.tipos_comprobantes (
    id integer NOT NULL,
    descripcion character varying(60),
    signo integer,
    abreviado character varying(40) NOT NULL,
    numero bigint,
    estado integer DEFAULT 0,
    afecta_caja integer DEFAULT 0,
    tipos_entidad json,
    modelo integer DEFAULT 0,
    concepto integer DEFAULT 0,
    aplica_impu integer DEFAULT 1,
    signo_en_caja integer DEFAULT 0,
    fecha_baja timestamp without time zone,
    template character varying(50)
);


ALTER TABLE public.tipos_comprobantes OWNER TO root;

--
-- Name: tipos_comprobantes_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.tipos_comprobantes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tipos_comprobantes_id_seq OWNER TO root;

--
-- Name: tipos_comprobantes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.tipos_comprobantes_id_seq OWNED BY public.tipos_comprobantes.id;


--
-- Name: tipos_entidades; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.tipos_entidades (
    id integer NOT NULL,
    denominacion character varying(80),
    estado integer DEFAULT 0
);


ALTER TABLE public.tipos_entidades OWNER TO root;

--
-- Name: tipos_entidades_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.tipos_entidades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tipos_entidades_id_seq OWNER TO root;

--
-- Name: tipos_entidades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.tipos_entidades_id_seq OWNED BY public.tipos_entidades.id;


--
-- Name: tipos_movimientos_caja; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.tipos_movimientos_caja (
    id integer NOT NULL,
    descripcion character varying(80),
    signo integer,
    estado integer DEFAULT 0,
    gestiona_cheques integer DEFAULT 0,
    gestiona_ctas_bancarias integer DEFAULT 0,
    movimiento character varying(1) DEFAULT ''::character varying,
    orden integer DEFAULT 0,
    afec_enti character varying(20),
    e_chq integer DEFAULT 0,
    gestiona_banco integer DEFAULT 0,
    mov_en_banco integer DEFAULT 0,
    txt_info_caja character varying(80),
    mov_internos integer DEFAULT 0,
    entre_proyectos integer DEFAULT 0,
    pide_proyectos integer DEFAULT 0,
    tipo_mov integer DEFAULT 0,
    fidei_act_c_impu integer DEFAULT 0,
    fidei_act_s_impu integer DEFAULT 0,
    fidei_otr_c_impu integer DEFAULT 0,
    fidei_otr_s_impu integer DEFAULT 0,
    chq_a_depo integer DEFAULT 0
);


ALTER TABLE public.tipos_movimientos_caja OWNER TO root;

--
-- Name: tipos_movimientos_caja_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.tipos_movimientos_caja_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tipos_movimientos_caja_id_seq OWNER TO root;

--
-- Name: tipos_movimientos_caja_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.tipos_movimientos_caja_id_seq OWNED BY public.tipos_movimientos_caja.id;


--
-- Name: tipos_obras; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.tipos_obras (
    id integer NOT NULL,
    descripcion character varying(100),
    estado integer DEFAULT 0
)
WITH (autovacuum_enabled='true');


ALTER TABLE public.tipos_obras OWNER TO root;

--
-- Name: tipos_obras_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.tipos_obras_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tipos_obras_id_seq OWNER TO root;

--
-- Name: tipos_obras_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.tipos_obras_id_seq OWNED BY public.tipos_obras.id;


--
-- Name: tipos_propiedades; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.tipos_propiedades (
    id integer NOT NULL,
    descripcion character varying(100),
    obligatorio integer,
    estado integer DEFAULT 0,
    fecha_baja timestamp without time zone
);


ALTER TABLE public.tipos_propiedades OWNER TO root;

--
-- Name: tipos_propiedades_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.tipos_propiedades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tipos_propiedades_id_seq OWNER TO root;

--
-- Name: tipos_propiedades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.tipos_propiedades_id_seq OWNED BY public.tipos_propiedades.id;


--
-- Name: tipos_proyectos; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.tipos_proyectos (
    id integer NOT NULL,
    descripcion character varying(40),
    estado integer DEFAULT 0
);


ALTER TABLE public.tipos_proyectos OWNER TO root;

--
-- Name: tipos_proyectos_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.tipos_proyectos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tipos_proyectos_id_seq OWNER TO root;

--
-- Name: tipos_proyectos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.tipos_proyectos_id_seq OWNED BY public.tipos_proyectos.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    nombre character varying(80),
    password character varying(40),
    usuario character varying(40),
    estado integer DEFAULT 0,
    nivel integer DEFAULT 0,
    fecha_baja timestamp without time zone
);


ALTER TABLE public.usuarios OWNER TO root;

--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.usuarios_id_seq OWNER TO root;

--
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: vi_aplicaciones_ctas_ctes; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_aplicaciones_ctas_ctes AS
 SELECT cc1.id AS cc1_id,
    cc1.comentario AS cc1_comentario,
    cc1.fecha AS cc1_fechax,
    to_char((cc1.fecha)::timestamp with time zone, 'dd-mm-yyyy'::text) AS cc1_fecha,
    cc1.proyecto_id AS cc1_proyecto_id,
    pr1.nombre AS pr1_nombre,
    to_char((cc1.fecha)::timestamp with time zone, 'DD-MM-YYYY'::text) AS cc1_fecha_dmy,
    cc1.fecha_registro AS cc1_fecha_registrox,
    to_char(cc1.fecha_registro, 'dd-mm-yyyy'::text) AS cc1_fecha_registro,
    (((((((tc1.abreviado)::text || ' Nro.'::text) || (cc1.docu_letra)::text) || ' '::text) || (cc1.docu_sucu)::text) || ' '::text) || (cc1.docu_nume)::text) AS comp1x_nume,
    (((((((tc1.abreviado)::text || ' Nro.'::text) || (COALESCE(cc1.docu_letra, ' '::character varying))::text) || ' '::text) || COALESCE((cc1.docu_sucu)::text, ' '::text)) || ' '::text) || COALESCE((cc1.docu_nume)::text, (cc1.numero)::text)) AS comp1_nume,
    tc1.modelo AS tc1_modelo,
    cc2.id AS cc2_id,
    cc2.comentario AS cc2_comentario,
    cc2.fecha AS cc2_fechax,
    to_char((cc2.fecha)::timestamp with time zone, 'dd-mm-yyyy'::text) AS cc2_fecha,
    cc2.proyecto_id AS cc2_proyecto_id,
    pr2.nombre AS pr2_nombre,
    to_char((cc2.fecha)::timestamp with time zone, 'DD-MM-YYYY'::text) AS cc2_fecha_dmy,
    cc2.fecha_registro AS cc2_fecha_registrox,
    to_char(cc2.fecha_registro, 'dd-mm-yyyy'::text) AS cc2_fecha_registro,
    (((tc2.abreviado)::text || ' Nro.'::text) || (cc2.numero)::text) AS comp2_nume,
    tc2.modelo AS tc2_modelo,
    rcc.monto_pesos AS rcc_monto_pesos,
    rcc.monto_divisa AS rcc_monto_divisa
   FROM ((((((((public.relacion_ctas_ctes rcc
     LEFT JOIN public.cuentas_corrientes cc1 ON (((rcc.cuenta_corriente_id = cc1.id) AND (cc1.estado = 0))))
     LEFT JOIN public.tipos_comprobantes tc1 ON ((cc1.tipo_comprobante_id = tc1.id)))
     LEFT JOIN public.monedas mo1 ON ((cc1.moneda_id = mo1.id)))
     LEFT JOIN public.proyectos pr1 ON ((cc1.proyecto_id = pr1.id)))
     LEFT JOIN public.cuentas_corrientes cc2 ON (((rcc.relacion_id = cc2.id) AND (cc2.estado = 0))))
     LEFT JOIN public.tipos_comprobantes tc2 ON ((cc2.tipo_comprobante_id = tc2.id)))
     LEFT JOIN public.monedas mo2 ON ((cc2.moneda_id = mo2.id)))
     LEFT JOIN public.proyectos pr2 ON ((cc2.proyecto_id = pr2.id)))
  WHERE (rcc.estado = 0);


ALTER TABLE public.vi_aplicaciones_ctas_ctes OWNER TO root;

--
-- Name: vi_chequeras; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_chequeras AS
 SELECT ch.id AS ch_id,
    ch.cuenta_bancaria_id AS ch_cuenta_bancaria_id,
    cb.denominacion AS cb_denominacion,
    cb.banco_id AS cb_banco_id,
    ba.denominacion AS ba_denominacion,
    ch.serie AS ch_serie,
    ch.desde_nro AS ch_desde_nro,
    ch.hasta_nro AS ch_hasta_nro,
    (((((ch.serie)::text || ' '::text) || (ch.desde_nro)::text) || ' - '::text) || (ch.hasta_nro)::text) AS numeracion,
    ch.fecha_solicitud AS ch_fecha_solicitud,
    to_char((ch.fecha_solicitud)::timestamp with time zone, 'dd-mm-yyyy'::text) AS ch_fecha_solicitudx,
    ch.moneda_id AS ch_moneda_id,
    mo.denominacion AS mo_denominacion,
    mo.codigo_afip AS mo_codigo_afip,
        CASE
            WHEN ((ch.echeque)::text = 'S'::text) THEN 'ECHEQ'::text
            ELSE ''::text
        END AS echeq,
    ch.echeque AS ch_echeque,
    cb.proyecto_id AS cb_proyecto_id,
    ch.estado AS ch_estado,
    public.fun_ultimo_chq_emi(ch.id) AS ultimo_emitido
   FROM (((public.chequeras ch
     LEFT JOIN public.cuentas_bancarias cb ON ((ch.cuenta_bancaria_id = cb.id)))
     LEFT JOIN public.bancos ba ON ((cb.banco_id = ba.id)))
     LEFT JOIN public.monedas mo ON ((ch.moneda_id = mo.id)))
  WHERE (ch.estado = 0);


ALTER TABLE public.vi_chequeras OWNER TO root;

--
-- Name: vi_cheques; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_cheques AS
 SELECT public.fun_chq_asignado(ccc.id) AS chq3_salida_id,
    ccc.id AS ccc_id,
    ccc.cuenta_corriente_id AS ccc_cuenta_corriente_id,
    ccc.importe AS ccc_importe,
    ccc.moneda_id AS ccc_moneda_id,
    ccc.importe_divisa AS ccc_importe_divisa,
    ccc.tipo_movimiento_caja_id AS ccc_tipo_movimiento_caja_id,
    ccc.cuenta_bancaria_id AS ccc_cuenta_bancaria_id,
    ccc.caja_id AS ccc_caja_id,
    ccc.comentario AS ccc_comentario,
    ccc.fecha_emision AS ccc_fecha_emision,
    ccc.fecha_acreditacion AS ccc_fecha_acreditacion,
    ccc.fecha_conciliacion AS ccc_fecha_conciliacion,
    to_char((ccc.fecha_emision)::timestamp with time zone, 'dd-mm-yyyy'::text) AS ccc_fecha_emisionx,
    to_char((ccc.fecha_acreditacion)::timestamp with time zone, 'dd-mm-yyyy'::text) AS ccc_fecha_acreditacionx,
    to_char((ccc.fecha_conciliacion)::timestamp with time zone, 'dd-mm-yyyy'::text) AS ccc_fecha_conciliacionx,
    ccc.serie AS ccc_serie,
    ccc.numero AS ccc_numero,
    ccc.chequera_id AS ccc_chequera_id,
    ccc.banco_id AS ccc_banco_id,
    ccc.e_chq AS ccc_e_chq,
    ccc.chq_a_depo AS ccc_chq_a_depo,
    mo1.denominacion AS mo1_denominacion,
    mo1.simbolo AS mo1_simbolo,
    tmc.id AS tmc_id,
    tmc.descripcion AS tmc_descripcion,
    tmc.signo AS tmc_signo,
    tmc.estado AS tmc_estado,
    tmc.gestiona_cheques AS tmc_gestiona_cheques,
    tmc.gestiona_ctas_bancarias AS tmc_gestiona_ctas_bancarias,
    cc.proyecto_id AS cc_proyecto_id,
    cc.proyecto_origen_id AS cc_proyecto_origen_id,
    cc.numero AS cc_numero,
    cc.fecha AS cc_fecha,
    to_char((cc.fecha)::timestamp with time zone, 'dd-mm-yyyy'::text) AS cc_fechax,
    tc.id AS tc_id,
    tc.descripcion AS tc_descripcion,
    tc.abreviado AS tc_abreviado,
    en.id AS en_id,
    en.razon_social AS en_razon_social,
    ca.denominacion AS ca_denominacion,
    ba2.denominacion AS ba2_denominacion,
    cch.id AS cch_id,
    cch.fecha AS cch_fecha,
    to_char((cch.fecha)::timestamp with time zone, 'dd-mm-yyyy'::text) AS cch_fechax,
    cch.numero AS cch_numero,
    tch.id AS tch_id,
    tch.descripcion AS tch_descripcion,
    tch.abreviado AS tch_abreviado,
    ccch.banco_id AS ccch_banco_id,
    ba3.denominacion AS ba3_denominacion,
    enh.id AS enh_id,
    enh.razon_social AS enh_razon_social,
    pr.nombre AS pr_nombre,
    prori.nombre AS prori_nombre
   FROM ((((((((((((((((public.cuentas_corrientes_caja ccc
     LEFT JOIN public.monedas mo1 ON ((ccc.moneda_id = mo1.id)))
     LEFT JOIN public.tipos_movimientos_caja tmc ON ((ccc.tipo_movimiento_caja_id = tmc.id)))
     LEFT JOIN public.cuentas_corrientes cc ON ((ccc.cuenta_corriente_id = cc.id)))
     LEFT JOIN public.tipos_comprobantes tc ON ((cc.tipo_comprobante_id = tc.id)))
     LEFT JOIN public.entidades en ON ((cc.entidad_id = en.id)))
     LEFT JOIN public.cuentas_bancarias cb ON ((ccc.cuenta_bancaria_id = cb.id)))
     LEFT JOIN public.bancos ba1 ON ((cb.banco_id = ba1.id)))
     LEFT JOIN public.cajas ca ON ((ccc.caja_id = ca.id)))
     LEFT JOIN public.bancos ba2 ON ((ccc.banco_id = ba2.id)))
     LEFT JOIN public.cuentas_corrientes_caja ccch ON ((public.fun_chq_asignado(ccc.id) = ccch.id)))
     LEFT JOIN public.cuentas_corrientes cch ON ((ccch.cuenta_corriente_id = cch.id)))
     LEFT JOIN public.tipos_comprobantes tch ON ((cch.tipo_comprobante_id = tch.id)))
     LEFT JOIN public.bancos ba3 ON ((ccch.banco_id = ba3.id)))
     LEFT JOIN public.entidades enh ON ((cch.entidad_id = enh.id)))
     LEFT JOIN public.proyectos pr ON ((cc.proyecto_id = pr.id)))
     LEFT JOIN public.proyectos prori ON ((cc.proyecto_origen_id = prori.id)))
  WHERE (ccc.estado = 0);


ALTER TABLE public.vi_cheques OWNER TO root;

--
-- Name: vi_cotizaciones; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_cotizaciones AS
 SELECT c.id AS c_id,
    c.fecha AS c_fecha,
    to_char((c.fecha)::timestamp with time zone, 'dd-mm-yyyy'::text) AS c_fechax,
    c.importe AS c_importe,
    m.id AS m_id,
    m.denominacion AS m_denominacion,
    m.codigo_afip AS m_codigo_afip,
    m.estado AS m_estado
   FROM (public.cotizaciones c
     JOIN public.monedas m ON ((c.moneda_id = m.id)))
  WHERE ((c.estado = 0) AND (m.estado = 0));


ALTER TABLE public.vi_cotizaciones OWNER TO root;

--
-- Name: vi_ctas_ctes; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_ctas_ctes AS
 SELECT cc.id AS cc_id,
    cc.tipo_comprobante_id AS cc_tipo_comprobante_id,
    cc.importe AS cc_importe,
    cc.moneda_id AS cc_moneda_id,
    cc.cotizacion_divisa AS cc_cotizacion_divisa,
    cc.importe_divisa AS cc_importe_divisa,
    cc.entidad_id AS cc_entidad_id,
    cc.detalle_proyecto_tipo_propiedad_id AS cc_detalle_proyecto_tipo_propiedad_id,
    cc.comentario AS cc_comentario,
    ((((((COALESCE(cc.docu_letra, ' '::character varying))::text || COALESCE((cc.docu_sucu)::text, ' '::text)) || '-'::text) || COALESCE((cc.docu_nume)::text, ' '::text)) || '  '::text) || (COALESCE(cc.comentario, ' '::character varying))::text) AS ccc_comentario,
    cc.proyecto_id AS cc_proyecto_id,
    cc.estado AS cc_estado,
    cc.usuario_id AS cc_usuario_id,
    cc.fecha AS cc_fecha,
    to_char((cc.fecha)::timestamp with time zone, 'dd-mm-yyyy'::text) AS cc_fechax,
    to_char((cc.fecha)::timestamp with time zone, 'DD-MM-YYYY'::text) AS cc_fecha_dmy,
    cc.fecha_registro AS cc_fecha_registro,
    cc.proyecto_origen_id AS cc_proyecto_origen_id,
    to_char(cc.fecha_registro, 'dd-mm-yyyy'::text) AS cc_fecha_registrox,
    cc.numero AS cc_numero,
    (((tc.abreviado)::text || ' '::text) || (cc.numero)::text) AS comp_nume,
    mo.simbolo AS mo_simbolo,
        CASE
            WHEN (tc.signo = 1) THEN public.fun_calcimportecaja(cc.id, 1)
            ELSE NULL::numeric
        END AS debe_mn_tot,
        CASE
            WHEN (tc.signo = '-1'::integer) THEN public.fun_calcimportecaja(cc.id, 1)
            ELSE NULL::numeric
        END AS haber_mn_tot,
        CASE
            WHEN (tc.signo = 1) THEN public.fun_calcimportecaja(cc.id, 2)
            ELSE NULL::numeric
        END AS debe_div_tot,
        CASE
            WHEN (tc.signo = '-1'::integer) THEN public.fun_calcimportecaja(cc.id, 2)
            ELSE NULL::numeric
        END AS haber_div_tot,
        CASE
            WHEN (tc.signo = 1) THEN to_char(NULLIF(public.fun_calcimportecaja(cc.id, 1), (0)::numeric), '9999,999,999D99'::text)
            ELSE NULL::text
        END AS debe_txt_mn_tot,
        CASE
            WHEN (tc.signo = '-1'::integer) THEN to_char(NULLIF(public.fun_calcimportecaja(cc.id, 1), (0)::numeric), '9999,999,999D99'::text)
            ELSE NULL::text
        END AS haber_txt_mn_tot,
        CASE
            WHEN (tc.signo = 1) THEN to_char(NULLIF(public.fun_calcimportecaja(cc.id, 2), (0)::numeric), '9999,999,999D99'::text)
            ELSE NULL::text
        END AS debe_txt_div_tot,
        CASE
            WHEN (tc.signo = '-1'::integer) THEN to_char(NULLIF(public.fun_calcimportecaja(cc.id, 2), (0)::numeric), '9999,999,999D99'::text)
            ELSE NULL::text
        END AS haber_txt_div_tot,
    0 AS saldo_mn,
    0 AS saldo_div,
    tc.descripcion AS tc_descripcion,
    tc.signo AS tc_signo,
    tc.abreviado AS tc_abreviado,
    tc.modelo AS tc_modelo,
    tc.concepto AS tc_concepto,
    tc.aplica_impu AS tc_aplica_impu,
    tc.tipos_entidad AS tc_tipos_entidad,
        CASE
            WHEN (tc.aplica_impu = 1) THEN 'APLICA'::text
            ELSE 'NO APLICA'::text
        END AS aplica_txt,
    public.fun_dameconceptocomprob(tc.concepto) AS concepto,
    e.razon_social AS e_razon_social,
    (((((e.calle)::text || ' '::text) || (e.numero)::text) || ' '::text) || (e.piso_departamento)::text) AS direccion,
    e.celular AS e_celular,
    e.whatsapp AS e_whatsapp,
    e.email AS e_email,
    e.observaciones AS e_observaciones,
    (((l.nombre)::text || ' '::text) || (pr.nombre)::text) AS local_prov,
    public.fun_dametiposentidades(e.id, 'E'::character varying) AS tipoentidad,
    p.nombre AS p_nombre,
    po.nombre AS po_nombre,
    u.nombre AS u_nombre,
    ptp.id AS ptp_id,
    ptp.tipo_propiedad_id AS ptp_tipo_propiedad_id,
    ptp.comentario AS ptp_comentario,
    ptp.coeficiente AS ptp_coeficiente,
    tp.descripcion AS tp_descripcion,
    public.fun_comprobsaldo(cc.id, 1) AS saldopesos,
    public.fun_comprobsaldo(cc.id, 2) AS saldodolar,
    ( SELECT count(*) AS count
           FROM public.relacion_ctas_ctes
          WHERE (((relacion_ctas_ctes.cuenta_corriente_id = cc.id) OR (relacion_ctas_ctes.relacion_id = cc.id)) AND (relacion_ctas_ctes.estado = 0))) AS tiene_apli
   FROM (((((((((((public.cuentas_corrientes cc
     LEFT JOIN public.tipos_comprobantes tc ON ((cc.tipo_comprobante_id = tc.id)))
     LEFT JOIN public.monedas mo ON ((cc.moneda_id = mo.id)))
     LEFT JOIN public.entidades e ON ((cc.entidad_id = e.id)))
     LEFT JOIN public.localidades l ON ((e.localidad_id = l.id)))
     LEFT JOIN public.provincias pr ON ((l.provincia_id = pr.id)))
     LEFT JOIN public.proyectos p ON ((cc.proyecto_id = p.id)))
     LEFT JOIN public.proyectos po ON ((cc.proyecto_origen_id = po.id)))
     LEFT JOIN public.usuarios u ON ((cc.usuario_id = u.id)))
     LEFT JOIN public.detalle_proyecto_tipos_propiedades dptp ON ((cc.detalle_proyecto_tipo_propiedad_id = dptp.id)))
     LEFT JOIN public.proyectos_tipos_propiedades ptp ON ((dptp.proyecto_tipo_propiedad_id = ptp.id)))
     LEFT JOIN public.tipos_propiedades tp ON ((ptp.tipo_propiedad_id = tp.id)))
  WHERE (cc.estado = 0);


ALTER TABLE public.vi_ctas_ctes OWNER TO root;

--
-- Name: vi_ctas_ctes_caja; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_ctas_ctes_caja AS
 SELECT ccc.id AS ccc_id,
    ccc.cuenta_corriente_id AS ccc_cuenta_corriente_id,
    ccc.importe AS ccc_importe,
    ccc.cuenta_bancaria_id AS ccc_cuenta_bancaria_id,
    ccc.cotizacion_divisa AS ccc_cotizacion_divisa,
    ccc.importe_divisa AS ccc_importe_divisa,
    ccc.comentario AS ccc_comentario,
    ccc.cta_cte_caja_origen_id AS ccc_cta_cte_caja_origen_id,
    ccc.banco_id AS ccc_banco_id,
    ba2.denominacion AS ba2_denominacion,
    ccc.fecha_emision AS ccc_fecha_emision,
    to_char((ccc.fecha_emision)::timestamp with time zone, 'dd-mm-yyyy'::text) AS ccc_fecha_emisionx,
    ccc.fecha_acreditacion AS ccc_fecha_acreditacion,
    to_char((ccc.fecha_acreditacion)::timestamp with time zone, 'dd-mm-yyyy'::text) AS ccc_fecha_acreditacionx,
    ccc.fecha_conciliacion AS ccc_fecha_conciliacion,
    to_char((ccc.fecha_conciliacion)::timestamp with time zone, 'dd-mm-yyyy'::text) AS ccc_fecha_conciliacionx,
    ccc.fecha_depositado AS ccc_fecha_depositado,
    to_char((ccc.fecha_depositado)::timestamp with time zone, 'dd-mm-yyyy'::text) AS ccc_fecha_depositadox,
    ccc.chequera_id AS ccc_chequera_id,
    ccc.serie AS ccc_serie,
    ccc.numero AS ccc_numero,
    ccc.chq_a_depo AS ccc_chq_a_depo,
        CASE
            WHEN (ccc.chq_a_depo = 1) THEN 'A DEPO.'::text
            ELSE '3EROS'::text
        END AS ccc_cartel_a_depo,
    ccc.moneda_id AS ccc_moneda_id,
    ccc.tipo_movimiento_caja_id AS ccc_tipo_movimiento_caja_id,
    ccc.e_chq AS ccc_e_chq,
    mo1.denominacion AS mo1_denominacion,
    mo1.simbolo AS mo1_simbolo,
    tmc.descripcion AS tmc_descripcion,
    tmc.signo AS tmc_signo,
    tmc.gestiona_cheques AS tmc_gestiona_cheques,
    tmc.gestiona_ctas_bancarias AS tmc_gestiona_ctas_bancarias,
    tmc.e_chq AS tmc_e_chq,
    tmc.mov_en_banco AS tmc_mov_en_banco,
    cb.denominacion AS cb_denominacion,
    cb.banco_id AS cb_banco_id,
    ba1.denominacion AS ba1_denominacion,
    ca.denominacion AS ca_denominacion,
    cc.estado AS cc_estado,
    cc.fecha AS cc_fecha,
    to_char((cc.fecha)::timestamp with time zone, 'dd-mm-yyyy'::text) AS cc_fechax,
    cc.proyecto_id AS cc_proyecto_id,
    pr.nombre AS pr_nombre,
    cc.entidad_id AS cc_entidad_id,
    en.razon_social AS en_razon_social,
    cc.proyecto_origen_id AS cc_proyecto_origen_id,
    cc.tipo_comprobante_id AS cc_tipo_comprobante_id,
    tc.abreviado AS tc_abreviado,
    cc.numero AS cc_numero,
    tc.signo AS tc_signo,
    tc.modelo AS tc_modelo,
    ccch.id AS ccch_id,
    cch.fecha AS cch_fecha,
    to_char((cch.fecha)::timestamp with time zone, 'dd-mm-yyyy'::text) AS cch_fechax,
    cch.proyecto_id AS cch_proyecto_id,
    cch.entidad_id AS cch_entidad_id,
    enh.razon_social AS enh_razon_social,
    cch.tipo_comprobante_id AS cch_tipo_comprobante_id,
    tch.abreviado AS tch_abreviado,
    cch.numero AS cch_numero,
    tch.signo AS tch_signo,
    tch.modelo AS tch_modelo,
    ba3.denominacion AS ba3_denominacion,
    ccch.numero AS ccch_numero,
    ccch.serie AS ccch_serie,
    ccch.fecha_emision AS ccch_fecha_emision,
    ccch.fecha_acreditacion AS ccch_fecha_acreditacion,
    ccch.fecha_conciliacion AS ccch_fecha_conciliacion,
    ccch.fecha_depositado AS ccch_fecha_depositado,
    to_char((ccch.fecha_emision)::timestamp with time zone, 'dd-mm-yyyy'::text) AS ccch_fecha_emisionx,
    to_char((ccch.fecha_acreditacion)::timestamp with time zone, 'dd-mm-yyyy'::text) AS ccch_fecha_acreditacionx,
    to_char((ccch.fecha_conciliacion)::timestamp with time zone, 'dd-mm-yyyy'::text) AS ccch_fecha_conciliacionx,
    to_char((ccch.fecha_depositado)::timestamp with time zone, 'dd-mm-yyyy'::text) AS ccch_fecha_depositadox,
    ccch.chq_a_depo AS ccch_chq_a_depo,
        CASE
            WHEN (ccch.chq_a_depo = 1) THEN 'A DEPO.'::text
            ELSE '3EROS'::text
        END AS ccch_cartel_a_depo,
        CASE
            WHEN ((tmc.signo = '-1'::integer) AND (ccc.moneda_id = 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS entradasmn,
        CASE
            WHEN ((tmc.signo = 1) AND (ccc.moneda_id = 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS salidasmn,
        CASE
            WHEN ((tmc.signo = '-1'::integer) AND (ccc.moneda_id <> 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS entradasus,
        CASE
            WHEN ((tmc.signo = 1) AND (ccc.moneda_id <> 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS salidasus,
    ccc.fecha_registro AS ccc_fecha_registro,
    to_char(ccc.fecha_registro, 'dd-mm-yyyy'::text) AS ccc_fecha_registrox,
        CASE
            WHEN ((ccc.signo_caja = 1) AND (ccc.moneda_id = 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS entradas_caja_mn,
        CASE
            WHEN ((ccc.signo_caja = '-1'::integer) AND (ccc.moneda_id = 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS salidas_caja_mn,
        CASE
            WHEN ((ccc.signo_caja = 1) AND (ccc.moneda_id <> 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS entradas_caja_us,
        CASE
            WHEN ((ccc.signo_caja = '-1'::integer) AND (ccc.moneda_id <> 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS salidas_caja_us,
        CASE
            WHEN ((ccc.signo_banco = 1) AND (ccc.moneda_id = 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS entradas_banco_mn,
        CASE
            WHEN ((ccc.signo_banco = '-1'::integer) AND (ccc.moneda_id = 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS salidas_banco_mn,
        CASE
            WHEN ((ccc.signo_banco = 1) AND (ccc.moneda_id <> 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS entradas_banco_us,
        CASE
            WHEN ((ccc.signo_banco = '-1'::integer) AND (ccc.moneda_id <> 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS salidas_banco_us,
    tmc.txt_info_caja AS tmc_txt_info_caja,
    tmc.tipo_mov AS tmc_tipo_mov,
    ccc.proyecto_id AS ccc_proyecto_id,
    prc.nombre AS prc_nombre,
    ccc.relacion_id AS ccc_relacion_id,
    tc.tipos_entidad AS tc_tipos_entidad,
    tmc.fidei_act_c_impu AS tmc_fidei_act_c_impu,
    tmc.fidei_act_s_impu AS tmc_fidei_act_s_impu,
    tmc.fidei_otr_c_impu AS tmc_fidei_otr_c_impu,
    tmc.fidei_otr_s_impu AS tmc_fidei_otr_s_impu,
    tc.signo_en_caja AS tc_signo_en_caja
   FROM ((((((((((((((((public.cuentas_corrientes_caja ccc
     LEFT JOIN public.monedas mo1 ON ((ccc.moneda_id = mo1.id)))
     LEFT JOIN public.tipos_movimientos_caja tmc ON ((ccc.tipo_movimiento_caja_id = tmc.id)))
     LEFT JOIN public.cuentas_bancarias cb ON ((ccc.cuenta_bancaria_id = cb.id)))
     LEFT JOIN public.bancos ba1 ON ((cb.banco_id = ba1.id)))
     LEFT JOIN public.cajas ca ON ((ccc.caja_id = ca.id)))
     LEFT JOIN public.bancos ba2 ON ((ccc.banco_id = ba2.id)))
     LEFT JOIN public.cuentas_corrientes cc ON ((ccc.cuenta_corriente_id = cc.id)))
     LEFT JOIN public.tipos_comprobantes tc ON ((cc.tipo_comprobante_id = tc.id)))
     LEFT JOIN public.entidades en ON ((cc.entidad_id = en.id)))
     LEFT JOIN public.cuentas_corrientes_caja ccch ON ((ccc.cta_cte_caja_origen_id = ccch.id)))
     LEFT JOIN public.cuentas_corrientes cch ON ((ccch.cuenta_corriente_id = cch.id)))
     LEFT JOIN public.tipos_comprobantes tch ON ((cch.tipo_comprobante_id = tch.id)))
     LEFT JOIN public.bancos ba3 ON ((ccch.banco_id = ba3.id)))
     LEFT JOIN public.entidades enh ON ((cch.entidad_id = enh.id)))
     LEFT JOIN public.proyectos pr ON ((cc.proyecto_id = pr.id)))
     LEFT JOIN public.proyectos prc ON ((ccc.proyecto_id = prc.id)))
  WHERE (ccc.estado = 0);


ALTER TABLE public.vi_ctas_ctes_caja OWNER TO root;

--
-- Name: vi_ctas_ctes_caja_ori; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_ctas_ctes_caja_ori AS
 SELECT ccc.id AS ccc_id,
    ccc.cuenta_corriente_id AS ccc_cuenta_corriente_id,
    ccc.importe AS ccc_importe,
    ccc.cuenta_bancaria_id AS ccc_cuenta_bancaria_id,
    ccc.cotizacion_divisa AS ccc_cotizacion_divisa,
    ccc.importe_divisa AS ccc_importe_divisa,
    ccc.comentario AS ccc_comentario,
    ccc.cta_cte_caja_origen_id AS ccc_cta_cte_caja_origen_id,
    ccc.banco_id AS ccc_banco_id,
    ba2.denominacion AS ba2_denominacion,
    ccc.fecha_emision AS ccc_fecha_emision,
    ccc.fecha_acreditacion AS ccc_fecha_acreditacion,
    ccc.fecha_conciliacion AS ccc_fecha_conciliacion,
    ccc.fecha_depositado AS ccc_fecha_depositado,
    ccc.chequera_id AS ccc_chequera_id,
    ccc.serie AS ccc_serie,
    ccc.numero AS ccc_numero,
    ccc.chq_a_depo AS ccc_chq_a_depo,
        CASE
            WHEN (ccc.chq_a_depo = 1) THEN 'A DEPO.'::text
            ELSE '3EROS'::text
        END AS ccc_cartel_a_depo,
    ccc.moneda_id AS ccc_moneda_id,
    ccc.tipo_movimiento_caja_id AS ccc_tipo_movimiento_caja_id,
    ccc.e_chq AS ccc_e_chq,
    mo1.denominacion AS mo1_denominacion,
    mo1.simbolo AS mo1_simbolo,
    tmc.descripcion AS tmc_descripcion,
    tmc.signo AS tmc_signo,
    tmc.gestiona_cheques AS tmc_gestiona_cheques,
    tmc.gestiona_ctas_bancarias AS tmc_gestiona_ctas_bancarias,
    tmc.e_chq AS tmc_e_chq,
    cb.denominacion AS cb_denominacion,
    cb.banco_id AS cb_banco_id,
    ba1.denominacion AS ba1_denominacion,
    ca.denominacion AS ca_denominacion,
    cc.estado AS cc_estado,
    cc.fecha AS cc_fecha,
    cc.proyecto_id AS cc_proyecto_id,
    pr.nombre AS pr_nombre,
    cc.entidad_id AS cc_entidad_id,
    en.razon_social AS en_razon_social,
    cc.tipo_comprobante_id AS cc_tipo_comprobante_id,
    tc.abreviado AS tc_abreviado,
    cc.numero AS cc_numero,
    tc.signo AS tc_signo,
    tc.modelo AS tc_modelo,
    ccch.id AS ccch_id,
    cch.fecha AS cch_fecha,
    cch.proyecto_id AS cch_proyecto_id,
    cch.entidad_id AS cch_entidad_id,
    enh.razon_social AS enh_razon_social,
    cch.tipo_comprobante_id AS cch_tipo_comprobante_id,
    tch.abreviado AS tch_abreviado,
    cch.numero AS cch_numero,
    tch.signo AS tch_signo,
    tch.modelo AS tch_modelo,
    ba3.denominacion AS ba3_denominacion,
    ccch.numero AS ccch_numero,
    ccch.serie AS ccch_serie,
    ccch.fecha_emision AS ccch_fecha_emision,
    ccch.fecha_acreditacion AS ccch_fecha_acreditacion,
    ccch.fecha_conciliacion AS ccch_fecha_conciliacion,
    ccch.fecha_depositado AS ccch_fecha_depositado,
    ccch.chq_a_depo AS ccch_chq_a_depo,
        CASE
            WHEN (ccch.chq_a_depo = 1) THEN 'A DEPO.'::text
            ELSE '3EROS'::text
        END AS ccch_cartel_a_depo,
        CASE
            WHEN ((tc.signo = '-1'::integer) AND (ccc.moneda_id = 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS entradasmn,
        CASE
            WHEN ((tc.signo = 1) AND (ccc.moneda_id = 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS salidasmn,
        CASE
            WHEN ((tc.signo = '-1'::integer) AND (ccc.moneda_id <> 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS entradasus,
        CASE
            WHEN ((tc.signo = 1) AND (ccc.moneda_id <> 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS salidasus,
    ccc.fecha_registro AS ccc_fecha_registro
   FROM (((((((((((((((public.cuentas_corrientes_caja ccc
     LEFT JOIN public.monedas mo1 ON ((ccc.moneda_id = mo1.id)))
     LEFT JOIN public.tipos_movimientos_caja tmc ON ((ccc.tipo_movimiento_caja_id = tmc.id)))
     LEFT JOIN public.cuentas_bancarias cb ON ((ccc.cuenta_bancaria_id = cb.id)))
     LEFT JOIN public.bancos ba1 ON ((cb.banco_id = ba1.id)))
     LEFT JOIN public.cajas ca ON ((ccc.caja_id = ca.id)))
     LEFT JOIN public.bancos ba2 ON ((ccc.banco_id = ba2.id)))
     LEFT JOIN public.cuentas_corrientes cc ON ((ccc.cuenta_corriente_id = cc.id)))
     LEFT JOIN public.tipos_comprobantes tc ON ((cc.tipo_comprobante_id = tc.id)))
     LEFT JOIN public.entidades en ON ((cc.entidad_id = en.id)))
     LEFT JOIN public.cuentas_corrientes_caja ccch ON ((ccc.cta_cte_caja_origen_id = ccch.id)))
     LEFT JOIN public.cuentas_corrientes cch ON ((ccch.cuenta_corriente_id = cch.id)))
     LEFT JOIN public.tipos_comprobantes tch ON ((cch.tipo_comprobante_id = tch.id)))
     LEFT JOIN public.bancos ba3 ON ((ccch.banco_id = ba3.id)))
     LEFT JOIN public.entidades enh ON ((cch.entidad_id = enh.id)))
     LEFT JOIN public.proyectos pr ON ((cc.proyecto_id = pr.id)))
  WHERE (ccc.estado = 0);


ALTER TABLE public.vi_ctas_ctes_caja_ori OWNER TO root;

--
-- Name: vi_ctas_ctes_caja_ori_01; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_ctas_ctes_caja_ori_01 AS
 SELECT ccc.id AS ccc_id,
    ccc.cuenta_corriente_id AS ccc_cuenta_corriente_id,
    ccc.importe AS ccc_importe,
    ccc.cuenta_bancaria_id AS ccc_cuenta_bancaria_id,
    ccc.cotizacion_divisa AS ccc_cotizacion_divisa,
    ccc.importe_divisa AS ccc_importe_divisa,
    ccc.comentario AS ccc_comentario,
    ccc.cta_cte_caja_origen_id AS ccc_cta_cte_caja_origen_id,
    ccc.banco_id AS ccc_banco_id,
    ba2.denominacion AS ba2_denominacion,
    ccc.fecha_emision AS ccc_fecha_emision,
    ccc.fecha_acreditacion AS ccc_fecha_acreditacion,
    ccc.fecha_conciliacion AS ccc_fecha_conciliacion,
    ccc.fecha_depositado AS ccc_fecha_depositado,
    ccc.chequera_id AS ccc_chequera_id,
    ccc.serie AS ccc_serie,
    ccc.numero AS ccc_numero,
    ccc.chq_a_depo AS ccc_chq_a_depo,
        CASE
            WHEN (ccc.chq_a_depo = 1) THEN 'A DEPO.'::text
            ELSE '3EROS'::text
        END AS ccc_cartel_a_depo,
    ccc.moneda_id AS ccc_moneda_id,
    ccc.tipo_movimiento_caja_id AS ccc_tipo_movimiento_caja_id,
    ccc.e_chq AS ccc_e_chq,
    mo1.denominacion AS mo1_denominacion,
    mo1.simbolo AS mo1_simbolo,
    tmc.descripcion AS tmc_descripcion,
    tmc.signo AS tmc_signo,
    tmc.gestiona_cheques AS tmc_gestiona_cheques,
    tmc.gestiona_ctas_bancarias AS tmc_gestiona_ctas_bancarias,
    tmc.e_chq AS tmc_e_chq,
    cb.denominacion AS cb_denominacion,
    cb.banco_id AS cb_banco_id,
    ba1.denominacion AS ba1_denominacion,
    ca.denominacion AS ca_denominacion,
    cc.estado AS cc_estado,
    cc.fecha AS cc_fecha,
    cc.proyecto_id AS cc_proyecto_id,
    pr.nombre AS pr_nombre,
    cc.entidad_id AS cc_entidad_id,
    en.razon_social AS en_razon_social,
    cc.tipo_comprobante_id AS cc_tipo_comprobante_id,
    tc.abreviado AS tc_abreviado,
    cc.numero AS cc_numero,
    tc.signo AS tc_signo,
    tc.modelo AS tc_modelo,
    ccch.id AS ccch_id,
    cch.fecha AS cch_fecha,
    cch.proyecto_id AS cch_proyecto_id,
    cch.entidad_id AS cch_entidad_id,
    enh.razon_social AS enh_razon_social,
    cch.tipo_comprobante_id AS cch_tipo_comprobante_id,
    tch.abreviado AS tch_abreviado,
    cch.numero AS cch_numero,
    tch.signo AS tch_signo,
    tch.modelo AS tch_modelo,
    ba3.denominacion AS ba3_denominacion,
    ccch.numero AS ccch_numero,
    ccch.serie AS ccch_serie,
    ccch.fecha_emision AS ccch_fecha_emision,
    ccch.fecha_acreditacion AS ccch_fecha_acreditacion,
    ccch.fecha_conciliacion AS ccch_fecha_conciliacion,
    ccch.fecha_depositado AS ccch_fecha_depositado,
    ccch.chq_a_depo AS ccch_chq_a_depo,
        CASE
            WHEN (ccch.chq_a_depo = 1) THEN 'A DEPO.'::text
            ELSE '3EROS'::text
        END AS ccch_cartel_a_depo,
        CASE
            WHEN ((tmc.signo = '-1'::integer) AND (ccc.moneda_id = 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS entradasmn,
        CASE
            WHEN ((tmc.signo = 1) AND (ccc.moneda_id = 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS salidasmn,
        CASE
            WHEN ((tmc.signo = '-1'::integer) AND (ccc.moneda_id <> 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS entradasus,
        CASE
            WHEN ((tmc.signo = 1) AND (ccc.moneda_id <> 1)) THEN ccc.importe
            ELSE (0)::numeric
        END AS salidasus,
    ccc.fecha_registro AS ccc_fecha_registro
   FROM (((((((((((((((public.cuentas_corrientes_caja ccc
     LEFT JOIN public.monedas mo1 ON ((ccc.moneda_id = mo1.id)))
     LEFT JOIN public.tipos_movimientos_caja tmc ON ((ccc.tipo_movimiento_caja_id = tmc.id)))
     LEFT JOIN public.cuentas_bancarias cb ON ((ccc.cuenta_bancaria_id = cb.id)))
     LEFT JOIN public.bancos ba1 ON ((cb.banco_id = ba1.id)))
     LEFT JOIN public.cajas ca ON ((ccc.caja_id = ca.id)))
     LEFT JOIN public.bancos ba2 ON ((ccc.banco_id = ba2.id)))
     LEFT JOIN public.cuentas_corrientes cc ON ((ccc.cuenta_corriente_id = cc.id)))
     LEFT JOIN public.tipos_comprobantes tc ON ((cc.tipo_comprobante_id = tc.id)))
     LEFT JOIN public.entidades en ON ((cc.entidad_id = en.id)))
     LEFT JOIN public.cuentas_corrientes_caja ccch ON ((ccc.cta_cte_caja_origen_id = ccch.id)))
     LEFT JOIN public.cuentas_corrientes cch ON ((ccch.cuenta_corriente_id = cch.id)))
     LEFT JOIN public.tipos_comprobantes tch ON ((cch.tipo_comprobante_id = tch.id)))
     LEFT JOIN public.bancos ba3 ON ((ccch.banco_id = ba3.id)))
     LEFT JOIN public.entidades enh ON ((cch.entidad_id = enh.id)))
     LEFT JOIN public.proyectos pr ON ((cc.proyecto_id = pr.id)))
  WHERE (ccc.estado = 0);


ALTER TABLE public.vi_ctas_ctes_caja_ori_01 OWNER TO root;

--
-- Name: vi_cuentas_bancarias; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_cuentas_bancarias AS
 SELECT cb.id AS cb_id,
    cb.denominacion AS cb_denominacion,
    cb.banco_id AS cb_banco_id,
    ba.denominacion AS ba_denominacion,
    cb.cbu AS cb_cbu,
    cb.alias AS cb_alias,
    cb.tipo AS cb_tipo,
        CASE
            WHEN ((cb.tipo)::text = 'C'::text) THEN 'CUENTA CORRIENTE'::text
            WHEN ((cb.tipo)::text = 'A'::text) THEN 'CAJA DE AHORRO'::text
            ELSE ''::text
        END AS tipocuenta,
    cb.proyecto_id AS cb_proyecto_id
   FROM (public.cuentas_bancarias cb
     LEFT JOIN public.bancos ba ON ((cb.banco_id = ba.id)))
  WHERE (cb.estado = 0);


ALTER TABLE public.vi_cuentas_bancarias OWNER TO root;

--
-- Name: vi_detalle_proyectos_tipos_propiedades; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_detalle_proyectos_tipos_propiedades AS
 SELECT dptp.id AS dptp_id,
    dptp.coeficiente AS dptp_coeficiente,
    e.id AS e_id,
    e.razon_social AS e_razon_social,
    (((((e.calle)::text || ' '::text) || (e.numero)::text) || ' '::text) || (e.piso_departamento)::text) AS direccion,
    e.celular AS e_celular,
    e.whatsapp AS e_whatsapp,
    e.email AS e_email,
    e.observaciones AS e_observaciones,
    e.estado AS e_estado,
    (((l.nombre)::text || ' '::text) || (p.nombre)::text) AS local_prov,
    ptp.id AS ptp_id,
    ptp.cantidad AS ptp_cantidad,
    ptp.comentario AS ptp_comentario,
    ptp.coeficiente AS ptp_coeficiente,
    pr.id AS pr_id,
    pr.nombre AS pr_nombre,
    pr.fecha_inicio AS pr_fecha_inicio,
    pr.fecha_finalizacion AS pr_fecha_finalizacion,
    to_char((pr.fecha_inicio)::timestamp with time zone, 'dd-mm-yyyy'::text) AS pr_fecha_iniciox,
    to_char((pr.fecha_finalizacion)::timestamp with time zone, 'dd-mm-yyyy'::text) AS pr_fecha_finalizacionx,
    pr.comentario AS pr_comentario,
    (((pr.calle)::text || ' '::text) || (pr.numero)::text) AS direccion1,
    l1.id AS l1_id,
    p1.id AS p1_id,
    (((l1.nombre)::text || ' '::text) || (p1.nombre)::text) AS local_prov1,
    tpr.id AS tpr_id,
    tpr.descripcion AS tpr_descripcion,
    tp.id AS tp_id,
    tp.descripcion AS tp_descripcion,
    tp.obligatorio AS tp_obligatorio,
    too.id AS too_id,
    too.descripcion AS too_descripcion,
    dptp.estado AS dptp_estado
   FROM ((((((((((public.proyectos_tipos_propiedades ptp
     LEFT JOIN public.proyectos pr ON ((ptp.proyecto_id = pr.id)))
     LEFT JOIN public.localidades l ON ((pr.localidad_id = l.id)))
     LEFT JOIN public.provincias p ON ((l.provincia_id = p.id)))
     LEFT JOIN public.tipos_proyectos tpr ON ((pr.tipo_proyecto_id = tpr.id)))
     LEFT JOIN public.tipos_propiedades tp ON ((ptp.tipo_propiedad_id = tp.id)))
     LEFT JOIN public.detalle_proyecto_tipos_propiedades dptp ON ((ptp.id = dptp.proyecto_tipo_propiedad_id)))
     LEFT JOIN public.entidades e ON ((dptp.entidad_id = e.id)))
     LEFT JOIN public.localidades l1 ON ((e.localidad_id = l1.id)))
     LEFT JOIN public.provincias p1 ON ((l1.provincia_id = p1.id)))
     LEFT JOIN public.tipos_obras too ON ((pr.tipo_obra_id = too.id)))
  WHERE (ptp.estado = 0);


ALTER TABLE public.vi_detalle_proyectos_tipos_propiedades OWNER TO root;

--
-- Name: vi_entidades; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_entidades AS
 SELECT e.id AS e_id,
    e.razon_social AS e_razon_social,
    e.cuit AS e_cuit,
    e.situacion_iva AS e_situacion_iva,
    (((((e.calle)::text || ' '::text) || (e.numero)::text) || ' '::text) || (e.piso_departamento)::text) AS direccion,
    e.celular AS e_celular,
    e.whatsapp AS e_whatsapp,
    e.email AS e_email,
    e.observaciones AS e_observaciones,
    l.id AS l_id,
    l.nombre AS l_nombre,
    p.id AS p_id,
    p.nombre AS p_nombre,
    (((l.nombre)::text || ' '::text) || (p.nombre)::text) AS local_prov,
    public.fun_dametiposentidades(e.id, 'E'::character varying) AS tipoentidad,
    public.fun_dametiposentidades(e.id, 'N'::character varying) AS e_tipos_entidad,
    ( SELECT count(*) AS count
           FROM public.cuentas_corrientes
          WHERE ((cuentas_corrientes.estado = 0) AND (cuentas_corrientes.entidad_id = e.id))) AS cant_cc
   FROM ((public.entidades e
     LEFT JOIN public.localidades l ON ((e.localidad_id = l.id)))
     LEFT JOIN public.provincias p ON ((l.provincia_id = p.id)))
  WHERE (e.estado = 0);


ALTER TABLE public.vi_entidades OWNER TO root;

--
-- Name: vi_localidades; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_localidades AS
 SELECT lo.id AS lo_id,
    lo.nombre AS lo_nombre,
    lo.cp AS lo_cp,
    lo.estado AS lo_estado,
    pr.id AS pr_id,
    pr.nombre AS pr_nombre,
    concat(lo.nombre, ' - ', pr.nombre) AS loca_prov
   FROM (public.localidades lo
     JOIN public.provincias pr ON ((lo.provincia_id = pr.id)));


ALTER TABLE public.vi_localidades OWNER TO root;

--
-- Name: vi_materiales; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vi_materiales AS
 SELECT m.id AS m_id,
    m.descripcion AS m_descripcion,
    m.unidad AS m_unidad,
    m.stock_minimo AS m_stock_minimo,
    m.ean_13 AS m_ean_13,
    m.cantidad_uni_compra AS m_cantidad_uni_compra,
    m.peso_uni_compra AS m_peso_uni_compra
   FROM public.materiales m
  WHERE (m.estado = 0);


ALTER TABLE public.vi_materiales OWNER TO postgres;

--
-- Name: vi_mov_bancarios; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_mov_bancarios AS
 SELECT mb.id AS mb_id,
    mb.fecha AS mb_fecha,
    to_char((mb.fecha)::timestamp with time zone, 'dd-mm-yyyy'::text) AS mb_fechax,
    mb.importe AS mb_importe,
    (mb.importe * (tmc.signo)::numeric) AS importe_c_signo,
    mb.comentario AS mb_comentario,
    cb.id AS cb_id,
    cb.denominacion AS cb_denominacion,
    cb.proyecto_id AS cb_proyecto_id,
    ba.id AS ba_id,
    ba.denominacion AS ba_denominacion,
    tmc.id AS tmc_id,
    tmc.descripcion AS tmc_descripcion,
    tmc.signo AS tmc_signo,
    tmc.estado AS tmc_estado,
    tmc.gestiona_banco AS tmc_gestiona_banco,
    cc.id AS cc_id,
    mb.estado AS mb_estado,
    mo.id AS mo_id,
    mo.denominacion AS mo_denominacion,
    mb.cotizacion_divisa AS mb_cotizacion_divisa,
    mb.importe_divisa AS mb_importe_divisa,
    mb.numero AS mb_numero
   FROM (((((public.movimientos_bancarios mb
     JOIN public.cuentas_bancarias cb ON ((mb.cuenta_bancaria_id = cb.id)))
     JOIN public.bancos ba ON ((cb.banco_id = ba.id)))
     JOIN public.tipos_movimientos_caja tmc ON ((mb.tipo_movimiento_caja_id = tmc.id)))
     LEFT JOIN public.cuentas_corrientes cc ON ((mb.cuenta_corriente_id = cc.id)))
     JOIN public.monedas mo ON ((mb.moneda_id = mo.id)));


ALTER TABLE public.vi_mov_bancarios OWNER TO root;

--
-- Name: vi_presupuestos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vi_presupuestos AS
 SELECT pre.id AS pre_id,
    pre.titulo AS pre_titulo,
    pre.comentario AS pre_comentario,
    pre.importe_inicial AS pre_importe_inicial,
    pre.importe_final AS pre_importe_final,
    mo.id AS mo_id,
    mo.denominacion AS mo_denominacion,
    pre.fecha_inicio AS pre_fecha_inicio,
    to_char((pre.fecha_inicio)::timestamp with time zone, 'DD-MM-YYYY'::text) AS pre_fecha_inicio_dmy,
    pre.fecha_final AS pre_fecha_final,
    to_char((pre.fecha_final)::timestamp with time zone, 'DD-MM-YYYY'::text) AS pre_fecha_final_dmy,
    e.id AS e_id,
    e.razon_social AS e_razon_social,
    (((((e.calle)::text || ' '::text) || (e.numero)::text) || ' '::text) || (e.piso_departamento)::text) AS direccion,
    e.celular AS e_celular,
    e.whatsapp AS e_whatsapp,
    e.email AS e_email,
    e.observaciones AS e_observaciones,
    pro.id AS pro_id,
    pro.estado AS pro_estado,
    pro.nombre AS pro_nombre,
    ( SELECT count(*) AS count
           FROM public.relacion_presu_ctactes
          WHERE (relacion_presu_ctactes.presupuesto_id = pre.id)) AS cant_cc
   FROM (((public.presupuestos pre
     LEFT JOIN public.entidades e ON ((pre.entidad_id = e.id)))
     LEFT JOIN public.proyectos pro ON ((pre.proyecto_id = pro.id)))
     LEFT JOIN public.monedas mo ON ((pre.moneda_id = mo.id)))
  WHERE (pre.estado = 0);


ALTER TABLE public.vi_presupuestos OWNER TO postgres;

--
-- Name: vi_proyectos; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_proyectos AS
 SELECT p.id AS p_id,
    p.nombre AS p_nombre,
    p.fecha_inicio AS p_fecha_inicio,
    p.fecha_finalizacion AS p_fecha_finalizacion,
    to_char((p.fecha_inicio)::timestamp with time zone, 'dd-mm-yyyy'::text) AS p_fecha_iniciox,
    to_char((p.fecha_finalizacion)::timestamp with time zone, 'dd-mm-yyyy'::text) AS p_fecha_finalizacionx,
    p.comentario AS p_comentario,
    p.calle AS p_calle,
    p.numero AS p_numero,
    (((p.calle)::text || ' '::text) || (p.numero)::text) AS direccion,
    p.localidad_id AS p_localidad_id,
    (((l.nombre)::text || ' '::text) || (pr.nombre)::text) AS local_prov,
    l.id AS l_id,
    l.nombre AS l_nombre,
    pr.id AS pr_id,
    pr.nombre AS pr_nombre,
    t.id AS t_id,
    t.descripcion AS t_descripcion,
    tob.id AS tob_id,
    tob.descripcion AS tob_descripcion
   FROM ((((public.proyectos p
     LEFT JOIN public.localidades l ON ((p.localidad_id = l.id)))
     LEFT JOIN public.provincias pr ON ((l.provincia_id = pr.id)))
     LEFT JOIN public.tipos_proyectos t ON ((p.tipo_proyecto_id = t.id)))
     LEFT JOIN public.tipos_obras tob ON ((p.tipo_obra_id = tob.id)))
  WHERE (p.estado = 0);


ALTER TABLE public.vi_proyectos OWNER TO root;

--
-- Name: vi_proyectos_entidades; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_proyectos_entidades AS
 SELECT pe.id AS pe_id,
    p.id AS p_id,
    p.nombre AS p_nombre,
    p.fecha_inicio AS p_fecha_inicio,
    p.fecha_finalizacion AS p_fecha_finalizacion,
    to_char((p.fecha_inicio)::timestamp with time zone, 'dd-mm-yyyy'::text) AS p_fecha_iniciox,
    to_char((p.fecha_finalizacion)::timestamp with time zone, 'dd-mm-yyyy'::text) AS p_fecha_finalizacionx,
    p.comentario AS p_comentario,
    p.calle AS p_calle,
    p.numero AS p_numero,
    (((p.calle)::text || ' '::text) || (p.numero)::text) AS direccion,
    (((l.nombre)::text || ' '::text) || (pr.nombre)::text) AS local_prov,
    e.id AS e_id,
    e.razon_social AS e_razon_social,
    (((((e.calle)::text || ' '::text) || (e.numero)::text) || ' '::text) || (e.piso_departamento)::text) AS direccion1,
    (((l1.nombre)::text || ' '::text) || (pr1.nombre)::text) AS local_prov1,
    e.celular AS e_celular,
    e.whatsapp AS e_whatsapp,
    e.email AS e_email,
    t.id AS t_id,
    t.descripcion AS t_descripcion,
    tob.id AS tob_id,
    tob.descripcion AS tob_descripcion,
    public.fun_dametiposentidades(e.id, 'E'::character varying) AS tipoentidad,
    e.tipos_entidad AS e_tipos_entidad,
    e.estado AS e_estado,
    pe.estado AS pe_estado
   FROM ((((((((public.proyectos_entidades pe
     LEFT JOIN public.proyectos p ON ((pe.proyecto_id = p.id)))
     LEFT JOIN public.entidades e ON ((pe.entidad_id = e.id)))
     LEFT JOIN public.localidades l ON ((p.localidad_id = l.id)))
     LEFT JOIN public.provincias pr ON ((l.provincia_id = pr.id)))
     LEFT JOIN public.localidades l1 ON ((e.localidad_id = l1.id)))
     LEFT JOIN public.provincias pr1 ON ((l1.provincia_id = pr1.id)))
     LEFT JOIN public.tipos_proyectos t ON ((p.tipo_proyecto_id = t.id)))
     LEFT JOIN public.tipos_obras tob ON ((p.tipo_obra_id = tob.id)))
  WHERE (pe.estado = 0);


ALTER TABLE public.vi_proyectos_entidades OWNER TO root;

--
-- Name: vi_proyectos_tipos_propiedades; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_proyectos_tipos_propiedades AS
 SELECT ptp.id AS ptp_id,
    ptp.coeficiente AS ptp_coeficiente,
    ptp.comentario AS ptp_comentario,
    pr.id AS pr_id,
    pr.nombre AS pr_nombre,
    pr.fecha_inicio AS pr_fecha_inicio,
    pr.fecha_finalizacion AS pr_fecha_finalizacion,
    to_char((pr.fecha_inicio)::timestamp with time zone, 'dd-mm-yyyy'::text) AS pr_fecha_iniciox,
    to_char((pr.fecha_finalizacion)::timestamp with time zone, 'dd-mm-yyyy'::text) AS pr_fecha_finalizacionx,
    pr.comentario AS pr_comentario,
    (((pr.calle)::text || ' '::text) || (pr.numero)::text) AS direccion,
    l.id AS l_id,
    p.id AS p_id,
    (((l.nombre)::text || ' '::text) || (p.nombre)::text) AS local_prov,
    tpr.id AS tpr_id,
    tpr.descripcion AS tpr_descripcion,
    tp.id AS tp_id,
    tp.descripcion AS tp_descripcion,
    tp.obligatorio AS tp_obligatorio,
        CASE
            WHEN (tp.obligatorio = 1) THEN 'Obligatorio'::text
            ELSE ''::text
        END AS tipo_obli,
    tob.id AS tob_id,
    tob.descripcion AS tob_descripcion
   FROM ((((((public.proyectos_tipos_propiedades ptp
     LEFT JOIN public.proyectos pr ON ((ptp.proyecto_id = pr.id)))
     LEFT JOIN public.localidades l ON ((pr.localidad_id = l.id)))
     LEFT JOIN public.provincias p ON ((l.provincia_id = p.id)))
     LEFT JOIN public.tipos_proyectos tpr ON ((pr.tipo_proyecto_id = tpr.id)))
     LEFT JOIN public.tipos_propiedades tp ON ((ptp.tipo_propiedad_id = tp.id)))
     LEFT JOIN public.tipos_obras tob ON ((pr.tipo_obra_id = tob.id)))
  WHERE (ptp.estado = 0);


ALTER TABLE public.vi_proyectos_tipos_propiedades OWNER TO root;

--
-- Name: vi_tipos_comprobantes; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_tipos_comprobantes AS
 SELECT tipos_comprobantes.id,
    tipos_comprobantes.descripcion,
    tipos_comprobantes.signo,
    tipos_comprobantes.abreviado,
    tipos_comprobantes.afecta_caja,
    tipos_comprobantes.numero,
        CASE
            WHEN (tipos_comprobantes.signo = '-1'::integer) THEN 'HABER'::text
            WHEN (tipos_comprobantes.signo = 1) THEN 'DEBE'::text
            ELSE ''::text
        END AS tiposigno,
        CASE
            WHEN (tipos_comprobantes.afecta_caja = 1) THEN 'AFECTA CAJA'::text
            ELSE 'NO AFECTA CAJA'::text
        END AS afectacaja,
        CASE
            WHEN (tipos_comprobantes.aplica_impu = 1) THEN 'APLICA'::text
            ELSE 'NO APLICA'::text
        END AS aplica,
    public.fun_dametiposentidades(tipos_comprobantes.id, 'C'::character varying) AS tipoentidad,
    public.fun_damemodelocomprob(tipos_comprobantes.modelo) AS modelocomprob,
    public.fun_dameconceptocomprob(tipos_comprobantes.concepto) AS conceptocomprob,
    tipos_comprobantes.modelo
   FROM public.tipos_comprobantes
  WHERE (tipos_comprobantes.estado = 0);


ALTER TABLE public.vi_tipos_comprobantes OWNER TO root;

--
-- Name: vi_tipos_obras; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_tipos_obras AS
 SELECT tipos_obras.id,
    tipos_obras.descripcion
   FROM public.tipos_obras
  WHERE (tipos_obras.estado = 0);


ALTER TABLE public.vi_tipos_obras OWNER TO root;

--
-- Name: vi_tipos_propiedades; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_tipos_propiedades AS
 SELECT tipos_propiedades.id,
    tipos_propiedades.descripcion,
    tipos_propiedades.obligatorio,
        CASE
            WHEN (tipos_propiedades.obligatorio = 1) THEN 'Obligatorio'::text
            ELSE ''::text
        END AS tipo_obli
   FROM public.tipos_propiedades
  WHERE (tipos_propiedades.estado = 0);


ALTER TABLE public.vi_tipos_propiedades OWNER TO root;

--
-- Name: vi_usuarios; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.vi_usuarios AS
 SELECT usuarios.id,
    usuarios.nombre,
    usuarios.usuario,
    usuarios.password,
    usuarios.nivel
   FROM public.usuarios
  WHERE (usuarios.estado = 0);


ALTER TABLE public.vi_usuarios OWNER TO root;

--
-- Name: cajas id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cajas ALTER COLUMN id SET DEFAULT nextval('public.cajas_id_seq'::regclass);


--
-- Name: chequeras id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.chequeras ALTER COLUMN id SET DEFAULT nextval('public.chequeras_id_seq'::regclass);


--
-- Name: conceptos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conceptos ALTER COLUMN id SET DEFAULT nextval('public.conceptos_id_seq'::regclass);


--
-- Name: cotizaciones id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cotizaciones ALTER COLUMN id SET DEFAULT nextval('public.cotizaciones_id_seq'::regclass);


--
-- Name: cuentas_bancarias id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_bancarias ALTER COLUMN id SET DEFAULT nextval('public.cuentas_bancarias_id_seq'::regclass);


--
-- Name: cuentas_corrientes id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes ALTER COLUMN id SET DEFAULT nextval('public.cuentas_corrientes_id_seq'::regclass);


--
-- Name: cuentas_corrientes_caja id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes_caja ALTER COLUMN id SET DEFAULT nextval('public.cuentas_corrientes_caja_id_seq'::regclass);


--
-- Name: detalle_proyecto_tipos_propiedades id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.detalle_proyecto_tipos_propiedades ALTER COLUMN id SET DEFAULT nextval('public.detalle_proyecto_tipos_propiedades_id_seq'::regclass);


--
-- Name: entidades id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.entidades ALTER COLUMN id SET DEFAULT nextval('public.entidades_id_seq'::regclass);


--
-- Name: informes_proyectos id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.informes_proyectos ALTER COLUMN id SET DEFAULT nextval('public.informes_proyectos_id_seq'::regclass);


--
-- Name: localidades id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.localidades ALTER COLUMN id SET DEFAULT nextval('public.localidades_id_seq'::regclass);


--
-- Name: materiales id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.materiales ALTER COLUMN id SET DEFAULT nextval('public.materiales_id_seq'::regclass);


--
-- Name: monedas id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.monedas ALTER COLUMN id SET DEFAULT nextval('public.monedas_id_seq'::regclass);


--
-- Name: movimientos_bancarios id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_bancarios ALTER COLUMN id SET DEFAULT nextval('public.movimientos_bancarios_id_seq'::regclass);


--
-- Name: movimientos_cheques id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.movimientos_cheques ALTER COLUMN id SET DEFAULT nextval('public.movimientos_cheques_id_seq'::regclass);


--
-- Name: permisos id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.permisos ALTER COLUMN id SET DEFAULT nextval('public.permisos_id_seq'::regclass);


--
-- Name: permisos_usuarios id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.permisos_usuarios ALTER COLUMN id SET DEFAULT nextval('public.permisos_usuarios_id_seq'::regclass);


--
-- Name: provincias id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.provincias ALTER COLUMN id SET DEFAULT nextval('public.provincias_id_seq'::regclass);


--
-- Name: proyectos id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.proyectos ALTER COLUMN id SET DEFAULT nextval('public.proyectos_id_seq'::regclass);


--
-- Name: proyectos_entidades id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.proyectos_entidades ALTER COLUMN id SET DEFAULT nextval('public.proyectos_entidades_id_seq'::regclass);


--
-- Name: proyectos_tipos_propiedades id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.proyectos_tipos_propiedades ALTER COLUMN id SET DEFAULT nextval('public.proyectos_tipos_propiedades_id_seq'::regclass);


--
-- Name: relacion_ctas_ctes id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.relacion_ctas_ctes ALTER COLUMN id SET DEFAULT nextval('public.relacion_ctas_ctes_id_seq'::regclass);


--
-- Name: tipos_comprobantes id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tipos_comprobantes ALTER COLUMN id SET DEFAULT nextval('public.tipos_comprobantes_id_seq'::regclass);


--
-- Name: tipos_entidades id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tipos_entidades ALTER COLUMN id SET DEFAULT nextval('public.tipos_entidades_id_seq'::regclass);


--
-- Name: tipos_movimientos_caja id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tipos_movimientos_caja ALTER COLUMN id SET DEFAULT nextval('public.tipos_movimientos_caja_id_seq'::regclass);


--
-- Name: tipos_obras id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tipos_obras ALTER COLUMN id SET DEFAULT nextval('public.tipos_obras_id_seq'::regclass);


--
-- Name: tipos_propiedades id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tipos_propiedades ALTER COLUMN id SET DEFAULT nextval('public.tipos_propiedades_id_seq'::regclass);


--
-- Name: tipos_proyectos id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tipos_proyectos ALTER COLUMN id SET DEFAULT nextval('public.tipos_proyectos_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Data for Name: bancos; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.bancos (id, denominacion, estado) FROM stdin;
7	BANCO DE GALICIA Y BUENOS AIRES S.A.U.	0
11	BANCO DE LA NACION ARGENTINA	0
14	BANCO DE LA PROVINCIA DE BUENOS AIRES	0
16	CITIBANK N.A.	0
17	BANCO BBVA ARGENTINA S.A.	0
20	BANCO DE LA PROVINCIA DE CORDOBA S.A.	0
27	BANCO SUPERVIELLE S.A.	0
29	BANCO DE LA CIUDAD DE BUENOS AIRES	0
34	BANCO PATAGONIA S.A.	0
44	BANCO HIPOTECARIO S.A.	0
45	BANCO DE SAN JUAN S.A.	0
65	BANCO MUNICIPAL DE ROSARIO	0
72	BANCO SANTANDER RIO S.A.	0
83	BANCO DEL CHUBUT S.A.	0
86	BANCO DE SANTA CRUZ S.A.	0
93	BANCO DE LA PAMPA SOCIEDAD DE ECONOMÍA M	0
94	BANCO DE CORRIENTES S.A.	0
97	BANCO PROVINCIA DEL NEUQUÉN SOCIEDAD ANÓ	0
143	BRUBANK S.A.U.	0
147	BANCO INTERFINANZAS S.A.	0
150	HSBC BANK ARGENTINA S.A.	0
158	OPEN BANK ARGENTINA S.A.	0
165	JPMORGAN CHASE BANK NATIONAL ASSOCIATIO	0
191	BANCO CREDICOOP COOPERATIVO LIMITADO	0
198	BANCO DE VALORES S.A.	0
247	BANCO ROELA S.A.	0
254	BANCO MARIVA S.A.	0
259	BANCO ITAU ARGENTINA S.A.	0
266	BNP PARIBAS	0
268	BANCO PROVINCIA DE TIERRA DEL FUEGO	0
269	BANCO DE LA REPUBLICA ORIENTAL DEL URUGU	0
277	BANCO SAENZ S.A.	0
281	BANCO MERIDIAN S.A.	0
285	BANCO MACRO S.A.	0
299	BANCO COMAFI SOCIEDAD ANONIMA	0
300	BANCO DE INVERSION Y COMERCIO EXTERIOR S	0
301	BANCO PIANO S.A.	0
305	BANCO JULIO SOCIEDAD ANONIMA	0
309	BANCO RIOJA SOCIEDAD ANONIMA UNIPERSONAL	0
310	BANCO DEL SOL S.A.	0
311	NUEVO BANCO DEL CHACO S. A.	0
312	BANCO VOII S.A.	0
315	BANCO DE FORMOSA S.A.	0
319	BANCO CMF S.A.	0
321	BANCO DE SANTIAGO DEL ESTERO S.A.	0
322	BANCO INDUSTRIAL S.A.	0
330	NUEVO BANCO DE SANTA FE SOCIEDAD ANONIMA	0
331	BANCO CETELEM ARGENTINA S.A.	0
332	BANCO DE SERVICIOS FINANCIEROS S.A.	0
336	BANCO BRADESCO ARGENTINA S.A.U.	0
338	BANCO DE SERVICIOS Y TRANSACCIONES S.A.	0
339	RCI BANQUE S.A.	0
340	BACS BANCO DE CREDITO Y SECURITIZACION S	0
341	BANCO MASVENTAS S.A.	0
384	WILOBANK S.A.U.	0
386	NUEVO BANCO DE ENTRE RÍOS S.A.	0
389	BANCO COLUMBIA S.A.	0
426	BANCO BICA S.A.	0
431	BANCO COINAG S.A.	0
432	BANCO DE COMERCIO S.A.	0
435	BANCO SUCREDITO REGIONAL S.A.U.	0
448	BANCO DINO S.A.	0
515	BANK OF CHINA LIMITED SUCURSAL BUENOS AI	0
44059	FORD CREDIT COMPAÑIA FINANCIERA S.A.	0
44077	COMPAÑIA FINANCIERA ARGENTINA S.A.	0
44088	VOLKSWAGEN FINANCIAL SERVICES COMPAÑIA F	0
44090	IUDU COMPAÑÍA FINANCIERA S.A.	0
44092	FCA COMPAÑIA FINANCIERA S.A.	0
44093	GPAT COMPAÑIA FINANCIERA S.A.U.	0
44094	MERCEDES-BENZ COMPAÑÍA FINANCIERA ARGENT	0
44095	ROMBO COMPAÑÍA FINANCIERA S.A.	0
44096	JOHN DEERE CREDIT COMPAÑÍA FINANCIERA S.	0
44098	PSA FINANCE ARGENTINA COMPAÑÍA FINANCIER	0
44099	TOYOTA COMPAÑÍA FINANCIERA DE ARGENTINA	0
45030	NARANJA DIGITAL COMPAÑÍA FINANCIERA S.A.	0
45056	MONTEMAR COMPAÑIA FINANCIERA S.A.	0
45072	TRANSATLANTICA COMPAÑIA FINANCIERA S.A.	0
65203	CREDITO REGIONAL COMPAÑIA FINANCIERA S.A	0
15	ICBC   INDUSTRIAL AND COMMERCIAL BANK OF CHINA	0
\.


--
-- Data for Name: cajas; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.cajas (id, denominacion, estado) FROM stdin;
1	Caja 1	0
\.


--
-- Data for Name: chequeras; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.chequeras (id, cuenta_bancaria_id, echeque, serie, desde_nro, hasta_nro, fecha_solicitud, moneda_id, estado) FROM stdin;
4	5	N	J	43494951	43495000	2023-07-11	1	0
5	6	N	J	80157001	80157150	2023-06-11	1	0
3	4	N	J	44038262	44038300	2023-08-17	1	0
6	4	S	A	1	26000000	2024-01-01	1	0
\.


--
-- Data for Name: conceptos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.conceptos (id, descripcion, orden) FROM stdin;
1	SIN CONCEPTO	4
2	TERRENO	1
3	MATERIALES	2
4	OBRA	3
\.


--
-- Data for Name: cotizaciones; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.cotizaciones (id, fecha, importe, moneda_id, estado, oficial_compra, oficial_venta, blue_compra, blue_venta, hora, fecha_baja) FROM stdin;
2	2022-12-08	315.00	2	0	\N	\N	\N	\N	\N	\N
3	2022-12-30	350.00	2	0	\N	\N	\N	\N	\N	\N
4	2023-01-23	380.00	2	0	\N	\N	\N	\N	\N	\N
5	2023-04-12	394.00	2	0	\N	\N	\N	\N	\N	\N
6	2023-06-09	484.00	2	0	\N	\N	\N	\N	\N	\N
1	2022-12-09	320.00	2	0	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: cuentas_bancarias; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.cuentas_bancarias (id, denominacion, banco_id, cbu, alias, tipo, estado, proyecto_id, fecha_baja) FROM stdin;
3	Credicoop	191			C	1	3	\N
4	Fideicomiso Rhodas	191			C	0	3	\N
5	Fideicomiso Islas Malvinas	191			C	0	4	\N
6	Fideicomiso Rio Desaguadero	191	19101202-5501200088247		C	0	5	\N
1	Cuenta banco proyecto 1	11			C	1	1	\N
2	Cuenta bancaria proyecto 2	389			C	1	2	\N
\.


--
-- Data for Name: cuentas_corrientes; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.cuentas_corrientes (id, tipo_comprobante_id, importe, moneda_id, cotizacion_divisa, importe_divisa, entidad_id, detalle_proyecto_tipo_propiedad_id, comentario, proyecto_id, estado, usuario_id, fecha, fecha_registro, numero, docu_letra, docu_sucu, docu_nume, proyecto_origen_id, fecha_baja) FROM stdin;
746	1	513602.44	1	0.00	1000.00	101	\N	fc 492118- de Dario	3	0	2	2024-04-11	2024-04-11 10:24:13.113505	69	A	44	492118	3	\N
747	3	377819.44	1	0.00	1000.00	101	\N	NC 34516 APLICA FC 492118	3	0	2	2024-04-11	2024-04-11 10:26:27.495637	9	A	44	34516	3	\N
748	3	87340.52	1	0.00	1000.00	101	\N	NC 34574 APLICA FC 492118	3	0	2	2024-04-11	2024-04-11 10:28:21.194872	10	A	44	34574	3	\N
749	3	16470.46	1	0.00	1000.00	101	\N	NC 142791 APLICA A FC 492118	3	0	2	2024-04-11	2024-04-11 10:30:04.38744	11	A	66	142791	3	\N
750	4	\N	\N	0.00	0.00	101	\N		\N	0	2	2024-04-11	2024-04-11 10:48:30.991363	147	\N	\N	\N	8	\N
751	9	\N	\N	0.00	0.00	14	\N		3	0	2	2024-04-11	2024-04-11 11:59:52.830612	141	\N	\N	\N	3	\N
752	9	\N	\N	0.00	0.00	37	\N		4	0	2	2024-04-11	2024-04-11 12:29:24.936176	142	\N	\N	\N	4	\N
753	1	679200.00	1	0.00	970.00	94	\N	fc alquoles Stremel	4	0	2	2024-04-11	2024-04-11 12:36:16.812141	70	A	4	100	4	\N
754	4	\N	\N	0.00	0.00	94	\N		\N	0	2	2024-04-11	2024-04-11 12:37:09.506619	148	\N	\N	\N	4	\N
755	9	\N	\N	0.00	0.00	39	\N		5	0	2	2024-04-11	2024-04-11 13:00:02.592843	143	\N	\N	\N	5	\N
756	9	\N	\N	0.00	0.00	38	\N		5	0	2	2024-04-11	2024-04-11 13:00:33.422362	144	\N	\N	\N	5	\N
757	9	\N	\N	0.00	0.00	40	\N		5	0	2	2024-04-11	2024-04-11 13:01:11.418972	145	\N	\N	\N	5	\N
758	1	200000.00	1	0.00	970.00	99	\N		5	0	2	2024-04-11	2024-04-11 13:30:12.869085	71	C	1	210	5	\N
759	4	\N	\N	0.00	0.00	99	\N		\N	0	2	2024-04-11	2024-04-11 13:30:53.289959	149	\N	\N	\N	5	\N
760	1	400000.00	1	0.00	970.00	99	\N	HONORARIOS	5	0	2	2024-04-11	2024-04-11 13:32:07.075622	72	C	1	211	5	\N
761	4	\N	\N	0.00	0.00	99	\N		\N	0	2	2024-04-11	2024-04-11 13:32:36.864302	150	\N	\N	\N	5	\N
762	1	350000.00	1	0.00	970.00	89	\N	HONORARIOS	5	0	2	2024-04-11	2024-04-11 13:33:47.648121	73	C	1	407	5	\N
763	4	\N	\N	0.00	0.00	89	\N		\N	0	2	2024-04-11	2024-04-11 13:34:20.805553	151	\N	\N	\N	5	\N
764	1	200000.00	1	0.00	970.00	102	\N	4 BOLSONES DE ARENA	5	0	2	2024-04-11	2024-04-11 13:35:20.914339	74	C	3	697	5	\N
765	4	\N	\N	0.00	0.00	102	\N		\N	0	2	2024-04-11	2024-04-11 13:35:54.215369	152	\N	\N	\N	5	\N
766	1	168000.00	1	0.00	970.00	102	\N	2 bolsones de arena	4	0	2	2024-04-11	2024-04-11 14:57:37.521585	75	C	3	687	4	\N
767	4	\N	\N	0.00	0.00	102	\N		\N	0	2	2024-04-11	2024-04-11 14:58:06.122964	153	\N	\N	\N	4	\N
769	12	1200000.00	1	0.00	970.00	74	\N	PRESUPUESTO CERTIFICADO N° 29	3	0	2	2024-04-11	2024-04-11 15:30:38.871178	55	C	1	29	3	\N
770	1	246277.98	1	0.00	1000.00	113	\N	Weber imperstop gris	5	0	2	2024-04-09	2024-04-12 09:46:59.444231	76	A	77	7315	5	\N
771	4	\N	\N	0.00	0.00	113	\N		\N	0	2	2024-04-12	2024-04-12 09:48:57.915363	154	\N	\N	\N	5	\N
772	9	\N	\N	0.00	0.00	17	\N		3	0	2	2024-04-12	2024-04-12 10:02:41.086208	146	\N	\N	\N	3	\N
773	9	\N	\N	0.00	0.00	17	\N	Aporte	3	0	2	2024-04-12	2024-04-12 10:40:31.850705	147	\N	\N	\N	3	\N
774	9	\N	\N	0.00	0.00	109	\N	Aporte	5	0	2	2024-04-12	2024-04-12 11:10:44.096174	148	\N	\N	\N	5	\N
775	9	\N	\N	0.00	0.00	41	\N	Aporte	5	0	2	2024-04-12	2024-04-12 12:43:59.017786	149	\N	\N	\N	5	\N
776	9	\N	\N	0.00	0.00	27	\N	Aportes	3	0	2	2024-04-12	2024-04-12 13:30:26.06089	150	\N	\N	\N	3	\N
777	1	23200.00	1	0.00	1000.00	89	\N	fc 408	4	0	2	2024-04-11	2024-04-12 16:10:58.986029	77	c	1	408	4	\N
778	9	\N	\N	0.00	0.00	47	\N		5	0	2	2024-04-11	2024-04-16 10:50:29.618496	151	\N	\N	\N	5	\N
779	9	\N	\N	0.00	0.00	48	\N		5	0	2	2024-04-16	2024-04-16 10:51:07.007888	152	\N	\N	\N	5	\N
780	9	\N	\N	0.00	0.00	109	\N		5	0	2	2024-04-11	2024-04-16 10:51:52.377379	153	\N	\N	\N	5	\N
781	9	\N	\N	0.00	0.00	37	\N		4	1	2	2024-04-16	2024-04-16 11:28:26.677183	154	\N	\N	\N	4	2024-04-16 11:28:45.618648
782	9	\N	\N	0.00	0.00	37	\N		4	0	2	2024-04-12	2024-04-16 11:30:05.268726	155	\N	\N	\N	4	\N
783	4	\N	\N	0.00	0.00	73	\N		\N	0	2	2024-04-12	2024-04-16 12:13:33.876488	155	\N	\N	\N	4	\N
784	9	\N	\N	0.00	0.00	48	\N		5	1	2	2024-04-15	2024-04-16 13:37:23.288113	156	\N	\N	\N	5	2024-04-16 13:47:29.259176
785	9	\N	\N	0.00	0.00	48	\N		5	0	2	2024-04-15	2024-04-16 13:48:22.328407	157	\N	\N	\N	5	\N
786	9	\N	\N	0.00	0.00	106	\N		5	0	2	2024-04-16	2024-04-16 13:48:52.130792	158	\N	\N	\N	5	\N
787	1	600000.00	1	0.00	1005.00	114	\N		4	0	2	2024-04-15	2024-04-16 14:54:35.562881	78	c	1	73	4	\N
788	4	\N	\N	0.00	0.00	114	\N		\N	0	2	2024-04-16	2024-04-16 14:55:12.966744	156	\N	\N	\N	4	\N
789	1	29000.00	1	0.00	1005.00	73	\N	\r\n	4	0	2	2024-04-16	2024-04-16 15:08:01.063669	79	C	1	72	4	\N
790	4	\N	\N	0.00	0.00	73	\N		\N	0	2	2024-04-16	2024-04-16 15:08:41.801838	157	\N	\N	\N	4	\N
791	9	\N	\N	0.00	0.00	42	\N		5	0	2	2024-04-16	2024-04-17 10:43:52.603931	159	\N	\N	\N	5	\N
792	9	\N	\N	0.00	0.00	14	\N		3	0	2	2024-04-17	2024-04-17 11:19:29.156596	160	\N	\N	\N	3	\N
793	9	\N	\N	0.00	0.00	13	\N		3	0	2	2024-04-16	2024-04-18 10:15:31.433717	161	\N	\N	\N	3	\N
794	1	64000.00	1	0.00	1030.00	115	\N	alquiler 3 arneses del 26/3 al 10/4/24	4	0	2	2024-04-18	2024-04-18 12:22:28.890795	80	A	5	869	4	\N
795	1	272000.00	1	0.00	1030.00	115	\N	alquiler tablones y andamios	4	0	2	2024-04-18	2024-04-18 12:23:34.513991	81	A	5	870	4	\N
796	4	\N	\N	0.00	0.00	115	\N		\N	0	2	2024-04-18	2024-04-18 12:25:27.814843	158	\N	\N	\N	4	\N
797	4	\N	\N	0.00	0.00	115	\N		\N	0	2	2024-04-18	2024-04-18 12:28:01.325708	159	\N	\N	\N	4	\N
798	9	\N	\N	0.00	0.00	17	\N	Aporte	3	0	2	2024-04-17	2024-04-18 13:29:16.000407	162	\N	\N	\N	3	\N
799	1	162310.00	1	0.00	1030.00	83	\N	Electro La Reja a Malvinas	4	0	2	2024-04-18	2024-04-18 13:31:49.636559	82	A	34	123382	4	\N
800	4	\N	\N	0.00	0.00	83	\N		\N	0	2	2024-04-18	2024-04-18 13:33:52.951878	160	\N	\N	\N	4	\N
801	13	\N	\N	0.00	0.00	112	\N		3	1	2	2024-04-24	2024-04-24 10:45:08.591366	4	\N	\N	\N	3	2024-04-24 10:48:38.364257
802	13	\N	\N	0.00	0.00	51	\N		3	0	2	2024-04-24	2024-04-24 10:49:24.222247	5	\N	\N	\N	3	\N
803	12	200000.00	1	0.00	484.00	73	\N		4	0	2	2024-05-06	2024-05-06 09:52:25.880662	56	C	2	48469	4	\N
804	4	\N	\N	0.00	0.00	73	\N		\N	0	2	2024-05-06	2024-05-06 09:53:36.984057	161	\N	\N	\N	4	\N
805	13	\N	\N	0.00	0.00	117	\N		3	0	2	2024-05-07	2024-05-07 10:30:14.755675	6	\N	\N	\N	3	\N
806	9	\N	\N	0.00	0.00	48	\N		5	0	2	2024-05-10	2024-05-10 09:30:32.513912	163	\N	\N	\N	5	\N
807	9	\N	\N	0.00	0.00	106	\N		5	0	2	2024-05-10	2024-05-10 09:31:10.100943	164	\N	\N	\N	5	\N
809	1	500000.00	1	0.00	1040.00	89	\N	Honorarios	3	0	2	2024-05-10	2024-05-10 09:57:05.282995	84	c	1	410	3	\N
810	4	\N	\N	0.00	0.00	89	\N		\N	0	2	2024-05-10	2024-05-10 09:58:01.737074	162	\N	\N	\N	3	\N
\.


--
-- Data for Name: cuentas_corrientes_caja; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.cuentas_corrientes_caja (id, cuenta_corriente_id, importe, moneda_id, cotizacion_divisa, importe_divisa, estado, tipo_movimiento_caja_id, cuenta_bancaria_id, caja_id, comentario, cta_cte_caja_origen_id, fecha_emision, fecha_acreditacion, serie, numero, chequera_id, banco_id, e_chq, chq_a_depo, fecha_conciliacion, fecha_depositado, fecha_registro, signo_caja, signo_banco, proyecto_id, relacion_id, fecha_baja) FROM stdin;
468	751	118870.00	1	1000.00	1000.00	0	10	\N	1	Recibo n° 64336515	\N	2024-04-05	2024-04-30	QD	4220609	\N	14	0	\N	\N	\N	2024-04-11 11:59:52.830612	1	1	\N	\N	\N
469	751	933000.00	1	1000.00	1000.00	0	10	\N	1	Recibo n° 64336515	\N	2024-03-25	2024-05-21	QD	4220594	\N	14	0	\N	\N	\N	2024-04-11 11:59:52.830612	1	1	\N	\N	\N
470	751	935000.00	1	1000.00	1000.00	0	10	\N	1	Recibo n° 64336515	\N	2024-03-25	2024-05-28	QD	4220595	\N	14	0	\N	\N	\N	2024-04-11 11:59:52.830612	1	1	\N	\N	\N
471	752	1000000.00	1	970.00	970.00	0	16	5	1	deposito aporte	\N	\N	2024-04-11	\N	\N	\N	\N	0	\N	\N	\N	2024-04-11 12:29:24.936176	1	1	\N	\N	\N
472	754	679200.00	1	970.00	970.00	0	17	5	1	Transferencia 	\N	\N	2024-04-11	\N	\N	\N	\N	0	\N	\N	\N	2024-04-11 12:37:09.506619	-1	-1	\N	\N	\N
473	755	850000.00	1	970.00	970.00	0	16	6	1	Aporte	\N	\N	2024-04-11	\N	\N	\N	\N	0	\N	\N	\N	2024-04-11 13:00:02.592843	1	1	\N	\N	\N
474	756	850000.00	1	970.00	970.00	0	16	6	1	Aporte	\N	\N	2024-04-11	\N	\N	\N	\N	0	\N	\N	\N	2024-04-11 13:00:33.422362	1	1	\N	\N	\N
475	757	850000.00	1	970.00	970.00	0	16	6	1	Aporte	\N	\N	2024-04-11	\N	\N	\N	\N	0	\N	\N	\N	2024-04-11 13:01:11.418972	1	1	\N	\N	\N
476	759	200000.00	1	970.00	970.00	0	17	6	1		\N	\N	2024-04-11	\N	\N	\N	\N	0	\N	\N	\N	2024-04-11 13:30:53.289959	-1	-1	\N	\N	\N
477	761	400000.00	1	970.00	970.00	0	17	6	1		\N	\N	2024-04-11	\N	\N	\N	\N	0	\N	\N	\N	2024-04-11 13:32:36.864302	-1	-1	\N	\N	\N
478	763	350000.00	1	970.00	970.00	0	17	6	1		\N	\N	2024-04-11	\N	\N	\N	\N	0	\N	\N	\N	2024-04-11 13:34:20.805553	-1	-1	\N	\N	\N
479	765	200000.00	1	970.00	970.00	0	17	6	1	Transferencia	\N	\N	2024-04-11	\N	\N	\N	\N	0	\N	\N	\N	2024-04-11 13:35:54.215369	-1	-1	\N	\N	\N
480	767	168000.00	1	970.00	970.00	0	17	5	1		\N	\N	2024-04-11	\N	\N	\N	\N	0	\N	\N	\N	2024-04-11 14:58:06.122964	-1	-1	\N	\N	\N
481	771	246277.98	1	1000.00	1000.00	0	17	6	1		\N	\N	2024-04-12	\N	\N	\N	\N	0	\N	\N	\N	2024-04-12 09:48:57.915363	-1	-1	\N	\N	\N
482	772	942917.00	1	1000.00	1000.00	0	16	4	1	Aporte	\N	\N	2024-04-12	\N	\N	\N	\N	0	\N	\N	\N	2024-04-12 10:02:41.086208	1	1	\N	\N	\N
483	773	364000.00	1	1000.00	1000.00	0	10	\N	1	Aporte	\N	0024-04-08	2024-04-20	QD	5721407	\N	14	0	\N	\N	\N	2024-04-12 10:40:31.850705	1	1	\N	\N	\N
484	773	30000.00	1	1000.00	1000.00	0	10	\N	1	Aporte	\N	2024-03-15	2024-03-20	N	1776975	\N	11	0	\N	\N	\N	2024-04-12 10:40:31.850705	1	1	\N	\N	\N
485	773	50000.00	1	1000.00	1000.00	0	10	\N	1	Aporte	\N	2024-02-27	2024-03-27	L	61683670	\N	191	0	\N	\N	\N	2024-04-12 10:40:31.850705	1	1	\N	\N	\N
486	773	588983.00	1	1000.00	1000.00	0	10	\N	1	Aporte	\N	2024-03-14	2024-04-23	QD	4868848	\N	14	0	\N	\N	\N	2024-04-12 10:40:31.850705	1	1	\N	\N	\N
487	773	25000.00	1	1000.00	1000.00	0	10	\N	1	Aporte	\N	2024-04-20	2024-04-20	96	8078218	\N	150	0	\N	\N	\N	2024-04-12 10:40:31.850705	1	1	\N	\N	\N
488	774	635600.00	1	1000.00	1000.00	0	9	\N	1	Aporte	\N	\N	2024-04-12	\N	\N	\N	\N	0	\N	\N	\N	2024-04-12 11:10:44.096174	1	1	\N	\N	\N
467	750	31972.00	1	1000.00	1000.00	0	23	4	1	SALDO FC 492118	\N	2024-08-04	2024-10-04	A	1	6	191	1	\N	0002-04-12	\N	2024-04-11 10:48:30.991363	-1	-1	\N	\N	\N
489	775	850000.00	1	1000.00	1000.00	0	16	6	1	Aporte	\N	\N	2024-04-12	\N	\N	\N	\N	0	\N	\N	\N	2024-04-12 12:43:59.017786	1	1	\N	\N	\N
490	776	3500000.00	1	1000.00	1000.00	0	16	4	1	Aporte	\N	\N	2024-04-12	\N	\N	\N	\N	0	\N	\N	\N	2024-04-12 13:30:26.06089	1	1	\N	\N	\N
491	778	850000.00	1	995.00	995.00	0	9	\N	1	Aporte	\N	\N	2024-04-11	\N	\N	\N	\N	0	\N	\N	\N	2024-04-16 10:50:29.618496	1	1	\N	\N	\N
492	779	850000.00	1	995.00	995.00	0	9	\N	1	Aporte	\N	\N	2024-04-16	\N	\N	\N	\N	0	\N	\N	\N	2024-04-16 10:51:07.007888	1	1	\N	\N	\N
493	780	500000.00	1	995.00	995.00	0	9	\N	1	Aporte	\N	\N	2024-04-11	\N	\N	\N	\N	0	\N	\N	\N	2024-04-16 10:51:52.377379	1	1	\N	\N	\N
494	781	850000.00	1	1005.00	1005.00	1	30	6	1	Aporte deposito bco RD	\N	\N	2024-04-16	\N	\N	\N	\N	0	\N	\N	\N	2024-04-16 11:28:26.677183	1	1	\N	\N	2024-04-16 11:28:45.618648
495	782	850000.00	1	1005.00	1005.00	0	30	6	1	Aporte en bco RD	\N	\N	2024-04-12	\N	\N	\N	\N	0	\N	\N	\N	2024-04-16 11:30:05.268726	1	1	\N	\N	\N
496	783	960000.00	1	1005.00	1005.00	0	9	\N	1	Recibo 46142351. jornales, comida, honorarios	\N	\N	2024-04-12	\N	\N	\N	\N	0	\N	\N	\N	2024-04-16 12:13:33.876488	-1	-1	\N	\N	\N
497	784	850000.00	1	1005.00	1005.00	1	16	6	1	Aporte	\N	\N	2024-04-15	\N	\N	\N	\N	0	\N	\N	\N	2024-04-16 13:37:23.288113	1	1	\N	\N	2024-04-16 13:47:29.259176
498	785	425000.00	1	1005.00	1005.00	0	16	6	1	Aporte 	\N	\N	2024-04-15	\N	\N	\N	\N	0	\N	\N	\N	2024-04-16 13:48:22.328407	1	1	\N	\N	\N
499	786	425000.00	1	1005.00	1005.00	0	16	6	1	Aporte	\N	\N	2024-04-16	\N	\N	\N	\N	0	\N	\N	\N	2024-04-16 13:48:52.130792	1	1	\N	\N	\N
500	788	600000.00	1	1005.00	1005.00	0	17	5	1	pago fc 73	\N	\N	2024-04-16	\N	\N	\N	\N	0	\N	\N	\N	2024-04-16 14:55:12.966744	-1	-1	\N	\N	\N
501	790	29000.00	1	1005.00	1005.00	0	17	5	1	TRANSFERENCIA FC 72	\N	\N	2024-04-16	\N	\N	\N	\N	0	\N	\N	\N	2024-04-16 15:08:41.801838	-1	-1	\N	\N	\N
502	791	1700000.00	1	1035.00	1035.00	0	9	\N	1	Aporte\r\n	\N	\N	2024-04-16	\N	\N	\N	\N	0	\N	\N	\N	2024-04-17 10:43:52.603931	1	1	\N	\N	\N
503	792	520000.00	1	1035.00	1035.00	0	9	\N	1	Aporte	\N	\N	2024-04-17	\N	\N	\N	\N	0	\N	\N	\N	2024-04-17 11:19:29.156596	1	1	\N	\N	\N
504	793	3450000.00	1	1030.00	1030.00	0	10	\N	1	Aporte	\N	2024-03-11	2024-04-15	QD	1704552	\N	14	0	\N	\N	\N	2024-04-18 10:15:31.433717	1	1	\N	\N	\N
505	793	1600000.00	1	1030.00	1030.00	0	10	\N	1	Aporte	\N	2024-03-19	2024-04-19	N	60	\N	11	0	\N	\N	\N	2024-04-18 10:15:31.433717	1	1	\N	\N	\N
506	793	1000000.00	1	1030.00	1030.00	0	10	\N	1	Aporte	\N	2024-03-26	2024-04-17	k	64316933	\N	93	0	\N	\N	\N	2024-04-18 10:15:31.433717	1	1	\N	\N	\N
507	793	1000000.00	1	1030.00	1030.00	0	10	\N	1	Aporte	\N	2024-03-26	2024-04-15	k	64316931	\N	93	0	\N	\N	\N	2024-04-18 10:15:31.433717	1	1	\N	\N	\N
508	796	64000.00	1	1030.00	1030.00	0	17	5	1	TRANSFERENCIA	\N	\N	2024-04-18	\N	\N	\N	\N	0	\N	\N	\N	2024-04-18 12:25:27.814843	-1	-1	\N	\N	\N
509	797	268848.53	1	1030.00	1030.00	0	17	5	1	Transferencia	\N	\N	2024-04-18	\N	\N	\N	\N	0	\N	\N	\N	2024-04-18 12:28:01.325708	-1	-1	\N	\N	\N
510	797	3151.47	1	1030.00	1030.00	0	25	\N	1	Ret Ganancias	\N	\N	2024-04-18	\N	\N	\N	\N	0	\N	\N	\N	2024-04-18 12:28:01.325708	-1	-1	\N	\N	\N
511	798	245652.71	1	1030.00	1030.00	0	10	\N	1	Aporte	\N	2024-03-05	2024-04-23	K	64548034	\N	93	0	\N	\N	\N	2024-04-18 13:29:16.000407	1	1	\N	\N	\N
512	798	950000.00	1	1030.00	1030.00	0	10	\N	1	Aporte	\N	2024-03-07	2024-04-10	B	47737151	\N	285	0	\N	\N	\N	2024-04-18 13:29:16.000407	1	1	\N	\N	\N
513	800	160717.60	1	1030.00	1030.00	0	17	5	1	Transferencia	\N	\N	2024-04-18	\N	\N	\N	\N	0	\N	\N	\N	2024-04-18 13:33:52.951878	-1	-1	\N	\N	\N
514	800	1593.15	1	1030.00	1030.00	0	25	\N	1	Ret Gcias	\N	\N	2024-04-18	\N	\N	\N	\N	0	\N	\N	\N	2024-04-18 13:33:52.951878	-1	-1	\N	\N	\N
515	801	250000.00	1	484.00	484.00	1	10	\N	1		\N	2024-04-02	2024-05-09	f	232165	\N	319	0	\N	\N	\N	2024-04-24 10:45:08.591366	1	1	\N	\N	2024-04-24 10:48:38.364257
516	801	1500000.00	1	484.00	484.00	1	10	\N	1		\N	2024-04-05	2024-05-10	w	32545	\N	93	0	\N	\N	\N	2024-04-24 10:45:08.591366	1	1	\N	\N	2024-04-24 10:48:38.364257
517	802	250000.00	1	484.00	484.00	0	10	\N	1		\N	2024-04-03	2024-05-09	d	324525	\N	336	0	\N	\N	\N	2024-04-24 10:49:24.222247	1	1	\N	\N	\N
518	802	1500000.00	1	484.00	484.00	0	10	\N	1		\N	2024-04-01	2024-05-07	h	4363634	\N	11	0	\N	\N	\N	2024-04-24 10:49:24.222247	1	1	\N	\N	\N
519	804	200000.00	1	484.00	484.00	0	9	\N	1		\N	\N	2024-05-06	\N	\N	\N	\N	0	\N	\N	\N	2024-05-06 09:53:36.984057	-1	-1	\N	\N	\N
520	805	1800000.00	1	1040.00	1040.00	0	10	\N	1		\N	2024-05-01	2024-05-03	N	25115265	\N	191	0	\N	\N	\N	2024-05-07 10:30:14.755675	1	1	\N	\N	\N
521	805	1800000.00	1	1040.00	1040.00	0	10	\N	1		\N	2024-05-01	2024-06-07	N	25116264	\N	191	0	\N	\N	\N	2024-05-07 10:30:14.755675	1	1	\N	\N	\N
522	805	1800000.00	1	1040.00	1040.00	0	10	\N	1		\N	2024-05-01	2024-07-05	N	25116263	\N	191	0	\N	\N	\N	2024-05-07 10:30:14.755675	1	1	\N	\N	\N
523	805	1799472.22	1	1040.00	1040.00	0	10	\N	1		\N	2024-05-01	2024-08-02	N	25116266	\N	191	0	\N	\N	\N	2024-05-07 10:30:14.755675	1	1	\N	\N	\N
524	806	425000.00	1	1040.00	1040.00	0	16	6	1	Aporte	\N	\N	2024-05-10	\N	\N	\N	\N	0	\N	\N	\N	2024-05-10 09:30:32.513912	1	1	\N	\N	\N
525	807	425000.00	1	1040.00	1040.00	0	16	6	1	Aporte	\N	\N	2024-05-10	\N	\N	\N	\N	0	\N	\N	\N	2024-05-10 09:31:10.100943	1	1	\N	\N	\N
526	810	500000.00	1	1040.00	1040.00	0	17	4	1	Honorarios	\N	\N	2024-05-10	\N	\N	\N	\N	0	\N	\N	\N	2024-05-10 09:58:01.737074	-1	-1	\N	\N	\N
\.


--
-- Data for Name: detalle_proyecto_tipos_propiedades; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.detalle_proyecto_tipos_propiedades (id, coeficiente, proyecto_tipo_propiedad_id, entidad_id, estado, fecha_baja) FROM stdin;
274	0.0000	31	107	0	\N
132	100.0000	31	23	0	\N
136	0.0000	31	13	0	\N
138	0.0000	31	22	0	\N
130	0.0000	31	14	0	\N
131	0.0000	31	19	0	\N
137	0.0000	31	11	0	\N
18	0.0000	16	12	0	\N
19	100.0000	16	11	0	\N
134	0.0000	31	27	0	\N
165	0.0000	18	25	0	\N
20	5.0000	18	12	0	\N
135	0.0000	31	25	0	\N
129	0.0000	31	17	0	\N
16	0.0000	15	12	0	\N
35	100.0000	21	25	0	\N
34	0.0000	21	11	0	\N
140	0.0000	31	21	0	\N
29	0.0000	21	39	0	\N
300	0.0000	36	107	0	\N
30	0.0000	21	48	0	\N
301	100.0000	36	13	0	\N
31	0.0000	21	12	0	\N
302	0.0000	36	22	0	\N
32	0.0000	21	27	0	\N
303	0.0000	36	14	0	\N
33	0.0000	21	13	0	\N
42	0.0000	22	39	0	\N
43	0.0000	22	48	0	\N
44	0.0000	22	12	0	\N
49	0.0000	23	39	0	\N
50	0.0000	23	48	0	\N
51	0.0000	23	12	0	\N
52	100.0000	23	14	0	\N
53	0.0000	23	27	0	\N
54	0.0000	23	25	0	\N
55	0.0000	23	13	0	\N
56	0.0000	23	11	0	\N
57	0.0000	24	39	0	\N
58	0.0000	24	48	0	\N
59	0.0000	24	12	0	\N
60	0.0000	24	14	0	\N
61	100.0000	24	15	0	\N
62	0.0000	24	27	0	\N
63	0.0000	24	25	0	\N
64	0.0000	24	13	0	\N
65	0.0000	24	11	0	\N
68	0.0000	25	12	0	\N
304	0.0000	36	19	0	\N
76	0.0000	26	39	0	\N
77	0.0000	26	48	0	\N
78	0.0000	26	12	0	\N
79	0.0000	26	17	0	\N
80	0.0000	26	14	0	\N
81	0.0000	26	15	0	\N
82	0.0000	26	27	0	\N
83	0.0000	26	25	0	\N
84	0.0000	26	13	0	\N
85	0.0000	26	11	0	\N
86	100.0000	26	18	0	\N
87	0.0000	27	39	0	\N
88	0.0000	27	48	0	\N
89	0.0000	27	12	0	\N
90	0.0000	27	17	0	\N
91	0.0000	27	14	0	\N
92	100.0000	27	19	0	\N
93	0.0000	27	15	0	\N
94	0.0000	27	27	0	\N
95	0.0000	27	25	0	\N
96	0.0000	27	13	0	\N
97	0.0000	27	11	0	\N
98	0.0000	27	18	0	\N
99	0.0000	28	39	0	\N
100	0.0000	28	48	0	\N
101	0.0000	28	12	0	\N
102	0.0000	28	17	0	\N
103	0.0000	28	14	0	\N
104	0.0000	28	19	0	\N
105	0.0000	28	15	0	\N
106	0.0000	28	27	0	\N
107	0.0000	28	25	0	\N
108	0.0000	28	13	0	\N
109	0.0000	28	11	0	\N
110	0.0000	28	18	0	\N
111	100.0000	28	21	0	\N
112	0.0000	29	39	0	\N
113	0.0000	29	48	0	\N
114	0.0000	29	12	0	\N
115	0.0000	29	17	0	\N
116	0.0000	29	14	0	\N
117	0.0000	29	19	0	\N
118	100.0000	29	23	0	\N
119	0.0000	29	15	0	\N
120	0.0000	29	27	0	\N
121	0.0000	29	25	0	\N
122	0.0000	29	13	0	\N
123	0.0000	29	11	0	\N
124	0.0000	29	18	0	\N
125	0.0000	29	21	0	\N
128	0.0000	31	12	0	\N
305	0.0000	36	26	0	\N
141	0.0000	32	39	0	\N
142	0.0000	32	48	0	\N
143	0.0000	32	12	0	\N
144	0.0000	32	17	0	\N
145	0.0000	32	14	0	\N
146	0.0000	32	19	0	\N
147	100.0000	32	26	0	\N
148	0.0000	32	23	0	\N
149	0.0000	32	15	0	\N
150	0.0000	32	27	0	\N
151	0.0000	32	25	0	\N
152	0.0000	32	13	0	\N
153	0.0000	32	11	0	\N
154	0.0000	32	22	0	\N
155	0.0000	32	18	0	\N
156	0.0000	32	21	0	\N
157	0.0000	18	39	0	\N
158	0.0000	18	48	0	\N
126	0.0000	31	39	0	\N
127	0.0000	31	48	0	\N
306	0.0000	36	23	0	\N
307	0.0000	36	11	0	\N
308	0.0000	36	27	0	\N
309	0.0000	36	25	0	\N
310	0.0000	36	17	0	\N
311	0.0000	36	15	0	\N
312	0.0000	36	21	0	\N
139	0.0000	31	18	0	\N
74	0.0000	25	13	0	\N
66	0.0000	25	39	0	\N
67	0.0000	25	48	0	\N
75	0.0000	25	11	0	\N
71	0.0000	25	15	0	\N
70	0.0000	25	14	0	\N
73	0.0000	25	25	0	\N
2	50.0000	1	1	1	\N
166	0.0000	18	13	0	\N
160	0.0000	18	14	0	\N
161	0.0000	18	19	0	\N
162	0.0000	18	26	0	\N
163	0.0000	18	23	0	\N
22	0.0000	18	11	0	\N
159	0.0000	18	17	0	\N
164	0.0000	18	15	0	\N
45	0.0000	22	27	0	\N
47	0.0000	22	13	0	\N
48	0.0000	22	11	0	\N
46	100.0000	22	25	0	\N
69	100.0000	25	17	0	\N
173	0.0000	31	26	0	\N
133	0.0000	31	15	0	\N
174	50.0000	31	24	0	\N
175	0.0000	31	28	0	\N
287	0.0000	33	107	0	\N
26	0.0000	15	27	0	\N
288	0.0000	33	13	0	\N
289	0.0000	33	22	0	\N
290	0.0000	33	14	0	\N
291	0.0000	33	19	0	\N
292	0.0000	33	26	0	\N
293	0.0000	33	23	0	\N
294	100.0000	33	11	0	\N
295	0.0000	33	27	0	\N
296	0.0000	33	25	0	\N
297	0.0000	33	17	0	\N
298	0.0000	33	15	0	\N
299	0.0000	33	21	0	\N
313	0.0000	37	107	0	\N
193	0.0000	25	24	0	\N
195	0.0000	25	28	0	\N
196	50.0000	25	18	0	\N
314	0.0000	37	13	0	\N
315	100.0000	37	22	0	\N
316	0.0000	37	14	0	\N
317	0.0000	37	19	0	\N
318	0.0000	37	26	0	\N
319	0.0000	37	23	0	\N
320	0.0000	37	11	0	\N
321	0.0000	37	27	0	\N
322	0.0000	37	25	0	\N
4	0.0000	2	1	1	\N
6	0.0000	3	1	1	\N
8	50.0000	4	1	1	\N
5	100.0000	3	2	1	\N
11	50.0000	6	2	1	\N
7	50.0000	4	2	1	\N
3	100.0000	2	2	1	\N
1	50.0000	1	2	1	\N
10	100.0000	8	3	1	\N
9	100.0000	7	3	1	\N
12	50.0000	6	3	1	\N
14	0.0000	13	4	1	\N
15	100.0000	14	10	1	\N
13	100.0000	13	10	1	\N
207	0.0000	18	24	0	\N
323	0.0000	37	17	0	\N
168	0.0000	18	28	0	\N
324	0.0000	37	15	0	\N
21	100.0000	18	27	0	\N
325	0.0000	37	21	0	\N
169	0.0000	18	18	0	\N
326	0.0000	38	107	0	\N
327	0.0000	38	13	0	\N
167	0.0000	18	22	0	\N
328	0.0000	38	22	0	\N
329	0.0000	38	14	0	\N
330	100.0000	38	34	0	\N
331	0.0000	38	19	0	\N
332	0.0000	38	26	0	\N
333	0.0000	38	23	0	\N
334	0.0000	38	11	0	\N
335	0.0000	38	27	0	\N
336	0.0000	38	25	0	\N
170	0.0000	18	21	0	\N
337	0.0000	38	17	0	\N
338	0.0000	38	15	0	\N
235	0.0000	20	107	0	\N
236	100.0000	20	13	0	\N
237	0.0000	20	22	0	\N
238	0.0000	20	14	0	\N
239	0.0000	20	19	0	\N
240	0.0000	20	26	0	\N
241	0.0000	20	23	0	\N
242	0.0000	20	11	0	\N
243	0.0000	20	27	0	\N
244	0.0000	20	25	0	\N
245	0.0000	20	17	0	\N
246	0.0000	20	15	0	\N
247	0.0000	20	21	0	\N
248	0.0000	22	107	0	\N
249	0.0000	22	22	0	\N
250	0.0000	22	14	0	\N
251	0.0000	22	19	0	\N
252	0.0000	22	26	0	\N
253	0.0000	22	23	0	\N
254	0.0000	22	17	0	\N
255	0.0000	22	15	0	\N
256	0.0000	22	21	0	\N
339	0.0000	38	21	0	\N
340	0.0000	39	107	0	\N
341	0.0000	39	13	0	\N
342	0.0000	39	22	0	\N
261	0.0000	25	107	0	\N
343	0.0000	39	14	0	\N
344	100.0000	39	34	0	\N
345	0.0000	39	19	0	\N
194	0.0000	25	22	0	\N
346	0.0000	39	26	0	\N
347	0.0000	39	23	0	\N
190	0.0000	25	19	0	\N
348	0.0000	39	11	0	\N
191	0.0000	25	26	0	\N
349	0.0000	39	27	0	\N
192	0.0000	25	23	0	\N
350	0.0000	39	25	0	\N
351	0.0000	39	17	0	\N
72	0.0000	25	27	0	\N
352	0.0000	39	15	0	\N
353	0.0000	39	21	0	\N
354	100.0000	41	29	0	\N
197	0.0000	25	21	0	\N
355	0.0000	41	35	0	\N
356	0.0000	41	36	0	\N
357	0.0000	41	32	0	\N
358	0.0000	41	31	0	\N
359	0.0000	41	104	0	\N
360	0.0000	41	34	0	\N
361	0.0000	41	11	0	\N
362	0.0000	41	30	0	\N
363	0.0000	41	37	0	\N
364	0.0000	35	29	0	\N
365	100.0000	35	35	0	\N
366	0.0000	35	36	0	\N
367	0.0000	35	32	0	\N
368	0.0000	35	31	0	\N
369	0.0000	35	104	0	\N
370	0.0000	35	34	0	\N
371	0.0000	35	11	0	\N
372	0.0000	35	30	0	\N
373	0.0000	35	37	0	\N
374	0.0000	42	29	0	\N
375	0.0000	42	35	0	\N
376	0.0000	42	36	0	\N
377	0.0000	42	32	0	\N
378	0.0000	42	31	0	\N
379	0.0000	42	104	0	\N
380	100.0000	42	34	0	\N
381	0.0000	42	11	0	\N
382	0.0000	42	30	0	\N
383	0.0000	42	37	0	\N
384	0.0000	43	29	0	\N
385	0.0000	43	35	0	\N
386	100.0000	43	36	0	\N
387	0.0000	43	32	0	\N
388	0.0000	43	31	0	\N
389	0.0000	43	104	0	\N
390	0.0000	43	34	0	\N
391	0.0000	43	11	0	\N
392	0.0000	43	30	0	\N
393	0.0000	43	37	0	\N
394	0.0000	44	29	0	\N
223	0.0000	15	13	0	\N
225	0.0000	15	14	0	\N
226	0.0000	15	19	0	\N
227	0.0000	15	26	0	\N
228	0.0000	15	23	0	\N
229	0.0000	15	25	0	\N
230	0.0000	15	17	0	\N
231	0.0000	15	15	0	\N
232	0.0000	15	21	0	\N
395	0.0000	44	35	0	\N
396	0.0000	44	36	0	\N
397	100.0000	44	32	0	\N
398	0.0000	44	31	0	\N
399	0.0000	44	104	0	\N
400	0.0000	44	34	0	\N
401	0.0000	44	11	0	\N
402	0.0000	44	30	0	\N
403	0.0000	44	37	0	\N
404	0.0000	45	29	0	\N
405	0.0000	45	35	0	\N
406	0.0000	45	36	0	\N
407	0.0000	45	32	0	\N
408	100.0000	45	31	0	\N
409	0.0000	45	104	0	\N
410	0.0000	45	34	0	\N
411	0.0000	45	11	0	\N
412	0.0000	45	30	0	\N
413	0.0000	45	37	0	\N
414	0.0000	46	29	0	\N
415	0.0000	46	35	0	\N
416	0.0000	46	36	0	\N
417	0.0000	46	32	0	\N
418	0.0000	46	31	0	\N
419	100.0000	46	104	0	\N
420	0.0000	46	34	0	\N
421	0.0000	46	11	0	\N
422	0.0000	46	30	0	\N
423	0.0000	46	37	0	\N
424	0.0000	47	29	0	\N
425	0.0000	47	35	0	\N
426	0.0000	47	36	0	\N
427	0.0000	47	32	0	\N
428	0.0000	47	31	0	\N
429	0.0000	47	104	0	\N
430	0.0000	47	34	0	\N
431	0.0000	47	11	0	\N
432	100.0000	47	30	0	\N
433	0.0000	47	37	0	\N
434	0.0000	48	29	0	\N
435	0.0000	48	35	0	\N
436	0.0000	48	36	0	\N
437	0.0000	48	32	0	\N
438	0.0000	48	31	0	\N
439	0.0000	48	104	0	\N
440	0.0000	48	34	0	\N
441	0.0000	48	11	0	\N
442	0.0000	48	30	0	\N
443	100.0000	48	37	0	\N
444	0.0000	50	39	0	\N
445	100.0000	50	38	0	\N
446	0.0000	50	105	0	\N
447	0.0000	50	29	0	\N
448	0.0000	50	40	0	\N
449	0.0000	50	47	0	\N
450	0.0000	50	45	0	\N
451	0.0000	50	36	0	\N
452	0.0000	50	48	0	\N
453	0.0000	50	109	0	\N
454	0.0000	50	42	0	\N
455	0.0000	50	108	0	\N
456	0.0000	50	41	0	\N
457	0.0000	50	34	0	\N
458	0.0000	50	51	0	\N
459	0.0000	50	11	0	\N
460	0.0000	50	50	0	\N
461	0.0000	50	30	0	\N
462	0.0000	50	106	0	\N
463	100.0000	51	39	0	\N
464	0.0000	51	38	0	\N
465	0.0000	51	105	0	\N
466	0.0000	51	29	0	\N
467	0.0000	51	40	0	\N
468	0.0000	51	47	0	\N
469	0.0000	51	45	0	\N
470	0.0000	51	36	0	\N
471	0.0000	51	48	0	\N
472	0.0000	51	109	0	\N
473	0.0000	51	42	0	\N
474	0.0000	51	108	0	\N
475	0.0000	51	41	0	\N
476	0.0000	51	34	0	\N
477	0.0000	51	51	0	\N
478	0.0000	51	11	0	\N
479	0.0000	51	50	0	\N
480	0.0000	51	30	0	\N
481	0.0000	51	106	0	\N
482	0.0000	52	39	0	\N
483	0.0000	52	38	0	\N
484	0.0000	52	105	0	\N
485	0.0000	52	29	0	\N
486	100.0000	52	40	0	\N
487	0.0000	52	47	0	\N
488	0.0000	52	45	0	\N
489	0.0000	52	36	0	\N
490	0.0000	52	48	0	\N
491	0.0000	52	109	0	\N
492	0.0000	52	42	0	\N
493	0.0000	52	108	0	\N
494	0.0000	52	41	0	\N
495	0.0000	52	34	0	\N
496	0.0000	52	51	0	\N
497	0.0000	52	11	0	\N
498	0.0000	52	50	0	\N
499	0.0000	52	30	0	\N
500	0.0000	52	106	0	\N
501	0.0000	53	39	0	\N
502	0.0000	53	38	0	\N
503	0.0000	53	105	0	\N
504	0.0000	53	29	0	\N
505	0.0000	53	40	0	\N
506	0.0000	53	47	0	\N
507	0.0000	53	45	0	\N
508	0.0000	53	36	0	\N
509	0.0000	53	48	0	\N
510	0.0000	53	109	0	\N
511	0.0000	53	42	0	\N
512	0.0000	53	108	0	\N
513	100.0000	53	41	0	\N
514	0.0000	53	34	0	\N
515	0.0000	53	51	0	\N
516	0.0000	53	11	0	\N
517	0.0000	53	50	0	\N
518	0.0000	53	30	0	\N
519	0.0000	53	106	0	\N
520	0.0000	54	39	0	\N
521	0.0000	54	38	0	\N
522	0.0000	54	105	0	\N
523	0.0000	54	29	0	\N
524	0.0000	54	40	0	\N
525	0.0000	54	47	0	\N
526	0.0000	54	45	0	\N
527	0.0000	54	36	0	\N
528	0.0000	54	48	0	\N
529	0.0000	54	109	0	\N
530	100.0000	54	42	0	\N
531	0.0000	54	108	0	\N
532	0.0000	54	41	0	\N
533	0.0000	54	34	0	\N
534	0.0000	54	51	0	\N
535	0.0000	54	11	0	\N
536	0.0000	54	50	0	\N
537	0.0000	54	30	0	\N
538	0.0000	54	106	0	\N
539	0.0000	55	39	0	\N
540	0.0000	55	38	0	\N
541	100.0000	55	105	0	\N
542	0.0000	55	29	0	\N
543	0.0000	55	40	0	\N
544	0.0000	55	47	0	\N
545	0.0000	55	45	0	\N
546	0.0000	55	36	0	\N
547	0.0000	55	48	0	\N
548	0.0000	55	109	0	\N
549	0.0000	55	42	0	\N
550	0.0000	55	108	0	\N
551	0.0000	55	41	0	\N
552	0.0000	55	34	0	\N
553	0.0000	55	51	0	\N
554	0.0000	55	11	0	\N
555	0.0000	55	50	0	\N
556	0.0000	55	30	0	\N
557	0.0000	55	106	0	\N
558	0.0000	56	39	0	\N
559	0.0000	56	38	0	\N
560	0.0000	56	105	0	\N
561	0.0000	56	29	0	\N
562	0.0000	56	40	0	\N
563	0.0000	56	47	0	\N
564	0.0000	56	45	0	\N
565	0.0000	56	36	0	\N
566	0.0000	56	48	0	\N
567	0.0000	56	109	0	\N
568	0.0000	56	42	0	\N
569	0.0000	56	108	0	\N
570	0.0000	56	41	0	\N
571	0.0000	56	34	0	\N
572	0.0000	56	51	0	\N
573	0.0000	56	11	0	\N
574	0.0000	56	50	0	\N
575	100.0000	56	30	0	\N
576	0.0000	56	106	0	\N
577	0.0000	57	39	0	\N
578	0.0000	57	38	0	\N
579	0.0000	57	105	0	\N
580	0.0000	57	29	0	\N
581	0.0000	57	40	0	\N
582	0.0000	57	47	0	\N
583	0.0000	57	45	0	\N
584	0.0000	57	36	0	\N
585	0.0000	57	48	0	\N
586	0.0000	57	109	0	\N
587	0.0000	57	42	0	\N
588	0.0000	57	108	0	\N
589	0.0000	57	41	0	\N
590	0.0000	57	34	0	\N
591	0.0000	57	51	0	\N
592	0.0000	57	11	0	\N
593	0.0000	57	50	0	\N
594	100.0000	57	30	0	\N
595	0.0000	57	106	0	\N
596	0.0000	58	39	0	\N
597	0.0000	58	38	0	\N
598	0.0000	58	105	0	\N
599	0.0000	58	29	0	\N
600	0.0000	58	40	0	\N
601	0.0000	58	47	0	\N
602	100.0000	58	45	0	\N
603	0.0000	58	36	0	\N
604	0.0000	58	48	0	\N
605	0.0000	58	109	0	\N
606	0.0000	58	42	0	\N
607	0.0000	58	108	0	\N
608	0.0000	58	41	0	\N
609	0.0000	58	34	0	\N
610	0.0000	58	51	0	\N
611	0.0000	58	11	0	\N
612	0.0000	58	50	0	\N
613	0.0000	58	30	0	\N
614	0.0000	58	106	0	\N
615	0.0000	59	39	0	\N
616	0.0000	59	38	0	\N
617	0.0000	59	105	0	\N
618	0.0000	59	29	0	\N
619	0.0000	59	40	0	\N
620	0.0000	59	47	0	\N
621	100.0000	59	45	0	\N
622	0.0000	59	36	0	\N
623	0.0000	59	48	0	\N
624	0.0000	59	109	0	\N
625	0.0000	59	42	0	\N
626	0.0000	59	108	0	\N
627	0.0000	59	41	0	\N
628	0.0000	59	34	0	\N
629	0.0000	59	51	0	\N
630	0.0000	59	11	0	\N
631	0.0000	59	50	0	\N
632	0.0000	59	30	0	\N
633	0.0000	59	106	0	\N
634	0.0000	60	39	0	\N
635	0.0000	60	38	0	\N
636	0.0000	60	105	0	\N
637	0.0000	60	29	0	\N
638	0.0000	60	40	0	\N
639	0.0000	60	47	0	\N
640	0.0000	60	45	0	\N
641	100.0000	60	36	0	\N
642	0.0000	60	48	0	\N
643	0.0000	60	109	0	\N
644	0.0000	60	42	0	\N
645	0.0000	60	108	0	\N
646	0.0000	60	41	0	\N
647	0.0000	60	34	0	\N
648	0.0000	60	51	0	\N
649	0.0000	60	11	0	\N
650	0.0000	60	50	0	\N
651	0.0000	60	30	0	\N
652	0.0000	60	106	0	\N
653	0.0000	61	39	0	\N
654	0.0000	61	38	0	\N
655	0.0000	61	105	0	\N
656	0.0000	61	29	0	\N
657	0.0000	61	40	0	\N
658	0.0000	61	47	0	\N
659	0.0000	61	45	0	\N
660	100.0000	61	36	0	\N
661	0.0000	61	48	0	\N
662	0.0000	61	109	0	\N
663	0.0000	61	42	0	\N
664	0.0000	61	108	0	\N
665	0.0000	61	41	0	\N
666	0.0000	61	34	0	\N
667	0.0000	61	51	0	\N
668	0.0000	61	11	0	\N
669	0.0000	61	50	0	\N
670	0.0000	61	30	0	\N
671	0.0000	61	106	0	\N
672	0.0000	62	39	0	\N
673	0.0000	62	38	0	\N
674	0.0000	62	105	0	\N
675	100.0000	62	29	0	\N
676	0.0000	62	40	0	\N
677	0.0000	62	47	0	\N
678	0.0000	62	45	0	\N
679	0.0000	62	36	0	\N
680	0.0000	62	48	0	\N
681	0.0000	62	109	0	\N
682	0.0000	62	42	0	\N
683	0.0000	62	108	0	\N
684	0.0000	62	41	0	\N
685	0.0000	62	34	0	\N
686	0.0000	62	51	0	\N
687	0.0000	62	11	0	\N
688	0.0000	62	50	0	\N
689	0.0000	62	30	0	\N
690	0.0000	62	106	0	\N
691	0.0000	63	39	0	\N
692	0.0000	63	38	0	\N
693	0.0000	63	105	0	\N
694	100.0000	63	29	0	\N
695	0.0000	63	40	0	\N
696	0.0000	63	47	0	\N
697	0.0000	63	45	0	\N
698	0.0000	63	36	0	\N
699	0.0000	63	48	0	\N
700	0.0000	63	109	0	\N
701	0.0000	63	42	0	\N
702	0.0000	63	108	0	\N
703	0.0000	63	41	0	\N
704	0.0000	63	34	0	\N
705	0.0000	63	51	0	\N
706	0.0000	63	11	0	\N
707	0.0000	63	50	0	\N
708	0.0000	63	30	0	\N
709	0.0000	63	106	0	\N
710	0.0000	64	39	0	\N
711	0.0000	64	38	0	\N
712	0.0000	64	105	0	\N
713	100.0000	64	29	0	\N
714	0.0000	64	40	0	\N
715	0.0000	64	47	0	\N
716	0.0000	64	45	0	\N
717	0.0000	64	36	0	\N
718	0.0000	64	48	0	\N
719	0.0000	64	109	0	\N
720	0.0000	64	42	0	\N
721	0.0000	64	108	0	\N
722	0.0000	64	41	0	\N
723	0.0000	64	34	0	\N
724	0.0000	64	51	0	\N
725	0.0000	64	11	0	\N
726	0.0000	64	50	0	\N
727	0.0000	64	30	0	\N
728	0.0000	64	106	0	\N
729	0.0000	65	39	0	\N
730	0.0000	65	38	0	\N
731	0.0000	65	105	0	\N
732	100.0000	65	29	0	\N
733	0.0000	65	40	0	\N
734	0.0000	65	47	0	\N
735	0.0000	65	45	0	\N
736	0.0000	65	36	0	\N
737	0.0000	65	48	0	\N
738	0.0000	65	109	0	\N
739	0.0000	65	42	0	\N
740	0.0000	65	108	0	\N
741	0.0000	65	41	0	\N
742	0.0000	65	34	0	\N
743	0.0000	65	51	0	\N
744	0.0000	65	11	0	\N
745	0.0000	65	50	0	\N
746	0.0000	65	30	0	\N
747	0.0000	65	106	0	\N
748	0.0000	66	39	0	\N
749	0.0000	66	38	0	\N
750	0.0000	66	105	0	\N
751	0.0000	66	29	0	\N
752	0.0000	66	40	0	\N
753	100.0000	66	47	0	\N
754	0.0000	66	45	0	\N
755	0.0000	66	36	0	\N
756	0.0000	66	48	0	\N
757	0.0000	66	109	0	\N
758	0.0000	66	42	0	\N
759	0.0000	66	108	0	\N
760	0.0000	66	41	0	\N
761	0.0000	66	34	0	\N
762	0.0000	66	51	0	\N
763	0.0000	66	11	0	\N
764	0.0000	66	50	0	\N
765	0.0000	66	30	0	\N
766	0.0000	66	106	0	\N
767	0.0000	67	39	0	\N
768	0.0000	67	38	0	\N
769	0.0000	67	105	0	\N
770	0.0000	67	29	0	\N
771	0.0000	67	40	0	\N
772	0.0000	67	47	0	\N
773	0.0000	67	45	0	\N
774	0.0000	67	36	0	\N
775	100.0000	67	48	0	\N
776	0.0000	67	109	0	\N
777	0.0000	67	42	0	\N
778	0.0000	67	108	0	\N
779	0.0000	67	41	0	\N
780	0.0000	67	34	0	\N
781	0.0000	67	51	0	\N
782	0.0000	67	11	0	\N
783	0.0000	67	50	0	\N
784	0.0000	67	30	0	\N
785	0.0000	67	106	0	\N
786	0.0000	68	39	0	\N
787	0.0000	68	38	0	\N
788	0.0000	68	105	0	\N
789	0.0000	68	29	0	\N
790	0.0000	68	40	0	\N
791	0.0000	68	47	0	\N
792	0.0000	68	45	0	\N
793	0.0000	68	36	0	\N
794	0.0000	68	48	0	\N
795	0.0000	68	109	0	\N
796	0.0000	68	42	0	\N
797	0.0000	68	108	0	\N
798	0.0000	68	41	0	\N
799	0.0000	68	34	0	\N
800	0.0000	68	51	0	\N
801	0.0000	68	11	0	\N
802	0.0000	68	50	0	\N
803	0.0000	68	30	0	\N
804	100.0000	68	106	0	\N
805	0.0000	69	39	0	\N
806	0.0000	69	38	0	\N
807	0.0000	69	105	0	\N
808	0.0000	69	29	0	\N
809	0.0000	69	40	0	\N
810	0.0000	69	47	0	\N
811	0.0000	69	45	0	\N
812	0.0000	69	36	0	\N
813	0.0000	69	48	0	\N
814	0.0000	69	109	0	\N
815	0.0000	69	42	0	\N
816	100.0000	69	108	0	\N
817	0.0000	69	41	0	\N
818	0.0000	69	34	0	\N
819	0.0000	69	51	0	\N
820	0.0000	69	11	0	\N
821	0.0000	69	50	0	\N
822	0.0000	69	30	0	\N
823	0.0000	69	106	0	\N
824	0.0000	70	39	0	\N
825	0.0000	70	38	0	\N
826	0.0000	70	105	0	\N
827	0.0000	70	29	0	\N
828	0.0000	70	40	0	\N
829	0.0000	70	47	0	\N
830	0.0000	70	45	0	\N
831	0.0000	70	36	0	\N
832	0.0000	70	48	0	\N
833	100.0000	70	109	0	\N
834	0.0000	70	42	0	\N
835	0.0000	70	108	0	\N
836	0.0000	70	41	0	\N
837	0.0000	70	34	0	\N
838	0.0000	70	51	0	\N
839	0.0000	70	11	0	\N
840	0.0000	70	50	0	\N
841	0.0000	70	30	0	\N
842	0.0000	70	106	0	\N
843	0.0000	71	39	0	\N
844	0.0000	71	38	0	\N
845	0.0000	71	105	0	\N
846	0.0000	71	29	0	\N
847	0.0000	71	40	0	\N
848	0.0000	71	47	0	\N
849	0.0000	71	45	0	\N
850	0.0000	71	36	0	\N
851	0.0000	71	48	0	\N
852	0.0000	71	109	0	\N
853	0.0000	71	42	0	\N
854	0.0000	71	108	0	\N
855	0.0000	71	41	0	\N
856	0.0000	71	34	0	\N
857	0.0000	71	51	0	\N
858	0.0000	71	11	0	\N
859	100.0000	71	50	0	\N
860	0.0000	71	30	0	\N
861	0.0000	71	106	0	\N
862	0.0000	72	39	0	\N
863	0.0000	72	38	0	\N
864	0.0000	72	105	0	\N
865	0.0000	72	29	0	\N
866	0.0000	72	40	0	\N
867	0.0000	72	47	0	\N
868	0.0000	72	45	0	\N
869	0.0000	72	36	0	\N
870	0.0000	72	48	0	\N
871	0.0000	72	109	0	\N
872	0.0000	72	42	0	\N
873	0.0000	72	108	0	\N
874	0.0000	72	41	0	\N
875	0.0000	72	34	0	\N
876	0.0000	72	51	0	\N
877	100.0000	72	11	0	\N
878	0.0000	72	50	0	\N
879	0.0000	72	30	0	\N
880	0.0000	72	106	0	\N
881	0.0000	73	39	0	\N
882	0.0000	73	38	0	\N
883	0.0000	73	105	0	\N
884	0.0000	73	29	0	\N
885	0.0000	73	40	0	\N
886	0.0000	73	47	0	\N
887	0.0000	73	45	0	\N
888	0.0000	73	36	0	\N
889	0.0000	73	48	0	\N
890	0.0000	73	109	0	\N
891	0.0000	73	42	0	\N
892	0.0000	73	108	0	\N
893	0.0000	73	41	0	\N
894	0.0000	73	34	0	\N
895	0.0000	73	51	0	\N
896	100.0000	73	11	0	\N
897	0.0000	73	50	0	\N
898	0.0000	73	30	0	\N
899	0.0000	73	106	0	\N
900	0.0000	74	39	0	\N
901	0.0000	74	38	0	\N
902	0.0000	74	105	0	\N
903	0.0000	74	29	0	\N
904	0.0000	74	40	0	\N
905	0.0000	74	47	0	\N
906	0.0000	74	45	0	\N
907	0.0000	74	36	0	\N
908	0.0000	74	48	0	\N
909	0.0000	74	109	0	\N
910	0.0000	74	42	0	\N
911	0.0000	74	108	0	\N
912	0.0000	74	41	0	\N
913	0.0000	74	34	0	\N
914	0.0000	74	51	0	\N
915	100.0000	74	11	0	\N
916	0.0000	74	50	0	\N
917	0.0000	74	30	0	\N
918	0.0000	74	106	0	\N
919	0.0000	75	39	0	\N
920	0.0000	75	38	0	\N
921	0.0000	75	105	0	\N
922	0.0000	75	29	0	\N
923	0.0000	75	40	0	\N
924	0.0000	75	47	0	\N
925	0.0000	75	45	0	\N
926	0.0000	75	36	0	\N
927	0.0000	75	48	0	\N
928	0.0000	75	109	0	\N
929	0.0000	75	42	0	\N
930	0.0000	75	108	0	\N
931	0.0000	75	41	0	\N
932	0.0000	75	34	0	\N
933	0.0000	75	51	0	\N
934	100.0000	75	11	0	\N
935	0.0000	75	50	0	\N
936	0.0000	75	30	0	\N
937	0.0000	75	106	0	\N
938	0.0000	76	39	0	\N
939	0.0000	76	38	0	\N
940	0.0000	76	105	0	\N
941	0.0000	76	29	0	\N
942	0.0000	76	40	0	\N
943	0.0000	76	47	0	\N
944	0.0000	76	45	0	\N
945	0.0000	76	36	0	\N
946	0.0000	76	48	0	\N
947	0.0000	76	109	0	\N
948	0.0000	76	42	0	\N
949	0.0000	76	108	0	\N
950	0.0000	76	41	0	\N
951	0.0000	76	34	0	\N
952	100.0000	76	51	0	\N
953	0.0000	76	11	0	\N
954	0.0000	76	50	0	\N
955	0.0000	76	30	0	\N
956	0.0000	76	106	0	\N
957	0.0000	77	39	0	\N
958	0.0000	77	38	0	\N
959	0.0000	77	105	0	\N
960	0.0000	77	29	0	\N
961	0.0000	77	40	0	\N
962	0.0000	77	47	0	\N
963	0.0000	77	45	0	\N
964	0.0000	77	36	0	\N
965	0.0000	77	48	0	\N
966	0.0000	77	109	0	\N
967	0.0000	77	42	0	\N
968	0.0000	77	108	0	\N
969	0.0000	77	41	0	\N
970	0.0000	77	34	0	\N
971	100.0000	77	51	0	\N
972	0.0000	77	11	0	\N
973	0.0000	77	50	0	\N
974	0.0000	77	30	0	\N
975	0.0000	77	106	0	\N
976	0.0000	79	39	0	\N
977	0.0000	79	38	0	\N
978	0.0000	79	105	0	\N
979	0.0000	79	29	0	\N
980	0.0000	79	40	0	\N
981	0.0000	79	47	0	\N
982	0.0000	79	45	0	\N
983	0.0000	79	36	0	\N
984	0.0000	79	48	0	\N
985	0.0000	79	109	0	\N
986	0.0000	79	42	0	\N
987	0.0000	79	108	0	\N
988	0.0000	79	41	0	\N
989	100.0000	79	34	0	\N
990	0.0000	79	51	0	\N
991	0.0000	79	11	0	\N
992	0.0000	79	50	0	\N
993	0.0000	79	30	0	\N
994	0.0000	79	106	0	\N
995	0.0000	78	39	0	\N
996	0.0000	78	38	0	\N
997	0.0000	78	105	0	\N
998	0.0000	78	29	0	\N
999	0.0000	78	40	0	\N
1000	0.0000	78	47	0	\N
1001	0.0000	78	45	0	\N
1002	0.0000	78	36	0	\N
1003	0.0000	78	48	0	\N
1004	0.0000	78	109	0	\N
1005	0.0000	78	42	0	\N
1006	0.0000	78	108	0	\N
1007	0.0000	78	41	0	\N
1008	100.0000	78	34	0	\N
1009	0.0000	78	51	0	\N
1010	0.0000	78	11	0	\N
1011	0.0000	78	50	0	\N
1012	0.0000	78	30	0	\N
1013	0.0000	78	106	0	\N
1014	0.0000	40	107	0	\N
1015	0.0000	40	13	0	\N
1016	0.0000	40	22	0	\N
1017	0.0000	40	14	0	\N
1018	100.0000	40	34	0	\N
1019	0.0000	40	19	0	\N
1020	0.0000	40	26	0	\N
1021	0.0000	40	23	0	\N
1022	0.0000	40	11	0	\N
1023	0.0000	40	27	0	\N
1024	0.0000	40	25	0	\N
1025	0.0000	40	17	0	\N
1026	0.0000	40	15	0	\N
1027	0.0000	40	21	0	\N
1028	0.0000	15	34	0	\N
222	100.0000	15	107	0	\N
224	0.0000	15	22	0	\N
17	0.0000	15	11	0	\N
1042	0.0000	80	39	0	\N
1043	0.0000	80	29	0	\N
1044	0.0000	80	35	0	\N
1045	0.0000	80	36	0	\N
1046	0.0000	80	32	0	\N
1047	0.0000	80	31	0	\N
1048	0.0000	80	104	0	\N
1049	0.0000	80	34	0	\N
1050	100.0000	80	11	0	\N
1051	0.0000	80	30	0	\N
1052	0.0000	80	37	0	\N
\.


--
-- Data for Name: entidades; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.entidades (id, razon_social, calle, numero, piso_departamento, celular, whatsapp, email, observaciones, cuit, situacion_iva, datos_varios, localidad_id, tipos_entidad, estado, fecha_baja, proyecto_id) FROM stdin;
1	Juan Pérez	qqqqq	2222		999 999999				\N	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
2	José García	wwwww	3333		888 888888				\N	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
3	Pedro López	eeeeee	4444		777 777777				\N	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
4	Proveedor materiales XX	ttttttttttt	444444444					proveedor materiales construcción	\N	\N	\N	16353	{"tipos_entidad":["1","2"]}	1	\N	\N
7	inversor zzzz							prueba de conbinación de entidades	\N	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
6	Proveedor 2	sss	222						\N	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
54	Confluencia 								30715378716	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
68	Hormiwhite								30715264303	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
55	Transporte E.G								30708375582	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
10	Promar								\N	\N	\N	16353	{"tipos_entidad":["1","2"]}	1	\N	\N
56	Escribania Dalla Villa								23180098879	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
57	Escribania Mendez								20255765540	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
58	Bahia Verde								30708808845	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
59	Bacci Alejandro- Electricista								20286649190	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
60	Bonzini 								20180029991	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
61	Coto Pinturerias								20128361880	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
69	Digital Import								30709782130	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
16	Jorge Edgardo Schneider								20180027913	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
29	Benedictino S.A								30710596766	\N	\N	16353	{"tipos_entidad":["1","2"]}	0	\N	\N
30	Rubenacker Alexis								2026549529	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
31	Matarazzo Antonio								23134613319	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
32	Malan Juan Pablo								20255176642	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
33	Azpiroz Martin Ignacio								23181286229	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
35	Dahir Diego 								20220496563	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
36	Ferraris Roberto Alfedo								20171298056	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
37	Sardi Ricardo Hugo								20185112897	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
41	Neschenko Paola Vanesa								27252068541	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
42	Laco Leandro Luis								20282964547	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
44	Alexis Rubenacker y Andrea								\N	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
46	Roberto Alfredo Ferraris								20172798056	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
47	Diaz Javier Agustin								20334151949	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
62	Aceros Dahir								30711503362	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
12	ATUNS								30549568617	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
63	Devic Hormigon								30707940200	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
64	DJM 								30710828594	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
65	Ecoservicios								30715115588	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
66	Fenestra								30710346905	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
67	Hoch Ascensores								30708388315	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
52	Años Luz								30650178218	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
70	Shneider Jorge								20180027913	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
71	Vitrum 								30714810118	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
72	Saipo Distribuidora								27325866700	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
73	Stremel Pablo								20254472908	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
74	Rossomando Juan Antonio								20055078530	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
75	Roque Arena								20125912975	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
76	ah sistemas								20132545066	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
77	Bahia Clima								30716108267	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
13	Franz Pablo Bruno 								20172798985	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
14	Manceñido Buide Daiana 								23299562484	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
15	Schneider Jorge Edgardo 								20180027913	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
17	Randone Claudio Fabian 								20172801820	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
24	Paoloni Norma 								27161187513	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
19	Petz Dario Hernan 								20244838422	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
20	Franz Pablo Bruno								20172798985	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
22	Grioli Roberto 								20167391878	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
28	Belleggia Sandra Edith 								27181287816	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
25	Ramos Marcelo 								20205296310	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
26	Petz Fabricio Enrique 								20298115655	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
27	Ramos Lionel Norman 								23182773409	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
34	Perrone Dario								20176470136	\N	\N	16353	{"tipos_entidad":["1","2"]}	0	\N	\N
38	Alterio Juan Carlos 								20103760446	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
39	 Colombero Gabriel Jose 								20148281999	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
40	Colombero Adriana Rosa 								27175967503	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
18	Ferrero Sandra Monica 								27172797240	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
45	Fardighini Federico Jose 								20282961696	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
48	Garcia Adrian  								20223287086	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
50	Pugliese Constanza Laura 								27329782013	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
53	Islas Carlos 								30529046576	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
49	Sgalippa Karina Veronica								27226439396	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
43	 Amaolo Sofia 								27290560441	\N	\N	16353	{"tipos_entidad":["1"]}	1	\N	\N
78	Jancovic Mirko								20257864422	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
79	Betini herrajes								30714220779	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
51	Pocai Gabriel 								20180029274	\N	\N	16353	{"tipos_entidad":["1","3"]}	0	\N	\N
80	Christi Ernesto								20200446705	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
81	Contenedores Morandi								30709551627	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
82	El mundo del bulon								20160683326	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
83	Expreso Interprovincial								33641261799	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
84	Fidetrust								30709441716	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
85	GHK Servicios								20265186204	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
86	Joy Amoblamientos								30714592714	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
87	Mancini Materiales electricos								20216246293	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
88	Saez Hector David								20205629026	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
89	Olave Laila								27300222345	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
90	Bernardi Erica								27271957918	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
91	Transporte Versat								30707475680	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
92	Metalurgica Don Bosco								30708025298	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
93	Pintureria Patagonia								30709470139	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
94	Rosa Juan sebastian								20322346256	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
95	Mendoclima								30710553641	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
21	Tamone Miguel Angel								20103463050	\N	\N	16353	{"tipos_entidad":["1","2"]}	0	\N	\N
96	Tapitel								30700939797	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
97	Tecnohome								3070909418536	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
98	Zingueria del Sur								30716894033	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
99	Perrone Emiliano								20375518865	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
100	Gili 								30561289278	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
101	Codimat								30540889356	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
102	Vanda Emilio								20145009791	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
103	Guala								30715331469	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
23	Pirola Gabriel Heber 								20124738289	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
104	Orio S.A								30707315756	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
105	Amaolo Sofia								27290560441	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
106	Sgalipa Karina Veronica								27226439396	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
107	Atuns								30549568617	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
108	Lascas SRL								30711449813	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
109	Iribas Rafael								20260943716	\N	\N	16353	{"tipos_entidad":["1"]}	0	\N	\N
110	Alvarez Gallardo Francisco								20437401846	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
111	Stremel Emiliano Ezaquiel								20472793293	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
11	Promar S.R.l								30562496846	\N	\N	16353	{"tipos_entidad":["1","2"]}	0	\N	\N
113	FERROMUNDO								30711463514	\N	\N	7755	{"tipos_entidad":["2"]}	0	\N	\N
114	Genesis construccion en seco	Scalabrini Ortiz 	1225						20387914499	\N	\N	16353	{"tipos_entidad":["2"]}	0	\N	\N
115	Alquila Todo Neuquen	J J Lastra	1634						30716628082	\N	\N	7755	{"tipos_entidad":["2"]}	0	\N	\N
112	Pocai Gabriel								20000000006	\N	\N	16353	{"tipos_entidad":["3"]}	1	2024-04-24 10:48:47.078527	\N
116	Rodriguez- Oficina								37551886	\N	\N	16353	{"tipos_entidad":["3"]}	0	\N	\N
117	Micser S.R.L								30707463690	\N	\N	16353	{"tipos_entidad":["3"]}	0	\N	\N
118	Fideicomiso Islas Malvinas	xx	11						111111111	\N	\N	16353	{"tipos_entidad":["3"]}	0	\N	4
\.


--
-- Data for Name: informes_proyectos; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.informes_proyectos (id, proyecto_id, estado, entidad_id, fecha_baja) FROM stdin;
\.


--
-- Data for Name: localidades; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.localidades (id, nombre, cp, estado, provincia_id) FROM stdin;
1111	CABEZA DE CHANCHO	3061	0	21
1112	CAMPO GARAY	3066	0	21
1113	CAMPO SAN JOSE	3060	0	21
1114	COLONIA INDEPENDENCIA	3066	0	21
1115	COLONIA MONTEFIORE	2341	0	21
1116	EL AMARGO	3060	0	21
1117	EL MARIANO	3060	0	21
1118	EL NOCHERO	3061	0	21
1119	ESTANCIA LA CIGUE	3060	0	21
1120	ESTEBAN RAMS	3066	0	21
1121	FORTIN ALERTA	3066	0	21
1122	FORTIN ARGENTINA	3060	0	21
1123	FORTIN ATAHUALPA	3061	0	21
1124	FORTIN CACIQUE	3060	0	21
1125	FORTIN SEIS DE CABALLERIA	3061	0	21
1126	FORTIN TOSTADO	3060	0	21
1127	GATO COLORADO	3541	0	21
1128	GREGORIA PEREZ DE DENIS	3061	0	21
1129	INDEPENDENCIA	3060	0	21
1130	KILOMETRO 293	3066	0	21
1131	KILOMETRO 389	3061	0	21
1132	KILOMETRO 421	3061	0	21
1133	KILOMETRO 468	3061	0	21
1134	LA BOMBILLA	3060	0	21
1135	LA ELSA	2341	0	21
1136	LA MARINA	2341	0	21
1137	LAS CHU	3061	0	21
1138	LOGRO	3066	0	21
1139	LOS CHARABONES	3060	0	21
1140	NUEVA ITALIA	3074	0	21
1141	PADRE PEDRO ITURRALDE	3061	0	21
1142	PORTALIS	3066	0	21
1143	POZO BORRADO	3061	0	21
1144	PUEBLO NUEVO	2124	0	21
1145	SANTA MARGARITA	3061	0	21
1146	TOSTADO	3060	0	21
1147	TRES POZOS	3061	0	21
1148	VILLA MINETTI	3061	0	21
1149	ANTONIO PINI	3061	0	21
1150	ARMSTRONG	2508	0	21
1151	BOUQUET	2523	0	21
1152	CAMPO CHARO	2512	0	21
1153	CAMPO GIMBATTI	2508	0	21
1154	CAMPO LA AMISTAD	2508	0	21
1155	CAMPO LA PAZ	2512	0	21
1156	CAMPO LA RIVIERE	2505	0	21
1157	CAMPO SANTA ISABEL	2505	0	21
1158	ITURRASPE	2521	0	21
1159	LA CALIFORNIA	2520	0	21
1160	LAS PAREJAS	2505	0	21
1161	LAS ROSAS	2520	0	21
1162	MONTES DE OCA	2521	0	21
1163	SAN GUILLERMO	2512	0	21
1164	TORTUGAS	2512	0	21
1165	ARTEAGA	2187	0	21
1166	BERABEVU	2639	0	21
1167	BIGAND	2177	0	21
1168	CAMPO CRENNA	2185	0	21
1169	CAMPO NUEVO	2639	0	21
1170	CAMPO PESOA	2173	0	21
1171	CANDELARIA SUD	2170	0	21
1172	CASILDA	2170	0	21
1173	CHABAS	2173	0	21
1174	CHA	2643	0	21
1175	COLONIA CANDELARIA	2170	0	21
1176	COLONIA FERNANDEZ	2639	0	21
1177	COLONIA GOMEZ	2639	0	21
1178	COLONIA HANSEN	2637	0	21
1179	COLONIA LA  CATALANA	2637	0	21
1180	COLONIA LA  PALENCIA	2639	0	21
1181	COLONIA LA  PELLEGRINI	2639	0	21
1182	COLONIA LA COSTA	2170	0	21
1183	COLONIA LAGO DI COMO	2187	0	21
1184	COLONIA PIAMONTESA	2639	0	21
1185	COLONIA SANTA NATALIA	2639	0	21
1186	COLONIA TOSCANA PRIMERA	2185	0	21
1187	COLONIA TOSCANA SEGUNDA	2185	0	21
1188	COLONIA VALENCIA	2639	0	21
1189	CUATRO ESQUINAS	2639	0	21
1190	GODEKEN	2639	0	21
1191	LA MERCED	2173	0	21
1192	LA VIUDA	2183	0	21
1193	LOS MOLINOS	2181	0	21
1194	LOS NOGALES	2183	0	21
1195	LOS QUIRQUINCHOS	2637	0	21
1196	PUEBLO AREQUITO	2183	0	21
1197	SAN JOSE DE LA ESQUINA	2185	0	21
1198	SANFORD	2173	0	21
1199	SANTA NATALIA	2639	0	21
1200	VILLADA	2173	0	21
1201	ADOLFO ALSINA	2311	0	21
1202	ANGELICA	2303	0	21
1203	ATALIVA	2307	0	21
1206	AURELIA	2318	0	21
1207	BAUER Y SIGEL	2403	0	21
1208	BELLA ITALIA	2301	0	21
1209	CABA	2322	0	21
1210	CAMPO CLUCELLAS	2407	0	21
1211	CAMPO DARATTI	2307	0	21
1212	CAMPO ROMERO	2407	0	21
1213	CAMPO TORQUINSTON	2403	0	21
1214	CAMPO ZURBRIGGEN	2407	0	21
1215	CAPILLA SAN JOSE	2301	0	21
1216	CASABLANCA	2317	0	21
1217	PLAZA CLUCELLAS	2407	0	21
1218	COLONIA ALDAO	2317	0	21
1219	COLONIA BELLA ITALIA	2300	0	21
1220	COLONIA BICHA	2317	0	21
1221	COLONIA BIGAND	2317	0	21
1222	BOSSI	2326	0	21
1223	COLONIA CASTELLANOS	2301	0	21
1224	COLONIA CELLO	2405	0	21
1225	FIDELA	2301	0	21
1226	COLONIA JOSEFINA	2403	0	21
1227	COLONIA MARGARITA	2443	0	21
1228	COLONIA MAUA	2311	0	21
1229	COLONIA REINA MARGARITA	2309	0	21
1230	COLONIA SAN ANTONIO	2301	0	21
1231	COLONIA TACURALES	2324	0	21
1232	CONSTANZA	2311	0	21
1233	CORONEL FRAGA	2301	0	21
1234	CRISTOLIA	2445	0	21
1235	DESVIO BOERO	2415	0	21
1236	EGUSQUIZA	2301	0	21
1237	ESMERALDA	2456	0	21
1238	ESTACION CLUCELLAS	2407	0	21
1239	ESTACION JOSEFINA	2403	0	21
1240	ESTACION SAGUIER	2315	0	21
1241	ESTRADA	2409	0	21
1242	SANTA EUSEBIA	2317	0	21
1243	EUSTOLIA	2407	0	21
1244	FRONTERA	2438	0	21
1245	GALISTEO	2307	0	21
1246	GARIBALDI	2443	0	21
1247	HUMBERTO PRIMERO	2309	0	21
1248	JOSE MANUEL ESTRADA	2403	0	21
1249	KILOMETRO 113	2407	0	21
1250	KILOMETRO 483	2456	0	21
1251	KILOMETRO 501	2438	0	21
1252	KILOMETRO 85	2303	0	21
1253	LEHMANN	2305	0	21
1254	LOS SEMBRADOS	2447	0	21
1255	MANGORE	2445	0	21
1256	MARIA JUANA	2445	0	21
1257	MONIGOTES	2342	0	21
1258	PALACIOS	2326	0	21
1259	PRESIDENTE ROCA	2301	0	21
1260	PUEBLO MARIA JUANA	2445	0	21
1261	MARINI	2301	0	21
1262	RAMONA	2301	0	21
1263	PUEBLO SAN ANTONIO	2301	0	21
1264	RAFAELA	2300	0	21
1265	RAQUEL	2322	0	21
1266	REINA MARGARITA	2309	0	21
1267	RINCON DE TACURALES	2317	0	21
1268	SAGUIER	2301	0	21
1269	SAN MIGUEL	2309	0	21
1270	SAN VICENTE	2447	0	21
1271	SANTA CLARA DE SAGUIER	2405	0	21
1272	SUNCHALES	2322	0	21
1273	SUSANA	2301	0	21
1274	TACURAL	2324	0	21
1275	VILA	2301	0	21
1276	VILLA SAN JOSE	2301	0	21
1277	VILLANI	2400	0	21
1278	VIRGINIA	2311	0	21
1279	ZANETTI	2301	0	21
1280	ZENON PEREYRA	2409	0	21
1281	CAMPO MAGNIN	3011	0	21
1282	CAMPO QUI	2258	0	21
1283	CAMPO RODRIGUEZ	2255	0	21
1284	CAVOUR	3081	0	21
1285	COLONIA ADOLFO ALSINA	3029	0	21
1286	COLONIA LA NUEVA	3081	0	21
1287	COLONIA MATILDE	3013	0	21
1288	COLONIA PUJOL	3080	0	21
1289	CORONEL RODRIGUEZ	3013	0	21
1290	CULULU	3023	0	21
1291	JACINTO L ARAUZ	3029	0	21
1292	EL TROPEZON	3009	0	21
1293	ELISA	3029	0	21
1294	EMPALME SAN CARLOS	3007	0	21
1295	ESPERANZA	3080	0	21
1296	ESTACION MATILDE	3013	0	21
1297	FELICIA	3087	0	21
1298	FRANCK	3009	0	21
1299	GRUTLY	3083	0	21
1300	GRUTLY NORTE	3083	0	21
1301	HIPATIA	3023	0	21
1302	HUMBOLDT	3081	0	21
1303	HUMBOLDT CHICO	3081	0	21
1304	ITUZAINGO	2311	0	21
1305	LA ORILLA	3080	0	21
1306	LA PELADA	3027	0	21
1307	LARRECHEA	3080	0	21
1308	LAS HIGUERITAS	3013	0	21
1309	LAS TUNAS	3009	0	21
1310	MARIA LUISA	3025	0	21
1311	MARIANO SAAVEDRA	3011	0	21
1312	NUEVO TORINO	3087	0	21
1313	PERICOTA	3025	0	21
1314	PILAR	3085	0	21
1315	PROGRESO	3023	0	21
1316	PROVIDENCIA	3025	0	21
1317	PUEBLO ABC	3080	0	21
1318	PUJATO NORTE	3080	0	21
1319	RINCON DEL PINTADO	3080	0	21
1320	RIVADAVIA	3081	0	21
1321	SA PEREYRA	3011	0	21
1322	SAN AGUSTIN	3017	0	21
1323	SAN CARLOS CENTRO	3013	0	21
1324	SAN CARLOS NORTE	3009	0	21
1325	SAN CARLOS SUD	3013	0	21
1326	SAN JERONIMO DEL SAUCE	3009	0	21
1327	SAN JERONIMO NORTE	3011	0	21
1328	SAN MARIANO	3011	0	21
1329	SANTA CLARA DE BUENA VISTA	2258	0	21
1330	SANTA MARIA CENTRO	3011	0	21
1331	SANTO DOMINGO	3025	0	21
1332	SARMIENTO	3023	0	21
1333	TOMAS ALVA EDISON	3023	0	21
1334	BOMBAL	2179	0	21
1335	CAMPO RUEDA	2109	0	21
1336	CA	2105	0	21
1337	CEPEDA	2105	0	21
1338	COLONIA VALDEZ	2115	0	21
1339	EL BAGUAL	2723	0	21
1340	EMPALME VILLA CONSTITUCION	2918	0	21
1341	ESTACION VILLA CONSTITUCION	2919	0	21
1342	FRANCISCO PAZ	2111	0	21
1343	GENERAL GELLY	2701	0	21
1344	GODOY	2921	0	21
1345	JUAN B MOLINA	2103	0	21
1346	JUNCAL	2723	0	21
1347	LA OTHILA	2115	0	21
1348	LA VANGUARDIA	2105	0	21
1349	LOMA VERDE	2117	0	21
1350	MAXIMO PAZ	2115	0	21
1351	ORATORIO MORANTE	2921	0	21
1352	PAVON	2918	0	21
1353	PAVON ARRIBA	2109	0	21
1354	PEYRANO	2113	0	21
1355	ALCORTA	2117	0	21
1356	RODOLFO ALCORTA	2115	0	21
1357	RUEDA	2921	0	21
1358	SANTA TERESA	2111	0	21
1359	SARGENTO CABRAL	2105	0	21
1360	STEPHENSON	2103	0	21
1361	THEOBALD	2918	0	21
1362	TRES ESQUINAS	2921	0	21
1363	VILLA CONSTITUCION	2919	0	21
1364	LA CELIA	2115	0	21
1366	AGUARA GRANDE	3071	0	21
1367	AMBROSETTI	2352	0	21
1368	BEALISTOCK	2326	0	21
1369	CAMPO BOTTO	2345	0	21
1370	CAMPO EL MATACO	2342	0	21
1371	CAPIVARA	2311	0	21
1372	CERES	2340	0	21
1373	COLONIA ANA	2345	0	21
1374	COLONIA BERLIN	2313	0	21
1375	COLONIA CLARA	3025	0	21
1376	COLONIA EL SIMBOL	3074	0	21
1377	COLONIA MACKINLAY	2347	0	21
1378	COLONIA MALHMAN SUD	2347	0	21
1379	COLONIA ORTIZ	2313	0	21
1380	COLONIA RIPAMONTI	2349	0	21
1381	COLONIA ROSA	2347	0	21
1382	CUATRO CASAS	2313	0	21
1383	CURUPAYTI	2342	0	21
1384	DOCE CASAS	2313	0	21
1385	EL AGUARA	3070	0	21
1386	HERSILIA	2352	0	21
1387	HUANQUEROS	3076	0	21
1388	HUGENTOBLER	2344	0	21
1389	KILOMETRO 235	3076	0	21
1390	LA CABRAL	3074	0	21
1391	LA CLARA	3025	0	21
1392	LA LUCILA	3072	0	21
1393	LA POLVAREDA	3074	0	21
1394	LA RUBIA	2342	0	21
1395	LA VERDE	3076	0	21
1396	LAGUNA VERDE	3076	0	21
1397	LAS AVISPAS	3074	0	21
1398	LAS PALMERAS	2326	0	21
1399	LOS MOLLES	3070	0	21
1400	MARIA EUGENIA	3072	0	21
1401	MOISES VILLE	2313	0	21
1402	MONTE OSCURIDAD	2349	0	21
1403	MUTCHNIK	2313	0	21
1404	PETRONILA	3046	0	21
1405	PORTUGALETE	3071	0	21
1406	RINCON DE SAN ANTONIO	3046	0	21
1407	RINCON DEL QUEBRACHO	3025	0	21
1408	SAN CRISTOBAL	3070	0	21
1409	SAN GUILLERMO	2347	0	21
1410	SANTURCE	3074	0	21
1411	SUARDI	2349	0	21
1412	VEINTICUATRO CASAS	2313	0	21
1413	VILLA SARALEGUI	3046	0	21
1414	VILLA TRINIDAD	2345	0	21
1415	WALVELBERG	2313	0	21
1416	ZADOCKHAN	2326	0	21
1417	CALCHINES	3001	0	21
1418	CAMPO DEL MEDIO	3001	0	21
1419	CAMPO ITURRASPE	3001	0	21
1420	CAYASTA	3001	0	21
1421	COLONIA CALIFORNIA	3005	0	21
1422	COLONIA NUEVA NARCISO	3001	0	21
1423	COLONIA SAN JOAQUIN	3001	0	21
1424	EL LAUREL	3001	0	21
1425	EL POZO	3001	0	21
1426	HELVECIA	3003	0	21
1427	JOSE MACIAS	3041	0	21
1428	LA NORIA	3001	0	21
1429	LAS CA	3046	0	21
1430	LAS TRES MARIAS	3046	0	21
1431	LOS CERRILLOS	3001	0	21
1432	RECREO SUR	3001	0	21
1433	RUINAS SANTA FE LA VIEJA	3001	0	21
1434	SALADERO M CABAL	3001	0	21
1435	SAN JOAQUIN	3001	0	21
1436	SANTA ROSA DE CALCHINES	3001	0	21
1437	VUELTA DEL PIRATA	3001	0	21
1438	ANDINO	2214	0	21
1439	BERRETTA	2501	0	21
1440	BUSTINZA	2501	0	21
1441	CAMPO HORQUESCO	2144	0	21
1442	CAMPO MEDINA	2142	0	21
1443	CAMPO PALETTA	2206	0	21
1444	CAMPO RAFFO	2216	0	21
1445	CA	2500	0	21
1446	CARRIZALES	2218	0	21
1447	CLARKE	2218	0	21
1448	CLASON	2146	0	21
1449	COLONIA MEDICI	2144	0	21
1450	COLONIA TRES MARIAS	2216	0	21
1451	CORREA	2506	0	21
1452	GRANJA SAN MANUEL	2501	0	21
1453	KILOMETRO 323	2142	0	21
1454	KILOMETRO 49	2506	0	21
1455	LARGUIA	2144	0	21
1456	LOS LEONES	2146	0	21
1457	LUCIO V LOPEZ	2142	0	21
1458	MARIA LUISA CORREA	2501	0	21
1459	OLIVEROS	2206	0	21
1460	RINCON DE GRONDONA	2206	0	21
1461	SALTO GRANDE	2142	0	21
1462	SAN ESTANISLAO	2501	0	21
1464	SAN RICARDO	2501	0	21
1465	SERODINO	2216	0	21
1466	TOTORAS	2144	0	21
1467	VILLA ELOISA	2503	0	21
1468	CAMPO HUBER	3555	0	21
1469	CAMPO ZAVALLA	3045	0	21
1470	ARIJON	2242	0	21
1471	AROCENA	2242	0	21
1472	BARRANCAS	2246	0	21
1473	BARRIO CAIMA	2242	0	21
1474	BERNARDO DE IRIGOYEN	2248	0	21
1475	CAMPO BRARDA	2248	0	21
1476	CAMPO CARIGNANO	2248	0	21
1477	CAMPO GALLOSO	2212	0	21
1478	CAMPO GARCIA	2240	0	21
1479	CAMPO GENERO	2248	0	21
1480	CAMPO GIMENEZ	2253	0	21
1481	CAMPO MOURE	2240	0	21
1482	CARCEL MODELO CORONDA	2240	0	21
1483	CENTENO	2148	0	21
1484	COLONIA CORONDINA	2240	0	21
1485	COLONIA CAMPO PIAGGIO	2252	0	21
1486	CORONDA	2240	0	21
1487	DESVIO ARIJON	2242	0	21
1488	DIAZ	2222	0	21
1489	GABOTO	2208	0	21
1490	GESSLER	2253	0	21
1491	IRIGOYEN	2248	0	21
1492	LARRECHEA	2241	0	21
1493	LOMA ALTA	2253	0	21
1494	LOPEZ	2255	0	21
1495	MACIEL	2208	0	21
1496	MONJE	2212	0	21
1497	ORO	2253	0	21
1498	PUENTE COLASTINE	2242	0	21
1499	PUERTO ARAGON	2246	0	21
1500	PUERTO GABOTO	2208	0	21
1501	RIGBY	2255	0	21
1502	SAN FABIAN	2242	0	21
1503	SAN GENARO	2146	0	21
1504	SAN GENARO NORTE	2147	0	21
1505	VILLA BIOTA	2147	0	21
1506	VILLA GUASTALLA	2148	0	21
1507	FORTIN ALMAGRO	3046	0	21
1508	ALTO VERDE	3001	0	21
1509	ANGEL GALLARDO	3014	0	21
1510	AROMOS	3036	0	21
1511	ARROYO AGUIAR	3014	0	21
1512	ARROYO LEYES	3001	0	21
1513	ASCOCHINGAS	3014	0	21
1514	BAJO LAS TUNAS	3017	0	21
1515	BARRANQUITAS	3000	0	21
1516	CABAL	3036	0	21
1517	CAMPO ANDINO	3021	0	21
1518	CAMPO CRESPO	3001	0	21
1519	CAMPO LEHMAN	3014	0	21
1520	CAMPO SANTO DOMINGO	3020	0	21
1521	CANDIOTI	3018	0	21
1522	COLASTINE	3001	0	21
1523	COLASTINE NORTE	3001	0	21
1524	COLONIA CAMPO BOTTO	3036	0	21
1525	CONSTITUYENTES	3014	0	21
1526	EL GALPON	3021	0	21
1527	EMILIA	3036	0	21
1528	IRIONDO	3018	0	21
1529	ISLA DEL PORTE	3001	0	21
1530	KILOMETRO 28	3014	0	21
1531	KILOMETRO 35	3014	0	21
1532	KILOMETRO 41	3020	0	21
1533	KILOMETRO 49	3023	0	21
1534	KILOMETRO 9	3000	0	21
1535	LA GUARDIA	3001	0	21
1536	LAGUNA PAIVA	3020	0	21
1537	LASSAGA	3036	0	21
1538	LLAMBI CAMPBELL	3036	0	21
1539	LOS HORNOS	3021	0	21
1540	MANUCHO	3023	0	21
1541	MONTE VERA	3014	0	21
1542	NELSON	3032	0	21
1543	NUEVA POMPEYA	3014	0	21
1544	PASO VINAL	3080	0	21
1545	PIQUETE	3000	0	21
1546	POMPEYA	3014	0	21
1547	PUEBLO CANDIOTI	3000	0	21
1548	RECREO	3018	0	21
1549	REYNALDO CULLEN	3020	0	21
1550	RINCON NORTE	3001	0	21
1551	RINCON POTREROS	3001	0	21
1552	RINLON DE AVILA	3023	0	21
1553	RIO SALADO	3036	0	21
1554	SAN GUILLERMO	3020	0	21
1556	SAN JOSE DEL RINCON	3001	0	21
1557	SAN PEDRO	3021	0	21
1558	SAN PEDRO NORTE	3021	0	21
1559	SAN PEDRO SUR	3014	0	21
1864	SANTO TOME	3016	0	21
1865	SAUCE VIEJO	3017	0	21
1866	SETUBAL	3014	0	21
1867	VILLA DON BOSCO	3000	0	21
1868	VILLA LUJAN	3016	0	21
1869	VILLA MARIA SELVA	3000	0	21
1870	VILLA VIVEROS	3001	0	21
1871	VILLA YAPEYU	3000	0	21
1872	YAMANDU	3014	0	21
1873	INGENIERO BOASI	3023	0	21
1874	SANTA CLARA	2258	0	21
1875	AARON CASTELLANOS	6106	0	21
1876	AMENABAR	6103	0	21
1877	CAFFERATA	2643	0	21
1878	CAMINERA GENERAL LOPEZ	2720	0	21
1879	CAMPO QUIRNO	2607	0	21
1880	CA	2635	0	21
1881	CARLOS DOSE	2635	0	21
1882	CARMEN	2618	0	21
1883	CARRERAS	2729	0	21
1884	CHAPUY	2603	0	21
1885	CHOVET	2633	0	21
1886	CORONEL ROSETI	6106	0	21
1887	COLONIA MORGAN	2609	0	21
1888	COLONIA SANTA LUCIA	2609	0	21
1889	CORA	2631	0	21
1890	4 DE FEBRERO	2732	0	21
1891	DIEGO DE ALVEAR	6036	0	21
1892	DURHAM	2631	0	21
1893	EL ALBERDON	6106	0	21
1894	EL CANTOR	2643	0	21
1895	EL JARDIN	2732	0	21
1896	EL REFUGIO	6103	0	21
1897	ELORTONDO	2732	0	21
1898	ENCADENADAS	2607	0	21
1899	ESTACION CHRISTOPHERSEN	2611	0	21
1900	FIRMAT	2630	0	21
1901	HUGHES	2725	0	21
1902	KILOMETRO 396	6106	0	21
1903	LA ADELAIDA	6103	0	21
1904	LA ASTURIANA	6106	0	21
1905	LA CALMA	6106	0	21
1906	LA CHISPA	2601	0	21
1907	LA CONSTANCIA	6103	0	21
1908	LA GAMA	2615	0	21
1909	LA INES	6100	0	21
1910	LA INGLESITA	2601	0	21
1911	LA MOROCHA	2613	0	21
1912	LA PICASA	6036	0	21
1913	LABORDEBOY	2726	0	21
1914	LAS DOS ANGELITAS	6106	0	21
1915	LAS ENCADENADAS	2607	0	21
1916	LAZZARINO	6103	0	21
1917	LOS ARCOS	2720	0	21
1918	MAGGIOLO	2622	0	21
1919	MARIA TERESA	2609	0	21
1920	MELINCUE	2728	0	21
1921	MERCEDITAS	2725	0	21
1922	MIRAMAR	6106	0	21
1923	MURPHY	2601	0	21
1924	OTTO BEMBERG	2605	0	21
1925	MIGUEL TORRES	2631	0	21
1926	RASTREADOR FOURNIER	2605	0	21
1927	RUFINO	6100	0	21
1928	RUNCIMAN	2611	0	21
1929	SAN CARLOS	6106	0	21
1930	SAN EDUARDO	2615	0	21
1931	SAN FRANCISCO DE SANTA FE	2601	0	21
1932	SAN GREGORIO	2613	0	21
1933	SAN MARCELO	6009	0	21
1934	SAN MARCOS DE VENADO TUERTO	2600	0	21
1935	SAN URBANO	2728	0	21
1936	SANCTI SPIRITU	2617	0	21
1937	SANTA EMILIA	2725	0	21
1938	SANTA ISABEL	2605	0	21
1939	SANTA PAULA	6106	0	21
1940	TARRAGONA	6103	0	21
1941	TEODELINA	6009	0	21
1942	VENADO TUERTO	2600	0	21
1943	VILLA CA	2607	0	21
1944	VILLA DIVISA DE MAYO	2631	0	21
1945	VILLA FREDICKSON	2630	0	21
1946	VILLA REGULES	2630	0	21
1947	VILLA ROSELLO	6100	0	21
1948	WHEELWRIGHT	2722	0	21
1949	ARROYO CEIBAL	3575	0	21
1950	ARROYO DEL REY	3565	0	21
1951	AVELLANEDA	3561	0	21
1952	BERNA	3569	0	21
1953	CAMPO EL ARAZA	3569	0	21
1954	CAMPO FURRER	3569	0	21
1955	CAMPO GARABATO	3572	0	21
1956	CAMPO GOLA	3516	0	21
1957	CAMPO GRANDE	3575	0	21
1958	COLONIA HARDY	3592	0	21
1959	CAMPO RAMSEYER	3572	0	21
1960	CAMPO REDONDO	3581	0	21
1961	CAMPO SIETE provincia	3575	0	21
1962	COLONIA URDANIZ	3516	0	21
1963	CAMPO VERGE	3516	0	21
1964	CAMPO YAGUARETE	3586	0	21
1965	CAPILLA GUADALUPE NORTE	3574	0	21
1966	COLONIA ALTHUAUS	3572	0	21
1967	COLONIA ELLA	3572	0	21
1968	COLONIA SAN MANUEL	3563	0	21
1969	COLONIA SANTA CATALINA	3572	0	21
1970	BARROS PAZOS	3569	0	21
1971	DESVIO KILOMETRO 392	3551	0	21
1972	DISTRITO 3 ISLETAS	3575	0	21
1973	EL ARAZA	3563	0	21
1974	EL CARMEN DE AVELLANEDA	3561	0	21
1975	EL CEIBALITO	3575	0	21
1976	EL RABON	3592	0	21
1977	EL RICARDITO	3572	0	21
1978	EL SOMBRERITO	3585	0	21
1979	EL TAPIALITO	3575	0	21
1980	EL TIMBO	3561	0	21
1981	EWALD	3561	0	21
1982	FLOR DE ORO	3575	0	21
1983	FLORENCIA	3516	0	21
1984	FLORIDA	3565	0	21
1985	FORTIN CHARRUA	3060	0	21
1986	GOLONDRINA	3551	0	21
1987	GUADALUPE NORTE	3574	0	21
1988	GUASUNCHO	3581	0	21
1989	INGENIERO CHANOURDIE	3575	0	21
1990	INGENIERO GARMENDIA	3586	0	21
1991	INGENIERO GERMANIA	3586	0	21
1992	ISLA TIGRE	3583	0	21
1993	ISLETA	3581	0	21
1994	KILOMETRO 17	3565	0	21
1995	KILOMETRO 23	3589	0	21
1996	KILOMETRO 30	3565	0	21
1997	KILOMETRO 320	3551	0	21
1998	KILOMETRO 392	3551	0	21
1999	KILOMETRO 403	3585	0	21
2000	KILOMETRO 408	3580	0	21
2001	KILOMETRO 41	3581	0	21
2002	KILOMETRO 421	3585	0	21
2003	KILOMETRO 67	3581	0	21
2004	LA BLANCA	3551	0	21
2005	LA CELIA	3569	0	21
2006	LA CLARITA	3585	0	21
2007	LA DIAMELA	3569	0	21
2008	LA ESMERALDA	3560	0	21
2009	LA JOSEFINA	3565	0	21
2010	LA LOLA	3567	0	21
2011	LA POTASA	3563	0	21
2012	LA RESERVA	3581	0	21
2013	LA SARITA	3563	0	21
2014	LA SELVA	3551	0	21
2015	LA VANGUARDIA	3561	0	21
2016	LA ZULEMA	3551	0	21
2017	LANTERI	3575	0	21
2018	LAS DELICIAS	3551	0	21
2019	LAS GARZAS	3574	0	21
2020	LAS MERCEDES	3516	0	21
2021	LAS PALMAS	3555	0	21
2022	LAS SIETE provincia	3575	0	21
2023	LAS TOSCAS	3586	0	21
2024	LOS CLAROS	3551	0	21
2025	LOS LAPACHOS	3575	0	21
2026	LOS LAURELES	3567	0	21
2027	LOS LEONES	3551	0	21
2028	MALABRIGO	3572	0	21
2029	MOCOVI	3581	0	21
2030	MOUSSY	3561	0	21
2031	NICANOR E MOLINAS	3563	0	21
2032	OBRAJE INDIO MUERTO	3589	0	21
2033	OBRAJE SAN JUAN	3589	0	21
2034	PAUL GROUSSAC	3585	0	21
2035	POTRERO GUASUNCHO	3589	0	21
2036	PUERTO OCAMPO	3580	0	21
2037	PUERTO PIRACUA	3516	0	21
2038	PUERTO PIRACUACITO	3592	0	21
2039	PUERTO RECONQUISTA	3567	0	21
2040	RECONQUISTA	3560	0	21
2041	DEST AERONAUTICO MILIT RECONQU	3567	0	21
2042	SAN ALBERTO	3565	0	21
2043	SAN ANTONIO DE OBLIGADO	3587	0	21
2044	SAN ROQUE	3553	0	21
2045	SAN VICENTE	3580	0	21
2046	SANTA ANA	3575	0	21
2047	TACUARENDI	3587	0	21
2048	VICTOR MANUEL SEGUNDO	3563	0	21
2049	VILLA ADELA	3581	0	21
2050	VILLA ANA	3583	0	21
2051	VILLA GUILLERMINA	3589	0	21
2052	VILLA OCAMPO	3580	0	21
2053	YAGUARETE	3586	0	21
2054	ACEBAL	2109	0	21
2055	AERO CLUB ROSARIO	2132	0	21
2056	ALBARELLOS	2101	0	21
2057	ALVAREZ	2107	0	21
2058	ALVEAR	2126	0	21
2059	ARMINDA	2119	0	21
2060	ARROYO SECO	2128	0	21
2061	BERNARD	2119	0	21
2062	CAMINO MONTE FLORES	2126	0	21
2063	CAMPO CALVO	2123	0	21
2064	CARMEN DEL SAUCE	2109	0	21
2065	COLONIA ESCRIBANO	2103	0	21
2066	CORONEL AGUIRRE	2124	0	21
2067	CORONEL BOGADO	2103	0	21
2068	CORONEL DOMINGUEZ	2105	0	21
2069	CRESTA	2126	0	21
2070	EL CARAMELO	2105	0	21
2071	ESTACION ERASTO	2119	0	21
2072	ESTANCIA LA MARIA	2105	0	21
2073	ESTANCIA SAN ANTONIO	2107	0	21
2074	FIGHIERA	2126	0	21
2075	FUNES	2132	0	21
2076	GENERAL LAGOS	2126	0	21
2077	GRANADERO B BARGAS	2132	0	21
2078	GRANADERO BAIGORRIA	2152	0	21
2079	IBARLUCEA	2142	0	21
2080	LA CAROLINA	2105	0	21
2081	LA CERAMICA Y CUYO	2000	0	21
2082	LA LATA	2126	0	21
2083	LICEO AERONAUTICO MILITAR	2132	0	21
2084	LINKS	2132	0	21
2085	LOS MUCHACHOS	2105	0	21
2086	MONTE FLORES	2101	0	21
2087	PAGANINI	2152	0	21
2088	PEREYRA LUCENA	2105	0	21
2089	PEREZ	2121	0	21
2090	PUEBLO ESTHER	2126	0	21
2091	PUEBLO MU	2119	0	21
2100	SAN SEBASTIAN	2121	0	21
2101	SOLDINI	2107	0	21
2102	TALLERES	2121	0	21
2103	URANGA	2105	0	21
2104	22 DE MAYO	2124	0	21
2105	VILLA AMELIA	2101	0	21
2106	VILLA AMERICA	2121	0	21
2107	VILLA GOBERNADOR GALVEZ	2124	0	21
2108	VILLA LYLY TALLERES	2121	0	21
2109	VILLA SAN DIEGO	2124	0	21
2110	ZAMPONI	2105	0	21
2111	ZAVALLA	2123	0	21
2112	ARRUFO	2344	0	21
2113	DHO	3070	0	21
2114		3072	0	21
2115	ALEJANDRA	3051	0	21
2116	CAMPO COUBERT	3056	0	21
2117	CA	3052	0	21
2118	COLONIA DURAN	3553	0	21
2119	COLONIA EL TOBA	3553	0	21
2120	COLONIA FRANCESA	3005	0	21
2121	COLONIA LA MORA	3045	0	21
2122	COLONIA LA NICOLASA	3056	0	21
2123	COLONIA MASCIAS	3001	0	21
2124	COLONIA SAGER	3553	0	21
2125	COLONIA TERESA	3005	0	21
2126	EL PAJARO BLANCO	3051	0	21
2127	LA BRAVA	3045	0	21
2128	LA CATALINA	3572	0	21
2129	LA LOMA	3555	0	21
2130	LOS CARDENALES	3005	0	21
2131	LOS CORRALITOS	3051	0	21
2132	LOS CUERVOS	3555	0	21
2133	LOS OSOS	3051	0	21
2134	ROMANG	3555	0	21
2135	SAN JAVIER	3005	0	21
2136	CASALEGNO	2248	0	21
2137	GALVEZ	2252	0	21
2138	LAS BANDURRIAS	2148	0	21
2139	SAN MARTIN DE TOURS	2255	0	21
2140	ABIPONES	3042	0	21
2141	ARRASCAETA	3046	0	21
2142	AVICHUNCHO	3040	0	21
2143	CACIQUE ARIACAIQUIN	3041	0	21
2144	CAMPO BERRAZ	3046	0	21
2145	CAYASTACITO	3038	0	21
2146	ANGELONI	3048	0	21
2147	COLONIA DOLORES	3045	0	21
2148	COLONIA EL OCHENTA	3042	0	21
2149	COLONIA LA BLANCA	3052	0	21
2150	COLONIA LA PENCA	3045	0	21
2151	COLONIA MANUEL MENCHACA	3046	0	21
2152	COLONIA SILVA	3042	0	21
2153	SOL DE MAYO	3048	0	21
2154	COLONIA TRES REYES	3048	0	21
2155	ESQUINA GRANDE	3040	0	21
2156	ESTHER	3036	0	21
2157	FIVES LILLE	3054	0	21
2158	GOBERNADOR CRESPO	3044	0	21
2159	GUARANIES	3054	0	21
2160	KILOMETRO 95	3046	0	21
2161	LA CAMILA	3054	0	21
2162	LA CLORINDA	3021	0	21
2163	LA CRIOLLA	3052	0	21
2164	LA JULIA	3046	0	21
2165	LA ROSA	3042	0	21
2166	LA SEMENTERA	3038	0	21
2167	LOS OLIVOS	3046	0	21
2168	LOS SALADILLOS	3041	0	21
2169	LUCIANO LEIVA	3048	0	21
2170	MARCELINO ESCALADA	3042	0	21
2171	MIGUEL ESCALADA	3046	0	21
2172		3041	0	21
2173	NARE	3046	0	21
2174	NUEVA UKRANIA	3046	0	21
2175	PAIKIN	3046	0	21
2176	PEDRO GOMEZ CELLO	3054	0	21
2177	SAN BERNARDO	3048	0	21
2178	RAMAYON	3042	0	21
2179	SAN JUSTO	3040	0	21
2180	SAN MARTIN NORTE	3045	0	21
2181	SOLEDAD	3025	0	21
2182	SOUTOMAYOR	3025	0	21
2183	VERA MUJICA	3040	0	21
2184	VERA Y PINTADO	3054	0	21
2185	VIDELA	3048	0	21
2186	VILLA LASTENIA	3042	0	21
2187	ALDAO	2214	0	21
2188	ARSENAL DE GUERRA SAN LORENZO	2156	0	21
2189	BARLETT	2175	0	21
2190	BORGHI	2156	0	21
2191	CAPITAN BERMUDEZ	2154	0	21
2192	CARCARA	2138	0	21
2193	CERANA	2202	0	21
2194	COLONIA CLODOMIRA	2123	0	21
2195	COLONIA EL CARMEN	2138	0	21
2196	CORONEL ARNOLD	2123	0	21
2197	CULLEN	2202	0	21
2198	EL TRANSITO	2202	0	21
2199	FABRICA MILITAR SAN LORENZO	2156	0	21
2200	FRAY LUIS BELTRAN	2156	0	21
2201	FUENTES	2123	0	21
2202	GRANADEROS	2156	0	21
2203	JESUS MARIA	2204	0	21
2204	JUAN ORTIZ	2154	0	21
2205	KILOMETRO 319	2154	0	21
2206	LA SALADA	2142	0	21
2207	LAS QUINTAS	2200	0	21
2208	LUIS PALACIOS	2142	0	21
2209	MAIZALES	2119	0	21
2210	PINO DE SAN LORENZO	2200	0	21
2211	PUEBLO KIRSTON	2202	0	21
2212	PUERTO DE SAN LORENZO	2200	0	21
2213	PUERTO GRAL SAN MARTIN	2202	0	21
2214	PUJATO	2123	0	21
2215	RICARDONE	2201	0	21
2216	ROLDAN	2134	0	21
2217	SAN GERONIMO	2136	0	21
2218	SAN JERONIMO SUR	2136	0	21
2219	SAN LORENZO	2200	0	21
2220	SEMINO	2138	0	21
2221	TIMBUES	2204	0	21
2222	TTE HIPOLITO BOUCHARD	2156	0	21
2223	VICENTE ECHEVARRIA	2142	0	21
2224	VILLA CASSINI	2154	0	21
2225	VILLA GARIBALDI	2156	0	21
2226	VILLA MARGARITA	2156	0	21
2227	VILLA MUGUETA	2175	0	21
2228	VILLA PORUCCI	2123	0	21
2229	AVENA	2449	0	21
2230	BARRIO BELGRANO ORTIZ	2440	0	21
2231	CAMPO CASTRO	2148	0	21
2232	CAMPO FAGGIANO	2440	0	21
2233	CA	2454	0	21
2234	CARLOS PELLEGRINI	2453	0	21
2235	CASAS	2148	0	21
2236	COLONIA BELGRANO	2257	0	21
2237	CASTELAR	2401	0	21
2238	COLONIA LA YERBA	2451	0	21
2239	COLONIA SAN FRANCISCO	2527	0	21
2240	COLONIA SANTA ANITA	2451	0	21
2241	CRISPI	2441	0	21
2242	EL TREBOL	2535	0	21
2243	ESMERALDITA	2401	0	21
2244	GRANADERO BRASILIO BUSTOS	2257	0	21
2245	KILOMETRO 443	2454	0	21
2246	KILOMETRO 465	2456	0	21
2247	LANDETA	2531	0	21
2248	LAS PETACAS	2451	0	21
2249	LOS CARDOS	2533	0	21
2250	MARIA SUSANA	2527	0	21
2251	PIAMONTE	2529	0	21
2252	SAN JORGE	2451	0	21
2253	SAN JOSE FRONTERA	2401	0	21
2254	SAN MARTIN DE LAS ESCOBAS	2449	0	21
2255	SASTRE	2440	0	21
2256	TAIS	2535	0	21
2257	TRAILL	2456	0	21
2258	WILDERMUTH	2257	0	21
2259	CALCHAQUI	3050	0	21
2260	CAMPO MONTE LA VIRUELA	3551	0	21
2261	CA	3551	0	21
2262	CARAGUATAY	3557	0	21
2263	COLMENA	3551	0	21
2264	COLONIA LA MARIA	3056	0	21
2265	COLONIA LA NEGRA	3054	0	21
2267	DESVIO KILOMETRO 282	3551	0	21
2268	EL DIECISIETE	3553	0	21
2269	EL TAJAMAR	3565	0	21
2270	ESPIN	3056	0	21
2271	ESTANCIA LAS GAMAS	3057	0	21
2272	ESTANCIA LOS PALMARES	3057	0	21
2273	ESTANCIA PAVENHAN	3057	0	21
2274	FORTIN CHILCAS	3553	0	21
2275	FORTIN OLMOS	3553	0	21
2276	GARABATO	3551	0	21
2277	GUAYCURU	3551	0	21
2278	INTIYACO	3551	0	21
2279	KILOMETRO 213	3050	0	21
2280	KILOMETRO 302	3551	0	21
2281	KILOMETRO 49	3589	0	21
2282	KILOMETRO 54	3589	0	21
2283	LA CIGUE	3057	0	21
2284	LA GALLARETA	3057	0	21
2285	LA GUAMPITA	3056	0	21
2286	LA HOSCA	3050	0	21
2287	LA ORIENTAL	3054	0	21
2288	LA SARNOSA	3057	0	21
2289	LOS AMORES	3551	0	21
2290	LOS GALPONES	3050	0	21
2291	LOS PALMARES	3057	0	21
2292	LOS TABANOS DESVIO KM 366	3551	0	21
2293	MARGARITA	3056	0	21
2294		3553	0	21
2295	OGILVIE	3551	0	21
2296	PARAJE 29	3553	0	21
2297	PARAJE TRAGNAGHI	3551	0	21
2298	PAVENHAN	3057	0	21
2299	POZO DE LOS INDIOS	3551	0	21
2300	SANTA FELICIA	3551	0	21
2301	SANTA LUCIA	3553	0	21
2302	TARTAGAL	3565	0	21
2303	TOBA	3551	0	21
2304	VELAZQUEZ	3550	0	21
2305	VERA	3550	0	21
2458	AVELLANEDA	1870	0	1
2459	CRUCESITA	1870	0	1
2460	DOCK SUD	1871	0	1
2461	SARANDI	1872	0	1
2462	VILLA DOMINICO	1874	0	1
2463	WILDE	1875	0	1
2464	25 DE MAYO	6660	0	1
2465	AGUSTIN MOSCONI	6667	0	1
2466	ARAUJO	6643	0	1
2467	BLAS DURA	6661	0	1
2468	COLONIA INCHAUSTI	6667	0	1
2469	DEL VALLE	6509	0	1
2470	DESVIO GARBARINI	6509	0	1
2471	ERNESTINA	6665	0	1
2472	ESCUELA AGRICOLA SALESIANA	6509	0	1
2473	GOBERNADOR UGARTE	6621	0	1
2474	HUETEL	6511	0	1
2475	ISLAS	6667	0	1
2476	JUAN VELA	6663	0	1
2477	LA GLORIA	6665	0	1
2478	LA RABIA	6667	0	1
2479	LA RUBIA	6667	0	1
2480	LA TRIBU	6660	0	1
2481	LAGUNA LAS MULITAS	6660	0	1
2482	LUCAS MONTEVERDE	6661	0	1
2483	MAMAGUITA	6661	0	1
2484	MARTIN BERRAONDO	6667	0	1
2485	NORBERTO DE LA RIESTRA	6663	0	1
2486	ORTIZ DE ROSAS	6660	0	1
2487	PEDERNALES	6665	0	1
2488	PUEBLITOS	6661	0	1
2489	SAN ENRIQUE	6661	0	1
2490	SAN JOSE	6665	0	1
2491	SANTIAGO GARBARINI	6660	0	1
2492	VALDEZ	6667	0	1
2493	12 DE OCTUBRE	6501	0	1
2494	9 DE JULIO	6500	0	1
2495	ALFREDO DEMARCHI	6533	0	1
2497	AMALIA	6516	0	1
2498	BACACAY	6516	0	1
2499	BARRIO JULIO DE VEDIA	6500	0	1
2500	CAMBACERES	6516	0	1
2501	CARLOS MARIA NAON	6515	0	1
2502	COLONIA LAS YESCAS	6513	0	1
2503	CORBETT	6507	0	1
2504	DENNEHY	6516	0	1
2505	DESVIO KILOMETRO 234	6503	0	1
2506	DUDIGNAC	6505	0	1
2507	EL JABALI	6531	0	1
2508	EL TEJAR	6515	0	1
2509	ESTACION PROVINCIAL	6501	0	1
2510	FAUZON	6500	0	1
2511	FRENCH	6516	0	1
2512	GALO LLORENTE	6513	0	1
2513	GERENTE CILLEY	6507	0	1
2514	INGENIERO DE MADRID	6651	0	1
2515	LA ADELA	6533	0	1
2516	LA AURORA	6513	0	1
2517	LA NI	6513	0	1
2518	LA YESCA	6513	0	1
2519	LAGUNA DEL CURA	6501	0	1
2520	LAS NEGRAS	6507	0	1
2521	LAS ROSAS	6533	0	1
2522	MOREA	6507	0	1
2523	MULCAHY	6501	0	1
2524	NORUMBEGA	6501	0	1
2525	PATRICIOS	6503	0	1
2526	QUIROGA	6533	0	1
2527	RAMON J NEILD	6533	0	1
2528	REGINALDO J NEILD	6533	0	1
2529	SAN JUAN	6500	0	1
2530	SANTOS UNZUE	6507	0	1
2531	TROPEZON	6501	0	1
2532	VILLA DIAMANTINA	6500	0	1
2533	ADOLFO ALSINA	6430	0	1
2534	ARANO	6443	0	1
2535	ARTURO VATTEONE	6433	0	1
2536	AVESTRUZ	8183	0	1
2537	CAMPO DEL NORTE AMERICANO	8185	0	1
2538	CAMPO LA ZULEMA	8185	0	1
2539	CAMPO LOS AROMOS	8185	0	1
2540	CAMPO SAN JUAN	8185	0	1
2541	CA	8183	0	1
2542	CANONIGO GORRITI	8185	0	1
2543	CARHUE	6430	0	1
2544	CHAPI TALO	6341	0	1
2545	COLONIA BARON HIRSCH	6441	0	1
2546	COLONIA LA ESTRELLA	8185	0	1
2547	COLONIA LAPIN	8185	0	1
2548	COLONIA LEVEN	8185	0	1
2549	COLONIA MURATURE	6341	0	1
2550	COLONIA NAVIERA	6341	0	1
2551	COLONIA PHILLIPSON N 1	8185	0	1
2552	COLONIA SANTA MARIANA	8185	0	1
2553	DELFIN HUERGO	8185	0	1
2554	EL PARQUE	6341	0	1
2555	EPUMER	6443	0	1
2556	ESTACION LAGO EPECUEN	6431	0	1
2557	ESTEBAN A GASCON	8185	0	1
2558	FATRALO	6430	0	1
2559	FRANCISCO MURATURE	6341	0	1
2560	JUAN V CILLEY	6430	0	1
2561	LA FLORIDA	8185	0	1
2562	LA PALA	6341	0	1
2563	LAGO EPECUEN	6431	0	1
2564	LEUBUCO	6338	0	1
2565	LOS GAUCHOS	6343	0	1
2566	MALABIA	6443	0	1
2567	MAZA	6343	0	1
2568	MONTE FIORE	8185	0	1
2569	POCITO	6430	0	1
2570	RIVERA	6441	0	1
2571	SAN ANTONIO	8185	0	1
2572	SAN MIGUEL ARCANGEL	8185	0	1
2573	THAMES	6343	0	1
2574	TRES LAGUNAS	6443	0	1
2575	VILLA CASTELAR EST ERIZE	6430	0	1
2576	VILLA MARGARITA	8185	0	1
2577	VILLA MAZA	6343	0	1
2578	VILLA SAURI	6430	0	1
2579	YUTUYACO	6443	0	1
2580	ADOLFO GONZALES CHAVES	7513	0	1
2581	ALZAGA	7021	0	1
2582	DE LA GARMA	7515	0	1
2583	JUAN E BARRA	7517	0	1
2584	PEDRO LASALLE	7515	0	1
2585	VASQUEZ	7519	0	1
2586	ALBERTI	6634	0	1
2588	ANDRES VACCAREZZA	6634	0	1
2589	BAUDRIX	6643	0	1
2590	COLONIA PALANTELEN	6643	0	1
2591	COLONIA ZAMBUNGO	6628	0	1
2592	CORONEL MON	6628	0	1
2593	CORONEL SEGUI	6628	0	1
2594	EMITA	6634	0	1
2595	GRISOLIA	6627	0	1
2596	LARREA	6634	0	1
2597	PALANTELEN	6434	0	1
2598	PLA	6634	0	1
2599	PRESIDENTE QUINTANA	6621	0	1
2600	SAN JOSE	6643	0	1
2601	VILLA MARIA	6628	0	1
2602	VILLA ORTIZ	6628	0	1
2615	BALNEARIO ATLANTIDA	7607	0	1
2616	BALNEARIO CAMET NORTE	7607	0	1
2617	BALNEARIO FRENTE MAR	7607	0	1
2618	BALNEARIO LA BALIZA	7607	0	1
2619	BALNEARIO LA CALETA	7609	0	1
2620	BALNEARIO MAR DE COBO	7609	0	1
2621	BALNEARIO PLAYA DORADA	7607	0	1
2622	BARRIO OESTE	7607	0	1
2623	BARRIO PARQUE BRISTOL	7607	0	1
2624	COMANDANTE NICANOR OTAMENDI	7603	0	1
2625	DIONISIA	7603	0	1
2626	EL CENTINELA	7607	0	1
2627	EL MARQUESADO	7607	0	1
2628	EL PITO	7607	0	1
2629	GENERAL ALVARADO	7607	0	1
2630	LA BALLENERA	7605	0	1
2631	LA COLMENA	7603	0	1
2632	LA ELMA	7603	0	1
2633	LA LUCIA	7603	0	1
2634	LA MADRECITA	7603	0	1
2635	LA REFORMA	7603	0	1
2636	LAS LOMAS	7603	0	1
2637	LAS PIEDRITAS	7605	0	1
2638	LOS PATOS	7603	0	1
2639	MAR DEL SUD	7607	0	1
2640	MECHONGUE	7605	0	1
2641	MIRAMAR	7607	0	1
2642	PLA Y RAGNONI	7607	0	1
2643	SAN CORNELIO	7603	0	1
2644	SAN EDUARDO DEL MAR	7607	0	1
2645	SAN FELIPE	7603	0	1
2646	SAN JOSE DE OTAMENDI	7601	0	1
2647	SANTA IRENE	7607	0	1
2648	VILLA COPACABANA	7607	0	1
2649	YRAIZOS	7605	0	1
2650	EL CHUMBIAO	7263	0	1
2651	EL PARCHE	7263	0	1
2652	EMMA	7263	0	1
2653	GENERAL ALVEAR	7263	0	1
2654	HARAS R DE LA PARVA	7263	0	1
2655	JOSE M MICHEO	7263	0	1
2656	LA PAMPA	7263	0	1
2657	LOS CUATRO CAMINOS	7263	0	1
2658	SANTA ISABEL	6550	0	1
2659	FLORENTINO AMEGHINO	6064	0	1
2660	BLAQUIER	6065	0	1
2661	EDUARDO COSTA	6064	0	1
2662	NUEVA SUIZA	6077	0	1
2663	PORVENIR	6063	0	1
2665	PI	1870	0	1
2666	AYACUCHO	7150	0	1
2667	CANGALLO	7153	0	1
2668	FAIR	7153	0	1
2669	LA CONSTANCIA	7153	0	1
2670	LANGUEYU	7151	0	1
2671	LAS SULTANAS	7151	0	1
2672	SAN IGNACIO	7151	0	1
2673	SAN LAUREANO	7150	0	1
2674	SOLANET	7151	0	1
2675	UDAQUIOLA	7151	0	1
2676	16 DE JULIO	7313	0	1
2677	ARROYO LOS HUESOS	7301	0	1
2678	ANTONIO DE LOS HEROS	7305	0	1
2679	ARIEL	7301	0	1
2680	AZUL	7300	0	1
2681	BASE NAVAL AZOPARDO	7301	0	1
2682	BERNARDO VERA Y PINTADO	7313	0	1
2683	CACHARI	7214	0	1
2684	CAMINERA AZUL	7300	0	1
2685	CAMPODONICO	7305	0	1
2686	CERRO AGUILA	7403	0	1
2687	CHILLAR	7311	0	1
2688	COVELLO	7305	0	1
2689	ESTACION LAZZARINO	7300	0	1
2690	FORTIN IRENE	7316	0	1
2691	FRANCISCO J MEEKS	7301	0	1
2692	KILOMETRO 433	7313	0	1
2693	LA CHUMBEADA	7316	0	1
2694	LA COLORADA	7300	0	1
2695	LA MANTEQUERIA	7300	0	1
2696	LA PROTEGIDA	7311	0	1
2697	LAGUNA MEDINA	7214	0	1
2698	LAS CORTADERAS	7300	0	1
2699	LAS NIEVES	7316	0	1
2700	LAZZARINO	7300	0	1
2701	MARTIN FIERRO	7311	0	1
2702	MIRAMONTE	7214	0	1
2703	NIEVES	7316	0	1
2704	PABLO ACOSTA	7301	0	1
2705	PARISH	7316	0	1
2706	SAN GERVACIO	7305	0	1
2707	SAN RAMON DE ANCHORENA	7311	0	1
2708	SHAW	7316	0	1
2709	VA	7301	0	1
2710	VICENTE PEREDA	7300	0	1
2711	ADELA CORTI	8000	0	1
2712	AGUARA	8105	0	1
2714	ALFEREZ SAN MARTIN	8117	0	1
2737	CABILDO	8118	1	1
2738	GRAL DANIEL CERRI	8105	1	1
2739	CHOIQUE	8000	0	1
2740	COCHRANE	8118	0	1
2742	CORTI	8118	0	1
2744	ESPORA	8107	0	1
2746	GARRO	8103	0	1
2747	GRUMBEIN	8101	1	1
2749	KILOMETRO 11	8101	0	1
2750	KILOMETRO 652	8109	0	1
2751	KILOMETRO 666	8105	0	1
2752	KILOMETRO 9 SUD	8101	0	1
2753	LA VITICOLA	8122	0	1
2757	PUERTO GALVAN	8000	0	1
2758	SAUCE CHICO	8105	0	1
2759	SPURR	8103	1	1
2760	VENANCIO	8117	0	1
2761	VILLA BUENOS AIRES	8000	0	1
2762	VILLA CERRITO	8000	0	1
2763	VILLA DOMINGO PRONSATO	8000	0	1
2764	VILLA FLORESTA	8000	0	1
2765	VILLA HARDING GREEN	8101	0	1
2766	VILLA HERMINIA	8101	0	1
2767	VILLA ITALIA	8000	0	1
2768	VILLA LIBRE	8000	0	1
2769	VILLA LORETO	8000	0	1
2770	VILLA MITRE	8000	0	1
2771	VILLA NOCITO	8000	0	1
2772	VILLA OBRERA	8000	0	1
2773	VILLA OLGA GRUMBEIN	8000	0	1
2774	VILLA ROSAS	8103	1	1
2775	VILLA SANCHEZ ELIA	8000	0	1
2776	VILLA SERRA	8103	0	1
2778	BALCARCE	7620	0	1
2779	BOSCH	7620	0	1
2780	CAMINERA NAPALEOFU	7007	0	1
2781	CAMPO LA PLATA	7623	0	1
2782	CAMPO LEITE	7623	0	1
2783	EL HERVIDERO	7007	0	1
2784	EL JUNCO	7620	0	1
2785	EL VERANO	7620	0	1
2786	EL VOLANTE	7620	0	1
2787	HARAS OJO DEL AGUA	7620	0	1
2788	LA BRAVA	7620	0	1
2789	LA ESPERANZA	7007	0	1
2790	LA PARA	7620	0	1
2791	LA SARA	7621	0	1
2792	LAGUNA BRAVA	7620	0	1
2793	LAS SUIZAS	7007	0	1
2794	LOS CARDOS	7620	0	1
2795	LOS PINOS	7623	0	1
2796	NAPALEOFU	7007	0	1
2797	RAMOS OTERO	7621	0	1
2798	RINCON DE BAUDRIX	7621	0	1
2799	SAN AGUSTIN	7623	0	1
2800	SAN SIMON	7621	0	1
2801	ALSINA	2938	0	1
2802	BARADERO	2942	0	1
2803	EL SILENCIO	2752	0	1
2804	ESTACION BARADERO	2942	0	1
2805	ESTANCIA SANTA CATALINA	2761	0	1
2806	IRENEO PORTELA	2943	0	1
2807	ISLA LOS LAURELES	2931	0	1
2808	PANAME	2931	0	1
2809	SANTA COLOMA	2761	0	1
2810	ALMACEN LA COLINA	2740	0	1
2811	ARRECIFES	2740	0	1
2812	CAMPO CRISOL	2754	0	1
2813	CA	2740	0	1
2814	EL NACIONAL	2740	0	1
2815	LA DELIA	2740	0	1
2816	LA NELIDA	2740	0	1
2817	PUENTE CA	2740	0	1
2818	TODD	2754	0	1
2819	VILLA SANGUINETTI	2740	0	1
2820	VI	2754	0	1
2822	BARKER	7005	0	1
2823	VILLA JUAREZ	7020	0	1
2824	BENITO JUAREZ	7020	0	1
2825	CAMINERA JUAREZ	7020	0	1
2826	CHAPAR	7020	0	1
2828	CORONEL RODOLFO BUNGE	7313	0	1
2829	EL LUCHADOR	7313	0	1
2830	ESTANCIA CHAPAR	7020	0	1
2831	HARAS EL CISNE	7020	0	1
2832	KILOMETRO 404	7005	0	1
2833	LA CALERA	7020	0	1
2834	LA NUTRIA	7313	0	1
2835	LOPEZ	7021	0	1
2836	MARIANO ROLDAN	7517	0	1
2837	MOLINO GALILEO	7020	0	1
2838	MONTE CRESPO	7020	0	1
2839	PACHAN	7020	0	1
2840	PARQUE MU	7020	0	1
2841	RICARDO GAVI	7313	0	1
2842	TEDIN URIBURU	7021	0	1
2843	VILLA CACIQUE	7005	0	1
2853	ARROYO DEL PESCADO	1923	0	1
2854	ARROYO LA MAZA	1923	0	1
2855	BERISSO	1923	0	1
2856	FRIGORIFICO ARMOUR	1923	0	1
2857	ISLA PAULINO	1929	0	1
2858	LA BALANDRA	1923	0	1
2859	LOS TALAS	1923	0	1
2860	PALO BLANCO	1923	0	1
2861	BOLIVAR	6550	0	1
2862	EL PORVENIR	6550	0	1
2863	HALE	6511	0	1
2864	JUAN F IBARRA	6551	0	1
2865	LA PERLA	6550	0	1
2866	LA TORRECITA	6553	0	1
2867	PARAJE MIRAMAR	6550	0	1
2868	NUEVA ESPA	6553	0	1
2869	PAULA	6557	0	1
2870	PIROVANO	6551	0	1
2871	MARIANO UNZUE	6551	0	1
2872	URDAMPILLETA	6553	0	1
2873	VALLIMANCA	6557	0	1
2874	VILLA LYNCH PUEYRREDON	6553	0	1
2875	VILLA SANZ	6511	0	1
2876	ASAMBLEA	6640	0	1
2877	BRAGADO	6640	0	1
2878	COLONIA SAN EDUARDO	6646	0	1
2879	COMODORO PY	6641	0	1
2880	GENERAL O BRIEN	6646	0	1
2881	IRALA	6013	0	1
2882	LA LIMPIA	6645	0	1
2883	LA MARIA	6640	0	1
2884	MAXIMO FERNANDEZ	6645	0	1
2885	MECHA	6648	0	1
2886	MECHITA	6648	0	1
2887	OLASCOAGA	6652	0	1
2888	WARNES	6646	0	1
2889	ALTAMIRANO	1986	0	1
2890	BARRIO LA DOLLY	1980	0	1
2891	BARRIO LAS MANDARINAS	1980	0	1
2892	CAMINERA SAMBOROMBON	7130	0	1
2893	CAMPO LOPE SECO	1980	0	1
2894	CORONEL BRANDSEN	1980	0	1
2895	DESVIO KILOMETRO 55	1981	0	1
2896	DOYHENARD	1980	0	1
2897	GOBERNADOR OBLIGADO	1981	0	1
2898	GOMEZ	1983	0	1
2899	GOMEZ  DE LA VEGA	1983	0	1
2900	JEPPENER	1986	0	1
2901	KILOMETRO 44	1980	0	1
2902	KILOMETRO 58	1981	0	1
2903	KILOMETRO 82	1980	0	1
2904	LA POSADA	1980	0	1
2905	OLIDEN	1981	0	1
2906	SAMBOROMBON	1980	0	1
2907	ARROYO ALELI	2805	0	1
2908	ARROYO CARABELITAS	2805	0	1
2909	ARROYO EL AHOGADO	2805	0	1
2910	ARROYO LAS CRUCES	2805	0	1
2911	ARROYO LAS ROSAS	2805	0	1
2912	ARROYO LOS TIGRES	2805	0	1
2913	ARROYO 	2805	0	1
2914	ARROYO PESQUERIA	2805	0	1
2915	ARROYO TAJIBER	2805	0	1
2916	ARROYO ZANJON	2805	0	1
2917	BLONDEAU	2805	0	1
2918	CAMPANA	2804	0	1
2919	CANAL N ALEM 1A SEC	2805	0	1
2920	CANAL N ALEM 2A SEC	2805	0	1
2921	EL FENIX	2804	0	1
2922	KILOMETRO 88	2804	0	1
2923	LA HORQUETA	2805	0	1
2924	OTAMENDI	2802	0	1
2925	LOMAS DEL RIO LUJAN	2802	0	1
2926	ALEJANDRO PETION	1808	0	1
2927	BARRIO 1 DE MAYO	1814	0	1
2928	CA	1814	0	1
2929	COLONIA SANTA ROSA	1816	0	1
2930	ESCUELA AGRICOLA DON BOSCO	1815	0	1
2931	FRANCISCO CASAL	1808	0	1
2932	GOBERNADOR UDAONDO	7221	0	1
2933	INDIA MUERTA	7114	0	1
2934	KILOMETRO 59	1814	0	1
2935	KILOMETRO 88	7221	0	1
2936	LA COSTA	1814	0	1
2937	LA GARITA	1814	0	1
2938	LA NORIA	1814	0	1
2939	LOS AROMOS	1816	0	1
2940	MAXIMO PAZ	1812	0	1
2941	PALMITAS	7221	0	1
2942	RUTA 205 KILOMETRO 57	1816	0	1
2943	RUTA 3 KILOMETRO 75 700	1816	0	1
2944	SANTA ROSA	1739	0	1
2945	URIBELARREA	1815	0	1
2946	VICENTE CASARES	1808	0	1
2947	VILLA ADRIANA	1816	0	1
2948	ALMACEN EL DESCANSO	2752	0	1
2949	ARROYO DE LUNA	2752	0	1
2950	CAMPO LA ELISA	2752	0	1
2951	CAPITAN SARMIENTO	2752	0	1
2952	COLEGIO SAN PABLO	2752	0	1
2953	LA LUISA	2752	0	1
2954	ALGARROBO	6531	0	1
2955	BELLOCQ	6535	0	1
2956	CADRET	6535	0	1
2957	EL CAMOATI	6537	0	1
2958	CARLOS CASARES	6530	0	1
2959	CENTENARIO	6535	0	1
2960	COLONIA LA ESPERANZA	6531	0	1
2961	COLONIA MAURICIO	6531	0	1
2962	COLONIA SANTA MARIA	6535	0	1
2963	EL CARPINCHO	6537	0	1
2964	ESTANCIA SAN CLAUDIO	6537	0	1
2965	GOBERNADOR ARIAS	6531	0	1
2966	HORTENSIA	6537	0	1
2967	LA DORITA	6538	0	1
2968	LA SOFIA	6535	0	1
2969	MAURICIO HIRSCH	6531	0	1
2970	MOCTEZUMA	6531	0	1
2971	ODORQUI	6537	0	1
2972	SAN JUAN DE NELSON	6530	0	1
2973	SANTA MARIA BELLOQ	6535	0	1
2974	SANTO TOMAS	6530	0	1
2975	SANTO TOMAS CHICO	6538	0	1
2976	SMITH	6531	0	1
2977	CARLOS TEJEDOR	6455	0	1
2978	COLONIA SERE	6459	0	1
2979	CUENCA	6231	0	1
2980	CURARU	6451	0	1
2981	DRYSDALE	6455	0	1
2982	ENCINA	6077	0	1
2983	ESTEBAN DE LUCA	6475	0	1
2984	HEREFORD	6233	0	1
2985	HUSARES	6455	0	1
2986	INGENIERO BEAUGEY	6457	0	1
2987	KILOMETRO 386	6457	0	1
2988	KILOMETRO 393	6467	0	1
2989	LA HIGUERA	6475	0	1
2990	LOS CHA	6475	0	1
2991	LOS INDIOS	6451	0	1
2992	MARUCHA	6451	0	1
2993	NECOL ESTACION FCGM	6077	0	1
2994	SAN CARLOS	6451	0	1
2995	SANTA INES	6459	0	1
2996	TIMOTE	6457	0	1
2997	TRES ALGARROBOS	6231	0	1
2998	CARMEN DE ARECO	6725	0	1
2999	ESTRELLA NACIENTE	6725	0	1
3000	GOUIN	6727	0	1
3001	HARAS LOS CARDALES	2752	0	1
3002	KENNY	2745	0	1
3003	LA CENTRAL	6725	0	1
3004	PARADA TATAY	6725	0	1
3005	RETIRO SAN PABLO	2752	0	1
3006	SAN ERNESTO	6725	0	1
3007	TATAY	6721	0	1
3008	TRES SARGENTOS	6727	0	1
3009	AMBROSIO P LEZICA	8508	0	1
3010	BAHIA SAN BLAS	8506	0	1
3011	CANTERA VILLALONGA	8504	0	1
3012	CARDENAL CAGLIERO	8506	0	1
3013	CARMEN DE PATAGONES	8504	0	1
3014	COLONIA MIGUEL ESTEVERENA	8508	0	1
3015	COLONIA EL GUANACO	8142	0	1
3016	COLONIA BARGA	8142	0	1
3017	COLONIA LA CELINA	8508	0	1
3018	COLONIA LA GRACIELA	8142	0	1
3019	COLONIA LOS ALAMOS	8142	0	1
3020	COLONIA SAN FRANCISCO	8142	0	1
3021	COLONIA TAPATTA	8142	0	1
3022	EL BAGUAL	8504	0	1
3023	EMILIO LAMARCA	8505	0	1
3024	FARO SEGUNDA BARRANCOSA	8504	0	1
3025	FORTIN VIEJO	8148	0	1
3026	IGARZABAL	8512	0	1
3027	JARRILLA	8508	0	1
3028	JOSE B CASAS	8506	0	1
3030	LAS CORTADERAS	8504	0	1
3031	LOS POZOS	8512	0	1
3032	PASO ALSINA	8142	0	1
3033	PUERTO TRES BONETES	8508	0	1
3034	PUERTO WASSERMANN	8506	0	1
3035	SALINA DE PIEDRA	8506	0	1
3036	STROEDER	8508	0	1
3037	TERMAS LOS GAUCHOS	8504	0	1
3038	VILLA ELENA	8512	0	1
3039	VILLALONGA	8512	0	1
3041	CANAL 15 CERRO DE LA GLORIA	7114	0	1
3042	CASTELLI	7114	0	1
3043	CENTRO GUERRERO	7114	0	1
3044	GUERRERO	7116	0	1
3045	LA CORINCO	7114	0	1
3046	LA COSTA	7114	0	1
3047	PARQUE TAILLADE	7114	0	1
3048	SAN JOSE DE GALI	7114	0	1
3049	CASTILLA	6616	0	1
3050	CHACABUCO	6740	0	1
3051	COLIQUEO	6743	0	1
3052	CUCHA CUCHA	6746	0	1
3053	GREGORIO VILLAFA	6740	0	1
3054	INGENIERO SILVEYRA	6743	0	1
3055	LA CALIFORNIA ARGENTINA	6616	0	1
3056	LOS ANGELES	2743	0	1
3057	MEMBRILLAR	6748	0	1
3058	O HIGGINS	6748	0	1
3059	PALEMON HUERGO	6628	0	1
3060	RAWSON	6734	0	1
3061	SAN PATRICIO	6734	0	1
3062	VILLAFA	6740	0	1
3063	ADELA	7136	0	1
3065	CHASCOMUS	7130	0	1
3066	COLONIA ESCUELA ARGENTINA	7136	0	1
3067	COMANDANTE GIRIBONE	7135	0	1
3068	CUARTEL 6	7136	0	1
3069	CUARTEL 8	7135	0	1
3070	DON CIPRIANO	7135	0	1
3071	EL CARBON	7135	0	1
3072	EL DESTINO	7116	0	1
3073	EL EUCALIPTUS	7130	0	1
3074	EL RINCON	7130	0	1
3075	ESTANCIA SAN RAFAEL	7130	0	1
3076	GANDARA	7136	0	1
3077	HARAS SAN IGNACIO	7136	0	1
3078	LA ALAMEDA	7130	0	1
3079	LA AMALIA	7130	0	1
3080	LA AMISTAD	7130	0	1
3081	LA AZOTEA GRANDE	7130	0	1
3082	LA HORQUETA	7130	0	1
3084	LA REFORMA	7130	0	1
3085	LAS BRUSCAS	7130	0	1
3086	LAS MULAS	7130	0	1
3087	LEGARISTI	7130	0	1
3088	LEZAMA	7116	0	1
3089	LIBRES DEL SUD	7135	0	1
3090	MONASTERIO	7136	0	1
3091	PEDRO NICOLAS ESCRIBANO	7135	0	1
3092	PESSAGNO	7135	0	1
3093	VISTA ALEGRE	7130	0	1
3094	VITEL	7130	0	1
3095	BENITEZ	6632	0	1
3096	CA	6625	0	1
3098	GOROSTIAGA	6632	0	1
3099	HARAS EL CARMEN	6627	0	1
3100	HENRY BELL	6621	0	1
3101	INDACOCHEA	6623	0	1
3102	LA CARLOTA	6628	0	1
3103	LA DORMILONA	6628	0	1
3104	LA RICA	6623	0	1
3105	PUENTE BATALLA	6620	0	1
3106	RAMON BIAUS	6627	0	1
3107	SAN SEBASTIAN	6623	0	1
3108	VILLA MOQUEHUA	6625	0	1
3109	COLON	2720	0	1
3110	EL ARBOLITO	2721	0	1
3111	EL PELADO	2720	0	1
3112	ESTANCIA LAS GAMAS	2723	0	1
3114	PEARSON	2711	0	1
3115	SARASA	2721	0	1
3116	ALMIRANTE SOLIER	8109	0	1
3117	ARROYO PAREJA	8111	0	1
3118	BAJO HONDO	8115	1	1
3119	BALNEARIO PARADA	8109	0	1
3120	BATERIAS	8113	0	1
3121	CALDERON	8101	0	1
3122	DESVIO SANDRINI	8109	0	1
3123	ISLA CATARELLI	8111	0	1
3124	LA MARTINA	8109	0	1
3125	LA VIRGINIA	8115	0	1
3126	PASO MAYOR	8115	0	1
3127	PEHUEN CO	8109	1	1
3128	PUERTO BELGRANO	8111	0	1
3129	PUERTO ROSALES	8111	0	1
3130	PUNTA ALTA	8109	1	1
3131	VILLA DEL MAR	8109	0	1
3132	VILLA GENERAL ARIAS	8101	0	1
3133	VILLA LAURA	8109	0	1
3134	VILLA MAIO	8109	0	1
3135	FARO	8150	0	1
3136	APARICIO	8158	0	1
3137	CALVO	8154	0	1
3138	CAMPO LA LIMA	8150	0	1
3139	CORONEL DORREGO	8150	1	1
3140	EL ZORRO	8151	0	1
3141	GIL	8151	0	1
3142	IRENE	7507	0	1
3143	JOSE A GUISASOLA	8156	0	1
3144	KILOMETRO 563	8151	0	1
3145	LA AURORA	8151	0	1
3146	LA LUNA	8150	0	1
3147	LA SIRENA	8150	0	1
3148	LA SOBERANA	8154	0	1
3149	LAS OSCURAS	8115	0	1
3150	NICOLAS DESCALZI	8151	0	1
3151	ORIENTE	7509	0	1
3152	PARAJE LA AURORA	8158	0	1
3153	SAN RAMON	8150	0	1
3154	SAN ROMAN	8154	0	1
3155	SAUCE GRANDE	8150	0	1
3156	CORONEL FALCON	8118	0	1
3157	CORONEL PRINGLES	7530	1	1
3158	DESPE	7531	0	1
3159	EL DIVISORIO	7531	0	1
3160	EL PENSAMIENTO	7531	0	1
3161	ESTACION CORONEL PRINGLES	7536	0	1
3162	INDIO RICO	7501	0	1
3163	KRABBE	7530	0	1
3164	LA RESERVA	7536	0	1
3165	LARTIGAU	7531	0	1
3166	LAS MOSTAZAS	7530	0	1
3167	PILLAHUINCO	7530	0	1
3168	STEGMANN	7536	0	1
3169	TEJO GALETA	7530	0	1
3170	BATHURST ESTACION	7540	0	1
3171	CASCADA	7547	0	1
3172	CORONEL SUAREZ	7540	1	1
3173	CURA MALAL	7548	0	1
3174	D ORBIGNY	7541	0	1
3176	LA PRIMAVERA	7543	0	1
3177	OMBU	7545	0	1
3178	OTO	7545	0	1
3179	PASMAN	7547	0	1
3180	PI	7540	0	1
3181	PUEBLO SAN JOSE	7541	0	1
3182	PUEBLO SANTA MARIA	7541	0	1
3183	QUI	7533	0	1
3184	SANTA TRINIDAD	7541	0	1
3185	VILLA ARCADIA	7540	0	1
3186	ZENTENA	7545	0	1
3187	ZOILO PERALTA	7530	0	1
3188	ALFALAD	6555	0	1
3189	ANDANT	6555	0	1
3190	ARBOLEDA	6557	0	1
3191	ATAHUALPA	6471	0	1
3192	CORONEL MARCELINO FREYRE	6555	0	1
3193	DAIREAUX	6555	0	1
3194	ENRIQUE LAVALLE	6467	0	1
3195	LA ARMONIA	6555	0	1
3196	LA COPETA	7545	0	1
3197	LA LARGA	6555	0	1
3198	LA MANUELA	6439	0	1
3199	LOS COLONIALES	6555	0	1
3200	LOUGE	7545	0	1
3201	LURO	6439	0	1
3202	MASUREL	6438	0	1
3203	MAURAS	6555	0	1
3204	MOURAS	6471	0	1
3205	SALAZAR	6471	0	1
3206	VILLA ALDEANITA	6471	0	1
3207	VILLA CAROLA	6555	0	1
3208	DOLORES	7100	0	1
3209	EL 60	7100	0	1
3210	KILOMETRO 212	7100	0	1
3211	LA ESTRELLA	7100	0	1
3212	LA POSTA	7112	0	1
3213	LA PROTECCION	7112	0	1
3214	LAS VIBORAS	7100	0	1
3215	LOMA DE SALOMON	7100	0	1
3216	PARAJE LA VASCA	7100	0	1
3217	PARRAVICHINI	7100	0	1
3218	SEVIGNE	7101	0	1
3219	TRES LEGUAS	7100	0	1
3220	VECINO	7118	0	1
3221	BASE NAVAL RIO SANTIAGO	1929	0	1
3222	DESTILERIA FISCAL	1925	0	1
3223	DOCK CENTRAL	1925	0	1
3224	ENSENADA	1925	0	1
3225	ESC NAV MILITAR RIO SANT	1927	0	1
3226	FUERTE BARRAGAN	1925	0	1
3227	GRAND DOCK	1925	0	1
3228	ISLA SANTIAGO	1929	0	1
3229	PUERTO LA PLATA	1925	0	1
3230	PUNTA LARA	1931	0	1
3231	ARROYO CANELON	1625	0	1
3232	ARROYO LAS ROSAS	1625	0	1
3233	BARRIO GARIN NORTE	1623	0	1
3234	BARRIO PARQUE LAMBARE	1623	0	1
3235	BELEN DE ESCOBAR	1625	0	1
3236	GARIN	1619	0	1
3237	INGENIERO MASCHWITZ	1623	0	1
3238	LA GRACIELITA	1623	0	1
3239	LOMA VERDE	1625	0	1
3240	MAQUINISTA F SAVIO	1619	0	1
3241	MATHEU	1627	0	1
3242	PUERTO DE ESCOBAR	1625	0	1
3243	PUNTA DE CANAL	1623	0	1
3244	BARRIO EL CAZADOR	1625	0	1
3247	VILLA LA CHECHELA	1625	0	1
3248	VILLA VALLIER	1625	0	1
3478	ARROYO DE LA CRUZ	2813	0	1
3479	CAMPO LA NENA	2764	0	1
3480	CAPILLA DEL SE	2812	0	1
3481	CHENAUT	2764	0	1
3482	DIEGO GAYNOR	2812	0	1
3483	ETCHEGOYEN	6703	0	1
3484	EXALTACION DE LA CRUZ	2812	0	1
3485	GOBERNADOR ANDONAEGHI	2764	0	1
3486	KILOMETRO 102	2763	0	1
3487	LA LATA	2812	0	1
3488	LA ROSADA	2812	0	1
3489	LOS CARDALES	2814	0	1
3490	ORLANDO	2812	0	1
3491	PARADA ROBLES	6703	0	1
3492	PAVON	2812	0	1
3493	VILLA PRECEPTOR M ROBLES	2812	0	1
3494	VILLA PRECEPTOR MANUEL CRUZ	6703	0	1
3509	ARENALES	6005	0	1
3510	ARRIBE	6007	0	1
3511	ASCENCION	6003	0	1
3512	COLONIA LOS HORNOS	6007	0	1
3513	DELGADO	6007	0	1
3514	DESVIO EL CHINGOLO	6031	0	1
3515	DESVIO KILOMETRO 95	6007	0	1
3516	ESCUELA AGRICOLA SALESIANA	6003	0	1
3517	ESTACION ASCENSION	6003	0	1
3518	ESTACION GENERAL ARENALES	6005	0	1
3519	FERRE	6003	0	1
3520	GENERAL ARENALES	6005	0	1
3521	HAM	6005	0	1
3522	KILOMETRO 95	6031	0	1
3523	LA ANGELITA	6003	0	1
3524	LA HUAYQUERIA	6005	0	1
3525	LA PINTA	6007	0	1
3526	LA TRINIDAD	6003	0	1
3527	ABBOTT	7228	0	1
3528	BONNEMENT	7223	0	1
3529	CHAS	7223	0	1
3530	EL SIASGO	7223	0	1
3531	GENERAL BELGRANO	7223	0	1
3532	GORCHS	7226	0	1
3533	HARAS CHACABUCO	7223	0	1
3534	IBA	7223	0	1
3535	KILOMETRO 146	7226	0	1
3536	LA CHUMBEADA	7223	0	1
3537	LA ESPERANZA	7223	0	1
3538	LA VERDE	7223	0	1
3539	NEWTON	7223	0	1
3540	GENERAL GUIDO	7118	0	1
3541	LABARDEN	7161	0	1
3542	SAN JUSTO	7118	0	1
3543	AGUAS VERDES	7112	0	1
3544	BARRIO PEDRO ROCCO	7109	0	1
3545	COSTA AZUL	7112	0	1
3546	FARO SAN ANTONIO	7103	0	1
3547	GENERAL LAVALLE	7103	0	1
3548	LA LUCILA DEL MAR	7113	0	1
3549	LA MASCOTA	7119	0	1
3550	LA TABLADA	7163	0	1
3551	LA VICTORIA	7109	0	1
3552	LAS TONINAS	7106	0	1
3553	MAR DE AJO	7109	0	1
3554	MAR DEL TUYU	7108	0	1
3555	NUEVA ATLANTIS	7113	0	1
3556	PLAYA LAS MARGARITAS	7109	0	1
3557	PUNTA MEDANOS	7109	0	1
3558	SALADA CHICA	7163	0	1
3559	SALADA GRANDE	7163	0	1
3560	SAN BERNARDO DEL TUYU	7111	0	1
3561	SAN CLEMENTE DEL TUYU	7105	0	1
3562	SAN JOSE DE LOS QUINTEROS	7109	0	1
3563	SANTA TERESA	7163	0	1
3564	SANTA TERESITA	7107	0	1
3565	VILLA CLELIA	7109	0	1
3566	CARILO	7167	0	1
3567	CLAVERIE	7163	0	1
3568	EL CHAJA	7163	0	1
3569	ESPADA	7163	0	1
3570	FARO QUERANDI	7165	0	1
3571	GENERAL MADARIAGA	7163	0	1
3572	GOBOS	7163	0	1
3573	GO	7163	0	1
3574	GOROSO	7163	0	1
3575	HINOJALES	7163	0	1
3576	INVERNADAS	7163	0	1
3577	ISONDU	7163	0	1
3578	JUANCHO	7169	0	1
3579	LA ESPERANZA GRAL MADARIAGA	7163	0	1
3580	MACEDO	7169	0	1
3581	MAR AZUL	7165	0	1
3582	MAR DE LAS PAMPAS	7165	0	1
3583	MEDALAND	7169	0	1
3584	MONTECARLO	7167	0	1
3585	OSTENDE	7167	0	1
3586	PARQUE CARILO	7167	0	1
3587	PASOS	7163	0	1
3588	PINAMAR	7167	0	1
3589	SPERONI	7163	0	1
3590	TIO DOMINGO	7163	0	1
3591	VALERIA DEL MAR	7167	0	1
3592	VILLA GESELL	7165	0	1
3593	ALEGRE	1987	0	1
3594	CANCHA DEL POLLO	1987	0	1
3595	CUARTEL 2	1987	0	1
3596	ESPARTILLAR	1987	0	1
3597	ESTANCIA VIEJA	7225	0	1
3598	KILOMETRO 70	1981	0	1
3599	LOMA VERDE	1981	0	1
3600	LOS MERINOS	1980	0	1
3601	RANCHOS	1987	0	1
3602	RINCON DE VIVOT	7225	0	1
3603	VILLANUEVA	7225	0	1
3604	CORONEL GRANADA	6062	0	1
3605	DOS HERMANOS	6042	0	1
3606	DUSSAUD	6050	0	1
3607	EL PEREGRINO	6053	0	1
3608	GENERAL PINTO	6050	0	1
3609	GERMANIA	6053	0	1
3610	GUNTHER	6053	0	1
3611	HALCEY	6064	0	1
3612	HARAS EL CATORCE	6050	0	1
3613	INGENIERO BALBIN	6051	0	1
3614	IRIARTE	6042	0	1
3615	LA SUIZA	6050	0	1
3616	LOS CALLEJONES	6062	0	1
3617	MAYOR JOSE ORELLANO	6053	0	1
3618	PAZOS KANKI	6058	0	1
3620	SOLALE	6064	0	1
3621	VILLA FRANCIA	6058	0	1
3622	VOLTA	6064	0	1
3628	BANDERALO	6244	0	1
3629	CA	6105	0	1
3630	CORONEL CHARLONE	6223	0	1
3631	DRABBLE	6242	0	1
3632	EL DIA	6241	0	1
3633	ELORDI	6242	0	1
3634	EMILIO BUNGE	6241	0	1
3636	GENERAL VILLEGAS	6230	0	1
3637	GONDRA	6241	0	1
3638	LOS CALDENES	6242	0	1
3639	LOS LAURELES	6230	0	1
3640	MOORES	6230	0	1
3641	PICHINCHA	6051	0	1
3642	PIEDRITAS	6241	0	1
3643	PRADERE JUAN A	6231	0	1
3644	SANTA ELEODORA	6241	0	1
3645	SANTA REGINA	6105	0	1
3646	VILLA SABOYA	6101	0	1
3647	VILLA SAUCE	6235	0	1
3648	ALAMOS	6437	0	1
3649	ALFA	6437	0	1
3650	ARROYO EL CHINGOLO	6437	0	1
3651	ARROYO VENADO	6437	0	1
3652	BONIFACIO	6439	0	1
3653	BRAVO DEL DOS	6411	0	1
3654	CASBAS	6417	0	1
3655	CASEY	6417	0	1
3656	COLONIA SAN RAMON	6437	0	1
3657	EL NILO	6437	0	1
3658	EL TREBA	6437	0	1
3659	FORTIN PAUNERO	6417	0	1
3660	GARRE	6411	0	1
3661	GUAMINI	6435	0	1
3662	LA GREGORIA	6437	0	1
3663	LA HERMINIA	6437	0	1
3664	LA NEVADA	7545	0	1
3665	LAGUNA ALSINA	6439	0	1
3666	LAGUNA DEL MONTE	6435	0	1
3667	LAS CUATRO HERMANAS	6437	0	1
3668	LAS MERCEDES	6437	0	1
3669	LAS TRES FLORES	6437	0	1
3670	PAPIN	6411	0	1
3671	ROLITO ESTACION FCGB	6430	0	1
3672	SAN FERMIN	6417	0	1
3673	SANTA RITA PDO GUAMINI	6437	0	1
3674	SATURNO	6417	0	1
3675	VICTORINO DE LA PLAZA	6411	0	1
3676	VUELTA DE ZAPATA	6435	0	1
3683	AGUSTIN ROCA	6001	0	1
3684	AGUSTINA	6001	0	1
3685	BARRIO CAROSIO	6000	0	1
3687	BARRIO VILLA ORTEGA	6000	0	1
3688	BLANDENGUES	6032	0	1
3689	FORTIN TIBURCIO	6001	0	1
3691	LA ORIENTAL	6022	0	1
3692	LAGUNA DE GOMEZ	6001	0	1
3693	LAPLACETTE	6013	0	1
3694	LAS PARVAS	6022	0	1
3695	MORSE	6013	0	1
3696	PUEBLO NUEVO	6000	0	1
3697	SAFORCADA	6022	0	1
3698	VILLA BELGRANO	6000	0	1
3699	VILLA MAYOR	6000	0	1
3700	VILLA ORTEGA	6000	0	1
3701	VILLA PENOTTI	6000	0	1
3702	VILLA TALLERES	6000	0	1
3703	VILLA TRIANGULO	6000	0	1
3704	VILLA YORK	6000	0	1
3723	ABASTO	1903	0	1
3724	ARTURO SEGUI	1895	0	1
3725	CITY BELL	1896	0	1
3727	JOAQUIN GORINA	1896	0	1
3730	ARANA	1909	0	1
3739	ESTACION GOMEZ	1903	0	1
3740	ESTACION MORENO	1901	0	1
3741	LISANDRO OLMOS ETCHEVERRY	1901	0	1
3742	LOS EUCALIPTUS CASCO URBANO	1895	0	1
3743	MANUEL B GONNET	1897	0	1
3744	MELCHOR ROMERO	1903	0	1
3745	NUEVA HERMOSURA	1907	0	1
3746	PEREYRA IRAOLA PARQUE	1894	0	1
3747	POBLET	1905	0	1
3748	VILLA ELISA	1894	0	1
3749	ALDECON	7406	0	1
3750	CHALA QUILCA	7406	0	1
3751	FORTIN NECOCHEA	7406	0	1
3752	GENERAL LAMADRID	7406	0	1
3753	LA COLINA	7408	0	1
3754	LAS BANDURRIAS	7406	0	1
3755	LAS MARTINETAS	7406	0	1
3756	LASTRA	7406	0	1
3757	LIBANO	7407	0	1
3758	PONTAUT	7535	0	1
3759	QUILCO	7406	0	1
3760	RAULET	7530	0	1
3761	SAN QUILCO	7406	0	1
3762	SANTA CLEMENTINA	7406	0	1
3764	MONTE CHINGOLO	1825	0	1
3765	REMEDIOS DE ESCALADA	1826	0	1
3766	VALENTIN ALSINA	1822	0	1
3767	LAPRIDA	7414	0	1
3768	LAS HERMANAS	7412	0	1
3769	LOS PINOS	7412	0	1
3770	PARAG	7412	0	1
3771	SAN JORGE	7404	0	1
3772	SANTA ELENA	7414	0	1
3773	VILLA PUEBLO NUEVO	7414	0	1
3774	VOLUNTAD	7412	0	1
3775	CORONEL BOERR	7208	0	1
3776	DOCTOR DOMINGO HAROSTEGUY	7212	0	1
3777	EL GUALICHO	7200	0	1
3778	EL TRIGO	7207	0	1
3779	ESTRUGAMOU	7207	0	1
3780	LA ESPERANZA ROSAS LAS FLORES	7205	0	1
3781	LA PORTE	7207	0	1
3782	LAS FLORES	7200	0	1
3783	PARDO	7212	0	1
3784	PLAZA MONTERO	7201	0	1
3785	ROSAS	7205	0	1
3786	SANTA ROSA DE MINELLONO	7212	0	1
3787	VILELA	7208	0	1
3788	EL DURAZNO	1735	0	1
3789	ENRIQUE FYNN	1741	0	1
3790	GENERAL HORNOS	1739	0	1
3791	KILOMETRO 77	1737	0	1
3792	KILOMETRO 79	1741	0	1
3793	LA CHOZA	1737	0	1
3794	GENERAL LAS HERAS	1741	0	1
3795	LOZANO	1741	0	1
3796	PARADA KILOMETRO 76	1739	0	1
3797	PLOMER	1733	0	1
3798	SPERATTI	1741	0	1
3799	VILLARS	1731	0	1
3800	ALBERDI	6034	0	1
3801	COLONIA ALBERDI	6034	0	1
3802	DE BRUYN	6031	0	1
3803	EDMUNDO PERKINS	6030	0	1
3804	EL DORADO	6031	0	1
3805	FORTIN ACHA	6031	0	1
3806	JUAN BAUTISTA ALBERDI	6034	0	1
3807	LEANDRO N ALEM	6032	0	1
3808	SAUZALES	6030	0	1
3809	TRIGALES	6053	0	1
3810	VEDIA	6030	0	1
3811	ARENAZA	6075	0	1
3812	BALSA	6070	0	1
3813	BAYAUCA	6078	0	1
3814	BERMUDEZ	6071	0	1
3815	CARLOS SALAS	6453	0	1
3817	EL TRIUNFO	6073	0	1
3818	ESTACION LINCOLN	6070	0	1
3819	ESTANCIA MITIKILI	6075	0	1
3820	ESTANCIA SAN ANTONIO	6075	0	1
3821	FORTIN VIGILANCIA	6073	0	1
3822	HARAS TRUJUI	6075	0	1
3823	KILOMETRO 321	6070	0	1
3824	KILOMETRO 322	6533	0	1
3825	KILOMETRO 352	6075	0	1
3826	KILOMETRO 356	6075	0	1
3827	LA PRADERA	6453	0	1
3828	LA ZARATE	6077	0	1
3829	LAS TOSCAS	6453	0	1
3830	LINCOLN	6070	0	1
3831	LOS ALTOS	6075	0	1
3832	PASTEUR	6077	0	1
3833	PUEBLO MARTINEZ DE HOZ	6533	0	1
3834	ROBERTS	6075	0	1
3835	SANTA MARIA	6071	0	1
3836	TRIUNVIRATO	6071	0	1
3837	VIGELENCIA	6070	0	1
3838	CAMPO PELAEZ	7623	0	1
3839	COSTA BONITA BALNEARIO	7631	0	1
3840	DOS NACIONES	7007	0	1
3841	EL CHEIQUE	7007	0	1
3842	EL LENGUARAZ	7635	0	1
3843	EL MORO	7623	0	1
3844	HARAS EL MORO	7631	0	1
3845	HARAS NACIONAL	7631	0	1
3846	KILOMETRO 440	7635	0	1
3847	LA PALMA	7007	0	1
3848	LA PLAYA	7631	0	1
3849	LAS NUTRIAS	7623	0	1
3850	LICENCIADO MATIENZO	7007	0	1
3851	LOBERIA	7635	0	1
3852	LOS CERROS	7635	0	1
3853	MALECON GARDELLA	7631	0	1
3854	MAORI	7633	0	1
3855	PIERES	7633	0	1
3856	QUEQUEN	7631	0	1
3857	SAN MANUEL	7007	0	1
3858	SAN MIGUEL DEL MORO	7631	0	1
3859	TAMANGUEYU	7633	0	1
3860	VILLA PUERTO QUEQUEN	7631	0	1
3861	ANTONIO CARBONI	7243	0	1
3862	AREVALO	7243	0	1
3863	EL ARAZA	7249	0	1
3864	ELVIRA	7243	0	1
3865	EMPALME LOBOS	7249	0	1
3866	KILOMETRO 112	7240	0	1
3867	KILOMETRO 88	1815	0	1
3868	LA ADELAIDA	7243	0	1
3869	LA PORTE	7241	0	1
3870	LAGUNA DE LOBOS	7240	0	1
3871	LAS CHACRAS	7241	0	1
3872	LOBOS	7240	0	1
3873	SALVADOR MARIA	7241	0	1
3874	SANTA ALICIA	7243	0	1
3875	SANTA FELICIA	7243	0	1
3876	ZAPIOLA	7249	0	1
3884	ALASTUEY	6703	0	1
3885	CAMINERA LUJAN	6700	0	1
3886	CA	6700	0	1
3887	CARLOS KEEN	6701	0	1
3888	COLONIA NAC DE ALIENADOS	6708	0	1
3889	CORTINES	6712	0	1
3890	CUARTEL CUATRO	6700	0	1
3891	DOCTOR DOMINGO CABRED	6708	0	1
3892	EST JAUREGUI VA FLANDRIA	6706	0	1
3893	LA LOMA	6700	0	1
3894	LEZICA Y TORREZURI	6700	0	1
3896	MARISCAL SUCRE	6708	0	1
3897	OLIVERA	6608	0	1
3898	OPEN DOOR	6708	0	1
3899	PUEBLO NUEVO	6700	0	1
3900	RUTA 8 KILOMETRO 77	6703	0	1
3901	SAN ELADIO	6601	0	1
3902	SANTA ELENA	6700	0	1
3903	SUCRE	6708	0	1
3904	TORRES	6703	0	1
3905	JAUREGUI JOSE MARIA	6706	0	1
3906	VILLA FRANCIA	6706	0	1
3908	ARBUCO	1915	0	1
3909	ATALAYA	1913	0	1
3910	BARRIO EL PORTE	1915	0	1
3911	BME BAVIO GRAL MANSILLA	1911	0	1
3912	BASE AERONAVAL PUNTA INDIO	1919	0	1
3913	COLONIA BEETHOVEN	1921	0	1
3914	CRISTINO BENAVIDEZ	1913	0	1
3915	EL PINO	1907	0	1
3916	EL ROSARIO	1921	0	1
3917	EMPALME MAGDALENA	1913	0	1
3918	JOSE FERRARI	1905	0	1
3919	JULIO ARDITI	1913	0	1
3920	KILOMETRO 103	1915	0	1
3921	KILOMETRO 92	1911	0	1
3922	LA PRIMAVERA	1921	0	1
3923	LA TALINA	1921	0	1
3925	LOS SANTOS VIEJOS	1921	0	1
3927	MAGDALENA	1913	0	1
3928	MONTE VELOZ	1917	0	1
3930	PARAJE STARACHE	1915	0	1
3931	PAYRO R	1913	0	1
3932	PI	1921	0	1
3933	PIPINAS	1921	0	1
3934	PUNTA INDIO	1917	0	1
3935	RINCON DE NOARIO	1921	0	1
3936	RUTA 11 KILOMETRO 23	1907	0	1
3937	VERGARA	7135	0	1
3938	VERONICA	1917	0	1
3939	VIEYTES	1915	0	1
3940	CARI LARQUEA	7119	0	1
3941	COLONIA FERRARI	7172	0	1
3942	HOGAR MARIANO ORTIZ BASUALDO	7172	0	1
3943	LA AMORILLA	7119	0	1
3944	LA COLORADA	7119	0	1
3945	LAS ARMAS	7172	0	1
3946	MAIPU	7160	0	1
3947	MONSALVO	7119	0	1
3948	SANTO DOMINGO	7119	0	1
3949	SEGUROLA	7119	0	1
4065	ARROYO GRANDE	7174	0	1
4066	BALNEARIO SANTA ELENA	7609	0	1
4067	CALFUCURA	7613	0	1
4068	CAMPAMENTO	7613	0	1
4069	COBO	7612	0	1
4070	CORONEL VIDAL	7174	0	1
4071	EL REFUGIO	7612	0	1
4072	EL VIGILANTE	7174	0	1
4073	ESCUELA AGRICOLA RURAL	7174	0	1
4074	GENERAL PIRAN	7172	0	1
4075	HARAS 1 DE MAYO	7174	0	1
4076	LA TOBIANA	7174	0	1
4077	LAS CHILCAS	7174	0	1
4078	MAR CHIQUITA	7174	0	1
4079	NAHUEL RUCA	7613	0	1
4080	SAN JULIAN	7613	0	1
4081	SAN VALENTIN	7613	0	1
4082	SANTA CLARA DEL MAR	7609	0	1
4083	SIEMPRE VERDE	7609	0	1
4084	UNIDAD TURISTICA CHAPADMALAL	7609	0	1
4085	VIVORATA	7612	0	1
4086	B LOS AROMOS SAN PATRICIO	1727	0	1
4087	B NUESTRA SE	1727	0	1
4088	B STA CATALINA HORNERO LA LOMA	1727	0	1
4089	B SARMIENTO DON ROLANDO	1727	0	1
4090	COLONIA HOGAR R GUTIERREZ	1727	0	1
4091	COLONIA NACIONAL DE MENORES	1727	0	1
4092	ELIAS ROMERO	1727	0	1
4093	KILOMETRO 45	1727	0	1
4094	KILOMETRO 53	1727	0	1
4096	MARCOS PAZ B BERNASCONI	1727	0	1
4097	MARCOS PAZ B EL MARTILLO	1727	0	1
4098	MARCOS PAZ B EL MORO	1727	0	1
4099	MARCOS PAZ B EL ZORZAL	1727	0	1
4100	MARCOS PAZ B LA LONJA	1727	0	1
4101	MARCOS PAZ B LA MILAGROSA	1727	0	1
4102	MARCOS PAZ B MARTIN FIERRO	1727	0	1
4103	MARCOS PAZ B URIOSTE	1727	0	1
4104	ZAMUDIO	1727	0	1
4105	AGOTE	6608	0	1
4106	ALTAMIRA	6601	0	1
4107	BARRIO GENERAL SAN MARTIN	6000	0	1
4108	COMAHUE OESTE	6601	0	1
4109	GOLDNEY	6614	0	1
4110	GOWLAND	6608	0	1
4111	LA VALEROSA	6601	0	1
4112	LA VERDE	6601	0	1
4113	MANUEL JOSE GARCIA	6608	0	1
4116	SAN JACINTO	6600	0	1
4117	SEMINARIO PIO XII	6600	0	1
4118	TOMAS JOFRE	6601	0	1
4124	BALNEARIO ORIENTE	8153	0	1
4125	BALNEARIO SAUCE GRANDE	8153	0	1
4126	MONTE HERMOSO	8153	1	1
4127	ZUBIAURRE	8151	0	1
4137	ACHUPALLAS	6627	0	1
4138	ANASAGASTI	6607	0	1
4139	CAMPO PE	6605	0	1
4140	ESTEBAN DIAZ	6607	0	1
4141	GONZALEZ RISOS	6605	0	1
4143	JUAN JOSE ALMEYRA	6603	0	1
4144	KILOMETRO 116	6605	0	1
4145	KILOMETRO 117	6603	0	1
4146	KILOMETRO 83	6605	0	1
4147	KILOMETRO 90	6605	0	1
4148	LA BLANQUEADA	7243	0	1
4149	LA VICTORIA DESVIO	6627	0	1
4150	LAS MARIANAS	6607	0	1
4151	MOLL	6627	0	1
4152	NAVARRO	6605	0	1
4153	RINCON NORTE	6605	0	1
4154	SOL DE MAYO	7243	0	1
4155	INGENIERO WILLIAMS	6603	0	1
4156	ANEQUE GRANDE	7011	0	1
4157	ARROYO CHICO	7011	0	1
4158	BALNEARIO LOS ANGELES	7641	0	1
4159	CLARAZ	7005	0	1
4160	EL PITO	7641	0	1
4161	ENERGIA	7641	0	1
4162	HARAS LA LULA	7011	0	1
4163	HOSPITAL NECOCHEA	7630	0	1
4164	JUAN N FERNANDEZ	7011	0	1
4165	LA DULCE	7637	0	1
4166	LA NEGRA	7005	0	1
4167	LA PRIMITIVA	7630	0	1
4168	LUMB	7639	0	1
4169	MEDANO BLANCO	7630	0	1
4171	NICANOR OLIVERA	7637	0	1
4172	PUERTO NECOCHEA	7641	0	1
4173	RAMON SANTAMARINA	7641	0	1
4174	SAN CALA	7011	0	1
4175	SAN JOSE	7635	0	1
4176	VALENZUELA ANTON	7630	0	1
4177	VILLA DIAZ VELEZ	7630	0	1
4220	ALVARO BARROS	7403	0	1
4221	BARRIO LA LUISA	7400	0	1
4222	BLANCA GRANDE	6561	0	1
4223	CALERA AVELLANEDA	7400	0	1
4224	CANTERAS DE GREGORINI	7401	0	1
4225	CERRO NEGRO	7403	0	1
4226	CERRO SOTUYO	7403	0	1
4227	COLONIA HINOJO	7318	0	1
4228	COLONIA NIEVES	7318	0	1
4229	COLONIA RUSA	7318	0	1
4230	COLONIA SAN MIGUEL	7403	0	1
4231	DURA	7401	0	1
4232	EMPALME QUERANDIES	7401	0	1
4233	ESPIGAS	6561	0	1
4235	FORTIN LAVALLE	7404	0	1
4236	HINOJO	7318	0	1
4237	ITURREGUI	6557	0	1
4238	KILOMETRO 333	7400	0	1
4239	LA ESTRELLA	7403	0	1
4240	LA NARCISA	7403	0	1
4241	LA NAVARRA	7400	0	1
4242	LA PALMIRA	7403	0	1
4243	LA PROTEGIDA	6561	0	1
4244	LA PROVIDENCIA	7403	0	1
4245	LA TOMASA	7403	0	1
4246	LAS PIEDRITAS	7400	0	1
4247	LOMA NEGRA	7403	0	1
4248	MAPIS	6557	0	1
4249	MU	7404	0	1
4250	OLAVARRIA	7400	0	1
4251	POURTALE	7404	0	1
4252	PUEBLO NUEVO	7400	0	1
4253	RECALDE	6559	0	1
4254	ROCHA	7404	0	1
4255	SAN JACINTO	7400	0	1
4256	SAN JUAN	7401	0	1
4257	SANTA LUISA	7401	0	1
4258	SIERRA CHICA	7401	0	1
4259	SIERRAS BAYAS	7403	0	1
4260	TENIENTE CORONEL MI	7401	0	1
4262	VILLA MONICA	7318	0	1
4263	ABEL	6450	0	1
4264	ALAGON	6463	0	1
4265	ALBARI	6405	0	1
4266	ANCON	6451	0	1
4267	ASTURIAS	6469	0	1
4268	BARRIO OBRERO	6450	0	1
4269	CAMPO ARISTIMU	6474	0	1
4270	CAPITAN CASTRO	6461	0	1
4271	CHICLANA	6476	0	1
4272	EL RECADO	6474	0	1
4273	EL SANTIAGO	6463	0	1
4274	FRANCISCO MADERO	6472	0	1
4275	GNECCO	6451	0	1
4276	GUANACO	6476	0	1
4277	GIRONDO	6451	0	1
4278	INOCENCIO SOSA	6451	0	1
4279	JUAN JOSE PASO	6474	0	1
4280	LA COTORRA	6461	0	1
4281	LARRAMENDY	6451	0	1
4282	LAS JUANITAS	6476	0	1
4283	MAGDALA	6451	0	1
4284	MONES CAZON	6469	0	1
4285	NUEVA PLATA	6451	0	1
4286	PEDRO GAMEN	6451	0	1
4287	PEHUAJO	6450	0	1
4288	PUEBLO SAN ESTEBAN	6450	0	1
4289	ROVIRA	6450	0	1
4290	SAN BERNARDO	6476	0	1
4291	SANTA CECILIA CENTRO	6463	0	1
4292	SANTA CECILIA NORTE	6472	0	1
4293	SANTA CECILIA SUD	6450	0	1
4294	BOCAYUBA	6348	0	1
4295	DE BARY	6348	0	1
4296	INGENIERO THOMPSON	6337	0	1
4297	JOSE MARIA BLANCO	6409	0	1
4298	MARIA P MORENO	6337	0	1
4299	PEHUELCHES	6409	0	1
4300	PELLEGRINI	6346	0	1
4302	ACEVEDO	2717	0	1
4303	AGUAS CORRIENTES	2701	0	1
4304	ALMACEN CASTRO	2751	0	1
4305	ALMACEN PIATTI	2711	0	1
4306	BARRIO TROCHA	2700	0	1
4307	CABO SAN FERMIN	2703	0	1
4309	CAMPO BUENA VISTA	2700	0	1
4310	CHACRA EXPERIMENTAL INTA	2700	0	1
4311	COLONIA LA NENA	2751	0	1
4312	COLONIA LA VANGUARDIA	2711	0	1
4313	COLONIA LABORDEROY	2751	0	1
4314	COLONIA LOS TOLDOS	2751	0	1
4316	EL CARMEN	2754	0	1
4317	EL QUEMADO	2751	0	1
4318	EL SOCORRO	2715	0	1
4319	ESTANCIAS	2909	0	1
4320	FONTEZUELA	2700	0	1
4321	FRANCISCO AYERZA	2700	0	1
4323	GORNATTI	2717	0	1
4324	GUERRICO	2717	0	1
4325	HARAS EL CENTINELA	2701	0	1
4326	HOSPITAL SAN ANTONIO DE LA LLA	2700	0	1
4327	JUAN G PUJOL	2909	0	1
4328	JUANA A DE LA PE	2717	0	1
4329	LA CORA	2700	0	1
4330	LA MARGARITA	2715	0	1
4331	LA SARITA	2751	0	1
4332	LA VANGUARDIA	2715	0	1
4333	LA VIOLETA	2751	0	1
4334	LIERRA ADJEMIRO	2718	0	1
4335	LOPEZ MOLINARI	2718	0	1
4336	MAGUIRRE	2718	0	1
4337	MANANTIALES	2717	0	1
4338	MANANTIALES GRANDES	2700	0	1
4339	MANUEL OCAMPO	2713	0	1
4340	MANZO Y NI	2718	0	1
4341	MARIANO H ALFONZO	2718	0	1
4342	MARIANO BENITEZ	2701	0	1
4343	MUTTI	2909	0	1
4344	ORTIZ BASUALDO	2703	0	1
4345	PARAJE SANTA ROSA	2711	0	1
4348	PINZON	2703	0	1
4349	PUEBLO OTERO	2700	0	1
4350	PUJOL	2907	0	1
4351	RANCAGUA	2701	0	1
4352	SAN FEDERICO	2711	0	1
4353	SAN JUAN	2754	0	1
4354	SAN RAMON	2754	0	1
4355	SANTA RITA	2700	0	1
4356	SANTA TERESITA PERGAMINO	2701	0	1
4357	TAMBO NUEVO	2700	0	1
4358	URQUIZA	2718	0	1
4359	VILLA CENTENARIO	2700	0	1
4360	VILLA DA FONTE	2718	0	1
4361	VILLA GODOY	2700	0	1
4362	VILLA PROGRESO	2700	0	1
4363	CAMARON CHICO	7116	0	1
4364	CASALINS	7225	0	1
4365	DON VICENTE	7116	0	1
4366	EL ALBA	7225	0	1
4367	EL VENCE	7116	0	1
4368	LA ALCIRA	7116	0	1
4369	LA DESPIERTA	7116	0	1
4370	LA FLORIDA	7116	0	1
4371	LA LARGA NUEVA	7116	0	1
4372	LA LUZ	7225	0	1
4373	LA MASCOTA	7225	0	1
4374	LA PIEDRA	7116	0	1
4375	LA REFORMA	7110	0	1
4376	LA VICTORIA	7225	0	1
4377	LAS ACHIRAS	7116	0	1
4378	LAS CHILCAS	7116	0	1
4379	LAS TORTUGAS	7116	0	1
4380	PILA	7116	0	1
4381	PUENTE EL OCHENTA	7225	0	1
4382	REAL AUDIENCIA	7225	0	1
4383	SAN ANTONIO	7116	0	1
4384	SAN DANIEL	7116	0	1
4385	SAN ENRIQUE	7116	0	1
4386	ALMIRANTE IRIZAR	1629	0	1
4387	BARRIO SAN ALEJO	1629	0	1
4388	CARLOS LEMEE	2812	0	1
4389	DEL VISO	1669	0	1
4390	EMPALME	1633	0	1
4391	ESTABLECIMIENTO SAN MIGUEL	1629	0	1
4392	FATIMA ESTACION EMPALME	1633	0	1
4393	KILOMETRO 45	1635	0	1
4394	KILOMETRO 61	1629	0	1
4395	MANUEL ALBERTI	1667	0	1
4396	MANZANARES	1629	0	1
4397	MANZONE	1633	0	1
4399	PRESIDENTE DERQUI	1635	0	1
4400	TORO	1635	0	1
4401	VILLA AGUEDA	1629	0	1
4402	VILLA ASTOLFI	1633	0	1
4403	VILLA BUIDE	1629	0	1
4404	VILLA ROSA	1631	0	1
4405	VILLA SANTA MARIA	1629	0	1
4406	VILLA VERDE	1629	0	1
4407	ZELAYA	1627	0	1
4409	17 DE AGOSTO	8129	0	1
4410	ADELA SAENZ	8129	0	1
4411	ALDEA SAN ANDRES	8126	0	1
4413	AZOPARDO	8181	0	1
4414	BORDENAVE	8187	0	1
4415	COLONIA DR GDOR UDAONDO	8180	0	1
4416	COLONIA EL PINCEN	8181	0	1
4417	COLONIA HIPOLITO YRIGOYEN	8181	0	1
4418	COLONIA LA CATALINA	8136	0	1
4419	COLONIA LA VASCONGADA	8183	0	1
4420	COLONIA SANTA ROSA	8181	0	1
4422	DESVIO SAN ALEJO	8180	0	1
4423	EMPALME PIEDRA ECHADA	8117	0	1
4424	ERIZE	8181	0	1
4425	ESTELA	8127	0	1
4426	FELIPE SOLA	8129	0	1
4427	GENERAL RONDEAU	8124	0	1
4428	LA CELINA	8136	0	1
4429	LA COLORADA CHICA	8126	0	1
4430	LA EVA	8136	0	1
4431	LA POCHOLA	8124	0	1
4432	LA ROSALIA	8187	0	1
4433	LA SOMBRA	8136	0	1
4434	LA VASCONGADA	8181	0	1
4435	LOPEZ LECUBE	8117	0	1
4436	PIEDRA ANCHA	8117	0	1
4438	RIVADEO	8127	0	1
4439	SAN ANDRES	8180	0	1
4440	SAN EMILIO	8136	0	1
4441	SAN GERMAN	8124	0	1
4442	SAN JOSE	8136	0	1
4443	TRES CUERVOS	8183	0	1
4444	VIBORAS	8180	0	1
4447	BALNEARIO MAR CHIQUITA	7609	0	1
4449	BARRIO BATAN	7601	0	1
4452	BARRIO CHAPADMALAL	7605	0	1
4458	BARRIO EMIR RAMON JUAREZ	7600	0	1
4461	BARRIO GASTRONOMICO	7600	0	1
4473	BARRIO PUEBLO NUEVO	7600	0	1
4478	BARRIO TIERRA DE ORO	7600	0	1
4479	BARRIO TIRO FEDERAL	7600	0	1
4482	CAMET	7612	0	1
4483	COLONIA DE VAC CHAPADMALAL	7609	0	1
4484	EL BOQUERON	7601	0	1
4486	EL SOLDADO	7600	0	1
4488	HARAS CHAPADMALAL	7605	0	1
4491	LA PEREGRINA	7601	0	1
4492	LAGUNA DE LOS PADRES	7601	0	1
4493	LAGUNA DEL SOLDADO	7600	0	1
4495	LOS ORTIZ	7601	0	1
4502	PLAYA CHAPADMALAL	7609	0	1
4508	SIERRA DE LOS PADRES	7601	0	1
4509	VILLA VIGNOLO	7600	0	1
4519	AGUIRREZABALA	2915	0	1
4520	ALMACEN EL CRUCE	2751	0	1
4521	COLONIA LA INVERNADA	2751	0	1
4522	COLONIA LA NORIA	2751	0	1
4523	COLONIA LA REINA	2751	0	1
4524	COLONIA STEGMAN	2751	0	1
4525	COSTA BRAVA	2914	0	1
4526	EL JUPITER	2916	0	1
4527	EL PARAISO	2916	0	1
4528	HARAS EL OMBU	2916	0	1
4529	LA ESPERANZA	2915	0	1
4530	LA QUERENCIA	2912	0	1
4531	LAS BAHAMAS	2916	0	1
4532	PEREZ MILLAN	2933	0	1
4533	RAMALLO	2915	0	1
4534	SANTA TERESA	2912	0	1
4535	VILLA GRAL SAVIO EX SANCHEZ	2912	0	1
4536	VILLA RAMALLO EST FFCC	2914	0	1
4537	VILLA RAMALLO	2914	0	1
4538	CHAPALEUFU	7203	0	1
4539	COLMAN	7201	0	1
4540	EGA	7013	0	1
4541	EL CARMEN DE LANGUEYU	7203	0	1
4542	EL CHALAR	7201	0	1
4543	GALERA DE TORRES	7203	0	1
4544	LOMA NEGRA	7203	0	1
4545	LOMA PARTIDA	7203	0	1
4546	MAGALLANES	7151	0	1
4547	MIRANDA	7201	0	1
4548	PE	7225	0	1
4549	RAUCH	7203	0	1
4550	SAN JOSE	7203	0	1
4551	VILLA BURGOS	7203	0	1
4552	VILLA LOMA	7203	0	1
4553	VILLA SAN PEDRO	7203	0	1
4554	AMERICA	6237	0	1
4555	BADANO	6403	0	1
4556	CERRITO	6237	0	1
4557	COLONIA EL BALDE	6403	0	1
4558	CONDARCO	6233	0	1
4559	FORTIN OLAVARRIA	6403	0	1
4560	GONZALEZ MORENO	6239	0	1
4561	LA CAUTIVA	6403	0	1
4562	MERIDIANO VO	6239	0	1
4563	MIRA PAMPA	6403	0	1
4564	RIVADAVIA	6237	0	1
4565	ROOSEVELT	6403	0	1
4566	SAN MAURICIO	6239	0	1
4437	PUAN	8180	0	1
4567	SANSINENA	6233	0	1
4568	SUNDBLAD	6401	0	1
4569	VALENTIN GOMEZ	6401	0	1
4570	VILLA SENA	6403	0	1
4571	CARABELAS	2703	0	1
4572	COLONIA LA BEBA	6003	0	1
4573	4 DE NOVIEMBRE	2707	0	1
4574	EL JAGUEL	2707	0	1
4575	GUIDO SPANO	2707	0	1
4576	HARAS SAN JACINTO	2705	0	1
4577	HUNTER	2707	0	1
4578	KILOMETRO 36	2705	0	1
4579	LA BEBA	6003	0	1
4580	LA NACION	2707	0	1
4581	LAS SALADAS	2707	0	1
4582	LOS INDIOS	2709	0	1
4583	PIRUCO	2705	0	1
4584	PLUMACHO	2703	0	1
4585	RAFAEL OBLIGADO	6001	0	1
4586	ROBERTO CANO	2703	0	1
4587	ROJAS	2705	0	1
4588	SOL DE MAYO	2709	0	1
4589	VILLA PROGRESO	2705	0	1
4590	BARRIENTOS	7247	0	1
4591	CAMPO SABATE	7245	0	1
4592	CARLOS BEGUERIE	7247	0	1
4593	HARAS EL SALASO	7245	0	1
4594	JUAN ATUCHA	7245	0	1
4595	JUAN TRONCONI	7247	0	1
4596	LA PAZ	7245	0	1
4597	LA PAZ CHICA	7247	0	1
4598	LA REFORMA	7245	0	1
4599	LA RINCONADA	7245	0	1
4600	ROQUE PEREZ	7245	0	1
4601	SANTIAGO LARRE	7245	0	1
4602	ABRA DE HINOJO	8170	0	1
4603	ALTA VISTA	8170	0	1
4604	ARQUEDAS	8164	0	1
4605	ARROYO AGUAS BLANCAS	8174	0	1
4606	ARROYO CORTO	8172	0	1
4607	COLONIA SAN MARTIN	8164	0	1
4608	COLONIA SAN PEDRO	8164	0	1
4609	DUCOS	8170	0	1
4612	GOYENA	8175	0	1
4613	LA SAUDADE	8174	0	1
4614	PIGUE	8170	1	1
4615	SAAVEDRA	8174	1	1
4616	SAN MARTIN DE TOURS	8164	0	1
4617	ALVAREZ DE TOLEDO	7267	0	1
4618	BARRIO VILLA SALADILLO	7260	0	1
4619	CAZON	7265	0	1
4620	DEL CARRIL	7265	0	1
4621	EL MANGRULLO	7260	0	1
4622	EMILIANO REYNOSO	7260	0	1
4623	ESTHER	7260	0	1
4624	GOBERNADOR ORTIZ DE ROSAS	7260	0	1
4625	JOSE SOJO	7260	0	1
4626	JUAN BLAQUIER	7267	0	1
4627	LA BARRANCOSA	7260	0	1
4628	LA CAMPANA	7260	0	1
4629	LA MARGARITA	7260	0	1
4630	LA RAZON	7260	0	1
4631	POLVAREDAS	7267	0	1
4632	SALADILLO	7260	0	1
4633	SALADILLO NORTE	7261	0	1
4634	SAN BENITO	7261	0	1
4635	TOLDOS VIEJOS	7267	0	1
4636	CAILOMUTA	6339	0	1
4637	ESTACION CAIOMUTA	6339	0	1
4638	GRACIARENA	6335	0	1
4639	QUENUMA	6335	0	1
4640	SALLIQUELO	6339	0	1
4641	ARROYO DULCE	2743	0	1
4642	BERDIER	2743	0	1
4643	CORONEL ISLE	2747	0	1
4644	EL RETIRO	2741	0	1
4645	GAHAN	2745	0	1
4646	INES INDART	2747	0	1
4647	KILOMETRO 187	2741	0	1
4648	LA INVENCIBLE	2745	0	1
4649	LAS CUATRO PUERTAS	2741	0	1
4650	MARCELINO UGARTE	2741	0	1
4651	MONROE	2743	0	1
4652	SALTO	2741	0	1
4653	TACUARI	2743	0	1
4654	VILLA SAN JOSE	2743	0	1
4655	AZCUENAGA	6721	0	1
4656	CUCULLU	6723	0	1
4657	ESPORA	6601	0	1
4658	FRANKLIN	6614	0	1
4659	HEAVY	6723	0	1
4660	KILOMETRO 108	6723	0	1
4661	KILOMETRO 125	6720	0	1
4662	LA FLORIDA	6720	0	1
4663	RUIZ SOLIS	6720	0	1
4664	SAN ANDRES DE GILES	6720	0	1
4665	SOLIS	2764	0	1
4666	TUYUTI	6721	0	1
4667	VILLA ESPIL	6712	0	1
4668	VILLA RUIZ	6705	0	1
4669	VILLA SAN ALBERTO	6720	0	1
4671	COLONIA LOS TRES USARIS	2760	0	1
4672	DUGGAN	2764	0	1
4673	FLAMENCO	2763	0	1
4674	PUENTE CASTEX	2760	0	1
4675	PUESTO DEL MEDIO	2763	0	1
4676	SAN ANTONIO DE ARECO	2760	0	1
4677	VAGUES	2764	0	1
4678	VILLA LIA	2761	0	1
4679	BALNEARIO CLAROMECO	7505	0	1
4680	COOPER	7639	0	1
4681	CRISTIANO MUERTO	7503	0	1
4682	DEFERRARI	7521	0	1
4683	EL CRISTIANO	7503	0	1
4684	LA BALLENA	7521	0	1
4685	LA FELICIANA	7503	0	1
4686	LA GAVIOTA	7521	0	1
4687	LOMA DEL INDIO	7521	0	1
4688	LOS MOLLES	7503	0	1
4689	OCHANDIO	7521	0	1
4690	SAN CAYETANO	7521	0	1
4691	SAN SEVERO	7521	0	1
4692	SANTA CATALINA	7503	0	1
4695	ACASSUSO	1640	0	1
4696	BECCAR	1643	0	1
4697	BOULOGNE	1609	0	1
4698	MARTINEZ	1640	0	1
4699	SAN ISIDRO	1642	0	1
4700	VILLA ADELINA	1607	0	1
4711	CAMPO FUNKE	7247	0	1
4712	FRANCISCO BERRA	7221	0	1
4713	FUNKE	7220	0	1
4714	GOYENECHE	7220	0	1
4715	GUARDIA DEL MONTE	7220	0	1
4716	KILOMETRO 128	7221	0	1
4717	KILOMETRO 88	7220	0	1
4718	LOS CERRILLOS	7226	0	1
4719	LOS EUCALIPTOS	7220	0	1
4720	SAN MIGUEL DEL MONTE	7220	0	1
4721	ZENON VIDELA DORNA	7226	0	1
4740	ALGARROBO	2935	0	1
4741	ARROYO BURGOS	2935	0	1
4742	COLONIA VELEZ	2933	0	1
4743	DOYLE	2935	0	1
4744	EL DESCANSO	2935	0	1
4745	EL ESPINILLO	2946	0	1
4746	GOBERNADOR CASTRO	2946	0	1
4747	INGENIERO MONETA	2935	0	1
4748	KILOMETRO 172	2935	0	1
4749	KILOMETRO 184	2946	0	1
4750	LA BOLSA	2933	0	1
4751	LA BUANA MOZA	2930	0	1
4752	LA MATILDE	2931	0	1
4753	LAS FLORES	2930	0	1
4754	OLIVEIRA CESAR	2931	0	1
4755	PARADA KILOMETRO 158	2935	0	1
4756	RIO TALA	2944	0	1
4757	RUTA 9 KILOMETRO 169 5	2930	0	1
4758	SAN PEDRO	2930	0	1
4759	SANTA LUCIA	2935	0	1
4760	VILLA DEPIETRI	2930	0	1
4761	VILLA LEANDRA	2946	0	1
4762	VILLA SARITA	2930	0	1
4763	VILLA TERESA	2944	0	1
4764	VILLAIGRILLO	2930	0	1
4765	VUELTA DE OBLIGADO	2931	0	1
4766	ALEJANDRO KORN	1864	0	1
4767	BARRIO SAN PABLO	1862	0	1
4768	BARRIO SANTA MAGDALENA	1862	0	1
4769	DOMSELAAR	1984	0	1
4770	EL PAMPERO	1865	0	1
4771	LA ARGENTINA	1865	0	1
4772	SAN VICENTE	1865	0	1
4773	CAPDEPONT	6612	0	1
4774	GENERAL RIVAS	6614	0	1
4775	HARAS LA ELVIRA	6612	0	1
4776	LA SARA	6612	0	1
4777	ROMAN BAEZ	6612	0	1
4778	SUIPACHA	6612	0	1
4779	ACEILAN	7003	0	1
4780	CANTERA AGUIRRE	7000	0	1
4781	CANTERA ALBION	7000	0	1
4782	CANTERA LA AURORA	7000	0	1
4783	CANTERA LA FEDERACION	7000	0	1
4784	CANTERA LA MOVEDIZA	7000	0	1
4785	CANTERA MONTE CRISTO	7000	0	1
4786	CANTERA SAN LUIS	7000	0	1
4787	CERRO DE LOS LEONES	7000	0	1
4788	DE LA CANAL	7013	0	1
4789	DESVIO AGUIRRE	7000	0	1
4790	EL GALLO	7000	0	1
4791	EMPALME CERRO CHATO	7000	0	1
4792	FULTON	7007	0	1
4793	GARDEY	7003	0	1
4794	IRAOLA	7009	0	1
4795	LA AURORA	7009	0	1
4796	LA AZOTEA	7007	0	1
4797	LA AZUCENA	7005	0	1
4798	LA NUMANCIA	7000	0	1
4799	LA PASTORA	7001	0	1
4800	LOS LEONES	7000	0	1
4801	MARIA IGNACIA	7003	0	1
4802	SAN PASCUAL	7007	0	1
4805	VELA	7003	0	1
4806	VILLA DAZA	7000	0	1
4807	VILLA DUFAU	7000	0	1
4808	VILLA GALICIA	7000	0	1
4809	VILLA ITALIA	7000	0	1
4811	ALTONA	7303	0	1
4812	CAMPO ROJAS	7303	0	1
4813	CROTTO	7307	0	1
4814	EL MIRADOR	7305	0	1
4815	EL SAUCE	7303	0	1
4816	LA ISABEL	7112	0	1
4817	LA PROTEGIDA	7311	0	1
4818	REQUENA	7307	0	1
4819	SAN ANDRES DE TAPALQUE	7305	0	1
4820	SAN BERNARDO	6561	0	1
4821	SANTA ROSA	7303	0	1
4822	TAPALQUE	7303	0	1
4823	UBALLES	7301	0	1
4824	VELLOSO	7305	0	1
4825	YERBAS	7303	0	1
4834	ESQUINA DE CROTTO	7100	0	1
4835	GENERAL CONESA	7101	0	1
4836	TORDILLO	7101	0	1
4837	BERRAONDO	8124	0	1
4838	CHASICO	8117	0	1
4840	EL CORTAPIE	8117	0	1
4841	ESTOMBA	8118	0	1
4842	FORTIN CHACO	8160	0	1
4843	FUERTE ARGENTINO	8160	0	1
4844	GARCIA DEL RIO	8162	0	1
4845	GLORIALDO	8129	0	1
4846	NUEVA ROMA	8117	0	1
4847	PELICURA	8117	0	1
4848	SALDUNGARAY	8166	1	1
4849	SIERRA DE LA VENTANA	8168	1	1
4850	TORNQUIST	8160	1	1
4851	TRES PICOS	8162	0	1
4852	30 DE AGOSTO	6405	0	1
4853	BARRIO INDIO TROMPA	6400	0	1
4854	BERUTI	6424	0	1
4855	CORAZZI	6405	0	1
4856	DUHAU	6405	0	1
4857	FRANCISCO DE VITORIA	6403	0	1
4858	FRANCISCO MAGNANO	6475	0	1
4859	GIRODIAS	6407	0	1
4860	LA CARRETA	6471	0	1
4861	LA MARGARITA	6471	0	1
4862	LA PORTE	6407	0	1
4863	LA ZANJA	6400	0	1
4864	LAGUNA REDONDA	6400	0	1
4865	LAS GUASQUITAS	6400	0	1
4866	LERTORA	6400	0	1
4867	MARI LAUQUEN	6400	0	1
4868	MARTIN FIERRO	6400	0	1
4869	PRIMERA JUNTA	6422	0	1
4870	SAN RAMON	6424	0	1
4871	SANTA INES	6471	0	1
4872	TRENQUE LAUQUEN	6400	0	1
4873	TRONGE	6407	0	1
4874	VILLA BRANDA	6471	0	1
4875	BALNEARIO OCEANO	7511	0	1
4876	BALNEARIO ORENSE	7511	0	1
4877	CLAUDIO C MOLINA	7515	0	1
4878	COPETONAS	7511	0	1
4879	EL BOMBERO	7507	0	1
4880	EL CARRETERO	7500	0	1
4881	EL TRIANGULO	7500	0	1
4882	ESTACION BARROW	7500	0	1
4883	EST SAN FRANCISCO BELLOQ	7505	0	1
4884	GENERAL VALDEZ	7503	0	1
4885	HUESO CLAVADO	7500	0	1
4886	LA HORQUETA	7500	0	1
4887	LA SORTIJA	7517	0	1
4888	LA TIGRA	7500	0	1
4889	LAS VAQUERIAS	7500	0	1
4890	LIN CALEL	7505	0	1
4891	MICAELA CASCALLARES	7507	0	1
4892	ORENSE	7503	0	1
4893	PASO DEL MEDANO	7511	0	1
4894	PIERINI	7517	0	1
4895	RETA	7511	0	1
4897	SAN FRANCISCO DE BELLOCQ	7505	0	1
4898	SAN MAYOL	7519	0	1
4899	TRES ARROYOS	7500	0	1
4900	VILLA CARUCHA	7505	0	1
4911	BAIGORRITA	6013	0	1
4912	CAMPO COLIQUEO	6015	0	1
4913	CAMPO LA TRIBU	6015	0	1
4914	CHANCAY	6017	0	1
4915	COLONIA LOS BOSQUES	6018	0	1
4916	COLONIA LOS HUESOS	6018	0	1
4917	COLONIA SAN FRANCISCO	6017	0	1
4918	EL RETIRO	6017	0	1
4919	GENERAL VIAMONTE	6015	0	1
4920	KILOMETRO 282	6017	0	1
4921	LA DELFINA	6017	0	1
4922	LA TRIBU	6015	0	1
4923	LOS BOSQUES	6018	0	1
4924	LOS HUESOS	6015	0	1
4925	LOS TOLDOS	6015	0	1
4926	QUIRNO COSTA	6018	0	1
4927	SAN EMILIO	6017	0	1
4928	SAN ROQUE	6017	0	1
4929	VILLA DELFINA	8000	0	1
4930	ZAVALIA	6018	0	1
4938	ARGERICH	8134	0	1
4939	BALNEARIO CHAPALCO	8132	0	1
4940	BALNEARIO SAN ANTONIO	8132	0	1
4941	CABEZA DE BUEY	8134	0	1
4942	COLONIA CUARENTA Y TRES	8136	0	1
4943	COLONIA LA MERCED	8105	0	1
4944	COLONIA MONTE LA PLATA	8144	0	1
4945	COLONIA LOS ALFALFARES	8132	0	1
4946	COLONIA OCAMPO	8134	0	1
4947	COLONIA PUEBLO RUSO	8144	0	1
4948	COLONIA SAN ENRIQUE	8132	0	1
4949	EL PARAISO	8144	0	1
4950	EL RINCON	8146	0	1
4951	FORTIN MERCEDES	8148	0	1
4953	HILARIO ASCASUBI	8142	1	1
4954	ISLA VERDE	8146	0	1
4955	JUAN COUSTE	8136	0	1
4956	KILOMETRO 697	8144	0	1
4957	LA BLANCA	8136	0	1
4958	LA CELIA	8144	0	1
4959	LA GLEVA	8134	0	1
4960	LA MASCOTA	8134	0	1
4961	LAGUNA CHASICO	8134	0	1
4962	LAS ESCOBAS	8134	0	1
4963	LAS ISLETAS	8148	0	1
4964	MAYOR BURATOVICH	8146	1	1
4965	MEDANOS	8132	1	1
4966	MONTES DE OCA	8136	0	1
4967	NICOLAS LEVALLE	8134	1	1
4968	OMBUCTA	8142	0	1
4969	PASO CRAMER	8134	0	1
4970	PEDRO LURO	8148	1	1
4971	PUERTO COLOMA	8142	0	1
4972	SALINAS CHICAS	8134	0	1
4973	SAN ADOLFO	8142	0	1
4974	TENIENTE ORIGONE	8144	0	1
4975	VILLA RIO CHICO	8146	0	1
4976	CORACEROS	6465	0	1
4977	EL TRIO	6467	0	1
4978	HENDERSON	6465	0	1
4979	HERRERA VEGAS	6557	0	1
4980	MARIA LUCILA	6467	0	1
4981	ALTO VERDE	2801	0	1
4982	ARROYO AGUILA NEGRA	2800	0	1
4983	ARROYO BOTIJA FALSA	2800	0	1
4984	ARROYO 	2800	0	1
4985	ARROYO NEGRO	2800	0	1
4986	ATUCHA	2808	0	1
4987	CANAL MARTIN IRIGOYEN	2800	0	1
4988	EL TATU	2801	0	1
4989	ESCALADA	2801	0	1
4990	FRIGORIFICO LAS PALMAS	2800	0	1
4991	LA PESQUERIA	2800	0	1
4992	LAS PALMAS	2806	0	1
4993	LIMA	2806	0	1
4994	VILLA ANGUS	2800	0	1
4995	VILLA CAPDEPONT	2800	0	1
4996	VILLA FLORIDA	2800	0	1
4997	VILLA FOX	2800	0	1
4998	VILLA MASSONI	2800	0	1
4999	VILLA MOSCONI	2800	0	1
5000	ZARATE	2800	0	1
5001	C.A.B.A.	0	0	2
5026	BASE AEREA TENIENTE MATIENZO	9411	0	23
5027	BASE AEREA VICECOMOD MARAMBIO	9411	0	23
5028	BASE EJERCITO ESPERANZA	9411	0	23
5029	BASE BELGRANO	9411	0	23
5030	BASE BELGRANO 3	9411	0	23
5031	BASE EJERCITO GRAL SAN MARTIN	9411	0	23
5032	BASE EJERCITO PRIMAVERA	9411	0	23
5033	BASE EJERCITO SOBRAL	9411	0	23
5034	DESTACAMENTO MELCHIOR	9411	0	23
5035	ESTACION CIENTIFICA ALTE BROWN	9411	0	23
5036	ISLA JOINVILLE	9411	0	23
5037	ISLA SHETLAND DEL SUR	9411	0	23
5038	ISLAS GEORGIAS DEL SUR	9411	0	23
5039	ISLAS ORCADAS DEL SUR	9411	0	23
5040	ISLA GRAN MALVINA	9409	0	23
5041	ISLA SOLEDAD	9409	0	23
5042	EL PARAMO	9420	0	23
5043	RIO GRANDE	9420	0	23
5044	SAN SEBASTIAN	9420	0	23
5045	SANTA INES	9420	0	23
5046	TOLHUIN	9420	0	23
5047	ISLA DE LOS ESTADOS	9410	0	23
5048	USHUAIA	9410	0	23
5049	9 DE ABRIL	1776	0	1
5051	EL JAGUEL	1842	0	1
5052	LUIS GUILLON	1838	0	1
5062	AGUADA DE GUERRA	8424	0	16
5063	AGUADA DE PIEDRA	8422	0	16
5065	ANECON CHICO	8418	0	16
5066	ANECON GRANDE	8416	0	16
5068	ATRAICO	8418	0	16
5069	BARRIL NIYEO	8422	0	16
5073	CALTRAUNA	8424	0	16
5075	CARRILAUQUEN	8418	0	16
5076	CERRO ABANICO	8424	0	16
5077	CHAIFUL	8418	0	16
5078	CHICHIHUAO	8422	0	16
5079	CLEMENTE ONELLI	8416	0	16
5080	COLI TORO	8418	0	16
5082	EL CAIN	8422	0	16
5083	EL CHEIFUL	8418	0	16
5085	EL MOLIGUE	8418	0	16
5087	EMPALME KILOMETRO 648	8418	0	16
5088	FITA RUIN	8418	0	16
5089	HUAN LUAN	8418	0	16
5090	INGENIERO JACOBACCI	8418	0	16
5091	INGENIERO ZIMMERMANN RESTA	8416	0	16
5092	LA ESPERANZA	8534	0	16
5093	LA RINCONADA	8424	0	16
5095	LAGUNITA	8424	0	16
5096	LENZANIYEN	8424	0	16
5097	LOMA BLANCA	8424	0	16
5099	LOS JUNCOS	8422	0	16
5100	LOS MANANTIALES	8422	0	16
5101	LOS MENUCOS	8424	0	16
5102	MANCULLIQUE	8422	0	16
5103	MAQUINCHAO	8422	0	16
5105	NILUAN	8422	0	16
5107	OJOS DE AGUA EMBARCADERO FCGB	8418	0	16
5108	PRAHUANIYEU	8424	0	16
5110	QUETREQUILE	8418	0	16
5113	RUCU LUAN	8422	0	16
5114	TROMENIYEU	8422	0	16
5115	VACA LAUQUEN	8422	0	16
5116	YUQUINCHE	8418	0	16
5117	COMI CO	8424	0	16
5118	CONA NIYEU	8521	0	16
5121	FALCKNER	8534	0	16
5122	GANZU LAUQUEN	8424	0	16
5123	YAMINUE	8534	0	16
5126	MINISTRO RAMOS MEXIA	8534	0	16
5128	SIERRA COLORADA	8534	0	16
5131	TRENETA	8534	0	16
5132	AGUADA DEL LORO	8520	0	16
5133	BALNEARIO EL CONDOR	8501	0	16
5136	CHINA MUERTA	8504	0	16
5138	EL DIQUE	8500	0	16
5139	GENERAL LIBORIO BERNAL	8500	0	16
5142	GUARDIA MITRE	8505	0	16
5144	LA LOBERIA	8501	0	16
5145	LA MESETA	8500	0	16
5146	LA PRIMAVERA	8520	0	16
5147	LAGUNA DEL BARRO	8514	0	16
5148	MATA NEGRA	8500	0	16
5150	NUEVO LEON	8514	0	16
5151	PLAYA BONITA	8400	0	16
5152	PRIMERA ANGOSTURA	8505	0	16
5155	SAN JAVIER	8501	0	16
5156	SAUCE BLANCO	8505	0	16
5158	VIEDMA	8500	0	16
5160	BAJO RICO	8360	0	16
5161	BENJAMIN ZORRILLA	8360	0	16
5164	CHELFORO	8366	0	16
5165	CHIMPAY	8364	0	16
5166	CHOELE CHOEL	8360	0	16
5167	COLONIA JOSEFA	8363	0	16
5168	CORONEL BELISLE	8364	0	16
5169	DARWIN	8364	0	16
5172	ESTANCIA LAS JULIAS	8363	0	16
5173	FORTIN UNO	8360	0	16
5174	ISLA CHICA	8363	0	16
5175	ISLA GRANDE	8361	0	16
5176	JAG	8520	0	16
5177	LA ELVIRA	8360	0	16
5180	LA JULIA	8363	0	16
5181	LA SARA	8360	0	16
5183	LAGUNA DE LA PRUEBA	8520	0	16
5184	LAMARQUE	8363	0	16
5185	LOS MOLINOS	8360	0	16
5186	LUIS BELTRAN	8361	0	16
5187	MARIA CRISTINA	8360	0	16
5189	NEGRO MUERTO	8360	0	16
5190	PASO LEZCANO	8361	0	16
5192	PASO PIEDRA	8360	0	16
5193	POMONA	8363	0	16
5194	PUESTO FARIA	8360	0	16
5195	RINCONADA	8360	0	16
5196	SALITRAL NEGRO	8363	0	16
5198	SANTA GENOVEVA	8363	0	16
5199	SANTA GREGORIA	8364	0	16
5201	SANTA NICOLASA	8364	0	16
5202	SAUCE BLANCO	8360	0	16
5203	6 DE OCTUBRE	8134	0	16
5207	COSTA DEL RIO AZUL	8430	0	16
5209	EL BOLSON	8430	0	16
5210	EL CONDOR ESTANCIA	8400	0	16
5211	EL FOYEL	8401	0	16
5212	EL MANSO	8430	0	16
5213	LAGUNA FRIAS	8411	0	16
5214	CASCADA LOS CANTAROS	8411	0	16
5215	LAGUNA LOS JUNCOS	8400	0	16
5216	LOS REPOLLOS	8430	0	16
5217	MALLIN AHOGADO	8430	0	16
5219	PUERTO BLEST	8411	0	16
5220	PUERTO OJO DE AGUA	8409	0	16
5223	PUERTO TIGRE ISLA VICTORIA	8400	0	16
5224	RIO VILLEGAS	8401	0	16
5225	SAN RAMON	8416	0	16
5226	VILLA MASCARDI	8401	0	16
5227	VILLA TURISMO	8430	0	16
5228	BOCA DE LA TRAVESIA	8505	0	16
5231	CHOCORI	8503	0	16
5232	COLONIA GENERAL FRIAS	8501	0	16
5233	COLONIA LA LUISA	8503	0	16
5234	COLONIA SAN JUAN	8503	0	16
5235	CORONEL FRANCISCO SOSA	8503	0	16
5236	EL PORVENIR	8503	0	16
5237	GENERAL CONESA	8503	0	16
5238	INGENIO SAN LORENZO	8503	0	16
5239	LA CAROLINA	8503	0	16
5240	LA FLECHA	8503	0	16
5241	LAGUNA CORTES	8520	0	16
5242	LUIS M ZAGAGLIA	8503	0	16
5243	NUEVA CAROLINA	8503	0	16
5244	PUESTO GAVI	8503	0	16
5245	RINCON DE GASTRE	8503	0	16
5246	SAN JUAN	8503	0	16
5247	SAN LORENZO	8503	0	16
5248	SAN SIMON	8503	0	16
5249	SEGUNDA ANGOSTURA	8501	0	16
5250	TRAVESIA CASTRO	8503	0	16
5251	TTE GRAL EUSTAQUIO FRIAS	8501	0	16
5252	AGUADA GUZMAN	8333	0	16
5253	ALANITOS	8333	0	16
5255	BARDA COLORADA	8333	0	16
5256	CANLLEQUIN	8417	0	16
5257	CARRI YEGUA	8417	0	16
5258	CERRO POLICIA	8333	0	16
5259	CHASICO	8417	0	16
5261	CURA LAUQUEN	8417	0	16
5262	EL CACIQUE	8417	0	16
5263	EL CAMARURO	8417	0	16
5264	EL GAUCHO POBRE	8417	0	16
5265	EL JARDINERO	8417	0	16
5266	HUA MICHE	8417	0	16
5267	JITA RUSIA	8417	0	16
5268	KILI MALAL	8417	0	16
5269	LA ANGOSTURA	8417	0	16
5270	LA CHILENA	8417	0	16
5271	LA CRIOLLITA	8417	0	16
5272	LA ESTRELLA	8417	0	16
5273	LA EXCURRA	8417	0	16
5274	LA MIMOSA	8417	0	16
5275	LA PORTE	8417	0	16
5276	LA RUBIA	8417	0	16
5277	LA VENCEDORA	8417	0	16
5278	LANQUI	8417	0	16
5279	LAS MELLIZAS	8417	0	16
5280	LONCO VACA	8417	0	16
5281	LOS COSTEROS	8417	0	16
5282	LOS PIRINEOS	8417	0	16
5283	LOS QUEBRACHOS	8417	0	16
5284	MENCUE	8417	0	16
5285	MICHIHUAO	8417	0	16
5286	MULANILLO	8417	0	16
5287	NAUPA HUEN	8313	0	16
5288	PALENQUE NIYEU	8417	0	16
5290	PILAHUE	8417	0	16
5291	PLANICIE DE JAGUELITO	8333	0	16
5292	QUEMPU NIYEU	8332	0	16
5294	SANTA ELENA	8417	0	16
5296	TRICACO	8332	0	16
5297	VALLE AZUL	8336	0	16
5299	AGUADA DE LOS PAJARITOS	8301	0	16
5300	AGUARA	8307	0	16
5301	ALLEN	8328	0	16
5303	BARDA DEL MEDIO	8305	0	16
5304	BARRIO NORTE	8328	0	16
5309	CATRIEL	8307	0	16
5310	CERVANTES	8326	0	16
5311	CHICHINALES	8326	0	16
5312	CINCO SALTOS	8303	0	16
5313	CIPOLLETTI	8324	0	16
5315	COLONIA ALTE GUERRICO	8307	0	16
5316	COLONIA EL MANZANO	8305	0	16
5318	COLONIA REGINA	8336	0	16
5319	COLONIA RUSA	8332	0	16
5320	CONTRALMIRANTE CORDERO	8301	0	16
5321	CONTRALMIRANTE M GUERRICO	8328	0	16
5322	CORONEL JUAN JOSE GOMEZ	8333	0	16
5323	CORONEL VIDAL	8305	0	16
5324	COS ZAURES	8307	0	16
5325	CUATRO ESQUINAS	8324	0	16
5326	CUENCA VIDAL	8301	0	16
5327	EL CUY	8333	0	16
5328	EL MANZANO	8328	0	16
5329	FERRI	8301	0	16
5331	GENERAL ENRIQUE GODOY	8336	0	16
5332	GENERAL FERNANDEZ ORO	8324	0	16
5333	GENERAL ROCA	8332	0	16
5334	INGENIERO HUERGO	8334	0	16
5337	IRIS	8324	0	16
5340	KILOMETRO 1218	8305	0	16
5341	LA ALIANZA	8324	0	16
5344	LA EMILIA	8324	0	16
5345	LA ESMERALDA	8324	0	16
5346	LA ESTANCIA VIEJA	8324	0	16
5348	LA LUCINDA	8324	0	16
5350	LAGO PELLEGRINI	8305	0	16
5352	LOS SAUCES	8307	0	16
5354	MAINQUE	8326	0	16
5356	PADRE ALEJANDRO STEFANELLI	8332	0	16
5357	PASO CORDOVA	8333	0	16
5358	PE	8307	0	16
5362	SAN JORGE	8324	0	16
5363	SARGENTO VIDAL	8305	0	16
5364	TERCERA ZONA	8336	0	16
5365	VALLE DE LOS ALAMOS	8307	0	16
5366	VILLA ALBERDI	8336	0	16
5367	VILLA REGINA	8336	0	16
5370	ARROYO LAS MINAS	8415	0	16
5373	CERRO MESA	8415	0	16
5374	CHACALHUA RUCA	8415	0	16
5375	CHACAY HUARRUCA	8415	0	16
5377	CHENQUENIYEU	8412	0	16
5379	CHURQUI	8412	0	16
5380	CORRAL DE LOS PINOS	8412	0	16
5381	EL PANTANOSO	8412	0	16
5382	FITALANCAO	8415	0	16
5383	FITAMICHE	8415	0	16
5384	FITATIMEN	8415	0	16
5386	LAS BAYAS	8412	0	16
5387	MAMUEL CHOIQUE	8415	0	16
5388		8415	0	16
5389	PORTEZUELO	8415	0	16
5391	REPOLLOS	8415	0	16
5392	RIO CHICO	8415	0	16
5397	CORONEL EUGENIO DEL BUSTO	8138	0	16
5401	JUAN DE GARAY	8138	0	16
5403	LA ADELA	8138	0	16
5410	LA MARIA INES	8138	0	16
5415	PICHI MAHUIDA	8138	0	16
5416	RIO COLORADO	8138	0	16
5419	SAN LEON	8138	0	16
5422	ARROYO BLANCO	8403	0	16
5423	ARROYO CHACAY	8401	0	16
5424	CA	8416	0	16
5425	CA	8417	0	16
5426	CA	8412	0	16
5427	CARHUE	8412	0	16
5428	CASA QUEMADA	8412	0	16
5429	CERRO ALTO	8403	0	16
5430	COMALLO	8416	0	16
5431	COMALLO ABAJO	8416	0	16
5432	COQUELEN	8416	0	16
5433	CORRALITO	8403	0	16
5434	COSTAS DEL PICHI LEUFU	8412	0	16
5435	DINA HUAPI	8402	0	16
5436	LA QUEBRADA	8412	0	16
5437	MENUCO VACA MUERTA	8412	0	16
5438	NENEO RUCA	8416	0	16
5439		8400	0	16
5440	PANQUEHUAO	8412	0	16
5441	PASO CHACABUCO	8401	0	16
5442	PASO DE LOS MOLLES	8412	0	16
5443	PASO DEL LIMAY	8403	0	16
5444	PASO FLORES	8403	0	16
5445	PASO MIRANDA	8403	0	16
5446	PERITO MORENO	8416	0	16
5447	PERITO MORENO ESTACION FCGR	8400	0	16
5448	PICHI LEUFU	8412	0	16
5449	PICHI LEUFU ABAJO	8412	0	16
5450	PICHI LEUFU ARRIBA	8412	0	16
5451	PILCANIYEU	8412	0	16
5452	PILQUINIYEU DEL LIMAY	8412	0	16
5453	PILQUINIYEU	8416	0	16
5454	QUINTA PANAL	8416	0	16
5455	RAYHUAO	8412	0	16
5456	SAN PEDRO	8412	0	16
5457	TRES OJOS DE AGUAS	8416	0	16
5458	VILLA LLANQUIN	8401	0	16
5459	ARROYO SALADO	8532	0	16
5460	ARROYO VERDE	8521	0	16
5461	BAJO DEL GUALICHO	8520	0	16
5462	BALNEARIO LAS GRUTAS	8521	0	16
5463	CINCO CHA	8520	0	16
5465	LA BOMBILLA	8520	0	16
5466	LAGUNA DEL MONTE	8514	0	16
5467	PERCY H SCOTT	8520	0	16
5468	POZO SALADO	8514	0	16
5469	PUERTO SAN ANTONIO ESTE	8521	0	16
5470	SACO VIEJO	8514	0	16
5471	SAN ANTONIO OESTE	8520	0	16
5472	SIERRA GRANDE	8532	0	16
5473	AGUADA CECILIO	8534	0	16
5474	ARROYO DE LA VENTANA	8521	0	16
5475	ARROYO LOS BERROS	8521	0	16
5476	ARROYO TEMBRADO	8521	0	16
5478	CAMPANA MAHUIDA	8532	0	16
5480	CHIPAUQUIL	8536	0	16
5481	EL SALADO	8536	0	16
5484	MUSTERS	8536	0	16
5485	NAHUEL NIYEU	8536	0	16
5486	PAJA ALTA	8536	0	16
5488	PUNTA DE AGUA	8536	0	16
5490	SIERRA DE LA VENTANA	8521	0	16
5491	SIERRA PAILEMAN	8521	0	16
5492	TENIENTE MAZA ESTACION FCGR	8534	0	16
5493	VALCHETA	8536	0	16
5494	VILLA MANZANO	8308	0	16
5495	MENDOZA	5500	0	13
5496	GODOY CRUZ	5501	0	13
5497	SAN FRANCISCO DEL MONTE	5503	0	13
5498	CANALEJAS	5636	0	13
5499	BOWEN	5634	0	13
5500	CARMENSA	5621	0	13
5501	CERRO NEVADO	5621	0	13
5502	COCHICO	5621	0	13
5503	COLONIA ALVEAR	5632	0	13
5504	COLONIA ALVEAR OESTE	5632	0	13
5505	COLONIA BOUQUET	5632	0	13
5506	COSTA DEL DIAMANTE	5637	0	13
5507	EL ARBOLITO	5636	0	13
5508	EL BANDERON	5634	0	13
5509	EL CEIBO	5621	0	13
5510	EL JUNCALITO	5620	0	13
5511	EL NEVADO	5620	0	13
5512	EL RETIRO	5632	0	13
5513	GASPAR CAMPOS	5609	0	13
5514	GENERAL ALVEAR	5620	0	13
5515	GOICO	5609	0	13
5516	JAIME PRATS	5623	0	13
5517	KILOMETRO 56	5620	0	13
5518	KILOMETRO 882	5620	0	13
5519	KILOMETRO 884	5634	0	13
5520	LA ADELINA	5634	0	13
5521	LA ESCANDINAVA	5634	0	13
5522	LA MARZOLINA	5632	0	13
5523	LA MONTILLA	5634	0	13
5524	LA MORA	5636	0	13
5525	LA POMONA	5620	0	13
5526	LA VARITA	5634	0	13
5527	LOS ANGELES	5634	0	13
5528	LOS CAMPAMENTOS	5634	0	13
5529	LOS COMPARTOS	5621	0	13
5530	MEDIA LUNA	6279	0	13
5531	OVEJERIA	5637	0	13
5532	PAMPA DEL TIGRE	5637	0	13
5533	POSTE DE FIERRO	5621	0	13
5534	PUEBLO LUNA	5632	0	13
5535	SAN PEDRO DEL ATUEL	5621	0	13
5536	TAMBITO	5621	0	13
5537	VILLA COMPARTO	5620	0	13
5538	ALTO DEL SALVADOR	5570	0	13
5539	BARRIO VILLA ADELA	5584	0	13
5540	BUEN ORDEN	5570	0	13
5541	CARRIL NORTE	5582	0	13
5542	CHAPANAY	5589	0	13
5543	CHIVILCOY	5571	0	13
5544	COLONIA LAMBARE	5571	0	13
5545	COLONIA REINA	5584	0	13
5546	EL ALTO SALVADOR	5571	0	13
5547	EL CENTRAL	5589	0	13
5548	EL DIVISADERO	5589	0	13
5549	EL 	5589	0	13
5550	ESPINO	5571	0	13
5551	GURRUCHAGA	5584	0	13
5552	LA CHIMBA	5589	0	13
5553	LA PASTORAL	5582	0	13
5554	LAS COLONIAS	5571	0	13
5555	LOS OLMOS	5571	0	13
5556	MONTE CASEROS	5571	0	13
5557	PALMIRA	5584	0	13
5558	REINA	5584	0	13
5559	REYES	5589	0	13
5561	TRES PORTE	5589	0	13
5562	VILLA CENTENARIO	5570	0	13
5563	VILLA DEL CARMEN	5570	0	13
5564	COMPUERTAS NEGRAS	5632	0	13
5565	CORRAL DE LORCA	5637	0	13
5566	CHIMBA	5584	0	13
5567	LOS EUCALIPTOS	5582	0	13
5569	BERMEJO	5533	0	13
5570	BUENA NUEVA	5523	0	13
5571	BUENA VISTA	5525	0	13
5572	CA	5519	0	13
5573	CANAL PESCARA	5525	0	13
5574	CAPILLA DEL ROSARIO	5523	0	13
5575	DORREGO	5519	0	13
5576	EL SAUCE	5533	0	13
5577	JESUS NAZARENO	5523	0	13
5578	PRIMAVERA	5525	0	13
5579	RODEO DE LA CRUZ	5525	0	13
5580	VILLA LOS CORRALITOS	5527	0	13
5581	VILLA NUEVA DE GUAYMALLEN	5521	0	13
5582	COLONIA SANTA TERESA	5527	0	13
5583	COLONIA SEGOVIA	5525	0	13
5584	LA PRIMAVERA	5527	0	13
5585	LIMON	5533	0	13
5586	LOS CORREDORES	5521	0	13
5587	NUEVA localidades	5519	0	13
5588	PARADERO LA SUPERIORA	5525	0	13
5589	VERGEL	5527	0	13
5590	VILLA SUAVA	5523	0	13
5591	VILLAS UNIDAS 25 DE MAYO	5519	0	13
5593	ALGARROBO GRANDE	5582	0	13
5594	ALTO GRANDE	5572	0	13
5595	ALTO VERDE	5582	0	13
5597	JUNIN	5573	0	13
5598	COLONIA DELFINO	5573	0	13
5599	EL CIPRES	5585	0	13
5600	EL MOYANO	5573	0	13
5601	INGENIERO GIAGNONI	5582	0	13
5602	JORGE NEWBERY	5585	0	13
5603	LA COLONIA	5570	0	13
5604	LA ISLA	5585	0	13
5605	LA ISLA CHICA	5585	0	13
5606	LA ISLA GRANDE	5585	0	13
5607	LOS BARRIALES	5585	0	13
5608	LOS OTOYANES	5579	0	13
5609	PUESTO LA COSTA	5582	0	13
5610	RAMBLON	5582	0	13
5611	RETAMO	5582	0	13
5612	RICARDO VIDELA	5582	0	13
5613	ROBERTS	5582	0	13
5614	RODRIGUEZ PE	5585	0	13
5615	TRES ACEQUIAS	5585	0	13
5616	VILLA MOLINO ORFILA	5571	0	13
5617	ALPATACAL	5591	0	13
5618	CADETES DE CHILE	5590	0	13
5619	CIRCUNVALACION	5591	0	13
5620	CORRAL DEL MOLLE	5590	0	13
5621	DELGADILLO	5590	0	13
5622	DESAGUADERO	5598	0	13
5623	EL CONSUELO	5590	0	13
5624	KILOMETRO 935 DESVIO FCGSM	5590	0	13
5625	LA CORTADERA	5590	0	13
5626	LA PAZ	5590	0	13
5627	LA PRIMAVERA	5590	0	13
5628	LAS VISCACHERAS	5590	0	13
5629	LOS ALGARROBOS	5590	0	13
5630	MAQUINISTA LEVET	5590	0	13
5631	PAMPITA EMBARCADERO FCGSM	5598	0	13
5632	PIRQUITA EMBARCADERO FCGSM	5590	0	13
5633	PUERTA DE LA ISLA	5590	0	13
5634	RETAMO	5590	0	13
5635	SOPANTA	5591	0	13
5636	TAPON	5598	0	13
5637	VILLA ANTIGUA	5590	0	13
5638	VILLA LA PAZ	5591	0	13
5639	VILLA VIEJA	5590	0	13
5640	ALGARROBAL ABAJO	5541	0	13
5641	ALGARROBAL ARRIBA	5541	0	13
5642	CAPDEVILLE	5543	0	13
5643	COLONIA ALEMANA	5543	0	13
5644	COLONIA 3 DE MAYO	5543	0	13
5645	CRISTO REDENTOR	5557	0	13
5646	EL CA	5543	0	13
5647	EL CHALLAO	5539	0	13
5648	EL PASTAL	5541	0	13
5649	EL PLUMERILLO	5541	0	13
5650	EL RESGUARDO	5543	0	13
5651	EMPALME FRONTERA	5553	0	13
5652	EMPALME RESGUARDO	5539	0	13
5653	ESPEJO	5539	0	13
5654	ESPEJO RESGUARDADO	5539	0	13
5655	ESTACION USPALLATA	5551	0	13
5656	GOBERNADOR BENEGAS	5544	0	13
5657	GUIDO	5549	0	13
5658	HORNITO DEL GRINGO	5543	0	13
5659	HORNOS DE MOYANO	5543	0	13
5660	JOCOLI	5543	0	13
5661	LA PIRATA	5553	0	13
5662	LAS CUEVAS	5557	0	13
5663	LAS HERAS	5539	0	13
5664	LOS PENITENTES	5553	0	13
5665	LOS TAMARINDOS	5539	0	13
5666	MATHEU NORTE	5543	0	13
5667	PANQUEHUA	5539	0	13
5668	PASO HONDO	5541	0	13
5669	PORTILLO AGUA DE TORO	5545	0	13
5670	PUENTE DEL INCA	5555	0	13
5671	PUESTO ISLA CHA	5435	0	13
5672	PUESTO LOS CHA	5435	0	13
5673	PUNTA DE VACAS	5553	0	13
5674	RIO BLANCO	5553	0	13
5675	SAN ALBERTO	5545	0	13
5676	SANCHEZ DE BUSTAMANTE	5539	0	13
5677	TERMAS VILLAVICENCIO	5545	0	13
5678	TROPERO SOSA	5539	0	13
5679	TTE BENJAMIN MATIENZO	5539	0	13
5680	USPALLATA	5545	0	13
5681	VILLA HIPODROMO	5547	0	13
5682	ZANJON AMARILLO	5553	0	13
5683	9 DE JULIO	5533	0	13
5684	ALTO DEL OLVIDO	5533	0	13
5685	ARROYITO	5537	0	13
5686	ASUNCION	5535	0	13
5687	BAJADA ARAUJO	5535	0	13
5688	COLONIA ANDRE	5535	0	13
5689	COLONIA DEL CARMEN	5535	0	13
5690	COLONIA ITALIANA	5533	0	13
5691	COSTA DE ARAUJO	5535	0	13
5692	EL ALPERO	5535	0	13
5693	EL CHIRCAL	5533	0	13
5694	EL GUANACO	5537	0	13
5695	EL RETAMO	5537	0	13
5696	EL RETIRO	5533	0	13
5697	EL ROSARIO	5535	0	13
5698	EL VERGEL	5533	0	13
5699	GENERAL ACHA	5533	0	13
5700	GOBERNADOR LUIS MOLINA	5533	0	13
5701	INGENIERO GUSTAVO ANDRE	5535	0	13
5702	JOCOLI VIEJO	5533	0	13
5703	KILOMETRO 1013	5535	0	13
5704	KILOMETRO 1032	5535	0	13
5705	KILOMETRO 43	5535	0	13
5706	LA BAJADA	5535	0	13
5707	LA CELIA	5535	0	13
5708	LA PALMERA	5533	0	13
5709	LA PEGA	5533	0	13
5710	LAGUNA DEL ROSARIO	5535	0	13
5711	LAS DELICIAS	5533	0	13
5712	LAVALLE VILLA TULUMAYA	5533	0	13
5713	LOS BALDES	5537	0	13
5714	LOS BLANCOS	5537	0	13
5715	LOS RALOS	5537	0	13
5716	MOLUCHES	5535	0	13
5717	PARAMILLO	5533	0	13
5718	PROGRESO	5535	0	13
5719	RESURRECCION	5535	0	13
5720	SAN JOSE	5535	0	13
5721	SAN MIGUEL	5537	0	13
5722	SANTA MARTA	5533	0	13
5723	3 DE MAYO	5543	0	13
5725	CARBOMETAL	5505	0	13
5726	CARRODILLA LA PUNTILLA	5505	0	13
5727	CHACRAS DE CORIA	5505	0	13
5728	EL REFUGIO	5634	0	13
5730	AGRELO	5509	0	13
5731	AGUA DE LOS MANANTIALES	5549	0	13
5732	ALTO DE LOS MANANTIALES	5549	0	13
5734	ALVAREZ CONDARCO	5549	0	13
5735	BA	5507	0	13
5736	BLANCO ENCALADA	5549	0	13
5737	CACHEUTA	5549	0	13
5738	CALLE TERRADA	5507	0	13
5739	CAMPAMENTO CACHEUTA YPF	5549	0	13
5740	CARLOS SUBERCASEUX	5549	0	13
5741	CARRIZAL DE ARRIBA	5509	0	13
5742	CARRIZAL DE ABAJO	5509	0	13
5743	CASA DE PIEDRA	5549	0	13
5744	CERRILLOS	5509	0	13
5745	CERRILLOS AL NORTE	5509	0	13
5746	COLONIA BARRAQUERO	5509	0	13
5747	COLONIA CANO	5507	0	13
5748	CONCHA SUBERCASEAUX	5549	0	13
5749	DISTRITO COMPUERTA	5507	0	13
5750	EL ALTILLO	5549	0	13
5751	EL CARRIZAL	5509	0	13
5752	KILOMETRO 1085	5549	0	13
5753	KILOMETRO 55	5549	0	13
5754	LAS CHACRITAS	5549	0	13
5755	LAS COMPUERTAS	5549	0	13
5756	LAS VEGAS	5613	0	13
5757	LOS PAPAGAYOS	5549	0	13
5758	LOTES DE GAVIOLA	5507	0	13
5759	LUJAN DE CUYO	5507	0	13
5760	MAYOR DRUMMOND	5507	0	13
5761	MINAS DE PETROLEO	5509	0	13
5762	PASO DE LOS ANDES	5503	0	13
5763	PERDRIEL	5509	0	13
5764	PETROLEO	5549	0	13
5765	POTRERILLOS	5549	0	13
5766	SAN IGNACIO	5549	0	13
5767	UGARTECHE	5509	0	13
5768	VILLA GAVIOLA	5507	0	13
5769	VISTALBA	5509	0	13
5770	BARRIO JARDIN LUZURIAGA	5513	0	13
5771	BARCALA	5587	0	13
5772	LAS BARRANCAS	5517	0	13
5773	BARRIO FERRI	5531	0	13
5774	BARRIO SAN EDUARDO	5513	0	13
5775	CARTELLONE	5531	0	13
5776	CESPEDES	5517	0	13
5777	CHACHINGO	5517	0	13
5778	COLONIA BOMBAL	5529	0	13
5779	COLONIA JARA	5529	0	13
5780	COQUIMBITO	5513	0	13
5781	CRUZ DE PIEDRA	5517	0	13
5782	EL ALTILLO	5531	0	13
5783	EL PARAISO	5531	0	13
5784	FINCA EL ARROZ	5531	0	13
5785	FRAY LUIS BELTRAN	5531	0	13
5786	GENERAL GUTIERREZ	5511	0	13
5787	GENERAL ORTEGA	5517	0	13
5788	ISLA CHICA	5587	0	13
5789	ISLA GRANDE	5587	0	13
5790	LA JAULA	5517	0	13
5791	LOS ALAMOS	5531	0	13
5792	LUNLUNTA	5517	0	13
5793	LUZURIAGA	5513	0	13
5794	MAIPU	5515	0	13
5795	MARQUEZ ESCUELA117	5517	0	13
5796	MAZA	5517	0	13
5797	PEDREGAL	5529	0	13
5798	RODEO DEL MEDIO	5529	0	13
5799	RUSSELL	5517	0	13
5800	SAN ROQUE	5587	0	13
5801	SANTA BLANCA	5531	0	13
5802	SARMIENTO	5513	0	13
5803	TERESA B DE TITTARELLI	5589	0	13
5804	VALLE HERMOSO	5587	0	13
5805	VILLA SECA	5517	0	13
5806	AGUA AMARGA	5563	0	13
5807	AGUA ESCONDIDA	5621	0	13
5808	AGUA DEL TORO	5621	0	13
5809	BARDAS BLANCAS	5611	0	13
5810	BELTRAN	5613	0	13
5811	CAJON GRANDE	5613	0	13
5812	CALMUCO	5611	0	13
5813	CAMPAMENTO RANQUILCO	5613	0	13
5814	CA	5613	0	13
5815	CA	5613	0	13
5816	COIHUECO	5611	0	13
5817	CORONEL BELTRAN	5613	0	13
5818	EL ALAMBRADO	5611	0	13
5819	EL AZUFRE	5621	0	13
5820	EL CHACAY	5613	0	13
5821	EL CHOIQUE	5613	0	13
5822	EL MANZANO	5611	0	13
5823	EL SOSNEADO	5611	0	13
5824	LA BATRA	5613	0	13
5825	LAS CHACRAS	5613	0	13
5826	LAS JUNTAS	5613	0	13
5827	LOS MOLLES	5611	0	13
5828	MALARGUE	5613	0	13
5829	MECHENGUIL	5613	0	13
5830	MINACAR	5613	0	13
5831	PAMPA AMARILLA	5613	0	13
5832	PATIMALAL	5613	0	13
5833	RANCHITOS	5613	0	13
5834	RANQUIL NORTE	5611	0	13
5835	RANQUILCO POZOS PETROLIFEROS	5613	0	13
5836	RIO BARRANCAS	5613	0	13
5837	RIO CHICO	5613	0	13
5838	RIO GRANDE	5613	0	13
5839	ANDRADE	5575	0	13
5840	BARRIO LENCINA	5579	0	13
5841	BARRIO RIVADAVIA	5579	0	13
5842	LOS CAMPAMENTOS	5579	0	13
5843	EL ALTO	5577	0	13
5844	EL MIRADOR	5579	0	13
5845	EL RETIRO	5579	0	13
5846	LA CENTRAL RIVADAVIA	5579	0	13
5847	LA FLORIDA	5579	0	13
5848	LA LIBERTAD	5579	0	13
5849	LA SIRENA	5579	0	13
5850	LA VERDE	5577	0	13
5851	LOS ARBOLES	5575	0	13
5853	MEDRANO	5585	0	13
5854	MINELLI	5579	0	13
5855	MUNDO NUEVO	5579	0	13
5856	PACHANGO	5579	0	13
5857	PHILLIPS	5579	0	13
5858	REDUCCION	5579	0	13
5859	RIVADAVIA	5577	0	13
5860	SANTA MARIA DE ORO	5579	0	13
5861	VILLA RIVADAVIA	5577	0	13
5862	VILLA SAN ISIDRO	5577	0	13
5863	AGUADA	5569	0	13
5864	CAPIZ	5560	0	13
5865	CHILECITO	5569	0	13
5866	EL CAPACHO	5569	0	13
5867	EUGENIO BUSTOS	5569	0	13
5868	LA CA	5567	0	13
5869	LA CONSULTA	5567	0	13
5870	LA FLORIDA	5569	0	13
5871	LAS VIOLETAS	5569	0	13
5872	PAPAGAYO	5569	0	13
5873	PAREDITAS	5569	0	13
5874	PIEDRAS BLANCAS	5569	0	13
5875	PUESTO QUEMADO	5435	0	13
5876	SAN CARLOS	5569	0	13
5877	TIERRAS BLANCAS	5569	0	13
5878	TRES BANDERAS	5517	0	13
5879	TRES ESQUINAS	5569	0	13
5880	ALTO VERDE	5582	0	13
5881	SAN MARTIN	5570	0	13
5882	NUEVA CALIFORNIA	5535	0	13
5883	RUTA 7 KILOMETRO 1014	5582	0	13
5884	ARISTIDES VILLANUEVA	5609	0	13
5885	ATUEL SUD	5623	0	13
5886	BALDE EL SOSNEADO	5611	0	13
5887	CALLE LARGA VIEJA	5605	0	13
5888	CA	5611	0	13
5889	CA	5603	0	13
5890	CAPITAN MONTOYA	5601	0	13
5891	CERRO ALQUITRAN	5611	0	13
5892	COLONIA ATUEL NORTE	5605	0	13
5893	COLONIA BOMBAL Y TABANERA	5607	0	13
5894	COLONIA COLOMER	5603	0	13
5895	COLONIA ELENA	5603	0	13
5896	COLONIA ESPA	5607	0	13
5897	COLONIA JAUREGUI	5622	0	13
5898	COLONIA LOPEZ	5622	0	13
5899	COLONIA PASCUAL IACARINI	5615	0	13
5900	COLONIA RUSA	5603	0	13
5901	CUADRO BENEGAS	5603	0	13
5902	CUADRO BOMBAL	5607	0	13
5903	CUADRO NACIONAL	5607	0	13
5904	EL ALGARROBAL	5541	0	13
5905	EL ALGARROBAL	5607	0	13
5906	EL BORBOLLON	5541	0	13
5907	EL CAMPAMENTO	5609	0	13
5908	EL CERRITO	5600	0	13
5909	EL NIHUIL	5605	0	13
5910	EL PORVENIR	5603	0	13
5911	EL TROPEZON	5603	0	13
5912	EL USILLAL	5601	0	13
5913	FINCA LOPEZ	5622	0	13
5914	GOUDGE	5603	0	13
5915	GUADALES	5609	0	13
5916	IGUAZU	5601	0	13
5917	INGENIERO BALLOFFET	5603	0	13
5918	KILOMETRO 47	5624	0	13
5919	LA CHILCA	5595	0	13
5920	LA GUEVARINA	5622	0	13
5921	LA LLAVE	5603	0	13
5922	LA LLAVE VIEJA	5603	0	13
5923	LA PICHANA	5600	0	13
5924	LA QUEBRADA	5622	0	13
5925	LA VASCONIA	5623	0	13
5926	LAS MALVINAS	5605	0	13
5927	LAS PAREDES	5601	0	13
5928	LOS BRITOS	5611	0	13
5929	LOS EMBARQUES	5595	0	13
5930	LOS HUARPES	5636	0	13
5931	LOS PARLAMENTOS	5611	0	13
5932	LOS PEJES	5603	0	13
5933	LOS REYUNOS	5615	0	13
5934	LOS TERNEROS	5600	0	13
5935	MINAS DEL NEVADO	5605	0	13
5936	MONTE COMAN	5609	0	13
5937		5595	0	13
5938	PALERMO CHICO	5624	0	13
5939	PEDRO VARGAS	5603	0	13
5940	PIEDRA DE AFILAR	5615	0	13
5941	PUEBLO DIAMANTE	5600	0	13
5942	PUEBLO ECHEVARRIETA	5603	0	13
5943	PUEBLO SOTO	5600	0	13
5944	PUNTA DEL AGUA	5621	0	13
5945	RAMA CAIDA	5603	0	13
5946	REAL DEL PADRE	5624	0	13
5947	RESOLANA	5601	0	13
5948	RINCON DEL ATUEL	5603	0	13
5949	RODOLFO ISELIN	5603	0	13
5950	SALINAS EL DIAMANTE	5605	0	13
5951	SALTO DE LAS ROSAS	5603	0	13
5952	SAN RAFAEL	5600	0	13
5953	SANTA TERESA	5605	0	13
5954	SOITUE	5632	0	13
5955	TABANERA	5607	0	13
5956	25 DE MAYO	5615	0	13
5957	VILLA ATUEL	5622	0	13
5958	12 DE OCTUBRE	5596	0	13
5959	BALDE DE PIEDRA	5596	0	13
5960	CATITAS VIEJAS	5594	0	13
5961	COMANDANTE SALAS	5594	0	13
5962	EL COLORADO	5592	0	13
5964	EL RETIRO	5594	0	13
5965	EL VILLEGUINO	5594	0	13
5966	GOBERNADOR CIVIT	5594	0	13
5967	LA COLONIA SUD	5594	0	13
5968	LA COSTA	5596	0	13
5969	LA DORMIDA	5592	0	13
5970	LAS CATITAS	5594	0	13
5971	PICHI CIEGO ESTACION FCGSM	5594	0	13
5972	RECOARO	5596	0	13
5973	SANTA ROSA	5596	0	13
5974	VILLA CATALA	5596	0	13
5975	ARROYO CLARO	5560	0	13
5976	ARROYO LOS SAUCES	5563	0	13
5977	CAMPO DE LOS ANDES	5565	0	13
5978	COLONIA LAS ROSAS	5565	0	13
5979	COLONIA TABANERA	5560	0	13
5980	ESTANCIA LA PAMPA	5563	0	13
5981	LA ESTACADA	5560	0	13
5982	LA PRIMAVERA	5565	0	13
5983	LAS ROSAS	5560	0	13
5984	LAS TORRECITAS	5560	0	13
5985	LOS ARBOLES	5563	0	13
5986	LOS SAUCES	5563	0	13
5987	LOS SAUCES LAVALLE	5560	0	13
5988	MELOCOTON	5565	0	13
5989	RUIZ HUIDOBRO	5560	0	13
5990	SAN PABLO	5563	0	13
5991	TOTORAL	5560	0	13
5992	TUNUYAN	5560	0	13
5993	VILLA SECA DE TUNUYAN	5563	0	13
5994	VISTA FLORES	5565	0	13
5995	ANCHORIS	5509	0	13
5996	ANCON	5561	0	13
5997	ARBOLEDA	5561	0	13
5998	CORDON DEL PLATA	5561	0	13
5999	EL PERAL	5561	0	13
6000	LA CARRERA	5561	0	13
6001	SAN JOSE DE GUAYMALLEN	5519	0	13
6002	SAN JOSE DE TUPUNGATO	5561	0	13
6003	TUPUNGATO	5561	0	13
6004	VILLA BASTIAS	5561	0	13
6005	ZAPATA	5560	0	13
6688	ATREUCO	6305	0	11
6689	BELLA VISTA	6305	0	11
6690	CEREALES	6301	0	11
6691	COLONIA AGUIRRE	6301	0	11
6692	COLONIA GUIBURG N 2	6305	0	11
6693	COLONIA LA ORACION	6307	0	11
6694	COLONIA MARIA LUISA	6301	0	11
6695	COLONIA SAN VICTORIO	6301	0	11
6696	COLONIA SOBADELL	6301	0	11
6697	DOBLAS	6305	0	11
6698	EL CENTENARIO	6307	0	11
6699	EL DESLINDE	6305	0	11
6700	EL DESTINO  ROLON	6305	0	11
6701	EL PALOMAR	6305	0	11
6702	HIDALGO	6307	0	11
6703	HIPOLITO YRIGOYEN	6305	0	11
6704	LA ANTONIA	6307	0	11
6705	LA ARA	6301	0	11
6706	LA BILBAINA	6345	0	11
6707	LA CATALINITA	6305	0	11
6708	LA DOLORES	6301	0	11
6709	LA ESMERALDA MACACHIN	6307	0	11
6710	LA ESPERANZA HIDALGO	6305	0	11
6711	LA ESPERANZA MACACHIN	6307	0	11
6712	LA JOSEFINA	6307	0	11
6713	LA MANUELITA	6305	0	11
6714	LA NUEVA PROVINCIA	6305	0	11
6715	LA ORACION	6307	0	11
6716	LA PAMPITA HIDALGO	6305	0	11
6717	LA PRIMAVERA MIGUEL RIGLOS	6301	0	11
6718	LA SARITA	6305	0	11
6719	LAS FELICITAS	6305	0	11
6720	LOS DOS HERMANOS	6305	0	11
6721	LOS QUINIENTOS	6301	0	11
6722	MACACHIN	6307	0	11
6723	MIGUEL RIGLOS	6301	0	11
6724	OJO DE AGUA	6305	0	11
6725	ROLON	6305	0	11
6726	SALINAS GRANDES HIDALGO	6305	0	11
6727	SAN FELIPE	6305	0	11
6728	SAN PEDRO ROLON	6305	0	11
6729	SANTO TOMAS	6307	0	11
6730	TOMAS M DE ANCHORENA	6301	0	11
6731	TRES HERMANOS MACACHIN	6307	0	11
6732	VALLE ARGENTINO	6307	0	11
6733	ANZOATEGUI	8138	0	11
6734	BALO LOS MORROS	8138	0	11
6735	CALEU CALEU	8138	0	11
6736	COLONIA SAN ROSARIO	8208	0	11
6737	EL AGUILA	8138	0	11
6738	GAVIOTAS	8138	0	11
6739	LA ADELA	8138	0	11
6740	SALINAS GRANDES  ANZOATEGUI	8138	0	11
6741	ANGUIL	6326	0	11
6742	BARRANCAS COLORADAS	6300	0	11
6743	COLONIA ECHETA	6301	0	11
6744	COLONIA LAGOS	6300	0	11
6745	COLONIA TORELLO	6326	0	11
6746	EL GUANACO	6313	0	11
6747	EL MIRADOR DE JUAREZ	6300	0	11
6748	EL OASIS	6300	0	11
6749	INES Y CARLOTA	6315	0	11
6750	LA CAROLA	6326	0	11
6751	LA CONSTANCIA  ANGUIL	6326	0	11
6752	LA ELVIRA	6326	0	11
6753	LA ESPERANZA ANGUIL	6326	0	11
6754	LA FLORIDA	6326	0	11
6755	LA JUANITA	6300	0	11
6756	LA PRIMAVERA SANTA ROSA	6300	0	11
6757	LA RESERVA ANGUIL	6326	0	11
6758	LA VERDE ANGUIL	6326	0	11
6759	LAS MALVINAS	6300	0	11
6760	LOS NOGALES	6300	0	11
6761	MEDANO BLANCO	6300	0	11
6762	SAN CARLOS	6326	0	11
6763	SAN JOSE  ANGUIL	6326	0	11
6764	SANTA ROSA	6300	0	11
6765	CAMPO LUDUE	6330	0	11
6766	CATRILO	6330	0	11
6767	CAYUPAN	6330	0	11
6768	COLONIA LA INDIA	6352	0	11
6769	COLONIA SAN MIGUEL	6352	0	11
6770	EL BRILLANTE	6352	0	11
6771	EL DESCANSO  LONQUIMAY	6352	0	11
6772	EL GUAICURU	6352	0	11
6773	EL MALACATE	6341	0	11
6774	EL RUBI	6352	0	11
6775	EL SALITRAL	6352	0	11
6776	EL TRIUNFO	6352	0	11
6777	IVANOWSKY	6330	0	11
6778	LA ATALAYA	6352	0	11
6779	LA BLANCA	6330	0	11
6780	LA CARMEN	6354	0	11
6781	LA CATALINA	6354	0	11
6782	LA CELIA	6352	0	11
6783	LA CUMBRE	6354	0	11
6784	LA ESMERALDA	6352	0	11
6785	LA GAVIOTA	6354	0	11
6786	LA GLORIA	6348	0	11
6787	LA LE	6330	0	11
6788	LA LUISA	6354	0	11
6789	LA MARIANITA	6354	0	11
6790	LA MATILDE	6341	0	11
6791	LA PAZ	6352	0	11
6792	LA PERLA	6352	0	11
6793	LA PERLITA	6352	0	11
6794	LA PUNA	6330	0	11
6795	LA REBECA	6330	0	11
6796	LA RESERVA IVANOWSKY	6341	0	11
6797	LA SEGUNDA	6352	0	11
6798	LA SUERTE	6354	0	11
6799	LA TRINIDAD	6354	0	11
6800	LA UNIDA	6330	0	11
6801	LA VICTORIA	6354	0	11
6802	LA VIOLETA	6352	0	11
6803	LAS GAVIOTAS	6354	0	11
6804	LONQUIMAY	6352	0	11
6805	PUEBLO QUINTANA	6352	0	11
6806	QUINTANA	6352	0	11
6807	SAN ANDRES	6354	0	11
6808	SAN EDUARDO	6330	0	11
6809	SAN JOSE	6354	0	11
6810	SAN JUAN	6354	0	11
6811	SAN JUSTO	6330	0	11
6812	SAN MANUEL	6352	0	11
6813	SAN PEDRO	6330	0	11
6814	URIBURU	6354	0	11
6815	ARBOL DE LA ESPERANZA	6323	0	11
6816	CHICALCO	6323	0	11
6817	COLONIA LA PASTORIL	6323	0	11
6818	CURRU MAHUIDA	6323	0	11
6819	EL CENTINELA	6323	0	11
6820	EMILIO MITRE	6323	0	11
6821	LA PRIMAVERA	6323	0	11
6822	LA RAZON SANTA ISABEL	6323	0	11
6823	LA SOLEDAD	6323	0	11
6824	LOS TAJAMARES	6323	0	11
6825	PASO DE LOS ALGARROBOS	6323	0	11
6826	PASO DE LOS PUNTANOS	6323	0	11
6827	PASO LA RAZON	6323	0	11
6828	SANTA ISABEL	6323	0	11
6829	VISTA ALEGRE	6323	0	11
6830	AGUAS BUENAS	6228	0	11
6831	BERNARDO LARROUDE	6220	0	11
6832	CEBALLOS	6221	0	11
6833	COLONIA DENEVI	6228	0	11
6834	COLONIA LAS MERCEDES	6221	0	11
6835	COLONIA TRENQUENDA	6220	0	11
6836	CORONEL HILARIO LAGOS	6228	0	11
6837	EL ANTOJO	6220	0	11
6838	EL PORVENIR	6228	0	11
6839	EL RECREO	6220	0	11
6840	GALLINAO	6228	0	11
6841	INTENDENTE ALVEAR	6221	0	11
6842	LA CASILDA	6228	0	11
6843	LA ENERGIA	6228	0	11
6844	LA ESPERANZA VERTIZ	6365	0	11
6845	LA INVERNADA	6228	0	11
6846	LA LUCHA	6228	0	11
6847	LA MAGDALENA	6228	0	11
6848	LA MARIA VERTIZ	6365	0	11
6849	LA PAMPEANA	6228	0	11
6850	LA PAULINA	6221	0	11
6851	LA PRADERA	6228	0	11
6852	LA VICTORIA	6221	0	11
6853	LAS DELICIAS	6221	0	11
6854	MARIANO MIRO	6228	0	11
6855	RAMON SEGUNDO	6228	0	11
6856	SAN JOSE	6228	0	11
6857	SAN URBANO	6228	0	11
6858	SANTA AURELIA	6239	0	11
6859	SANTA FELICITAS	6220	0	11
6860	SARAH	6228	0	11
6861	TRES LAGUNAS	6228	0	11
6862	VERTIZ	6365	0	11
6863	ZONA RURAL DE VERTIZ	6365	0	11
6864	AGUA DE TORRE	5621	0	11
6865	ALGARROBO DEL AGUILA	6323	0	11
6866	ESTABLECIMIENTO EL CENTINELA	6323	0	11
6867	LA HUMADA	6323	0	11
6868	LA IMARRA	6323	0	11
6869	LA VEINTITRES	6323	0	11
6870	COLONIA SAN JUAN	6326	0	11
6871	BOEUF	6380	0	11
6872	CAMPO CARETTO	6381	0	11
6873	CAMPO MOISES SECCION 1A	6383	0	11
6874	CAMPO PICO	6381	0	11
6875	CHACRA 16	6380	0	11
6876	COLONIA ESPIGA DE ORO	6313	0	11
6877	COLONIA LA PAZ	6313	0	11
6878	COLONIA SAN FELIPE	6313	0	11
6879	COLONIA SAN LORENZO	6380	0	11
6880	COLONIA SANTA ELENA	6313	0	11
6881	COLONIAS DRYSDALE	6381	0	11
6882	COLONIAS MURRAY	6381	0	11
6883	CONHELO	6381	0	11
6884	EDUARDO CASTEX	6380	0	11
6885	EL DESTINO	6381	0	11
6886	EL DESTINO	6313	0	11
6887	EL FURLONG	6313	0	11
6888	EL PELUDO	6381	0	11
6889	KILOMETRO 619	6381	0	11
6890	LA DELFINA	6313	0	11
6891	LAS CHACRAS	6381	0	11
6892	LOO CO	6381	0	11
6893	LOTE 12	6313	0	11
6894	LOTE 13 ESCUELA 173	6313	0	11
6895	LOTE 17 ESCUELA 95	6380	0	11
6896	LOTE 2 ESCUELA 185	6380	0	11
6897	LOTE 20 LA CARLOTA	6380	0	11
6898	LOTE 21 COLONIA SANTA ELENA	6313	0	11
6899	LOTE 23 ESCUELA 221	6313	0	11
6900	LOTE 24 SECCION 1A	6383	0	11
6901	LOTE 8 ESCUELA 184	6380	0	11
6902	MAURICIO MAYER	6315	0	11
6903	MONTE NIEVAS	6383	0	11
6904	NICOLAS VERA	6380	0	11
6905	RUCANELO	6381	0	11
6906	SAN JOSE	6313	0	11
6907	SAN RAMON	6383	0	11
6908	SECCION PRIMERA CONHELLO	6383	0	11
6909	WINIFREDA	6313	0	11
6910	ZONA RURAL  METILEO	6367	0	11
6911	ZONA URBANA NORTE	6380	0	11
6912	CERRO DEL AIGRE	8201	0	11
6913	EL DIEZ	8201	0	11
6914	EL DIEZ Y SIETE	8201	0	11
6915	EL NUEVE	8201	0	11
6916	EL TARTAGAL	8201	0	11
6917	EL TRECE	8201	0	11
6918	EL UNO	8201	0	11
6919	EUSKADI	8201	0	11
6920	GOBERNADOR DUVAL	8336	0	11
6921	LA CHITA PUELCHES	8201	0	11
6922	LA CLELIA	8201	0	11
6923	LA JAPONESA	8336	0	11
6924	LA LIMPIA	8201	0	11
6925	LA REFORMA VIEJA	8201	0	11
6926	LEGASA	8201	0	11
6927	MINERALES DE LA PAMPA	8201	0	11
6928	PUELCHES	8201	0	11
6929	SAN ROBERTO	8201	0	11
6930	ALPACHIRI	6309	0	11
6931	CAMPO LA FLORIDA	6311	0	11
6932	CAMPO URDANIZ	6309	0	11
6933	COLONIA ANASAGASTI	6309	0	11
6934	COLONIA LA ESPERANZA	6311	0	11
6935	COLONIA LUNA	6311	0	11
6936	COLONIA SANTA TERESA	6311	0	11
6937	CONA LAUQUEN	8212	0	11
6938	EL PUMA	8214	0	11
6939	GRAL MANUEL CAMPOS	6309	0	11
6940	GUATRACHE	6311	0	11
6942	LA ELVA	8212	0	11
6943	LA MARIA ELENA	8212	0	11
6944	LA MARIA ROSA	6309	0	11
6945	LA NUEVA	6311	0	11
6946	LA PIEDAD	6311	0	11
6947	LA TORERA	8214	0	11
6948	LAS QUINTAS	6311	0	11
6949	LOS TOROS	6311	0	11
6950	LUNA	8212	0	11
6951	MONTE RALO	6309	0	11
6952	PERU	8212	0	11
6953	PICHE CONA LAUQUEN	8212	0	11
6954	REMECO	6311	0	11
6955	SALINAS MARI MANUEL	6309	0	11
6956	SAN MIGUEL	8212	0	11
6957	SANTA ANA	6309	0	11
6958	ABRAMO	8212	0	11
6959	BERNASCONI	8204	0	11
6960	CAMPO CICARE	8208	0	11
6961	CAMPO DE SALAS	8208	0	11
6962	CAMPO NICHOLSON	8208	0	11
6963	COLONIA BEATRIZ	8208	0	11
6964	COLONIA ESPA	8206	0	11
6965	COLONIA HELVECIA	8206	0	11
6966	COLONIA VASCONGADA	8208	0	11
6967	COLONIA VILLA ALBA	8206	0	11
6968	COTITA	8212	0	11
6969	DOS AMIGOS	8212	0	11
6970	DOS DE IPI	8212	0	11
6971	DOS VIOLETAS	8212	0	11
6972	EL LUCERO	8212	0	11
6973	EL MIRADOR	8212	0	11
6974	EL TRIGO	8206	0	11
6975	EL VASQUITO	8206	0	11
6976	GENERAL SAN MARTIN	8206	0	11
6977	HUCAL	8212	0	11
6978	IPI	8212	0	11
6979	JACINTO ARAUZ	8208	0	11
6980	LA ADMINISTRACION	8212	0	11
6981	LA CATITA	8212	0	11
6982	LA COLORADA CHICA	8206	0	11
6983	LA COLORADA GRANDE	8206	0	11
6984	LA CONSTANCIA	8212	0	11
6985	LA ESTRELLA DEL SUD	8212	0	11
6986	LA ISABEL	8212	0	11
6987	LA JUANITA	8206	0	11
6988	LA MARIA	8212	0	11
6989	LA MARIA ELISA	8212	0	11
6990	LA PORTE	8206	0	11
6991	LA PRIMERA	8206	0	11
6992	LA PUMA	8206	0	11
6993	LA UNION	8212	0	11
6994	LA VICTORIA	8212	0	11
6995	LOTE 17 ESCUELA 121	8206	0	11
6996	LOTE 18 ESCUELA 158	8206	0	11
6997	LOTE 20	8204	0	11
6998	LOTE 22 IPI	8212	0	11
6999	LOTE 23 ESCUELA 264	8206	0	11
7000	LOTE 7 ESCUELA 270	8206	0	11
7001	LOTE 8 ESCUELA 179	6319	0	11
7002	LOTE 8	8212	0	11
7003	MINAS DE SAL	8206	0	11
7004	REMECO	8212	0	11
7005	SAN AQUILINO	8212	0	11
7006	SAN DIEGO	8212	0	11
7007	SAN JUAN	8212	0	11
7008	TRAICO	8206	0	11
7009	TRAICO GRANDE	8208	0	11
7010	TRES BOTONES	8212	0	11
7011	TRES NACIONES	8212	0	11
7012	TRIBULUCI	8212	0	11
7013	TRUBULUCO	8212	0	11
7014	VILLA ALBA	8206	0	11
7015	VILLA MENCUELLE	8208	0	11
7016	EL BOQUERON	8200	0	11
7017	LA ASTURIANA	8201	0	11
7018	LAS DOS NACIONES	8200	0	11
7019	LIHUE CALEL	8201	0	11
7020	LIMAY MAHUIDA	8201	0	11
7021	SIERRAS DE LIHUEL CALEL	8200	0	11
7022	CUCHILLO CO	8214	0	11
7023	EL PORVENIR	8214	0	11
7024	JULIAN A MANSILLA	8201	0	11
7025	CAICHUE	6321	0	11
7026	CARRO QUEMADO	6319	0	11
7027	CHACRAS DE VICTORICA	6319	0	11
7028	COLONIA EL PORVENIR	6321	0	11
7029	COSTA DEL SALADO	6321	0	11
7030	DOS AMIGOS	6321	0	11
7031	EL DESTINO	6321	0	11
7032	EL DURAZNO	6319	0	11
7033	EL MATE	6321	0	11
7034	EL ODRE	6321	0	11
7035	EL REFUGIO	6321	0	11
7036	EL RETIRO	6321	0	11
7037	EL SILENCIO	6321	0	11
7038	GUADALOZA	6319	0	11
7039	JAGUEL DEL ESQUINERO	6321	0	11
7040	JAGUEL DEL MONTE	6321	0	11
7041	JUZGADO VIEJO	6321	0	11
7042	LA CATALINA	6321	0	11
7043	LA CIENAGA	6321	0	11
7044	LA CONSTANCIA	6321	0	11
7045	LA ELENITA	6321	0	11
7046	LA ELIA	6321	0	11
7047	LA ELINA	6321	0	11
7048	LA ESMERALDA	6321	0	11
7049	LA ESTRELLA	6321	0	11
7050	LA EULOGIA	6321	0	11
7051	LA FE	6321	0	11
7052	LA FLORENCIA	6317	0	11
7053	LA GUADALOSA	6321	0	11
7054	LA ISABEL	6321	0	11
7055	LA LAURENTINA	6321	0	11
7056	LA LUZ	6321	0	11
7057	LA MARCELA	6321	0	11
7058	LA MOROCHA	6319	0	11
7059	LA PENCOSA	6321	0	11
7060	LA RAZON	6321	0	11
7061	LA TINAJERA	6321	0	11
7062	LA UNION	6321	0	11
7063	LA VERDE	6321	0	11
7064	LA ZOTA	6321	0	11
7065	LABAL	6319	0	11
7066	LEONA REDONDA	6321	0	11
7067	LOMA REDONDA	6321	0	11
7068	LOMAS DE GATICA	6321	0	11
7069	LOMAS OMBU	6321	0	11
7070	LOS MANANTIALES	6321	0	11
7071	LOS TRES POZOS	6321	0	11
7072	LOTE 5 LUAN TORO	6317	0	11
7073	LOVENTUEL	6317	0	11
7074	LUAN TORO	6317	0	11
7075	MANANTIALES	6321	0	11
7076	MAYACO	6321	0	11
7077	NAHUEL NAPA	6321	0	11
7078	NANQUEL HUITRE	6321	0	11
7079	POITAGUE	6319	0	11
7080	SAN EMILIO	6321	0	11
7081	SAN FRANCISCO	6319	0	11
7082	SAN JOSE	6321	0	11
7083	TELEN	6321	0	11
7084	VICTORICA	6319	0	11
7085	ARGENTINA BELVEDERE	6367	0	11
7086	AZTEAZU	6365	0	11
7087	BARRIO EL MOLINO	6360	0	11
7088	CAIMI	6361	0	11
7089	CARLOS BERG	6360	0	11
7090	COLONIA LA CARLOTA	6315	0	11
7091	EL BELGICA	6331	0	11
7092	EL PARQUE	6331	0	11
7093	GENERAL PICO	6360	0	11
7094	LA BARRANCOSA	6365	0	11
7095	LA CHAPELLE	6360	0	11
7096	LA GAVENITA	6361	0	11
7097	LA GUE	6360	0	11
7098	LA TERESITA	6361	0	11
7099	LAS TRES HERMANAS	6331	0	11
7100	MOCOVI	6360	0	11
7101	PAVON	6331	0	11
7102	RUCAHUE	6331	0	11
7103	SAN ALBERTO	6331	0	11
7104	SAN BENITO	6331	0	11
7105	SAN IGNACIO	6360	0	11
7106	SAN ILDEFONSO	6365	0	11
7107	SAN JOAQUIN	6360	0	11
7108	SAN JOSE	6360	0	11
7109	SANTA CATALINA	6365	0	11
7110	SANTA ELENA	6360	0	11
7111	SANTA INES	6360	0	11
7112	SPELUZZI	6365	0	11
7113	ZONA RURAL DORILA	6365	0	11
7114	25 DE MAYO	8201	0	11
7115	COLONIA GOBERNADOR AYALA	8307	0	11
7116	EL ESCABEL	8201	0	11
7117	GOBERNADOR AYALA	8201	0	11
7118	LA BOTA	8307	0	11
7119	LA COPELINA	8307	0	11
7120	PASO LA BALSA	8307	0	11
7121	PUELEN	8307	0	11
7122	SAN SALVADOR	8201	0	11
7123	ALFREDO PE	6333	0	11
7124	COLONIA BARON	6315	0	11
7125	COLONIA BEAUFORT	6331	0	11
7126	COLONIA GIUSTI	6331	0	11
7127	COLONIA LA ABUNDANCIA	6333	0	11
7128	COLONIA LA SARA	6333	0	11
7129	COLONIA SAN JOSE	6315	0	11
7130	COLONIA SANTA CECILIA	6333	0	11
7131	CURILCO	6331	0	11
7132	HUELEN	6333	0	11
7133	LA CAUTIVA	6333	0	11
7134	LA CELINA	6333	0	11
7135	LA DELICIA	6333	0	11
7136	LA ENRIQUETA	6333	0	11
7137	LA OLLA	6333	0	11
7138	LA PUMA	6360	0	11
7139	LOS PIRINEOS	6315	0	11
7140	LOTE 25 ESCUELA 178	6315	0	11
7141	LOTE 6 ESCUELA 171	6315	0	11
7142	MARI MARI	6333	0	11
7143	MIGUEL CANE	6331	0	11
7144	QUEMU QUEMU	6333	0	11
7145	RELMO	6331	0	11
7146	SAN MIGUEL	6331	0	11
7147	SANTA ELVIRA	6333	0	11
7148	SOL DE MAYO	6333	0	11
7149	TRILI	6365	0	11
7150	VILLA MIRASOL	6315	0	11
7151	VILLA SAN JOSE	6315	0	11
7152	ZONA RURAL	6331	0	11
7153	ZONA RURAL DE MIRASOL	6315	0	11
7154	CALEUFU	6387	0	11
7155	CARAMAN	6387	0	11
7156	CHAMAICO	6214	0	11
7157	COLONIA EL TIGRE	6385	0	11
7158	COLONIA LA MARGARITA	6214	0	11
7159	COLONIA LAS PIEDRITAS	6385	0	11
7160	COLONIA SAN BASILIO	6214	0	11
7161	EL GUANACO	6205	0	11
7162	EL TAJAMAR	6205	0	11
7163	INGENIERO FOSTER	6385	0	11
7164	JARDON	6214	0	11
7165	LA MARGARITA	6214	0	11
7166	LA MARUJA	6385	0	11
7167	LAS DELICIAS	6214	0	11
7168	LAS PIEDRITAS	6387	0	11
7169	LOTE 11 ESCUELA 107	6213	0	11
7170	LOTE 15 ESCUELA 18	6387	0	11
7171	LOTE 15	6213	0	11
7172	LOTE 4	6387	0	11
7173	LOTE 5 CALEUFU  ESC 120	6205	0	11
7174	PARERA	6213	0	11
7175	PICHI HUINCA	6385	0	11
7176	QUETREQUEN	6212	0	11
7177	RANCUL	6214	0	11
7178	SAN BASILIO	6214	0	11
7179	SAN MARCELO	6214	0	11
7180	ADOLFO VAN PRAET	6212	0	11
7181	ALTA ITALIA	6207	0	11
7182	CHANILAO	6201	0	11
7183	EL OLIVO	6203	0	11
7184	EL TIGRE	6203	0	11
7185	EL TORDILLO	6212	0	11
7186	EMBAJADOR MARTINI	6203	0	11
7187	FALUCHO	6212	0	11
7188	INGENIERO LUIGGI	6205	0	11
7189	LA ELINA	6203	0	11
7190	LA VOLUNTAD	6228	0	11
7191	LOTE 2 LA ELINA	6203	0	11
7193	MAISONNAVE	6212	0	11
7194	OJEDA	6207	0	11
7195	REALICO	6200	0	11
7196	SAN JUAN SIMSON	6212	0	11
7197	SANTA GRACIA	6212	0	11
7198	TRES HERMANOS QUETREQUEN	6212	0	11
7199	BAJO DE LAS PALOMAS	6313	0	11
7200	BOLICHE LA ARA	6301	0	11
7201	CACHIRULO	6303	0	11
7202	CALCHAHUE	6303	0	11
7203	CHACU	6303	0	11
7204	CHAPALCO	6303	0	11
7205	COLONIA FERRARO	6303	0	11
7206	COLONIA RAMON QUINTAS	6303	0	11
7207	COLONIA ROCA	6303	0	11
7208	EL EUCALIPTO CARRO QUEMADO	6319	0	11
7209	EL VOLANTE	6303	0	11
7210	LA AVANZADA	6325	0	11
7211	LA BAYA	6303	0	11
7212	LA BAYA MUERTA	6303	0	11
7213	LA CELINA	6303	0	11
7214	LA CELMIRA	6303	0	11
7215	LA ESTHER	6325	0	11
7216	LA VANGUARDIA	6303	0	11
7217	LINDO VER	6303	0	11
7218	LOS ALAMOS	6325	0	11
7219	LOS ALGARROBOS	6303	0	11
7220	NAICO	6325	0	11
7221	NERRE CO	6303	0	11
7222	OFICIAL E SEGURA	6303	0	11
7223	PARQUE LURO	6325	0	11
7224	PICHI HUILCO	6303	0	11
7225	RAMON QUINTAS	6303	0	11
7226	SAN HUMBERTO	6325	0	11
7227	SANTIAGO ORELLANO	6325	0	11
7228	TA HUILCO	6303	0	11
7229	TOAY	6303	0	11
7230	ARATA	6385	0	11
7231	CAMPO SALUSSO	6369	0	11
7232	COLONIA MIGLIORI	6367	0	11
7233	METILEO	6367	0	11
7234	MINISTRO ORLANDO	6367	0	11
7235	SAN JOAQUIN METILEO	6367	0	11
7236	TRENEL	6369	0	11
7237	ZONA RURAL	6369	0	11
7238	ATALIVA ROCA	6301	0	11
7239	BARRANCAS COLORADAS	8201	0	11
7240	CERRO AZUL	8201	0	11
7241	CERRO BAYO	8201	0	11
7242	CERRO LA BOTA	8201	0	11
7243	CHACHARRAMENDI	8201	0	11
7244	COLONIA CAZAUX	8214	0	11
7245	COLONIA DEVOTO	6325	0	11
7246	COLONIA LA AMARGA	6325	0	11
7247	COLONIA LA MUTUA	8214	0	11
7248	COLONIA LIA Y ALLENDE	8200	0	11
7249	COLONIA MEDANO COLORADO	8214	0	11
7250	COLONIA MINISTRO LOBOS	6325	0	11
7251	COLONIA SANTA CLARA	8214	0	11
7252	COLONIA SANTA MARIA	8214	0	11
7253	EL CARANCHO	8200	0	11
7254	EL CHILLEN	6325	0	11
7255	EL DESCANSO	8214	0	11
7256	EL MADRIGAL	8200	0	11
7257	EL PIMIA	8214	0	11
7258	EL VERANEO	8200	0	11
7259	EPU PEL	8214	0	11
7260	GENERAL ACHA	8200	0	11
7261	LA AURORA	8200	0	11
7262	LA CHITA	8200	0	11
7263	LA ESCONDIDA	8200	0	11
7264	LA LONJA	8200	0	11
7265	LA LUCHA LA REFORMA	8201	0	11
7266	LA MAGDALENA	8200	0	11
7267	LA MODERNA	8200	0	11
7268	LA NILDA	8200	0	11
7269	LA PALOMA	8200	0	11
7270	LA PAMPITA	8200	0	11
7271	LA SORPRESA	8200	0	11
7272	LAS ACACIAS	8200	0	11
7273	LOTE 10	8200	0	11
7274	LOTE 11	8200	0	11
7275	LOTE 12	8200	0	11
7276	LOTE 13	8200	0	11
7277	LOTE 18	8200	0	11
7278	LOTE 19	8200	0	11
7279	LOTE 21	8200	0	11
7280	LOTE 22	8200	0	11
7281	LOTE 3	8200	0	11
7282	MARACO	8200	0	11
7283	MARACO CHICO	8200	0	11
7284	MEDANO COLORADO	8200	0	11
7285	QUEHUE	8203	0	11
7286	QUI	8200	0	11
7287	SANTA CLARA	8214	0	11
7288	SANTA MARIA	8214	0	11
7289	UNANUE	8214	0	11
7290	UTRACAN	8203	0	11
7291	VALLE ARGENTINO	8200	0	11
7292	VALLE DAZA	8200	0	11
7293	ARROYO VERDE	8532	0	5
7294	BAHIA CRACHER	9120	0	5
7295	BAJO DEL GUALICHO	9121	0	5
7296	BAJO BARTOLO	9121	0	5
7297	BAJO LAS DAMAJUANAS	9121	0	5
7298	CALETA VALDEZ	9121	0	5
7300	EL DESEMPE	9120	0	5
7301	EL PASTIZAL	9121	0	5
7302	EL PIQUILLIN	9121	0	5
7303	EL QUILIMUAY	9121	0	5
7304	EL RUANO	9121	0	5
7305	EL SALITRAL	9121	0	5
7306	EMPALME PUERTO LOBOS	8532	0	5
7307	LA CORONA	9121	0	5
7308	LA ROSILLA	9121	0	5
7309	LARRALDE	9121	0	5
7310	LORETO	9121	0	5
7311	MEDANOS	9121	0	5
7312	PUERTO LOBOS	8532	0	5
7313	PUERTO MADRYN	9120	0	5
7314	PUERTO PIRAMIDES	9121	0	5
7315	PUERTO SAN ROMAN	9121	0	5
7316	PUNTA BAJOS	9121	0	5
7317	PUNTA DELGADA	9121	0	5
7318	PUNTA NORTE	9121	0	5
7319	PUNTA QUIROGA	9120	0	5
7320	SALINAS CHICAS	9121	0	5
7321	SALINAS GRANDES	9121	0	5
7322	SAN JOSE	9121	0	5
7323	BUENOS AIRES CHICO	9210	0	5
7324	CA	9213	0	5
7325	CA	9213	0	5
7326	CERRO RADAL	8430	0	5
7327	CHOLILA	9217	0	5
7328	COLONIA CUSHAMEN	9213	0	5
7329	COSTA CHUBUT	9210	0	5
7330	COSTA DEL LEPA	9201	0	5
7331	CUSHAMEN	9211	0	5
7332	EL CAJON	9217	0	5
7333	EL COIHUE	9211	0	5
7334	EL HOYO	8431	0	5
7335	EL MAITEN	9210	0	5
7336	EL MIRADOR	9201	0	5
7337	EPUYEN	9211	0	5
7338	FITHEN VERIN	9210	0	5
7339	FITIRHUIN	9210	0	5
7340	GUALJAINA	9201	0	5
7341	ING BRUNO J THOMAE	9210	0	5
7342	LA CASTELLANA	9007	0	5
7343	LAGO LEZAMA	9217	0	5
7344	LAGO PUELO	8431	0	5
7345	LAS GOLONDRINAS	8430	0	5
7346	LELEQUE	9213	0	5
7347		8415	0	5
7348	RANQUIL HUAO	9213	0	5
7349	SIEMPRE VIVA	9213	0	5
7350	CERRO FOFOCAHUEL	9213	0	5
7351	FOFO CAHUEL	9213	0	5
7352	BAHIA BUSTAMANTE	9111	0	5
7353	BAHIA SOLANO	9003	0	5
7356	CA	9001	0	5
7357	CA	9009	0	5
7358	CA	9009	0	5
7359	CA	9009	0	5
7362	COMODORO RIVADAVIA	9000	0	5
7366	EMPALME A ASTRA	9003	0	5
7367	HOLDICH	9009	0	5
7369	LA SALAMANCA	9007	0	5
7370	PAMPA DEL CASTILLO	9000	0	5
7371	PAMPA PELADA	9007	0	5
7372	PAMPA SALAMANCA	9007	0	5
7373	PICO SALAMANCA	9000	0	5
7374	RADA TILLY	9001	0	5
7375	RIO CHICO	9007	0	5
7376	SIERRA CUADRADA	9007	0	5
7377	SIERRA OVERA CHICAS Y GRANDES	9007	0	5
7380	CABO RASO	9111	0	5
7381	CAMARONES	9111	0	5
7382	DOS POZOS	9100	0	5
7383	EL JAGUEL	9007	0	5
7384	FLORENTINO AMEGHINO	9113	0	5
7385	GARAYALDE	9007	0	5
7386	MALASPINA	9007	0	5
7387	RUTA 3 KILOMETRO 1711	9007	0	5
7388	RUTA 3 KILOMETRO 1646	9111	0	5
7389	SIERRA COLORADA	9007	0	5
7390	UZCUDUN	9007	0	5
7391	ALDEA ESCOLAR	9203	0	5
7392	ARROYO PERCY	9203	0	5
7393	ARROYO PESCADO	9200	0	5
7394	CERRO CENTINELA	9203	0	5
7395	CERRO MALLACO	9200	0	5
7396	CHACRA DE AUSTIN	9200	0	5
7397	COLONIA 16 DE OCTUBRE	9200	0	5
7398	CORCOVADO	9201	0	5
7399	EL BOQUETE	9210	0	5
7400	ESQUEL	9200	0	5
7401	FUTALEUFU	9203	0	5
7402	LAGO RIVADAVIA	9217	0	5
7403	LAGO ROSARIO	9203	0	5
7404	LAGO VERDE	9225	0	5
7405	LAGUNA TERRAPLEN	9200	0	5
7406	LEGUA 24	9203	0	5
7407	LOS CIPRESES	9203	0	5
7408	MALLIN GRANDE CORCOVADO	9121	0	5
7409	MATUCANA	9200	0	5
7410	MAYOCO	9200	0	5
7411	NAHUEL PAN ESTACION FCGR	9200	0	5
7412	PARQUE NACIONAL LOS ALERCES	9201	0	5
7413	RIO CORINTO	9203	0	5
7414	SIERRA DE TECKA	9200	0	5
7415	SUNICA	9200	0	5
7416	TREVELIN	9203	0	5
7417	VALLE FRIO	9203	0	5
7418	VILLA FUTALAUFQUEN	9200	0	5
7419	ANGOSTURA	9105	0	5
7420	ANGOSTURA SEGUNDA	9105	0	5
7421	BETESTA	9105	0	5
7422	BOCA DE LA ZANJA	9107	0	5
7423	BOCA ZANJA SUD	9107	0	5
7424	BRYN BROWN	9105	0	5
7425	BRYN GWYN	9105	0	5
7426	CABA	9105	0	5
7427	CAMPAMENTO VILLEGAS	9107	0	5
7428	DIQUE FLORENTINO AMEGHINO	9101	0	5
7429	DOLAVON	9107	0	5
7430	EBENECER	9107	0	5
7431	EL ARGENTINO	9105	0	5
7432	GAIMAN	9105	0	5
7433	GLASFRYN	9105	0	5
7434	LOMA REDONDA	9105	0	5
7435	MAESTEG	9105	0	5
7436	TOMA DE LOS CANALES	9107	0	5
7437	TREORKI	9105	0	5
7438	VALLE LOS MARTIRES	9105	0	5
7439	VALLE DEL RIO CHUBUT	9121	0	5
7440	28 DE JULIO	9107	0	5
7441	VILLA INES	9105	0	5
7442	AGUADA DEL PITO	9121	0	5
7443	BAJADA MORENO	9121	0	5
7444	CARHUE NIYEO	9121	0	5
7445	CERRO SANTA ANA	9100	0	5
7446	COLELACHE	9121	0	5
7447	EL CHACAY DPTO GASTRE	9121	0	5
7448	EL ESCORIAL	9121	0	5
7449	GASTRE	9121	0	5
7450	LAGUNITA SALADA	9121	0	5
7451	PIRRE MAHUIDA	9121	0	5
7452	PLANCUNTRE	9121	0	5
7453	SACANANA	9121	0	5
7454	TAQUETREN	9201	0	5
7455	CARRENLEUFU	9201	0	5
7456	COLAN CONHUE	9201	0	5
7457	COLONIA EPULEF	9201	0	5
7458	EL CRONOMETRO	9201	0	5
7459	EL CUCHE	9201	0	5
7460	EL KAQUEL	9201	0	5
7461	EL MOLLE	9220	0	5
7462	EL POYO	9201	0	5
7463	ESTANCIA LA MIMOSA	9201	0	5
7464	ESTANCIA PAMPA CHICA	9201	0	5
7465	LANGUI	9201	0	5
7466	LAS SALINAS	9201	0	5
7467	MALLIN BLANCO	9201	0	5
7468	PAMPA DE AGNIA	9201	0	5
7469	PAMPA TEPUEL	9201	0	5
7470	PASO DEL SAPO	9201	0	5
7471	PIEDRA PARADA	9201	0	5
7472	POCITOS DE QUICHAURA	9201	0	5
7473	TECKA	9201	0	5
7474	VALLE DEL TECKA	9201	0	5
7475	VALLE GARIN	9201	0	5
7476	VALLE HONDO	9221	0	5
7477	ALTO DE LAS PLUMAS	9101	0	5
7478	CABEZA DE BUEY	9101	0	5
7479	EL MIRASOL	9101	0	5
7480	LAGUNA GRANDE	9107	0	5
7481	LAS CHAPAS	9107	0	5
7482	LAS PLUMAS	9101	0	5
7483	ARROYO GUILAIA	9207	0	5
7484	CAJON DE GINEBRA CHICO	9201	0	5
7485	CAJON DE GINEBRA GRANDE	9201	0	5
7486	CA	9207	0	5
7487	CERRO CONDOR	9207	0	5
7488	CERRO LONCO TRAPIAL	9201	0	5
7489	EL CALAFATE	9201	0	5
7490	EL CANQUEL	9207	0	5
7491	EL PAJARITO	9201	0	5
7492	EL SOMBRERO	9207	0	5
7493	LA BOMBILLA	9207	0	5
7494	LA PRIMAVERA	9201	0	5
7495	LAS CORTADERAS	9207	0	5
7496	LAS HORQUETAS	9207	0	5
7497	LOS ALTARES	9207	0	5
7498	LOS MANANTIALES	9207	0	5
7499	PASO DE INDIOS	9207	0	5
7500	SIERRA NEVADA PASO DE INDIOS	9207	0	5
7501	TORO HOSCO	9207	0	5
7502	BAJO DE LOS HUESOS	9103	0	5
7503	BASE AERONAVAL ALMIRANTE IRIZA	9101	0	5
7504	CASA BLANCA	9103	0	5
7505	CHARQUE CHICO	9103	0	5
7506	PLAYA UNION	9103	0	5
7507	PUENTE HENDRE	9101	0	5
7508	PUNTA NINFAS	9120	0	5
7509	RAWSON	9103	0	5
7510	SOL DE MAYO	9103	0	5
7512	ALDEA APELEG	9033	0	5
7513	ALDEA BELEIRO	9037	0	5
7514	ALTO RIO MAYO	9037	0	5
7515	ALTO RIO SENGUER	9033	0	5
7516	ARROYO CHALIA	9035	0	5
7517	ARROYO GATO	9033	0	5
7518	BAJO LA CANCHA	9031	0	5
7520	DOCTOR RICARDO ROJAS	9035	0	5
7521	EL COITE	9033	0	5
7522	EL PORVENIR	9227	0	5
7523	EL TRIANA	9037	0	5
7524	FACUNDO	9031	0	5
7525	HITO 45	9039	0	5
7526	HITO 50	9039	0	5
7527	LA CANCHA	9039	0	5
7529	LA LAURITA	9227	0	5
7530	LA NICOLASA	9039	0	5
7531	LA PEPITA	9033	0	5
7532	LA SIBERIA	9039	0	5
7533	LAGO BLANCO	9039	0	5
7534	LAGO FONTANA	9033	0	5
7535	LOS TAMARISCOS	9031	0	5
7536	PASO MORENO	9227	0	5
7538	PASTOS BLANCOS	9033	0	5
7539	RIO FRIAS	9227	0	5
7540	RIO MAYO	9030	0	5
7541	SIERRA NEVADA BUEN PASTO	9023	0	5
7542	VALLE HUEMULES	9039	0	5
7543	ARROYO QUILLA	9020	0	5
7544	BUEN PASTO	9023	0	5
7545	CA	9020	0	5
7546	CA	9020	0	5
7547	COLHUE HUAPI	9021	0	5
7548	COLONIA GERMANIA	9020	0	5
7549	COSTA RIO CHICO	9020	0	5
7550	ENRIQUE HERMITTE	9020	0	5
7551	KILOMETRO 191	9020	0	5
7552	LAGO MUSTERS	9023	0	5
7553	LAGUNA DEL MATE	9020	0	5
7554	LAGUNA PALACIO	9020	0	5
7555	LAS PULGAS	9020	0	5
7556	MANANTIAL GRANDE	9020	0	5
7557	PASO DE TORRES	9020	0	5
7558	SARMIENTO	9020	0	5
7559	SIERRA CORRIENTES	9020	0	5
7560	SIERRA VICTORIA	9020	0	5
7561	VALLE HERMOSO	9020	0	5
7562	ALTO RIO PICO	9223	0	5
7563	ARENOSO	9225	0	5
7564	CA	9223	0	5
7565	CA	9220	0	5
7566	CASA BLANCA	9220	0	5
7567	CERRO NEGRO	9223	0	5
7568	CORRALITOS	9220	0	5
7569	EL CHERQUE	9223	0	5
7570	EL SHAMAN	9223	0	5
7571	EL TROPEZON	9223	0	5
7572	GOBERNADOR COSTA	9223	0	5
7573	HITO 43	9225	0	5
7574	JOSE DE SAN MARTIN	9220	0	5
7575	LAGO VINTTER	9225	0	5
7576	LAGUNA BLANCA	9220	0	5
7577	LAGUNA DE VACAS	9121	0	5
7578	LAGUNA VERDE	9220	0	5
7579	LAS MULAS	9223	0	5
7580	LAS PAMPAS	9225	0	5
7581	LENZANILLEO	9223	0	5
7582	LOS CORRALITOS	9223	0	5
7583	MATA GRANDE	9220	0	5
7584	NIRIGUAO	9223	0	5
7585	NIRIGUCE PAMPA	9223	0	5
7586	ESTANCIA NUEVA LUBECKA	9227	0	5
7587	PIEDRA SHOTEL	9227	0	5
7588	PUTRACHOIQUE	9223	0	5
7589	RIO PICO	9225	0	5
7591	TRES PICOS	9223	0	5
7592	AGUADA DE LAS TEJAS	9121	0	5
7593	BAJADA DEL DIABLO	9101	0	5
7594	CA	9121	0	5
7595	CA	9121	0	5
7596	CA	9121	0	5
7597	CATAYCO	9120	0	5
7598	CERRO PICHALAO	9120	0	5
7599	CHACAY ESTE	9121	0	5
7600	CHACAY OESTE	9121	0	5
7601	CHASICO	9121	0	5
7602	EL ALAMO	9121	0	5
7603	ESTANCIA EL MORO	9121	0	5
7604	GAN GAN	9121	0	5
7605	LAGUNA FRIA	9121	0	5
7606	MALLIN GRANDE	9121	0	5
7607	PAINALUF	9121	0	5
7608	SEPRUCAL	9121	0	5
7609	SIERRA CHATA	9121	0	5
7610	SIERRA ROSADA	9121	0	5
7611	TALAGAPA	9121	0	5
7612	TATUEN	9121	0	5
7613	TELSEN	9121	0	5
7614	ALUMINE	8345	0	15
7615	ARROYO QUILLEN	8341	0	15
7616	CARRI LIL	8345	0	15
7618	EL DORMIDO	8341	0	15
7619	EL GATO	8341	0	15
7620	HARAS PATRIA	8345	0	15
7621	KILCA CASA	8345	0	15
7622	LA ANGOSTURA DE ICALMA	8345	0	15
7623	LA ARBOLEDA	8341	0	15
7624	LA OFELIA	8341	0	15
7625	LAGOTERA	8345	0	15
7626	LITRAN	8345	0	15
7627	LONCO LUAN	8345	0	15
7628	LONCO MULA	8345	0	15
7629	MALALCO	8341	0	15
7630	MOQUEHUE	8345	0	15
7631	PAMPA DE LONCO LUAN	8345	0	15
7634	CHANQUIL QUILLA	8345	0	15
7635	QUILCA	8345	0	15
7636	QUILLEN	8341	0	15
7637	RAHUE	8341	0	15
7638	RUCA CHOROY ARRIBA	8345	0	15
7639	SAINUCO	8345	0	15
7640	SAN JUAN RAHUE	8341	0	15
7641	VILLA PEHUENIA	8345	0	15
7642	A	8305	0	15
7643	AUCA MAHUIDA	8305	0	15
7644	LOS CHIHUIDOS	8305	0	15
7645	LOS CHINITOS	8305	0	15
7646	PUNTA DE SIERRA	8305	0	15
7647	SAN PATRICIO DEL CHA	8305	0	15
7648	TRATAYEN	8305	0	15
7649	AGUADA FLORENCIO	8340	0	15
7650	BAJADA DEL MARUCHO	8340	0	15
7651	CA	8375	0	15
7652	CATAN LIL	8341	0	15
7653	CERRO GATO	8375	0	15
7654	CHACAYCO	8340	0	15
7655	CHARAHUILLA	8341	0	15
7656	EL OVERO	8340	0	15
7657	ESPINAZO DEL ZORRO	8341	0	15
7658	FORTIN 1 DE MAYO	8341	0	15
7659	LA NEGRA	8375	0	15
7660	LAJA	8341	0	15
7661	LAPA	8341	0	15
7662	LAPACHAL	8341	0	15
7663	LAS COLORADAS	8341	0	15
7664	LOS RODILLOS	8341	0	15
7665	MALLIN DE LAS YEGUAS	8375	0	15
7666	OJO DE AGUA	8341	0	15
7667	PASO CATA TUN	8341	0	15
7668	PILO LIL	8373	0	15
7669	SANTA ISABEL	8375	0	15
7670	ZINGONE Y CIA M	8375	0	15
7671	ZULEMITA	8375	0	15
7672	CAVIAHUE	8349	0	15
7673	AGUADA CHACAY CO	8353	0	15
7674	ANQUINCO	8353	0	15
7675	ARROYO BLANCO	8353	0	15
7676	BATRE LAUQUEN	8353	0	15
7677	CAEPE MALAL	8353	0	15
7678	VILLA CURI LEUVU	8353	0	15
7679	CAJON GRANDE	8353	0	15
7680	CA	8353	0	15
7681	CANCHA HUINGANCO	8353	0	15
7682	CASA DE PIEDRA	8353	0	15
7683	CERRO NEGRO CHAPUA	8353	0	15
7684	CERRO NEGRO TRICAO	8353	0	15
7685	CHACAY CO	8353	0	15
7686	CHACAY MELEHUE	8353	0	15
7687	CHAPUA	8353	0	15
7688	CHAPUA ABAJO	8353	0	15
7690	COYUCO COCHICO	8353	0	15
7691	CURU  LEUVU	8353	0	15
7692	EL ALAMITO	8353	0	15
7693	EL CURILEO	8353	0	15
7694	LA CIENAGA	8353	0	15
7695	LA CIENEGUITA	8353	0	15
7696	LA SALADA	8353	0	15
7697	LAS ABEJAS	8353	0	15
7698	LAS CORTADERAS	8353	0	15
7699	LAS SALADAS	8353	0	15
7700	LEUTO CABALLO	8353	0	15
7701	LOS ENTIERROS	8353	0	15
7703	LOS MOLLES	8353	0	15
7704	LOS TRES CHORROS	8353	0	15
7705	LUICOCO	8353	0	15
7706	MAYAN MAHUIDA	8353	0	15
7707	PAMPA FERREIRA	8353	0	15
7708	QUEMPU LEUFU	8353	0	15
7709	TIHUE	8353	0	15
7710	TRICAO MALAL	8353	0	15
7711	ACHICO	8315	0	15
7712	ALIANZA	8373	0	15
7713	ALICURA	8403	0	15
7714	BAJADA COLORADA	8315	0	15
7715	CARRAN CURA	8315	0	15
7716	CARRI LAUQUEN	8315	0	15
7717	CHICHIGUAY	8373	0	15
7718	CHINCHINA	8373	0	15
7719	COSTA LIMAY	8315	0	15
7720	EL SALITRAL	8375	0	15
7721	LA PINTADA	8315	0	15
7722	LA TERESA	8315	0	15
7723	LAS MERCEDES	8373	0	15
7724	PAMPA COLLON CURA	8375	0	15
7725	PE	8373	0	15
7727	PIEDRA PINTADA	8315	0	15
7728	SAN BERNARDO	8315	0	15
7729	SAN IGNACIO	8375	0	15
7730	SA	8315	0	15
7731	SANTA ISABEL	8315	0	15
7732	SANTO TOMAS	8315	0	15
7734	ZAINA YEGUA	8315	0	15
7736	ARROYITO	8313	0	15
7737	ARROYITO CHALLACO	8313	0	15
7738	BALSA SENILLOSA	8316	0	15
7741	CAMPAMENTO SOL	8319	0	15
7742	CENTENARIO	8309	0	15
7744	CHALLACO	8318	0	15
7745	CHINA MUERTA	8316	0	15
7748	CUTRAL CO	8322	0	15
7749	LAS PERLAS	8300	0	15
7750	LOMA DE LA LATA	8300	0	15
7752	MARI MENUCO	8300	0	15
7756	PLANICIE BANDERITA	8301	0	15
7757	PLAZA HUINCUL	8318	0	15
7758	PLOTTIER	8316	0	15
7759	PORTEZUELO GRANDE	8300	0	15
7760	PUEBLO NUEVO	8322	0	15
7761	RINCON DE EMILIO	8300	0	15
7762	SAUZAL BONITO	8319	0	15
7763	SENILLOSA	8316	0	15
7764	VILLA EL CHOCON	8311	0	15
7766	VISTA ALEGRE NORTE	8309	0	15
7767	VISTA ALEGRE SUR	8309	0	15
7768	AUCA PAN	8373	0	15
7769	CERRO DE LOS PINOS	8373	0	15
7770	CHACOYAL	8373	0	15
7771	CHIUQUILLIHUIN	8371	0	15
7772	COLLUN CO	8371	0	15
7773	EL TROMEN	8353	0	15
7774	HUECHULAFQUEN	8371	0	15
7775	JUNIN DE LOS ANDES	8371	0	15
7776	LA ATALAYA	8371	0	15
7777	LA RINCONADA	8375	0	15
7778	LA UNION	8371	0	15
7779	LUBECA	8371	0	15
7780	MAMUL MALAL	8371	0	15
7781	NAHUEL MAPE	8371	0	15
7782	PALITUE	8371	0	15
7783	PAMPA DEL MALLEO	8373	0	15
7784	PASO DE SAN IGNACIO	8375	0	15
7785	PIEDRA MALA	8371	0	15
7786	QUILA QUEHUE	8371	0	15
7787	QUILQUIHUE	8371	0	15
7788	SAN JUAN JUNIN DE LOS ANDES	8371	0	15
7789	TRES PICOS	8371	0	15
7790	TROMEN	8371	0	15
7791	TRILI	8353	0	15
7792	BUENA ESPERANZA	8360	0	15
7793	CALEUFU	8373	0	15
7794	CAMINERA	8370	0	15
7795	CHACABUCO	8373	0	15
7796	CHAPELCO	8370	0	15
7797	CHIMEHUIN	8373	0	15
7798	EL CERRITO	8370	0	15
7799	EL OASIS	8370	0	15
7800	EL PORVENIR	8370	0	15
7801	FILO HUA HUM	8370	0	15
7802	GENTE GRANDE	8379	0	15
7803	HUA HUM	8370	0	15
7804	LA FORTUNA	8370	0	15
7805	LAGO LOLOG	8370	0	15
7806	LAS BANDURRIAS	8370	0	15
7807	LASCAR	8370	0	15
7808	LOLOG	8370	0	15
7809	VILLA LAGO MELIQUINA	8370	0	15
7810	QUENTRENQUEN	8373	0	15
7811	QUILA QUINA	8370	0	15
7812	QUINQUIMITREO	8373	0	15
7813	SAN MARTIN DE LOS ANDES	8370	0	15
7814	TIPILIUKE	8373	0	15
7815	TROMPUL	8370	0	15
7816	VILLA RAUR	8370	0	15
7817	AGUAS DE LAS MULAS	8349	0	15
7818	CAJON DE ALMAZA	8349	0	15
7819	CAJON DE MANZANO	8349	0	15
7820	CERRO DE LA PARVA	8349	0	15
7821	CHORRIACA	8351	0	15
7822	COIHUECO	8351	0	15
7823	COSTA DEL ARROYO SALADO	8351	0	15
7824	EL PERALITO	8351	0	15
7825	EL PINO ANDINO	8349	0	15
7826	EL SALADO	8351	0	15
7827	FRANHUCURA	8351	0	15
7828	HUALCUPEN	8349	0	15
7829	HUNCAL	8351	0	15
7830	LA ARGENTINA	8349	0	15
7831	LONCOPUE	8349	0	15
7832	MALLIN DEL TORO	8349	0	15
7833	MULICHINCO	8349	0	15
7834	PAMPA DEL SALADO	8351	0	15
7835	QUINTUCO	8351	0	15
7836	SANTA ISABEL	8349	0	15
7837	TRAHUNCURA	8351	0	15
7838	CAMINERA TRAFUL	8403	0	15
7839	CORRENTOSO	8407	0	15
7840	CULLIN MANZANO	8401	0	15
7841	EL ARBOLITO	8407	0	15
7842	EL MACHETE	8407	0	15
7843	EL MANZANO	8403	0	15
7844	ESTANCIA LA PRIMAVERA	8403	0	15
7845	ESTANCIA NEWBERY	8401	0	15
7846	ESTANCIA TEQUEL MALAL	8401	0	15
7847	HUINCA LU	8403	0	15
7848	ISLA VICTORIA	8400	0	15
7849	LA ARAUCARIA	8401	0	15
7850	LA ESTACADA	8401	0	15
7851	LA LIPELA	8401	0	15
7852	NAHUEL HUAPI	8401	0	15
7853	PASO COIHUE	8401	0	15
7854	PENINSULA HUEMUL	8400	0	15
7855	PUERTO ANCHORENA	8400	0	15
7856	PUERTO MANZANO	8407	0	15
7857	RINCON GRANDE	8401	0	15
7859	VILLA TRAFUL	8403	0	15
7860	ANDACOLLO	8353	0	15
7861	BELLA VISTA	8353	0	15
7862	CAMALEONES	8353	0	15
7863	CAYANTA	8353	0	15
7864	EL CHINGUE	8353	0	15
7865	EL DURAZNO	8353	0	15
7866	FILMATUE	8353	0	15
7867	FLORES	8353	0	15
7868	GUA	8353	0	15
7869	HUINGANCO	8353	0	15
7870	HUMIGAMIO	8353	0	15
7871	INVERNADA VIEJA	8353	0	15
7872	JECANASCO	8353	0	15
7873	JUARANCO	8353	0	15
7874	LA PRIMAVERA	8353	0	15
7875	LAS LAGUNAS	8353	0	15
7876	LAS OVEJAS	8353	0	15
7877	LILEO	8353	0	15
7878	LOS CARRIZOS	8353	0	15
7879	LOS CISNES	8353	0	15
7880	LOS MICHES	8353	0	15
7881	MACHICO	8353	0	15
7882	MILLA	8353	0	15
7883	MINA LILEO	8353	0	15
7884	NAHUEVE	8353	0	15
7885	NERECO NORTE	8353	0	15
7886	NIRECO	8353	0	15
7887	RE	8353	0	15
7888	TIERRAS BLANCAS	8353	0	15
7889	VARVARCO	8353	0	15
7890	BUTA MALLIN	8353	0	15
7891	CAJON DE LOS PATOS	8349	0	15
7892	CHENQUECURA	8349	0	15
7893	CHOCHOY MALLIN	8349	0	15
7894	COLIPILI	8349	0	15
7895	EL BOSQUE	8349	0	15
7896	EL CHOLAR	8353	0	15
7897	EL HUECU	8349	0	15
7898	HAYCU	8349	0	15
7899	NALAY CULLIN	8349	0	15
7900	NAU NAUCO	8351	0	15
7901		8349	0	15
7902	PICHAIHUE	8351	0	15
7903	PICHI NEUQUEN	8351	0	15
7904	RANQUELES	8349	0	15
7905	RANQUILCO	8349	0	15
7906	RANQUILON	8349	0	15
7907	TAQUIMILAN	8351	0	15
7908	TAQUIMILLAN ABAJO	8353	0	15
7909	TRALAITUE	8349	0	15
7910	TRES CHORROS	8353	0	15
7911	VILU MALLIN	8349	0	15
7912	BARRANCAS	8353	0	15
7913	BUTA CO	8353	0	15
7914	BUTA RANQUIL	8353	0	15
7915	HUITRIN	8353	0	15
7916	MINA CARRASCOSA	8353	0	15
7917	PAMPA DE TRIL	8353	0	15
7918	PASO BARDA	8353	0	15
7919	PUESTO HERNANDEZ  BATERIAS	8319	0	15
7920	RINCON DE LOS SAUCES	8319	0	15
7921	RIO BARRANCAS	8353	0	15
7922	SAN EDUARDO	8353	0	15
7923	CERRO DEL LEON	8313	0	15
7924	EL SAUCE	8313	0	15
7925	LIMAY CENTRO	8313	0	15
7926	LOS SAUCES	8313	0	15
7927	PANTANITOS	8313	0	15
7928	PASO AGUERRE	8313	0	15
7930	AGRIO BALSA	8351	0	15
7931	ARROYO CAHUNCO	8347	0	15
7932	BAJADA DEL AGRIO	8351	0	15
7933	BALNEARIO DEL RIO AGRIO	8351	0	15
7934	BALSA DEL RIO AGRIO	8351	0	15
7935	CAJON DEL TORO	8347	0	15
7936	CALIHUE	8347	0	15
7937	CARRERI	8347	0	15
7938	CERRO COLORADO	8347	0	15
7939	CERRO DE LA GRASA	8347	0	15
7940	CHACAY	8347	0	15
7942	CODIHUE	8347	0	15
7945	CONFLUENCIA DEL AGUIJON	8351	0	15
7946	CORRAL DE PIEDRA	8347	0	15
7947	CUCHILLO CURA	8347	0	15
7948	EL ATRAVESADO	8347	0	15
7949	EL ESCORIAL	8347	0	15
7950	EL PALAO	8347	0	15
7951	HAICHOL	8347	0	15
7952	HUARENCHENQUE	8349	0	15
7953	HUILLILON	8347	0	15
7954	LA BUITRERA	8347	0	15
7955	LA PORTE	8347	0	15
7956	LA VERDAD	8347	0	15
7958	LAS LAJITAS	8347	0	15
7959	LAS TOSCAS	8347	0	15
7960	LAS TRES LAGUNAS	8347	0	15
7961	LIU CULLIN	8347	0	15
7962	LLAMUCO	8347	0	15
7963	LOS GALPONES	8347	0	15
7964	MALLIN BLANCO	8347	0	15
7965	MALLIN CHILENO	8347	0	15
7966	MALLIN DE LA CUEVA	8347	0	15
7967	MALLIN DE MENA	8347	0	15
7968	MALLIN DEL RUBIO	8347	0	15
7969	MALLIN QUEMADO	8347	0	15
7970	PASO ANCHO	8347	0	15
7971	PICHE PONON	8347	0	15
7972	PIEDRAS BAYAS	8347	0	15
7973	PILMATUE	8351	0	15
7974	PINO HACHADO	8347	0	15
7975	PINO SOLO	8347	0	15
7976	POZO HUALICHES	8347	0	15
7977	PRIMEROS PINOS	8347	0	15
7978	QUEBRADA HONDA	8347	0	15
7979	QUILI MALAL	8351	0	15
7980	RAMICHAL	8347	0	15
7981	RIO AGRIO	8351	0	15
7982	SALQUICO	8347	0	15
7983	SAN DEMETRIO	8347	0	15
7985	LA SUSANA	8340	0	15
7986	BAJADA DE LOS MOLLES	8340	0	15
7987	BARDA ANGUIL	8340	0	15
7988	BARDA NEGRA	8340	0	15
7989	CAICHIHUE	8340	0	15
7990	COVUNCO	8340	0	15
7991	COVUNCO ABAJO	8351	0	15
7992	COVUNCO ARRIBA	8340	0	15
7993	COVUNCO CENTRO	8351	0	15
7994	EL TROPEZON	8340	0	15
7995	GO	8340	0	15
7996	HUECHAHUE	8375	0	15
7997	LA POCHOLA	8340	0	15
7998	LA FRIA	8340	0	15
7999	LA ISABEL	8340	0	15
8000	LA PATAGONIA	8340	0	15
8001	LA PATRIA	8340	0	15
8002	LA TERESA	8340	0	15
8003	LAGUNA BLANCA	8340	0	15
8004	LAGUNA MIRANDA	8340	0	15
8005	LAS BARDITAS	8340	0	15
8006	LAS CORTADERAS	8340	0	15
8007	LOS MUCHACHOS	8340	0	15
8008	MARIANO MORENO	8351	0	15
8009		8340	0	15
8010	OJO DE AGUA	8340	0	15
8011	PASO DE LOS INDIOS	8318	0	15
8012	PORTADA COVUNCO	8340	0	15
8013	PUENTE PICUN LEUFU	8340	0	15
8014	SANTO DOMINGO	8340	0	15
8015	TAQUI NILEU	8340	0	15
8016	TRES PIEDRAS	8340	0	15
8018	CA	9305	0	20
8019	CA	9300	0	20
8020	CA	9300	0	20
8021	CA	9303	0	20
8022	CERRO REDONDO	9303	0	20
8023	CHONQUE	9303	0	20
8024	COMANDANTE LUIS PIEDRABUENA	9303	0	20
8025	EL BAILE	9303	0	20
8027	EL PAN DE AZUCAR	9303	0	20
8028	EL PASO	9303	0	20
8029	GARMINUE	9303	0	20
8030	LA BARRETA	9303	0	20
8031	LA JULIA	9303	0	20
8032	LA PIGMEA	9303	0	20
8033	LA PORTE	9303	0	20
8034	LAGUNA GRANDE	9303	0	20
8035	LAS MERCEDES	9303	0	20
8036	PASO DE LOS INDIOS	9303	0	20
8037	PASO DEL RIO SANTA CRUZ	9303	0	20
8038	PASO IBA	9303	0	20
8039	PUERTO SANTA CRUZ	9300	0	20
8040	RIO CHICO	9303	0	20
8041	SIERRA DE LA VENTANA	9303	0	20
8042	TAUEL AIKE	9303	0	20
8043	AGUADA GRANDE	9053	0	20
8044	AGUADA ESCONDIDA	9019	0	20
8045	ALMA GRANDE	9015	0	20
8046	ZANJON DEL PESCADO	9015	0	20
8047	BAHIA LANGARA	9011	0	20
8048	CABO BLANCO	9051	0	20
8049	CABO TRES PUNTAS	9051	0	20
8050	CALETA OLIVIA	9011	0	20
8051	CAMERON	9017	0	20
8052	CERRO SILVA	9017	0	20
8053	LA ESTHER	9011	0	20
8054	CA	9013	0	20
8055	CARA MALA	9313	0	20
8056	CERRO ALTO	9053	0	20
8057	CERRO LA SETENTA	9017	0	20
8058	CERRO RENZEL	9017	0	20
8059	COLONIA CARLOS PELLEGRINI	9017	0	20
8060	EL BARBUCHO	9053	0	20
8061	MESETA GUENGUE	9017	0	20
8062	EL HUECO	9051	0	20
8064	CERRO MANGRULLO	9011	0	20
8065	CERRO MORO	9019	0	20
8066	CERRO PUNTUDO	9051	0	20
8067	EL POLVORIN	9051	0	20
8076	FARO CABO GUARDIAN	9313	0	20
8077	FARO CAMPANA	9313	0	20
8078	FITZ ROY	9019	0	20
8079	FLORADORA	9053	0	20
8080	GOBERNADOR MOYANO	9050	0	20
8081	INDIA MUERTA	9017	0	20
8082	JARAMILLO	9053	0	20
8083	JELAINA	9015	0	20
8084	KOLUEL KAIKE	9019	0	20
8085	LA ANTONIA	9015	0	20
8086	LA ARGENTINA	9017	0	20
8087	LA CENTRAL	9051	0	20
8088	LA GUARDIA	9015	0	20
8089	LA MADRUGADA	9051	0	20
8090	LA MARGARITA	9051	0	20
8091	LA PROTEGIDA	9051	0	20
8092	LA ROSA	9015	0	20
8093	LA ROSADA	9051	0	20
8094	LA VIOLETA	9051	0	20
8095	LAS HERAS	9017	0	20
8096	LAS MASITAS	9017	0	20
8097	CERRO NEGRO	9053	0	20
8098	MATA MAGALLANES	9017	0	20
8099	MAZAREDO	9051	0	20
8100	MINERALES	9015	0	20
8101	MONTE VERDE	9019	0	20
8102	PAMPA VERDUM	9017	0	20
8103	EL PLUMA	9017	0	20
8104	PELLEGRINI	9017	0	20
8105	PICO TRUNCADO	9015	0	20
8106	PIEDRA CLAVADA	9017	0	20
8107	LAS PIRAMIDES	9017	0	20
8108	PUERTO DESEADO	9050	0	20
8109	PUNTA MERCEDES	9313	0	20
8110	SARAI	9051	0	20
8111	TEHUELCHES	9019	0	20
8112	TELLIER	9050	0	20
8113	TRES CERROS	9050	0	20
8114	YEGUA MUERTA	9017	0	20
8115	28 DE NOVIEMBRE	9407	0	20
8116	AN AIKE	9400	0	20
8117	BELLA VISTA	9400	0	20
8119	CA	9400	0	20
8120	CAP	9400	0	20
8121	CERRO PALIQUE	9400	0	20
8122	CHALL AIKE	9400	0	20
8123	CORONEL GUARUMBA	9400	0	20
8124	EL ZURDO	9401	0	20
8125	ESTACION ING ATILIO CAPPA	9400	0	20
8126	FUENTES DE COYLE	9401	0	20
8127	GAYPON	9407	0	20
8128	GOBERNADOR MAYER	9401	0	20
8129	JULIA DUFOUR	9407	0	20
8130	LA ESPERANZA	9401	0	20
8131	LAGUNA COLORADA	9400	0	20
8132	LAS HORQUETAS	9400	0	20
8133	MINA 3	9407	0	20
8134	MORRO CHICO	9407	0	20
8135	PALERMO AIKE	9400	0	20
8136	PALI AIKE	9400	0	20
8137	PASO DEL MEDIO	9400	0	20
8138	PUEBLO NUEVO	9407	0	20
8139	PUENTE BLANCO	9407	0	20
8140	PUNTA DEL MONTE	9400	0	20
8141	RINCON DE LOS MORROS	9407	0	20
8143	RIO TURBIO	9407	0	20
8144	ROSPENTEK	9407	0	20
8145	TAPI AIKE	9420	0	20
8146	BAHIA TRANQUILA	9405	0	20
8147	CONDOR CLIF	9405	0	20
8148	EL CALAFATE	9405	0	20
8149	EL CERRITO	9405	0	20
8150	EL CHALTEN	9301	0	20
8151	FORTALEZA	9401	0	20
8152	GUARDAPARQUE FITZ ROY	9301	0	20
8153	LA FEDERICA	9301	0	20
8154	LA FLORIDA	9301	0	20
8155	LA LEONA	9303	0	20
8157	LAGO ARGENTINO	9405	0	20
8158	LAGO ROCA	9405	0	20
8159	LAGO SAN MARTIN	9301	0	20
8160	LAGO TAR	9301	0	20
8161	PASO CHARLES FHUR	9405	0	20
8162	PASO RIO LA LEONA	9301	0	20
8163	PENINSULA MAIPU	9301	0	20
8164	PIEDRA CLAVADA	9301	0	20
8165	PUNTA BANDERA	9405	0	20
8166	PUNTA DEL LAGO VIEDMA	9301	0	20
8167	QUIEN SABE	9405	0	20
8168	RIO BOTE	9405	0	20
8169	TRES LAGOS	9301	0	20
8170	VENTISQUERO MORENO	9405	0	20
8171	CA	9040	0	20
8172	CA	9017	0	20
8173	COLONIA LEANDRO N ALEM	9040	0	20
8174	EL PLUMA	9017	0	20
8175	EL PORTEZUELO	9040	0	20
8176	INGENIERO PALLAVICINI	9040	0	20
8177	LA ASTURIANA	9040	0	20
8178	LA MARIA	9017	0	20
8179	LAGO BUENOS AIRES	9040	0	20
8180	LOS ANTIGUOS	9041	0	20
8181	MONTE CEBALLOS	9040	0	20
8182	NACIMIENTOS DEL PLUMA	9040	0	20
8183	PERITO MORENO	9040	0	20
8184	EL SALADO	9313	0	20
8185	LOS MANANTIALES	9313	0	20
8186	PUERTO SAN JULIAN	9310	0	20
8187	CA	9311	0	20
8189	GOBERNADOR GREGORES	9311	0	20
8190	LAGO CARDIEL	9301	0	20
8191	H YRIGOYEN LAGO POSADAS	9315	0	20
8192	LAGO STROBEL	9311	0	20
8193	PASO DEL AGUILA	9311	0	20
8194	TUCU TUCU	9311	0	20
8365	AGUA VERDE	3636	0	9
8366	ALFONSINA STORNI	3634	0	9
8367	BAJO HONDO	3630	0	9
8368	BUEN LUGAR	3636	0	9
8369	CABALLO MUERTO	3636	0	9
8370	CABO PRIMERO CHAVEZ	3630	0	9
8371	CAPITAN JUAN SOLA	3634	0	9
8372	COLONIA BUENA VISTA	3620	0	9
8373	CNEL MIGUEL MARTINEZ DE HOZ	3636	0	9
8374	COSTA DEL PILCOMAYO	3630	0	9
8375	DOCTOR GUMERSINDO SAYAGO	3636	0	9
8376	EL AZOTADO	3636	0	9
8377	EL PIMPIN	3632	0	9
8378	EL PINDO	3634	0	9
8379	EL QUEMADO	3636	0	9
8380	EL TASTAS	3632	0	9
8381	EL ZORRO	3636	0	9
8382	FLORENCIO SANCHEZ	3636	0	9
8383	FORTIN CABO 1RO CHAVES	3630	0	9
8384	FORTIN GUEMES	3630	0	9
8385	FORTIN LA SOLEDAD	3630	0	9
8386	FORTIN PILCOMAYO	3630	0	9
8387	GUADALCAZAR	3636	0	9
8388	JOAQUIN V GONZALEZ	3634	0	9
8389	JOSE MANUEL ESTRADA	3634	0	9
8390	LA PALMA SOLA	3636	0	9
8391	LAGUNA YEMA	3634	0	9
8393	MATIAS GULACSI	3632	0	9
8394	MEDIA LUNA	3634	0	9
8395	PASO DE LOS TOBAS	3630	0	9
8396	POZO DEL MORTERO	3632	0	9
8397	POZO LA NEGRA	3630	0	9
8399	RIACHO LINDO	3634	0	9
8400	RICARDO GUIRALDES	3636	0	9
8401	SOLDADO MARCELINO TORALES	3630	0	9
8402	SUMAYEN	3634	0	9
8403	COLONIA PASTORIL	3601	0	9
8404	FORMOSA	3600	0	9
8405	GRAN GUARDIA	3604	0	9
8406	ITUZAINGO	3601	0	9
8407	KILOMETRO 642 NAV R BERMEJO	3630	0	9
8408	LOS PILAGAS	3604	0	9
8409	MARIANO BOEDO	3604	0	9
8410	MOJON DE FIERRO	3600	0	9
8411	SAN HILARIO	3604	0	9
8414	BAHIA NEGRA	3600	0	9
8415	BANCO PAYAGUA	3601	0	9
8416	CABO ADRIANO AYALA	3526	0	9
8417	CAMPO GORETA	3601	0	9
8418	CHURQUI CUE	3601	0	9
8419	COLONIA AQUINO	3601	0	9
8420	COLONIA TATANE	3626	0	9
8421	COMISARIA PTE YRIGOYEN	3601	0	9
8422	COSTA DEL LINDO	3601	0	9
8423	CURUPAY	3601	0	9
8424	EL ANGELITO	3601	0	9
8425	EL ARBOL SOLO	3601	0	9
8426	EL ARBOLITO	3601	0	9
8427	EL OLVIDO	3601	0	9
8428	EL OMBU	3601	0	9
8429	EL PINDO	3601	0	9
8430	EL SILENCIO	3601	0	9
8431	ESTERITO	3601	0	9
8432	FORTIN GALPON	3601	0	9
8433	FRAY MAMERTO ESQUIU	3601	0	9
8435	GRAL LUCIO V MANSILLA	3526	0	9
8436	HERRADURA	3601	0	9
8437	ISLA PAYAGUA	3601	0	9
8439	LA CHINA	3601	0	9
8440	LA LUCRECIA	3601	0	9
8441	LA PASION	3601	0	9
8442	NUEVO PILCOMAYO	3526	0	9
8443	OLEGARIO VICTOR ANDRADE	3526	0	9
8444	RIACHO RAMIREZ	3601	0	9
8445	SAN ANTONIO	3601	0	9
8446	SAN CAYETANO	3601	0	9
8447	SAN FRANCISCO DE LAISHI	3601	0	9
8448	SANTA MARIA	3601	0	9
8449	SARGENTO CABRAL	3601	0	9
8450	TRES MOJONES	3601	0	9
8451	TRES POCITOS	3601	0	9
8452	VILLA ESCOLAR	3526	0	9
8453	BOLSA DE PALOMO	3636	0	9
8454	CAMPO GRANDE	3636	0	9
8455	CA	3636	0	9
8456	CARLOS PELEGRINI	3636	0	9
8457	DOCTOR LUIS AGOTE	3636	0	9
8458	EL DESMONTE	3636	0	9
8459	FRANCISCO NARCISO DE LAPRIDA	3636	0	9
8460	GOBERNADOR YALUR	3636	0	9
8461	ING GUILLERMO N JUAREZ	3636	0	9
8462	LAS TRES MARIAS	3636	0	9
8463	LOS CHAGUANCOS	3636	0	9
8464	MISTOL MARCADO	3636	0	9
8465	POZO DE LA YEGUA	3636	0	9
8466	POZO DEL MAZA	3636	0	9
8467	POZO VERDE  ING G N JUAREZ	3636	0	9
8468	PUERTO IRIGOYEN	3636	0	9
8469	AGENTE FELIPE SANTIAGO IBA	3624	0	9
8470	ALOLAGUE	3626	0	9
8471	ALTO ALEGRE	3620	0	9
8472	ARBOL SOLO	3628	0	9
8473	BARTOLOME DE LAS CASAS	3622	0	9
8474	BRUCHARD	3622	0	9
8475	CABO 1RO CASIMIRO BENITEZ	3626	0	9
8476	CAMPO AZCURRA	3624	0	9
8477	CAMPO DEL CIELO	3624	0	9
8478	CATANEO CUE	3615	0	9
8479	COLONIA FRANCISCO J MU	3630	0	9
8480	COLONIA EL CATORCE	3624	0	9
8481	COLONIA EL SILENCIO	3624	0	9
8482	COLONIA GUILLERMINA	3624	0	9
8483	COLONIA ISLA SOLA	3624	0	9
8484	COLONIA JUAN B ALBERDI	3626	0	9
8485	COLONIA JUANITA	3626	0	9
8486	COLONIA LA BRAVA	3626	0	9
8487	COLONIA PERIN	3624	0	9
8488	COLONIA RECONQUISTA	3624	0	9
8489	COLONIA SAN ISIDRO	3630	0	9
8490	COLONIA SAN JOSE	3626	0	9
8491	COLONIA UNION ESCUELA	3626	0	9
8492	COMANDANTE FONTANA	3620	0	9
8493	CORONEL ARGENTINO LARRABURE	3620	0	9
8494	CORONEL ENRIQUE ROSTAGNO	3624	0	9
8495	CORONEL FELIX BOGADO	3626	0	9
8496	DOCTOR CARLOS MONTAG	3624	0	9
8497	DOMINGO F SARMIENTO	3621	0	9
8498	EL CEIBAL	3630	0	9
8499	EL COGOIK	3620	0	9
8500	EL DESCANSO	3630	0	9
8501	EL OCULTO	3624	0	9
8502	EL PORTE	3621	0	9
8503	EL PORTE	3620	0	9
8504	EL RECREO	3626	0	9
8505	EL SAUCE	3628	0	9
8506	ESTANISLAO DEL CAMPO	3626	0	9
8507	FORTIN CABO 1RO LUGONES	3621	0	9
8508	FORTIN SARGENTO 1RO LEYES	3621	0	9
8509	HERMINDO BONAS	3626	0	9
8510	IBARRETA	3624	0	9
8511	ISLETA	3630	0	9
8512	JUAN G BAZAN	3632	0	9
8513	JUAN JOSE PASO	3626	0	9
8514	KILOMETRO 1769	3628	0	9
8515	KILOMETRO 503	3626	0	9
8516	LA INMACULADA	3624	0	9
8517	LA PALOMA	3628	0	9
8518	LAS CHOYAS	3626	0	9
8519	LAS LOLAS	3621	0	9
8520	LAS LOMITAS	3630	0	9
8521	LAS MOCHAS	3626	0	9
8522	LAS SALADAS	3630	0	9
8523	LAZO QUEMADO	3624	0	9
8524	LEGUA A	3624	0	9
8525	LOMA CLAVEL	3626	0	9
8526	LOS ESTEROS	3628	0	9
8527	LOS INMIGRANTES	3626	0	9
8528	MAESTRA BLANCA GOMEZ	3624	0	9
8529	MAESTRO FERMIN BAEZ	3621	0	9
8531	PASO DE NAITE	3628	0	9
8532	PATO MARCADO	3626	0	9
8533	PORTE	3626	0	9
8534	POSTA CAMBIO A ZALAZAR	3632	0	9
8535	POSTA SARGENTO CABRAL	3630	0	9
8536	POZO DE LAS GARZAS	3630	0	9
8537	POZO DEL TIGRE	3628	0	9
8538	POZO VERDE	3628	0	9
8539	QUEBRACHO MARCADO	3630	0	9
8540	RANERO CUE	3626	0	9
8541	RINCON FLORIDO	3620	0	9
8542	SAN LORENZO	3626	0	9
8543	SAN MARTIN 2	3621	0	9
8544	SARGENTO AGRAMONTE	3630	0	9
8545	SGTO AYUDANTE V SANABRIA	3626	0	9
8546	SATURNINO SEGUROLA	3626	0	9
8547	SOLDADO ALBERTO VILLALBA	3636	0	9
8548	SOLDADO DANTE SALVATIERRA	3624	0	9
8549	SOLDADO ERMINDO LUNA	3630	0	9
8550	SOLDADO ISMAEL SANCHEZ	3624	0	9
8551	SOLDADO RAMON A ARRIETA	3620	0	9
8552	SUBTENIENTE PERIN	3624	0	9
8553	SUIPACHA	3630	0	9
8554	TATANE	3601	0	9
8555	TENIENTE BROWN	3622	0	9
8556	TOMAS GODOY CRUZ	3630	0	9
8557	TRANSITO CUE	3626	0	9
8559	TRES POZOS	3626	0	9
8560	URBANA VIEJA	3621	0	9
8561	VILLA ADELAIDA	3624	0	9
8562	VILLA GENERAL GUEMES	3621	0	9
8563	VILLA GRAL MANUEL BELGRANO	3615	0	9
8564	VILLA GENERAL URQUIZA	3628	0	9
8565	APAYEREY	3615	0	9
8566	BELLA VISTA	3615	0	9
8567	BUENA VISTA	3615	0	9
8568	CHIROCHILAS	3613	0	9
8569	EL ESPINILLO	3615	0	9
8570	GENERAL JULIO DE VEDIA	3615	0	9
8571	JULIO CUE	3615	0	9
8572	LA FRONTERA	3613	0	9
8573	LAGUNA GALLO	3611	0	9
8574	LAGUNA INES	3613	0	9
8575	LOMA ZAPATU	3615	0	9
8576	LORO CUE	3615	0	9
8577	MISION TACAAGLE	3615	0	9
8578	PORTON NEGRO	3615	0	9
8579	SALVACION	3611	0	9
8580	SEGUNDA PUNTA	3613	0	9
8581	SOLDADO HERIBERTO AVALOS	3615	0	9
8582	SUBTTE RICARDO E MASAFERRO	3615	0	9
8584	VILLA REAL	3615	0	9
8585	CENTRO FRONTERIZO CLORINDA	3611	0	9
8586	CLORINDA	3610	0	9
8587	COLONIA ALFONSO	3613	0	9
8588	COLONIA BOUVIER	3611	0	9
8589	EL PARAISO	3610	0	9
8590	FRONTERA	3613	0	9
8591	GARCETE CUE	3611	0	9
8592	GOBERNADOR LUNA OLMOS	3611	0	9
8593	ISLA DE PUEN	3610	0	9
8594	LAGUNA BLANCA	3613	0	9
8595	LAGUNA NAICK NECK	3611	0	9
8596	MARCA M	3613	0	9
8597	MONTE LINDO  CNIA PASTORIL	3601	0	9
8598	PALMA SOLA	3611	0	9
8599	PRIMERA JUNTA	3613	0	9
8600	PUERTO PILCOMAYO	3611	0	9
8601	RIACHO HE HE	3611	0	9
8602	SAN JUAN	3611	0	9
8603	SANTA ISABEL	3611	0	9
8604	SGTO MAYOR BERNARDO AGUILA	3611	0	9
8605	SIETE PALMAS	3613	0	9
8606	TORO PASO	3611	0	9
8607	TRES LAGUNAS	3611	0	9
8609	VILLA LUCERO	3611	0	9
8610	BARRIO SAN JOSE OBRERO	3606	0	9
8611	MAYOR EDMUNDO V VILLAFA	3601	0	9
8612	COLONIA LA SOCIEDAD	3626	0	9
8613	COLONIA SANTA ROSA	3626	0	9
8614	DESVIO LOS MATACOS	3608	0	9
8615	EL COLORADO	3603	0	9
8616	EL CORRALITO	3606	0	9
8617	EL GATO	3601	0	9
8618	EL SALADO	3606	0	9
8619	ESPINILLO	3603	0	9
8620	KILOMETRO 139	3526	0	9
8621	KILOMETRO 142	3603	0	9
8622	KILOMETRO 1695	3606	0	9
8623	KILOMETRO 1895	3608	0	9
8624	KILOMETRO 232	3603	0	9
8625	LA ESPERANZA	3601	0	9
8626	LA LOMA	3606	0	9
8627	LA PICADITA	3601	0	9
8628	LA URBANA	3615	0	9
8629	LAS CA	3603	0	9
8631	MERCEDES CUE	3601	0	9
8632	MONSE	3606	0	9
8633	PALO SANTO	3608	0	9
8634	PARA TODO	3606	0	9
8635	PIRANE	3606	0	9
8636	POTRERO NORTE	3608	0	9
8637	RACEDO ESCOBAR	3603	0	9
8638	SOLDADO TOMAS SANCHEZ	3601	0	9
8639	CARLOS SAAVEDRA LAMAS	3636	0	9
8640	EL TOTORAL	3636	0	9
8641	GENERAL MOSCONI	3636	0	9
8642	LOTE NRO 8	3636	0	9
8643	MARIA CRISTINA	3636	0	9
8644	SANTA TERESA	3636	0	9
8645	SELVA MARIA	3636	0	9
8646	SOMBRERO NEGRO	3636	0	9
8648	ARROYO BARU	3269	0	8
8649	BERDUC	3285	0	8
8650	CA	3267	0	8
8651	CANTERA LA CONSTANCIA	3287	0	8
8652	COLON	3280	0	8
8653	COLONIA AMBIS	3269	0	8
8654	COLONIA BAYLINA	3269	0	8
8655	COLONIA CARABALLO	3265	0	8
8656	COLONIA EL CARMEN	3267	0	8
8657	COLONIA F SILLEN	3269	0	8
8658	COLONIA HOCKER	3265	0	8
8659	COLONIA HUGHES	3281	0	8
8660	COLONIA LAS PEPAS	3267	0	8
8661	COLONIA MABRAGA	3283	0	8
8662	COLONIA NUEVA SUR	3281	0	8
8663	COLONIA NUEVA SAN MIGUEL	3267	0	8
8664	COLONIA PEREIRA	3272	0	8
8665	COLONIA SAENZ VALIENTE	3287	0	8
8666	COLONIA SAN ANTONIO	3212	0	8
8667	COLONIA SAN FRANCISCO	3283	0	8
8668	COLONIA SAN IGNACIO	3267	0	8
8669	COLONIA SAN JOSE	3218	0	8
8670	COLONIA SAN MIGUEL	3265	0	8
8671	COLONIA SANTA ELENA	3269	0	8
8672	COLONIA SANTA ROSA	3267	0	8
8673	EJIDO COLON	3281	0	8
8674	EL BRILLANTE	3283	0	8
8675	ENRIQUE BERDUC	3118	0	8
8676	FABRICA COLON	3281	0	8
8677	HAMBIS	3269	0	8
8678	ISLA SAN JOSE	3287	0	8
8679	JUAN JORGE	3285	0	8
8680	LA CARLOTA	3218	0	8
8681	LA CLARITA	3269	0	8
8682	MARTINIANO LEGUIZAMON	3285	0	8
8683	PALMAR	3285	0	8
8684	PALMAR YATAY	3287	0	8
8685	PERUCHO VERNA	3283	0	8
8686	POS POS	3285	0	8
8687	PUEBLO CAZES	3269	0	8
8688	PUEBLO COLORADO	3281	0	8
8689	PUEBLO LIEBIG	3281	0	8
8690	PUNTAS DEL GUALEGUAYCHU	3269	0	8
8691	PUNTAS DEL PALMAR	3280	0	8
8692	SAN ANSELMO	3281	0	8
8693	SAN FRANCISCO	3265	0	8
8694	SAN GREGORIO	3203	0	8
8695	SAN JOSE	3283	0	8
8696	SAN MIGUEL	3269	0	8
8697	SAN MIGUEL NRO 2	3269	0	8
8698	SAN SALVADOR	3218	0	8
8699	SANTA INES	3285	0	8
8700	UBAJAY	3287	0	8
8701	VILLA ELISA	3265	0	8
8703	YATAY	3281	0	8
8704	AYUI PARADA	3204	0	8
8705	BENITO LEGEREN	3203	0	8
8706	CALABACILLAS	3203	0	8
8707	CAMBA PASO	3201	0	8
8708	CLODOMIRO LEDESMA	3203	0	8
8709	COLONIA ADELA	3201	0	8
8710	COLONIA AYUI	3201	0	8
8711	COLONIA CAMPOS	3216	0	8
8712	COLONIA CURBELO	3216	0	8
8713	COLONIA GENERAL ROCA	3201	0	8
8714	CNIA JUSTO JOSE DE URQUIZA	3212	0	8
8715	COLONIA LA MORA	3216	0	8
8716	COLONIA LA QUINTA	3216	0	8
8717	COLONIA LOMA NEGRA	3112	0	8
8718	COLONIA NAVARRO	3201	0	8
8719	COLONIA OFICIAL N 5	3216	0	8
8720	COLONIA SAN BONIFACIO	3212	0	8
8721	COLONIA YERUA	3201	0	8
8722	CONCORDIA	3200	0	8
8723	CUEVA DEL TIGRE	3201	0	8
8724	DON ROBERTO	3212	0	8
8725	EL DURAZNAL	3212	0	8
8726	EL MARTILLO	3201	0	8
8727	EL REDOMON	3212	0	8
8728	EL REFUGIO	3212	0	8
8729	EMBARCADERO FERRARI	3201	0	8
8730	ESTACION YERUA	3214	0	8
8731	FRIGORIFICO YUQUERI	3203	0	8
8732	GENERAL CAMPOS	3216	0	8
8733	HERVIDERO	3201	0	8
8734	ISTHILART	3204	0	8
8735	JUAN B MONTI	3201	0	8
8736	KILOMETRO 343	3216	0	8
8737	LA ALICIA	3212	0	8
8738	LA COLORADA	3212	0	8
8739	LA CRIOLLA	3212	0	8
8740	LA EMILIA	3212	0	8
8741	LA GRANJA	3212	0	8
8742	LA INVERNADA	3212	0	8
8743	LA NOBLEZA	3212	0	8
8744	LA ODILIA	3212	0	8
8745	LA PERLA	3216	0	8
8746	LA QUERENCIA	3212	0	8
8747	LA QUINTA	3216	0	8
8748	LA ROSADA	3201	0	8
8749	LAS MOCHAS	3216	0	8
8750	LAS TEJAS	3201	0	8
8751	LESCA	3200	0	8
8752	LOMA NEGRA	3212	0	8
8753	LOS BRILLANTES	3212	0	8
8754	LOS CHARRUAS	3212	0	8
8755	NUEVA ESCOCIA	3201	0	8
8756	OSVALDO MAGNASCO	3212	0	8
8757	PARADA YUQUERI	3214	0	8
8758	PEDERMAR	3203	0	8
8759	PEDERNAL	3203	0	8
8760	PUEBLO FERRE	3216	0	8
8761	PUERTO YERUA	3201	0	8
8762	RUTA 14 KM 443	3201	0	8
8763	SALADERO CONCORDIA	3200	0	8
8764	SAN BUENAVENTURA	3212	0	8
8765	SAN JORGE	3212	0	8
8766	SAN JUAN LA QUERENCIA	3212	0	8
8767	SANTA ISABEL	3203	0	8
8768	TABLADA NORTE CONCORDIA	3200	0	8
8769	TABLADA OESTE CONCORDIA	3200	0	8
8770	VILLA ZORRAQUIN	3201	0	8
8771	WALTER MOSS	3216	0	8
8772	YAROS	3212	0	8
8773	YERUA	3214	0	8
8774	YUQUERI	3214	0	8
8775	ALDEA BRASILERA	3101	0	8
8776	ALDEA PROTESTANTE	3101	0	8
8777	ALDEA SALTO	3101	0	8
8778	ALDEA SPATZENKUTTER	3101	0	8
8779	ALDEA VALLE MARIA	3101	0	8
8780	CARRIZAL	3101	0	8
8781	COLEGIO ADVENTISTA DEL PLATA	3103	0	8
8782	COLONIA ENSAYO	3101	0	8
8783	COLONIA GRAPSCHENTAL	3114	0	8
8784	COLONIA PALMAR	3101	0	8
8785	COLONIA RIVAS	3164	0	8
8786	COSTA GRANDE	3101	0	8
8787	COSTA GRANDE DOLL	3101	0	8
8788	DIAMANTE	3105	0	8
8789	DOCTOR GARCIA	3101	0	8
8790	EJIDO DIAMANTE	3105	0	8
8791	GENERAL ALVEAR	3101	0	8
8792	GENERAL RAMIREZ	3164	0	8
8794	LAS CUEVAS	3101	0	8
8795	PAJA BRAVA	3101	0	8
8796	PUEBLO GENERAL BELGRANO	2821	0	8
8797	RACEDO	3114	0	8
8799	RIVAS	3164	0	8
8800	SAN FRANCISCO	3101	0	8
8801	SANATORIO ADVENTISTA DEL PLATA	3103	0	8
8802	STROBEL	3101	0	8
8803	VILLA AIDA	3103	0	8
8804	VILLA LIBERTADOR SAN MARTIN	3103	0	8
8805	BIZCOCHO	3206	0	8
8806	CABI MONDA	3228	0	8
8807	CHAJARI	3228	0	8
8808	CHAVIYU PARADA FCGU	3206	0	8
8809	CHAVIYU COLONIA FLORES	3204	0	8
8810	COLONIA ALEMANA	3228	0	8
8811	COLONIA BELGRANO	3228	0	8
8812	COLONIA BIZCOCHO	3206	0	8
8813	COLONIA DON BOSCO	3204	0	8
8814	COLONIA ENSANCHE SAUCE	3208	0	8
8815	COLONIA FLORES	3206	0	8
8816	COLONIA FRAZER	3228	0	8
8817	COLONIA FREITAS	3229	0	8
8818	COLONIA GUALEGUAYCITO	3206	0	8
8819	COLONIA LA GLORIA	3204	0	8
8820	COLONIA LA MATILDE	3208	0	8
8821	COLONIA LA PAZ	3206	0	8
8822	COLONIA LAMARCA	3206	0	8
8823	COLONIA OFICIAL N 1 LA FLORIDA	3228	0	8
8824	COLONIA SAUCE	3261	0	8
8825	COLONIA VILLA LIBERTAD	3228	0	8
8826	COOPERATIVA GRAL SAN MARTIN	3228	0	8
8827	CUATRO BOCAS	3185	0	8
8828	ESTACION GENERAL RACEDO	3114	0	8
8829	FEDERACION	3206	0	8
8830	GUALEGUAYCITO	3204	0	8
8831	GUAYAQUIL	3206	0	8
8832	LA ARGENTINA	2846	0	8
8833	LA CALERA	3272	0	8
8834	LAMARCA	3206	0	8
8835	LAS CATORCE	3228	0	8
8836	LAS PE	3206	0	8
8837	LOMAS BLANCAS	3185	0	8
8838	LOS CONQUISTADORES	3183	0	8
8839	SAN JAIME	3185	0	8
8840	SAN JAIME DE LA FRONTERA	3185	0	8
8841	SAN PEDRO	3212	0	8
8842	SANTA ANA	3208	0	8
8843	SARANDI	3228	0	8
8844	VILLA DEL ROSARIO	3229	0	8
8845	ARROYO DEL MEDIO	3144	0	8
8846	BANDERAS	3190	0	8
8847	CHA	3181	0	8
8848	COLONIA FALCO	3188	0	8
8849	CONSCRIPTO BERNARDI	3188	0	8
8850	EL CIMARRON	3188	0	8
8851	EL GRAMIYAL	3144	0	8
8852	EL PAGO APEADERO FCGU	3212	0	8
8853	FEDERAL	3180	0	8
8854	LAS ACHIRAS	3281	0	8
8855	SAUCE DE LUNA	3144	0	8
8856	TTE PRIMERO BRIGIO CAINZO	3212	0	8
8857	VILLA PERPER	3188	0	8
8858	ATENCIO	3187	0	8
8859	CATALOTTI	3187	0	8
8860	CHA	3187	0	8
8861	CHIRCALITO	3187	0	8
8862	COLONIA LA MATILDE	3287	0	8
8863	CORREA	3187	0	8
8864	LA ESMERALDA	3187	0	8
8865	LA HIERRA	3183	0	8
8866	LA VERBENA	3185	0	8
8867	LAS LAGUNAS	3187	0	8
8868	LAS MULITAS	3191	0	8
8869	MAC KELLER	3187	0	8
8870	MESA	3187	0	8
8871	PAJAS BLANCAS	3187	0	8
8872	PALO A PIQUE	3191	0	8
8873	SAN JOSE DE FELICIANO	3187	0	8
8874	SAN LUIS SAN JOSE FELICIANO	3187	0	8
8875	SAN VICTOR	3191	0	8
8876	TASES	3187	0	8
8877	VIBORAS	3187	0	8
8878	VILLA PORTE	3191	0	8
8879	ALBARDON	2840	0	8
8880	ALDEA ASUNCION	2841	0	8
8882	BOCA GUALEGUAY	2840	0	8
8883	CHACRAS	2840	0	8
8884	COSTA DEL NOGOYA	3155	0	8
8885	CUATRO MANOS	2841	0	8
8886	CUCHILLA	2840	0	8
8887	EL GUALEGUAY	3212	0	8
8888	EL REMANCE	2840	0	8
8889	GENERAL GALARZA	2843	0	8
8890	GONZALEZ CALDERON	2841	0	8
8891	GUALEGUAY	2840	0	8
8892	GUALEYAN	2821	0	8
8893	HOJAS ANCHAS	2840	0	8
8894	ISLAS DE LAS LECHIGUANAS	2846	0	8
8895	LAS BATEAS	2840	0	8
8896	LAS COLAS	2841	0	8
8897	LAZO	2841	0	8
8898	PUERTA DE CRESPO	3155	0	8
8899	PUERTO RUIZ	2840	0	8
8900	PUNTA DEL MONTE	2840	0	8
8901	QUINTO DISTRITO	2843	0	8
8902	SALADERO ALZUA	2840	0	8
8903	SALADERO SAN JOSE	2840	0	8
8904	SAN JULIAN	2841	0	8
8905	SANTA MARTA	2840	0	8
8906	TRES BOCAS	3155	0	8
8907	ALARCON	2852	0	8
8908	ALDEA SAN ANTONIO	2826	0	8
8909	ARROYO DEL CURA	2821	0	8
8910	BERISSO	2848	0	8
8911	BERISSO DESVIO FCGU	2852	0	8
8912	BRAZO LARGO	1647	0	8
8913	BRITOS	2824	0	8
8914	CEIBAL	2823	0	8
8915	CEIBAS	2823	0	8
8916	COLONIA DELTA	2805	0	8
8917	COLONIA GDOR BASAVILBASO	2824	0	8
8918	COLONIA ITALIANA	2824	0	8
8919	COOPERATIVA BRAZO LARGO	2823	0	8
8920	COSTA SAN ANTONIO	2826	0	8
8921	CUCHILLA REDONDA	2852	0	8
8922	DOCTOR EUGENIO MU	2824	0	8
8923	DOS HERMANAS	2854	0	8
8924	EL SARANDI	3191	0	8
8925	EMPALME HOLT	2846	0	8
8926	ENRIQUE CARBO	2852	0	8
8927	ESCRI	2828	0	8
8928	FAUSTINO M PARERA	2824	0	8
8929	GENERAL ALMADA	2824	0	8
8930	GILBERT	2828	0	8
8931	GUALEGUAYCHU	2820	0	8
8932	HOLT	2846	0	8
8933	IRAZUSTA	2852	0	8
8934	ISLA DEL IBICUY	2823	0	8
8935	ISLA EL DORADO	2805	0	8
8936	KILOMETRO 311	2820	0	8
8937	KILOMETRO 340	2848	0	8
8938	KILOMETRO 361	2848	0	8
8939	KILOMETRO 389	2846	0	8
8940	LA CALERA	2823	0	8
8941	LA CHICA	2824	0	8
8942	LA COSTA	2852	0	8
8943	LA CUADRA	2823	0	8
8944	LA ESCONDIDA	2826	0	8
8945	LA FLORIDA	2824	0	8
8946	LA LATA	2820	0	8
8947	LARROQUE	2854	0	8
8948	LAS MASITAS	2828	0	8
8949	LAS MERCEDES	2854	0	8
8950	LOS AMIGOS	2828	0	8
8951	MAZARUCA	2846	0	8
8952		2821	0	8
8953	PALAVECINO	2820	0	8
8954	PARANA BRAVO	2805	0	8
8955	PASO DEL CISNERO	2846	0	8
8956	PASTOR BRITOS	2826	0	8
8957	PEHUAJO NORTE	2821	0	8
8958	PEHUAJO SUD	2854	0	8
8959	PERDICES	2823	0	8
8960	PUEBLO NUEVO	2820	0	8
8961	PUENTE PARANACITO	2823	0	8
8962	PUERTO PERAZZO	2846	0	8
8963	PUERTO SAN JUAN	2846	0	8
8964	PUERTO UNZUE	2820	0	8
8965	RINCON DEL GATO	2821	0	8
8966	SAN ANTONIO	2826	0	8
8967	SARANDI	2821	0	8
8968	TALITAS GUALEGUAYCHU	2852	0	8
8969	URDINARRAIN	2826	0	8
8970	VILLA ANTONY	2820	0	8
8971	VILLA DEL CERRO	2821	0	8
8972	VILLA FAUSTINO M PARERA	2824	0	8
8973	VILLA LILA	2820	0	8
8974	VILLA ROMERO	2824	0	8
8975	FERNANDEZ	2846	0	8
8976	IBICUY	2846	0	8
8977	MEDANOS	2848	0	8
8978	PARANACITO	2846	0	8
8979	PUERTO CONSTANZA	2846	0	8
8980	VILLA PARANACITO	2823	0	8
8981	ALCARACITO	3142	0	8
8982	ALCARAZ 2DO	3138	0	8
8983	PUEBLO ARRUA EST ALCARAZ	3138	0	8
8984	ALCARAZ 1RO	3144	0	8
8985	ALCARAZ NORTE	3136	0	8
8986	ALCARAZ SUD	3137	0	8
8987	BONALDI	3191	0	8
8988	BOVRIL	3142	0	8
8989	CALANDRIA	3191	0	8
8990	CENTENARIO PARANA	3190	0	8
8991	COLONIA ALCARCITO	3138	0	8
8992	COLONIA AVIGDOR	3142	0	8
8993	COLONIA BUENA VISTA	3190	0	8
8994	COLONIA FONTANINI	3191	0	8
8995	COLONIA LA DELIA	3190	0	8
8996	COLONIA LA PROVIDENCIA	3137	0	8
8997	COLONIA OFICIAL N 13	3191	0	8
8998	COLONIA OFICIAL N 14	3191	0	8
8999	COLONIA OFICIAL N 3	3190	0	8
9000	COLONIA OUGRIE	3138	0	8
9001	COLONIA VIRARO	3142	0	8
9002	CURUZU CHALI	3190	0	8
9003	DON GONZALO	3144	0	8
9004	EJIDO SUD	3190	0	8
9005	EL CARMEN	3190	0	8
9006	EL COLORADO	3192	0	8
9007	EL CORCOVADO	3142	0	8
9008	EL GAUCHO	3191	0	8
9009	EL QUEBRACHO	3192	0	8
9010	EL ROSARIO	3191	0	8
9011	EL SOLAR	3137	0	8
9012	ESTACAS	3191	0	8
9013	ESTACION ALCARAZ	3188	0	8
9014	FLORESTA	3191	0	8
9015	GONZALEZ	3191	0	8
9016	ISLA CURUZU CHALI	3190	0	8
9017	LA DILIGENCIA	3142	0	8
9018	LA PAZ	3190	0	8
9019	LAS LAGUNAS	3191	0	8
9020	LAS TOSCAS	3191	0	8
9021	MANANTIALES	3191	0	8
9022	MARTINETTI	3191	0	8
9023	MIRA MONTE	3191	0	8
9024	MONTIEL	3191	0	8
9025	OMBU	3190	0	8
9026	PIEDRAS BLANCAS	3129	0	8
9027	PILOTO AVILA	3190	0	8
9028	PRIMER CONGRESO	3142	0	8
9029	PUEBLO ELLISON	3142	0	8
9030	SAN ANTONIO	3191	0	8
9031	SAN GERONIMO	3191	0	8
9032	SAN GUSTAVO	3191	0	8
9033	SAN JUAN	3191	0	8
9034	SAN RAMIREZ	3191	0	8
9035	SANTA ELENA	3192	0	8
9036	SANTA MARIA	3191	0	8
9037	SARANDI CORA	3190	0	8
9038	SIR LEONARD	3142	0	8
9039	TACUARAS YACARE	3190	0	8
9040	VILLA BOREILO	3191	0	8
9041	VIZCACHERA	3127	0	8
9042	YACARE	3190	0	8
9043	YESO	3190	0	8
9044	20 DE SEPTIEMBRE	3158	0	8
9045	ARANGUREN	3162	0	8
9046	BETBEDER	3156	0	8
9047	CHIQUEROS	3158	0	8
9048	COLONIA ALGARRABITOS	3156	0	8
9049	COLONIA LA LLAVE	3158	0	8
9050	CRUCESITAS 3 SECCION	3151	0	8
9051	CRUCESITAS 7 SECCION	3109	0	8
9052	CRUCESITAS 8 SECCION	3177	0	8
9053	DON CRISTOBAL	3164	0	8
9054	DON CRISTOBAL 1 SECCION	3150	0	8
9055	DON CRISTOBAL 2 SECCION	3162	0	8
9056	EL PUEBLITO	3151	0	8
9057	EL TALLER	3117	0	8
9058	GOBERNADOR FEBRE	3151	0	8
9059	HERNANDEZ	3156	0	8
9060	LA COLINA	3158	0	8
9061	LA FAVORITA	3158	0	8
9062	LA LLAVE	3158	0	8
9063	LA MARUJA A	3151	0	8
9064	LAURENCENA	3150	0	8
9065	LOS PARAISOS	3158	0	8
9066	LUCAS GONZALEZ	3158	0	8
9067	LUCAS NORESTE	3216	0	8
9068	MONTOYA	3150	0	8
9069	NOGOYA	3150	0	8
9070	PUEBLITO	3164	0	8
9071	SAN LORENZO	3158	0	8
9072	SAUCE	3150	0	8
9073	SECCION URQUIZA	3109	0	8
9074	VILLA TRES DE FEBRERO	3150	0	8
9075	ALDEA MARIA LUISA	3114	0	8
9076	ALDEA SAN RAFAEL	3116	0	8
9077	ALDEA SANTA MARIA	3123	0	8
9078	ALMACEN CRISTIAN SCHUBERT	3111	0	8
9079	ANTONIO TOMAS SUD	3134	0	8
9080	ARROYO LAS TUNAS	3111	0	8
9081	AVENIDA EJERCITO PARANA	3100	0	8
9082	BAJADA GRANDE	3100	0	8
9083	BARRANCAS COLORADAS	3133	0	8
9084	CENTRO COMUNITARIO CNIA NUE	3118	0	8
9085	CERRITO	3122	0	8
9086	CHA	3111	0	8
9087	COLONIA ARGENTINA	3118	0	8
9088	COLONIA CELINA	3113	0	8
9089	COLONIA CENTENARIO	3109	0	8
9090	COLONIA CRESPO	3118	0	8
9091	COLONIA HERNANDARIAS	3129	0	8
9092	COLONIA HIGUERA	3138	0	8
9093	COLONIA MARIA LUISA	3114	0	8
9094	COLONIA NUEVA	3118	0	8
9095	COLONIA OFICIAL N 4	3134	0	8
9096	COLONIA REFFINO	3114	0	8
9097	COLONIA RIVADAVIA	3123	0	8
9098	COLONIA SAN JUAN	3123	0	8
9099	COLONIA SAN MARTIN	3113	0	8
9100	COLONIA SANTA LUISA	3133	0	8
9101	CORRALES NUEVOS	3100	0	8
9102	CRESPO	3116	0	8
9103	CRESPO NORTE	3118	0	8
9104	CURTIEMBRE	3113	0	8
9105	DESTACAMENTO GENERAL GUEMES	3125	0	8
9106	DISTRITO ESPINILLO	3107	0	8
9107	DISTRITO TALA	3118	0	8
9108	EL PALENQUE	3122	0	8
9109	EL PINGO	3132	0	8
9110	EL RAMBLON	3109	0	8
9111	GENERAL RACEDO	3122	0	8
9112	HASENKAMP	3134	0	8
9113	HERNANDARIAS	3127	0	8
9114	LA BALSA	3113	0	8
9115	LA COLMENA	3134	0	8
9116	LA JULIANA	3134	0	8
9117	LA PICADA	3118	0	8
9118	LA PICADA NORTE	3118	0	8
9119	LA VIRGINIA	3134	0	8
9120	LAS GARZAS	3136	0	8
9121	LAS TUNAS	3111	0	8
9122	LOS NARANJOS	3134	0	8
9123	MARIA GRANDE	3133	0	8
9124	MARIA GRANDE PRIMERA	3111	0	8
9125	MARIA GRANDE SEGUNDA	3133	0	8
9126	MORENO	3122	0	8
9127	ORO VERDE	3100	0	8
9128	PARACAO	3100	0	8
9129	PARANA	3100	0	8
9130	COLONIA AVELLANEDA	3107	0	8
9131	PUEBLO BELLOCQ	3136	0	8
9132	PUEBLO BRUGO	3125	0	8
9133	PUEBLO GENERAL PAZ	3123	0	8
9134	PUEBLO MORENO	3122	0	8
9135	PUERTO CURTIEMBRE	3113	0	8
9136	QUINTAS AL SUD	3100	0	8
9137	RAMBLON	3109	0	8
9138	RAMON A PARERA	3118	0	8
9139	SAN BENITO	3107	0	8
9140	SANTA LUISA	3133	0	8
9141	SANTA SARA	3134	0	8
9142	SAUCE MONTRULL	3118	0	8
9143	SAUCE PINTO	3107	0	8
9144	SEGUI	3117	0	8
9145	SOLA	3176	0	8
9146	SOSA	3133	0	8
9147	TABOSSI	3111	0	8
9148	TALITAS	3136	0	8
9149	TEZANOS PINTO	3114	0	8
9150	TIRO FEDERAL	3100	0	8
9151	TRES LAGUNAS	3113	0	8
9152	VIALE	3109	0	8
9153	VILLA FONTANA	3114	0	8
9154	VILLA GOB LUIS ETCHEVEHERE	3114	0	8
9155	VILLA HERNANDARIAS	3127	0	8
9156	VILLA SARMIENTO	3100	0	8
9157	VILLA URANGA	3100	0	8
9158	VILLA URQUIZA	3113	0	8
9160	COLONIA DUPORTAL	2845	0	8
9161	DURAZNO	3177	0	8
9163	GOBERNADOR ECHAGUE	2845	0	8
9164	GOBERNADOR MANSILLA	2845	0	8
9165	GOBERNADOR SOLA	3174	0	8
9166	GUARDAMONTE	3177	0	8
9167	LAS GUACHAS	3174	0	8
9168	GOBERNADOR MACIA	3177	0	8
9169	ROSARIO DEL TALA	3174	0	8
9170	SAUCE SUR	2845	0	8
9171	ACHIRAS	3246	0	8
9172	ALBERTO GERCHUNOFF	3170	0	8
9173	BALNEARIO PELAY	3260	0	8
9174	BASAVILBASO	3170	0	8
9175	CARAGUATA	3248	0	8
9176	CASEROS	3262	0	8
9177	CENTELLA	3261	0	8
9178	COLONIA 1 DE MAYO	3272	0	8
9179	COLONIA 5 ENSANCHE DE MAYO	3281	0	8
9180	COLONIA ARROYO URQUIZA	3281	0	8
9181	COLONIA CARMELO	3263	0	8
9182	COLONIA CRUCESITAS	3263	0	8
9183	COLONIA CUPALEN	3261	0	8
9184	COLONIA ELIA	3261	0	8
9185	COLONIA ELISA	3260	0	8
9186	COLONIA ENSANCHE MAYO	3263	0	8
9187	COLONIA GRAL URQUIZA	3263	0	8
9188	COLONIA LUCA	3261	0	8
9189	COLONIA LUCIENVILLE	3170	0	8
9190	COLONIA LUCRECIA	3248	0	8
9191	COLONIA N 1	3170	0	8
9192	COLONIA N 2	3170	0	8
9193	COLONIA N 3	3170	0	8
9194	COLONIA N 4	3170	0	8
9195	COLONIA NUEVA MONTEVIDEO	2828	0	8
9196	COLONIA OFICIAL N 6	3261	0	8
9197	COLONIA PERFECCION	3260	0	8
9198	COLONIA SAGASTUME	3246	0	8
9199	COLONIA SAN ANTONIO	3269	0	8
9200	COLONIA SAN CIPRIANO	3263	0	8
9201	COLONIA SAN JORGE	3263	0	8
9202	COLONIA SANTA ANA	3261	0	8
9203	COLONIA SANTA TERESITA	3263	0	8
9204	COLONIA TRES DE FEBRERO	3265	0	8
9205	CONCEPCION DEL URUGUAY	3260	0	8
9206	CUPALEN	3261	0	8
9207	ESTACION URQUIZA	3248	0	8
9208	ESTACION URUGUAY	3260	0	8
9209	GENACITO	3272	0	8
9210	GRUPO ACHIRAS	3246	0	8
9211	HERRERA	3272	0	8
9212	LA MARIA LUISA	3261	0	8
9213	LA TIGRESA	3260	0	8
9214	LA ZELMIRA	2820	0	8
9215	LAS MERCEDES	3272	0	8
9216	LAS MOSCAS	3244	0	8
9217	LAS ROSAS	2828	0	8
9218	LIBAROS	3244	0	8
9219	LIEBIG	3281	0	8
9220	MAC DOUGALL	3244	0	8
9221	MANGRULLO	3248	0	8
9222	NICOLAS HERRERA	3272	0	8
9223	PALACIO SAN JOSE	3262	0	8
9224	1 DE MAYO	3263	0	8
9225	PRONUNCIAMIENTO	3263	0	8
9226	ROCAMORA	3172	0	8
9227	SAGASTUME	3246	0	8
9228	SAN CIPRIANO	3263	0	8
9229	SAN JUSTO	3260	0	8
9230	SAN MARTIN	3111	0	8
9231	SANTA ANITA	3248	0	8
9232	SANTA ROSA	3248	0	8
9233	TALITA	3261	0	8
9234	TOMAS ROCAMORA	3261	0	8
9235	VILLA MANTERO	3272	0	8
9236	VILLA SAN MARCIAL	3248	0	8
9237	VILLA SAN MIGUEL	3272	0	8
9238	VILLA UDINE	3262	0	8
9239	ANTELO	3151	0	8
9240	CHILCAS	3162	0	8
9241	COLONIA ANGELA	3151	0	8
9242	HINOJAL	3162	0	8
9243	ISLA EL PILLO	3101	0	8
9244	LAGUNA DEL PESCADO	3155	0	8
9245	LOS GANSOS	3101	0	8
9246	MOLINO DOLL	3101	0	8
9247	MONTOYA	3151	0	8
9248	PAJONAL	3101	0	8
9249	PUEBLITO NORTE	3155	0	8
9250	PUENTE VICTORIA	3153	0	8
9251	QUINTO CUARTEL VICTORIA	3153	0	8
9252	RINCON DEL DOLL	3101	0	8
9253	TRES ESQUINAS	3156	0	8
9254	VICTORIA	3153	0	8
9255	BARON HIRSCH	3246	0	8
9256	BELEZ	3252	0	8
9257	BENITEZ	3216	0	8
9258	CAMPO MORENO	3252	0	8
9259	CLARA	3252	0	8
9260	COLONIA ACHIRAS	3246	0	8
9261	COLONIA BARON HIRSCH	3246	0	8
9262	COLONIA BELEZ	3252	0	8
9263	COLONIA BERRO	3128	0	8
9264	COLONIA CARLOS CALVO	3252	0	8
9265	COLONIA CARMEL	3246	0	8
9266	COLONIA HEBREA	3216	0	8
9267	COLONIA IDA	3246	0	8
9268	COLONIA LA ARMONIA	3216	0	8
9269	COLONIA LA ESPERANZA	3216	0	8
9270	COLONIA LA MORA	3216	0	8
9271	COLONIA LA ROSADA	3252	0	8
9272	COLONIA LOPEZ	3218	0	8
9273	COLONIA MIGUEL	3246	0	8
9274	COLONIA NUEVA ALEMANIA	3218	0	8
9275	COLONIA PERLIZA	3246	0	8
9276	COLONIA SAN JORGE	3252	0	8
9277	COLONIA SAN MANUEL	3246	0	8
9278	COLONIA SANDOVAL	3252	0	8
9279	COLONIA SONENFELD	3246	0	8
9280	COLONIA VELEZ	3252	0	8
9281	COSTA DEL PAYTICU	3138	0	8
9282	DESPARRAMADOS	3246	0	8
9283	EBEN HOROSCHA	3246	0	8
9284	EL AVESTRUZ	3216	0	8
9285	ING MIGUEL SAJAROFF	3246	0	8
9286	JUBILEO	3254	0	8
9287	LA ENCIERRA	3144	0	8
9288	LA ESTRELLA	3254	0	8
9289	LA PAMPA	3254	0	8
9290	LOS OMBUES	3241	0	8
9291	LUCAS SUR 1RA SECCION	3241	0	8
9292	MAURICIO RIBOLE	3216	0	8
9293	PARAJE GUAYABO	3240	0	8
9294	RAICES OESTE	3241	0	8
9295	RINCON DE MOJONES	3241	0	8
9296	ROSPINA	3246	0	8
9297	SAN VICENTE	3252	0	8
9298	LUCAS SUR 2DA SECCION	3240	0	8
9299	SPINDOLA	3252	0	8
9300	VERGARA	3252	0	8
9301	VILLA CLARA	3252	0	8
9302	VILLA DOMINGUEZ	3246	0	8
9303	VILLAGUAY	3240	0	8
9304	VILLAGUAY ESTE	3244	0	8
9305	VILLAGUAYCITO	3218	0	8
9306	VIRANO	3142	0	8
9307	DOS HERMANAS	3366	0	14
9308	25 DE MAYO	3363	0	14
9309	ACARAGUA	3361	0	14
9310	ALBA POSSE	3363	0	14
9311	BARTOLITO	3363	0	14
9312	COLONIA ALICIA	3363	0	14
9313	COLONIA AURORA	3363	0	14
9314	COLONIA EL DORADILLO	3363	0	14
9315	COLONIA EL PROGRESO	3363	0	14
9316	DESPLAYADA	3363	0	14
9317	EL MACACO	3363	0	14
9318	EL SALTI	3363	0	14
9319	EL SALTITO	3363	0	14
9320	MAI BAO	3363	0	14
9322	PUERTO ALICIA	3363	0	14
9323	PUERTO AURORA	3363	0	14
9324	PUERTO INSUA	3363	0	14
9325	PUERTO LONDERO	3363	0	14
9326	PUERTO SAN MARTIN	3363	0	14
9327	SAN CARLOS	3363	0	14
9328	SAN FRANCISCO DE ASIS	3363	0	14
9329	SANTA RITA	3363	0	14
9330	TORTA QUEMADA	3363	0	14
9331	TRES BOCAS	3363	0	14
9332	VILLA VILMA	3363	0	14
9333	VILLAFA	3363	0	14
9334	APOSTOLES	3350	0	14
9335	ARROYO TUNITAS	3350	0	14
9336	AZARA	3351	0	14
9337	CAMPO RICHARDSON	3350	0	14
9338	CARRILLO VIEJO	3350	0	14
9339	CENTINELA	3306	0	14
9340	CHEROGUITA	3358	0	14
9341	CHIRIMAY	3350	0	14
9342	COLONIA APOSTOLES	3350	0	14
9343	EL RANCHO	3358	0	14
9344	ENSANCHE ESTE	3350	0	14
9345	ENSANCHE NORTE	3350	0	14
9346	ESTACION APOSTOLES	3358	0	14
9347	LA CAPILLA	3350	0	14
9348	LAS TUNAS	3350	0	14
9349	LOTE 117	3351	0	14
9350	MONTE HERMOSO	3351	0	14
9351	NACIENTES DEL TUNAR	3350	0	14
9352	PINDAPOY	3306	0	14
9353	RINCON DE CHIMTRAY	3350	0	14
9354	SAN JOSE	3306	0	14
9355	SAN JUAN DE LA SIERRA	3306	0	14
9356	SIERRAS SAN JUAN	3306	0	14
9357	TIGRE	3350	0	14
9358	TRES CAPONES	3353	0	14
9361	ARISTOBULO DEL VALLE	3364	0	14
9362	BERNARDINO RIVADAVIA	3364	0	14
9363	CAINGUAS	3364	0	14
9364	CAMPO GRANDE	3362	0	14
9365	COLONIA SEGUI	3361	0	14
9366	DESTACAMENTO BOSQUES	3362	0	14
9367	2 DE MAYO	3364	0	14
9368	EL TIGRE	3364	0	14
9369	FRONTERAS	3364	0	14
9370	KILOMETRO 17 RUTA 8	3362	0	14
9371	PARAJE LUCERO	3364	0	14
9372	PINDAITI	3364	0	14
9373	PINDAYTI	3364	0	14
9374	1 DE MAYO	3362	0	14
9375	SALTO ENCANTADO	3364	0	14
9376	ARROYO MAGDALENA	3317	0	14
9377	ARROYO PASTORA	3316	0	14
9378	ARROYO TOMAS	3309	0	14
9379	BA	3317	0	14
9380	BELLA VISTA	3309	0	14
9381	BONPLAND	3317	0	14
9382	BONPLAND NORTE	3318	0	14
9383	BRAZO DEL TACUARUZU	3309	0	14
9384	CAAPORA	3316	0	14
9385	CAMPI	3317	0	14
9386	CAMPI	3309	0	14
9387	CANDELARIA	3308	0	14
9388	CAPUERON	3309	0	14
9389	CERRO CORA	3309	0	14
9390	COLONIA ALEMANA	3309	0	14
9391	COLONIA ARISTOBULO DEL VALLE	3317	0	14
9392	COLONIA GUARANI	3309	0	14
9393	COLONIA MARTIRES	3318	0	14
9394	COLONIA PROFUNDIDAD	3308	0	14
9395	LA INVERNADA	3309	0	14
9396	LAS QUEMADAS	3309	0	14
9397	LORETO	3316	0	14
9398	LOTE 12	3316	0	14
9399	NACIENTES DEL ISABEL	3309	0	14
9400	PICADA FINLANDESA	3317	0	14
9401	PICADA PORTUGUESA	3317	0	14
9402	PICADA SAN JAVIER	3317	0	14
9403	PICADA SAN MARTIN	3317	0	14
9404	PROFUNDIDAD	3308	0	14
9405	PUERTO LA MINA	3308	0	14
9406	RINCON DE BONPLAND	3317	0	14
9407	RUINAS DE LORETO	3316	0	14
9408	SANTA ANA	3316	0	14
9409	SOL DE MAYO	3308	0	14
9410	TACUARUZU	3309	0	14
9411	TEYUGUARE	3322	0	14
9412	TIMBAUBA	3317	0	14
9413	TRATADO DE PAZ	3317	0	14
9414	VILLA VENECIA	3309	0	14
9415	YABEBIRI	3308	0	14
9416	YACUTINGA	3308	0	14
9417	YERBAL MAMBORETA	3316	0	14
9418	BARRIO DON SANTIAGO	3304	0	14
9419	DAMUS	3306	0	14
9420	DOMINGO BARTHE	3304	0	14
9421	FACHINAL	3304	0	14
9422	GARUPA	3304	0	14
9423	GARUPA NORTE	3304	0	14
9424	KILOMETRO 538	3306	0	14
9425	KILOMETRO 546	3306	0	14
9426	KILOMETRO 577	3304	0	14
9427	MANANTIALES	3306	0	14
9428	MIGUEL LANUS	3304	0	14
9429	NUEVA VALENCIA	3306	0	14
9430	PARADA LEIS	3306	0	14
9432	PUENTE NACIONAL	3306	0	14
9433	RINCON DE BUGRES	3306	0	14
9434	SAN ANDRES	3304	0	14
9435	SAN ISIDRO	3300	0	14
9436	SAN JUAN	3306	0	14
9437	SANTA INES	3304	0	14
9438	SIERRA DE SAN JOSE	3306	0	14
9439	TORORO	3306	0	14
9440	VILLA LANUS	3300	0	14
9441	VILLALONGA	3300	0	14
9442	ARRECHEA	3355	0	14
9443	ARROYO PERSIGUERO	3355	0	14
9444	ARROYO SANTA MARIA	3353	0	14
9445	BARRA CONCEPCION	3355	0	14
9446	BRETES MARTIRES	3355	0	14
9447	COLONIA CAPON BONITO	3355	0	14
9448	COLONIA MARTIR SANTA MARIA	3355	0	14
9449	COLONIA SAN JAVIER	3355	0	14
9450	COLONIA SANTA MARIA	3353	0	14
9451	CONCEPCION DE LA SIERRA	3355	0	14
9452	EL PERSIGUERO	3355	0	14
9453	OJO DE AGUA	3328	0	14
9454	PASO DEL ARROYO PERSIGUERO	3355	0	14
9455	PASO PORTE	3355	0	14
9456	PERSIGUERO	3355	0	14
9457	PUERTO CONCEPCION	3355	0	14
9458	PUERTO SAN LUCAS	3355	0	14
9459	SAN ISIDRO	3355	0	14
9460	SAN LUCAS	3355	0	14
9461	SANTA MARIA LA MAYOR	3355	0	14
9462	SANTA MARIA MARTIR	3355	0	14
9463	ISLA SAN LUCAS	3355	0	14
9464	9 DE JULIO KILOMETRO 20	3380	0	14
9465	COLONIA VICTORIA	3382	0	14
9466	ELDORADO	3380	0	14
9468	KILOMETRO 10	3380	0	14
9469	MARIA MAGDALENA	3381	0	14
9470	PATI CUA	3382	0	14
9471	PUERTO DELICIA	3381	0	14
9472	PUERTO PINARES	3382	0	14
9473	PUERTO VICTORIA	3382	0	14
9474	SANTIAGO DE LINIERS	3381	0	14
9475	VILLA ROULET	3382	0	14
9476	ALMIRANTE BROWN	3366	0	14
9477	BARRACON	3366	0	14
9478	BERNARDO DE IRIGOYEN	3366	0	14
9479	CABURE	3371	0	14
9480	COLONIA MANUEL BELGRANO	3316	0	14
9481	DESEADO	3384	0	14
9482	EL PORVENIR	3374	0	14
9483	INTEGRACION	3366	0	14
9484	PI	3366	0	14
9485	PI	3366	0	14
9486	SAN ANTONIO	3366	0	14
9487	CAPITAN ANTONIO MORALES	3364	0	14
9488	COMANDANTE ANDRESITO	3364	0	14
9489	EL SOBERBIO	3364	0	14
9490	FRACRAN	3364	0	14
9491	MONTEAGUDO	3364	0	14
9492	SAN VICENTE	3364	0	14
9493	CATARATAS DEL IGUAZU	3372	0	14
9494	PUERTO ESPERANZA	3378	0	14
9495	GOBERNADOR LANUSSE	3376	0	14
9496	LA PLANTADORA	3322	0	14
9497	LIBERTAD	3374	0	14
9498	PUERTO AGUIRRE	3370	0	14
9499	PUERTO BEMBERG	3374	0	14
9500	PUERTO BOSSETTI	3374	0	14
9501	PUERTO CAROLINA	3370	0	14
9502	PUERTO ERRECABORDE	3374	0	14
9503	PUERTO IGUAZU	3370	0	14
9504	PUERTO PENINSULA	3370	0	14
9505	PUERTO URUGUAY	3370	0	14
9506	22 DE DICIEMBRE	3378	0	14
9507	WANDA	3376	0	14
9508	ARROYO DEL MEDIO	3313	0	14
9509	ARROYO ISABEL	3311	0	14
9510	CAMPO TORNQUINST	3315	0	14
9511	CERRO AZUL	3313	0	14
9512	COLONIA ALBERDI	3311	0	14
9513	COLONIA ALMAFUERTE	3317	0	14
9514	COLONIA CAAGUAZU	3315	0	14
9515	COLONIA FINLANDESA	3317	0	14
9516	COLONIA POLACA	3313	0	14
9517	DOS ARROYOS	3315	0	14
9518	EL CHATON	3315	0	14
9519	GRAL GUEMES	3313	0	14
9520	LEANDRO N ALEM	3315	0	14
9521	MECKING	3315	0	14
9522	OLEGARIO VICTOR ANDRADE	3311	0	14
9523	ONCE VUELTAS	3315	0	14
9524	PICADA BELGRANO	3315	0	14
9525	PICADA BONPLAND	3315	0	14
9526	PICADA ESPA	3315	0	14
9527	GOBERNADOR LOPEZ	3315	0	14
9528	PICADA IGLESIA	3315	0	14
9529	PICADA LIBERTAD	3315	0	14
9530	PICADA POLACA	3313	0	14
9531	PICADA POZO FEO	3315	0	14
9532	PICADA RUSA	3315	0	14
9533	PICADA SAN JAVIER	3315	0	14
9534	PICADA SUR MECKING	3315	0	14
9535	VILLA LIBERTAD	3315	0	14
9536	CAPIOVI	3332	0	14
9537	CAPIOVISI	3334	0	14
9538	CAPIVU	3332	0	14
9539	COLONIA LA OTILIA	3332	0	14
9540	COLONIA ORO VERDE	3334	0	14
9541	CU	3334	0	14
9542	EL ALCAZAR	3384	0	14
9543	GARUHAPE	3334	0	14
9544	LINEA CUCHILLA	3334	0	14
9545	LOS TEALES	3328	0	14
9546	PUERTO INGENIERO MORANDI	3332	0	14
9547	PUERTO LEONI	3332	0	14
9548	PUERTO MBOPICUA	3334	0	14
9549	PUERTO MINERAL	3332	0	14
9550	PUERTO ORO VERDE	3334	0	14
9551	PUERTO PARANAY	3384	0	14
9552	PUERTO RICO	3334	0	14
9553	PUERTO SAN ALBERTO	3334	0	14
9554	PUERTO TIGRE	3334	0	14
9555	RUIZ DE MONTOYA	3334	0	14
9556	SAN ALBERTO	3334	0	14
9557	SAN GOTARDO	3332	0	14
9558	SAN MIGUEL	3334	0	14
9559	SAN SEBASTIAN	3334	0	14
9560	3 DE MAYO	3334	0	14
9561	MBOPICUA	3332	0	14
9562	BARRANCON	3384	0	14
9563	CARAGUATAY	3386	0	14
9564	GUARAYPO	3384	0	14
9565	ITA CURUZU	3384	0	14
9566	LARRAQUE	3384	0	14
9567	LINEA DE PERAY	3384	0	14
9568	MONTECARLO	3384	0	14
9569	PARANAY	3386	0	14
9570	PUERTO ALCAZAR	3386	0	14
9571	PUERTO AVELLANEDA	3384	0	14
9572	PUERTO CARAGUATAY	3386	0	14
9573	PUERTO LAHARRAGUE	3384	0	14
9574	PUERTO PIRAY	3381	0	14
9575	TARUMA	3386	0	14
9576	PIRAY	3381	0	14
9577	ARROYO FEDOR	3360	0	14
9578	BARRA BONITA	3360	0	14
9579	BAYO TRONCHO	3360	0	14
9580	CAMPO RAMON	3361	0	14
9581	CAMPO VIERA	3362	0	14
9582	COLONIA ALBERDI	3361	0	14
9583	COLONIA CHAPA	3361	0	14
9584	COLONIA YABEBIRI	3316	0	14
9585	FLORENTINO AMEGHINO	3361	0	14
9586	GENERAL ALVEAR	3361	0	14
9587	GUARANI	3361	0	14
9588	GUAYABERA	3361	0	14
9589	KILOMETRO 4	3361	0	14
9590	KILOMETRO 8	3361	0	14
9591	LOS HELECHOS	3361	0	14
9592	OBERA	3360	0	14
9593	PANAMBI	3361	0	14
9594	PICADA SAN MARTIN	3360	0	14
9595	PICADA SUECA	3361	0	14
9596	PICADA YAPEYU	3361	0	14
9597	PUEBLO SALTO	3360	0	14
9598	SAMAMBAYA	3361	0	14
9599	SAN MARTIN	3360	0	14
9600	VILLA ARMONIA	3361	0	14
9601	VILLA BLANQUITA	3360	0	14
9602	VILLA BONITA	3361	0	14
9603	VILLA SVEA	3361	0	14
9604	YAPEYU CENTRO	3361	0	14
9605	APARICIO CUE	3322	0	14
9606	ARROYO YABEBIRI	3322	0	14
9607	BARRANCON	3322	0	14
9608	COLONIA DOMINGO SAVIO	3322	0	14
9609	COLONIA JAPONESA	3328	0	14
9610	COLONIA LEIVA	3326	0	14
9611	COLONIA 	3328	0	14
9612	COLONIA POLANA	3326	0	14
9613	COLONIA ROCA	3327	0	14
9614	COLONIA ROCA CHICA	3322	0	14
9615	COLONIA SAN IGNACIO	3322	0	14
9616	COLONIA YACUTINGA	3317	0	14
9617	CORPUS	3327	0	14
9618	EL 26	3326	0	14
9619	EL DESTIERRO	3326	0	14
9620	EL TRIUNFO	3322	0	14
9621	ESTACION EXPERIMENTAL DE LORET	3322	0	14
9622	GOBERNADOR ROCA	3324	0	14
9623	HEKENAN	3327	0	14
9624	HIPOLITO YRIGOYEN	3328	0	14
9625	INVERNADA SAN IGNACIO	3322	0	14
9626	ISLA ARGENTINA	3353	0	14
9627	JARDIN AMERICA	3328	0	14
9628	LA HORQUETA	3322	0	14
9629	LA OTILIA	3328	0	14
9630	LOTE 25	3327	0	14
9631	LOTE 5	3318	0	14
9632	MANIS	3327	0	14
9633	MARIA ANTONIA	3322	0	14
9634	OASIS	3328	0	14
9635	OBLIGADO	3327	0	14
9636	OTILIA	3328	0	14
9637	PASTOREO	3322	0	14
9638	PUERTO CAZADOR	3327	0	14
9639	PUERTO CHU	3322	0	14
9640	PUERTO DOCE	3327	0	14
9641	PUERTO ESPA	3326	0	14
9642	PUERTO GISELA	3326	0	14
9643	PUERTO HARDELASTE	3327	0	14
9644	PUERTO MENOCHIO	3326	0	14
9645	PUERTO NARANJITO	3326	0	14
9646	PUERTO SAN IGNACIO	3322	0	14
9647	PUERTO TABAY	3328	0	14
9648	PUERTO VIEJO	3322	0	14
9649	PUERTO YABEBIRI	3322	0	14
9650	ROCA CHICA	3324	0	14
9651	SAN IGNACIO	3322	0	14
9652	SANTO PIPO	3326	0	14
9653	BUENA VISTA	3357	0	14
9654	COLONIA CUMANDAY	3357	0	14
9655	COSTA PORTERA	3357	0	14
9656	FRANCES	3357	0	14
9657	GUERRERO	3357	0	14
9658	INVERNADA CHICA	3353	0	14
9659	INVERNADA GRANDE	3353	0	14
9660	ITACARUARE	3353	0	14
9661	KILOMETRO 26	3357	0	14
9662	KILOMETRO 78	3315	0	14
9663	LOS GALPONES	3353	0	14
9664	MACHADI	3353	0	14
9665	MOJON GRANDE	3315	0	14
9666	PICADA SAN JAVIER	3353	0	14
9667	PUERTO ROSARIO	3357	0	14
9668	PUERTO RUBEN	3357	0	14
9669	PUERTO SALTI	3357	0	14
9670	RINCON DE LOPEZ	3353	0	14
9671	RINCON DEL GUERRERO	3357	0	14
9672	SAN JAVIER	3357	0	14
9673	TRES ESQUINAS	3357	0	14
9674	BARRACON	3364	0	14
9675	CAMPANA	3361	0	14
9676	CRUCE CABALLERO	3364	0	14
9677	EL PARAISO	3351	0	14
9678	PIRAY MINI	3366	0	14
9679	SAN PEDRO	3364	0	14
9680	TOBUNAS	3364	0	14
9681	ARROYITO	3448	0	7
9682	BELLA VISTA	3432	0	7
9683	CARRIZAL NORTE	3433	0	7
9684	CEBOLLAS	3432	0	7
9685	COLONIA 3 DE ABRIL	3433	0	7
9686	COLONIA PROGRESO	3433	0	7
9687	DESMOCHADO	3441	0	7
9688	EL CARRIZAL	3432	0	7
9689	ISLA ALTA	3449	0	7
9690	PROGRESO	3432	0	7
9691	RAICES	3433	0	7
9692	VILLA ROLLET	3432	0	7
9693	YAGUA RINCON	3432	0	7
9694	ARERUNGUA	3481	0	7
9695	BERON DE ASTRADA	3481	0	7
9696	COLONIA BERON DE ASTRADA	3197	0	7
9697	MARTINEZ CUE	3481	0	7
9699	PASO POTRERO	3481	0	7
9700	TORO PICHAY	3481	0	7
9701	VALENCIA	3481	0	7
9702	YAHAPE	3412	0	7
9703	CORRIENTES	3400	0	7
9704	LAGUNA BRAVA	3401	0	7
9705	PARAJE EL CARMEN	3199	0	7
9706	RIACHUELO	3416	0	7
9707	RIACHUELO SUD	3416	0	7
9708	SAN CAYETANO	3401	0	7
9709	BAJO GUAZU	3421	0	7
9710	BATEL	3421	0	7
9711	CARAMBOLA	3423	0	7
9712	COLONIA DORA ELENA	3421	0	7
9713	COLONIA LA HABANA	3423	0	7
9714	COLONIA LUCERO	3421	0	7
9715	COLONIA SANTA ROSA	3421	0	7
9716	CONCEPCION	3423	0	7
9717	COSTA DEL BATEL	3423	0	7
9718	EL BUEN RETIRO	3423	0	7
9719	EL CARMEN	3485	0	7
9720	EL PORVENIR	3423	0	7
9721	SAN ANTONIO DEL CAIMAN	3485	0	7
9722	SANTA ROSA	3421	0	7
9723	TABAY	3421	0	7
9724	TALITA CUE	3423	0	7
9725	TARTAGUITO	3423	0	7
9726	TATACUA	3421	0	7
9727	TRES HERMANAS	3423	0	7
9728	VIRGEN MARIA	3423	0	7
9729	YAGUARU	3423	0	7
9730	LA CRIOLLA	3342	0	7
9731	ABALO	3466	0	7
9732	ABELI	3466	0	7
9733	ABO NEZU	3461	0	7
9734	AGUAY	3461	0	7
9735	ARROYO CASCO	3465	0	7
9736	ARROYO GARAY	3185	0	7
9737	ARROYO SECO	3641	0	7
9738	BAIBIENE	3466	0	7
9739	BASUALDO	3185	0	7
9740	CASUALIDAD	3461	0	7
9741	CAZADORES CORRENTINOS	3465	0	7
9742	COLONIA ACU	3460	0	7
9743	COLONIA BASUALDO	3185	0	7
9744	COLONIA CHIRCAL	3461	0	7
9745	COLONIA PAIRIRI	3185	0	7
9746	COSTA ARROYO GARAY	3185	0	7
9747	CURUZU CUATIA	3460	0	7
9748	EL CEIBO	3460	0	7
9749	EL CERRO	3461	0	7
9750	EL LOTO	3466	0	7
9751	EMILIO R CONI	3465	0	7
9752	ESPERANZA	3461	0	7
9753	ESPINILLO	3460	0	7
9754	ESTRELLA	3461	0	7
9755	IBAVIYU	3466	0	7
9756	KILOMETRO 405	3460	0	7
9757	LOBORY	3460	0	7
9758	MINUANES	3465	0	7
9759	PAGO LARGO	3465	0	7
9760	PARAJE PORTILLO	3185	0	7
9761	PEDRO DIAZ COLODRERO	3185	0	7
9762	PERUGORRIA	3461	0	7
9763	RINCON DE TUNAS	3185	0	7
9764	SAN JUAN	3466	0	7
9765	SARANDI	3460	0	7
9766	PASO TALA	3461	0	7
9767	TIERRA COLORADA	3460	0	7
9768	TUNITAS	3460	0	7
9769	VACA CUA	3460	0	7
9770	YAGUARY	3460	0	7
9771	ARROYO SOLIS	3401	0	7
9772	BARTOLOME MITRE	3418	0	7
9773	COSTA GRANDE	3425	0	7
9774	EL POLLO	3401	0	7
9775	EL SOMBRERO	3416	0	7
9776	EMPEDRADO	3418	0	7
9777	KILOMETRO 451	3418	0	7
9778	KILOMETRO 462	3418	0	7
9779	KILOMETRO 494	3416	0	7
9780	KILOMETRO 501	3416	0	7
9781	KILOMETRO 504	3416	0	7
9782	LOMAS DE EMPEDRADO	3418	0	7
9783	MANUEL DERQUI	3416	0	7
9784	VILLA SAN ISIDRO	3401	0	7
9785	ABRA GUAZU	3197	0	7
9786	ALEJANDRIA	3197	0	7
9787	ARROYO SARANDI	3194	0	7
9788	ARROYO SATURNO	3197	0	7
9789	ARROYO SORO	3194	0	7
9790	ARROYO VEGA	3196	0	7
9791	BORANZA	3197	0	7
9792	BUENA VISTA	3196	0	7
9793	CAMPO BORDON	3196	0	7
9794	CAMPO CAFFERATA	3196	0	7
9795	CAMPO DE CARLOS	3196	0	7
9796	CAMPO MORATO	3196	0	7
9797	CAMPO ROMERO	3196	0	7
9798	CAMPO SAN JACINTO	3196	0	7
9799	CHACRAS NORTE	3196	0	7
9800	CHACRAS SECCION EJIDO	3196	0	7
9801	CHACRAS SUD	3196	0	7
9802	CORONEL ABRAHAM SCHWEIZER	3197	0	7
9803	CU	3197	0	7
9804	EL COQUITO	3197	0	7
9805	EL PARQUE	3196	0	7
9806	EL PORVENIR	3197	0	7
9807	EL YAPU	3197	0	7
9808	ESQUINA	3196	0	7
9809	ESTERO GRANDE	3197	0	7
9810	ESTERO SAUCE	3197	0	7
9811	ESTERO YATAY	3197	0	7
9812	GUAYQUIRARO	3194	0	7
9813	INGA	3196	0	7
9814	JESUS MARIA	3196	0	7
9815	LA AMISTAD	3196	0	7
9816	LA CONCEPCION	3454	0	7
9817	LA EMILIA	3196	0	7
9818	LA FLORENCIA	3197	0	7
9819	LA ISABEL	3196	0	7
9820	LA MOROCHA	3196	0	7
9821	LA NENA	3197	0	7
9822	LA PALMERA	3197	0	7
9823	LAS CUCHILLAS	3463	0	7
9824	LIBERTAD	3196	0	7
9825	LIBERTADOR	3197	0	7
9826	LOS ALGARROBOS	3197	0	7
9827	LOS EUCALIPTOS	3197	0	7
9828	LOS FLOTADORES	3196	0	7
9829	LOS LAURELES	3199	0	7
9830	LOS MEDIOS	3197	0	7
9831	LOS PARAISOS	3197	0	7
9832	MALVINAS	3199	0	7
9833	MALVINAS CENTRO	3199	0	7
9834	OMBU SOLO	3196	0	7
9835	PARAJE POTON	3197	0	7
9836	PASO ALGARROBO	3197	0	7
9837	PASO CEJAS	3197	0	7
9838	PUEBLITO	3196	0	7
9839	RINCON DE SARANDY	3197	0	7
9840	SAN ANTONIO	3196	0	7
9841	SAN FERNANDO	3196	0	7
9842	SAN FRANCISCO	3196	0	7
9843	SAN GUSTAVO	3196	0	7
9844	SAN JACINTO	3196	0	7
9845	SAN JUAN	3196	0	7
9846	SAN LORENZO	3197	0	7
9847	SAN LUIS	3197	0	7
9848	SAN MARTIN	3197	0	7
9849	SAN ROQUE	3196	0	7
9850	SAN VICENTE	3196	0	7
9851	SANTA ANA	3197	0	7
9852	SANTA CECILIA	3196	0	7
9853	SANTA ISABEL	3197	0	7
9854	SANTA LIBRADA	3196	0	7
9855	SANTA RITA	3196	0	7
9856	SARANDI	3196	0	7
9857	TORO CHIPAY	3197	0	7
9858	TRES BOCAS	3194	0	7
9859	VILLA CRISTIA	3196	0	7
9860	ALTAMIRA	3344	0	7
9861	ALVEAR	3344	0	7
9862	ARROYO MENDEZ	3344	0	7
9863	BATAY	3344	0	7
9864	CAMBARA	3344	0	7
9865	CONCEPCION	3344	0	7
9866	CUAY CHICO	3344	0	7
9867	2 DE JULIO	3344	0	7
9868	EL PARAISO	3344	0	7
9869	ESFADAL	3344	0	7
9870	ESPINILLAR	3344	0	7
9871	FLORIDA	3344	0	7
9872	KILOMETRO 393	3344	0	7
9873	KILOMETRO 394	3344	0	7
9874	KILOMETRO 396	3344	0	7
9875	LA BLANQUEADA	3344	0	7
9876	LA CHIQUITA	3344	0	7
9877	LA ELSA	3344	0	7
9878	LA ELVA	3344	0	7
9879	MORICA	3344	0	7
9880	PALMITA	3344	0	7
9881	PANCHO CUE	3344	0	7
9882	PIRACU	3344	0	7
9883	PIRAYU	3344	0	7
9884	SAN CARLOS	3344	0	7
9885	SAN JOSE	3344	0	7
9886	SAN JUAN	3344	0	7
9887	SAN PEDRO	3344	0	7
9888	SANTA ANA	3344	0	7
9889	SANTA ISABEL	3344	0	7
9890	SANTA RITA	3344	0	7
9891	TAMBO NUEVO	3344	0	7
9892	TINGUI	3344	0	7
9893	TORRENT	3344	0	7
9894	TRES CAPONES	3344	0	7
9895	AGUAY	3407	0	7
9896	ALGARROBAL	3480	0	7
9897	ALGARROBALES	3407	0	7
9898	ALTAMORA PARADA	3407	0	7
9899	ANGOSTURA	3481	0	7
9900	AYALA CUE	3407	0	7
9901	BLANCO CUE	3480	0	7
9902	CAA CATI	3407	0	7
9903	CAPILLITA	3407	0	7
9904	CERRITO	3405	0	7
9905	COLONIA BRANCHI	3480	0	7
9906	COLONIA ROMERO	3481	0	7
9907	EL PALMAR	3481	0	7
9908	IBAHAY	3480	0	7
9909	ITA IBATE	3480	0	7
9910	LA LOMA	3480	0	7
9911	LOMAS DE VALLEJOS	3405	0	7
9912	NTRA SRA DEL ROS DE CAA CATI	3407	0	7
9913	PALMAR GRANDE	3405	0	7
9914	PARAJE BARRANQUITAS	3480	0	7
9915	PASO FLORENTIN	3407	0	7
9916	PUISOYE	3405	0	7
9917	ROMERO	3407	0	7
9918	SANTA ISABEL	3480	0	7
9919	TACUARACARENDY	3481	0	7
9920	TACUARAL	3405	0	7
9921	TALATY	3405	0	7
9922	TILITA	3480	0	7
9923	TOLATU	3405	0	7
9924	VERGARA	3405	0	7
9925	VERGARA LOMAS	3405	0	7
9926	ZAPALLAR	3405	0	7
9927	ALAMO	3450	0	7
9928	ARROYO CARANCHO	3450	0	7
9929	BALENGO	3450	0	7
9930	BA	3454	0	7
9931	BUENA ESPERANZA	3454	0	7
9932	BUENA VISTA	3454	0	7
9933	CAMPO ARAUJO	3450	0	7
9934	CAMPO ESCALADA	3450	0	7
9935	CASUALIDAD	3450	0	7
9936	COLONIA CAROLINA	3451	0	7
9937	GOYA	3450	0	7
9938	IFRAN	3453	0	7
9939	ISABEL VICTORIA	3453	0	7
9940	LUJAN	3450	0	7
9941	MARUCHAS	3451	0	7
9942	MORA	3451	0	7
9943	PAGO REDONDO	3451	0	7
9944	PASO RUBIO	3451	0	7
9945	PASO SAN JUAN	3454	0	7
9946	PASO SANTA ROSA	3450	0	7
9947	PUERTO GOYA	3451	0	7
9948	SAN ALEJO	3454	0	7
9949	SAN ISIDRO	3454	0	7
9950	SAN MANUEL	3454	0	7
9951	SAN MARCOS	3454	0	7
9952	SAN MARTIN	3450	0	7
9953	SANTILLAN	3450	0	7
9954	TRES BOCAS	3454	0	7
9955	ABRA	3414	0	7
9956	CURUZU	3414	0	7
9957	GUAYU	3412	0	7
9958	ISLA IBATE	3412	0	7
9959	ITATI	3414	0	7
9960	LA UNION	3414	0	7
9961	RAMADA PASO	3412	0	7
9962	TUYUTI	3412	0	7
9963	YACAREY	3412	0	7
9964	AGUAPEY	3306	0	7
9965	AGUARA CUA	3302	0	7
9966	APIPE GRANDE	3302	0	7
9967	BOQUERON	3302	0	7
9968	BUENA VISTA	3302	0	7
9969	CAA GARAY	3302	0	7
9970	COLONIA LIEBIGS	3358	0	7
9971	DOS HERMANOS	3358	0	7
9972	EL SOCORRO	3358	0	7
9973	ESTABLECIMIENTO LA MERCED	3358	0	7
9974	ISLA APIPE CHICO	3302	0	7
9975	ITUZAINGO	3302	0	7
9976	LA PUPII	3358	0	7
9977	OJO DE AGUA	3306	0	7
9978	OMBU	3302	0	7
9979	PLAYADITO	3358	0	7
9980	PORVENIR	3306	0	7
9981	PUERTO VALLE	3302	0	7
9982	RINCON ITAEMBE	3300	0	7
9983	SAN ANTONIO	3302	0	7
9984	SAN BORJITA	3300	0	7
9985	SAN CARLOS	3306	0	7
9986	SAN JOAQUIN	3302	0	7
9987	SANTA ROSA	3358	0	7
9988	SANTO TOMAS	3306	0	7
9989	VILLA OLIVARI	3486	0	7
9990	ALGARROBO	3441	0	7
9991	BARRIO VILLA CORDOBA	3440	0	7
9992	COLONIA CECILIO ECHEVERRIA	3440	0	7
9993	COLONIA GENERAL FERRE	3440	0	7
9994	COLONIA MENDEZ BAR	3443	0	7
9995	CRUZ DE LOS MILAGROS	3441	0	7
9996	GOBERNADOR JUAN E MARTINEZ	3445	0	7
9997	LA BOLSA	3443	0	7
9998	LAVALLE	3443	0	7
9999	QUINTA TERESA	3440	0	7
10000	RINCON DE SOTO	3443	0	7
10001	SALADERO SAN ANTONIO	3443	0	7
10002	SAN ANTONIO	3445	0	7
10003	SAN EUGENIO	3440	0	7
10004	SAN LUIS	3445	0	7
10005	SANTA LUCIA	3445	0	7
10006	VEDOYA	3445	0	7
10007	VILLA AQUINO	3440	0	7
10008	VILLA CORDOBA	3440	0	7
10009	YATAYTI CALLE	3445	0	7
10010	YATAY	3445	0	7
10011	ABRA	3427	0	7
10012	ARROYITO	3427	0	7
10013	BUENA VISTA	3427	0	7
10014	CAMPO CARDOZO	3427	0	7
10015	LOMA ALTA	3425	0	7
10016	MANANTIALES	3427	0	7
10017	MBURUCUYA	3427	0	7
10018	PASO AGUIRRE	3427	0	7
10019	SAN JUAN	3427	0	7
10020	SAN LORENZO	3427	0	7
10021	SANTA ANA	3427	0	7
10022	SANTA TERESA	3427	0	7
10023	TOROS CORA	3427	0	7
10024	VELOSO	3427	0	7
10025	ALEN CUE	3471	0	7
10026	ALFONSO LOMAS	3471	0	7
10027	ARBOL SOLO	3230	0	7
10028	BAYGORRIA	3230	0	7
10029	BOQUERON	3471	0	7
10030	CAAGUAZU	3472	0	7
10031	CAPITA MINI	3472	0	7
10032	CAPITAN JOAQUIN MADARIAGA	3465	0	7
10033	EL CERRITO	3472	0	7
10034	EL PILAR	3472	0	7
10035	EL REMANSO	3476	0	7
10036	FELIPE YOFRE	3472	0	7
10037	ITA CORA	3470	0	7
10038	ITA PUCU	3470	0	7
10039	ITATI RINCON	3470	0	7
10040	KILOMETRO 261	3476	0	7
10041	LA AGRIPINA	3476	0	7
10042	LA AURORA	3472	0	7
10043	LA BELERMINA	3470	0	7
10044	LA CARLOTA	3472	0	7
10045	LA HAYDEE	3230	0	7
10046	LAS ELINAS	3472	0	7
10047	LAS ROSAS	3472	0	7
10048	MARIANO I LOZA EST SOLARI	3476	0	7
10049	MERCEDES	3470	0	7
10050	PAY UBRE CHICO	3470	0	7
10051	RINCON DE YAGUARY	3460	0	7
10052	TACURAL MERCEDES	3471	0	7
10053	UGUAY	3471	0	7
10054	YUQUERI	3470	0	7
10055	ACU	3466	0	7
10056	ARROYO MANGANGA	3220	0	7
10057	ARROYO TIMBOY	3220	0	7
10058	ARROYO TOTORAS	3220	0	7
10059	BUEN RETIRO	3222	0	7
10060	CAMBA CUA	3222	0	7
10061	CASUARINA	3222	0	7
10062	CHACRAS 1A SECCION	3220	0	7
10063	CHACRAS 2A SECCION	3220	0	7
10064	CHACRAS 3A SECCION	3220	0	7
10065	CHACRAS 4A SECCION	3220	0	7
10066	CHIRCAL	3220	0	7
10067	COLONIA LIBERTAD	3224	0	7
10068	EL CEIBO	3220	0	7
10069	EL CHIRCAL	3220	0	7
10070	EL PORVENIR COLONIA LIBERTAD	3224	0	7
10071	ESTACION LIBERTAD	3224	0	7
10072	ESTE ARGENTINO	3220	0	7
10073	INDEPENDENCIA	3222	0	7
10074	JUAN PUJOL	3222	0	7
10075	KILOMETRO 104	3226	0	7
10076	KILOMETRO 134	3222	0	7
10077	KILOMETRO 148	3405	0	7
10078	KILOMETRO 161	3220	0	7
10079	KILOMETRO 167	3220	0	7
10080	KILOMETRO 173	3220	0	7
10081	KILOMETRO 182	3224	0	7
10082	LA FLOR	3222	0	7
10083	LA FLORIDA	3220	0	7
10084	LA PALMA	3224	0	7
10085	MIRA FLORES	3222	0	7
10086	MOCORETA	3226	0	7
10087	MONTE CASEROS	3220	0	7
10088	MOTA	3222	0	7
10089	PARADA LABOUGLE	3222	0	7
10090	PILINCHO	3222	0	7
10091	PUERTO JUAN DE DIOS	3226	0	7
10092	SAN ANDRES	3226	0	7
10093	SAN ANTONIO	3222	0	7
10094	SAN FERMIN	3222	0	7
10095	SAN FERNANDO	3222	0	7
10096	SAN GREGORIO	3226	0	7
10097	SAN JOSE EST LIBERTAD DP	3224	0	7
10098	SAN LUIS EST LIBERTAD DP	3224	0	7
10099	SAN MIGUEL ESTACION LIBERTAD	3224	0	7
10100	SAN SALVADOR	3222	0	7
10101	SANTA LEA	3224	0	7
10102	SANTA MAGDALENA	3222	0	7
10103	SANTA MARTA	3224	0	7
10104	SANTA RITA	3222	0	7
10105	SANTO DOMINGO	3222	0	7
10106	TACUABE	3222	0	7
10107	TALLERES	3220	0	7
10108	TIMBOY	3222	0	7
10109	VILLA LA FLORIDA	3220	0	7
10110	BONPLAND	3234	0	7
10111	EL PROGRESO	3230	0	7
10112	KILOMETRO 204	3232	0	7
10113	KILOMETRO 235	3234	0	7
10114	KILOMETRO 268	3230	0	7
10115	LA AMELIA	3230	0	7
10116	LA COLORADA	3230	0	7
10117	LA CONSTANCIA	3230	0	7
10118	LA ELENA	3230	0	7
10119	LA VERDE	3230	0	7
10120	LOS PINOS	3230	0	7
10121	MADARIAGA	3230	0	7
10122	MIRADOR	3230	0	7
10123	MIRUNGA	3231	0	7
10124	NUEVA ESPERANZA	3230	0	7
10125	NUEVA PALMIRA	3230	0	7
10126	OMBUCITO	3230	0	7
10127	PALMAR	3230	0	7
10128	PALMITA	3230	0	7
10129	PARADA PUCHETA	3232	0	7
10130	PASO DE LOS LIBRES	3230	0	7
10131	PASO LEDESMA	3234	0	7
10132	QUINTA SECCION OMBUCITO	3230	0	7
10133	QUIYATI	3230	0	7
10134	RECREO	3230	0	7
10135	REDUCCION	3230	0	7
10136	SAN ANTONIO	3234	0	7
10137	SAN CARLOS	3230	0	7
10138	SAN FELIPE	3230	0	7
10139	SAN FRANCISCO	3232	0	7
10140	SAN IGNACIO	3232	0	7
10141	SAN JOAQUIN	3230	0	7
10142	SAN JUAN	3230	0	7
10143	SAN PALADIO	3230	0	7
10144	SAN PEDRO	3230	0	7
10145	SAN ROQUITO	3471	0	7
10146	SAN SALVADOR	3471	0	7
10147	SANTA EMILIA	3232	0	7
10148	SANTA ISABEL	3230	0	7
10149	SANTA RITA PARADA PUCHETA	3232	0	7
10150	TAPEBICUA	3232	0	7
10151	TRES HOJAS	3230	0	7
10152	TRISTAN CHICO	3230	0	7
10153	YAPEYU	3232	0	7
10154	ARROYO AMBROSIO	3420	0	7
10155	CNIA OFICIAL JUAN BAUTISTA	3420	0	7
10156	ESTACION SALADAS	3428	0	7
10157	KILOMETRO 406	3420	0	7
10158	KILOMETRO 431	3428	0	7
10159	PAGO ALEGRE	3425	0	7
10160	PAGO DE LOS DESEOS	3425	0	7
10161	PINDONCITO	3420	0	7
10162	RINCON DE AMBROSIO	3416	0	7
10163	SALADAS	3420	0	7
10164	SAN LORENZO	3416	0	7
10165	ARROYO SAN JUAN	3409	0	7
10166	COLONIA M ABERASTURY	3409	0	7
10167	COSTA TOLEDO	3409	0	7
10168	EL PELON	3401	0	7
10169	MATILDE	3412	0	7
10170	PASO DE LA PATRIA	3409	0	7
10171	PUERTO ARAZA	3409	0	7
10172	SAN COSME	3412	0	7
10173	SANTA ANA	3401	0	7
10174	SANTA RITA	3412	0	7
10175	SANTO DOMINGO	3412	0	7
10176	SOCORRO	3412	0	7
10177	SOLEDAD	3412	0	7
10178	VILLAGA CUE	3412	0	7
10179	CERRUDO CUE	3403	0	7
10180	COSTA GRANDE	3403	0	7
10181	HERLITZKA	3403	0	7
10182	LOMAS DE AGUIRRE	3405	0	7
10183	LOMAS DE GONZALEZ	3403	0	7
10184	SAN LUIS DEL PALMAR	3403	0	7
10185	BUENA VISTA	3471	0	7
10186	COLONIA AROCENA INA	3231	0	7
10187	COLONIA CARLOS PELLEGRINI	3471	0	7
10188	GUAVIRAVI	3232	0	7
10189	LA CRUZ	3346	0	7
10190	LOS MANANTIALES	3230	0	7
10191	LOS TRES CERROS	3346	0	7
10192	SAN GABRIEL	3346	0	7
10193	SANTA ELISA	3230	0	7
10194	TRES CERROS	3346	0	7
10195	YAPEYU	3231	0	7
10196	YURUCUA	3346	0	7
10197	BARRANQUERAS	3480	0	7
10198	COLONIA CAIMAN	3485	0	7
10199	COLONIA SAN ANTONIO	3485	0	7
10200	INFANTE	3483	0	7
10201	LA ANGELA	3483	0	7
10202	LA PACHINA	3483	0	7
10203	LAPACHO	3483	0	7
10204	LOMAS SAN JUAN	3483	0	7
10205	LORETO	3483	0	7
10206		3483	0	7
10207	OMBU	3485	0	7
10208	PALMA SOLA	3485	0	7
10209	SAN MIGUEL	3485	0	7
10210	SAN NICOLAS	3485	0	7
10211	SAN SEBASTIAN	3483	0	7
10212	SANTA ISABEL	3485	0	7
10213	SILVERO CUE	3485	0	7
10214	TACUARAL	3485	0	7
10215	TACUAREMBO	3485	0	7
10216	TAPE RATI	3485	0	7
10217	TIMBO PASO	3483	0	7
10218	VERON CUE	3485	0	7
10219	YATAYTI POI	3485	0	7
10220	YATAYTI SATA	3485	0	7
10221	YTA PASO	3483	0	7
10222	YUQUERI	3483	0	7
10223	9 DE JULIO	3445	0	7
10224	ALAMO	3448	0	7
10225	ALGARROBAL	3445	0	7
10226	ARROYO GONZALEZ	3445	0	7
10227	ARROYO PAISO	3445	0	7
10228	BAJO GRANDE	3445	0	7
10229	BARRIO ALGARROBO	3445	0	7
10230	BOLICHE LATA	3449	0	7
10231	CAAYOBAY	3448	0	7
10232	CA	3448	0	7
10233	CARAYA	3448	0	7
10234	CERRITO	3445	0	7
10235	CHAVARRIA	3474	0	7
10236	COLONIA PANDO	3449	0	7
10237	ESTANCIA LAS SALINAS	3474	0	7
10238	KILOMETRO 374	3446	0	7
10239	KILOMETRO 387	3446	0	7
10240	LA LUISA	3446	0	7
10241	MANUEL FLORENCIO MANTILLA	3446	0	7
10242	NARANJITO	3448	0	7
10243	NUEVA ESPERANZA	3474	0	7
10244	OSCURO	3474	0	7
10245	PASO LUCERO	3423	0	7
10246	PEDRO R FERNANDEZ	3446	0	7
10247	PIEDRITA	3222	0	7
10248	SAN DIEGO	3446	0	7
10249	SAN PEDRO	3474	0	7
10250	SAN RAFAEL	3446	0	7
10251	SAN ROQUE	3448	0	7
10252	SAN SEBASTIAN	3448	0	7
10253	SANTA SINFOROSA	3446	0	7
10254	SANTIAGO ALCORTA	3446	0	7
10255	SANTO DOMINGO	3449	0	7
10256	SANTO TOMAS	3448	0	7
10257	TATACUA	3448	0	7
10258	TIMBO	3448	0	7
10259	URUGUAY	3474	0	7
10260	YACARE	3446	0	7
10261	YAZUCA	3448	0	7
10262	AGUAPEY	3342	0	7
10263	CAA GARAY GDOR VALENTIN	3342	0	7
10264	CAABY POY	3342	0	7
10265	CARABI POY	3342	0	7
10266	CASUALIDAD	3340	0	7
10267	CAU GARAY	3342	0	7
10268	CAZA PAVA	3342	0	7
10269	JOSE RAFAEL GOMEZ GARABI	3342	0	7
10270	COLONIA JOSE R GOMEZ	3340	0	7
10271	CORONEL DESIDERIO SOSA	3342	0	7
10272	CUAY GRANDE	3344	0	7
10273	EL CARMEN	3342	0	7
10274	GALARZA CUE	3340	0	7
10275	GARRUCHOS	3351	0	7
10276	GDOR ING V VIRASORO	3342	0	7
10277	GOMEZ CUE	3340	0	7
10278	IBERA	3342	0	7
10279	ISLA GRANDE	3342	0	7
10280	KILOMETRO 442	3340	0	7
10281	KILOMETRO 459	3340	0	7
10282	KILOMETRO 470	3342	0	7
10283	KILOMETRO 475	3342	0	7
10284	KILOMETRO 479	3342	0	7
10285	KILOMETRO 489	3342	0	7
10286	KILOMETRO 506	3342	0	7
10287	KILOMETRO 517	3342	0	7
10288	LAS RATAS	3342	0	7
10289	PUERTO HORMIGUERO	3340	0	7
10290	RINCON DE MERCEDES	3351	0	7
10291	SAN ALONSO	3342	0	7
10292	SAN JUSTO	3342	0	7
10293	SAN VICENTE	3342	0	7
10294	SANTO TOME	3340	0	7
10295	SOSA	3342	0	7
10296	TAREIRI	3342	0	7
10297	VUELTA DEL OMBU	3342	0	7
10298	CA	3463	0	7
10299	LINDA VISTA	3463	0	7
10300	LOS EUCALIPTOS	3463	0	7
10301	SAN LUIS	3463	0	7
10302	SAUCE	3463	0	7
10303	SERIANO CUE	3463	0	7
10305	AMBATO	4711	0	3
10307	CASA VIEJAS	4711	0	3
10308	CHAMORRO	4715	0	3
10309	CHAVARRIA	4715	0	3
10310	CHUCHUCARUANA	4711	0	3
10311	COLPES	4711	0	3
10312	EL ARBOL SOLO	4711	0	3
10313	EL ATOYAL	4715	0	3
10314	EL BISCOTE	4715	0	3
10315	EL BOLSON	4711	0	3
10316	EL CHORRO	4711	0	3
10317	EL NOGAL	4711	0	3
10318	EL PARQUE	4711	0	3
10319	EL PIE DE LA CUESTA	4711	0	3
10320	EL POLEAR	4711	0	3
10321	EL POTRERILLO	4711	0	3
10322	EL RODEO	4715	0	3
10323	EL RODEO GRANDE	4711	0	3
10324	EL TABIQUE	4711	0	3
10325	EL TALA	4715	0	3
10326	HUMAYA	4711	0	3
10327	ISLA LARGA	4711	0	3
10328	LA AGUADA	4711	0	3
10329	LA CA	4715	0	3
10330	LA PIEDRA	4715	0	3
10331	LA PUERTA	4711	0	3
10332	LAS AGUITAS	4715	0	3
10333	LAS BURRAS	4715	0	3
10334	LAS CHACRITAS	4711	0	3
10335	LAS CUCHILLAS	4715	0	3
10336	LAS JUNTAS	4715	0	3
10337	LAS LAJAS	4715	0	3
10338	LAS PAMPITAS	4711	0	3
10339	LAS PIEDRAS BLANCAS	4715	0	3
10340	LOS CASTILLOS	4711	0	3
10341	LOS GUINDOS	4711	0	3
10342	LOS LOROS	4715	0	3
10343	LOS MOLLES	4715	0	3
10344	LOS NARVAEZ	4711	0	3
10345	LOS NAVARROS	4711	0	3
10346	LOS PUESTOS	5319	0	3
10347	LOS TALAS	4711	0	3
10348	LOS VARELA	4711	0	3
10349	MOLLE QUEMADO	4715	0	3
10350	SINGUIL	4711	0	3
10351	VILLA QUINTIN AHUMADA	4715	0	3
10352	ACOSTILLA	4701	0	3
10353	AGUA DEL SIMBOL	5261	0	3
10354	AGUA LOS MATOS	5265	0	3
10355	ALTO DEL ROSARIO	5261	0	3
10356	AMANA	4701	0	3
10357	ANCASTI	4701	0	3
10358	ANQUINCILA	4701	0	3
10359	BREA	5265	0	3
10360	CABRERA	4701	0	3
10361	CALACIO	4701	0	3
10362	CALERA	4701	0	3
10363	CA	4701	0	3
10364	CA	4701	0	3
10365	CA	5265	0	3
10366	CANDELARIA	4701	0	3
10367	CASA ARMADA	4701	0	3
10368	CASA DE LA CUMBRE	5261	0	3
10369	CASA VIEJA	4701	0	3
10370	CHACRITAS	5265	0	3
10371	CONCEPCION	4701	0	3
10372	CORRAL DE PIEDRA	4701	0	3
10373	CORRAL VIEJO	4701	0	3
10374	CORRALITO	5265	0	3
10375	EL ARBOLITO	4701	0	3
10376	EL ARENAL	5261	0	3
10377	EL BARREAL	4701	0	3
10378	EL CERCADO	4701	0	3
10379	EL CEVILARCITO	4701	0	3
10380	EL CHA	4701	0	3
10381	EL CHORRO	4701	0	3
10382	EL MOJON	4701	0	3
10383	EL MOLLAR	4701	0	3
10384	EL POTRERO DE LOS CORDOBA	4701	0	3
10385	EL POZO	4701	0	3
10386	EL QUEBRACHAL	5261	0	3
10387	EL SALTITO	5261	0	3
10388	EL SAUCE	4701	0	3
10389	EL SAUCE IPIZCA	4701	0	3
10390	EL TOTORAL	4701	0	3
10391	EL VALLECITO	4701	0	3
10392	EL ZAPALLAR	4701	0	3
10393	ESTANCIA	5265	0	3
10394	ESTANCIA VIEJA	4701	0	3
10395	GUANACO	4701	0	3
10396	HIGUERA DEL ALUMBRE	4701	0	3
10397	IPIZCA	4701	0	3
10398	LA AGUADITA	4701	0	3
10399	LA BARROSA	4701	0	3
10400	LA BEBIDA	4701	0	3
10401	LA ESTANCIA	4701	0	3
10402	LA ESTANCITA	4701	0	3
10403	LA FALDA	4701	0	3
10404	LA HIGUERITA	4701	0	3
10405	LA HUERTA	5261	0	3
10406	LA MESADA	4701	0	3
10407	LA PE	5261	0	3
10408	LA TIGRA	5261	0	3
10409	LAS BARRANCAS	4701	0	3
10410	LAS BARRANCAS CASA ARMADA	4701	0	3
10411	LAS CHACRAS	4701	0	3
10412	LAS CUCHILLAS	5261	0	3
10413	LAS CUCHILLAS DEL AYBAL	5265	0	3
10414	LAS TAPIAS	4701	0	3
10415	LAS TUNAS	4701	0	3
10416	LOMA SOLA	4701	0	3
10417	LOS BULACIO	4701	0	3
10418	LOS HUAYCOS	4701	0	3
10419	LOS MOGOTES	5261	0	3
10420	LOS MOLLES	5261	0	3
10421	LOS MORTEROS	4701	0	3
10422	LOS PIQUILLINES	4701	0	3
10423	MAJADA	5265	0	3
10424	NAVAGUIN	5261	0	3
10425	OJO DE AGUA	4701	0	3
10426	PE	4701	0	3
10427	POTRERO	4701	0	3
10428	QUEBRACHO	4701	0	3
10429	RIO LOS MOLINOS	4701	0	3
10430	SAN ANTONIO	4701	0	3
10431	SAN JOSE	4701	0	3
10432	SAN MARTIN	4234	0	3
10433	SANTA GERTRUDIS	4701	0	3
10434	SAUCE DE LOS CEJAS	5265	0	3
10435	SAUCE HUACHO	4701	0	3
10436	TACANA	4701	0	3
10437	TACO DE ABAJO	4701	0	3
10438	TOTORAL	4701	0	3
10439	YERBA BUENA	5265	0	3
10440	ACONQUIJA	4743	0	3
10441	AGUA DE LAS PALOMAS	4741	0	3
10442	AGUA VERDE	4740	0	3
10443	ALTO DE LA JUNTA	4743	0	3
10444	LA ALUMBRERA	4743	0	3
10445	AMANAO	4741	0	3
10446	ANDALGALA	4740	0	3
10447	ASERRADERO EL PILCIO	4740	0	3
10448	BUENA VISTA	4743	0	3
10449	CARAPUNCO	4741	0	3
10450	CASA DE PIEDRA	4741	0	3
10451	CHA	4751	0	3
10452	CHAQUIAGO	4741	0	3
10453	CHILCA	4740	0	3
10454	CHOYA	4741	0	3
10455	CONDOR HUASI	4711	0	3
10456	DISTRITO ESPINILLO	4740	0	3
10457	EL ALAMITO	4743	0	3
10458	EL ARBOLITO	4743	0	3
10459	EL CARRIZAL	4741	0	3
10460	EL COLEGIO	4740	0	3
10461	EL ESPINILLO	4743	0	3
10462	EL LINDERO	4740	0	3
10463	EL MOLLE	4740	0	3
10464	EL PUCARA	4711	0	3
10465	EL SUNCHO	4743	0	3
10466	EL ZAPALLAR	4741	0	3
10467	HUACO	4741	0	3
10468	HUASCHASCHI	4740	0	3
10469	HUASAN	4740	0	3
10470	LA AGUADA	4740	0	3
10471	LA BANDA	4740	0	3
10472	LA HOYADA	4139	0	3
10473	LA LAGUNA	4741	0	3
10474	LAS ESTANCIAS	4743	0	3
10475	LAS PAMPITAS	4743	0	3
10476	LOS RASTROJOS	4701	0	3
10477	MALLI 1	4740	0	3
10478	MALLI 2	4740	0	3
10479	MOLLECITO	5319	0	3
10480	PILCIAO	4740	0	3
10481	EL POTRERO	4743	0	3
10482	RODEO GRANDE	4740	0	3
10483	VILLA CORONEL ARROYO	4741	0	3
10485	MINA INCA HUASI	4705	0	3
10486	ANTOFAGASTA DE LA SIERRA	4705	0	3
10487	AGUA COLORADA	4750	0	3
10488	AGUA DE DIONISIO	4751	0	3
10489	AGUAS CALIENTES	4751	0	3
10490	ALTO EL BOLSON	4751	0	3
10491	AMPUJACO	4750	0	3
10492	ASAMPAY	4751	0	3
10493	BARRANCA LARGA	4751	0	3
10494	BELEN	4750	0	3
10495	CACHIJAN	4751	0	3
10496	CARRIZAL	4751	0	3
10497	CARRIZAL DE ABAJO	4751	0	3
10498	CARRIZAL DE LA COSTA	4751	0	3
10499	CONDOR HUASI DE BELEN	4751	0	3
10500	CORRAL QUEMADO	4751	0	3
10501	CORRALITO	4753	0	3
10502	COTAGUA	4751	0	3
10503	CULAMPAJA	4751	0	3
10504	DURAZNO	4753	0	3
10505	EL CAJON	4751	0	3
10506	EL CAMPILLO	4751	0	3
10507	EL CARRIZAL	4751	0	3
10508	EL DURAZNO	4751	0	3
10509	EL EJE	4751	0	3
10510	EL MEDIO	4750	0	3
10511	EL MOLINO	4750	0	3
10512	EL PORTEZUELO	4750	0	3
10513	EL TIO	4751	0	3
10514	EL TOLAR	4751	0	3
10515	FARALLON NEGRO	4751	0	3
10516	HUACO	4750	0	3
10517	HUALFIN	4751	0	3
10518	HUASAYACO	4751	0	3
10519	HUASI CIENAGA	4751	0	3
10520	JACIPUNCO	4751	0	3
10521	LA AGUADA	4751	0	3
10522	LA BANDA	4750	0	3
10523	LA CA	4751	0	3
10524	LA CAPELLANIA	4751	0	3
10525	LA CIENAGA	4751	0	3
10526	LA COSTA	4750	0	3
10527	LA CUESTA	4751	0	3
10528	LA ESTANCIA	4751	0	3
10529	LA PUERTA DE SAN JOSE	4751	0	3
10530	LA PUNTILLA	4750	0	3
10531	LA QUEBRADA	4751	0	3
10532	LA RAMADA	4753	0	3
10533	LA TOMA	4751	0	3
10534	LA VI	4751	0	3
10535	LAGUNA BLANCA	4751	0	3
10536	LAGUNA COLORADA	4751	0	3
10537	LAS BAYAS	4753	0	3
10538	LAS CUEVAS	4751	0	3
10539	LAS JUNTAS	4751	0	3
10540	LAS MANZAS	4751	0	3
10541	LOCONTE	4751	0	3
10542	LONDRES	4753	0	3
10543	LONDRES ESTE	4750	0	3
10544	LONDRES OESTE	4753	0	3
10545	LOS COLORADOS	4753	0	3
10546	LOS MORTERITOS	4711	0	3
10547	LOS NACIMIENTOS	4751	0	3
10548	LOS POZUELOS	4751	0	3
10549	MINAS AGUA TAPADA	4751	0	3
10550	NACIMIENTOS DE ARRIBA	4751	0	3
10551	NACIMIENTOS DE SAN ANTONIO	4751	0	3
10552	NACIMIENTOS DEL BOLSON	4751	0	3
10553	PAPA CHACRA	4751	0	3
10554	PIEDRA LARGA	4753	0	3
10555	POZO DE PIEDRA	4751	0	3
10556	RODEO GERVAN	4751	0	3
10557	SAN FERNANDO	4751	0	3
10558	TALAMAYO	4750	0	3
10559	VILLA VIL	4751	0	3
10560	VICU	4751	0	3
10561	ADOLFO E CARRANZA	5263	0	3
10562	BALDE LA PUNTA	5263	0	3
10563	BALDE NUEVO	5263	0	3
10564	BUENA VISTA	5263	0	3
10565	CAPAYAN	4726	0	3
10566	CERRILLOS	4139	0	3
10567	LOS CHA	4726	0	3
10568	CHUMBICHA	4728	0	3
10569	COLONIA DEL VALLE	4726	0	3
10570	COLONIA NUEVA CONETA	4724	0	3
10571	CONCEPCION	4726	0	3
10572	CONETA	4724	0	3
10573	EL BA	4724	0	3
10574	EL CARRIZAL	4726	0	3
10575	EL MILAGRO	4726	0	3
10576	HUILLAPIMA	4726	0	3
10577	KILOMETRO 128	4728	0	3
10578	KILOMETRO 99	5263	0	3
10579	LA CA	4726	0	3
10580	LA HORQUETA	5263	0	3
10581	LA PARAGUAYA	4724	0	3
10582	LAMPASILLO	4726	0	3
10583	LAS PALMAS	4726	0	3
10584	LOS ANGELES	4724	0	3
10585	LOS BAZAN	4724	0	3
10586	LOS PINOS	4724	0	3
10587	LOS PUESTOS	4724	0	3
10588	MIRAFLORES	4724	0	3
10589	SAN GERONIMO	4728	0	3
10590	SAN LORENZO	4724	0	3
10591	SAN MARTIN	5263	0	3
10592	SAN PABLO	4726	0	3
10593	SAN PEDRO CAPAYAN	4726	0	3
10594	SISIGUASI	4724	0	3
10595	TELARITOS	5263	0	3
10596	TRAMPASACHA	4728	0	3
10597	BANDA VARELA	4700	0	3
10598	SAN FDO DEL VALLE DE CATAMARCA	4700	0	3
10599	CHACABUCO	4700	0	3
10600	EL TALA	4700	0	3
10601	LA AGUADA	4700	0	3
10602	LA BREA	4700	0	3
10603	LA CALERA	4700	0	3
10604	LA CHACARITA	4700	0	3
10605	LA CHACARITA DE LOS PADRES	4700	0	3
10606	LAS VARITAS	4700	0	3
10607	LAZARETO	4700	0	3
10608	LOMA CORTADA	4700	0	3
10609	RIO DEL TALA	4700	0	3
10611	VILLA CUBAS	4700	0	3
10612	VILLA PARQUE CHACABUCO	4700	0	3
10613	LA TERCENA	4707	0	3
10614	ACHALCO	4234	0	3
10615	ALBIGASTA	4231	0	3
10616	AYAPASO	4234	0	3
10617	BARRANQUITAS	4235	0	3
10618	BEBIDA	4235	0	3
10619	BELLA VISTA	4235	0	3
10620	BREA CHIMPANA	4230	0	3
10621	CHA	4234	0	3
10622	EL ALTO	4235	0	3
10623	EL RODEITO	4235	0	3
10624	EL ROSARIO	4235	0	3
10625	EL SIMBOL	4234	0	3
10626	EL VALLECITO	4235	0	3
10627	ESTANZUELA	4235	0	3
10628	GUAYAMBA	4235	0	3
10629	ICHIPUCA	4234	0	3
10630	ILOGA	4235	0	3
10631	INACILLO	4235	0	3
10632	INFANZON	4235	0	3
10633	KILOMETRO 1093	4234	0	3
10634	LA CALERA	4234	0	3
10635	LA CALERA DEL SAUCE	4235	0	3
10636	LA ESTANCIA	4235	0	3
10637	LA ESTANZUELA	4235	0	3
10638	LA HUERTA	4235	0	3
10639	LA QUEBRADA	4234	0	3
10640	LAS JUSTAS	4235	0	3
10641	LAS LOMITAS	4234	0	3
10642	LAS TAPIAS	4235	0	3
10643	LAS TRANCAS	4235	0	3
10644	LAS TRILLAS	4235	0	3
10645	LINDERO	4235	0	3
10646	LOS CISTERNAS	4701	0	3
10647	LOS MORTEROS	4234	0	3
10648	LOS ORTICES	4235	0	3
10649	LOS PEDRAZAS	4235	0	3
10650	MINA DAL	4235	0	3
10651	NOGALITO	4235	0	3
10652	ORELLANO	4235	0	3
10653	OYOLA	4235	0	3
10654	POZO GRANDE	4234	0	3
10655	PUEBLITO	4235	0	3
10656	PUESTO LOS GOMEZ	4235	0	3
10657	RIO DE AVILA	4235	0	3
10658	RIO DE LA PLATA	4235	0	3
10659	SAN JERONIMO	4235	0	3
10660	SAN VICENTE	4235	0	3
10661	SAUCE HUACHO	4235	0	3
10662	SOLEDAD	4701	0	3
10663	SUCUMA	4235	0	3
10664	SURUIPIANA	4235	0	3
10665	EL TACO	4701	0	3
10666	TALEGA	4235	0	3
10667	TAPSO	4234	0	3
10668	TINTIGASTA	4235	0	3
10669	VILISMAN	4235	0	3
10670	EL SALADILLO	5261	0	3
10672	COLLAGASTA	4711	0	3
10673	EL DESMONTE	4707	0	3
10674	LA CARRERA	4711	0	3
10675	LA FALDA DE SAN ANTONIO	4707	0	3
10676	OCHO VADOS	4713	0	3
10677	SAN JOSE DE PIEDRA BLANCA	4709	0	3
10678	POMANCILLO	4711	0	3
10679	SAN ANTONIO DE P BLANCA	4707	0	3
10680	SAN ANTONIO FRAY M ESQUIU	4707	0	3
10682	SIERRA BRAVA	4711	0	3
10683	VILLA LAS PIRQUITAS	4713	0	3
10684	ALBIGASTA	4235	0	3
10685	ALTO BELLO	5261	0	3
10686	ANCASTILLO	4231	0	3
10687	ANGELINA	5264	0	3
10688	ANJULI	4231	0	3
10689	BA	5261	0	3
10690	BAVIANO	5265	0	3
10691	CABALLA	5261	0	3
10692	CA	5264	0	3
10694	CERRILLADA	5264	0	3
10695	CHA	5264	0	3
10696	CHICHAGASTA	5266	0	3
10697	CORRALITOS	4230	0	3
10698	CORTADERAS	5261	0	3
10699	DIVISADERO	5260	0	3
10700	EL ABRA	5261	0	3
10701	EL AYBAL	5261	0	3
10702	EL BA	5261	0	3
10703	EL BARREAL	5260	0	3
10704	EL BARRIAL	5261	0	3
10705	EL BARRIALITO	4231	0	3
10706	EL BELLO	5260	0	3
10707	EL CACHO	5261	0	3
10708	EL CENTENARIO	4231	0	3
10709	EL CERCADO	5260	0	3
10710	EL CERRITO	5261	0	3
10711	EL CHA	5261	0	3
10712	EL CIENAGO	5261	0	3
10713	EL GACHO	5261	0	3
10714	EL LINDERO	5260	0	3
10715	EL MILAGRO	5261	0	3
10716	EL MISTOLITO	5261	0	3
10717	EL MORENO	5261	0	3
10718	EL POLEAR	5261	0	3
10719	EL PORTEZUELO	5261	0	3
10720	EL POTRERO	5261	0	3
10721	EL PUESTITO	5261	0	3
10722	EL PUESTO	5261	0	3
10723	EL QUIMILO	5263	0	3
10724	EL RETIRO	5264	0	3
10725	EL ROSARIO	5264	0	3
10726	EL SUNCHO	5261	0	3
10727	EL TALA	5264	0	3
10728	EL VALLE	5261	0	3
10729	EL VALLECITO	4230	0	3
10730	EMPALME SAN CARLOS	5260	0	3
10731	ENSENADA	5266	0	3
10732	ESQUIU	5261	0	3
10733	GARAY	5261	0	3
10734	GARZON	4231	0	3
10735	ICA	5265	0	3
10736	JESUS MARIA	5264	0	3
10737	KILOMETRO 1008	5264	0	3
10738	KILOMETRO 1017	5264	0	3
10739	KILOMETRO 38	5261	0	3
10740	KILOMETRO 955	5260	0	3
10741	KILOMETRO 969	5260	0	3
10742	KILOMETRO 997	5260	0	3
10743	LA AGUADA	5261	0	3
10744	LA ANTIGUA	5261	0	3
10745	LA BARROSA	5265	0	3
10746	LA BREA	5260	0	3
10747	LA BUENA ESTRELLA	5260	0	3
10748	LA CA	5261	0	3
10749	LA COLONIA	5261	0	3
10750	LA DORADA	5261	0	3
10751	LA FALDA	5265	0	3
10752	LA FLORIDA	5261	0	3
10753	LA GRANJA	5264	0	3
10754	LA GUARDIA	5263	0	3
10755	LA ISLA	5264	0	3
10756	LA MONTOSA	5261	0	3
10757	LA PARADA	5265	0	3
10758	LA PE	5261	0	3
10759	LA QUINTA	5261	0	3
10760	LA RENOVACION	4231	0	3
10761	LA VALENTINA	5261	0	3
10762	LA ZANJA	5261	0	3
10763	LAS CORTADERAS	5261	0	3
10764	LAS FLORES	5261	0	3
10765	LAS IGUANAS	4231	0	3
10766	LAS LOMITAS	5261	0	3
10767	LAS PALMITAS	4231	0	3
10768	LAS PALOMAS	5261	0	3
10769	LAS PE	5263	0	3
10770	LAS TEJAS	4231	0	3
10771	LAS TOSCAS	5265	0	3
10772	LOS ALAMOS	4235	0	3
10773	LOS CADILLOS	5261	0	3
10774	LOS CORDOBESES	4231	0	3
10775	LOS CORRALES	4235	0	3
10776	LOS NOGALES	4235	0	3
10777	LOS POCITOS	5261	0	3
10778	MARIA DORA	5264	0	3
10779	MARIA ELENA	5261	0	3
10780	MOTEGASTA	5261	0	3
10781	OLTA	5261	0	3
10782	PALO CRUZ	5261	0	3
10783	PALO PARADO	4231	0	3
10784	PARADA KILOMETRO 62	5263	0	3
10785	PORTILLO CHICO	5261	0	3
10786	POZANCONES	5260	0	3
10787	POZOS CAVADOS	5266	0	3
10788	PUESTO DE FADEL O DE LOBO	5260	0	3
10789	PUESTO DE LOS MORALES	4231	0	3
10790	PUESTO DE VERA	5265	0	3
10791	PUESTO SABATTE	5261	0	3
10792	QUIROS	5266	0	3
10793	RAMBLONES	5261	0	3
10794	RECREO	5260	0	3
10795	RIO CHICO	5265	0	3
10796	RIO DE BAZANES	5261	0	3
10797	RIO DE DON DIEGO	5261	0	3
10798	RIO DE LA DORADA	5261	0	3
10799	SAN ANTONIO	5264	0	3
10800	SAN ANTONIO DE LA PAZ	5264	0	3
10801	SAN ANTONIO VIEJO	5264	0	3
10802	SAN FRANCISCO	5265	0	3
10803	SAN JOSE	5319	0	3
10804	SAN LORENZO	5261	0	3
10805	SAN MANUEL	5264	0	3
10806	SAN MIGUEL	5261	0	3
10807	SAN NICOLAS	5261	0	3
10808	SAN RAFAEL	5260	0	3
10809	SANTA LUCIA	5260	0	3
10810	SANTO DOMINGO	5260	0	3
10811	SICHA	5265	0	3
10812	TACOPAMPA	5261	0	3
10813	TULA	5264	0	3
10814	LAS BARRANCAS	4751	0	3
10815	LAS MINAS	4740	0	3
10816	AMADORES	4716	0	3
10817	BALCOSNA	4719	0	3
10818	BALCOSNA DE AFUERA	4719	0	3
10819	CERVI	4716	0	3
10820	EL BASTIDOR	4718	0	3
10821	EL CEVIL	4716	0	3
10822	EL CHAMICO	4719	0	3
10823	EL CIFLON	4719	0	3
10824	EL CONTADOR	4719	0	3
10825	EL DURAZNILLO	4722	0	3
10826	EL GARABATO	4716	0	3
10827	EL RETIRO	4716	0	3
10828	EL ROSARIO	4719	0	3
10829	EL TOTORAL	4718	0	3
10830	HUACRA	4722	0	3
10831	LA BAJADA	4716	0	3
10832	LA BANDA	4716	0	3
10833	LA ESQUINA	4718	0	3
10834	LA FALDA	4718	0	3
10835	LA HIGUERA	4719	0	3
10836	LA MERCED	4718	0	3
10837	LA VI	4722	0	3
10838	LA VI	4722	0	3
10839	LAS HUERTAS	4722	0	3
10840	LAS LAJAS	4719	0	3
10841	LAS TRANQUITAS	4722	0	3
10842	LOS GALPONES	4718	0	3
10843	LOS OVEJEROS	4722	0	3
10844	LOS PINTADOS	4722	0	3
10845	MONTE POTRERO	4716	0	3
10846	PALO LABRADO	4716	0	3
10847	POZO DEL ALGARROBO	4723	0	3
10848	POZO DEL CAMPO	4723	0	3
10849	RAFAEL CASTILLO	4716	0	3
10850	SALCEDO	4716	0	3
10851	SAN ANTONIO DE PACLIN	4719	0	3
10852	SANTA ANA	4718	0	3
10853	SANTA BARBARA	4718	0	3
10854	SAUCE MAYO	4722	0	3
10855	SUMAMPA	4722	0	3
10856	SUPERI	4718	0	3
10857	TALAGUADA	4718	0	3
10858	TIERRA VERDE	4719	0	3
10859	VILLA COLLANTES	4719	0	3
10860	YOCAN	4716	0	3
10861	APOYACO	5317	0	3
10862	CALERA LA NORMA	5315	0	3
10863	COLPES	5319	0	3
10864	EL PAJONAL	5315	0	3
10865	EL POTRERO	5321	0	3
10866	ESTABLECIMIENTO MINERO CERRO B	5317	0	3
10867	ESTACION POMAN	5315	0	3
10868	JOYANGO	5321	0	3
10869	KILOMETRO 975	5321	0	3
10870	LA AGUADA GRANDE	5321	0	3
10871	LA YEGUA MUERTA	5321	0	3
10872	LAS BREAS	5321	0	3
10873	LAS CASITAS	5315	0	3
10874	LAS CIENAGAS	5315	0	3
10875	LOS BALDES	5315	0	3
10876	LOS CAJONES	5317	0	3
10877	MALCASCO	5315	0	3
10878	MISCHANGO	5315	0	3
10879	MUTQUIN	5317	0	3
10880	POMAN	5315	0	3
10881	RETIRO DE COLANA	5317	0	3
10882	RINCON	5317	0	3
10883	ROSARIO DE COLANA	5317	0	3
10884	SAN MIGUEL	5321	0	3
10885	SAUJIL	5321	0	3
10886	SIJAN	5319	0	3
10887	TUSCUMAYO	5315	0	3
10888	AGUA AMARILLA LA HOYADA	4139	0	3
10889	AGUA AMARILLA PTA DE BALASTO	4139	0	3
10890	AMPAJANGO	4139	0	3
10891	ANDALHUALA	4139	0	3
10892	BANDA	4139	0	3
10893	CAMPITOS	4139	0	3
10894	CASPINCHANGO	4139	0	3
10895	CASA DE PIEDRA	4139	0	3
10896	CERRILLOS	4139	0	3
10897	CHAFI	4139	0	3
10898	CHA	4139	0	3
10899	EL ARROYO	4139	0	3
10900	EL BALDE	4139	0	3
10901	EL CAJON	4139	0	3
10902	EL CALCHAQUI	4139	0	3
10903	EL CERRITO	4139	0	3
10904	EL DESMONTE	4139	0	3
10905	EL MEDANITO	4139	0	3
10906	EL TESORO	4139	0	3
10907	EL TRAPICHE	4139	0	3
10908	EL ZARZO	4139	0	3
10909	ENTRE RIOS	4139	0	3
10910	ESTANCIA VIEJA	4139	0	3
10911	FAMABALASTRO	4139	0	3
10912	FAMATANCA	4139	0	3
10913	FUERTE QUEMADO	4141	0	3
10914	IAPES	4139	0	3
10915	JULIPAO	4139	0	3
10916	LA OLLADA	4139	0	3
10917	LA OVEJERIA	4719	0	3
10918	LA QUEBRADA	4139	0	3
10919	LA SOLEDAD	4139	0	3
10920	LAS MOJARRAS	4139	0	3
10921	LOS POZUELOS	4139	0	3
10922	LOS SALTOS	4139	0	3
10923	MEDANITO	4139	0	3
10924	OVEJERIA	4139	0	3
10925	PAJANGUILLO	4139	0	3
10926	PALOMA YACO	4139	0	3
10927	PIE DEL MEDANO	4139	0	3
10928	PUNTA DE BALASTO	4139	0	3
10929	SAN ANTONIO DEL CAJON	4139	0	3
10930	SAN JOSE NORTE	4139	0	3
10931	SANTA MARIA	4139	0	3
10932	TOROYACO	4139	0	3
10933	TOTORILLA	4139	0	3
10934	ALIJILAN	4723	0	3
10935	ALMIGAUCHO	4723	0	3
10936	ALTA GRACIA	4723	0	3
10937	AMANCALA	4723	0	3
10938	AMPOLLA	4723	0	3
10939	BA	4723	0	3
10940	CACHI	4723	0	3
10941	CORTADERAS	4237	0	3
10942	DOS POCITOS	4723	0	3
10943	DOS TRONCOS	4723	0	3
10944	EL CARMEN	4723	0	3
10945	EL DESMONTE	4723	0	3
10946	EL POTRERO	4723	0	3
10947	EL QUEBRACHITO	4235	0	3
10948	LA AGUADA	4723	0	3
10949	LA BAJADA	4723	0	3
10950	LA CALERA	4723	0	3
10951	LA MARAVILLA	5264	0	3
10952	LAS CA	4235	0	3
10953	LAS CAYAS	4723	0	3
10954	LAS LOMITAS	4235	0	3
10955	LAS PAMPAS	4235	0	3
10956	LAS TUNAS	4723	0	3
10957	LOS ALTOS	4723	0	3
10958	LOS BASTIDORES	4723	0	3
10959	LOS ESTANTES	4723	0	3
10960	LOS MOLLES	4723	0	3
10961	LOS ORTICES	4723	0	3
10962	LOS POCITOS	4723	0	3
10963	LOS TRONCOS	4723	0	3
10964	LOS ZANJONES	4723	0	3
10965	MANANTIALES	4723	0	3
10966	MISTOL ANCHO	4723	0	3
10967	MONTE REDONDO	4723	0	3
10968	OVANTA	4723	0	3
10969	PAMPA CHACRA	4723	0	3
10970	PUERTA GRANDE	4723	0	3
10971	PUESTO DE LA VIUDA	4237	0	3
10972	PUESTO DEL MEDIO	4723	0	3
10973	QUEBRACHAL	4723	0	3
10974	QUEBRACHOS BLANCOS	4723	0	3
10975	QUIMILPA	4723	0	3
10976	RETIRO	5317	0	3
10977	SALAUCA	4723	0	3
10978	SAN LUIS	4723	0	3
10979	YAQUICHO	4723	0	3
10980	LAVALLE	5343	0	3
10981	ANDALUCIA	5331	0	3
10982	ANILLACO	5341	0	3
10983	BANDA DE LUCERO	5333	0	3
10984	BA	5345	0	3
10985	CARRIZAL	5333	0	3
10986	CERRO NEGRO	5331	0	3
10987	CIENAGUITA	5333	0	3
10988	COPACABANA	5333	0	3
10989	CORDOBITA	5331	0	3
10990	CORRAL DE PIEDRA	5341	0	3
10991	COSTA DE REYES	5341	0	3
10992	EL ALTO	5333	0	3
10993	EL BARRIALITO	5345	0	3
10994	EL CACHIYUYO	5341	0	3
10995	EL PE	5345	0	3
10996	EL PUEBLITO	5331	0	3
10997	EL PUESTO	5341	0	3
10998	EL RETIRO	5345	0	3
10999	EL TAMBILLO	4753	0	3
11000	FIAMBALA	5345	0	3
11001	KILOMETRO 1006	5331	0	3
11002	KILOMETRO 999	5331	0	3
11003	LA AGUADITA	5345	0	3
11004	LA CA	5341	0	3
11005	LA CANDELARIA	5333	0	3
11006	LA CAPELLANIA	5333	0	3
11007	LA CIENAGA	5341	0	3
11008	LA CIENAGA DE LOS ZONDONES	5341	0	3
11009	LA FALDA	5341	0	3
11010	LA FLORIDA	5341	0	3
11011	LA ISLA	5333	0	3
11012	LA MAJADA	5341	0	3
11013	LA MESADA	5341	0	3
11014	LA PALCA	5341	0	3
11015	LA PUNTILLA	5331	0	3
11016	LA PUNTILLA DE SAN JOSE	5341	0	3
11017	LA RAMADITA	5341	0	3
11018	LAS CHACRAS	5331	0	3
11019	LAS HIGUERITAS	5340	0	3
11020	LAS PAMPAS	5341	0	3
11021	LAS PAPAS	5341	0	3
11022	LAS RETAMAS	5345	0	3
11023	LORO HUASI	5340	0	3
11024	LOS BALVERDIS	5331	0	3
11025	LOS GONZALES	5331	0	3
11026	LOS GUAYTIMAS	5340	0	3
11027	LOS MORTEROS	5345	0	3
11028	LOS PALACIOS	5340	0	3
11029	LOS POTRERILLOS	5341	0	3
11030	LOS QUINTEROS	5331	0	3
11031	LOS RINCONES	5331	0	3
11032	LOS ROBLEDOS	5340	0	3
11033	LOS VALDEZ	5340	0	3
11034	MEDANITOS	5341	0	3
11035	MESADA DE LOS ZARATE	5341	0	3
11036	MESADA GRANDE	5341	0	3
11037	PALO BLANCO	5341	0	3
11038	PAMPA BLANCA	5341	0	3
11039	PASO SAN FRANCISCO	5341	0	3
11040	PE	5331	0	3
11041	PLAZA DE SAN PEDRO	5341	0	3
11042	RIO COLORADO	5331	0	3
11043	RIO GRANDE	5341	0	3
11044	SALADO	5331	0	3
11045	SAN BUENAVENTURA	5340	0	3
11046	SAN JOSE DE TINOGASTA	5341	0	3
11047	SANTA CRUZ	5331	0	3
11048	SANTA ROSA	5343	0	3
11049	SANTO TOMAS	5341	0	3
11050	SAUJIL DE TINOGASTA	5341	0	3
11051	TATON	5341	0	3
11052	TINOGASTA	5340	0	3
11053	VILLA SAN ROQUE	5343	0	3
11054	VILLA SELEME	5331	0	3
11055	VI	5333	0	3
11056	AGUA COLORADA	4724	0	3
11057	ANTAPOCA	4705	0	3
11058	EL BA	4707	0	3
11059	EL HUECO	4707	0	3
11060	HUAYCAMA	4705	0	3
11061	LA ESTRELLA	4724	0	3
11062	LAS ESQUINAS	4707	0	3
11063	LAS TEJAS DE VALLE VIEJO	4700	0	3
11064	MOTA BOTELLO	4705	0	3
11065	POLCOS	4707	0	3
11066	PORTEZUELO	4716	0	3
11067	POZO DEL MISTOL	4705	0	3
11068	ROSARIO DEL SUMALAO	4707	0	3
11069	SAN ISIDRO	4707	0	3
11070	SANTA CRUZ	4705	0	3
11071	SANTA ROSA	4707	0	3
11072	SUMALAO	4705	0	3
11073	TRES PUENTES	4707	0	3
11074	VILLA DOLORES	4707	0	3
11075	VILLA MACEDO	4707	0	3
11076	COLONIA BENITEZ	3505	0	4
11077	COLONIA EL PILAR	3505	0	4
11078	EL TRAGADERO	3505	0	4
11079	PUERTO ANTEQUERA	3505	0	4
11080	ARROYO QUINTANA	3505	0	4
11081	ISLA ANTEQUERA	3505	0	4
11082	LA PILAR	3505	0	4
11083	MARGARITA BELEN	3505	0	4
11084	PILAR	3505	0	4
11085	PUENTE INE	3505	0	4
11086	PUNTA NUEVA	3505	0	4
11087	TRES HORQUETAS	3505	0	4
11088	GENERAL CAPDEVILA	3732	0	4
11089	COLONIA HAMBURGUESA	3732	0	4
11090	EL ESTERO	3734	0	4
11091	EL PORONGAL	3734	0	4
11092	EL ZAPALLAR	3509	0	4
11093	GANCEDO	3734	0	4
11094	GENERAL PINEDO	3732	0	4
11095	HERMOSO CAMPO	3733	0	4
11096	ITIN	3733	0	4
11097	KILOMETRO 523	3733	0	4
11098	LOS FORTINES	3734	0	4
11099	PAMPA LANDRIEL	3731	0	4
11100	PINEDO CENTRAL	3732	0	4
11101	VIBORAS	3734	0	4
11102	COLONIA ABORIGEN	3531	0	4
11103	COLONIA BLAS PARERA	3531	0	4
11104	KILOMETRO 22	3534	0	4
11105	LA ESPERANZA	3534	0	4
11106	LA SOLEDAD	3534	0	4
11107	LA TAMBORA	3534	0	4
11108	MACHAGAI	3534	0	4
11109	SANTA MARTA	3534	0	4
11110	TRES PALMAS	3534	0	4
11111	COLONIA ABORIGEN CHACO	3531	0	4
11112	COLONIA EL AGUARA	3534	0	4
11113	COLONIA LA LOLA	3534	0	4
11114	EL TOTORAL	3534	0	4
11115	NAPALPI	3531	0	4
11116	CAMPO ZAPA	3722	0	4
11117	COLONIA CUERO QUEMADO	3722	0	4
11118	COLONIA GENERAL NECOCHEA	3722	0	4
11119	COLONIA JUAN LAVALLE	3722	0	4
11120	EL CAJON	3722	0	4
11121	EL ORO BLANCO	3722	0	4
11122	EL TRIANGULO	3706	0	4
11123	LAS BRE	3722	0	4
11124	PAMPA DEL HUEVO	3722	0	4
11125	PAMPA DEL TORDILLO	3722	0	4
11126	PAMPA DEL ZORRO	3722	0	4
11127	PAMPA SAN MARTIN	3722	0	4
11128	POZO DEL INDIO ESTACION FCGB	3722	0	4
11130	LOS CERRITOS	3722	0	4
11131	LOS CHINACOS	3722	0	4
11132	PAMPA IPORA GUAZU	3722	0	4
11133	AGUA BUENA	3714	0	4
11134	BOTIJA	3714	0	4
11135	CONCEPCION DEL BERMEJO	3708	0	4
11136	LORENA	3714	0	4
11137	LOS FRENTONES	3712	0	4
11138	PAMPA BORRACHO	3708	0	4
11139	PAMPA DEL INFIERNO	3708	0	4
11140	PAMPA HERMOSA	3708	0	4
11141	PAMPA JUANITA	3708	0	4
11142	POZO HONDO	3714	0	4
11143	RIO MUERTO	3712	0	4
11144	TACO POZO	3714	0	4
11145	CABRAL CUE	3518	0	4
11146	CANCHA LARGA	3518	0	4
11147	COLONIA RIO DE ORO	3518	0	4
11148	EL CAMPAMENTO	3524	0	4
11149	EL LAPACHO	3518	0	4
11150	EL MIRASOL	3524	0	4
11151	EL RETIRO	3522	0	4
11152	FLORADORA	3522	0	4
11153	GANDOLFI	3526	0	4
11154	GENERAL VEDIA	3522	0	4
11155	GUAYCURU	3518	0	4
11156	ISLA DEL CERRITO	3505	0	4
11157	KILOMETRO 76 RIO BERMEJO	3526	0	4
11158	LA LEONESA	3518	0	4
11159	LA MAGDALENA	3522	0	4
11160	LA POSTA	3524	0	4
11161	LA RINCONADA	3524	0	4
11162	LAGUNA PATOS	3518	0	4
11163	LAPACHO	3518	0	4
11164	LAS PALMAS	3518	0	4
11165	LAS ROSAS	3518	0	4
11166	LOMA ALTA	3518	0	4
11167	MIERES	3524	0	4
11168	PUERTO BERMEJO	3524	0	4
11169	PUERTO LAS PALMAS	3518	0	4
11170	PUERTO EVA PERON	3526	0	4
11171	RANCHOS VIEJOS	3518	0	4
11172	RINCON DEL ZORRO	3518	0	4
11173	RIO BERMEJO	3524	0	4
11174	RIO DE ORO	3518	0	4
11175	SAN CARLOS	3522	0	4
11176	SAN EDUARDO	3522	0	4
11177	SAN FERNANDO	3518	0	4
11178	SOLALINDE	3524	0	4
11179	TACUARI	3518	0	4
11180	TIMBO	3524	0	4
11181	TRES HORQUETAS	3522	0	4
11182	VELAZ	3526	0	4
11183	PUNTA DE RIELES	3518	0	4
11184	QUIA	3518	0	4
11185	CERRITO	3730	0	4
11186	COLONIA JUAN LARREA	3730	0	4
11187	EL PUCA	3730	0	4
11188	PAMPA BARRERA	3730	0	4
11189	PUEBLO PUCA	3730	0	4
11190	SANTA ELVIRA	3731	0	4
11191	TRES ESTACAS	3731	0	4
11192	CHARATA	3730	0	4
11193	GENERAL NECOCHEA	3730	0	4
11194	MESON DE FIERRO	3731	0	4
11195	PAMPA CABRERA	3731	0	4
11196	PAMPA SOMMER	3730	0	4
11198	COLONIA BERNARDINO RIVADAVIA	3701	0	4
11199	BARRIO GRAL JOSE DE SAN MARTIN	3700	0	4
11200	BARRIO SARMIENTO	3700	0	4
11201	COLONIA BAJO HONDO	3700	0	4
11202	GIRASOL	3703	0	4
11203	KILOMETRO 15	3700	0	4
11204	LAS CUCHILLAS CNIA J MARMOL	3701	0	4
11205	PAMPA AGUADO	3700	0	4
11206	PAMPA ALEGRIA	3700	0	4
11207	PAMPA DE LOS LOCOS	3700	0	4
11208	PAMPA FLORIDA	3703	0	4
11209	PAMPA GALPON	3700	0	4
11210	PAMPA LOCA	3700	0	4
11211	PRESIDENCIA ROQUE SAENZ PEÃ‘A	3700	0	4
11212	CABEZA DE TIGRE	3540	0	4
11213	KILOMETRO 596	3541	0	4
11214	SANTA MARIA	3541	0	4
11215	CAMPO EL JACARANDA	3733	0	4
11216	CHOROTIS	3733	0	4
11217	SANTA SYLVINA	3541	0	4
11218	ZUBERBHULER	3733	0	4
11219	AMAMBAY	3718	0	4
11220	CORZUELA	3718	0	4
11221	COLONIA JUAN PENCO	3514	0	4
11222	COLONIA MIXTA	3514	0	4
11223	HIVONNAIT	3514	0	4
11224	KILOMETRO 29	3514	0	4
11225	KILOMETRO 34	3514	0	4
11226	KILOMETRO 38	3514	0	4
11227	KILOMETRO 5	3514	0	4
11228	LA ELABORADORA	3514	0	4
11229	LAGUNA ESCONDIDA	3514	0	4
11230	PUENTE PHILIPPON	3514	0	4
11231	PUENTE SVRITZ	3514	0	4
11232	EL OBRAJE	3514	0	4
11233	KILOMETRO 2 FCGB	3514	0	4
11234	KILOMETRO 22	3514	0	4
11235	LA ESCONDIDA	3514	0	4
11236	LA VERDE	3514	0	4
11237	LAPACHITO	3514	0	4
11238	MAKALLE	3514	0	4
11240	LA LIBERTAD	3705	0	4
11241	JUAN JOSE CASTELLI	3705	0	4
11242	EL ESPINILLO	3703	0	4
11243	EL PINTADO	3705	0	4
11245	EL QUEBRACHAL	3705	0	4
11246	EL SAUZALITO	3705	0	4
11247	FORTIN LAVALLE	3703	0	4
11248	FUERTE ESPERANZA	3705	0	4
11249	KILOMETRO 184	3620	0	4
11250	MANANTIALES	3705	0	4
11251	MIRAFLORES	3705	0	4
11252	MISION NUEVA POMPEYA	3705	0	4
11253	NUEVA POBLACION	3705	0	4
11254	POZO DE LAS GARZAS	3705	0	4
11255	POZO NAVAGAN	3621	0	4
11256	VILLA RIO BERMEJITO	3703	0	4
11257	WICHI	3705	0	4
11258	AVIA TERAI	3706	0	4
11259	CAMPO LARGO	3716	0	4
11260	CNIA AGRICOLA PAMPA NAPENAY	3706	0	4
11261	COLONIA JOSE MARMOL	3700	0	4
11262	COLONIA MALGRATTI	3716	0	4
11263	COLONIA MARIANO SARRATEA	3706	0	4
11264	EL CATORCE	3706	0	4
11265	FORTIN LAS CHU	3716	0	4
11266	LA MASCOTA	3706	0	4
11268	MALBALAES	3701	0	4
11269	NAPENAY	3706	0	4
11270	PAMPA DEL REGIMIENTO	3706	0	4
11271	PAMPA GRANDE	3701	0	4
11272	PAMPA OCULTA	3716	0	4
11273	CAMPO EL BERMEJO	3509	0	4
11274	CAMPO WINTER	3509	0	4
11275	CIERVO PETISO	3515	0	4
11276	COLONIA CORONEL DORREGO	3511	0	4
11277	COLONIA RODRIGUEZ PE	3511	0	4
11278	COLONIA SIETE ARBOLES	3509	0	4
11279	GENERAL JOSE DE SAN MARTIN	3509	0	4
11280	KILOMETRO 39	3509	0	4
11281	KILOMETRO 42	3509	0	4
11282	KILOMETRO 48	3509	0	4
11283	KILOMETRO 59	3509	0	4
11284	LAGUNA LIMPIA	3515	0	4
11285	LOS POZOS	3511	0	4
11286	PAMPA ALMIRON	3507	0	4
11287	PAMPA DEL INDIO	3531	0	4
11288	PRESIDENCIA ROCA	3511	0	4
11289	PUERTO ZAPALLAR	3509	0	4
11290	SANTOS LUGARES	3531	0	4
11291	SELVAS DEL RIO DE ORO	3507	0	4
11292	VENEZUELA	3509	0	4
11293	10 DE MAYO	3705	0	4
11294	LA EDUVIGIS	3507	0	4
11295	CAMPO DE LA CHOZA	3514	0	4
11296	CAMPO ECHEGARAY	3514	0	4
11297	COLONIA ECHEGARAY	3514	0	4
11298	COLONIA POPULAR	3505	0	4
11299	CORONEL AVALOS	3505	0	4
11300	FORTIN CARDOSO	3513	0	4
11301	GENERAL DONOVAN	3514	0	4
11302	GENERAL OBLIGADO	3513	0	4
11303	KILOMETRO 501	3513	0	4
11304	LA CHOZA	3513	0	4
11305	LAGUNA BELIGAY	3505	0	4
11306	LAGUNA BLANCA	3514	0	4
11307	PUERTO BASTIANI	3505	0	4
11308	PUERTO TIROL	3505	0	4
11309	RIO ARAZA	3514	0	4
11310	VILLA JALON	3505	0	4
11311	LA EVANGELICA	3505	0	4
11312	ALELOY	3703	0	4
11313	COLONIA VELEZ SARSFIELD	3703	0	4
11314	EL BOQUERON	3703	0	4
11316	EL PALMAR  TRES ISLETAS	3703	0	4
11317	LA POBLADORA	3703	0	4
11318	PAMPA AGUARA	3703	0	4
11319	PAMPA VARGAS	3703	0	4
11320	EL TREINTA Y SEIS	3703	0	4
11321	KILOMETRO 841	3703	0	4
11322	KILOMETRO 884	3703	0	4
11323	TRES ISLETAS	3703	0	4
11324	AVANZADA	3540	0	4
11325	COLONIA EL TIGRE	3541	0	4
11326	COLONIA JUAN JOSE PASO	3540	0	4
11327	COLONIA MATHEU	3540	0	4
11328	CORONEL DU GRATY	3541	0	4
11329	EL ESQUINERO	3543	0	4
11330	EL 	3541	0	4
11331	EL PORVENIR	3543	0	4
11332	ENRIQUE URIEN	3543	0	4
11333	FORTIN POTRERO	3540	0	4
11334	LA 	3540	0	4
11335	LA NUEVA	3540	0	4
11336	LA OFELIA	3540	0	4
11337	LOS FORTINES	3540	0	4
11338	LOS GANSOS	3540	0	4
11339	PUEBLO CLODOMIRO DIAZ	3541	0	4
11340	TUCURU	3540	0	4
11341	VILLA ANGELA	3540	0	4
11342	LA TIGRA	3701	0	4
11343	LA CLOTILDE	3701	0	4
11344	MALBALAES	3701	0	4
11345	SAN BERNARDO	3701	0	4
11346	COLONIA CORONEL BRANDSEN	3536	0	4
11347	GUAYAIBI	3531	0	4
11348	COLONIA HERRERA	3536	0	4
11349	COLONIA HIPOLITO VIEYTES	3536	0	4
11350	COLONIA SANTA ELENA	3536	0	4
11351	CORONEL BRANDSEN	3536	0	4
11352	CUATRO ARBOLES	3536	0	4
11353	EL CURUNDU	3536	0	4
11354	FORTIN AGUILAR	3532	0	4
11355	FORTIN CHAJA	3536	0	4
11356	LAS BANDERAS	3536	0	4
11357	MARTINEZ DE HOZ	3536	0	4
11358	PASO DEL OSO	3536	0	4
11359	PRESIDENCIA DE LA PLAZA	3536	0	4
11360	CAMPO FELDMAN	3530	0	4
11361	COLONIA PUENTE URIBURU	3530	0	4
11362	LA CHIQUITA	3701	0	4
11363	LA MATANZA	3531	0	4
11364	PAMPA VERDE	3531	0	4
11365	PICADITAS	3530	0	4
11366	QUITILIPI	3530	0	4
11367	REDUCCION NAPALPI	3530	0	4
11368	VILLA EL PALMAR	3530	0	4
11369	BARRANQUERAS	3503	0	4
11370	EL PALMAR	3501	0	4
11371	RESISTENCIA	3500	0	4
11372	TIGRE	3500	0	4
11373	VILLA ALTA	3500	0	4
11374	BASAIL	3516	0	4
11375	CACUI	3514	0	4
11376	CAMPO DE GALNASI	3501	0	4
11377	COLONIA BARANDA	3505	0	4
11378	COLONIA PUENTE PHILIPON	3514	0	4
11379	COLONIA TACUARI	3516	0	4
11380	EL BA	3516	0	4
11381	FONTANA	3514	0	4
11382	KILOMETRO 34	3516	0	4
11383	LA COLONIA	3500	0	4
11384	LA GANADERA	3505	0	4
11385	LA ISLA	3503	0	4
11386	LA LIGURIA	3501	0	4
11387	LA PALOMETA	3505	0	4
11388	LIVA	3514	0	4
11389	LOS ALGARROBOS	3505	0	4
11390	LOS PALMARES	3516	0	4
11391	MARIA SARA	3505	0	4
11392	PARALELO 28	3516	0	4
11393	PUENTE PALOMETA	3505	0	4
11394	PUERTO VICENTINI	3514	0	4
11395	PUERTO VILELAS	3503	0	4
11397	TROPEZON	3500	0	4
11398	VICENTINI	3514	0	4
11399	VILLA BARBERAN	3500	0	4
11400	VILLA EL DORADO	3500	0	4
11401	VILLA FORESTACION	3503	0	4
11402	VILLA JUAN DE GARAY	3500	0	4
11403	VILLA LIBERTAD	3500	0	4
11405	KILOMETRO 525	3545	0	4
11406	KILOMETRO 530	3545	0	4
11407	SAMUHU	3543	0	4
11408	VILLA BERTHET	3545	0	4
11409	CAPITAN SOLARI	3515	0	4
11410	COLONIA ELISA	3515	0	4
11411	COLONIAS UNIDAS	3515	0	4
11412	INGENIERO BARBET	3515	0	4
11413	KILOMETRO 602	3515	0	4
11414	LAS GARCITAS	3515	0	4
11415	SALTO DE LA VIEJA	3515	0	4
11416	KILOMETRO 575	3515	0	4
11417	LA DIFICULTAD	3515	0	4
11418	LA PASTORIL	3515	0	4
11419	ARBOL SOLO	3513	0	4
11420	CHARADAI	3513	0	4
11421	COTE LAI	3513	0	4
11422	ESTERO REDONDO	3513	0	4
11423	HORQUILLA	3543	0	4
11424	KILOMETRO 443	3513	0	4
11425	KILOMETRO 498	3543	0	4
11426	KILOMETRO 520	3543	0	4
11427	LA SABANA	3513	0	4
11428	LA VICU	3513	0	4
11429	LAS TOSCAS	3513	0	4
11430	MACOMITAS	3513	0	4
11431	OBRAJE LA VICU	3513	0	4
11432	RIO TAPENAGA	3513	0	4
11433	HAUMONIA	3543	0	4
11434	LOS CHIRIGUANOS	3632	0	9
11436	AGUA SUCIA	4449	0	17
11437	ALGARROBAL	4446	0	17
11438	ALTO ALEGRE	4449	0	17
11439	CABEZA DE ANTA	4434	0	17
11440	APOLINARIO SARAVIA	4449	0	17
11441	EL ARENAL	4446	0	17
11442	ARITA	4449	0	17
11443	BARREALITO	4449	0	17
11444	CAMPO ALEGRE	4449	0	17
11445	CARRERAS	4434	0	17
11446	CEIBALITO	4446	0	17
11447	CHA	4446	0	17
11448	CHORROARIN	4446	0	17
11450	COLONIA HURLINGHAM	4449	0	17
11451	CORONEL MOLLINEDO	4449	0	17
11452	CORONEL OLLEROS	4446	0	17
11453	CORONEL VIDT	4448	0	17
11454	DIVISADERO	4446	0	17
11455	EL BORDO	4449	0	17
11456	EL CARMEN	4449	0	17
11457	EL CARRIZAL	4446	0	17
11458	EL JARAVI	4446	0	17
11459	EL LIBANO	4434	0	17
11460	EL MANANTIAL	4449	0	17
11461	EL NARANJO	4434	0	17
11462	EL PACARA	4446	0	17
11463	EL PERICOTE	4449	0	17
11464	EL QUEBRACHAL	4452	0	17
11465	EL REY	4434	0	17
11466	EL SIMBOLAR	4423	0	17
11467	EL VENCIDO	4452	0	17
11468	EL YESO	4434	0	17
11469	ESPINILLO	4449	0	17
11470	ESQUINA	4449	0	17
11471	ESTANCIA VIEJA	4434	0	17
11472	FINCA MISION ZENTA	4448	0	17
11473	FLORESTA	4452	0	17
11474	FUERTE EL PITO	4452	0	17
11475	GAONA	4452	0	17
11476	GENERAL PIZARRO	4449	0	17
11477	GONZALEZ	4434	0	17
11478	JOAQUIN V GONZALEZ	4448	0	17
11479	KILOMETRO 1088	4448	0	17
11480	KILOMETRO 1104	4449	0	17
11481	KILOMETRO 1152	4452	0	17
11482	LA CUESTITA ANTA	4434	0	17
11483	LA MANGA	4446	0	17
11484	LAGUNA BLANCA	4448	0	17
11485	LAGUNA VERDE	4449	0	17
11486	LAS BATEAS	4449	0	17
11487	LAS FLACAS	4434	0	17
11488	LAS FLORES	4449	0	17
11489	LAS LAJITAS	4449	0	17
11490	LAS TORTUGAS	4449	0	17
11491	LAS VIBORAS	4434	0	17
11492	LIMONCITO	4448	0	17
11493	LLUCHA	4452	0	17
11494	LOS CHIFLES	4446	0	17
11495	LOS NOGALES	4434	0	17
11496	LUIS BURELA	4449	0	17
11497	MACAPILLO	4452	0	17
11498	MANGA VIEJA	4452	0	17
11499	MEDIA LUNA	4449	0	17
11500	MINAS YPF	4448	0	17
11501	MOLLE POZO	4446	0	17
11502	MONASTERIOS	4449	0	17
11503	NUESTRA SE	4452	0	17
11504	PALERMO	4449	0	17
11505	LAS PALMAS	4449	0	17
11506	PASO DE LA CRUZ	4434	0	17
11507	PASO DE LAS CARRETAS	4446	0	17
11508	PIQUETE CABADO	4449	0	17
11509	PIQUETE DE ANTA	4448	0	17
11510	POBLACION	4448	0	17
11511	EL PORVENIR	4452	0	17
11512	POTRERILLO	4446	0	17
11513	POZO GRANDE	4449	0	17
11514	POZO VERDE	4449	0	17
11515	PRINGLES	4452	0	17
11516	PULI	4446	0	17
11517	QUEBRACHAL	4452	0	17
11518	RIO DEL VALLE	4449	0	17
11519	ROCA	4452	0	17
11520	ROSARIO DEL DORADO	4449	0	17
11521	SALADILLO	4434	0	17
11522	SAN GABRIEL	4452	0	17
11523	SAN JUAN	4446	0	17
11524	SAN LUIS	4449	0	17
11525	SAN MARTIN	4449	0	17
11526	SAN RAMON	4449	0	17
11527	SAN SEBASTIAN	4434	0	17
11528	SANTA ROSA	4449	0	17
11529	SANTA ROSA DE ANTA	4452	0	17
11530	SANTO DOMINGO	4449	0	17
11531	SAUCE BAJADA	4434	0	17
11532	SAUCE SOLO	4448	0	17
11533	SIMBOLAR	4452	0	17
11534	SANTO DOMINGO	4448	0	17
11536	SUNCHALITO	4452	0	17
11537	TACO PAMPA	4452	0	17
11538	TALAVERA	4452	0	17
11539	TOLLOCHE	4452	0	17
11540	TORO PAMPA	4452	0	17
11541	TOTORAL	4449	0	17
11542	TUNALITO	4449	0	17
11543	VENCIDA	4452	0	17
11544	VINAL POZO	4452	0	17
11545	YASQUIASME	4430	0	17
11546	CACHI	4417	0	17
11547	LA PAYA	4419	0	17
11548	PALERMO OESTE	4415	0	17
11549	PAYOGASTA	4415	0	17
11550	PUEBLO VIEJO	4417	0	17
11551	PUERTA DE LA PAYA	4417	0	17
11552	PUIL	4417	0	17
11553	PUNTA DE AGUA	4415	0	17
11554	RIO TORO	4417	0	17
11555	SAN JOSE DE ESCALCHI	4419	0	17
11556	VALLECITO	4644	0	17
11557	CAFAYATE	4427	0	17
11558	EL RECREO	4427	0	17
11559	LA ARMONIA	4427	0	17
11560	LA BANDA	4427	0	17
11561	LA PUNILLA	4427	0	17
11562	LAS CONCHAS	4427	0	17
11563	LOROHUASI	4427	0	17
11564	TOLOMBON	4141	0	17
11565	YACOCHUYA	4427	0	17
11566	SALTA	4400	0	17
11567	CERRILLOS	4403	0	17
11568	EL LEONCITO	4421	0	17
11569	LA MERCED	4421	0	17
11570	LAS PIRCAS	4421	0	17
11571	LAS TIENDITAS	4421	0	17
11572	SAN GERONIMO	4421	0	17
11573	SAN MARTIN	4421	0	17
11574	SUMALAO	4421	0	17
11575	AGUA NEGRA	4415	0	17
11576	BELLA VISTA	4423	0	17
11577	CACHO MOLINO	4421	0	17
11578	CALVIMONTE	4421	0	17
11579	CAMPO ALEGRE	4423	0	17
11580	CHICOANA	4423	0	17
11581	CHIVILME	4423	0	17
11582	CUESTA DEL OBISPO	4417	0	17
11583	DOCTOR FACUNDO ZUVIRIA	4423	0	17
11584	EL CANDADO	4415	0	17
11585	EL CARRIL	4421	0	17
11586	EL MARAY	4415	0	17
11587	EL MOYAR	4423	0	17
11588	EL QUEMADO	4423	0	17
11589	EL TIPAL	4423	0	17
11590	LA CALAVERA	4423	0	17
11591	LA ESPERANZA	4423	0	17
11592	LA GUARDIA	4423	0	17
11593	LA MARGARITA	4423	0	17
11594	LA MAROMA	4423	0	17
11595	LA TOMA	4421	0	17
11596	LAS ANIMAS	4415	0	17
11597	LAS GARZAS	4421	0	17
11598	LAS MORAS	4423	0	17
11599	LAS ZANJAS	4415	0	17
11600	LOS LOS	4423	0	17
11601	MAL PASO	4415	0	17
11602	MOLINO	4423	0	17
11603	PALMIRA	4423	0	17
11604	PEDREGAL	4423	0	17
11605	PE	4423	0	17
11606	POTRERO DE DIAZ	4423	0	17
11607	PULARES	4423	0	17
11608	QUEBRADA DE ESCOIPE	4415	0	17
11609	SAN ANTONIO CHICOANA	4421	0	17
11610	SAN FERNANDO DE ESCOIPE	4423	0	17
11611	SAN JOAQUIN	4423	0	17
11612	SAN JOSE	4421	0	17
11613	SAN JOSE DE LA VI	4423	0	17
11614	SAN MARTIN LA CUESTA	4415	0	17
11615	SANTA ANA	4423	0	17
11616	SANTA GERTRUDIS	4423	0	17
11617	SANTA ROSA	4423	0	17
11618	TILIAN	4423	0	17
11619	VILLA FANNY	4423	0	17
11620	VI	4423	0	17
11621	YACERA	4415	0	17
11623	AGUAS CALIENTES	4430	0	17
11624	ALGARROBAL	4430	0	17
11625	BETANIA	4432	0	17
11626	CABEZA DE BUEY	4434	0	17
11627	CAMPO SANTO	4432	0	17
11628	CANTERA DEL SAUCE	4432	0	17
11629	CHACRA EXPERIMENTAL	4430	0	17
11630	COBA	4434	0	17
11631	COBOS	4432	0	17
11632	CRUZ QUEMADA	4434	0	17
11633	EBRO	4434	0	17
11634	EL ALGARROBO	4434	0	17
11635	EL BORDE DE SAN MIGUEL	4432	0	17
11636	EL ESTANQUE	4434	0	17
11637	EL OSO	4434	0	17
11638	EL SAUCE	4432	0	17
11639	EL ZANJON	4434	0	17
11640	GALLINATO	4432	0	17
11641	INGENIO SAN ISIDRO	4432	0	17
11642	KILOMETRO 1094	4430	0	17
11643	KILOMETRO 1102	4432	0	17
11644	LA OFELIA	4432	0	17
11645	LA OLIVA	4432	0	17
11646	LA PUNTILLA	4434	0	17
11647	LA RAMADA	4432	0	17
11648	LA TRAMPA	4434	0	17
11649	LA VI	4432	0	17
11650	LAS MESITAS	4434	0	17
11651	LAS VERTIENTES SANTA RITA DE	4430	0	17
11652	LECHIGUANA	4434	0	17
11653	LOS CORRALES	4434	0	17
11654	MADRE VIEJA	4430	0	17
11655	OJO DE AGUA	4430	0	17
11656	PALOMITAS	4434	0	17
11657	PUESTO VIEJO	4430	0	17
11658	QUISTO	4430	0	17
11659	RODEO GRANDE	4432	0	17
11660	SALADILLO	4430	0	17
11661	SAN ISIDRO	4430	0	17
11662	SAN MARTIN	4432	0	17
11663	SANTA ROSA	4432	0	17
11664	SAUSALITO	4430	0	17
11665	TORZALITO	4430	0	17
11666	VILLA MAYOR ZABALETA	4430	0	17
11667	VIRGILIO TEDIN	4434	0	17
11668	ZAPALLITO	4430	0	17
11669	ACAMBUCO	4568	0	17
11670	AGUARAY	4566	0	17
11671	ANTONIO QUIJARRO	4552	0	17
11672	ARENAL	4560	0	17
11673	BUEN LUGAR	4550	0	17
11674	CAMINERA SAN PEDRITO	4563	0	17
11675	CAMPAMENTO TABLILLA	4563	0	17
11676	CAMPAMENTO VESPUCIO	4563	0	17
11677	CAMPICHUELO	4552	0	17
11678	CAMPO DURAN	4566	0	17
11679	CAMPO LIBRE	4554	0	17
11680	COLONIA OTOMANA	4550	0	17
11681	CORONEL CORNEJO	4552	0	17
11682	CORRALITO	4552	0	17
11683	CORZUELA	4550	0	17
11684	DRAGONES	4554	0	17
11685	EL AGUAY	4563	0	17
11686	EL CUCHILLO	4550	0	17
11687	EL ESPINILLO	4554	0	17
11688	EL RETIRO	4550	0	17
11689	EMBARCACION	4550	0	17
11690	EMBOSCADA	4554	0	17
11691	GENERAL BALLIVIAN	4552	0	17
11692	GENERAL ENRIQUE MOSCONI	4562	0	17
11693	HICKMANN	4554	0	17
11694	ITUYURO	4566	0	17
11695	KILOMETRO 1306 FCGB	4550	0	17
11696	KILOMETRO 1398	4562	0	17
11697	KILOMETRO 1448	4564	0	17
11698	LA FORTUNA	4550	0	17
11699	LA QUENA	4550	0	17
11700	LAS LOMITAS	4562	0	17
11701	LOS BALDES	4550	0	17
11702	LOTE ESTELA	4533	0	17
11703	LUNA MUERTA	4554	0	17
11704	MACUETA	4566	0	17
11705	MANUELA PEDRAZA	4560	0	17
11706	MISION CHAQUE	4554	0	17
11707	MISTOLAR	4554	0	17
11708	MONTE CARMELO	4554	0	17
11709	NUEVO PORVENIR	4550	0	17
11710	OTOMANA	4550	0	17
11711	EST POCITOS	4568	0	17
11712	PASTOR SEVILLOSA	4552	0	17
11713	PEDRO LOZANO	4554	0	17
11714	PIQUIRENDA	4564	0	17
11715	PLUMA DEL PATO	4560	0	17
11716	POCOY	4552	0	17
11717	POZO BRAVO	4554	0	17
11718	PUESTO GRANDE	4550	0	17
11719	RECAREDO	4563	0	17
11720	RIO CARAPAN	4566	0	17
11721	SANTA VICTORIA	4550	0	17
11722	SENDA HACHADA ESTACION FCGB	4552	0	17
11723	TABACO CIMARRON	4554	0	17
11724	TARTAGAL	4560	0	17
11725	TOBANTIRENDA	4564	0	17
11726	TONONO	4560	0	17
11727	TRANQUITAS	4552	0	17
11728	VESPUCIO	4562	0	17
11729	VILLA SAAVEDRA	4560	0	17
11730	YACUY	4564	0	17
11731	YARIGUARENDA	4560	0	17
11732	ACOSTA	4425	0	17
11733	CAMPOS DE ALEMANIA	4425	0	17
11734	BODEGUITA	4425	0	17
11735	CARAHUASI	4425	0	17
11736	CEVILAR	4425	0	17
11737	COROPAMPA	4425	0	17
11738	DURAZNO	4425	0	17
11739	FINCA EL CARMEN	4425	0	17
11740	GUACHIPAS	4425	0	17
11741	LA COSTA	4425	0	17
11742	LA FLORIDA	4425	0	17
11743	LA PAMPA	4425	0	17
11744	LA POBLACION	4425	0	17
11745	LOS CHURQUIS	4425	0	17
11746	LOS SAUCES	4425	0	17
11747	PAMPA GRANDE	4425	0	17
11748	REDONDO	4425	0	17
11749	RIO ALEMANIA	4425	0	17
11750	SANTA BARBARA	4425	0	17
11751	SANTA ELENA	4425	0	17
11752	SAUCE	4425	0	17
11753	SAUCE REDONDO	4425	0	17
11754	TIPA SOLA	4425	0	17
11755	ASTILLERO	4633	0	17
11756	CANCILLAR	4633	0	17
11757	CASA GRANDE	4633	0	17
11758	CHIYAYOC	4633	0	17
11759	COLANZULI	4633	0	17
11760	FINCA SANTIAGO	4633	0	17
11761	LAS HIGUERAS	4633	0	17
11762	IRUYA	4633	0	17
11763	ISLA DE CA	4531	0	17
11764	LA HUERTA	4633	0	17
11765	MATANCILLAS	4633	0	17
11766	MOLINO	4644	0	17
11767	MOLLAR	4644	0	17
11768	PINAL	4633	0	17
11769	RODEO COLORADO	4633	0	17
11770	SAN ANTONIO DE IRUYA	4633	0	17
11771	SAN ISIDRO DE IRUYA	4633	0	17
11772	SAN JUAN	4633	0	17
11773	SAN PEDRO DE IRUYA	4633	0	17
11774	TIPAYOC	4633	0	17
11775	TOROYOC	4644	0	17
11776	UCHOGOL	4633	0	17
11777	VILLA ALEM	4633	0	17
11778	VIZCARRA	4644	0	17
11779	VOLCAN HIGUERAS	4633	0	17
11780	MOJOTORO	4432	0	17
11781	VILLA SAN LORENZO	4401	0	17
11782	BARRO NEGRO	4415	0	17
11783	EL RODEO	4415	0	17
11784	LA POMA	4415	0	17
11785	LOMA DE BURRO	4415	0	17
11786	MINA SAN ESTEBAN	4415	0	17
11787	MINA SAN GUILLERMO	4415	0	17
11788	MINA SAN WALTERIO	4415	0	17
11789	MINAS VICTORIA	4415	0	17
11790	PUEBLO VIEJO	4415	0	17
11791	TRIGAL	4415	0	17
11792	VILLITAS	4415	0	17
11793	ABLOME	4421	0	17
11794	AMPASCACHI	4421	0	17
11795	BELLA VISTA	4421	0	17
11796	CABRA CORRAL DIQUE	4421	0	17
11797	CASTA	4425	0	17
11798	CORONEL MOLDES	4421	0	17
11799	EL ACHERAL	4425	0	17
11800	EL CARANCHO	4421	0	17
11801	EL CARMEN	4421	0	17
11802	ENTRE RIOS	4430	0	17
11803	GUALIANA	4421	0	17
11804	KILOMETRO 1176 300	4421	0	17
11805	LA ARGENTINA	4421	0	17
11806	LA ARMONIA	4421	0	17
11807	LA BODEGA	4421	0	17
11808	LA COSTA	4421	0	17
11809	LA VI	4425	0	17
11810	LAS CA	4421	0	17
11811	LAS LECHUZAS	4425	0	17
11812	OSMA	4421	0	17
11813	PASO DEL RIO	4421	0	17
11814	PE	4421	0	17
11815	PIEDRAS MORADAS	4421	0	17
11816	PUENTE DE DIAZ	4421	0	17
11817	QUISCA LORO	4421	0	17
11818	RETIRO	4421	0	17
11819	SALADILLO DE OSMA	4421	0	17
11820	SAN ANTONIO LA VI	4421	0	17
11821	SAN NICOLAS	4421	0	17
11822	SAN VICENTE	4421	0	17
11823	SAUCE ALEGRE	4421	0	17
11824	SEVILLAR	4421	0	17
11825	SI	4421	0	17
11826	TALAPAMPA	4425	0	17
11827	TRES ACEQUIAS	4421	0	17
11828	CAIPE	4413	0	17
11829	SALAR DEL HOMBRE MUERTO	4419	0	17
11830	SALADILLO	4415	0	17
11831	SAN ANTONIO DE LOS COBRES	4411	0	17
11832	ACHARAS	4434	0	17
11833	ALTO DEL MISTOL	4446	0	17
11834	ARROCERO ITALIANO	4444	0	17
11835	BAJO GRANDE	4446	0	17
11836	BALDERRAMA	4440	0	17
11837	CAMPO ALEGRE	4440	0	17
11838	CAMPO AZUL	4440	0	17
11839	CHILCAS	4434	0	17
11840	CONCHAS	4440	0	17
11841	DURAZNO	4440	0	17
11843	EL GALPON	4444	0	17
11844	EL GUANACO	4440	0	17
11845	EL PARQUE	4444	0	17
11846	EL SAUZAL	4440	0	17
11847	EL TUNAL	4446	0	17
11848	ESTECO EMBARCADERO FCGB	4440	0	17
11849	FINCA ARMONIA	4444	0	17
11850	FINCA ROCCA	4444	0	17
11851	JURAMENTO	4434	0	17
11852	LA AGUADITA	4440	0	17
11853	LA ARMONIA	4444	0	17
11854	LA CARRETERA	4446	0	17
11855	LA CUESTITA METAN	4434	0	17
11856	LA POBLACION	4444	0	17
11857	LA POSTA	4434	0	17
11858	LAGUNITA NUEVA POBLACION	4446	0	17
11859	LAS ACHERAS	4434	0	17
11860	LAS CUESTITAS	4434	0	17
11861	LAS DELICIAS	4444	0	17
11862	LAS JUNTAS	4440	0	17
11863	LOS ROSALES	4446	0	17
11864	LUMBRERAS	4434	0	17
11865	METAN	4440	0	17
11866	METAN VIEJO	4441	0	17
11867	MIRAFLORES	4434	0	17
11868	NOGALITO	4440	0	17
11869	OVEJERIA	4444	0	17
11870	PASO DEL DURAZNO	4440	0	17
11871	PASTEADERO	4440	0	17
11872	PERU	4440	0	17
11873	POBLACION DE ORTEGA	4444	0	17
11874	POTRERO	4446	0	17
11875	PUNTA DEL AGUA	4440	0	17
11876	QUESERA	4434	0	17
11877	ROSALES	4446	0	17
11878	SAN JOSE DE ORQUERAS	4446	0	17
11879	SANTA ELENA	4440	0	17
11880	SCHNEIDEWIND	4440	0	17
11881	SACHA PERA	4440	0	17
11882	TALA MUYO	4440	0	17
11883	TALAS	4446	0	17
11884	TUNALITO	4446	0	17
11885	VERA CRUZ	4440	0	17
11886	YATASTO	4440	0	17
11887	ANGOSTURA	4419	0	17
11888	BANDA GRANDE	4419	0	17
11889	BREALITO	4419	0	17
11890	BURRO YACO	4419	0	17
11891	CERRO BRAVO	4419	0	17
11892	CERRO DE LA ZORRA VIEJA	4419	0	17
11893	CERRO DEL AGUA DE LA FALDA	4419	0	17
11894	COLMENAR	4419	0	17
11895	COLTE	4419	0	17
11896	CORRIDA DE CORI	4419	0	17
11897	DIAMANTE	4419	0	17
11898	EL BREALITO	4419	0	17
11899	EL CHURCAL	4419	0	17
11900	ESQUINA	4419	0	17
11901	HUMANAS	4419	0	17
11902	LURACATAO	4419	0	17
11903	MOLINOS	4419	0	17
11904	PE	4419	0	17
11905	SAN JOSE DE COLTE	4419	0	17
11906	SECLANTAS ADENTRO	4419	0	17
11907	SECLANTAS	4419	0	17
11908	TACUIL	4419	0	17
11909	TOMUCO	4419	0	17
11910	VOLCAN AZUFRE	4419	0	17
11911	AGUAS BLANCAS	4531	0	17
11912	ALGARROBAL	4534	0	17
11913	ANGEL PEREDO	4533	0	17
11914	ANGELICA	4533	0	17
11915	ARBOL SOLO	4534	0	17
11916	ARENALES	4535	0	17
11917	CHAGUARAL	4537	0	17
11918	COLONIA SANTA ROSA	4531	0	17
11919	POZO DEL CUINCO	4542	0	17
11920	EL MISTOL	4534	0	17
11921	EL QUIMILAR CARBONCITO	4534	0	17
11922	EL TABACAL	4533	0	17
11923	ESTEBAN DE URIZAR	4537	0	17
11924	HIPOLITO YRIGOYEN	4533	0	17
11925	INGENIO SAN MARTIN	4533	0	17
11926	JERONIMO MATORRAS	4537	0	17
11927	KILOMETRO 1281	4534	0	17
11928	KILOMETRO 1291	4534	0	17
11929	KILOMETRO 1280	4534	0	17
11930	KILOMETRO 1298	4533	0	17
11931	LA ESTRELLA	4537	0	17
11932	LAS VARAS	4534	0	17
11933	MANUEL ELORDI	4550	0	17
11934	MARIA LUISA	4533	0	17
11935	MARTINEZ DEL TINEO	4537	0	17
11936	ORAN	4530	0	17
11937	PARANI	4530	0	17
11938	PICHANAL	4534	0	17
11939	PIEDRA DEL POTRILLO	4530	0	17
11940	PIZARRO	4534	0	17
11941	POZO AZUL	4530	0	17
11942	POZO CERCADO	4535	0	17
11943	PUESTO DEL MEDIO	4534	0	17
11944	RIO COLORADO	4530	0	17
11945	RIO DE LAS PIEDRAS	4530	0	17
11946	RIO PESCADO	4530	0	17
11947	SAN ANDRES	4530	0	17
11948	SAN ANTONIO	4530	0	17
11949	SAN BERNARDO	4530	0	17
11950	SAN IGNACIO	4530	0	17
11951	SAN RAMON DE LA NUEVA ORAN	4530	0	17
11952	SANTA CRUZ	4531	0	17
11953	SANTA MARINA	4542	0	17
11954	SANTA ROSA	4534	0	17
11955	SAUCELITO	4538	0	17
11956	SOLEDAD	4530	0	17
11957	TABACAL INGENIO	4533	0	17
11958	TRES POZOS	4530	0	17
11959	URUNDEL	4542	0	17
11960	YACARA	4534	0	17
11961	YUCHAN	4537	0	17
11962	AGUAS MUERTAS	4535	0	17
11963	ALGARROBAL	4535	0	17
11964	ALTO DE LA SIERRA	4561	0	17
11965	ALTO VERDE	4535	0	17
11966	AMBERES	4561	0	17
11967	BELGRANO FORTIN 2	4535	0	17
11968	BELLA VISTA	4535	0	17
11969	CAMPO ARGENTINO	4535	0	17
11970	CAPITAN JUAN PAGE	4554	0	17
11971	EL DESTIERRO	4535	0	17
11972	EL SOLDADITO	4535	0	17
11973	EL TUNALITO	4535	0	17
11974	FORTIN FRIAS	4535	0	17
11975	GENERAL GUEMES	4430	0	17
11976	HITO 1	4561	0	17
11977	LA CANCHA	4535	0	17
11978	LA CHINA	4561	0	17
11979	LA ESQUINITA	4535	0	17
11980	LA MONTA	4535	0	17
11981	PUESTO LA PAZ	4561	0	17
11982	LA TABLADA	4535	0	17
11983	LA UNION	4535	0	17
11984	LAS BOLSAS	4535	0	17
11985	LAS CA	4535	0	17
11986	LAS CONCHAS	4535	0	17
11987	LAS LLAVES	4535	0	17
11988	LOS BLANCOS	4554	0	17
11989	LOS RANCHILLOS	4554	0	17
11990	MARTIN GARCIA	4535	0	17
11991	MEDIA LUNA	4554	0	17
11992	MISION LA PAZ	4561	0	17
11993	MISTOL MAREADO	4554	0	17
11994	MOLLINEDO	4535	0	17
11995	CNEL JUAN SOLA EST MORILLO	4554	0	17
11996	PALMARCITO	4535	0	17
11997	PARAISO	4535	0	17
11998	PASO EL MILAGRO SAN ANICETO	4535	0	17
11999	PORONGAL	4535	0	17
12000	POZO DEL PATO	4535	0	17
12001	POZO DEL ZORRO	4535	0	17
12002	POZO VERDE	4535	0	17
12003	PUESTO DE LA VIUDA	4535	0	17
12004	RESISTENCIA	4554	0	17
12005	RIVADAVIA	4535	0	17
12006	SAN BERNARDO	4561	0	17
12007	SAN ISIDRO	4535	0	17
12008	SAN JOAQUIN	4535	0	17
12009	SAN PATRICIO	4554	0	17
12010	SANTA CLARA	4554	0	17
12011	SANTA MARIA	4561	0	17
12012	SANTA VICTORIA ESTE	4561	0	17
12013	SANTO DOMINGO	4535	0	17
12014	SURI PINTADO	4554	0	17
12015	EL TALA	4126	0	17
12016	TRES POZOS	4554	0	17
12017	VICTORICA	4535	0	17
12018	VILLA PETRONA	4535	0	17
12019	ALMONA	4421	0	17
12020	ANTILLA	4193	0	17
12021	LAS MERCEDES	4193	0	17
12022	SALVADOR MAZZA	4568	0	17
12023	ROSARIO DE LA FRONTERA	4190	0	17
12024	SAN PEDRO	4193	0	17
12025	SANTA MARIA	4193	0	17
12026	CACHI	4409	0	17
12027	CAMPO QUIJANO	4407	0	17
12028	EL POTRERO	4405	0	17
12029	LA SILLETA	4407	0	17
12030	ROSARIO DE LERMA	4405	0	17
12031	AMBLAYO	4425	0	17
12032	ANGASTACO	4427	0	17
12033	ANIMANA	4427	0	17
12034	BARRIAL	4427	0	17
12035	BUENA VISTA	4427	0	17
12036	CORRALITO	4427	0	17
12037	JACIMANA	4427	0	17
12038	LA ARCADIA	4427	0	17
12039	LA VI	4427	0	17
12040	LOS SAUCES	4427	0	17
12041	MONTE VIEJO	4427	0	17
12042	PAYOGASTILLA	4427	0	17
12043	PUCARA	4427	0	17
12044	SAN ANTONIO	4427	0	17
12045	SAN CARLOS	4427	0	17
12046	SAN FELIPE	4427	0	17
12047	SAN LUCAS	4427	0	17
12048	SAN RAFAEL	4427	0	17
12049	SANTA ROSA	4427	0	17
12050	SIMBOLAR	4427	0	17
12051	TONCO	4415	0	17
12052	ACOYTE	4651	0	17
12053	BACOYA	4644	0	17
12054	BARITU	4651	0	17
12055	HORNILLOS	4651	0	17
12056	LA FALDA	4651	0	17
12057	LIZOITE	4651	0	17
12058	LOS TOLDOS	4531	0	17
12059	MESON	4651	0	17
12060	NAZARENO	4651	0	17
12061	PAL TOLCO	4651	0	17
12062	PAPA CHACRA	4651	0	17
12063	PASCALLA	4651	0	17
12064	PUNCA VISCANA	4651	0	17
12065	PUCARA	4651	0	17
12066	PUESTO	4651	0	17
12067	RODEO PAMPA	4651	0	17
12068	SAN FELIPE	4651	0	17
12069	SAN FRANCISCO	4651	0	17
12070	SAN JUAN DE ORO	4651	0	17
12071	SAN LEON	4651	0	17
12073	SANTA CRUZ	4651	0	17
12074	SANTA VICTORIA OESTE	4651	0	17
12075	SOLEDAD	4651	0	17
12076	TRIGO HUAYCO	4651	0	17
12077	TUCTUCA	4651	0	17
12078	AGUA NEGRA	4101	0	24
12079	ALTA GRACIA DE VILLA BURRUYACU	4101	0	24
12080	ANGOSTURA	4117	0	24
12081	ANTA CHICA	4187	0	24
12082	ANTILLAS	4119	0	24
12083	ASERRADERO	4101	0	24
12084	CA	4119	0	24
12085	CA	4117	0	24
12086	CA	4119	0	24
12087	CA	4101	0	24
12088	CA	4101	0	24
12089	CEJA POZO	4187	0	24
12090	CHABELA	4117	0	24
12091	CHA	4117	0	24
12092	CHA	4117	0	24
12093	CHILCA	4119	0	24
12094	COLONIA LOS HILLS	4101	0	24
12095	COLONIA NRO 2	4119	0	24
12096	COLONIA SAN RAMON	4101	0	24
12098	CORTADERAS	4195	0	24
12099	COSSIO	4119	0	24
12100	CUCHILLAS	4101	0	24
12101	EL BACHI	4187	0	24
12102	EL BARCO	4119	0	24
12103	EL CAJON	4119	0	24
12104	EL CHA	4117	0	24
12105	EL CHORRO	4119	0	24
12106	EL ESPINILLO	4117	0	24
12107	EL MUTUL	4101	0	24
12108	EL NARANJO	4117	0	24
12109	EL OBRAJE	4119	0	24
12110	EL PUESTITO	4119	0	24
12111	EL PUESTO DEL MEDIO	4187	0	24
12112	EL RODEO	4119	0	24
12113	EL SAUZAL	4151	0	24
12114	EL TAJAMAR	4119	0	24
12115	EL TIMBO NUEVO	4101	0	24
12116	EL ZAPALLAR	4119	0	24
12117	GARMENDIA	4187	0	24
12118	GOBERNADOR PIEDRABUENA	4187	0	24
12119	JAGUEL	4119	0	24
12120	KILOMETRO 37	4119	0	24
12121	LA ARGENTINA	4119	0	24
12122	LA CA	4119	0	24
12123	LA CIENAGA	4101	0	24
12124	LA CRUZ	4119	0	24
12125	LA FLORIDA	4195	0	24
12126	LA PUERTA	4101	0	24
12127	LA RAMADA	4119	0	24
12128	LA RAMADA DE ABAJO	4119	0	24
12129	LA SALA	4119	0	24
12130	LAGUNA DE ROBLES	4119	0	24
12131	LAS COLAS	4195	0	24
12132	LAS PECHOSAS	4119	0	24
12133	LAS ZANJAS	4119	0	24
12134	LEO HUASI	4101	0	24
12135	LOMA GRANDE	4119	0	24
12136	LOS CHORRILLOS	4119	0	24
12137	LOS HILOS	4101	0	24
12138	LUJAN	4187	0	24
12139	MACOMITA	4117	0	24
12140	MARI	4117	0	24
12141	MATUL	4101	0	24
12142	MEDINA	4101	0	24
12143	MOJON	4115	0	24
12144	MONTE CRISTO	4187	0	24
12145	NIO VILLA PADRE MONTI	4101	0	24
12146	NOGALITO	4101	0	24
12147	NUEVA ROSA	4101	0	24
12148	OJO	4101	0	24
12149	PACARA MARCADO	4119	0	24
12150	PAJA COLORADA	4187	0	24
12151	PALOMITAS	4119	0	24
12152	PAMPA POZO	4242	0	24
12153	PASO DE LA PATRIA	4187	0	24
12154	POZO CAVADO	4162	0	24
12155	POZO DEL ALGARROBO	4119	0	24
12156	POZO GRANDE	4195	0	24
12157	POZO HONDO	4117	0	24
12158	POZO LARGO	4195	0	24
12159	PUERTA ALEGRE	4187	0	24
12160	PUERTA VIEJA	4101	0	24
12161	PUESTO DE LOS VALDES	4149	0	24
12162	PUESTO DE UNCOS	4119	0	24
12163	REQUELME	4119	0	24
12164	RIO DEL NIO	4119	0	24
12165	RIO LORO	4101	0	24
12166	RODEO TORO	4119	0	24
12167	ROSARIO	4187	0	24
12168	SALADILLO	4146	0	24
12169	SAN ARTURO	4187	0	24
12170	SAN CARLOS	4186	0	24
12171	SAN EUSEBIO	4119	0	24
12172	SAN FEDERICO	4187	0	24
12173	SAN IGNACIO	4178	0	24
12174	SAN JOSE	4124	0	24
12175	SAN JOSE DE MACOMITA	4117	0	24
12176	SAN MIGUEL	4119	0	24
12177	SAN PATRICIO	4119	0	24
12178	SAN PEDRO	4187	0	24
12179	SAN RAMON	4149	0	24
12180	SANTA ROSA	4119	0	24
12181	SANTA TERESA	4117	0	24
12182	7 DE ABRIL	4195	0	24
12183	SINQUEAL	4119	0	24
12184	SUNCHAL	4101	0	24
12185	SURIYACU	4195	0	24
12186	TACO	4117	0	24
12187	TACO PALTA	4117	0	24
12188	TALA BAJADA	4195	0	24
12189	TALA POZO	4119	0	24
12190	TAQUELLO	4117	0	24
12191	TARUCA PAMPA	4119	0	24
12192	TIMBO NUEVO	4101	0	24
12193	TIMBO VIEJO	4101	0	24
12194	TINAJEROS	4187	0	24
12195	TRANQUITAS	4101	0	24
12196	TRES SARGENTOS	4101	0	24
12197	TUSCAL REDONDO	4186	0	24
12198	URIZAR	4187	0	24
12199	UTURUNO	4187	0	24
12200	VACAHUASI	4101	0	24
12201	VILLA BENJAMIN ARAOZ	4119	0	24
12202	VILLA BURRUYACU	4119	0	24
12203	VILLA COLMENA	4103	0	24
12204	VILLA DE LOS BRITOS	4101	0	24
12205	VILLA DESIERTO DE LUZ	4187	0	24
12206	VILLA EL BACHE	4187	0	24
12207	VILLA EL RETIRO	4187	0	24
12208	VILLA LA SOLEDAD	4187	0	24
12209	VILLA LA TUNA	4187	0	24
12210	VILLA MARIA	4187	0	24
12211	VILLA MERCEDES	4187	0	24
12212	VILLA MONTE CRISTO	4187	0	24
12213	VILLA NUEVA	4162	0	24
12214	VILLA PADRE MONTI	4101	0	24
12215	VILLA ROSA	4101	0	24
12216	VILLA SAN ANTONIO	4187	0	24
12217	VIRGINIA	4186	0	24
12218	ESTACION EXPERIMENTAL AGRICOLA	4101	0	24
12219	ESTACION SUPERIOR AGRICOLA	4101	0	24
12220	GOBERNADOR NOUGES	4111	0	24
12221	KILOMETRO 792	4105	0	24
12222	NUEVOS MATADEROS	4109	0	24
12223	SAN MIGUEL DE TUCUMAN	4000	0	24
12225	VILLA ZENON SANTILLAN	4000	0	24
12226	ALPACHIRI	4149	0	24
12227	ALTO VERDE	4153	0	24
12228	ARCADIA	4147	0	24
12229	BAJO DE LOS SUELDOS	4151	0	24
12230	BARRIO BELGRANO	4146	0	24
12231	BELICHA HUAICO	4149	0	24
12232	CARRETA QUEMADA	4146	0	24
12233	COCHUNA	4149	0	24
12234	COLONIA FARA	4147	0	24
12235	COLONIA HUMAITA PRIMERA	4151	0	24
12236	COLONIA JUAN JOSE IRAMAIN	4147	0	24
12237	COLONIA PEDRO LEON CORNET	4147	0	24
12238	CONCEPCION	4146	0	24
12239	CORTADERAS	4153	0	24
12240	CUESTA DE CHILCA	4146	0	24
12241	EL CEIBAL	4153	0	24
12242	EL MILAGRO	4151	0	24
12243	EL MISTOLAR	4174	0	24
12244	EL MOLINO	4149	0	24
12245	EL PORVENIR	4151	0	24
12246	EL POTRERILLO	4149	0	24
12247	EL POTRERO	4146	0	24
12248	FINCA ENTRE RIOS	4151	0	24
12249	GASTONA	4149	0	24
12250	GASTONILLA	4147	0	24
12251	HUMAITA 1	4151	0	24
12252	HUMAITA 2	4151	0	24
12253	ILTICO	4146	0	24
12254	INGENIO LA CORONA	4146	0	24
12255	INGENIO LA TRINIDAD	4151	0	24
12256	JAYA	4149	0	24
12257	KILOMETRO 1185	4174	0	24
12258	KILOMETRO 66	4146	0	24
12259	LA CALERA	4158	0	24
12260	LA ESPERANZA	4151	0	24
12261	LA HIGUERA	4122	0	24
12262	LA TRINIDAD	4151	0	24
12263	LAGARTE	4174	0	24
12264	LAS ANIMAS	4149	0	24
12265	LAS FALDAS	4147	0	24
12266	LAS LEGUAS	4149	0	24
12267	LESCANO	4146	0	24
12268	LOS GUCHEA	4151	0	24
12269	LOS TIMBRES	4147	0	24
12270	LOS VEGA	4146	0	24
12271	MARIA LUISA	4174	0	24
12272	MEDINAS	4151	0	24
12273	MEMBRILLO	4146	0	24
12274	MOLINOS	4151	0	24
12275	MONTE RICO	4152	0	24
12276	POSTA	4157	0	24
12277	RESCATE	4174	0	24
12278	RIO SECO KILOMETRO 1207	4174	0	24
12279	RODEO GRANDE	4174	0	24
12280	ROSARIO OESTE	4151	0	24
12281	SAN JOSE	4146	0	24
12282	SAN RAMON CHICLIGASTA	4149	0	24
12283	SUD DE SANDOVALES	4174	0	24
12284	SURIYACO	4174	0	24
12285	VILLA ALVEAR	4146	0	24
12286	VILLA CAROLINA	4147	0	24
12287	VILLA LA TRINIDAD	4151	0	24
12288	YUCUMANITA	4151	0	24
12289	AGUA DULCE	4115	0	24
12290	ALABAMA	4117	0	24
12291	ALDERETES	4178	0	24
12292	ALTO NUESTRA SE	4109	0	24
12293	ARBOL SOLO	4178	0	24
12294	BANDA DEL RIO SALI	4109	0	24
12295	BARRIO BELGRANO	4109	0	24
12296	BLANCO POZO	4178	0	24
12297	BOCA DEL TIGRE	4178	0	24
12298	CAMPO LA FLOR	4178	0	24
12299	CA	4186	0	24
12300	CARBON POZO	4111	0	24
12301	CAROLINAS BAJAS	4117	0	24
12302	CASA ROSADA	4178	0	24
12303	CEJAS DE BE	4178	0	24
12304	CEVIL POZO	4178	0	24
12305	CHA	4117	0	24
12306	COHIGAC	4178	0	24
12307	COLMENA LOLITA	4182	0	24
12309	COLOMBRES	4111	0	24
12310	COLONIA LOLITA NORTE	4182	0	24
12311	CRUZ DEL NORTE ESTACION FCGM	4178	0	24
12312	DELFIN GALLO	4117	0	24
12313	EL BRACHO	4111	0	24
12314	EL CEVILAR COLOMBRES	4111	0	24
12315	EL COCHUCHAL	4117	0	24
12316	EL NARANJITO	4115	0	24
12317	EL PARAISO	4117	0	24
12318	EL PUERTO	4178	0	24
12319	EL PUESTO	4178	0	24
12320	EL RINCON	4186	0	24
12321	EMPALME AGUA DULCE	4178	0	24
12322	FAVORINA	4115	0	24
12323	FINCA ELISA	4111	0	24
12324	FINCA MAYO	4182	0	24
12325	LA FAVORITA	4178	0	24
12326	LA FLOR	4178	0	24
12327	LA FLORIDA	4117	0	24
12328	LA LIBERTAD	4186	0	24
12329	LA MARAVILLA	4124	0	24
12330	LA TALA	4178	0	24
12331	LAPACHITOS	4186	0	24
12332	LAS CEJAS	4186	0	24
12333	LAS MERCEDES	4111	0	24
12334	LAS PALOMITAS	4178	0	24
12335	LAS PIEDRITAS	4178	0	24
12336	LASTENIA	4111	0	24
12337	LOLITA	4182	0	24
12338	LOS GODOS	4117	0	24
12339	LOS GODOY	4186	0	24
12340	LOS GUTIERREZ	4178	0	24
12341	LOS HARDOY	4186	0	24
12342	LOS PEREYRA	4178	0	24
12343	LOS PEREZ	4117	0	24
12344	LOS PORCELES	4111	0	24
12345	LOS RALOS	4182	0	24
12346	LOS VALLISTOS	4109	0	24
12347	LOS VILLAGRA	4111	0	24
12348	LUISIANA ESTACION FCGM	4117	0	24
12349	LUJAN	4117	0	24
12350	MAYO	4182	0	24
12351	MONTE LARGO	4117	0	24
12352	MOYA	4117	0	24
12353	NUEVO PUEBLO LA FLORIDA	4117	0	24
12354	PACARA	4111	0	24
12355	PACARA PINTADO	4111	0	24
12356	PALMAS REDONDAS	4178	0	24
12357	POLITO	4111	0	24
12358	POZO LAPACHO	4186	0	24
12359	PUENTE RIO SALI	4109	0	24
12360	RANCHILLOS	4178	0	24
12361	RANCHILLOS VIEJOS	4178	0	24
12362	RETIRO	4111	0	24
12363	SAN AGUSTIN	4186	0	24
12364	SAN ANTONIO	4115	0	24
12365	SAN JOSE	4186	0	24
12366	SAN MIGUEL	4178	0	24
12367	SAN MIGUELITO	4178	0	24
12368	SAN PEDRO	4117	0	24
12369	SAN PEREYRA	4182	0	24
12370	SAN VICENTE	4178	0	24
12371	SANTA LUISA	4186	0	24
12372	SANTILLAN	4186	0	24
12373	VILLA TERCERA	4182	0	24
12374	GUANACO MUERTO	4178	0	24
12375	GUZMAN ESTACION FCGB	4117	0	24
12376	INGENIO CONCEPCION	4109	0	24
12377	INGENIO CRUZ ALTA	4184	0	24
12378	INGENIO LA FLORIDA	4117	0	24
12379	INGENIO SAN JUAN	4109	0	24
12380	AGUA AZUL	4132	0	24
12381	ARROYO DE LA CRUZ	4132	0	24
12382	BUEN RETIRO	4132	0	24
12383	CAMPO HERRERA	4105	0	24
12384	CA	4129	0	24
12385	CARRICHANGO	4132	0	24
12386	COLONIA EL SUNCHAL	4168	0	24
12387	COLONIA MARIA ELENA	4129	0	24
12388	COLONIA SANTA CLARA	4132	0	24
12389	EL CARMEN	4128	0	24
12390	EL CEIBAL	4105	0	24
12391	EL CRUCE	4132	0	24
12392	EL MOYAR	4168	0	24
12393	EL OBRAJE	4129	0	24
12394	ENTRE RIOS	4166	0	24
12395	FAMAILLA	4132	0	24
12396	FINCA PEREYRA	4132	0	24
12397	FINCA TULIO	4168	0	24
12398	INGENIO LULES	4129	0	24
12399	INVERNADA	4132	0	24
12400	KILOMETRO 102	4132	0	24
12401	KILOMETRO 5	4166	0	24
12402	KILOMETRO 99	4134	0	24
12403	LA AGUADITA	4101	0	24
12404	LA BANDA	4133	0	24
12405	LA CAPILLA	4128	0	24
12406	LA FRONTERITA	4132	0	24
12407	LA RINCONADA PARADA	4107	0	24
12408	LAS BANDERITAS	4132	0	24
12409	LAS MORERAS	4128	0	24
12410	LAS TABLAS	4129	0	24
12411	LAURELES	4132	0	24
12413	MALVINAS	4129	0	24
12414	MANANTIAL DE OVANTA	4105	0	24
12415	MERCEDES	4128	0	24
12416	MONTE GRANDE	4133	0	24
12417	NUEVA BAVIERA	4132	0	24
12418	OBRAJE	4129	0	24
12419	PADILLA	4133	0	24
12420	POTRERO	4129	0	24
12421	PUERTAS GRANDES	4168	0	24
12422	PUNTA DEL MONTE	4129	0	24
12423	QUEBRADA DE LULES	4129	0	24
12424	RIO LULES	4166	0	24
12425	SAN FELIPE	4166	0	24
12426	SAN GABRIEL DEL MONTE	4132	0	24
12427	SAN JENARO	4129	0	24
12428	SAN JOSE DE BUENA VISTA	4132	0	24
12429	SAN JOSE DE LULES	4128	0	24
12430	SAN LUIS	4132	0	24
12431	SAUCE HUACHO	4132	0	24
12432	TRES ALMACENES	4132	0	24
12433	25 DE MAYO	4242	0	24
12434	9 DE JULIO	4242	0	24
12435	ALONGO	4161	0	24
12436	AMUNPA	4176	0	24
12437	ARBOLES GRANDES	4176	0	24
12438	BARRANCAS	4176	0	24
12439	BELTRAN	4242	0	24
12440	CAMPO GRANDE	4159	0	24
12441	CAMPO LA CRUZ	4161	0	24
12442	CASA VIEJA	4162	0	24
12443	CHALCHACITO	4242	0	24
12444	CHILCA	4242	0	24
12445	COCO	4242	0	24
12446	DURAZNO	4242	0	24
12447	EL PARAISO	4242	0	24
12448	EL PUESTITO	4242	0	24
12449	EL QUEBRACHITO	4242	0	24
12450	EL SESTEADERO	4242	0	24
12451	EL TOSTADO	4242	0	24
12452	ENCRUCIJADA	4242	0	24
12453	ESCOBAS	4159	0	24
12454	GRANEROS	4159	0	24
12455	KILOMETRO 19	4162	0	24
12456	LA CA	4242	0	24
12457	LA CHILCA	4242	0	24
12458	LA FLORIDA	4174	0	24
12459	LA GRAMA	4174	0	24
12460	LA IGUANA	4242	0	24
12461	LA LAGUNILLA	4163	0	24
12462	LA TRINIDAD	4151	0	24
12463	LA ZANJA	4242	0	24
12464	LACHICO	4242	0	24
12465	LAMADRID	4176	0	24
12466	LAS BRISAS	4242	0	24
12467	LAS CA	4103	0	24
12468	LAS LOMITAS	4176	0	24
12469	LOS AGUDOS	4157	0	24
12470	LOS AGUIRRE	4174	0	24
12471	LOS CERCOS	4176	0	24
12472	LOS DIAZ	4159	0	24
12473	LOS GONZALEZ	4119	0	24
12474	LOS GRAMAJOS	4159	0	24
12475	LOS PARAISOS	4176	0	24
12476	LOS SAUCES	4176	0	24
12477	MISTOL	4162	0	24
12478	MONTUOSO	4242	0	24
12479	MORON	4242	0	24
12480	PAEZ	4242	0	24
12481	PALO BLANCO	4161	0	24
12482	PALOMAS	4174	0	24
12483	PAMPA LARGA	4159	0	24
12484	POZO HONDO	4242	0	24
12485	PUESTO 9 DE JULIO	4242	0	24
12486	PUESTO LOS AVILAS	4242	0	24
12487	PUESTO LOS PEREZ	4242	0	24
12488	RAMADITAS	4242	0	24
12489	RAMOS	4242	0	24
12490	RETIRO	4162	0	24
12491	ROMERELLO	4163	0	24
12492	RUMI YURA	4242	0	24
12493	SALA VIEJA	4242	0	24
12494	SAN ANTONIO DE QUISCA	4176	0	24
12495	SAN FRANCISCO	4161	0	24
12496	SAN GERMAN	4242	0	24
12497	SAN JUANCITO	4242	0	24
12498	SAN MIGUEL	4242	0	24
12499	SANTA BARBARA	4242	0	24
12500	SANTA CRUZ	4149	0	24
12501	SANTA ROSA	4242	0	24
12502	SAUCE GAUCHO	4242	0	24
12503	SAUCE SECO	4162	0	24
12504	SIMBOL	4242	0	24
12505	SOL DE MAYO	4176	0	24
12506	TACO RALO	4242	0	24
12507	TACO RODEO	4159	0	24
12508	TALA CAIDA	4176	0	24
12509	TALITAS	4242	0	24
12510	TORO MUERTO	4242	0	24
12511	TRES POZOS	4178	0	24
12512	VILTRAN	4242	0	24
12513	YAPACHIN	4242	0	24
12514	YMPAS	4159	0	24
12515	ZAPALLAR	4159	0	24
12517	CAMPO BELLO	4159	0	24
12518	DONATO ALVAREZ	4161	0	24
12519	EL BATIRUANO	4158	0	24
12520	EL CORRALITO	4158	0	24
12521	ESCABA	4158	0	24
12522	KILOMETRO 36	4158	0	24
12523	KILOMETRO 46	4158	0	24
12524	LA PUERTA DE MARAPA	4158	0	24
12525	LOS ARROYO	4158	0	24
12526	LOS GUAYACANES	4158	0	24
12527	MARAPA	4158	0	24
12528	NARANJO ESQUINA	4158	0	24
12529	TALAMUYO	4158	0	24
12530	VILLA BELGRANO	4158	0	24
12531	YAQUILO	4158	0	24
12532	ALTO EL PUESTO	4159	0	24
12533	BAJASTINE	4164	0	24
12534	DOMINGO MILLAN	4161	0	24
12535	EL BAJO	4164	0	24
12536	EL HUAICO	4142	0	24
12537	EL NOGAL	4161	0	24
12538	EL PORVENIR	4162	0	24
12539	EL RINCON	4157	0	24
12540	EL SUNCHO	4164	0	24
12541	HUASA PAMPA NORTE	4163	0	24
12542	KILOMETRO 29	4159	0	24
12543	KILOMETRO 10 FCGB	4161	0	24
12544	LA CA	4159	0	24
12545	LA COCHA	4162	0	24
12546	LA INVERNADA	4158	0	24
12547	LA POSTA	4164	0	24
12548	LAS ABRAS	4187	0	24
12549	LAS CEJAS	4162	0	24
12550	LOS BAJOS	4161	0	24
12551	LOS MOLLES	4242	0	24
12552	LOS PIZARRO	4162	0	24
12553	MAL PASO	4157	0	24
12554	MONTE GRANDE	4162	0	24
12555	MONTE REDONDO	4162	0	24
12556	POZO CAVADO	4162	0	24
12557	PUEBLO VIEJO	4164	0	24
12558	PUESTO NUEVO	4163	0	24
12559	RUMI PUNCO	4164	0	24
12560	SACRIFICIO	4161	0	24
12561	SAN FRANCISCO	4161	0	24
12562	SAN IGNACIO	4162	0	24
12563	SAN LUIS DE LAS CASAS VIEJAS	4159	0	24
12564	SAN PABLO	4129	0	24
12565	SAUCE YACU	4162	0	24
12566	TACO RODEO	4159	0	24
12567	ACOSTILLA	4113	0	24
12568	AGUA BLANCA	4168	0	24
12569	AGUADA	4111	0	24
12570	AHI VEREMOS	4115	0	24
12571	AMAICHA DEL LLANO	4168	0	24
12572	AVESTILLA	4113	0	24
12573	BAJO GRANDE	4111	0	24
12574	BA	4111	0	24
12575	BARREALITO	4115	0	24
12576	BELLA VISTA	4168	0	24
12577	BUENA VISTA	4115	0	24
12578	CACHI HUASI	4168	0	24
12579	CACHI YACO	4113	0	24
12580	CAMAS AMONTONADAS	4168	0	24
12581	CAMPANA	4168	0	24
12582	CAMPO AZUL	4168	0	24
12583	CA	4168	0	24
12584	CA	4168	0	24
12585	CANDELILLAL	4168	0	24
12586	CEVILARCITO	4168	0	24
12587	CHA	4111	0	24
12588	CHA	4168	0	24
12589	COLONIA AGRICOLA	4111	0	24
12590	COLONIA ARGENTINA	4111	0	24
12591	CONDOR HUASI	4115	0	24
12592	CORTADERAL	4111	0	24
12593	CORTADERAS	4111	0	24
12594	COSTA ARROYO ESQUINA	4111	0	24
12595	CUATRO SAUCES	4105	0	24
12596	EL BARRIALITO	4119	0	24
12597	EL CARMEN	4113	0	24
12598	EL CORTADERAL	4111	0	24
12599	EL DURAZNO	4113	0	24
12600	EL GUARDAMONTE	4113	0	24
12601	EL MELON	4178	0	24
12602	EL MOJON	4178	0	24
12603	EL MOLLAR	4115	0	24
12604	EL NARANJO	4113	0	24
12605	EL PAVON	4115	0	24
12606	EL QUIMIL	4178	0	24
12607	EL ROSARIO	4113	0	24
12608	EL SUNCHO	4115	0	24
12609	ENTRE RIOS	4113	0	24
12610	ESQUINA DEL LLANO	4111	0	24
12611	ESTACION ARAOZ	4178	0	24
12612	GOMEZ CHICO	4113	0	24
12613	INGENIO BELLA VISTA	4168	0	24
12614	INGENIO LEALES	4111	0	24
12615	JUAN POSSE	4111	0	24
12616	JUSCO POZO	4115	0	24
12617	KILOMETRO 1220	4166	0	24
12618	KILOMETRO 1235	4166	0	24
12619	KILOMETRO 1248	4166	0	24
12620	KILOMETRO 1256	4166	0	24
12621	KILOMETRO 794	4111	0	24
12622	LA EMPATADA	4111	0	24
12623	LA FLORIDA	4115	0	24
12624	LA FRONTERITA	4111	0	24
12625	LA TUNA	4149	0	24
12626	LAGUNA BLANCA	4115	0	24
12627	LAS ACOSTILLAS	4113	0	24
12628	LAS CA	4113	0	24
12629	LAS CELAYAS	4115	0	24
12630	LAS COLONIAS	4115	0	24
12631	LAS ENCRUCIJADAS	4115	0	24
12632	LAS MERCEDES	4111	0	24
12633	LAS PALMITAS	4115	0	24
12634	LAS ZORRAS	4115	0	24
12635	LOMA VERDE	4111	0	24
12636	LOS BRITOS	4113	0	24
12637	LOS CAMPEROS	4111	0	24
12638	LOS CHA	4115	0	24
12639	LOS CRESPO	4113	0	24
12640	LOS DIAZ	4159	0	24
12641	LOS GOMEZ	4113	0	24
12642	LOS HERRERAS	4113	0	24
12643	LOS JUAREZ	4113	0	24
12644	LOS PUESTOS	4115	0	24
12645	LOS QUEMADOS	4113	0	24
12646	LOS ROMANOS	4113	0	24
12647	LOS SUELDOS	4111	0	24
12648	LOS VILLEGAS	4115	0	24
12649	LOS ZELAYAS	4115	0	24
12650	LUNAREJOS	4113	0	24
12651	MANCHALA	4166	0	24
12652	MANCOPA	4115	0	24
12653	MANUEL GARCIA FERNANDEZ	4166	0	24
12654	MARIA ELENA	4168	0	24
12655	MIGUEL LILLO	4113	0	24
12656	MIXTA	4115	0	24
12657	MONTE BELLO	4115	0	24
12658	MOYAR	4115	0	24
12659	MUJER MUERTA	4178	0	24
12660	NOARIO	4113	0	24
12661	NUEVA ESPA	4113	0	24
12662	ORAN	4115	0	24
12663	PALA PALA	4111	0	24
12664	PALMITAS	4115	0	24
12665	PIRHUAS	4115	0	24
12666	POSSE DESVIO PARTICULAR FCGM	4115	0	24
12667	POZO DEL ALTO	4111	0	24
12668	PUENTE EL MANANTIAL	4166	0	24
12669	PUESTO CHICO	4111	0	24
12670	PUMA POZO	4115	0	24
12671	PUNTA RIELES	4115	0	24
12672	QUILMES	4111	0	24
12673	RIO COLORADO	4166	0	24
12674	ROMA	4111	0	24
12675	ROMERA POZO	4115	0	24
12676	ROSARIO OESTE	4111	0	24
12677	SAN ANTONIO	4115	0	24
12678	SAN JOSE DE LEALES	4113	0	24
12679	SAN NICOLAS	4111	0	24
12680	SAN RAMON	4166	0	24
12681	SANDIS	4115	0	24
12682	SANTA FELISA	4111	0	24
12683	SANTA ROSA DE LEALES	4111	0	24
12684	SOL DE MAYO	4176	0	24
12685	SOLEDAD	4115	0	24
12686	SUELDOS	4111	0	24
12687	SUPERINTENDENTE LEDESMA	4178	0	24
12688	TACANAS	4178	0	24
12689	TRES POZOS	4178	0	24
12690	TUSCA POZO	4113	0	24
12691	TUSQUITAS	4113	0	24
12692	VIELOS	4115	0	24
12693	VILCA POZO	4115	0	24
12694	VILLA FIAD	4111	0	24
12695	VILLA DE LEALES	4113	0	24
12696	YALAPA	4147	0	24
12697	YATAPAYANA	4113	0	24
12698	EL CEIBAL	4128	0	24
12699	EL MANANTIAL	4105	0	24
12700	EL NOGALITO	4105	0	24
12701	LA BOLSA	4128	0	24
12702	LA REDUCCION	4129	0	24
12703	LAS TIPAS	4105	0	24
12704	LOS AGUIRRE	4105	0	24
12705	LOS ALCARACES	4105	0	24
12706	LOS CHA	4111	0	24
12707	LULES	4128	0	24
12708	POTRERO DE LAS TABLAS	4128	0	24
12709	PUERTA GRANDE	4164	0	24
12710	SAN FELIPE	4105	0	24
12711	SAN JOSE	4163	0	24
12712	SAN PABLO	4129	0	24
12713	SAN RAFAEL	4129	0	24
12714	SANTA BARBARA	4105	0	24
12715	VILLA NOGUES	4105	0	24
12716	ACHERAL	4134	0	24
12717	AMBERES	4144	0	24
12718	ARAGONES	4142	0	24
12719	ARAN	4142	0	24
12720	ARENILLA	4134	0	24
12721	CAPITAN CACERES	4142	0	24
12722	CASA DE PIEDRA	4142	0	24
12723	CASPINCHANGO	4135	0	24
12724	CHILCAR	4142	0	24
12725	COLONIA SANTA CATALINA	4142	0	24
12726	COSTILLA	4142	0	24
12727	DURAZNOS BLANCOS	4135	0	24
12728	EL CERCADO	4142	0	24
12729	EL CHURQUIS	4142	0	24
12730	EL NOGALAR	4135	0	24
12731	HUASA PAMPA	4142	0	24
12732	INDEPENDENCIA	4143	0	24
12733	INGENIO 	4142	0	24
12734	INGENIO LA PROVIDENCIA	4145	0	24
12735	INGENIO SANTA ROSA	4143	0	24
12736	ISLA SAN JOSE	4142	0	24
12737	LA FLORIDA	4144	0	24
12738	LA MARAVILLA	4124	0	24
12739	LA RAMADITA	4135	0	24
12740	LAS CIENAGAS	4135	0	24
12741	LAS HIGUERITAS	4144	0	24
12742	LAS MESADAS	4132	0	24
12743	LEON ROUGES	4143	0	24
12744	LOS MOYES	4143	0	24
12745	LOS REYES	4143	0	24
12746	LOS ROBLES	4142	0	24
12747	LOS RODRIGUEZ	4135	0	24
12748	LOS ROJOS	4143	0	24
12749	LOS SOSAS	4142	0	24
12750	MACIO	4172	0	24
12751	MONTEROS	4142	0	24
12752	NEGRO POTRERO	4135	0	24
12753	ORAN	4142	0	24
12754	PILCO	4142	0	24
12755	PUEBLO VIEJO	4164	0	24
12756	RINCON DE BALDERRAMA	4166	0	24
12757	RIO SECO	4145	0	24
12758	SAN GABRIEL	4134	0	24
12759	SAN JOSE DE FLORES	4134	0	24
12760	SANTA CATALINA	4142	0	24
12761	SANTA ELENA	4135	0	24
12762	SANTA LUCIA	4135	0	24
12763	SANTA MONICA	4135	0	24
12764	SANTA ROSA	4143	0	24
12765	SARGENTO MOYA	4144	0	24
12766	SOLDADO MALDONADO	4142	0	24
12767	TENIENTE BERDINA	4132	0	24
12768	VILLA NUEVA AGUILARES	4142	0	24
12769	VILLA QUINTEROS	4144	0	24
12770	YACUCHINA	4142	0	24
12771	YONOPONGO	4142	0	24
12772	AGUILARES	4152	0	24
12773	ARROYO BARRIENTO	4152	0	24
12774	ARROYO MAL PASO	4157	0	24
12775	CEVIL GRANDE	4155	0	24
12776	CEVIL SOLO	4157	0	24
12777	CHAVARRIA	4155	0	24
12778	COLONIA MARULL	4152	0	24
12779	COLONIA NASCHI	4152	0	24
12780	DOLAVON	4161	0	24
12781	EL CARMEN	4157	0	24
12782	EL POLEAR	4161	0	24
12783	EL RODEO	4155	0	24
12784	EL TUSCAL	4157	0	24
12785	FALDA DE ARCADIA	4157	0	24
12786	HUASA RINCON	4152	0	24
12787	INGENIO MARAPA	4158	0	24
12788	INGENIO SANTA BARBARA	4157	0	24
12789	JUAN BAUTISTA ALBERDI	4158	0	24
12790	KILOMETRO 55	4155	0	24
12791	LA TAPIA	4157	0	24
12792	LA TIPA	4157	0	24
12793	LAS ANIMAS	4176	0	24
12794	LOS ALISOS	4158	0	24
12795	LOS CALLEJONES	4152	0	24
12796	LOS CORDOBA	4157	0	24
12797	LOS GALPONES	4157	0	24
12798	LOS LUNAS	4155	0	24
12799	LOS RIOS	4157	0	24
12800	LOS RIZOS	4157	0	24
12801	LOS SARMIENTOS	4157	0	24
12802	MAL PASO	4157	0	24
12803	MARIA BLANCA	4157	0	24
12804	MERCEDES	4152	0	24
12805	MONTE BELLO	4157	0	24
12806	MONTE REDONDO	4152	0	24
12807	MULTIFLORES	4152	0	24
12808	NASCHE	4152	0	24
12809	NUEVA ESQUINA	4161	0	24
12810	RINCON HUASA	4152	0	24
12811	RIO CHICO	4153	0	24
12812	SAN MIGUEL	4152	0	24
12813	SANTA ANA	4155	0	24
12814	SANTA ROSA	4152	0	24
12815	TUSCAL	4155	0	24
12816	VILLA ALBERDI	4158	0	24
12817	VILLA CLODOMIRO HILERET	4155	0	24
12818	YAMINAS	4158	0	24
12819	ATAHONA	4174	0	24
12820	ALTO LAS FLORES	4152	0	24
12821	AMPATA	4174	0	24
12822	AMPATILLA	4174	0	24
12823	ARROYO ATAHONA	4174	0	24
12824	BALDERRAMA	4166	0	24
12825	BUENA VISTA	4172	0	24
12826	CAMPO VOLANTE	4172	0	24
12827	CEJAS DE AROCA	4174	0	24
12828	CHIGLIGASTA	4174	0	24
12829	CIUDACITA	4174	0	24
12830	EL CHILCAR	4172	0	24
12831	EL JARDIN	4172	0	24
12832	EL POLEAR	4172	0	24
12833	EL TOBAR	4174	0	24
12834	GUEMES	4172	0	24
12835	ICHIPUCA	4174	0	24
12836	KILOMETRO 1194	4174	0	24
12837	KILOMETRO 1207	4174	0	24
12838	LA RINCONADA	4172	0	24
12839	LAS CEJAS	4172	0	24
12840	LAZARTE	4174	0	24
12841	LOS ARRIETAS	4151	0	24
12842	LOS MENDOZAS	4174	0	24
12843	LOS PEREZ	4174	0	24
12844	LOS TREJOS	4174	0	24
12845	MACIO	4172	0	24
12846	MANUELA PEDRAZA	4166	0	24
12847	MONTEAGUDO	4174	0	24
12848	NIOGASTA	4174	0	24
12849	NUEVA TRINIDAD	4157	0	24
12850	PALOMINOS	4174	0	24
12851	SAN ANTONIO DE PADUA	4174	0	24
12852	SANDOVALES	4174	0	24
12853	SANTA ISABEL	4152	0	24
12854	SIMOCA	4172	0	24
12855	SUD DE LAZARTE	4174	0	24
12856	SUD DE TREJOS	4174	0	24
12857	VALENZUELA	4149	0	24
12858	VILLA STA ROSA DE NVA TRINIDAD	4187	0	24
12859	YERBA BUENA	4172	0	24
12860	ACONQUIJA	4107	0	24
12861	ALISOS	4137	0	24
12862	AMAICHA DEL VALLE	4137	0	24
12863	ANCHILLOS	4141	0	24
12864	ANJUANA	4141	0	24
12865	ANTAMA	4107	0	24
12866	BARRIO CASINO	4107	0	24
12867	CALIMONTE	4141	0	24
12868	CA	4129	0	24
12869	CASAS VIEJAS	4137	0	24
12870	CHORRILLOS	4101	0	24
12871	CHURQUI	4119	0	24
12872	COLALAO DEL VALLE	4141	0	24
12873	CUATRO GATOS	4107	0	24
12874	EL ARBOLAR	4141	0	24
12875	EL BA	4141	0	24
12876	EL CARRIZAL	4141	0	24
12877	EL CATORCE	4105	0	24
12878	EL CUARTEADERO	4103	0	24
12879	EL MOLINO	4158	0	24
12880	EL MOLLAR	4135	0	24
12881	EL PASO	4141	0	24
12882	EL ZANJON	4103	0	24
12883	ESQUINA	4111	0	24
12884	FRONTERITAS	4111	0	24
12885	HIGUERITAS	4107	0	24
12886	HOYADA	4105	0	24
12887	HUASAMAYO	4122	0	24
12888	JULIPAO	4141	0	24
12889	JUNTA	4122	0	24
12890	LA AGUADITA	4101	0	24
12891	LA ANGOSTURA	4137	0	24
12892	LA CA	4107	0	24
12893	LA CIENAGA	4137	0	24
12894	LA CRUZ	4119	0	24
12895	LA QUEBRADA	4129	0	24
12896	LARA	4137	0	24
12897	LAS ARCAS	4124	0	24
12898	LAS CA	4141	0	24
12899	LAS CARRERAS	4137	0	24
12900	LAS MORITAS	4103	0	24
12901	LAS SALINAS	4101	0	24
12902	LAS TIPAS DE COLALAO	4124	0	24
12903	LAS ZANJAS	4119	0	24
12904	LOMA COLORADA	4141	0	24
12905	LOS CHA	4141	0	24
12906	LOS COLORADOS	4137	0	24
12907	LOS CORDONES	4137	0	24
12908	LOS CORPITOS	4137	0	24
12909	LOS CUARTOS	4137	0	24
12910	LOS ZAZOS	4137	0	24
12911	MANAGUA	4141	0	24
12912	OJO DE AGUA	4107	0	24
12913	OVEJERIA	4124	0	24
12914	PARAISO	4117	0	24
12915	PICHAO	4141	0	24
12916	PIE DE LA CUESTA	4124	0	24
12917	PIE DEL ACONQUIJA	4107	0	24
12918	PUERTA SAN JAVIER	4107	0	24
12919	QUILMES	4141	0	24
12920	QUISCA CHICA	4141	0	24
12921	RINCON	4103	0	24
12922	RODEO GRANDE	4174	0	24
12923	SALADILLO	4146	0	24
12924	SALAS	4137	0	24
12925	SAN JOSE DE CHASQUIVIL	4137	0	24
12926	SINQUEAL	4119	0	24
12927	TAFI DEL VALLE	4137	0	24
12928	TALA PASO	4141	0	24
12929	TALLERES NACIONALES	4103	0	24
12930	TIO FRANCO	4141	0	24
12931	TIO PUNCO	4137	0	24
12932	TOTORITAS	4141	0	24
12933	YASYAMAYO	4141	0	24
12934	ZURITA	4137	0	24
12935	AGUADITA	4101	0	24
12936	ALTO DE ANFAMA	4107	0	24
12937	ANCA JULI	4105	0	24
12938	ANFANA	4105	0	24
12939	BARRIO DIAGONAL	4101	0	24
12940	BARRIO RIVADAVIA	4101	0	24
12941	CHASQUIVIL	4105	0	24
12942	COMUNA LA ESPERANZA	4103	0	24
12943	EL COLMENAR	4101	0	24
12944	EL DURAZNITO	4103	0	24
12945	EL SIAMBON	4105	0	24
12946	EL TIRO ARGENTINO	4103	0	24
12947	EMBALSE EL CADILLAL	4101	0	24
12949	GRANJA MODELO	4101	0	24
12950	LA ESPERANZA	4176	0	24
12951	LA PICADA	4103	0	24
12952	LA TOMA	4103	0	24
12953	LAS TALITAS	4101	0	24
12955	LAS TIPAS	4105	0	24
12956	LOS ESTANQUES	4103	0	24
12957	LOS NOGALES	4101	0	24
12958	LOS POCITOS	4101	0	24
12959	NUEVA ESPERANZA	4103	0	24
12960	PUEBLO OBRERO	4103	0	24
12961	QUILMES	4141	0	24
12962	RACO	4105	0	24
12963	RIO LORO	4101	0	24
12964	SAN JAVIER	4105	0	24
12965	TAFI VIEJO	4103	0	24
12966	TAFICILLO	4103	0	24
12967	VILLA MITRE	4103	0	24
12968	ACEQUIONES	4124	0	24
12969	AGUA ROSADA	4124	0	24
12970	AGUA SALADA	4124	0	24
12971	BARBORIN	4124	0	24
12972	BENJAMIN PAZ	4122	0	24
12973	CASA DEL ALTO	4122	0	24
12974	CHOROMORO	4122	0	24
12975	CHULCA	4124	0	24
12976	CHUSCHA	4122	0	24
12977	CORRAL VIEJO	4124	0	24
12978	DESMONTE	4122	0	24
12979	EL CEDRO	4122	0	24
12980	EL MISTOL	4124	0	24
12981	EL OJO	4122	0	24
12982	EL QUEBRACHAL	4124	0	24
12983	GONZALO	4122	0	24
12985	LA AGUADITA	4101	0	24
12986	LA BANDA	4119	0	24
12987	LA CA	4124	0	24
12988	LA CUESTA	4126	0	24
12989	LA DORITA	4124	0	24
12990	LA HIGUERA	4122	0	24
12991	LA TOMA	4119	0	24
12992	LA ZANJA	4242	0	24
12993	LAS ARCAS	4124	0	24
12994	LAS CRIOLLAS	4122	0	24
12995	LAS MESADAS	4132	0	24
12996	LAS TACANAS	4124	0	24
12997	LAUREL YACO	4124	0	24
12998	LEOCADIO PAZ	4124	0	24
12999	LOMA DEL MEDIO	4122	0	24
13000	LOS PLANCHONES	4105	0	24
13001	LOS SAUCES	4176	0	24
13002	MANANTIALES	4124	0	24
13003	MATO YACO	4122	0	24
13004	MIRANDA	4124	0	24
13005	MONTE BELLO	4124	0	24
13006		4122	0	24
13007	PERUCHO	4124	0	24
13008	PIE DE LA CUESTA	4124	0	24
13009	PINGOLLAR	4124	0	24
13010	PUERTAS	4122	0	24
13011	PUESTO GRANDE	4122	0	24
13012	RIARTE	4126	0	24
13013	RIO VIPOS	4122	0	24
13014	RODEO DEL ALGARROBO	4122	0	24
13015	RODEO GRANDE	4122	0	24
13016	SALAMANCA	4122	0	24
13017	SALINAS	4122	0	24
13018	SAN FERNANDO	4124	0	24
13019	SAN ISIDRO	4124	0	24
13020	SAN JOSE	4124	0	24
13021	SAN JULIAN YACO	4122	0	24
13022	SAN MIGUEL	4122	0	24
13023	SAN PEDRO DE COLALAO	4124	0	24
13024	SAN VICENTE	4122	0	24
13025	SAUCE YACU	4122	0	24
13026	SAUZAL	4124	0	24
13027	SEPULTURA	4122	0	24
13028	SIMBOLAR	4122	0	24
13029	TACO YANA	4124	0	24
13030	TALA YACO	4122	0	24
13031	TAPIA	4122	0	24
13032	TICUCHO	4122	0	24
13033	TOCO LLANA	4124	0	24
13034	TORO LOCO	4124	0	24
13035	TOTORAL	4119	0	24
13036	TUNA SOLA	4122	0	24
13037	UTURUNGU	4113	0	24
13038	VIADUCTO DEL TORO	4122	0	24
13039	VILLA TRANCAS	4124	0	24
13040	VIPOS	4122	0	24
13041	ZARATE	4124	0	24
13042	CAMINO DEL PERU	4105	0	24
13043	CEVIL REDONDO	4105	0	24
13044	CURVA DE LOS VEGAS	4105	0	24
13045	KILOMETRO 808	4105	0	24
13046	LA BANDA	4105	0	24
13047	LA CAVERA	4105	0	24
13048	LAS TALAS	4105	0	24
13049	LOS BULACIO	4105	0	24
13050	PARADA DE OHUANTA	4105	0	24
13051	POTRERILLO	4101	0	24
13052	SAN ALBERTO	4105	0	24
13053	VILLA CARMELA	4105	0	24
13054	VILLA MARCOS PAZ	4107	0	24
13055	ABDON CASTRO TOLAY	4641	0	10
13056	ABRA PAMPA	4640	0	10
13057	ABRALAITE	4634	0	10
13058	AGUA CALIENTE DE LA PUNA	4641	0	10
13059	AGUA CHICA	4640	0	10
13060	AGUAS CALIENTES	4431	0	10
13061	ARBOLITO NUEVO	4643	0	10
13062	BARRANCAS	4641	0	10
13063	CASA COLORADA	4643	0	10
13064	CASABINDO	4641	0	10
13065	CATARI	4640	0	10
13066	CHAUPI RODERO	4640	0	10
13067	CHOROJRA	4640	0	10
13068	COCHINOCA	4641	0	10
13069	COLORADOS	4618	0	10
13070	DONCELLAS	4641	0	10
13071	ESTACION ZOOTECNICA	4640	0	10
13072	LLULLUCHAYOC	4644	0	10
13073	LOTE MIRAFLORES	4503	0	10
13074	MIRAFLORES DE LA CANDELARIA	4640	0	10
13075	POTRERO	4640	0	10
13076	POTRERO DE LA PUNA	4640	0	10
13077	PUESTO DEL MARQUEZ	4644	0	10
13079	QUERA	4634	0	10
13080	QUETA	4641	0	10
13081	QUICHAGUA	4641	0	10
13082	RACHAITE	4641	0	10
13083	RINCONADILLAS	4641	0	10
13084	RONTUYOC	4640	0	10
13085	RUMI CRUZ	4640	0	10
13086	SAN FRANCISCO DE ALFARCITO	4641	0	10
13087	SAN JUAN DE QUILLAGUES	4641	0	10
13088	SANTA ANA DE LA PUNA	4641	0	10
13089	SANTUARIO	4640	0	10
13090	SAYATE	4640	0	10
13091	TABLADITAS	4640	0	10
13092	TAMBILLOS	4641	0	10
13093	TUSAQUILLAS	4641	0	10
13094	ALTO COMEDERO	4600	0	10
13095	GUERRERO	4600	0	10
13096	HUAICO CHICO	4601	0	10
13097	LOZANO	4616	0	10
13098	REYES	4600	0	10
13099	SAN SALVADOR DE JUJUY	4600	0	10
13100	TERMAS DE REYES	4600	0	10
13101	TILQUIZA	4600	0	10
13102	BARRIO ALBERDI	4600	0	10
13103	VILLA localidades DE NIEVA	4600	0	10
13104	BARRIO CUYAYA	4600	0	10
13105	VILLA GORRITI	4600	0	10
13106	BARRIO LUJAN	4600	0	10
13107	BARRIO SANTA RITA	4600	0	10
13108	YALA	4616	0	10
13109	ALTO VERDE	4608	0	10
13110	BARRIO LA UNION	4648	0	10
13111	BORDO LA ISLA	4608	0	10
13112	CAMPO LA TUNA	4608	0	10
13113	CATAMONTA	4603	0	10
13114	CHAMICAL	4608	0	10
13115	CORONEL ARIAS	4608	0	10
13116	EL CADILLAL	4608	0	10
13117	EL CARMEN	4603	0	10
13118	CHUCUPAL	4603	0	10
13119	EL OLLERO	4603	0	10
13120	EL PONGO	4608	0	10
13121	EL SUNCHAL	4603	0	10
13122	EL TOBA	4606	0	10
13123	ESTACION PERICO	4608	0	10
13124	KILOMETRO 1129	4608	0	10
13125	LA CIENAGA	4603	0	10
13126	LA OVEJERIA	4606	0	10
13127	LAS CA	4606	0	10
13128	LAS PAMPITAS	4608	0	10
13129	LAS PICHANAS	4606	0	10
13130	LAS PIRCAS	4603	0	10
13131	LAVAYEN	4503	0	10
13132	LOS CEDROS	4603	0	10
13133	LOS LAPACHOS	4606	0	10
13134	LOS MANANTIALES	4606	0	10
13135	LOTE SAN JUANCITO	4522	0	10
13136	MAQUINISTA VERON	4606	0	10
13137	MONTERRICO	4608	0	10
13138	PALO BLANCO	4522	0	10
13139	PAMPA BLANCA	4606	0	10
13140	PAMPA VIEJA	4606	0	10
13141	PERICO	4608	0	10
13142	PUEBLO VIEJO	4632	0	10
13143	SAN VICENTE	4608	0	10
13144	SANTO DOMINGO	4608	0	10
13145	APARZO	4630	0	10
13146	AZUL PAMPA	4631	0	10
13147	BALIAZO	4630	0	10
13148	CARAYOC	4651	0	10
13149	CHAUPI RODERO	4632	0	10
13150	CHORCAN	4631	0	10
13151	CHUCALEZNA	4626	0	10
13152	CIANZO	4630	0	10
13153	COCTACA	4631	0	10
13154	CORAYA	4630	0	10
13155	DOGLONZO	4631	0	10
13156	EL AGUILAR	4634	0	10
13157	EL CONDOR	4644	0	10
13158	HIPOLITO YRIGOYEN EST ITURBE	4632	0	10
13159	HORNADITAS	4630	0	10
13160	HUMAHUACA	4630	0	10
13162	LA VETA	4634	0	10
13163	MIYUYOC	4632	0	10
13164	OCUMAZO	4626	0	10
13165	OVARA	4630	0	10
13166	PALCA DE APARZO	4631	0	10
13167	PE	4632	0	10
13168	PUCARA	4624	0	10
13169	RODERO	4631	0	10
13170	RONQUE	4631	0	10
13171	SAN ROQUE	4630	0	10
13172	SENADOR PEREZ	4626	0	10
13173	TEJADAS	4634	0	10
13174	TRES CRUCES	4634	0	10
13175	UQUIA	4626	0	10
13176	VARAS	4631	0	10
13177	VETA MINA AGUILAR	4634	0	10
13178	ALTO CALILEGUA	4513	0	10
13179	ARENAL BARROSO	4506	0	10
13180	CAIMANCITO	4516	0	10
13181	CALILEGUA	4514	0	10
13182	CASILLAS	4632	0	10
13183	CHALICAN	4504	0	10
13185	FRAILE PINTADO	4506	0	10
13186	GUAYACAN	4506	0	10
13187	INGENIO LEDESMA	4512	0	10
13188	LA BAJADA	4506	0	10
13191	NORMENTA	4512	0	10
13192	PUEBLO LEDESMA	4512	0	10
13193	23 DE AGOSTO	4504	0	10
13194	YUTO	4518	0	10
13197	CARAHUNCO	4612	0	10
13198	CENTRO FORESTAL	4612	0	10
13199	CERROS ZAPLA	4612	0	10
13200	EL ALGARROBAL	4612	0	10
13201	EL BRETE	4612	0	10
13202	EL CUCHO	4612	0	10
13203	EL REMATE	4612	0	10
13204	GENERAL MANUEL SAVIO	4612	0	10
13205	LA CUESTA	4612	0	10
13206	LAS CAPILLAS	4612	0	10
13207	LAS ESCALERAS	4612	0	10
13208	LOS BLANCOS	4612	0	10
13209	MINA 9 DE OCTUBRE	4612	0	10
13210	PALPALA	4612	0	10
13212	CARAHUASI	4643	0	10
13213	CIENEGO GRANDE	4643	0	10
13214	COYAGUAIMA	4643	0	10
13215	CUSI CUSI	4643	0	10
13216	GUAYATAYOC	4643	0	10
13217	HUALLATAYOC	4653	0	10
13218	LOMA BLANCA	4643	0	10
13219	MINA PIRQUITAS	4643	0	10
13221	OROSMAYO	4643	0	10
13222	PAICONE	4643	0	10
13223	MINA PAN DE AZUCAR	4643	0	10
13224	POZUELO	4643	0	10
13225	RINCONADA	4643	0	10
13226	SAN JUAN	4643	0	10
13227	SAN PEDRO	4500	0	10
13228	ALISOS  DE ABAJO	4605	0	10
13229	CEIBAL	4605	0	10
13230	CERRO NEGRO	4605	0	10
13231	LA CABA	4605	0	10
13232	LA TOMA	4605	0	10
13233	LOS ALISOS	4605	0	10
13234	PA	4605	0	10
13235	SAN ANTONIO	4605	0	10
13236	ARRAYANAL	4503	0	10
13237	ARROYO COLORADO	4501	0	10
13238	BARRO NEGRO	4522	0	10
13239	EL QUEMADO	4504	0	10
13240	LA ESPERANZA	4503	0	10
13241	LA MENDIETA	4522	0	10
13242	LOTE DON DAVID	4522	0	10
13243	LOTE DON EMILIO	4522	0	10
13244	LOTE EL PUESTO	4503	0	10
13245	LOTE PALMERA	4503	0	10
13246	LOTE PARAPETI	4503	0	10
13247	LOTE PIEDRITAS	4522	0	10
13248	LOTE SAN ANTONIO	4512	0	10
13249	RODEITO	4500	0	10
13250	SAN JOSE DEL BORDO	4500	0	10
13251	SAN JUAN DE DIOS	4501	0	10
13252	SAN LUCAS	4500	0	10
13253	EL ARENAL	4500	0	10
13254	EL FUERTE	4501	0	10
13255	EL PALMAR	4501	0	10
13256	EL PALMAR DE SAN FRANCISCO	4542	0	10
13257	EL PIQUETE	4501	0	10
13258	EL TALAR	4542	0	10
13259	INGENIO LA ESPERANZA	4542	0	10
13260	ISLA CHICA	4501	0	10
13261	ISLA GRANDE	4501	0	10
13262	LEACHS	4504	0	10
13263	LOTE SAUZAL	4522	0	10
13264	PALMA SOLA	4501	0	10
13265	PUESTO NUEVO	4501	0	10
13266	PUESTO VIEJO	4606	0	10
13267	REAL DE LOS TOROS	4501	0	10
13268	RIO NEGRO	4504	0	10
13269	SAN RAFAEL	4501	0	10
13270	SANTA CLARA	4501	0	10
13271	SIETE AGUAS	4501	0	10
13272	VINALITO	4518	0	10
13273	CABRERIA	4655	0	10
13274	CASIRA	4653	0	10
13275	CERRITO	4653	0	10
13276	CIENEGUILLAS	4653	0	10
13277	HORNILLOS	4653	0	10
13278	LA CRUZ	4655	0	10
13279	ORATORIO	4655	0	10
13280	OROS SAN JUAN	4655	0	10
13281	PASAJES	4653	0	10
13282	PASTO PAMPA	4653	0	10
13283	PUESTO CHICO	4653	0	10
13284	PUESTO GRANDE	4653	0	10
13285	RODEO CHICO	4653	0	10
13286	SAN FRANCISCO	4655	0	10
13287	SAN LEON	4655	0	10
13288	SANTA CATALINA	4655	0	10
13289	TIMON CRUZ	4655	0	10
13290	TOQUERO	4653	0	10
13291	YOSCABA	4653	0	10
13292	CATUA	4413	0	10
13293	VILLA CORANZULI	4643	0	10
13294	EL TORO	4643	0	10
13295	HUANCAR	4641	0	10
13296	MU	4641	0	10
13297	OLAROZ CHICO	4641	0	10
13298	SEY	4411	0	10
13299	SUSQUES	4641	0	10
13300	ABRA MAYO	4624	0	10
13301	ALFARCITO	4624	0	10
13302	CHORRILLOS	4626	0	10
13303	EL DURAZNO	4624	0	10
13304	POSTA DE HORNILLOS	4618	0	10
13305	HUACALERA	4626	0	10
13306	HUICHAIRA	4624	0	10
13307	JUELLA	4624	0	10
13308	EL PERCHEL	4624	0	10
13309	LA BANDA	4624	0	10
13310	MAIMARA	4622	0	10
13311	QUEBRADA HUASAMAYO	4624	0	10
13312	SAN JOSE	4626	0	10
13313	SAN PEDRITO	4622	0	10
13314	TILCARA	4624	0	10
13315	VILLA DEL PERCHEL	4626	0	10
13316	BARCENA	4616	0	10
13317	BOMBA	4616	0	10
13318	CHILCAYOC	4616	0	10
13319	EL ANGOSTO	4655	0	10
13320	EL MORENO	4618	0	10
13321	EL SALADILLO	4500	0	10
13322	HUACHICHOCANA	4618	0	10
13323	KILOMETRO 1183	4616	0	10
13324	LA AGUADITA	4618	0	10
13325	LA CIENAGA	4618	0	10
13326	LAGUNAS DE YALA	4616	0	10
13327	LEON	4616	0	10
13328	MOLINOS	4616	0	10
13329	PISCUNO	4655	0	10
13330	PUERTA DE LIPAN	4618	0	10
13331	PUNA DE JUJUY	4618	0	10
13332	PUNTA CORRAL	4618	0	10
13333	PURMAMARCA	4618	0	10
13334	SAN BERNARDO	4618	0	10
13335	SAN JOSE DEL CHA	4618	0	10
13336	TESORERO	4616	0	10
13337	TIRAXI	4616	0	10
13338	TRES MORROS	4618	0	10
13339	TUMBAYA	4618	0	10
13340	TUNALITO	4618	0	10
13341	VOLCAN	4616	0	10
13342	CASPALA	4631	0	10
13343	MOLULO	4624	0	10
13344	OCLOYAS	4601	0	10
13345	PAMPICHUELA	4513	0	10
13346	SAN FRANCISCO	4512	0	10
13347	SAN LUCAS	4513	0	10
13348	SANTA ANA	4631	0	10
13349	SANTA BARBARA	4513	0	10
13350	VALLE COLORADO	4631	0	10
13351	VALLE GRANDE	4513	0	10
13352	YALA DE MONTE CARMELO	4624	0	10
13353	BARRIOS	4650	0	10
13354	CANGREJILLOS	4644	0	10
13355	CANGREJOS	4644	0	10
13356	CARACARA	4644	0	10
13357	CASTI	4651	0	10
13358	CHOCOITE	4644	0	10
13359	ESCAYA	4644	0	10
13360	INTICANCHO	4651	0	10
13361	LA CIENAGA	4650	0	10
13362	LA CUEVA	4632	0	10
13363	LA QUIACA	4650	0	10
13364	MAYINTE	4644	0	10
13365	MINA BELGICA	4644	0	10
13366	MINA PULPERA	4644	0	10
13367	MINA SAN FRANCISCO	4644	0	10
13368	PUMAHUASI	4644	0	10
13369	REDONDA	4644	0	10
13370	RIO COLORADO	4644	0	10
13371	SANSANA	4650	0	10
13372	SURIPUJIO	4651	0	10
13373	TAFNA	4650	0	10
13374	VISCACHANI	4651	0	10
13375	YAVI	4651	0	10
13376	YAVI CHICO	4644	0	10
13831	AIMOGASTA	5310	0	12
13832	ARAUCO	5311	0	12
13833	BA	5310	0	12
13834	ESTACION MAZAN	5313	0	12
13836	LOS BALDES	5310	0	12
13837	MACHIGASTA	5311	0	12
13838	SAN ANTONIO	5310	0	12
13839	TERMAS DE SANTA TERESITA	5313	0	12
13840	TINOCAN	5313	0	12
13841	UDPINANGO	5311	0	12
13842	VILLA MAZAN	5313	0	12
13843	CAMPANAS	5361	0	12
13844	AMILGANCHO	5300	0	12
13845	ANCHICO	5301	0	12
13846	BAJO HONDO	5300	0	12
13847	BAZAN	5300	0	12
13848	CAMPO TRES POZOS	5301	0	12
13849	CEBOLLAR	5300	0	12
13850	EL BAYITO	5301	0	12
13851	EL DURAZNILLO	5300	0	12
13852	EL ESCONDIDO	5301	0	12
13853	EL ROSARIO	5263	0	12
13854	EL TALA	5304	0	12
13855	EL VALLE	5301	0	12
13856	ESPERANZA DE LOS CERRILLOS	5263	0	12
13857	LA ANTIGUA	5301	0	12
13858	LA BUENA ESTRELLA	5301	0	12
13859	LA BUENA SUERTE	5300	0	12
13860	LA ESPERANZA	5300	0	12
13861	LA LIBERTAD	5263	0	12
13862	LA RAMADITA	5300	0	12
13863	LA RIOJA	5300	0	12
13864	LA ROSILLA	5301	0	12
13865	LAS CATAS	5301	0	12
13866	LAS SIERRAS BRAVAS	5301	0	12
13867	LOS CERRILLOS	5301	0	12
13868	MEDANO	5300	0	12
13869	MESILLAS BLANCAS	5301	0	12
13870	POZO BLANCO	5301	0	12
13871	POZO DE AVILA	5300	0	12
13872	POZO DE LA YEGUA	5301	0	12
13873	PUERTA DE LA QUEBRADA	5300	0	12
13874	PUERTO ALEGRE	5300	0	12
13875	PUERTO DEL VALLE	5301	0	12
13876	PUNTA DEL NEGRO	5300	0	12
13877	SAN ANTONIO	5301	0	12
13878	SAN BERNARDO	5301	0	12
13879	SAN IGNACIO	5301	0	12
13880	SAN JOSE	5301	0	12
13881	SAN LORENZO	5301	0	12
13882	SAN MARTIN	5300	0	12
13883	SAN MIGUEL	5301	0	12
13884	SAN NICOLAS	5301	0	12
13886	SAN RAFAEL	5301	0	12
13887	SANTA ANA	5301	0	12
13888	SANTA TERESA	5301	0	12
13889	TALAMUYUNA	5304	0	12
13890	TRAMPA DEL TIGRE	5300	0	12
13891	AGUA BLANCA	5301	0	12
13892	AGUADA	5301	0	12
13893	AMINGA	5301	0	12
13894	ANILLACO	5301	0	12
13895	ANJULLON	5303	0	12
13896	CHUQUIS	5301	0	12
13897	ISMIANGO	5301	0	12
13898	LOS MOLINOS	5301	0	12
13899	PINCHAS	5301	0	12
13900	SANTA VERA CRUZ	5301	0	12
13901	CHULO	5380	0	12
13902	EL RETAMO	5380	0	12
13903	LA SERENA	5380	0	12
13904	LOS BORDOS	5380	0	12
13905	POLCO	5380	0	12
13906	QUEBRACHAL	5381	0	12
13907	SANTA BARBARA	5381	0	12
13909	ANGUINAN	5363	0	12
13910	CACHIYUYAL	5367	0	12
13911	CATINZACO	5374	0	12
13912	CATINZACO EMBARCADERO FCGB	5374	0	12
13913	CHILECITO	5360	0	12
13914	GUACHIN	5367	0	12
13916	LA PUNTILLA	5367	0	12
13917	LOS SARMIENTOS	5361	0	12
13918	MALLIGASTA	5361	0	12
13919	MIRANDA	5367	0	12
13920	NONOGASTA	5372	0	12
13921	SAMAY HUASI	5360	0	12
13922	SAN MIGUEL	5361	0	12
13923	SAN NICOLAS	5360	0	12
13924	SA	5367	0	12
13925	SANTA FLORENTINA	5360	0	12
13926	TILIMUQUI	5361	0	12
13927	VICHIGASTA	5374	0	12
13928	AICU	5361	0	12
13929	BANDA FLORIDA	5351	0	12
13930	EL FUERTE	5351	0	12
13931	EL MOLLE	5350	0	12
13932	EL ZAPALLAR	5353	0	12
13933	LA MARAVILLA	5351	0	12
13934	LA PAMPA	5361	0	12
13935	LA PERLITA	5350	0	12
13936	LOS FRANCES	5350	0	12
13937	LOS NACIMIENTOS	5353	0	12
13938	LOS PALACIOS	5351	0	12
13939	LOS TAMBILLOS	5361	0	12
13940	PAGANCILLO	5369	0	12
13941	PASO SAN ISIDRO	5351	0	12
13942	PUERTO ALEGRE	5361	0	12
13943	SAN BERNARDO	5350	0	12
13944	SANTA CLARA	5351	0	12
13945	VILLA UNION	5350	0	12
13946	EL DIVISADERO	5470	0	12
13947	ALTO CARRIZAL	5361	0	12
13948	ANGULOS	5361	0	12
13949	ANTINACO	5361	0	12
13950	BARRIO DE GALLI	5361	0	12
13952	CARRIZALILLO	5361	0	12
13954	EL CHOCOY	5361	0	12
13955	EL JUMEAL	5365	0	12
13956	EL PEDREGAL	5361	0	12
13957	FAMATINA	5365	0	12
13958	LA BANDA	5365	0	12
13959	LA CUADRA	5361	0	12
13960	LAS GREDAS	5365	0	12
13961	LOS CORRALES	5361	0	12
13962	PITUIL	5361	0	12
13963	PLAZA NUEVA	5365	0	12
13964	PLAZA VIEJA	5361	0	12
13965	SANTA CRUZ	5361	0	12
13966	SANTO DOMINGO	5361	0	12
13967	BELLA VISTA	5381	0	12
13969	ESQUINA DEL NORTE	5380	0	12
13970	SANTA RITA LA ZANJA	5276	0	12
13971	ALCAZAR	5385	0	12
13972	TAMA	5385	0	12
13973	CHILA	5385	0	12
13974	COLONIA ALFREDO	5380	0	12
13975	EL PUESTO	5385	0	12
13976	FALDA DE CITAN	5385	0	12
13977	LA LOMITA	5385	0	12
13978	LA MERCED	5385	0	12
13979	LA REPRESA	5385	0	12
13980	LAS HIGUERAS	5385	0	12
13981	PACATALA	5385	0	12
13982	PUNTA DE LOS LLANOS	5384	0	12
13983	TASQUIN	5385	0	12
13984	TUIZON	5385	0	12
13985	VILLA CASANA	5471	0	12
13986	AGUA COLORADA	5383	0	12
13987	BAJO GRANDE	5383	0	12
13988	BALDE SALADO	5383	0	12
13989	BALDES DE PACHECO	5276	0	12
13990	CISCO	5383	0	12
13991	EL CHUSCO	5276	0	12
13992	EL QUEBRACHO	5383	0	12
13993	ESQUINA DEL SUD	5383	0	12
13994	ILIAR	5381	0	12
13996	LA FLORIDA	5276	0	12
13997	LA HUERTA	5383	0	12
13998	LA TRAMPA	5383	0	12
13999	LAS VERTIENTES	5276	0	12
14000	LOMA BLANCA	5381	0	12
14001	LOMA LARGA	5383	0	12
14002	NEPES	5276	0	12
14003	OLTA	5383	0	12
14004	SIMBOLAR	5276	0	12
14005	TALA VERDE	5383	0	12
14006	TALVA	5381	0	12
14007	VERDE OLIVO	5276	0	12
14008	CHAMICAL	5380	0	12
14009	EL MOLLAR	5381	0	12
14010	AGUADITA	5385	0	12
14011	ATILES	5385	0	12
14012	CASANGATE	5385	0	12
14013	CHIMENEA	5385	0	12
14014	EL BARRANCO	5385	0	12
14015	EL PORTEZUELO	5385	0	12
14016	EL POTRERILLO	5385	0	12
14017	EL POTRERO	5385	0	12
14018	HUAJA	5385	0	12
14019	ILISCO	5471	0	12
14021	LA ESQUINA	5471	0	12
14022	LA TORDILLA	5471	0	12
14023	LA YESERA	5471	0	12
14024	LOS ALGARROBOS	5385	0	12
14025	MALANZAN	5385	0	12
14026	MOLLACO	5385	0	12
14027	NACATE	5385	0	12
14028	PUESTO DE LOS SANCHEZ	5471	0	12
14029	RETAMAL	5385	0	12
14030	RIO DE LAS CA	5385	0	12
14031	SALANA	5385	0	12
14032	SAN ANTONIO	5471	0	12
14035	SOLCA	5385	0	12
14036	TUANI	5385	0	12
14037	EL ALTILLO	5355	0	12
14038	EL CONDADO	5355	0	12
14039	LAS AGUADITAS	5355	0	12
14040	PADERCITAS	5355	0	12
14041	RIVADAVIA	5355	0	12
14042	VILLA CASTELLI	5355	0	12
14043	AGUA COLORADA	5275	0	12
14044	ALTILLO DEL MEDIO	5274	0	12
14045	AMBIL	5475	0	12
14046	CATUNA	5275	0	12
14047	CHA	5276	0	12
14048	COLONIA ORTIZ DE OCAMPO	5275	0	12
14049	COMANDANTE LEAL	5272	0	12
14050	DIQUE DE ANZULON	5275	0	12
14051	DIQUE LOS SAUCES	5274	0	12
14052	EL CARRIZAL	5475	0	12
14053	EL CERCO	5475	0	12
14054	EL CIENAGO	5275	0	12
14055	EL FRAILE	5274	0	12
14056	EL QUEMADO	5475	0	12
14057	EL VERDE	5275	0	12
14058	ESQUINA GRANDE	5275	0	12
14059	FRANCISCO ORTIZ DE OCAMPO	5275	0	12
14061	LA AGUADITA	5275	0	12
14062	LA DORA	5475	0	12
14063	LA IGUALDAD	5474	0	12
14064	LAS PALOMAS	5275	0	12
14065	LOS AGUIRRES	5275	0	12
14066	LOS ALANICES	5275	0	12
14067	LOS BARRIACITOS	5274	0	12
14068	LOS MISTOLES	5275	0	12
14069	MILAGRO	5274	0	12
14070	OLPAS	5275	0	12
14071	PIEDRA LARGA	5475	0	12
14072	POZO DEL MEDIO	5274	0	12
14073	SAN CRISTOBAL	5274	0	12
14074	SAN JOSE	5475	0	12
14075	TORRECITAS	5275	0	12
14076	VILLA SANTA RITA	5275	0	12
14077	AGUAYO	5473	0	12
14078	CA	5471	0	12
14079	CORRAL DE ISAAC	5471	0	12
14080	CORTADERAS	5381	0	12
14081	CUATRO ESQUINAS	5473	0	12
14082	EL BALDE	5471	0	12
14083	EL CALDEN	5717	0	12
14084	EL CATORCE	5474	0	12
14085	EL VALLECITO	5360	0	12
14087	LA ISLA	5274	0	12
14088	NUEVA ESPERANZA	5473	0	12
14089	POZO DE LA PIEDRA	5473	0	12
14090	PUESTO DE CARRIZO	5471	0	12
14091	PUESTO DICHOSO	5471	0	12
14092	SAN ANTONIO	5473	0	12
14093	SANTO DOMINGO	5473	0	12
14094	SIEMPRE VERDE	5473	0	12
14095	ULAPES	5473	0	12
14096	VILLA NIDIA	5473	0	12
14097	AMANA	5386	0	12
14098	LA TORRE	5386	0	12
14099	LOS COLORADOS	5386	0	12
14100	PAGANZO	5386	0	12
14101	PATQUIA	5386	0	12
14102	SALINAS DE BUSTOS	5386	0	12
14103	ABRA VERDE	5470	0	12
14104	AGUA BLANCA	5471	0	12
14105	AGUA DE LA PIEDRA	5475	0	12
14106	AGUA DE PIEDRA	5470	0	12
14107	ALTO BAYO	5470	0	12
14108	BARRANQUITAS	5474	0	12
14109	CA	5470	0	12
14110	CASAS VIEJAS	5471	0	12
14111	CHEPES	5470	0	12
14112	DESIDERIO TELLO	5474	0	12
14113	EL ALTO	5470	0	12
14114	EL BARREAL	5470	0	12
14115	EL CINCUENTA	5470	0	12
14116	EL POTRERILLO	5475	0	12
14117	EL TALA	5471	0	12
14118	LA AGUADA	5470	0	12
14119	LA CALERA	5471	0	12
14120	LA CALLANA	5471	0	12
14121	LA CONSULTA	5470	0	12
14122	LA JARILLA	5471	0	12
14123	LA LAGUNA	5471	0	12
14124	LA PINTADA	5470	0	12
14125	LA PRIMAVERA	5470	0	12
14126	LA REFORMA	5471	0	12
14127	LAS SALINAS	5471	0	12
14128	LAS TOSCAS	5471	0	12
14129	LAS TUSCAS	5470	0	12
14130	LOS CORIAS	5471	0	12
14131	LOS OROS	5470	0	12
14132	MASCASIN	5471	0	12
14133		5471	0	12
14134	PORTEZUELO DE LOS ARCE	5471	0	12
14135	PUNTA DEL CERRO	5470	0	12
14136	QUEBRADA DEL VALLECITO	5471	0	12
14137	REAL DEL CADILLO	5471	0	12
14138	SAN JOSE	5471	0	12
14139	SAN RAFAEL	5471	0	12
14140	SANTA CRUZ	5470	0	12
14141	TAMA	5385	0	12
14142	TOTORAL	5471	0	12
14143	VALLE HERMOSO	5471	0	12
14144	VILLA CHEPES	5471	0	12
14145	ALPASINCHE	5325	0	12
14146	AMUSCHINA	5329	0	12
14147	ANDOLUCAS	5329	0	12
14148	CHAUPIHUASI	5327	0	12
14149	CUIPAN	5329	0	12
14150	EL RETIRO	5325	0	12
14151	LA PIRGUA	5325	0	12
14152	LA PLAZA	5329	0	12
14153	LAS TALAS	5329	0	12
14154	LOROHUASI	5325	0	12
14155	LOS OLIVARES	5327	0	12
14156	LOS ROBLES	5329	0	12
14157	SALICAS	5327	0	12
14158	SCHAQUI	5329	0	12
14159	SURIYACO	5329	0	12
14160	TUYUBIL	5329	0	12
14161	EL HUACO	5301	0	12
14162	HUACO	5301	0	12
14163	LAS BOMBAS	5301	0	12
14165	VILLA BUSTOS	5301	0	12
14166	VILLA SANAGASTA	5301	0	12
14167	EL HORNO	5357	0	12
14168	LA BANDA	5359	0	12
14169	PE	5359	0	12
14170	POTRERO GRANDE	5359	0	12
14171	VALLE HERMOSO	5359	0	12
14172	VINCHINA	5357	0	12
14173	ALTO JAGUEL	5359	0	12
14174	BAJO JAGUEL	5359	0	12
14175	CASA PINTADA	5359	0	12
14176	DISTRITO PUEBLO	5359	0	12
14177	JAGUE	5359	0	12
14178	LA CIENAGA	5350	0	12
14179	COLONIA SANTA ROSA AGUIRRE	2357	0	22
14180	MALBRAN	2354	0	22
14181	PINTO  VILLA GENERAL MITRE	2356	0	22
14182	BUEN LUGAR	4301	0	22
14183	CAMPO GALLO	3747	0	22
14184	CAMPO GRANDE	4301	0	22
14185	CEJAS	4301	0	22
14186	CUQUENOS	4301	0	22
14187	EL BA	4301	0	22
14188	EL MILAGRO	4301	0	22
14189	EL OLIVAR	4301	0	22
14190	EL PORVENIR	4301	0	22
14191	ESTEROS	4301	0	22
14192	FORTUNA	4301	0	22
14193	HUACHANA	4301	0	22
14194	LA PALOMA	4301	0	22
14195	LAS PALMITAS	4301	0	22
14196	MAJANCITO	4301	0	22
14197	MONTEVIDEO	4301	0	22
14198	MORADITO	4301	0	22
14199	NARANJITO	4301	0	22
14200	NORQUEOJ	4301	0	22
14201	NUEVA GRANADA	4301	0	22
14202	POZO DEL CASTA	4301	0	22
14203	POZO GRANDE	4301	0	22
14204	RANCHITOS	4301	0	22
14205	RETIRO	4301	0	22
14206	SACHAYOJ	3731	0	22
14207	SANTA CRUZ	4301	0	22
14208	SANTA ROSA	3749	0	22
14209	SANTOS LUGARES	4301	0	22
14210	TACA	4301	0	22
14211	TACO POZO	4301	0	22
14212	TARPUNA	4301	0	22
14213	VILLA PALMAR	4301	0	22
14214	ALBARDON	4208	0	22
14215	ALBARDON CHU	4208	0	22
14216	AYUNCHA	4208	0	22
14217	BURRA HUA	4208	0	22
14218	CA	4201	0	22
14219	EL REMANSO	4208	0	22
14220	ISLA VERDE	4212	0	22
14221	VILLA ATAMISQUI	4317	0	22
14222	COLONIA DORA	4332	0	22
14223	HERRERA	4328	0	22
14224	ICA	4334	0	22
14225	LUGONES	4326	0	22
14226	REAL SAYANA	4334	0	22
14227	ABRA GRANDE	4336	0	22
14228	ALTO POZO	4302	0	22
14229	ANTAJE	4302	0	22
14230	ARDILES	4302	0	22
14231	ARDILES DE LA COSTA	4302	0	22
14232	BARRIO ESTE	4300	0	22
14233	BEJAN	4225	0	22
14234	CA	4301	0	22
14235	CHA	4302	0	22
14236	CHAUPI POZO	4302	0	22
14237	CLODOMIRA	4338	0	22
14238	COLONIAS	4302	0	22
14239	COLONIA MARIA LUISA	4300	0	22
14240	CORVALANES	4302	0	22
14241	CUYOJ	4300	0	22
14242	EL AIBE	4302	0	22
14243	EL ALAMBRADO	4300	0	22
14244	EL BARRIAL	4300	0	22
14245	EL BOSQUE	4300	0	22
14246	EL CARMEN	4300	0	22
14247	EL CEBOLLIN	4302	0	22
14248	EL PARAISO	4300	0	22
14249	EL PUENTE	4302	0	22
14250	EL ROSARIO	4300	0	22
14252	KILOMETRO 661	4300	0	22
14253	KILOMETRO 665	4300	0	22
14254	KISKA HURMANA	4302	0	22
14255	LA BANDA	4300	0	22
14256	LA CA	4302	0	22
14257	LA CUARTEADA	4302	0	22
14258	LA FALDA	4302	0	22
14259	LA GERMANIA	4302	0	22
14261	LA ISLA	4300	0	22
14262	LA VUELTA	4302	0	22
14263	LAS COLONIAS	4302	0	22
14264	LAS HERMANAS	4300	0	22
14265	LOS ALDERETES	4302	0	22
14266	LOS DIAZ	4302	0	22
14267	LOS DOCE QUEBRACHOS	4302	0	22
14268	LOS GALLARDOS	4302	0	22
14269	LOS HERREROS	4302	0	22
14270	LOS NARANJOS	4300	0	22
14271	LOS PUESTOS	4302	0	22
14272	LOS PUNTOS	4302	0	22
14273	MEDIA FLOR	4336	0	22
14274	NUEVA ANTAJE	4300	0	22
14275	NUEVA TRINIDAD	4300	0	22
14276	PALERMO	4302	0	22
14277	QUISHCA	4302	0	22
14278	QUITA PUNCO	4302	0	22
14279	RINCON	4300	0	22
14280	RUBIA MORENO	4300	0	22
14281	SAN CARLOS	4300	0	22
14282	SAN JUAN	4300	0	22
14283	SAN LORENZO	4302	0	22
14284	SAN MARTIN	4302	0	22
14285	SAN RAMON	4302	0	22
14286	SAN ROQUE	4302	0	22
14287	SANTA CRUZ	4302	0	22
14288	SANTA RITA	4302	0	22
14289	SANTA ROSA	4302	0	22
14290	SANTOS LUGARES	4300	0	22
14291	SIMBOLAR	4339	0	22
14292	SINQUEN PUNCO	4302	0	22
14293	SURI POZO	4302	0	22
14294	TAPERAS	4302	0	22
14295	TRAMO 16	4301	0	22
14296	VILLA UNION	4300	0	22
14297	BANDERA	3064	0	22
14298	FORTIN INCA	3062	0	22
14299	GUARDIA ESCOLTA	3062	0	22
14300	ANTILO	4225	0	22
14301	EL BARRIAL	4225	0	22
14302	EL CHURQUI	4225	0	22
14303	LAS CEJAS	4221	0	22
14304	SANTIAGO DEL ESTERO	4200	0	22
14305	25 DE MAYO SUD	4231	0	22
14306	ANCAJAN	4233	0	22
14307	BALDE POZO	4237	0	22
14308	BARRIO JARDIN	4230	0	22
14309	CERRO RICO	4231	0	22
14310	CHA	4230	0	22
14311	CHILLIMO	4237	0	22
14312	EL ABRA	4237	0	22
14313	EL SALVADOR	4231	0	22
14314	FLORIDA	4237	0	22
14315	GUATANA	4230	0	22
14316	KILOMETRO 1073	4230	0	22
14317	KILOMETRO 1098	4234	0	22
14318	KILOMETRO 18	4233	0	22
14319	KILOMETRO 3	4230	0	22
14320	LA ESPERANZA	4230	0	22
14321	LA ESQUINA	4230	0	22
14322	LA GUARDIA	4233	0	22
14323	LA LAGUNA	4230	0	22
14324	LA REPRESA	4233	0	22
14325	LAPRIDA	4205	0	22
14326	LAS FLORES	4230	0	22
14327	LAS PE	4237	0	22
14328	LOS RALOS	4230	0	22
14329	MENDOZA	4237	0	22
14330	MOJONCITO	4233	0	22
14331	POZO DE LA PUERTA	4230	0	22
14332	PUERTA DE LAS PIEDRAS	4230	0	22
14333	REMANSITO	4230	0	22
14334	RUMI ESQUINA	4234	0	22
14335	SAN JOSE	4237	0	22
14336	SAN JUAN	4233	0	22
14337	SAN JUANCITO	4233	0	22
14338	SAN PEDRO	4233	0	22
14339	VILLA COINOR	4230	0	22
14340	ZORRO HUARCUNA	4237	0	22
14341	BELGRANO	4301	0	22
14342	DOS ARBOLES	4452	0	22
14343	MANGA BAJADA	4301	0	22
14344	MONTE QUEMADO	3714	0	22
14345	PAMPA DE LOS GUANACOS	3712	0	22
14346	RIO MUERTO	4301	0	22
14347	SAN JOSE DEL BOQUERON	4301	0	22
14348	SAN VICENTE	4301	0	22
14349	VINAL VIEJO	4301	0	22
14350	BANDERA BAJADA	4301	0	22
14351	CALLEJON BAJADA	4301	0	22
14352	CANTEROS	4301	0	22
14353	CARDON ESQUINA	4301	0	22
14354	CASPI CORRAL	4301	0	22
14355	CHILE	4301	0	22
14356	DIQUE FIGUEROA	4301	0	22
14357	EL CHA	4301	0	22
14358	EL PIRUCHO	4301	0	22
14359	EL QUEMADO	4301	0	22
14360	JUMI VIEJO	4301	0	22
14361	LA PACIENCIA	4301	0	22
14362	PALIZAS	4301	0	22
14363	PORONGOS	4301	0	22
14364	QUEBRACHAL	4301	0	22
14365	REPARO	4301	0	22
14366	RINCON	4301	0	22
14367	SAN JORGE	4301	0	22
14368	SAN JOSE	4301	0	22
14369	SAN PABLO	4301	0	22
14370	SAN ROQUE	4301	0	22
14371	SAN VICENTE	4301	0	22
14372	SANTA RITA	4301	0	22
14373	SANTA ROSA	4354	0	22
14374	SAUCE ESQUINA	4301	0	22
14375	TAJAMAR	4301	0	22
14376	VACA HUA	4353	0	22
14377	A	3760	0	22
14378	AVERIAS	3766	0	22
14379	EL MALACARA	3761	0	22
14380	LOS JURIES	3763	0	22
14381	TRES CERROS	4237	0	22
14382	LOMA DE YESO	4238	0	22
14383	9 DE JULIO	4238	0	22
14384	ABRA DE QUIMIL	4238	0	22
14385	AGUJEREADO	4238	0	22
14386	AHI VEREMOS	4238	0	22
14387	AIBALITO	4238	0	22
14388	CAMPO VERDE	4238	0	22
14389	CODILLO	4238	0	22
14390	DO	4225	0	22
14391	EL CADILLO	4238	0	22
14392	EL CARMEN	4238	0	22
14393	EL PORVENIR	4238	0	22
14394	EL PUESTITO	4238	0	22
14395	EL QUILLIN	4234	0	22
14396	EL SIMBOLAR	4238	0	22
14397	ILIAGES	4238	0	22
14398	JUMIAL	4238	0	22
14399	KILOMETRO 1121	4234	0	22
14400	LA CHILCA	4238	0	22
14401	LAS FLORES	4234	0	22
14402	LAS JUNTAS	4238	0	22
14403	LAS MARAVILLAS	4238	0	22
14404	LAS TALITAS	4238	0	22
14405	LOS COBRES	4238	0	22
14406	LOS CORREAS	4238	0	22
14407	MANGRULLO	4234	0	22
14408	MEDIO MUNDO	4238	0	22
14409	MISTOL MUYOJ	4225	0	22
14410	MORON	4238	0	22
14411	PALMITAS	4238	0	22
14412	PAMPA POZO	4238	0	22
14413	POZANCON	4238	0	22
14414	POZO CABADO	4238	0	22
14415	POZO HUASCHO	4225	0	22
14416	PROVIDENCIA	4238	0	22
14417	PUESTO DE DIAZ	4238	0	22
14418	PUESTO DEL MEDIO	4238	0	22
14419	QUEBRACHOS	4225	0	22
14420	SAN ANTONIO	4234	0	22
14421	SAN ANTONIO	4238	0	22
14422	SAN JOSE	4238	0	22
14423	SAN JUAN	4238	0	22
14424	SAN LORENZO	4238	0	22
14425	SAN PEDRO	4238	0	22
14426	SAN RAMON	4238	0	22
14427	SANTA BARBARA	4208	0	22
14428	TABLEADO	4238	0	22
14429	TALA POZO	4238	0	22
14430	TIBILAR	4238	0	22
14431	TONZU	4234	0	22
14432	VILLA GUASAYAN	4238	0	22
14433	VILLARES	4238	0	22
14434	EL CHARCO	4306	0	22
14435	LA FORTUNA	4304	0	22
14436	LAS ORELLANAS	4304	0	22
14437	POZO HONDO	4184	0	22
14438	SAN GREGORIO	4301	0	22
14439	COLONIA SIEGEL	4356	0	22
14440	EL CUADRADO	3765	0	22
14441	MATARA	4356	0	22
14442	SUNCHO CORRAL	4350	0	22
14443	TOBAS	3752	0	22
14444	VILELAS	3752	0	22
14445	CA	4208	0	22
14446	CA	4315	0	22
14447	CHU	4208	0	22
14448	DIENTE DEL ARADO	4208	0	22
14449	DORMIDA	4208	0	22
14450	EL MULATO	4208	0	22
14451	EL PINTO	4208	0	22
14452	JUMI POZO	4208	0	22
14453	KILOMETRO 88	4208	0	22
14454	LA NORIA	4208	0	22
14455	LA REVANCHA	4208	0	22
14456	LOMITAS	4208	0	22
14457	LORETO	4208	0	22
14458	MONTE REDONDO	4212	0	22
14459	MORAMPA	4208	0	22
14460	POZO CIEGO	4208	0	22
14461	PUESTO DE JUANES	4208	0	22
14462	RAMADITA	4208	0	22
14463	SAN GREGORIO	4208	0	22
14464	SAN ISIDRO	4208	0	22
14465	SAN JERONIMO	4208	0	22
14466	SAN JOSE	4208	0	22
14467	SAN JUAN	4208	0	22
14468	SAN MIGUEL	4208	0	22
14469	SAN PABLO	4208	0	22
14470	SAN VICENTE	4212	0	22
14471	SANDIA HUAJCHU	4208	0	22
14472	SANTA BARBARA FERREIRA	4208	0	22
14473	SANTA MARIA	4208	0	22
14474	TACA	4208	0	22
14475	TALA ATUN	4208	0	22
14476	TAQUETUYOJ	4208	0	22
14477	TONTOLA	4208	0	22
14478	TORO CHARQUINA	4208	0	22
14479	TOTORA PAMPA	4208	0	22
14480	TOTORAS	4208	0	22
14481	TUSCA POZO	4208	0	22
14482	TUSCA POZO	4212	0	22
14483	TUSCAYOJ	4208	0	22
14484	YALAN	4208	0	22
14485	YOLOHUASI	4208	0	22
14486	YULU HUASI	4208	0	22
14487	ALHUAMPA	3741	0	22
14488	AMAMA	4353	0	22
14489	GIRARDET	3736	0	22
14490	LIBERTAD	3745	0	22
14491	MONTE REDONDO	4301	0	22
14492	QUIMILI	3740	0	22
14493	TINTINA	3743	0	22
14494	WEISBURD	4351	0	22
14495	KILOMETRO 49	5258	0	22
14496	LA ISLA	5251	0	22
14497	SOL DE JULIO	5255	0	22
14498	VILLA OJO DE AGUA	5250	0	22
14499	BABILONIA	4301	0	22
14500	BAJO GRANDE	4301	0	22
14501	BOBADAL	4187	0	22
14502	CAMPO GRANDE	4189	0	22
14503	CASA VERDE	4301	0	22
14504	CHA	4301	0	22
14505	CHA	4301	0	22
14507	EL MOJON	4197	0	22
14508	EL PORVENIR	4301	0	22
14509	EL REMATE	4195	0	22
14510	ESTECO	4301	0	22
14511	HOYO CERCO	4301	0	22
14512	HU	4301	0	22
14513	LA LOMADA	4301	0	22
14514	LOMA NEGRA	4302	0	22
14515	NUEVA ESPERANZA	4197	0	22
14516	NUEVO SIMBOLAR	4301	0	22
14517	POTRERO BAJADA	4301	0	22
14518	POZO DEL SIMBOL	4301	0	22
14519	RANCHITOS	4301	0	22
14520	SAN LUIS	4301	0	22
14521	SAN RAMON	4339	0	22
14522	SANTO DOMINGO PELLEGRINI	4301	0	22
14523	SORIA BAJADA	4301	0	22
14524	TACA	4301	0	22
14525	VILLA NUEVA	4301	0	22
14526	SUMAMPA	5253	0	22
14527	ABRA DE LA CRUZ	4225	0	22
14528	ABRAS DEL MARTIRIZADO	4225	0	22
14529	AGUADA	4220	0	22
14530	ALGARROBALES	4304	0	22
14531	ALPA PUCA	4225	0	22
14532	AMAPOLA	4223	0	22
14533	ANJULI	4220	0	22
14534	BAHOMA	4220	0	22
14535	BAJO VERDE	4223	0	22
14536	BARRIALITO	4225	0	22
14537	BAUMAN	4225	0	22
14538	BEBIDAS	4225	0	22
14539	BUENA VISTA	4220	0	22
14540	CA	4220	0	22
14541	CA	4220	0	22
14542	CA	4223	0	22
14543	CHA	4225	0	22
14544	CHA	4304	0	22
14545	CHA	4220	0	22
14546	CHA	4225	0	22
14547	CHURQUI	4301	0	22
14548	COLONIA TINCO	4220	0	22
14549	EL ALAMBRADO	4223	0	22
14550	EL MANANTIAL	4220	0	22
14551	EL PUESTO	4223	0	22
14552	EL RETIRO	4223	0	22
14553	EL RINCON	4220	0	22
14554	ESPINAL	4220	0	22
14555	ESTANCIA VIEJA	4220	0	22
14556	GALEANO	4220	0	22
14557	GRAMILLA	4304	0	22
14558	HUASCHO PATILLA	4220	0	22
14559	ISLA DE LOS CASTILLOS	4220	0	22
14560	ISLA DE LOS SOTELOS	4304	0	22
14561	LA AGUADA	4220	0	22
14562	LA SOLEDAD	4225	0	22
14563	LOMA DEL MEDIO	4223	0	22
14564	LORO HUASI	4220	0	22
14565	LOS CASTILLOS	4220	0	22
14566	LOS DECIMAS	4221	0	22
14567	LOS FIERROS	4220	0	22
14568	MANANTIALES	4220	0	22
14569	MANSUPA	4220	0	22
14570	PALMA REDONDA	4223	0	22
14571	PATILLO	4225	0	22
14572	PEREZ DE ZURITA	4221	0	22
14573	PUESTO DE VIEYRA	4225	0	22
14574	PUESTO DEL RETIRO	4223	0	22
14575	PUNTA POZO	4225	0	22
14576	QUEBRACHOS	4225	0	22
14577	QUERA	4225	0	22
14578	SAN CARLOS	4225	0	22
14579	SAN COSME	4225	0	22
14580	SAN PABLO	4220	0	22
14581	TACAMAMPA	4220	0	22
14582	TALA	4220	0	22
14583	TALA POZO	4223	0	22
14584	TAQUELLO	4223	0	22
14585	TERMAS DE RIO HONDO	4220	0	22
14586	VILLA BALNEARIA	4220	0	22
14587	VILLA RIO HONDO	4225	0	22
14588	YUTO YACA	4221	0	22
14589	YUTU YACO	4221	0	22
14590	CLAVEL BLANCO	2341	0	22
14591	NUEVA CERES	2340	0	22
14592	SELVA	2354	0	22
14593	ACOSTA	4302	0	22
14594	AGUAS COLORADAS	4301	0	22
14595	AREAS	4301	0	22
14596	BANEGAS	4302	0	22
14597	BELTRAN	4308	0	22
14598	COLONIA EL SIMBOLAR	4354	0	22
14599	DIQUE CHICO	4301	0	22
14600	EL CERCADO	4302	0	22
14601	FERNANDEZ	4322	0	22
14602	GUAYCURU	4302	0	22
14604	LA PAZ	4301	0	22
14605	LA RIVERA	4301	0	22
14606	LOS ARIAS	4301	0	22
14607	LOS PEREYRA	4301	0	22
14608	POZO LIMPIO	4301	0	22
14609	POZO VERDE	4301	0	22
14610	QUEBRACHO YACU	4301	0	22
14611	ROMANOS	4302	0	22
14613	SANTO DOMINGO ROBLES	4301	0	22
14614	SARMIENTO	4302	0	22
14615	TABLADA DEL BOQUERON	4301	0	22
14616	TURENA	4302	0	22
14617	TUSCA BAJADA	4301	0	22
14618	VILLA HIPOLITA	4301	0	22
14619	VILMER	4302	0	22
14620	BARRANCAS	4319	0	22
14621	LOS TELARES	4321	0	22
14622	ORATORIO	5257	0	22
14623	BREA POZO	4313	0	22
14624	LA HIGUERA	4301	0	22
14625	GARZA	4324	0	22
14626	ARRAGA	4206	0	22
14627	KILOMETRO 112	4208	0	22
14628	KILOMETRO 118	4208	0	22
14629	KILOMETRO 120	4208	0	22
14630	NUEVA FRANCIA	4206	0	22
14631	SAUCE SOLO	4206	0	22
14661	AGUA HEDIONDA	5705	0	19
14662	AGUADITA	5719	0	19
14663	ALGARROBAL	5707	0	19
14664	ARBOL VERDE	5715	0	19
14665	BAJADA	5711	0	19
14666	BALDE AHUMADA	5713	0	19
14667	BALDE DE ARRIBA	5707	0	19
14668	BALDE DE AZCURRA	5707	0	19
14669	BALDE DE GARCIA	5715	0	19
14670	BALDE DE GUARDIA	5713	0	19
14671	BALDE DE LEDESMA	5715	0	19
14672	BALDE DE MONTE	5715	0	19
14673	BALDE DE PUERTAS	5707	0	19
14674	BALDE DE QUINES	5715	0	19
14675	BALDE DE TORRES	5713	0	19
14676	BALDE EL CARRIL	5713	0	19
14677	BALDE HONDO	5705	0	19
14678	BALDE RETAMO	5711	0	19
14679	BALDE VIEJO	5711	0	19
14680	BALDECITO	5713	0	19
14681	BALDECITO LA PAMPA	5707	0	19
14682	BA	5707	0	19
14683	BA	5705	0	19
14684	BANDA SUD	5705	0	19
14685	BA	5711	0	19
14686	BARRIALES	5707	0	19
14687	BARZOLA	5707	0	19
14688	BELLA VISTA	5705	0	19
14689	BOTIJAS	5707	0	19
14690	CAMPANARIO	5705	0	19
14691	CA	5703	0	19
14692	CA	5709	0	19
14693	CANDELARIA	5713	0	19
14694	CANTANTAL	5707	0	19
14695	CARMELO	5707	0	19
14696	CEBOLLAR	5709	0	19
14697	CERRO BAYO	5707	0	19
14698	CERRO NEGRO	5707	0	19
14699	CHIMBAS	5707	0	19
14700	CHIMBORAZO	5707	0	19
14701	CONSULTA	5709	0	19
14702	CORRAL DE PIEDRA	5709	0	19
14703	EL ALTO	5715	0	19
14704	EL BA	5711	0	19
14705	EL CADILLO	5713	0	19
14706	EL CALDEN	5711	0	19
14707	EL CARMEN	5719	0	19
14708	EL CHA	5711	0	19
14709	EL ESPINILLO	5703	0	19
14710	EL HORMIGUERO	5713	0	19
14711	EL INJERTO	5711	0	19
14712	EL MANANTIAL	5709	0	19
14713	EL MOLINO	5709	0	19
14714	EL MOLLAR	5713	0	19
14715	EL MOLLARCITO	5707	0	19
14716	EL PAYERO	5707	0	19
14717	EL PIMPOLLO	5717	0	19
14718	EL POTRERILLO	5711	0	19
14719	EL POTRERO DE LEYES	5703	0	19
14720	EL PUESTITO	5713	0	19
14721	EL PUESTO	5711	0	19
14722	EL RINCON	5707	0	19
14723	EL SEMBRADO	5713	0	19
14724	EL VERANO	5707	0	19
14725	EL ZAPALLAR	5711	0	19
14726	ENTRE RIOS	5711	0	19
14727	LA AGUADA	5711	0	19
14728	LA BAJADA	5713	0	19
14729	LA BAVA	5705	0	19
14730	LA BREA	5711	0	19
14731	LA COLONIA	5713	0	19
14732	LA ESQUINA	5709	0	19
14733	LA FLORIDA	5711	0	19
14734	LA LEGUA	5709	0	19
14735	LA MAJADA	5703	0	19
14736	LA MEDULA	5713	0	19
14737	LA MODERNA	5713	0	19
14738	LA PATRIA	5707	0	19
14739	LA PLATA	5713	0	19
14740	LA PORFIA	5705	0	19
14741	LA PRIMAVERA	5719	0	19
14742	LA RAMADA	5713	0	19
14743	LA REPRESITA	5705	0	19
14744	LA RESISTENCIA	5713	0	19
14745	LA SALVADORA	5707	0	19
14746	LA SIRENA	5713	0	19
14747	LA TRANCA	5421	0	19
14748	LA TUSCA	5713	0	19
14749	LA VERTIENTE	5711	0	19
14750	LAS BAJADAS	5713	0	19
14751	LAS CHIMBAS	5713	0	19
14752	LAS LAGUNAS	5719	0	19
14753	LAS LAGUNITAS	5707	0	19
14754	LAS MESIAS	5707	0	19
14755	LAS PALOMAS	5715	0	19
14756	LAS PAMPITAS	5707	0	19
14757	LAS PLAYAS ARGENTINAS	5713	0	19
14758	LAS PUERTAS	5711	0	19
14759	LAS SALINAS	5705	0	19
14760	LEANDRO N ALEM	5703	0	19
14761	LINDO	5707	0	19
14762	LOMAS BLANCAS	5731	0	19
14763	LOS ALMACIGOS	5707	0	19
14764	LOS ARCES	5713	0	19
14765	LOS CERRILLOS	5715	0	19
14766	LOS MENDOCINOS	5707	0	19
14767	LOS PEJES	5709	0	19
14768	LUJAN	5709	0	19
14769	MANANTIAL	5709	0	19
14770	MARAVILLA	5705	0	19
14771	MEDANO BELLO	5713	0	19
14772	MONTE CARMELO	5707	0	19
14773	MONTE VERDE	5719	0	19
14774	PAMPA GRANDE	5707	0	19
14775	PAMPA INVERNADA	5705	0	19
14776	PASO DE PIEDRA	5707	0	19
14777	PASTAL	5707	0	19
14778	PATIO LIMPIO	5713	0	19
14779	PE	5707	0	19
14780	PIE DE LA CUESTA	5711	0	19
14781	POZO CAVADO	5705	0	19
14782	POZO DE LOS RAYOS	5705	0	19
14783	POZO DEL MOLLE	5707	0	19
14784	PUERTO RICO	5705	0	19
14785	PUESTO DE TABARES	5711	0	19
14786	PUESTO PAMPA INVERNADA	5705	0	19
14787	PUESTO QUEBRADA CAL	5705	0	19
14788	PUESTO ROBERTO	5713	0	19
14789	PUESTO TALAR	5711	0	19
14790	QUEBRACHITO	5713	0	19
14791	QUINES	5711	0	19
14792	RAMADITA	5705	0	19
14793	RAMBLONES	5705	0	19
14794	RIO JUAN GOMEZ	5705	0	19
14795	RODEO CADENAS	5705	0	19
14796	SALINAS	5713	0	19
14797	SAN CELESTINO	5713	0	19
14798	SAN FRANCISCO DEL MONTE DE ORO	5705	0	19
14799	SAN MARTIN	5713	0	19
14800	SAN MIGUEL	5711	0	19
14801	SAN PEDRO	5713	0	19
14802	SAN ROQUE	5703	0	19
14803	SAN RUFINO	5707	0	19
14804	SAN SALVADOR	5707	0	19
14805	SANTA ANA QUINES	5711	0	19
14806	SANTA ANA	5719	0	19
14807	SANTA CLARA	5711	0	19
14808	SANTA MARIA	5719	0	19
14809	SANTA RUFINA	5709	0	19
14810	SANTA TERESITA	5709	0	19
14811	SANTO DOMINGO	5707	0	19
14812	6 DE SEPTIEMBRE	5703	0	19
14813	SOCOSCORA	5705	0	19
14815	TEMERARIA	5707	0	19
14816	TINTITACO	5705	0	19
14817	TRES CA	5713	0	19
14818	VISTA ALEGRE	5707	0	19
14819	EL ZAMPAL	5707	0	19
14820	AGUA AMARGA	5719	0	19
14821	ALAZANAS	5719	0	19
14822	ALGARROBOS GRANDES	5719	0	19
14823	ALTA GRACIA	5703	0	19
14824	ALTILLO	5719	0	19
14825	ALTO	5703	0	19
14826	ARBOL SOLO	5703	0	19
14827	BAJO DE LA CRUZ	5719	0	19
14828	BEBIDA	5719	0	19
14829	BELLA ESTANCIA	5719	0	19
14830	CA	5719	0	19
14831	DIVISADERO	5703	0	19
14832	EL BAGUAL	5703	0	19
14833	EL BALDE	5703	0	19
14834	EL JARILLAL	5719	0	19
14835	EL PARAISO	5703	0	19
14836	EL PEDERNAL	5719	0	19
14837	EL RAMBLON	5719	0	19
14838	EL SALTO	5703	0	19
14839	EL VALLE	5719	0	19
14840	ESPINILLO	5703	0	19
14841	ESTANCIA SAN ROQUE	5719	0	19
14842	GIGANTE	5719	0	19
14843	HIPOLITO YRIGOYEN	5703	0	19
14844	HUALTARAN	5719	0	19
14845	LA AGUADA	5719	0	19
14846	LA ALAMEDA	5719	0	19
14847	LA CALERA	5719	0	19
14848	LA CHILCA	5703	0	19
14849	LA CORINA	5703	0	19
14850	LA DUDA	5703	0	19
14851	LA EMPAJADA	5719	0	19
14852	LA ESCONDIDA	5703	0	19
14853	LA ESPERANZA	5703	0	19
14854	LA ESTRELLA	5719	0	19
14855	LA EULOGIA	5703	0	19
14856	LA FLORIDA	5719	0	19
14857	LA GARZA	5703	0	19
14858	LA JOSEFA	5719	0	19
14859	LA JULIA	5703	0	19
14860	LA SANDIA	5703	0	19
14861	LA SERRANA	5703	0	19
14862	LA UNION	5703	0	19
14863	LA YESERA	5719	0	19
14864	LAS CARITAS	5703	0	19
14865	LAS GALERAS	5719	0	19
14866	LAS LOMAS	5703	0	19
14867	LONGARI	5703	0	19
14868	LOS AGUADOS	5719	0	19
14869	LOS ALGARROBOS	5703	0	19
14870	LOS ARADITOS	5719	0	19
14871	LOS CERRITOS	5719	0	19
14872	LOS CHA	5703	0	19
14873	LOS CHANCAROS	5719	0	19
14874	LOS MOLLES	5703	0	19
14875	LOS RAMBLONES	5703	0	19
14876	LOS TALAS	5719	0	19
14877	LOS TELARIOS	5719	0	19
14878	MANANTIALES	5703	0	19
14879	PALIGUANTA	5703	0	19
14880	PARAISO	5703	0	19
14881	PORTEZUELO	5719	0	19
14882	POZO DEL ESPINILLO	5703	0	19
14883	POZO DEL TALA	5703	0	19
14884	PUNTA DE LA SIERRA	5719	0	19
14885	RECREO	5719	0	19
14886	REPRESA DEL CARMEN	5719	0	19
14887	RETAMO	5703	0	19
14888	ROMANCE	5719	0	19
14889	RUMIGUASI	5703	0	19
14890	SAN AGUSTIN	5719	0	19
14891	SAN ANTONIO	5719	0	19
14892	SAN ISIDRO	5719	0	19
14893	SAN JOSE	5703	0	19
14894	SAN PEDRO	5719	0	19
14896	SANTA ROSA DEL GIGANTE	5719	0	19
14897	TAZA BLANCA	5703	0	19
14898	TORO NEGRO	5703	0	19
14899	TRES LOMAS	5719	0	19
14900	TRES PUERTAS	5719	0	19
14901	VILLA DE LA QUEBRADA	5703	0	19
14902	VILLA GENERAL ROCA	5703	0	19
14903	VIZCACHERAS	5703	0	19
14904	ALTO LINDO	5883	0	19
14905	BALCARCE	5883	0	19
14906	BELLA VISTA	5835	0	19
14907	CALERA ARGENTINA	5759	0	19
14908	CALERAS CA	5759	0	19
14909	CHACRAS VIEJAS	5770	0	19
14910	CHA	5773	0	19
14911	CHA	5883	0	19
14912	CHILCAS	5777	0	19
14913	CONCARAN	5770	0	19
14914	CONLARA	5759	0	19
14915	CORRAL DE TORRES	5777	0	19
14916	CORTADERAS	5883	0	19
14917	DOMINGUEZ	5835	0	19
14918	DURAZNITO	5777	0	19
14919	EL ARROYO	5770	0	19
14920	EL BA	5770	0	19
14921	EL CALDEN	5770	0	19
14922	EL CAVADO	5770	0	19
14923	EL CERRO	5770	0	19
14924	EL POLEO	5770	0	19
14925	EL PUESTO	5759	0	19
14926	EL RECUERDO	5883	0	19
14927	EL SAUCE	5831	0	19
14928	EL SAUCE	5770	0	19
14929	EL SOCORRO	5770	0	19
14930	EL TALA	5835	0	19
14931	EL TOTORAL	5773	0	19
14932	ESTANCIA	5883	0	19
14933	ESTANZUELA	5831	0	19
14934	FENOGLIO	5770	0	19
14935	HUCHISSON	5759	0	19
14936	LA ARGENTINA	5835	0	19
14937	LA AURORA	5835	0	19
14938	LA CRISTINA	5773	0	19
14939	LA ELVIRA	5773	0	19
14940	LA ESTANZUELA	5773	0	19
14941	LA GRAMILLA	5770	0	19
14942	LA RIOJITA	5773	0	19
14943	LA SUIZA	5759	0	19
14944	LAS CANTERAS	5759	0	19
14945	LAS NIEVES	5770	0	19
14946	LOS CHA	5835	0	19
14947	LOS COMEDORES	5770	0	19
14948	LOS CORRALITOS	5759	0	19
14949	LOS CUADROS	5835	0	19
14950	LOS ESPINILLOS	5883	0	19
14951	LOS MANANTIALES	5773	0	19
14952	LOS MOLLECITOS	5759	0	19
14953	LOS PUESTOS	5770	0	19
14954	LOS QUEBRACHOS	5770	0	19
14955	LOS SAUCES	5775	0	19
14956	MANANTIAL DE FLORES	5775	0	19
14957	MANANTIAL DE RENCA	5759	0	19
14958	MINA LOS CONDORES	5770	0	19
14959	NASCHEL	5759	0	19
14960	OTRA BANDA	5773	0	19
14961	PAPAGAYOS	5883	0	19
14962	PASO DE LOS ALGARROBOS	5773	0	19
14963	PIEDRAS CHATAS	5759	0	19
14964	PIQUILLINES	5835	0	19
14965	PORVENIR	5835	0	19
14966	PUENTE HIERRO	5773	0	19
14967	PUNTA DE LA LOMA	5773	0	19
14968	PUNTA DEL ALTO	5773	0	19
14969	RENCA	5775	0	19
14970	RETAZO DEL MONTE	5759	0	19
14971	RIOJITA	5773	0	19
14972	SAN FELIPE	5759	0	19
14973	SAN PABLO	5773	0	19
14974	SAN VICENTE	5770	0	19
14975	SANTA MARTINA	5770	0	19
14976	SANTA SIMONA	5770	0	19
14977	SELCI	5773	0	19
14978	TILISARAO	5773	0	19
14979	TOIGUS	5831	0	19
14980	USPARA	5835	0	19
14981	VILLA DEL CARMEN	5835	0	19
14982	VILLA DOLORES	5770	0	19
14983	VILLA ELENA	5883	0	19
14984	VILLA LARCA	5883	0	19
14985	VOLCAN ESTANZUELA	5835	0	19
14986	AGUA SALADA	5751	0	19
14987	ANTIHUASI	5701	0	19
14988	ARENILLA	5701	0	19
14989	BALDE DE LA ISLA	5701	0	19
14990	BUENA VENTURA	5701	0	19
14991	BUENA VISTA	5701	0	19
14992	CA	5750	0	19
14993	CA	5701	0	19
14994	CA	5701	0	19
14995	CANTERAS SANTA ISABEL	5750	0	19
14996	CAROLINA	5701	0	19
14997	CASA DE PIEDRA	5701	0	19
14998	CASAS VIEJAS	5750	0	19
14999	CERRO BLANCO	5701	0	19
15000	CERRO DE LA PILA	5750	0	19
15001	CERRO DE PIEDRA	5701	0	19
15002	CERRO VERDE	5750	0	19
15003	CERROS LARGOS	5701	0	19
15004	CHIPICAL	5701	0	19
15005	COMANDANTE GRANVILLE	5736	0	19
15006	CRUZ DE CA	5701	0	19
15007	CRUZ DE PIEDRA	5701	0	19
15008	EL VALLE	5701	0	19
15009	EL AMPARO	5701	0	19
15010	EL ARENAL	5701	0	19
15011	EL BLANCO	5750	0	19
15012	EL CHA	5751	0	19
15013	EL DURAZNO	5701	0	19
15014	EL PORTEZUELO	5750	0	19
15015	EL POZO	5750	0	19
15016	EL ROSARIO	5750	0	19
15017	EL TALITA	5751	0	19
15018	ELEODORO LOBOS	5722	0	19
15019	EMBALSE LA FLORIDA	5701	0	19
15020	ESTABLECIMIENTO LAS FLORES	5750	0	19
15021	ESTANCIA GRANDE	5701	0	19
15022	FRAGA	5736	0	19
15023	GRUTA DE INTIHUASI	5701	0	19
15024	HINOJITO	5701	0	19
15025	INTIHUASI	5701	0	19
15026	ISLA	5701	0	19
15027	LA AGUADA	5750	0	19
15028	LA ALAMEDA	5750	0	19
15029	LA ALIANZA	5701	0	19
15030	LA ARBOLEDA	5751	0	19
15031	LA BAJADA	5701	0	19
15032	LA CALAGUALA	5701	0	19
15033	LA CA	5750	0	19
15034	LA CAUTIVA	5736	0	19
15035	LA FLORIDA	5701	0	19
15036	LA FRAGUA	5750	0	19
15037	LA HIGUERITA	5701	0	19
15038	LA JUSTA	5750	0	19
15039	LA PETRA	5751	0	19
15040	LA RINCONADA	5750	0	19
15041	LA TOMA	5750	0	19
15042	LA TOTORA	5751	0	19
15043	LAGUNA BRAVA	5701	0	19
15044	LAS BARRANQUITAS	5701	0	19
15045	LAS DELICIAS	5750	0	19
15046	LAS FLORES	5750	0	19
15047	LAS PE	5750	0	19
15048	LAS ROSAS	5750	0	19
15049	LOS ARROYOS	5701	0	19
15050	LOS CARRICITOS	5701	0	19
15051	LOS MEDANITOS	5751	0	19
15052	LOS MEMBRILLOS	5751	0	19
15053	LOS MONTES	5701	0	19
15054	LOS PASITOS	5701	0	19
15055	LOS TAPIALES	5701	0	19
15056	MANANTIAL GRANDE	5751	0	19
15057	MARAY	5701	0	19
15058	MARMOL VERDE	5701	0	19
15059	MEDANOS	5736	0	19
15060	MINA SANTO DOMINGO	5701	0	19
15061	MONTE CHIQUITO	5701	0	19
15062	OJO DE AGUA	5701	0	19
15063	11 DE MAYO	5701	0	19
15064	PAMPA DEL TAMBORERO	5701	0	19
15065	PAMPITA	5701	0	19
15066	PANTANILLOS	5701	0	19
15067	PASO DE CUERO	5701	0	19
15068	PASO DE LAS CARRETAS	5736	0	19
15069	PASO DEL REY	5701	0	19
15070	PASO JUAN GOMEZ	5701	0	19
15071	QUEBRADA DE LA BURRA	5701	0	19
15072	QUEBRADA HONDA	5750	0	19
15073	RIO GRANDE	5701	0	19
15074	SALADILLO	5751	0	19
15075	SALADO	5755	0	19
15076	SAN ANTONIO	5750	0	19
15077	SAN GREGORIO	5751	0	19
15078	SAN IGNACIO	5736	0	19
15079	SAN JOSE DE LOS CHA	5701	0	19
15080	SAN MIGUEL	5701	0	19
15082	SANTA ISABEL	5750	0	19
15083	SAUCESITO	5701	0	19
15084	SOLOBASTA	5701	0	19
15085	TOTORAL	5701	0	19
15086	TOTORILLA	5771	0	19
15087	TRAPICHE	5701	0	19
15088	VALLE DE LA PANCANTA	5701	0	19
15089	VALLECITO	5701	0	19
15090	VIRARCO	5701	0	19
15091	VISTA HERMOSA	5730	0	19
15092	YACORO	5750	0	19
15093	ALEGRIA	6389	0	19
15094	ANCHORENA	6389	0	19
15095	ARIZONA	6389	0	19
15096	BAGUAL	6216	0	19
15097	BAJADA NUEVA	6216	0	19
15098	BATAVIA	6279	0	19
15099	BILLIKEN	6216	0	19
15100	BUENA ESPERANZA	6277	0	19
15101	CASIMIRO GOMEZ	6214	0	19
15102	COCHENELOS	6277	0	19
15103	COCHEQUINGAN	6216	0	19
15104	COLONIA CALZADA	6279	0	19
15105	COLONIA EL CAMPAMENTO	6216	0	19
15106	COLONIA LA FLORIDA	6216	0	19
15107	COLONIA URDANIZ	6216	0	19
15108	CORONEL SEGOVIA	6279	0	19
15109	EL AGUILA	6279	0	19
15110	EL CAMPAMENTO	6216	0	19
15111	EL CINCO	6216	0	19
15113	EL MARTILLO	6216	0	19
15114	EL OASIS	6277	0	19
15115	EL PICHE	6279	0	19
15116	EL PORVENIR	6216	0	19
15117	EL QUINGUAL	6277	0	19
15119	EL RODEO	6389	0	19
15120	EL TORO MUERTO	6216	0	19
15121	EL VERANO	6277	0	19
15122	EL YACATAN	6279	0	19
15123	ESTANCIA 30 DE OCTUBRE	6279	0	19
15124	ESTANCIA DON ARTURO	6279	0	19
15125	FORTIN EL PATRIA	6279	0	19
15126	FORTUNA	6216	0	19
15127	FRISIA	6277	0	19
15128	GLORIA A DIOS	6279	0	19
15129	LA ALCORTE	6216	0	19
15130	LA AMALIA	6279	0	19
15131	LA AROMA	6279	0	19
15132	LA AURORA	6216	0	19
15133	LA BAVARIA	6279	0	19
15134	LA BOLIVIA	6279	0	19
15135	LA CALDERA	6216	0	19
15136	LA COLINA	6269	0	19
15137	LA CORA	6279	0	19
15138	LA DONOSTIA	6216	0	19
15139	LA DULCE	6277	0	19
15140	LA ELENA	6216	0	19
15141	LA ELENITA	6216	0	19
15142	LA EMMA	6216	0	19
15143	LA ERNESTINA	6216	0	19
15144	LA ESCONDIDA	6216	0	19
15145	LA ESMERALDA	6277	0	19
15146	LA ESPERANZA	6279	0	19
15147	LA ESTRELLA	6216	0	19
15148	LA ETHEL	6277	0	19
15149	LA FELISA	6279	0	19
15150	LA FLORIDA	6216	0	19
15151	LA GAVIOTA	6216	0	19
15152	LA GERMANIA	6279	0	19
15153	LA GITANA	6216	0	19
15154	LA HOLANDA	6216	0	19
15155	LA HORTENSIA	6279	0	19
15156	LA INVERNADA	6277	0	19
15157	LA ISLA	6279	0	19
15158	LA JOSEFA	6216	0	19
15159	LA JUANA	6279	0	19
15160	LA JUANITA	6216	0	19
15161	LA LAURA	6279	0	19
15162	LA LINDA	6216	0	19
15163	LA LUISA	6279	0	19
15164	LA MARAVILLA	6216	0	19
15165	LA MARGARITA	6216	0	19
15166	LA MARGARITA CARLOTA	6216	0	19
15167	LA MARIA ESTHER	6279	0	19
15168	LA MARIA LUISA	6277	0	19
15169	LA MAROMA	6216	0	19
15170	LA MASCOTA	6216	0	19
15171	LA MEDIA LEGUA	6216	0	19
15172	LA MELINA	6216	0	19
15173	LA NUTRIA	6279	0	19
15174	LA REINA	6279	0	19
15176	LA RESERVA	6279	0	19
15177	LA ROSALIA	6279	0	19
15178	LA ROSINA	6277	0	19
15179	LA SEGUNDA	6277	0	19
15180	LA TIGRA	6216	0	19
15181	LA TRAVESIA	6389	0	19
15182	LA URUGUAYA	6216	0	19
15183	LA VACA	6389	0	19
15184	LA VERDE	6389	0	19
15185	LAS AROMAS	6277	0	19
15186	LAS CORTADERAS	6216	0	19
15187	LAS GITANAS	6216	0	19
15188	LAS LAGUNAS	6216	0	19
15189	LAS MARTINETAS	6216	0	19
15190	LAS MESTIZAS	6277	0	19
15191	LAURA ELISA	6279	0	19
15192	LOS BARRIALES	6216	0	19
15193	LOS CHA	6279	0	19
15194	LOS DOS RIOS	6216	0	19
15195	LOS DURAZNOS	6216	0	19
15196	LOS HUAYCOS	6279	0	19
15197	LOS LOBOS	6216	0	19
15198	LOS OSCUROS	6277	0	19
15199	LOS VALLES	6279	0	19
15200	MACHAO	6277	0	19
15201	MARTIN DE LOYOLA	6279	0	19
15202	MILAGRO	6216	0	19
15203	MONTE COCHEQUINGAN	6216	0	19
15204	NAHUEL MAPA	6279	0	19
15205	NAVIA	6279	0	19
15206	NILINAST	6277	0	19
15207	NUEVA ESPERANZA	6279	0	19
15208	NUEVA GALIA	6216	0	19
15209		6279	0	19
15210	PASO DE LOS GAUCHOS	6216	0	19
15211	PENICE	6279	0	19
15212	PLACILLA	6277	0	19
15213	POLLEDO	6216	0	19
15214	RANQUELCO	6216	0	19
15215	ROSALES	6216	0	19
15216	SAN ANTONIO	6279	0	19
15217	SAN CARLOS	6389	0	19
15218	SAN ISIDRO	6279	0	19
15219	SAN JORGE	6216	0	19
15220	SAN JOSE	6279	0	19
15221	SAN JUAN	6277	0	19
15222	SANTA CECILIA	6279	0	19
15223	SANTA LUCIA	6216	0	19
15224	SANTA MARIA	6279	0	19
15225	SANTA TERESA	6216	0	19
15226	SANTO DOMINGO	6216	0	19
15227	TOINGUA	6216	0	19
15228	TORO BAYO	6279	0	19
15229	UCHAIMA	6279	0	19
15230	UNION	6216	0	19
15231	VALLE HERMOSO	6279	0	19
15232	VIVA LA PATRIA	6279	0	19
15233	AGUA FRIA	5831	0	19
15234	ALFALAND	5731	0	19
15235	ALTO VERDE	5741	0	19
15236	AVANZADA	5738	0	19
15237	AVIADOR ORIGONE	5741	0	19
15238	BOCA DEL RIO	5831	0	19
15239	CALDENADAS	5738	0	19
15240	CENTENARIO	6279	0	19
15241	CERRO BLANCO	5731	0	19
15242	CERRO NEGRO	5731	0	19
15243	CHALANTA	5721	0	19
15244	CHANCARITA	5831	0	19
15245	COLONIA BELLA VISTA	5735	0	19
15246	COLONIA LUNA	5738	0	19
15247	CORONEL ALZOGARAY	5730	0	19
15248	CRAMER	5733	0	19
15249	localidades JARDIN DE SAN LUIS	5730	0	19
15250	EL CARMEN	5738	0	19
15251	EL CHA	5730	0	19
15252	EL DIQUE	5730	0	19
15253	EL FORTIN	5730	0	19
15254	EL MANGRULLO	5738	0	19
15255	EL MORRO	5731	0	19
15256	EL NASAO	5738	0	19
15257	EL PASAJERO	5731	0	19
15258	EL PLATEADO	5731	0	19
15259	EL SARCO	5731	0	19
15260	EL TALITA	5831	0	19
15261	GENERAL PEDERNERA	5738	0	19
15262	GUANACO	5759	0	19
15263	ISONDU	5735	0	19
15264	JUAN JORBA	5731	0	19
15265	JUAN LLERENA	5735	0	19
15266	JUSTO DARACT	5738	0	19
15267	KILOMETRO 656	5738	0	19
15268	LA AGUADA	5831	0	19
15269	LA ANGELINA	5731	0	19
15270	LA BERTITA	5731	0	19
15271	LA CA	5831	0	19
15272	LA CARMEN	5738	0	19
15273	LA ELIDA	5738	0	19
15274	LA EMILIA	5721	0	19
15275	LA GAMA	5731	0	19
15276	LA GARRAPATA	5738	0	19
15277	LA GUARDIA	5759	0	19
15278	LA HERMOSURA	5831	0	19
15279	LA IBERIA	5731	0	19
15280	LA JAVIERA	5731	0	19
15281	LA MAGDALENA	5738	0	19
15282	LA MASCOTA	5738	0	19
15283	LA NEGRA	5730	0	19
15284	LA NEGRITA	5731	0	19
15285	LA PORTADA	5731	0	19
15286	LA ROSADA	5831	0	19
15287	LA TULA	5738	0	19
15288	LA VENECIA	5735	0	19
15289	LAS CAROLINAS	5731	0	19
15290	LAS ENCADENADAS	5738	0	19
15291	LAS MELADAS	5738	0	19
15292	LAS PALMAS	5730	0	19
15293	LAS PRADERAS	5731	0	19
15294	LAS TOTORITAS	5738	0	19
15295	LAVAISSE	5730	0	19
15296	LIBORIO LUNA	5730	0	19
15297	LOS ALAMOS	5831	0	19
15298	LOS CESARES	5738	0	19
15299	LOS CISNES	5731	0	19
15300	LOS ESQUINEROS	5738	0	19
15301	LOS MEDANOS	5738	0	19
15302	LOS POZOS	5738	0	19
15303	MARLITO	5730	0	19
15304	VILLA MERCEDES	5730	0	19
15305	NO ES MIA	5831	0	19
15306	NUEVA ESCOCIA	5743	0	19
15307	PEDERNERA	5730	0	19
15308	POSTA DE FIERRO	5831	0	19
15309	PRIMER AGUA	5831	0	19
15310	PUNILLA	5831	0	19
15311	REAL	5831	0	19
15312	RIO QUINTO	5738	0	19
15313	SAN ALEJANDRO	5831	0	19
15314	SAN JUAN DE TASTU	5731	0	19
15315	SAN NICOLAS PUNILLA	5831	0	19
15316	SAN PEDRO	5831	0	19
15318	SAN RAMON	5730	0	19
15319	SANTA CATALINA	5738	0	19
15320	SANTA CLARA	5730	0	19
15321	SANTA CLARA	5831	0	19
15322	SANTA FELISA	5831	0	19
15323	SANTA ISABEL	5831	0	19
15324	TASTO	5731	0	19
15325	TRES ESQUINAS	5730	0	19
15326	VILLA REYNOLDS	5733	0	19
15327	VISCACHERAS	5731	0	19
15328	ADOLFO RODRIGUEZ SAA	5777	0	19
15329	ANGELITA	5711	0	19
15330	BALDE	5883	0	19
15331	BALDE DE GUI	5715	0	19
15332	BALDE DE NUEVO	5715	0	19
15333	BALDE DEL ESCUDERO	5715	0	19
15334	BA	5711	0	19
15335	BA	5711	0	19
15336	BARRIO BLANCO	5777	0	19
15337	CA	5715	0	19
15338	CA	5771	0	19
15339	CA	5777	0	19
15340	CA	5777	0	19
15341	CA	5881	0	19
15342	CA	5777	0	19
15343	CARPINTERIA	5883	0	19
15344	CERRITO BLANCO	5777	0	19
15345	CERRO DE ORO	5881	0	19
15346	EL BARRIAL	5715	0	19
15347	EL POCITO	5715	0	19
15348	EL PUEBLITO	5777	0	19
15349	EL RINCON	5881	0	19
15350	EL RIO	5711	0	19
15351	EL TEMBLEQUE	5715	0	19
15352	FLORIDA	5715	0	19
15353	INVERNADA	5777	0	19
15354	ISLA	5873	0	19
15355	ISLITAS	5715	0	19
15356	LA AGUADA DE LAS ANIMAS	5871	0	19
15357	LA ALEGRIA	5871	0	19
15358	LA ANGOSTURA	5873	0	19
15359	LA CHILCA	5779	0	19
15361	LA LINEA	5711	0	19
15362	LA LOMA	5871	0	19
15363	LA RAMADA	5881	0	19
15364	LA UNION	5711	0	19
15365	LAFINUR	5871	0	19
15366	LAS BARRANCAS	5871	0	19
15367	LAS CABRAS	5715	0	19
15368	LAS ISLITAS	5715	0	19
15369	LAS PLAYAS	5711	0	19
15370	LAS ROSADAS	5715	0	19
15371	LAS TIGRAS	5777	0	19
15372	LOMITAS	5871	0	19
15373	LOS ALGARROBITOS	5715	0	19
15374	LOS ARGUELLOS	5777	0	19
15375	LOS CAJONES	5871	0	19
15376	LOS CHA	5777	0	19
15377	LOS MOLLES	5711	0	19
15378	LOS PEROS	5777	0	19
15379	LOS ROLDANES	5777	0	19
15380	LOS TIGRES	5777	0	19
15381	MERLO	5881	0	19
15382	MOYAR	5777	0	19
15383	NARANJO	5711	0	19
15384	OJO DEL RIO	5777	0	19
15385	PASO DE LA CRUZ	5777	0	19
15386	PASO DE LAS SIERRAS	5873	0	19
15387	PASO DEL MEDIO	5711	0	19
15388	PICOS YACU	5777	0	19
15389	PIEDRA BLANCA	5881	0	19
15390	PIZARRAS BAJO VELEZ	5777	0	19
15391	POCITOS	5715	0	19
15392	POZO DE LAS RAICES	5777	0	19
15393	POZO DEL MEDIO	5715	0	19
15394	PUNTA DEL AGUA	5873	0	19
15395	PUNTOS DE LA LINEA	5711	0	19
15396	QUEBRADA DEL TIGRE	5711	0	19
15397	RINCON DEL ESTE	5881	0	19
15398	SAN MIGUEL	5883	0	19
15399	SANTA ANA	5871	0	19
15400	SANTA LUCIA	5715	0	19
15401	SANTA LUCINDA	5715	0	19
15402	SANTA ROSA DE CONLARA	5777	0	19
15403	TALITA	5711	0	19
15404	VILLA LUISA	5871	0	19
15405	AGUA SEBALLE	5721	0	19
15406	AGUAS DE PIEDRAS	5721	0	19
15407	ALGARROBITOS	5701	0	19
15408	ALTO GRANDE	5700	0	19
15409	ALTO PELADO	5721	0	19
15410	ALTO PENCOSO	5724	0	19
15411	BALDE	5724	0	19
15412	BARRANCA COLORADA	5703	0	19
15413	EL BARRIAL	5703	0	19
15414	BEAZLEY	5721	0	19
15415	BEBEDERO	5724	0	19
15416	CA	5721	0	19
15417	CERRO VARELA	5721	0	19
15418	CERRO VIEJO	5721	0	19
15419	CHARLONE	5719	0	19
15420	CHISCHACA	5721	0	19
15421	CHICHAQUITA	5721	0	19
15422	CHOSMES	5724	0	19
15423	DANIEL DONOVAN	5701	0	19
15424	EL CAZADOR	5721	0	19
15425	EL CHA	5703	0	19
15426	EL CHARCO	5724	0	19
15427	EL CHORRILLO	5701	0	19
15428	EL LECHUZO	5724	0	19
15429	EL MATACO	5724	0	19
15430	EL MILAGRO	5724	0	19
15431	EL MOLLE	5721	0	19
15432	EL RIECITO	5722	0	19
15433	EL SOCORRO	5721	0	19
15434	EL TALITA	5701	0	19
15435	EL TOTORAL	5721	0	19
15436	EL VOLCAN	5701	0	19
15437	ESTACION ZANJITAS	5721	0	19
15438	GORGONTA	5721	0	19
15439	GUASQUITA	5724	0	19
15440	HUEJEDA	5721	0	19
15441	JARILLA	5724	0	19
15442	JUANA KOSLAY	5701	0	19
15443	LA BONITA	5721	0	19
15444	LA CABRA	5724	0	19
15445	LA CA	5721	0	19
15446	LA IRENE	5721	0	19
15447	LA PAMPA	5701	0	19
15448	LA PEREGRINA	5721	0	19
15449	LA REPRESA	5721	0	19
15450	LA SELVA	5724	0	19
15451	LA SE	5721	0	19
15452	LA TOSCA	5721	0	19
15453	LA UNION	5724	0	19
15454	LA VERDE	5721	0	19
15455	LAGUNA SECA	5724	0	19
15456	LAS BARRANCAS	5719	0	19
15457	LAS COLONIAS	5721	0	19
15458	LAS GAMAS	5721	0	19
15459	LAS LAGUNITAS	5721	0	19
15460	LAS TRES CA	5721	0	19
15461	LAS VIZCACHERAS	5721	0	19
15462	LOS CERRILLOS	5721	0	19
15463	LOS CHA	5721	0	19
15464	LOS JAGUELES	5724	0	19
15465	LOS PUQUIOS	5701	0	19
15466	LOS TAMARI	5724	0	19
15467	MANTILLA	5724	0	19
15468	MOSMOTA	5721	0	19
15469	NEGRO MUERTO	5724	0	19
15470	NOGOLI	5703	0	19
15471	PAJE	5721	0	19
15472	PASO ANCHO	5721	0	19
15473	PASO DE LAS SALINAS	5721	0	19
15474	PASO DE LAS TOSCAS	5721	0	19
15475	PASO DE LAS VACAS	5721	0	19
15476	PASO DE LOS BAYOS	5721	0	19
15477	PASO LOS ALGARROBOS	5724	0	19
15478	POTRERO DE LOS FUNES	5701	0	19
15479	POZO CERCADO	5721	0	19
15480	POZO DEL CARRIL	5703	0	19
15481	PUESTO DE LOS JUMES	5721	0	19
15482	PUNTA DEL CERRO	5721	0	19
15483	REPRESA DEL CHA	5703	0	19
15484	REPRESA DEL MONTE	5700	0	19
15485	SALINAS DEL BEBEDERO	5724	0	19
15486	SALITRAL	5721	0	19
15487	SALTO CHICO	5721	0	19
15488	SAN ANTONIO	5724	0	19
15489	SAN ANTONIO	5721	0	19
15490	SAN GERONIMO	5719	0	19
15491	SAN JORGE	5721	0	19
15492	SAN LUIS	5700	0	19
15493	SAN MARTIN	5721	0	19
15494	SAN RAIMUNDO	5703	0	19
15495	SAN ROQUE	5701	0	19
15496	SAN VICENTE	5721	0	19
15497	SANTA RITA	5724	0	19
15498	SANTA ROSA	5719	0	19
15499	SANTO DOMINGO	5721	0	19
15500	TRAVESIA	5721	0	19
15501	TRES CA	5721	0	19
15502	TUKIROS	5701	0	19
15503	VARELA	5721	0	19
15504	AGUA LINDA	5753	0	19
15505	ALANICES	5771	0	19
15506	ALTO DEL MOLLE	5755	0	19
15507	ALTO DEL VALLE	5755	0	19
15508	ANCAMILLA	5753	0	19
15509	ARBOLES BLANCOS	5771	0	19
15510	ARROYO DE VILCHES	5771	0	19
15511	ARROYO LA CAL	5753	0	19
15512	BAJO DE CONLARA	5753	0	19
15513	BAJO LA LAGUNA	5753	0	19
15514	BARRANQUITAS	5771	0	19
15515	CABEZA DE NOVILLO	5771	0	19
15516	CAIN DE LOS TIGRES	5771	0	19
15517	CA	5773	0	19
15518	CA	5753	0	19
15519	CA	5773	0	19
15520	CA	5771	0	19
15521	CA	5753	0	19
15522	CA	5753	0	19
15523	CA	5753	0	19
15524	CA	5755	0	19
15525	CA	5773	0	19
15526	CASA DE CONDOR	5753	0	19
15527	CASA DE PIEDRA	5753	0	19
15528	CERRITO	5753	0	19
15529	CERRITO NEGRO	5755	0	19
15530	CERRO COLORADO	5753	0	19
15531	CHACRITAS	5753	0	19
15532	CHUTUNSA	5753	0	19
15533	CONSUELO	5753	0	19
15534	CORRAL DEL TALA	5753	0	19
15535	CORRALES	5753	0	19
15536	CORTADERAS	5771	0	19
15537	CRUCECITAS	5773	0	19
15538	CRUZ BRILLANTE	5753	0	19
15539	CUEVA DE TIGRE	5755	0	19
15540	DIVISADERO	5753	0	19
15541	DORMIDA	5753	0	19
15542	DURAZNITO	5773	0	19
15543	EL BAJO	5755	0	19
15544	EL BALDECITO	5753	0	19
15545	EL BURRITO	5753	0	19
15546	EL CARDAL	5753	0	19
15547	EL CERRITO	5753	0	19
15548	EL CONDOR	5753	0	19
15549	EL CORO	5753	0	19
15550	EL MANANTIAL ESCONDIDO	5701	0	19
15551	EL OLMO	5773	0	19
15552	EL PAJARETE	5753	0	19
15553	EL PANTANILLO	5753	0	19
15554	EL PARAGUAY	5753	0	19
15555	EL PARAISO	5755	0	19
15556	EL PEJE	5755	0	19
15557	EL POLEO	5773	0	19
15558	EL PORVENIR	5773	0	19
15559	EL PROGRESO	5753	0	19
15560	EL PUERTO	5753	0	19
15561	EL PUESTO	5755	0	19
15562	EL RODEO	5771	0	19
15563	EL SALADO	5753	0	19
15564	EL SALVADOR	5771	0	19
15565	EL TALITA	5753	0	19
15566	EL TORCIDO	5773	0	19
15567	EL VALLE	5753	0	19
15568	EL VALLECITO	5773	0	19
15569	ENSENADA	5773	0	19
15570	FORTUNA DE SAN JUAN	5755	0	19
15571	GENERAL URQUIZA	5763	0	19
15572	GUANACO PAMPA	5771	0	19
15573	GUZMAN	5773	0	19
15574	HINOJOS	5753	0	19
15575	HORNITO	5753	0	19
15576	HUERTAS	5771	0	19
15577	LA AGUEDA	5753	0	19
15578	LA ARMONIA	5773	0	19
15579	LA AURORA	5771	0	19
15580	LA CARMENCITA	5753	0	19
15581	LA CHILLA	5771	0	19
15582	LA CIENAGA	5701	0	19
15583	LA COCHA	5773	0	19
15584	LA DORA	5753	0	19
15585	LA ELVIRA	5770	0	19
15586	LA ESPERANZA	5753	0	19
15587	LA ESQUINA	5753	0	19
15588	LA ESQUINA DEL RIO	5753	0	19
15589	LA ESTANCIA	5753	0	19
15590	LA FLORIDA	5773	0	19
15591	LA HUERTA	5753	0	19
15592	LA HUERTITA	5755	0	19
15593	LA PUERTA	5755	0	19
15594	LA RAMADA	5753	0	19
15595	LA SALA	5771	0	19
15596	LA TOTORA	5753	0	19
15597	LA ULBARA	5753	0	19
15598	LAS VERTIENTES	5701	0	19
15599	LAGUNA DE LA CA	5773	0	19
15600	LAGUNA DE LOS PATOS	5773	0	19
15601	LAGUNA LARGA	5753	0	19
15602	LAS AGUADAS	5771	0	19
15603	LAS BARRANQUITAS	5755	0	19
15604	LAS CA	5773	0	19
15605	LAS CHACRAS	5753	0	19
15606	LAS CHACRAS DE SAN MARTIN	5755	0	19
15607	LAS CHACRITAS	5753	0	19
15608	LAS FLORES	5753	0	19
15609	LAS HIGUERAS	5755	0	19
15610	LAS LAGUNAS	5773	0	19
15611	LAS LAJAS	5753	0	19
15612	LAS LOMAS	5753	0	19
15613	LAS MANGAS	5753	0	19
15614	LAS TOSCAS	5753	0	19
15615	LOS ALAMOS	5753	0	19
15616	LOS ALGARROBOS	5753	0	19
15617	LOS COMEDEROS	5753	0	19
15618	LOS CONDORES	5773	0	19
15619	LOS CORRALES	5753	0	19
15620	LOS DURAZNITOS	5773	0	19
15621	LOS HINOJOS	5753	0	19
15622	LOS LECHUZONES	5753	0	19
15623	LOS LOBOS	5771	0	19
15624	LOS MOLLES	5753	0	19
15625	LOS NOQUES	5773	0	19
15626	LOS POLEOS	5755	0	19
15627	LOS TALAS	5753	0	19
15628	MANANTIAL	5755	0	19
15629	MANANTIAL BLANCO	5701	0	19
15630	MANANTIAL LINDO	5753	0	19
15631	MEDIA LUNA	5755	0	19
15632	OJO DE AGUA	5753	0	19
15633	PAMPA	5755	0	19
15634	PAMPA DEL BAJO	5753	0	19
15635	PAMPA GRANDE	5771	0	19
15636	PANTANILLO	5753	0	19
15637	PASO GRANDE	5753	0	19
15638	PIEDRA BOLA	5753	0	19
15639	PIEDRA LARGA	5753	0	19
15640	PIEDRA ROSADA	5753	0	19
15641	PIEDRA SOLA	5753	0	19
15642	PLANTA DE SANDIA	5753	0	19
15643	POTRERILLO	5753	0	19
15644	POZO SECO	5753	0	19
15645	PUERTA COLORADA	5771	0	19
15646	PUERTA DE PALO	5755	0	19
15647	PUESTITO	5753	0	19
15648	QUEBRADA DE LA MORA	5755	0	19
15649	QUEBRADA DE LOS BARROSOS	5753	0	19
15650	QUEBRADA DE SAN VICENTE	5755	0	19
15651	RINCON DEL CARMEN	5771	0	19
15652	SALADO DE AMAYA	5771	0	19
15653	SAN FERNANDO	5753	0	19
15654	SAN ISIDRO	5753	0	19
15655	SAN ISIDRO	5771	0	19
15656	SAN JOSE	5753	0	19
15657	SAN LORENZO	5753	0	19
15658	SAN MARTIN	5755	0	19
15659	SAN MIGUEL	5753	0	19
15660	SAN PEDRO	5753	0	19
15661	SAN RAFAEL	5753	0	19
15662	SAN RAMON	5753	0	19
15664	SAUCE	5753	0	19
15665	SOL DE ABRIL SAN MARTIN	5701	0	19
15666	TALA VERDE	5771	0	19
15667	TALARCITO	5701	0	19
15668	TOTORAL	5771	0	19
15669	UNQUILLO	5771	0	19
15670	VENTA DE LOS RIOS	5753	0	19
15671	VILLA DE PRAGA	5753	0	19
15672	CASTRO BARROS	5276	0	12
15701	COPAHUE	8349	0	15
15702	SAN EUGENIO	2253	0	21
15703	ALGARROBO VERDE	5443	0	18
15704	CUATRO ESQUINAS	5443	0	18
15705	CUYO	5443	0	18
15706	EL RINCON	5443	0	18
15707	ENCON	5421	0	18
15708	JOSE MARTI	5443	0	18
15709	KILOMETRO 910	5443	0	18
15710	KILOMETRO 936	5443	0	18
15711	LAS CASUARINAS	5443	0	18
15712	LOS CORREDORES	5443	0	18
15713	PUNTA DEL MEDANO	5443	0	18
15714	SAN ANTONIO	5443	0	18
15715	SANTA MARIA DEL ROSARIO	5443	0	18
15716	TUPELI	5443	0	18
15717	VILLA BORJAS	5443	0	18
15718	VILLA SANTA ROSA	5443	0	18
15719	9 DE JULIO	5417	0	18
15720	COLONIA GUTIERREZ	5438	0	18
15721	FINCA ZAPATA	5417	0	18
15722	LA MAJADITA	5417	0	18
15723	CHACRITAS	5417	0	18
15724	TIERRA ADENTRO	5417	0	18
15725	USINA	5438	0	18
15726	BA	5419	0	18
15727	CAMPO AFUERA	5419	0	18
15728	DOS PUENTES	5419	0	18
15729	EL SALADO	5419	0	18
15730	LA CA	5419	0	18
15731	LA LAJA	5419	0	18
15732	LAS LOMITAS	5419	0	18
15733	LAS PIEDRITAS	5419	0	18
15734	LOS PUESTOS	5419	0	18
15735	TERMA LA LAJA	5419	0	18
15736	VILLA GENERAL SAN MARTIN	5419	0	18
15737	EL ALAMITO	5415	0	18
15738	ANGACO NORTE	5415	0	18
15739	CALLE AGUILERAS	5415	0	18
15740	CALLE NACIONAL	5415	0	18
15741	DOMINGO DE ORO	5415	0	18
15742	LAS TAPIAS	5415	0	18
15743	PAQUITA	5415	0	18
15744	PICHAGUAL	5415	0	18
15745	PLUMERILLO	5415	0	18
15746	VILLA DEL SALVADOR	5415	0	18
15747	VILLA GENERAL ACHA	5415	0	18
15748	BARREAL	5405	0	18
15749	BELLA VISTA	5403	0	18
15750	CABECERA DEL BARRIAL	5403	0	18
15751	CALINGASTA	5403	0	18
15752	CASTA	5403	0	18
15753	COLON	5401	0	18
15754	HILARIO	5401	0	18
15755	MINA SAN JORGE	5403	0	18
15756	RUTA 20 KILOMETRO 114	5401	0	18
15757	TAMBERIAS	5401	0	18
15758	DESAMPARADOS	5400	0	18
15759	DIAZ VELEZ	5400	0	18
15760	PRESBITERO FCO PEREZ HERNADEZ	5400	0	18
15761	SAN JUAN	5400	0	18
15762	TRINIDAD	5400	0	18
15763	VILLA CAROLINA	5400	0	18
15764	VILLA HUASIHUL	5400	0	18
15765	VILLA MARINI	5400	0	18
15766	VILLA SAN ISIDRO	5415	0	18
15767	AMBAS PUNTILLAS	5442	0	18
15768	AMPACAMA	5444	0	18
15769	BALDE DE LEYES	5446	0	18
15770	BERMEJO	5444	0	18
15771	CAUCETE	5442	0	18
15772	DIFUNTA CORREA	5443	0	18
15773	EL CHUPINO	5446	0	18
15774	FINCA DE IZASA	5442	0	18
15775	GUAYAMAS	5444	0	18
15776	KILOMETRO 893	5444	0	18
15777	KILOMETRO 895	5442	0	18
15778	LA PUNTILLA	5442	0	18
15779	LAGUNA SECA	5444	0	18
15780	LAS CHACRAS	5446	0	18
15781	LAS SALINAS	5446	0	18
15782	LOS MEDANOS	5443	0	18
15783	LOS PAPAGAYOS	5446	0	18
15784	LOTES ESCUELA 138	5442	0	18
15785	LOTES DE ALVAREZ	5442	0	18
15786	LOTES DE CORIA	5442	0	18
15787	LOTES DE URIBURU	5442	0	18
15788	LOTES RIVERA	5442	0	18
15789	MARAYES	5446	0	18
15790	NIKISANGA	5444	0	18
15791	NUEVA CASTILLA	5444	0	18
15792	POZO DE LOS ALGARROBOS	5443	0	18
15793	POZO SALADO	5442	0	18
15794	PUNTILLA	5443	0	18
15795	PUNTILLA BLANCA	5443	0	18
15796	RINCON	5442	0	18
15797	SAN CARLOS	5446	0	18
15798	URIBURU	5442	0	18
15799	VALLECITO	5443	0	18
15800	VILLA COLON	5442	0	18
15801	VILLA INDEPENDENCIA	5443	0	18
15802	CHIMBAS	5413	0	18
15803	LAS CHIMBAS	5436	0	18
15804	VILLA JUAN XXIII	5413	0	18
15805	VILLA MORRONES	5413	0	18
15806	VILLA SANTA PAULA	5413	0	18
15807	BA	5467	0	18
15808	BA	5465	0	18
15809	BELLA VISTA	5467	0	18
15810	BUENA ESPERANZA	5467	0	18
15811	CAMPANARIO NUEVO	5467	0	18
15812	CA	5467	0	18
15813	CERRO NEGRO	5465	0	18
15814	CHISNASCO	5467	0	18
15815	COLANGUIL	5467	0	18
15816	COLOLA	5465	0	18
15817	EL CARRIZAL	5467	0	18
15818	EL CHINGUILLO	5467	0	18
15819	GUA	5465	0	18
15820	IGLESIA	5467	0	18
15821	LA CHIGUA	5467	0	18
15822	LA MARAL	5465	0	18
15823	LA MORAL	5465	0	18
15824	LAS FLORES	5467	0	18
15825	LOS QUILLAY	5417	0	18
15826	MACLACASTO	5467	0	18
15827	MALIMAN	5467	0	18
15828	MANANTIALES	5467	0	18
15829	RODEO	5465	0	18
15830	TERMA PISMANTA	5467	0	18
15831	TOTORALITO	5465	0	18
15832	TUDCUM	5467	0	18
15833	ADAN QUIROGA	5409	0	18
15834	AGUA DE LOS CABALLOS	5460	0	18
15835	AGUADA DE LA PE	5461	0	18
15837	AGUADITAS DEL RIO JACHAL	5461	0	18
15838	AGUAS DEL PAJARO	5461	0	18
15839	ALCAUCHA	5461	0	18
15840	ALTO HUACO	5463	0	18
15841	BELLA VISTA	5460	0	18
15842	CERRO NEGRO	5460	0	18
15843	COLANQUI	5460	0	18
15844	COYON	5409	0	18
15845	CRUZ DE PIEDRA	5460	0	18
15846	CUMIYANGO	5409	0	18
15847	EL BALDE	5409	0	18
15848	EL BUEN RETIRO	5461	0	18
15849	EL FICAL	5461	0	18
15850	EL FUERTE	5409	0	18
15851	EL VOLCAN	5409	0	18
15852	ENTRE RIOS	5461	0	18
15853	FINCA EL MOLINO	5460	0	18
15854	GRAN CHINA	5461	0	18
15855	GUAJA	5461	0	18
15856	HUACO	5463	0	18
15857	HUERTA DE GUACHI	5461	0	18
15858	INGENIERO MATIAS G SANCHEZ	5409	0	18
15859	LA CHILCA	5460	0	18
15860	LA FALDA	5461	0	18
15861	LA OVERA	5460	0	18
15862	LAS AGUADITAS	5409	0	18
15863	LOS DIAGUITAS	5409	0	18
15864	LOS HORNOS	5460	0	18
15865	LOS QUIMBALETES	5461	0	18
15866	LOS RANCHOS	5460	0	18
15867	NIQUIVIL	5409	0	18
15868	NIQUIVIL VIEJO	5409	0	18
15869	OTRA BANDA	5460	0	18
15870	PAMPA DEL CHA	5461	0	18
15871	PAMPA VIEJA	5461	0	18
15872	PANACAN	5461	0	18
15873	PASO DEL LAMAR	5463	0	18
15874	PIMPA	5461	0	18
15875	PUNTA DE AGUA	5463	0	18
15876	RINCON	5460	0	18
15877	RIO PALO	5460	0	18
15878	SAN ROQUE	5409	0	18
15879	SANTA BARBARA	5409	0	18
15880	SIERRA BILLICUM	5460	0	18
15881	TAMBERIAS	5461	0	18
15882	TRANCAS	5460	0	18
15883	TUCUNUCO	5409	0	18
15884	VILLA	5460	0	18
15885	VILLA MERCEDES	5461	0	18
15886	VOLCAN	5460	0	18
15887	BARRIO SANTA BARBARA	5427	0	18
15888	CARPINTERIA	5435	0	18
15889	CENTRO AVIACION CIVIL SAN JUAN	5427	0	18
15890	COLONIA ROCA	5427	0	18
15891	COLONIA RODAS	5421	0	18
15892	COLONIA RODRIGUEZ ZAVALLA	5425	0	18
15893	CONTEGRAND	5421	0	18
15894	EL ABANICO	5429	0	18
15895	ESTACION LA RINCONADA	5433	0	18
15896	JUAN CELANI	5427	0	18
15897	LA CALLECITA	5421	0	18
15898	LA COSECHERA	5427	0	18
15899	POCITO	5429	0	18
15900	QUINTO CUARTEL	5427	0	18
15901	QUIROGA	5435	0	18
15902	RINCONADA	5429	0	18
15903	SANCHEZ DE LORIA	5427	0	18
15904	VILLA ABERASTAIN	5427	0	18
15905	VILLA BARBOZA	5427	0	18
15906	VILLA NACUSI	5427	0	18
15907	ALBARRACIN	5425	0	18
15908	BARRIO OBRERO RAWSON	5425	0	18
15909	CAPITAN LAZO	5423	0	18
15910	COLONIA CENTENARIO	5421	0	18
15911	COLONIA EL MOLINO	5425	0	18
15912	COLONIA FLORIDA	5425	0	18
15913	COLONIA JUAN SOLARI	5425	0	18
15914	COLONIA YORNER	5425	0	18
15915	COLONIA ZAPATA	5436	0	18
15916	COLONIA RODRIGUEZ ZAVALLA	5425	0	18
15917	EL MEDANITO	5400	0	18
15918	EL MOLINO	5425	0	18
15919	GERMANIA	5425	0	18
15920	LA FLORIDA	5425	0	18
15921	LA ORILLA	5425	0	18
15922	LLOVERAS	5425	0	18
15923	MEDANO DE ORO	5421	0	18
15924	PRIMER CUARTEL	5425	0	18
15925	SANTA CLARA	5425	0	18
15926	SEGUNDO CUARTEL	5425	0	18
15927	VILLA FLEURY	5425	0	18
15928	VILLA FRANCA	5425	0	18
15929	VILLA KRAUSE	5425	0	18
15930	VILLA LAPRIDA	5425	0	18
15931	VILLA LERGA	5424	0	18
15932	VILLA RACHEL	5425	0	18
15933	ZAVALLA	5425	0	18
15934	DIQUE TOMA	5407	0	18
15935	RIO SASO	5407	0	18
15936	RIVADAVIA	5400	0	18
15937	VILLA OBRERA	5407	0	18
15938	BELGRANO	5439	0	18
15939	CALIBAR	5442	0	18
15940	CALLE LARGA	5439	0	18
15941	CALLECITA	5439	0	18
15942	DOS ACEQUIAS	5439	0	18
15943	KILOMETRO 905	5439	0	18
15944	LA GERMANIA	5439	0	18
15945	LA PUNTILLA	5439	0	18
15946	LOS ANGACOS	5439	0	18
15947	PUNTILLA BLANCA	5439	0	18
15948	PUNTILLA NEGRA	5439	0	18
15949	SAN ISIDRO	5439	0	18
15950	SAN MARTIN	5439	0	18
15951	VILLA ALEM	5439	0	18
15952	VILLA LUGANO	5439	0	18
15953	ALTO DE SIERRA	5438	0	18
15954	COLL	5438	0	18
15955	COLONIA RICHET	5438	0	18
15956	LOS COMPARTOS	5439	0	18
15957	LOS VI	5438	0	18
15958	LUZ DEL MUNDO	5411	0	18
15959	PAJAS BLANCAS	5411	0	18
15960	PEDRO ECHAGUE	5436	0	18
15961	PUENTE NACIONAL	5438	0	18
15962	PUENTE RIO SAN JUAN	5438	0	18
15963	PUENTE RUFINO	5438	0	18
15964	SANTA LUCIA	5411	0	18
15965	ALGARROBO GRANDE	5435	0	18
15966	AZUCARERA DE CUYO	5435	0	18
15967	COCHAGUAL	5435	0	18
15968	COLONIA FIORITO	5435	0	18
15969	COLONIA FISCAL SARMIENTO	5435	0	18
15970	COLONIA SAN ANTONIO	5435	0	18
15971	DIVISADERO	5431	0	18
15972	GUANACACHE	5431	0	18
15973	LA CIENEGUITA	5435	0	18
15974	LAGUNA DEL ROSARIO	5435	0	18
15975	LAS LAGUNAS	5435	0	18
15976	LOS BERROS	5431	0	18
15977	LOS CHA	5435	0	18
15978	LOS SOMBREROS	5431	0	18
15979	LOTE ALVARADO	5435	0	18
15980	MEDIA AGUA	5435	0	18
15981	PEDERNAL	5431	0	18
15982	PUNTA DE LAGUNA	5435	0	18
15983	RAMBLON	5435	0	18
15984	RETAMITO	5435	0	18
15985	SAN CARLOS	5435	0	18
15986	TRES ESQUINAS	5435	0	18
15987	BARRIO GRAFFIGNA	5409	0	18
15988	BODEGA GRAFFIGNA	5409	0	18
15989	MATAGUSANOS	5419	0	18
15990	TALACASTO	5400	0	18
15991	ULLUM	5409	0	18
15992	AGUA ESCONDIDA	5447	0	18
15993	AGUANGO	5449	0	18
15994	BALDE DEL NORTE	5449	0	18
15995	BALDE DEL ROSARIO	5449	0	18
15996	BALDECITO	5449	0	18
15997	BALDECITO DEL MORADO	5449	0	18
15998	BALDES DE LA CHILCA	5449	0	18
15999	BALDES DEL SUD	5449	0	18
16000	BALDES DEL TARABAY	5447	0	18
16001	BARREALITO	5447	0	18
16002	CABEZA DEL TORO	5449	0	18
16003	CUCHILLAZO	5447	0	18
16004	CHA	5449	0	18
16005	EL GIGANTILLO	5447	0	18
16006	EL PUERTO	5449	0	18
16007	LA CIENEGUITA	5449	0	18
16008	LA COLONIA	5449	0	18
16009	LA HUERTA	5447	0	18
16010	LA MESADA	5447	0	18
16011	LA RAMADA	5449	0	18
16012	LAS DELICIAS	5447	0	18
16013	LAS HIGUERITAS	5449	0	18
16014	LAS TUMANAS	5447	0	18
16015	LOMA NEGRA	5449	0	18
16016	LOMAS BLANCAS	5449	0	18
16017	LOS BALDECITOS	5449	0	18
16018	LOS BALDES	5447	0	18
16019	LOS BALDES DE ASTICA	5447	0	18
16020	LOS BARRIALES	5449	0	18
16021	LOS CHAVES	5449	0	18
16022	LOS MOLLES	5449	0	18
16023	LOS RINCONES	5449	0	18
16024	MEDANO COLORADO	5449	0	18
16025	PAPAGAYOS	5449	0	18
16026	RINCONES	5449	0	18
16027	SAN ANTONIO	5449	0	18
16028	SAN JUAN BAUTISTA USNO	5449	0	18
16029	SIERRA DE CHAVEZ	5449	0	18
16030	SIERRA DE ELIZONDO	5447	0	18
16031	SIERRA DE RIVERO	5449	0	18
16032	TUMANAS	5447	0	18
16033	USNO	5449	0	18
16034	VILLA CARLOTA	5449	0	18
16035	YOCA	5449	0	18
16036	ANGUALASTO	5467	0	18
16037	EMBALSE	5856	0	6
16038	LA CRUZ	5859	0	6
16039	LOS CONDORES	5823	0	6
16040	LOS MOLINOS	5189	0	6
16041	RIO DE LOS SAUCES	5821	0	6
16042	SAN AGUSTIN	5191	0	6
16043	SANTA ROSA DE CALAMUCHITA	5196	0	6
16044	UNIDAD TURISTICA EMBALSE	5857	0	6
16045	VILLA DEL DIQUE	5862	0	6
16046	VILLA GENERAL BELGRANO	5194	0	6
16047	VILLA RUMIPAL	5864	0	6
16049	VILLA YACANTO	5197	0	6
16051	SALDAN	5149	0	6
16052	TOLEDO	5123	0	6
16054	AGUA DE ORO	5107	0	6
16055	CABANA	5109	0	6
16056	CANTERAS EL SAUCE	5107	0	6
16057	COLONIA CAROYA	5223	0	6
16058	DUMESNIL	5149	0	6
16059	EL DIQUECITO	5151	0	6
16060	EL MANZANO	5107	0	6
16061	EL PUEBLITO	5107	0	6
16062	JESUS MARIA	5220	0	6
16063	LA CALERA	5151	0	6
16064	LA GRANJA	5115	0	6
16065	LA PUERTA	5101	0	6
16066	MALVINAS ARGENTINAS	5125	0	6
16067	MENDIOLAZA	5107	0	6
16068	MI GRANJA	5125	0	6
16069	RIO CEBALLOS	5111	0	6
16070	SALSIPUEDES	5113	0	6
16071	UNQUILLO	5109	0	6
16072	VILLA ALLENDE	5105	0	6
16073	VILLA CERRO AZUL	5107	0	6
16074	CRUZ DEL EJE	5280	0	6
16075	EL BRETE	5281	0	6
16076	LA HIGUERA	5285	0	6
16077	LA LAGUNA	5284	0	6
16078	PASO VIEJO	5284	0	6
16079	SAN MARCOS SIERRAS	5282	0	6
16080	SERREZUELA	5270	0	6
16081	VILLA DE SOTO	5284	0	6
16082	DEL CAMPILLO	6271	0	6
16083	HIPOLITO BOUCHARD	6225	0	6
16084	HUINCA RENANCO	6270	0	6
16085	ITALO	6271	0	6
16086	MATTALDI	6271	0	6
16087	NICOLAS BRUZONE	6271	0	6
16088	JOVITA	6127	0	6
16089	VILLA HUIDOBRO	6275	0	6
16090	VILLA VALERIA	6273	0	6
16091	ARROYO ALGODON	5909	0	6
16092	ARROYO CABRAL	5917	0	6
16093	AUSONIA	5901	0	6
16094	CHAZON	2675	0	6
16095	COLONIA SILVIO PELLICO	5907	0	6
16096	ETRURIA	2681	0	6
16097	LA LAGUNA	5901	0	6
16098	LA PALESTINA	5925	0	6
16099	LA PLAYOSA	5911	0	6
16100	LOS ZORROS	5901	0	6
16101	LUCA	5917	0	6
16102	PASCO	5925	0	6
16103	TICINO	5927	0	6
16104	TIO PUJIO	5936	0	6
16106	VILLA NUEVA	5903	0	6
16107	CHU	5218	0	6
16108	DEAN FUNES	5200	0	6
16109	MOGNA	5409	0	18
16110	QUILINO	5214	0	6
16112	VILLA QUILINO	5214	0	6
16113	ALEJANDRO ROCA	2686	0	6
16114	BENGOLEA	5807	0	6
16115	CARNERILLO	5805	0	6
16116	CHARRAS	5807	0	6
16117	GENERAL CABRERA	5809	0	6
16118	GENERAL DEHEZA	5923	0	6
16119	HUANCHILLA	6121	0	6
16120	LA CARLOTA	2670	0	6
16121	OLAETA	5807	0	6
16122	REDUCCION	5803	0	6
16123	SANTA EUFEMIA	2671	0	6
16124	UCACHA	2677	0	6
16125	CHUCUMA	5447	0	18
16126	ALEJO LEDESMA	2662	0	6
16127	ARIAS	2624	0	6
16128	CAMILO ALDAO	2585	0	6
16129	CAP GRAL BERNARDO O HIGGINS	2645	0	6
16130	CAVANAGH	2625	0	6
16131	COLONIA ITALIANA	2645	0	6
16132	CORRAL DE BUSTOS	2645	0	6
16133	CRUZ ALTA	2189	0	6
16134	GENERAL BALDISSERA	2583	0	6
16135	GENERAL ROCA	2592	0	6
16136	GUATIMOZIN	2627	0	6
16137	INRIVILLE	2587	0	6
16138	ISLA VERDE	2661	0	6
16139	LEONES	2594	0	6
16140	LOS SURGENTES	2581	0	6
16141	MARCOS JUAREZ	2580	0	6
16142	MONTE BUEY	2589	0	6
16143	SAIRA	2525	0	6
16144	SALADILLO	2587	0	6
16145	SAN CARLOS	5291	0	6
16146	SALSACATE	5295	0	6
16147	GENERAL LEVALLE	6132	0	6
16148	LA CESIRA	6101	0	6
16149	LABOULAYE	6120	0	6
16150	MELO	6123	0	6
16151	RIO BAMBA	6134	0	6
16152	ROSALES	6128	0	6
16153	SERRANO	6125	0	6
16154	VILLA ROSSI	6128	0	6
16155	BIALET MASSE	5158	0	6
16156	CABALANGO	5155	0	6
16157	CAPILLA DEL MONTE	5184	0	6
16158	CASA GRANDE	5162	0	6
16159	COSQUIN	5166	0	6
16160	CRUZ CHICA	5178	0	6
16161	CUESTA BLANCA	5153	0	6
16162	HUERTA GRANDE	5174	0	6
16163	YCHO CRUZ SIERRAS	5153	0	6
16164	LA CUMBRE	5178	0	6
16165	LA FALDA	5172	0	6
16166	LOS COCOS	5182	0	6
16167	SAN ANTONIO DE ARREDONDO	5153	0	6
16168	SAN ESTEBAN	5182	0	6
16169	SANTA MARIA DE PUNILLA	5164	0	6
16170	SOLARES DE YCHO CRUZ	5153	0	6
16171	TALA HUASI	5153	0	6
16172	TANTI	5155	0	6
16173	VALLE HERMOSO	5168	0	6
16174	VILLA CARLOS PAZ	5152	0	6
16175	VILLA GIARDINO	5176	0	6
16176	VILLA PARQUE SIQUIMAN	5152	0	6
16177	VILLA RIO YCHO CRUZ	5153	0	6
16178	ACHIRAS	5833	0	6
16179	ADELIA MARIA	5843	0	6
16180	ALCIRA ESTACION GIGENA	5813	0	6
16181	BERROTARAN	5817	0	6
16182	BULNES	5845	0	6
16183	CHAJAN	5837	0	6
16184	CORONEL BAIGORRIA	5811	0	6
16185	CORONEL MOLDES	5847	0	6
16186	ELENA	5815	0	6
16187	LA CAUTIVA	6142	0	6
16188	LAS ACEQUIAS	5848	0	6
16189	LAS HIGUERAS	5805	0	6
16190	LAS VERTIENTES	5839	0	6
16191	MONTE DE LOS GAUCHOS	5831	0	6
16193	SAMPACHO	5829	0	6
16194	SAN BASILIO	5841	0	6
16195	SANTA CATALINA	5825	0	6
16196	TOSQUITA	6141	0	6
16197	VICU	6140	0	6
16198	WASHINGTON	6144	0	6
16199	CAPILLA DE LOS REMEDIOS	5101	0	6
16200	COLONIA EL FORTIN	5133	0	6
16201	COMECHINGONES	5129	0	6
16202	DIEGO DE ROJAS	5135	0	6
16203	ESQUINA	5131	0	6
16204	LA PARA	5137	0	6
16205	LA PUERTA	5137	0	6
16206	LAS AVERIAS	5135	0	6
16207	LAS SALADAS	5137	0	6
16208	MONTE CRISTO	5125	0	6
16209	OBISPO TREJO	5225	0	6
16210	PIQUILLIN	5125	0	6
16211	RIO PRIMERO	5127	0	6
16212	SANTA ROSA DE RIO PRIMERO	5133	0	6
16213	VILLA FONTANA	5137	0	6
16214	GUTEMBERG	5249	0	6
16215	SEBASTIAN ELCANO	5231	0	6
16216	VILLA DE MARIA	5248	0	6
16217	CALCHIN	5969	0	6
16218	CALCHIN OESTE	5965	0	6
16219	CARRILOBO	5915	0	6
16220	COLAZO	5965	0	6
16221	COSTA SACATE	5961	0	6
16222	LAGUNA LARGA	5974	0	6
16223	LAS JUNTURAS	5965	0	6
16224	LUQUE	5967	0	6
16225	MANFREDI	5988	0	6
16226	MATORRALES	5965	0	6
16227	ONCATIVO	5986	0	6
16228	PILAR	5972	0	6
16229	POZO DEL MOLLE	5913	0	6
16230	RIO SEGUNDO	5960	0	6
16231	SANTIAGO TEMPLE	5125	0	6
16232	VILLA DEL ROSARIO	5963	0	6
16233	MINA CLAVERO	5889	0	6
16234	NONO	5887	0	6
16235	VILLA SARMIENTO	5871	0	6
16236	SAN PEDRO	5871	0	6
16237	VILLA PALERMO	5400	0	18
16238	VILLA CURA BROCHERO	5891	0	6
16239	CRUZ DE CA	5875	0	6
16240	LA PAZ	5879	0	6
16241	LA RAMADA	5875	0	6
16242	LAS CHACRAS	5875	0	6
16243	LAS TAPIAS	5885	0	6
16244	LOS CERRILLOS	5871	0	6
16245	LOS HORNILLOS	5885	0	6
16246	LUYABA	5875	0	6
16247	PIEDRA PINTADA	5871	0	6
16248	QUEBRACHO LADEADO	5875	0	6
16249	SAN JOSE	5871	0	6
16250	VILLA DE LAS ROSAS	5885	0	6
16251	VILLA DOLORES	5870	0	6
16252	YACANTO	5877	0	6
16253	ALICIA	5949	0	6
16254	ALTOS DE CHIPION	2417	0	6
16255	ARROYITO	2434	0	6
16256	BALNEARIA	5141	0	6
16257	BRINKMANN	2419	0	6
16258	COLONIA MARINA	2424	0	6
16259	COLONIA PROSPERIDAD	2423	0	6
16260	COLONIA SAN BARTOLOME	2426	0	6
16261	COLONIA VALTELINA	2413	0	6
16262	COLONIA VIGNAUD	2419	0	6
16263	DEVOTO	2424	0	6
16264	EL ARA	5947	0	6
16265	EL FORTIN	5951	0	6
16266	PARAJE BEBIDA	5407	0	18
16267	EL TIO	2432	0	6
16268	FREYRE	2413	0	6
16269	VILLA DEL CARMEN	5400	0	18
16270	LA LEGUA	5411	0	18
16271	JACHAL	5460	0	18
16272	CA	5431	0	18
16273	CAMPO DE BATALLA	5435	0	18
16274	ALTA GRACIA	5186	0	6
16275	BOUWER	5119	0	6
16276	ANISACATE	5189	0	6
16277	DESPE	5121	0	6
16278	LA SERRANITA	5189	0	6
16279	LOZADA	5101	0	6
16280	MALAGUE	5101	0	6
16281	MONTE RALO	5119	0	6
16282	RAFAEL GARCIA	5119	0	6
16283	SAN CLEMENTE	5187	0	6
16284	SAN NICOLAS	5187	0	6
16285	VILLA PARQUE SANTA ANA	5101	0	6
16286	VILLA ANISACATE	5189	0	6
16287	VILLA EL DESCANSO	5189	0	6
16288	VILLA LA BOLSA	5189	0	6
16289	YOCSINA	5101	0	6
16290	CAMINIAGA	5244	0	6
16291	SAN FRANCISCO DEL CHA	5209	0	6
16292	ALMAFUERTE	5854	0	6
16293	CORRALITO	5853	0	6
16294	DALMACIO VELEZ SARSFIELD	5919	0	6
16295	GENERAL FOTHERINGHAM	5933	0	6
16296	HERNANDO	5929	0	6
16297	JAMES CRAIK	5984	0	6
16298	LAS PERDICES	5921	0	6
16299	OLIVA	5980	0	6
16300	PAMPAYASTA NORTE	5931	0	6
16301	PAMPAYASTA SUR	5931	0	6
16302	RIO TERCERO	5850	0	6
16303	TANCACHA	5933	0	6
16304	VILLA ASCASUBI	5935	0	6
16305	CA	5229	0	6
16306	LAS PE	5238	0	6
16307	SINSACATE	5220	0	6
16308	VILLA DEL TOTORAL	5236	0	6
16309	CERRO COLORADO	5244	0	6
16310	LAS ARRIAS	5231	0	6
16311	LUCIO V MANSILLA	5216	0	6
16312	SAN JOSE DE LA DORMIDA	5244	0	6
16313	SAN JOSE DE LAS SALINAS	5216	0	6
16314	SAN PEDRO NORTE	5205	0	6
16315	TULUMBA	5203	0	6
16316	ALTO ALEGRE	5907	0	6
16317	BALLESTEROS	2572	0	6
16318	BALLESTEROS SUD	2572	0	6
16319	BELL VILLE	2550	0	6
16320	BENJAMIN GOULD	2664	0	6
16321	CANALS	2650	0	6
16322	CHILIBROSTE	2561	0	6
16323	CINTRA	2559	0	6
16324	COLONIA BISMARCK	2651	0	6
16325	IDIAZABAL	2557	0	6
16326	JUSTINIANO POSSE	2553	0	6
16327	LABORDE	2657	0	6
16328	MONTE MAIZ	2659	0	6
16329	MORRISON	2568	0	6
16330	NOETINGER	2563	0	6
16331	ORDO	2555	0	6
16332	PASCANAS	2679	0	6
16333	PUEBLO ITALIANO	2651	0	6
16334	SAN ANTONIO DE LITIN	2559	0	6
16335	SAN MARCOS SUD	2566	0	6
16336	VIAMONTE	2671	0	6
16337	WENCESLAO ESCALANTE	2655	0	6
16338	ZONDA	5401	0	18
16339	ASTICA	5447	0	18
16340	LA CIENAGA	5463	0	18
16341	BOCA DE LA QUEBRADA	5461	0	18
16342	PIE DE PALO	5444	0	18
16343	LA ISLA	5401	0	18
16344	EL BOSQUE	5415	0	18
16345	PUNTA DEL MONTE	5415	0	18
16346	DIVISORIA	5443	0	18
16347	LA CHIMBERA	5443	0	18
16348	NUEVA ESPA	5443	0	18
16349	VILLA NUEVA	5401	0	18
16350	VILLA CORRAL	5401	0	18
16351	SOROCAYENSE	5401	0	18
16352	PUCHUZUN	5401	0	18
16353	BAHIA BLANCA	8000	1	1
16357	PERGAMINO	2700	0	1
16359	TANDIL	7000	0	1
16367	LA TORDILLA NORTE	2435	0	6
16369	LA PAQUITA	2417	0	6
16370	SEEBER	2419	0	6
16372	LUXARDO	2411	0	6
16374	QUEBRACHO HERRADO	2423	0	6
16375	GERLI	1870	0	1
16376	CANNING	1804	0	1
16377	MONTE GRANDE	1842	0	1
16380	GERLI	1824	0	1
16381	LANUS	1824	0	1
16388	SAN CARLOS DE BARILOCHE	8400	0	16
16391	SANTA FE	3000	0	21
16397	VILLA UNION	2357	0	22
16398	LIB GRAL SAN MARTIN	4512	0	10
16400	LAS ABRAS	2357	0	22
16402	EL JARDIN	4126	0	17
16403	VILLA BASILIO NIEVAS	5401	0	18
16404	VILLA CONCEPCION DEL TIO	2433	0	6
16405	SAN FRANCISCO	2400	0	6
16406	LAS VARILLAS	5940	0	6
16407	TRANSITO	2436	0	6
16408	LA FRANCIA	2426	0	6
16409	MORTEROS	2421	0	6
16410	SACANTA	5945	0	6
16411	PORTE	2415	0	6
16412	SATURNINO M LASPIUR	5943	0	6
16413	MARULL	5139	0	6
16414	LAS VARAS	5941	0	6
16417	VILLA DOS TRECE	3603	0	9
16418	GUANDACOL	5353	0	12
16422	TRES LOMAS	6409	0	1
16423	SARMIENTO	5212	0	6
16424	MAYU SUMAJ	5831	0	6
16425	VILLA SANTA CRUZ DEL LAGO	5152	0	6
16426	TUCLAME	5284	0	6
16427	VILLA SANTA MARIA	5186	0	6
16428	VILLA DEL PRADO	5186	0	6
16429	MARQUESADO	5407	0	18
16430	COLONIA JULIA Y ECHARREN	8138	0	16
16431	HURLINGHAM	1686	0	1
16432	VILLA SANTOS TESEI	1688	0	1
16434	CASTELAR	1712	0	1
16435	VILLA SARMIENTO	1706	0	1
16436	EL PALOMAR	1684	0	1
16437	HAEDO	1706	0	1
16438	MORON	1708	0	1
16439	SAN FERNANDO	1646	0	1
16440	VICTORIA	1644	0	1
16441	VIRREYES	1646	0	1
16442	ZONA DELTA SAN FERNANDO	1647	0	1
16443	GENERAL PAZ	5145	0	6
16444	MALENA	5839	0	6
16445	VILLA GOBERNADOR UDAONDO	1713	0	1
16446	ITUZAINGO	1714	0	1
16447	BARRIO PARQUE LELOIR	1713	0	1
16448	BANFIELD	1828	0	1
16449	LLAVALLOL	1836	0	1
16450	LOMAS DE ZAMORA	1832	0	1
16451	TEMPERLEY	1834	0	1
16452	TURDERA	1834	0	1
16464	AEROPUERTO EZEIZA	1802	0	1
16465	CANNING	1804	0	1
16466	CARLOS SPEGAZZINI	1812	0	1
16467	EZEIZA	1804	0	1
16468	LA UNION	1804	0	1
16469	TRISTAN SUAREZ	1806	0	1
16470	GRAND BOURG	1615	0	1
16471	INGENIERO ADOLFO SOURDEAUX	1612	0	1
16472	LOS POLVORINES	1613	0	1
16473	PABLO NOGUES	1613	0	1
16474	TORTUGUITAS	1667	0	1
16475	VILLA DE MAYO	1614	0	1
16481	CASEROS	1678	0	1
16482	CHURRUCA	1657	0	1
16483	localidades JARDIN DEL PALOMAR	1684	0	1
16484	localidadesELA	1702	0	1
16485	EL LIBERTADOR	1657	0	1
16486	JOSE INGENIEROS	1702	0	1
16487	LOMA HERMOSA	1657	0	1
16488	MARTIN CORONADO	1682	0	1
16489	11 DE SEPTIEMBRE	1657	0	1
16490	PABLO PODESTA	1657	0	1
16491	REMEDIOS DE ESCALADA	1657	0	1
16492	SANTOS LUGARES	1676	0	1
16493	VILLA BOSCH	1682	0	1
16494	VILLA RAFFO	1674	0	1
16495	VILLA SAENZ PE	1674	0	1
16496	ALDO BONZI	1770	0	1
16497	20 DE JUNIO	1761	0	1
16498	localidades MADERO	1768	0	1
16499	localidades EVITA	1778	0	1
16500	GONZALEZ CATAN	1759	0	1
16502	GREGORIO DE LAFERRERE	1757	0	1
16503	ISIDRO CASANOVA	1765	0	1
16504	LA SALADA	1774	0	1
16505	LOMAS DEL MIRADOR	1752	0	1
16506	MERCADO CENTRAL	1771	0	1
16507	RAFAEL CASTILLO	1755	0	1
16508	RAMOS MEJIA	1704	0	1
16509	SAN JUSTO	1754	0	1
16510	TABLADA	1766	0	1
16511	TAPIALES	1770	0	1
16512	VILLA INSUPERABLE	1752	0	1
16513	VILLA LUZURIAGA	1754	0	1
16514	VIRREY DEL PINO	1763	0	1
16516	JOSE CLEMENTE PAZ	1665	0	1
16517	CHUCUL	5805	0	6
16522	BELLA VISTA	1661	0	1
16523	CAMPO DE MAYO	1659	0	1
16524	MU	1663	0	1
16525	SAN MIGUEL	1663	0	1
16526	CUARTEL V	1744	0	1
16527	FRANCISCO ALVAREZ	1746	0	1
16528	LA REJA	1744	0	1
16529	MORENO	1744	0	1
16530	PASO DEL REY	1742	0	1
16531	TRUJUI	1664	0	1
16532	BENAVIDEZ	1621	0	1
16533	DIQUE LUJAN	1623	0	1
16534	DON TORCUATO	1611	0	1
16535	EL TALAR	1617	0	1
16536	GENERAL PACHECO	1617	0	1
16537	RICARDO ROJAS	1618	0	1
16538	RINCON DE MILBERG	1648	0	1
16539	TIGRE	1648	0	1
16540	TRONCOS DEL TALAR	1618	0	1
16546	BERNAL ESTE	1876	0	1
16547	BERNAL OESTE	1876	0	1
16548	DON BOSCO	1876	0	1
16549	EZPELETA ESTE	1882	0	1
16550	EZPELETA OESTE	1882	0	1
16551	QUILMES	1878	0	1
16552	QUILMES OESTE	1879	0	1
16553	SAN FRANCISCO SOLANO	1881	0	1
16554	VILLA LA FLORIDA	1881	0	1
16565	GENERAL SAN MARTIN	1650	0	1
16566	JOSE LEON SUAREZ	1655	0	1
16567	SAN ANDRES	1651	0	1
16568	VILLA BALLESTER	1653	0	1
16569	VILLA LYNCH	1672	0	1
16570	LIBERTAD	1716	0	1
16571	MARIANO ACOSTA	1723	0	1
16572	MERLO	1722	0	1
16573	PARQUE SAN MARTIN	1722	0	1
16574	PONTEVEDRA	1761	0	1
16575	SAN ANTONIO DE PADUA	1718	0	1
16576	BOSQUES	1889	0	1
16577	FLORENCIO VARELA	1888	0	1
16578	GOBERNADOR COSTA	1888	0	1
16579	INGENIERO ALLAN	1891	0	1
16580	SANTA ROSA	1888	0	1
16581	VILLA BROWN	1888	0	1
16582	VILLA VATTEONE	1888	0	1
16583	ZEBALLOS	1888	0	1
16584	LAS PE	5301	0	12
16585	SAN PEDRO	5301	0	12
16586	EL CARRIZAL TAMA	5385	0	12
16588	BERAZATEGUI	1884	0	1
16589	CENTRO AGRICOLA EL PATO	1893	0	1
16590	GUILLERMO E HUDSON	1885	0	1
16591	JUAN MARIA GUTIERREZ	1890	0	1
16592	PEREYRA	1894	0	1
16593	PLATANOS	1885	0	1
16594	RANELAGH	1886	0	1
16595	SOURIGUES	1885	0	1
16596	VILLA ESPA	1884	0	1
16597	SAN JAVIER	4105	0	24
16598	YERBA BUENA	4107	0	24
16599	SAN JOSE	4139	0	3
16600	LOTE ESTELA	4533	0	17
16601	EL ESPINILLO	6279	0	19
16602	INGENIERO FORRES	4322	0	22
16604	AGUA VERDE	4715	0	3
16605	BISCOTAL	4715	0	3
16606	CORRALITA	4715	0	3
16607	FERNANDO MARTI	6223	0	1
16608	ITURBE	4632	0	10
16609	GUEMES	4640	0	10
16610	TEUCO	4641	0	10
16611	TURU TARI	4640	0	10
16612	CERRO CHICO	4640	0	10
16613	LA FALDA	4640	0	10
16614	LUMARA	4640	0	10
16615	MIRA FLORES	4640	0	10
16616	PUERTA POTRERO	4640	0	10
16617	SAN JOSE DE MIRAFLORES	4640	0	10
16619	COLONIA LOS LAPACHOS	4606	0	10
16620	TOBA	4648	0	10
16621	ALEGRIA	4506	0	10
16622	BAJADA ALTA	4506	0	10
16623	COLONIA 8 DE SEPTIEMBRE	4512	0	10
16624	EL CARDONAL	4506	0	10
16625	LA REDUCCION	4506	0	10
16626	LOTE MAIZ NEGRO	4506	0	10
16627	OCULTO	4506	0	10
16628	OJO DE AGUA	4506	0	10
16629	SIBERIA	4506	0	10
16630	LOS BAYOS	4503	0	10
16631	LOTE LA CIENAGA	4503	0	10
16632	LOTE LA POSTA	4503	0	10
16633	ALTO DEL SALADILLO	4500	0	10
16634	LA SANGA	4500	0	10
16635	PALO SANTO	4522	0	10
16636	SALADILLO LEDESMA	4500	0	10
16637	SALADILLO SAN PEDRO	4522	0	10
16638	POTRERO	4616	0	10
16639	SANTUYOC	4616	0	10
16640	AMANCAYOC	4513	0	10
16641	TIRAXI CHICO	4616	0	10
16642	AMARGURAS	4513	0	10
16643	CACHO	4513	0	10
16644	CHORRO	4513	0	10
16645	LOMA LARGA	4513	0	10
16646	NOGAL	4513	0	10
16647	NOGALES	4513	0	10
16648	NOGALITO	4513	0	10
16649	PICACHO	4513	0	10
16650	PILCOMAYO	4513	0	10
16651	PUEBLO	4513	0	10
16652	QUE	4513	0	10
16653	SAN ANTONIO	4513	0	10
16654	TALAR	4513	0	10
16656	ABRA DE PE	4650	0	10
16657	EL MONUMENTO	4650	0	10
16658	LA CHINACA	4561	0	10
16660	LAS BLANCAS	4448	0	17
16661	RIO BLANCO	4417	0	17
16662	JACIMANA	4427	0	17
16663	LA ARCADIA	4427	0	17
16664	MONTE VIEJO	4427	0	17
16665	SAN ANTONIO	4427	0	17
16666	CHACHAPOYAS	4400	0	17
16667	CEBADOS	4403	0	17
16668	FINCA CAMINO A COLON	4403	0	17
16669	FINCA CAMINO VALLISIOS	4403	0	17
16670	FINCA COLON	4403	0	17
16671	FINCA EL COLEGIO	4403	0	17
16672	ISLA DE LA CANDELARIA	4403	0	17
16673	KILOMETRO 1156	4403	0	17
16674	LA FAMA	4403	0	17
16675	OLMOS	4403	0	17
16676	PARAJE ZANJON	4403	0	17
16677	PIEDEMONTE	4403	0	17
16678	RIO ANCHO	4403	0	17
16679	RODEOS	4403	0	17
16680	SAN MIGUEL	4403	0	17
16681	SANTA ELENA	4403	0	17
16682	VILLA LOS TARCOS	4403	0	17
16683	GUAMACHI	4560	0	17
16684	SAN PEDRO	4560	0	17
16685	EL ACHERAL	4425	0	17
16686	LAS CURTIEMBRES	4425	0	17
16687	TRES CRUCES	4425	0	17
16688	CHA	4633	0	17
16689	SAN ANTONIO	4633	0	17
16690	EL TRIGAL	4415	0	17
16691	ABRA DEL GALLO	4411	0	17
16692	ACAZOQUE	4411	0	17
16693	ESTACION CACHI	4411	0	17
16694	JUNCAL	4411	0	17
16695	PARAJE CERRO NEGRO	4411	0	17
16696	PARAJE COBRES	4411	0	17
16697	PARAJE CORTADERAS	4411	0	17
16698	PARAJE ESQUINA DE GUARDIA	4411	0	17
16699	PARAJE LAS CUEVAS	4411	0	17
16700	PARAJE MINA CONCORDIA	4411	0	17
16701	PARAJE MORRO COLORADO	4411	0	17
16702	PARAJE NACIMIENTOS	4411	0	17
16703	PARAJE OLACAPATO	4413	0	17
16704	PARAJE PASTOS GRANDES	4411	0	17
16705	PARAJE PIRCAS	4411	0	17
16706	PARAJE PIZCUNO	4411	0	17
16707	PARAJE UNCURU	4411	0	17
16709	SALAR DE HOMBRE MUERTO	4419	0	17
16710	EL MOLLE	4530	0	17
16711	POZO DE LA ESQUINA	4530	0	17
16712	EL ZAPALLAR	4430	0	17
16713	EL CEIBAL	4430	0	17
16714	EL SUNCHAL	4430	0	17
16715	LA ASUNCION	4430	0	17
16716	LA MARAVILLA	4430	0	17
16717	SAN PEDRO DE ARANDA	4430	0	17
16718	BAJADA BLANCA	4193	0	17
16719	CABEZA DE ANTA	4193	0	17
16720	CA	4193	0	17
16721	CA	4193	0	17
16722	CERRO COLORADO	4193	0	17
16723	CERRO NEGRO	4193	0	17
16724	CHA	4193	0	17
16725	COLGADAS	4193	0	17
16726	EL CEIBAL	4193	0	17
16727	EL OJO	4193	0	17
16728	LA CRUZ	4193	0	17
16729	LA FIRMEZA	4193	0	17
16730	LA PAJITA	4193	0	17
16731	LAS CATITAS	4193	0	17
16732	LAS SALADAS	4193	0	17
16733	LAS TUNILLAS	4193	0	17
16734	POZO BLANCO	4193	0	17
16735	RECREO	4193	0	17
16736	SAN ROQUE	4193	0	17
16737	SANTA CATALINA	4193	0	17
16738	SURI MICUNA	4193	0	17
16739	TALA YACO	4193	0	17
16740	VILLA CORTA	4193	0	17
16741	VIZCACHERAL	4193	0	17
16742	BARBAYASCO	4190	0	17
16754	EL MOLINITO	4715	0	3
16755	EL REALITO	4715	0	3
16756	FALDEO	4715	0	3
16757	GALPON	4715	0	3
16758	LA AGUITA	4715	0	3
16759	LA SALVIA	4715	0	3
16760	LAMPASO	4715	0	3
16761	LAS BARRAS	4715	0	3
16762	AGUA SALADA	4740	0	3
16763	ALGARROBAL	4740	0	3
16764	ARIMA	4740	0	3
16765	AGUADITA	4705	0	3
16766	BALSA	4705	0	3
16767	CUMBRE DEL LAUDO	4705	0	3
16768	GENTILE	4705	0	3
16769	ROSARIO DEL SUMALAO	4705	0	3
16770	TACAHUASI	4705	0	3
16771	TORO MUERTO	4705	0	3
16772	VEGA CURUTU	4705	0	3
16773	VEGA TAMBERIA	4705	0	3
16774	AGUA DEL CAMPO	4750	0	3
16775	ANGOSTURA	4750	0	3
16776	CASA GRANDE	4750	0	3
16777	CHIQUERITO	4750	0	3
16778	CHUCOLAY	4750	0	3
16779	CORTADERA	4750	0	3
16780	CUEVA BLANCA	4750	0	3
16781	LA REPRESA	4750	0	3
16782	LA TOTORA	4750	0	3
16783	LORO HUASI	4139	0	3
16784	LUNA AGUADA	4750	0	3
16785	OJO DE LA CORTADERA	4750	0	3
16786	PALO BLANCO	4750	0	3
16787	PAMPA CIENAGA	4750	0	3
16788	POTRERITO	4750	0	3
16789	PUERTO POTRERO	4750	0	3
16790	PUERTO CHIPI	4750	0	3
16791	PUERTO DE LA PAMPA	4750	0	3
16792	RINCON GRANDE	4750	0	3
16793	RUMIMONION	4750	0	3
16794	SAN ANTONIO	4750	0	3
16795	SAN BUENAVENTURA	4750	0	3
16796	SHINCAL	4750	0	3
16797	VISCOTE	4750	0	3
16798	ZARCITO	4750	0	3
16799	ZARZA	4750	0	3
16800	CACHUAN	4750	0	3
16801	LA BARRANCA LARGA	4750	0	3
16802	NACIMIENTO	4750	0	3
16803	NACIMIENTOS DE ABAJO	4750	0	3
16804	POZUELOS	4750	0	3
16805	DURAZNILLO	4750	0	3
16806	LAS LATILLAS	4750	0	3
16807	SEBILA	4750	0	3
16808	PAYABUAYCA	4700	0	3
16809	SAUCE	4700	0	3
16810	PE	4700	0	3
16811	EL SALTO	5260	0	3
16812	LAS CORTADERITAS	5260	0	3
16813	LOS CAUDILLOS	5260	0	3
16814	NAVIGAN	5260	0	3
16815	ACHERAL	5260	0	3
16816	AGUA ESCONDIDA	5260	0	3
16817	BUEN RETIRO	5260	0	3
16818	CAMPO BELLO	5260	0	3
16819	CAMPO BLANCO	5260	0	3
16820	CATITA	5260	0	3
16821	JUMEAL	5260	0	3
16822	LAGUNITA	5260	0	3
16823	LAJA	5260	0	3
16824	LAS PUERTAS	5260	0	3
16825	LAS ZANJAS	5260	0	3
16826	LIEBRE	5260	0	3
16827	LOS CHA	5260	0	3
16828	MOLLEGASTA	5260	0	3
16829	OLMOS	5260	0	3
16830	PAMPA POZO	5260	0	3
16831	PLUMERO	5260	0	3
16832	PTO ESPINAL	5260	0	3
16833	PUNTA DEL POZO	5260	0	3
16834	SANCHO	5260	0	3
16835	TAJAMARES	5260	0	3
16836	TINAJERA	5260	0	3
16837	VILLA OFELIA	5260	0	3
16838	VILLA SOTOMAYOR	5260	0	3
16839	PARAJE LOS CHA	5260	0	3
16840	BALDE	5260	0	3
16841	BUEY MUERTO	5260	0	3
16842	CERRO COLORADO	5260	0	3
16843	EL RECREO	5260	0	3
16844	LA CAMPANA	5260	0	3
16845	LA HOYADA	5260	0	3
16846	LA LOMA	5260	0	3
16847	PALO SECO	5260	0	3
16848	SAN ROQUE	5260	0	3
16849	YAPES	5260	0	3
16850	BARRO NEGRO	4718	0	3
16851	BASTIDOR	4718	0	3
16852	CHIFLON	4718	0	3
16853	POSTA	4718	0	3
16854	JOYANGUITO	5315	0	3
16855	BUEY MUERTO	4139	0	3
16856	CERRO COLORADO	4139	0	3
16857	CIENAGA	4139	0	3
16858	PUERTO BLANCO	4750	0	3
16859	LAS LATILLAS	4728	0	3
16860	SEBILA	4728	0	3
16861	OLLITA	5260	0	3
16862	CIENAGA	5260	0	3
16863	DESRUMBE	4139	0	3
16864	EL RECREO	4139	0	3
16865	LA CAMPANA	4139	0	3
16866	LA HOYADA	4139	0	3
16867	LA LOMA	4139	0	3
16868	PALO SECO	4139	0	3
16869	SAN JOSE BANDA	4139	0	3
16870	YAPES	4139	0	3
16871	CARIDAD	4723	0	3
16872	EL RODEITO	4723	0	3
16873	EL SAUCECITO	4723	0	3
16874	LA VICTORIA	4723	0	3
16875	NAIPA	4723	0	3
16876	SANTOS LUGARES	4723	0	3
16877	AGUA GRANDE	5340	0	3
16878	AGUADA	5340	0	3
16879	ANCHOCA	5340	0	3
16880	APOCANGO	5340	0	3
16881	BALUNGASTA	5340	0	3
16882	CANTERA ROTA	5340	0	3
16883	CASA DE ALTO	5340	0	3
16884	CASA GRANDE	5340	0	3
16885	CASTA	5340	0	3
16886	CERDAS	5340	0	3
16887	CHANERO	5340	0	3
16888	CHAVERO	5340	0	3
16889	ESTANCITO	5340	0	3
16890	GUANCHICITO	5340	0	3
16891	GUANCHIN	5340	0	3
16892	GUINCHO	5340	0	3
16893	JUNTA	5340	0	3
16894	LA CHILCA	5340	0	3
16895	LAS LOSAS	5340	0	3
16896	LAS PELADAS	5340	0	3
16897	LOMA GRANDE	5340	0	3
16898	LOS CHANAMPA	5340	0	3
16899	LOS VALVEROS	5340	0	3
16900	MATAMBRE	5340	0	3
16901	MEDANO	5340	0	3
16902	NEGRO MUERTO	5340	0	3
16903	OJO DE AGUA	5340	0	3
16904	PALACIOS	5340	0	3
16905	PAN DE AZUCAR	5340	0	3
16906	PANTANOS	5340	0	3
16907	PASTOS AMARILLOS	5340	0	3
16908	PILLAHUASI	5340	0	3
16909	PLANCHADA	5340	0	3
16910	POCITOS	5340	0	3
16911	QUEBRADA HONDA	5340	0	3
16912	QUEMADITA	5340	0	3
16913	QUEMADO	5340	0	3
16914	QUIQUERO	5340	0	3
16915	QUSTO	5340	0	3
16916	RIO ABAJO	5340	0	3
16917	RIO DE LOS INDIOS	5340	0	3
16918	RODEO	5340	0	3
16919	SUNCHO	5340	0	3
16920	TALA ZAPATA	5340	0	3
16921	TALAR	5265	0	3
16922	TALITA	5340	0	3
16923	TAMBERIA	5340	0	3
16924	TAMBU	5340	0	3
16925	TOTORA	5340	0	3
16926	TROYA	5340	0	3
16927	VALLECITO	5340	0	3
16928	VEGA	5340	0	3
16929	VINQUIS	5340	0	3
16930	YACOCHUYO	5340	0	3
16931	CHA	4707	0	3
16932	ESTANQUE	4707	0	3
16933	PAMPA	4707	0	3
16934	SEBILA	4707	0	3
16935	TALA	4707	0	3
16936	TIORCO	4707	0	3
16937	ZANJA	4707	0	3
16938	CORTADERA	5340	0	3
16939	CORRAL VIEJO	4139	0	3
16940	LA HIGUERITA	5261	0	3
16941	OJO DE AGUA	4750	0	3
16942	AGUA NUEVA	5600	0	13
16943	AGUA DE LA MULA	5600	0	13
16944	CAJON DE MAYO	5600	0	13
16945	CENTRAL HIDROELECTRICA 1	5600	0	13
16946	CENTRAL HIDROELECTRICA 2	5600	0	13
16947	COLONIA LA LLAVE	5600	0	13
16948	COLONIA SOITUE	5600	0	13
16949	COMISION NAC DE EMERGENCIA	5600	0	13
16950	CUESTA DE LOS TERNEROS	5600	0	13
16951	EL PICONA	5600	0	13
16952	EL PLATEADO	5600	0	13
16953	EMBALSE VALLE GRANDE	5600	0	13
16954	ESTANCIA EL CAMPAMENTO	5600	0	13
16955	ESTANCIA LA SARITA	5600	0	13
16956	ESTANCIA LA TRINTRICA	5600	0	13
16957	ESTANCIA LOS HUAICOS	5600	0	13
16958	ESTANCIA LOS LEONES	5600	0	13
16959	ESTANCIA SOFIA RAQUEL	5600	0	13
16960	ESTANCIA TIERRAS BLANCAS	5600	0	13
16961	LA LLAVE NUEVA	5600	0	13
16962	LA MINA DEL PECE	5600	0	13
16963	LA PICASA	5600	0	13
16964	MINAS EL SOSNEADO	5600	0	13
16965	PTA DEL AGUA VIEJA	5600	0	13
16966	PUESTA EL CAVADO	5600	0	13
16967	PUESTO AGUA DE LA LIEBRE	5600	0	13
16968	PUESTO AGUA DEL MEDANO	5600	0	13
16969	PUESTO EL JILGUERO	5600	0	13
16970	PUESTO LAS PUNTANAS	5600	0	13
16971	ALGARROBO DE SORTUE	5600	0	13
16972	LA CARUSINA	5600	0	13
16973	LA JAULA	5600	0	13
16974	LA PICARONA	5600	0	13
16975	LA TOSCA	5600	0	13
16976	LOS CLAVELES	5600	0	13
16977	LOS PATOS	5600	0	13
16978	LOS PEJECITOS	5600	0	13
16979	LOS REPUNTES	5600	0	13
16980	LOS TOLDITOS	5600	0	13
16982	CABO DE LAS VIRGENES	9400	0	20
16983	CAMUZU AIKE	9400	0	20
16984	CANCHA CARRERA	9400	0	20
16985	CONDOR	9400	0	20
16986	MONTE AYMOND	9400	0	20
16987	PUNTA LOYOLA	9400	0	20
16988	EL TURBIO	9407	0	20
16989	GLENCROSS	9407	0	20
16990	BAJO CARACOLES	9315	0	20
16991	HOTEL LAS HORQUETAS	9315	0	20
16992	TAMEL AIKE	9315	0	20
16993	PASO ROBALLO	9315	0	20
16994	LA MANCHURIA	9311	0	20
16995	YACIMIENTO CERRO VANGUARDIA	9310	0	20
16997	CORONEL MARTIN IRIGOYEN	9407	0	20
17003	9 DE JULIO	3363	0	14
17004	CHACRA LA CASILDA	6221	0	11
17005	CHACRA LA MAGDALENA	6621	0	11
17006	ESTANCIA LA LUCHA	6221	0	11
17007	ESTANCIA LA PAMPEANA	6221	0	11
17008	ESTANCIA LA VOLUNTAD	6221	0	11
17009	EL GUANACO	6380	0	11
17011	EL BOQUERON	8200	0	11
17016	PTO LOS AMARILLOS	5636	0	13
17017	EX ESCUELA HOGAR NRO 5	8200	0	11
17018	localidades OESTE	5634	0	13
17020	EL BUEN PASTOR	5634	0	13
17021	EL DESVIO	5621	0	13
17022	EL VENTARRON	5621	0	13
17023	ESTANCIA EL BALDERON	5634	0	13
17024	ESTANCIA LA CORTADERA	5634	0	13
17025	ESTANCIA LA VARITA	5634	0	13
17026	KILOMETRO 84	5634	0	13
17027	LA CALDENADA	5634	0	13
17028	LA CALIFORNIA	5621	0	13
17029	LA CORONA	5634	0	13
17030	LA LUNINA	5634	0	13
17031	LA SE	5634	0	13
17032	LOS AMARILLOS	5634	0	13
17034	MEDANOS COLORADOS	5636	0	13
17036	VUELTA DEL ZANJON	5634	0	13
17063	CAMPO MORENO	3734	0	4
17065	COLONIA ABATE	3732	0	4
17066	COLONIA BRAVO	3732	0	4
17067	COLONIA DRYDALE	3734	0	4
17068	COLONIA ECONOMIA	3732	0	4
17069	COLONIA EL TRIANGULO	3732	0	4
17070	COLONIA LA MARIA LUISA	3734	0	4
17071	COLONIA LA TOTA	3734	0	4
17072	ADRIAN MATURANO	5590	0	13
17073	ALEJANDRO PEREZ	5590	0	13
17074	ALFREDO LUCERO	5590	0	13
17075	ALTO DE LOS PERROS	5590	0	13
17076	ALTO DE LOS SAPOS	5590	0	13
17077	COLONIA NECOCHEA SUD	3732	0	4
17078	ALVAREZ	5590	0	13
17079	ANA DE DONAIRE	5590	0	13
17080	ANACLETA VIUDA DE PEREZ	5590	0	13
17081	ANDRES PEREZ	5590	0	13
17082	ANTONIO SOSA	5590	0	13
17083	B ELENA	5590	0	13
17084	CHACRAS	3432	0	7
17085	COLONIA WELHERS	3732	0	4
17086	BAJADA DEL PERRO	5590	0	13
17087	BA	5598	0	13
17088	LA BANDERITA	8200	0	11
17089	BECERRA	5590	0	13
17090	BLAS PANELO	5590	0	13
17091	BOYEROS	5590	0	13
17092	C GONZALES VIDELA	5590	0	13
17093	CAMPO EL TORO	5590	0	13
17094	EL CUADRADO	3734	0	4
17095	CHACRAS DE LIMA	5590	0	13
17096	CHAMUSCAO	5590	0	13
17097	CHA	5590	0	13
17098	CIRILO MAHONA	5590	0	13
17099	ARROYO CARABALLO	3265	0	8
17100	CLARENTINO ROLDAN	5590	0	13
17101	COLONIA EL REGADIO	5590	0	13
17102	CORRAL DE CUERO	5590	0	13
17103	CRUZ DEL YUGO	5590	0	13
17104	EL PALMAR	3732	0	4
17105	CRUZ LEDESMA	5590	0	13
17106	DALMIRO ZAPATA	5590	0	13
17107	DANIEL LUCERO	5590	0	13
17108	DANIEL MORGAN	5590	0	13
17109	ESTANCIA ACHALA	3060	0	21
17110	DIONISIO ORDO	5590	0	13
17111	DIONISIO ORTUBIA	5590	0	13
17112	DOMINGO GIMENEZ	5590	0	13
17113	DOMINGO LARA	5590	0	13
17114	DOMINGO OGA	5590	0	13
17115	DOMINGO REAL	5590	0	13
17116	EL PUMA	3734	0	4
17117	DONATO OJEDA	5590	0	13
17118	ARROYO CONCEPCION	3287	0	8
17119	EL TRIANGULO	3060	0	21
17120	DOROTEO ORDO	5590	0	13
17121	EL TORO PI	3432	0	7
17122	EL SALADILLO	3734	0	4
17123	EL TRIANGULO	3732	0	4
17124	ESTACION AGRONOMICA	3432	0	7
17125	ARROYO GRANDE	3203	0	8
17126	KILOMETRO 402	3448	0	7
17127	ARROYO PALMAR	3218	0	8
17128	LAS GARZAS	3432	0	7
17129	ARROYO URQUIZA	3280	0	8
17130	LOMAS	3432	0	7
17131	LOMAS ESTE	3432	0	7
17132	FORTIN TACURU	3060	0	21
17133	MACEDO	3432	0	7
17134	DULCE	5590	0	13
17135	E ROSALES	5590	0	13
17136	EL CARANCHITO	5590	0	13
17137	EL CAVADO CHICO	5590	0	13
17138	EL CERCADO	5590	0	13
17139	EL CHALET	5590	0	13
17140	EL GONZANO	5590	0	13
17141	CALERA	3281	0	8
17142	MARTIN	3432	0	7
17143	EL GUERRINO	5590	0	13
17144	EL JILGUERO	5590	0	13
17145	LA ECONOMIA	3732	0	4
17146	EL LECHUCITO	5590	0	13
17147	EL PERINO	5590	0	13
17148	EL REGADIO	5590	0	13
17149	EL VAQUERO	5590	0	13
17150	EL ZAMPAL	5590	0	13
17151	EL ZAPATINO	5590	0	13
17152	ELOY FUNES	5590	0	13
17153	EMILIO NIETA	5590	0	13
17154	EPIFANIO FERNANDEZ	5590	0	13
17155	ERNESTO ALCARAZ	5590	0	13
17156	ROMERO CUAZU	3432	0	7
17157	LAS LEONAS	3732	0	4
17158	ESTANCIA LA VIZCACHERA	5590	0	13
17159	ESTANCIA LAS VIZCACHERAS	5590	0	13
17160	ESTANISLAO ORDO	5590	0	13
17161	SAN FERNANDO	3432	0	7
17162	LOS QUEBRACHITOS	3734	0	4
17163	EUSEBIA VIUDA DE GOMEZ	5590	0	13
17164	EVARISTO ACEVEDO	5590	0	13
17165	EVARISTO SALAS	5590	0	13
17166	FABRICIANO ROJAS	5590	0	13
17167	FELIPE GARRO	5590	0	13
17168	FLORENCIO MOLINA	5590	0	13
17169	LAS ARENAS	3060	0	21
17170	FERMIN PEREZ	5590	0	13
17171	MINISTRO RAMON GOMEZ	3732	0	4
17172	YUQUERI	3432	0	7
17173	FLORENCIO ORDO	5590	0	13
17174	FRANCISCO MOLINA	5590	0	13
17175	FRANCISCO ROJAS	5590	0	13
17176	FRUCTUOSO DIAZ	5590	0	13
17177	GERMAN MATURANO	5590	0	13
17178	GERTRUDIS DE OJEDA	5590	0	13
17179	PALMAR CENTRAL	3732	0	4
17180	GILBERTO PEREZ	5590	0	13
17181	GREGORIO ZAPATA	5590	0	13
17182	GUILLERMO DONAIRE	5590	0	13
17183	H GARZALA	5590	0	13
17184	COLONIA ELISA	3265	0	8
17185	HERMENEGILDO DIAZ	5590	0	13
17186	PALMAR NORTE	3732	0	4
17187	HONORIO ZAPATA	5590	0	13
17188	HUAICOS DE RUFINO	5590	0	13
17189	HUECOS DE LOS TORDILLOS	5590	0	13
17190	IGNACIO VILLEGAS	5590	0	13
17191	IRINEO ZAPATA	5590	0	13
17192	ISLA RETAMITO	5590	0	13
17193	J ORTUBIA	5590	0	13
17194	CARRIZAL	3432	0	7
17195	JOSE DIAZ	5590	0	13
17196	JOSE FERNANDEZ	5590	0	13
17197	JOSE LUCERO	5590	0	13
17198	JOSE R MOLINA	5590	0	13
17199	PAMPA DOROTIER	3732	0	4
17200	JOSE SUAREZ	5590	0	13
17201	JUAN B DUFAU	5590	0	13
17202	JUAN H ORTIZ	5590	0	13
17203	JUAN MILLAN	5590	0	13
17204	JUAN ZAPATA	5590	0	13
17205	COLONIA EMILIO GOUCHON	3269	0	8
17206	JULIO COMEGLIO	5590	0	13
17207	JUNTA DE LOS RIOS	5590	0	13
17208	LA CA	5590	0	13
17209	SAN BERNARDO	3061	0	21
17210	PUERTA DE LEON	3732	0	4
17211	LA CAUTIVA	5590	0	13
17212	LA CHAPINA	5590	0	13
17213	WELHERS	3732	0	4
17214	LA COLA	5590	0	13
17215	LA ESQUINA	5590	0	13
17216	LA ESTANCIA	5590	0	13
17217	SIN PEREZA	3060	0	21
17218	LA FORTUNA	5590	0	13
17219	LA ISLA	5590	0	13
17220	LA LEONA	5590	0	13
17221	LADISLAO	5590	0	13
17222	LAS CRUCES	5590	0	13
17223	LAS ROSAS	5590	0	13
17224	LAS VISTAS	5590	0	13
17225	LADISLAO CAMPOS	5590	0	13
17226	LINO PEREZ	5590	0	13
17227	BEDOYA	3412	0	7
17228	LISANDRO ESCUDERO	5590	0	13
17229	LOS ALTAMIQUES	5590	0	13
17230	LOS BURGOS	5590	0	13
17231	LOS COLORADOS	5590	0	13
17232	COSTA INE	3505	0	4
17233	COLONIA	3481	0	7
17234	LOS HORCONCITOS	5590	0	13
17235	LOS RAMBLONES	5590	0	13
17236	LOS ROSETI	5590	0	13
17237	LOS TAMARINDOS	5590	0	13
17239	ESTANCIA LA CARMENCHA	3481	0	7
17240	LOS TORDILLOS	5621	0	13
17241	LOS VERDES	5590	0	13
17242	LOS VILLEGAS	5590	0	13
17243	LUCAS DONAIRE	5590	0	13
17244	LUIS MARQUEZ	5590	0	13
17245	M ESCUDERO	5590	0	13
17247	M QUIROGA	5590	0	13
17248	MARAVILLA	5590	0	13
17249	MARIA GARCIA	5590	0	13
17250	MARIA VIUDA DE DONAIRE	5590	0	13
17251	ESTANCIA MBOTA	3481	0	7
17252	MARIO OLGUIN	5590	0	13
17254	MATIAS GARRO	5590	0	13
17255	MAURICIO CALDERON	5590	0	13
17256	MEDARDO MIRANDA	5590	0	13
17257	MOSMOTA	5590	0	13
17259	ESTANCIA SAN ANTONIO	3481	0	7
17260	NATALIA DONAIRE	5590	0	13
17261	NECTO SOSA	5590	0	13
17262	NESTOR AGUILERA	5590	0	13
17263	ISLA TACUARA	3481	0	7
17264	NICOLAS ORDO	5590	0	13
17265	ONOTRE PUEBLA	5590	0	13
17266	PASCUAL SOSA	5590	0	13
17267	PASO DE LAS CANOAS	5590	0	13
17269	PAULINO MATURA	5590	0	13
17270	PEDRO CASTELU	5590	0	13
17271	PEDRO PABLO PEREZ	5590	0	13
17272	LA LOMA	3505	0	4
17273	PUENTE VIEJO	5590	0	13
17274	PUESTO DE GARRO	5590	0	13
17275	PUESTO DE LAS CARRETAS	5590	0	13
17276	PUESTO DE LAS TROPAS	5590	0	13
17277	PUESTO DE OLGUIN	5590	0	13
17278	PUESTO DE OROZCO	5590	0	13
17279	PUESTO DE PETRA	5590	0	13
17280	PUESTO DE SOSA	5590	0	13
17281	MBARIGUI	3481	0	7
17282	PUESTO DEL CHA	5590	0	13
17283	PUESTO EL RETAMITO	5590	0	13
17284	PUESTO NUERAS	5590	0	13
17285	PUNTA DE RIELES	3505	0	4
17286	PUESTO ZAMPAL	5590	0	13
17287	PALMAR ARERUNGUA	3481	0	7
17288	PUNTOS DE AGUA	5590	0	13
17289	R BEBEDERA	5590	0	13
17290	RAMBLON DE LA PAMPA	5590	0	13
17291	RAMBLON GRANDE	5590	0	13
17292	PIRAYU	3481	0	7
17293	RAMON DONAIRE	5590	0	13
17294	RAMON GIMENEZ	5590	0	13
17295	PUESTO DE ISLA	3487	0	7
17296	REGINO OJEDA	5590	0	13
17297	RETAMO PARTIDO	5590	0	13
17298	ROSARIO GATICA	5590	0	13
17299	RINCON	3481	0	7
17300	PUNTA RIELES	3505	0	4
17301	RUFINO GOMEZ	5590	0	13
17302	RUIZ CUE	3481	0	7
17303	COLONIA SAN ERNESTO	3254	0	8
17304	S CORTIS	5590	0	13
17305	SAN ANTONIO	5590	0	13
17306	SAN PEDRO	5590	0	13
17307	SAN MIGUEL	3505	0	4
17308	TORO I	3481	0	7
17309	SANTIAGO ROMERO	5590	0	13
17310	SATURNINO ROMERO	5590	0	13
17311	SIXTO LEDESMA	5590	0	13
17312	LAS LIEBRES	2520	0	21
17313	SERVILIANO OJEDA	5590	0	13
17314	COLONIA GUALTIERI	3534	0	4
17315	BA	3400	0	7
17316	TEODORO GARRO	5590	0	13
17317	BA	3400	0	7
17318	TEODORO VILLARUEL	5590	0	13
17319	CA	3401	0	7
17320	TEOFILA ACEVEDO	5590	0	13
17321	AREQUITO	2183	0	21
17322	COLONIA VAZQUEZ	3267	0	8
17323	TEOFILO RUBEN	5590	0	13
17324	TEOFILO ZAPATA	5590	0	13
17325	CARABAJAL ESTE	3416	0	7
17326	LAS LOMITAS	3534	0	4
17327	COLONIA ARROCERA	3416	0	7
17328	TILA	5590	0	13
17329	LOTE 11	3534	0	4
17330	TILIO ALCARAZ	5590	0	13
17331	COLONIA NUEVA VALENCIA	3416	0	7
17332	TOMAS MERCADO	5590	0	13
17333	TRAVESIA	5590	0	13
17334	LOTE 14	3534	0	4
17335	TRINO ROSALESO	5590	0	13
17336	VICENTE MU	5590	0	13
17337	LOTE 23	3534	0	4
17338	VICENTE PELETAY	5590	0	13
17339	VIUDA DE OROZCO	5590	0	13
17340	ZANON CANAL	5590	0	13
17342	DOCTOR FELIX MARIA GOMEZ	3400	0	7
17343	LOTE 3	3534	0	4
17344	GARRIDO CUE	3416	0	7
17345	ESTABLECIMIENTO LA CALERA	3287	0	8
17346	LOTE 42	3534	0	4
17347	KILOMETRO 13	3401	0	7
17348	KILOMETRO 512	3416	0	7
17349	KILOMETRO 516	3416	0	7
17350	PAMPA BANDERA	3534	0	4
17351	LAGUNA PAIVA	3401	0	7
17352	LAGUNA SOTO	3401	0	7
17353	LOMAS SAN CAYETANO	3401	0	7
17354	MATADERO SANTA CATALINA	3416	0	7
17355	CURVA DE NOVOA	3722	0	4
17356	DOS BOLICHES	3722	0	4
17357	PALMERA	3401	0	7
17358	2 DE MAYO	3722	0	4
17359	PARQUE SAN MARTIN	3400	0	7
17360	PASO LOVERA	3401	0	7
17361	PASO PESOA	3401	0	7
17362	RINCON DEL SOMBRERO	3416	0	7
17363	VILLA EL DORADO	3400	0	7
17364	VILLA JUAN DE VERA	3400	0	7
17365	VILLA SOLARI	3401	0	7
17366	PAMPIN	3401	0	7
17367	ESTABLECIMIENTO LOS MONIGOTES	3287	0	8
17368	AURELIA NORTE	2318	0	21
17369	KILOMETRO 25	3177	0	8
17370	EL ESTERO	3722	0	4
17371	KILOMETRO 114	3280	0	8
17372	AURELIA SUD	2318	0	21
17373	EL RECOVECO	3722	0	4
17374	KILOMETRO 305	3265	0	8
17375	EL RECOVO	3722	0	4
17376	KILOMETRO 310	3280	0	8
17377	KILOMETRO 311	3269	0	8
17378	LAS CUCHILLAS	3722	0	4
17379	KILOMETRO 322	3280	0	8
17380	LAS PIEDRITAS	3722	0	4
17381	KILOMETRO 324	3280	0	8
17382	KILOMETRO 336	3280	0	8
17383	PAMPA BRUGNOLI	3722	0	4
17384	KILOMETRO 337	3269	0	8
17385	PAMPA DEL CIELO	3722	0	4
17386	KILOMETRO 344	3269	0	8
17387	KILOMETRO 353	3218	0	8
17388	KILOMETRO 45	3287	0	8
17389	KILOMETRO 49	3280	0	8
17390	PAMPA HERMOSA	3722	0	4
17391	KILOMETRO 50	3287	0	8
17392	PAMPA MITRE	3722	0	4
17393	KILOMETRO 56	3285	0	8
17394	PAMPA VILLORDO	3722	0	4
17395	KILOMETRO 86	3285	0	8
17396	PAMPA ZANATA	3722	0	4
17397	KILOMETRO 88	3280	0	8
17398	KILOMETRO 89	3285	0	8
17399	PAMPINI	3722	0	4
17400	KILOMETRO 99	3283	0	8
17401	PUEBLO PUCA	3722	0	4
17402	KILOMETRO 1183	3714	0	4
17403	ALTO TRES COMPADRES	5537	0	13
17404	ALTO DE LAS ARA	5519	0	13
17405	CAPILLA DEL COVADITO	5533	0	13
17406	CAPILLA SAN JOSE	5533	0	13
17407	COLONIA ESTRELLA	5533	0	13
17408	COLONIA SAN FRANCISCO	5533	0	13
17409	ARA	3423	0	7
17410	DON MARTIN	5537	0	13
17411	EL 15	5533	0	13
17412	BATARA	3423	0	7
17413	CAIMAN	3423	0	7
17414	EL BALSADERO	5533	0	13
17415	COLONIA CABRAL	3518	0	4
17416	EL CALVADITO	5533	0	13
17417	EL CAVADITO	5537	0	13
17418	CAPILLA CUE	3423	0	7
17419	EL CHILCAL	5533	0	13
17420	EL COLON	5535	0	13
17421	EL 14	3518	0	4
17422	EL PASCAL	5533	0	13
17423	COLONIA JACOBO FINH	3423	0	7
17424	EL SALADO	5563	0	13
17425	EL TAPON	5533	0	13
17426	EL BAYO	2300	0	21
17427	FORZUDO	5537	0	13
17428	GUADAL DE LOS PEREZ	5533	0	13
17429	LA ESPERANZA	5533	0	13
17430	LA EXCAVACION	5537	0	13
17431	LA FORTUNA	5533	0	13
17432	LA HOLANDA	5533	0	13
17433	LA TOMA	5563	0	13
17434	ESTACION MARIA JUANA	2445	0	21
17435	LAGUNA DE GUANACACHE	5535	0	13
17436	LAS CRUCES	5537	0	13
17437	EL PALMAR	3518	0	4
17438	LAS GATEADAS	5533	0	13
17439	LAS VIOLETAS	5533	0	13
17440	LOS ALGODONES	5537	0	13
17441	LOS YAULLINES	5533	0	13
17442	MARIA LUISA	5563	0	13
17443	FASSI	2300	0	21
17444	LA ESPERANZA	3518	0	4
17445	PAMPA DEL SALADO	5535	0	13
17446	PASO DEL CISNE	5533	0	13
17447	PUERTO HORTENSA	5533	0	13
17448	PUESTO ALGARROBO GRANDE	5533	0	13
17449	PUESTO EL PICHON	5533	0	13
17450	HUGENTOBLER	2317	0	21
17451	PUESTO LA HORTENSIA	5537	0	13
17452	PUESTO RANCHO DE LA PAMPA	5582	0	13
17453	RAMBLON DE LOS CHILENOS	5533	0	13
17454	SAN PEDRO	5537	0	13
17455	AGUA BOTADA	5613	0	13
17456	AGUA DE CABRERA	5613	0	13
17457	AGUA DEL CHANCHO	5613	0	13
17458	AGUADA PENEPE	5613	0	13
17459	AGUADA PEREZ	5613	0	13
17460	AGUADA PUESTO LA TOTORA	5611	0	13
17461	LOTE 15 ESCUELA 268	3522	0	4
17462	COLONIA TATACUA	3423	0	7
17463	BAJO DEL PELUDO	5613	0	13
17464	BARREAL COLORADO	5613	0	13
17465	LOTE 16 ESCUELA 204	3522	0	4
17466	BARREAL DE LA MESILLA	5613	0	13
17467	BARRIALES LOS RANCHOS	5613	0	13
17468	BOLICHE	5613	0	13
17469	LOTE 92 LA RINCONADA	3524	0	4
17470	BOLICHE LOS BARREALES	5611	0	13
17471	BUTA BILLON	5613	0	13
17472	EL YUQUERI	3423	0	7
17473	PINDO	3518	0	4
17474	ESTANCIA SAN ROBERTO	3423	0	7
17475	ESTANCIA SANTA MARIA	3423	0	7
17476	IGUATE PORA	3423	0	7
17477	LA ANGELITA	3423	0	7
17478	LA AURORA	3423	0	7
17479	LA PEPITA	3423	0	7
17480	LOS ANGELES	3423	0	7
17481	PUEBLO TERRAGNI	2300	0	21
17482	LUJAMBIO	3423	0	7
17483	MONTEVIDEO	3423	0	7
17484	NUEVO PORVENIR	3423	0	7
17485	PALMAR	3423	0	7
17486	PARAJE FLORIDA	3423	0	7
17487	PASO IRIBU CUA	3423	0	7
17488	TERMAS DEL CERRITO	3518	0	4
17489	PINDO	3421	0	7
17490	PORVENIR	3423	0	7
17491	SIERRA PEREYRA	2300	0	21
17492	SAN AGUSTIN	3423	0	7
17493	SAN FRANCISCO	3423	0	7
17494	YATAY	3518	0	4
17495	SAN JOSE	3423	0	7
17496	SAN JUAN	3423	0	7
17497	TRES COLONIAS	2300	0	21
17498	SAN NICANOR	3423	0	7
17499	SAN NICOLAS	3421	0	7
17500	SANTA MARIA	3423	0	7
17501	9 DE JULIO	3714	0	4
17502	SANTA RITA	3423	0	7
17503	SAUCE	3423	0	7
17504	CASTELLIN	3714	0	4
17505	TAJIBO	3423	0	7
17506	COLOMBIA	3714	0	4
17507	EL CA	3714	0	4
17508	EL GUANACO	3714	0	4
17509	LA SUIZA	3280	0	8
17510	EL INDIO	3714	0	4
17511	LA S DIEZ CASAS	3269	0	8
17512	EL PARAISO	3714	0	4
17513	EL VALLA	3714	0	4
17514	LA AGUADA	3714	0	4
17550	PARQUE NACIONAL EL PALMAR	3280	0	8
17551	ARROYO CASTILLO	3460	0	7
17552	CABEZA DE VACA	5613	0	13
17553	CAMPAMENTO CARAPACHO	5611	0	13
17554	CAMPO EL ALAMO	5613	0	13
17555	CANCHA DE ESQUI	5613	0	13
17556	AGUAS NEGRAS	3634	0	9
17557	CHACHAO	5613	0	13
17558	CHACHARALEN	5611	0	13
17559	EL ALAMO	5613	0	13
17560	EL CAJON	5613	0	13
17561	EL CIENAGO	5611	0	13
17562	EL DURAZNO	5611	0	13
17563	EL INFIERNILLO	5509	0	13
17564	EL PAYEN	5613	0	13
17565	EL PUESTITO	5613	0	13
17566	EL VATRO	5613	0	13
17567	EL ZAMPAL	5613	0	13
17568	GUAYQUERIA COLORADA	5613	0	13
17569	PUENTE DE GUALEGUAYCHU	3265	0	8
17570	HOTEL TERMAS DEL AZUFRE	5613	0	13
17571	HOTEL TERMAS EL SOSNEADO	5613	0	13
17572	JAGUEL AMARILLO	5611	0	13
17573	JAGUEL DE LAS CHILCAS	5509	0	13
17574	PUERTO ALMIRON	3281	0	8
17575	JAGUEL DE ROSAS	5611	0	13
17576	JAGUEL DEL CATALAN	5611	0	13
17577	JAGUEL DEL GAUCHO	5613	0	13
17578	PUERTO COLORADO	3280	0	8
17579	JAGUEL DEL GOBIERNO	5613	0	13
17580	JAGUEL	5611	0	13
17581	JUNTA DE LA VAINA	5613	0	13
17582	LA BANDERA	5613	0	13
17583	LA BARDA CORTADA	5613	0	13
17584	LA CORTADERA	5613	0	13
17585	LA ESTRECHURA	5613	0	13
17586	LA JUNTA	5613	0	13
17587	LA NEGRITA	5613	0	13
17588	LA SALINILLA	5613	0	13
17589	LA YESERA	5613	0	13
17590	LAGUNA NEGRA	5613	0	13
17591	LAGUNA SALADA	5613	0	13
17592	LAS LOICAS	5613	0	13
17593	LAS YEGUAS	5613	0	13
17594	LLANO BLANCO	5611	0	13
17595	LOMA EXTENDIDA	5613	0	13
17596	LOMAS ALTAS	5613	0	13
17597	LOMAS CHICAS	5613	0	13
17598	LONCO VACAS	5613	0	13
17599	LOS BARRIALES	5613	0	13
17600	LOS CARRIZALES	5613	0	13
17601	LOS COLADOS	5613	0	13
17602	LOS POZOS	5613	0	13
17603	LOS RAMBLONES	5611	0	13
17604	MALAL DEL MEDIO	5611	0	13
17605	MALLIN QUEMADO	5613	0	13
17606	MATANCILLA	5613	0	13
17607	MATONCILLA	5611	0	13
17608	MECHANQUIL	5613	0	13
17609	MINA ARGENTINA	5613	0	13
17610	MINA ETHEL	5613	0	13
17611	SANTA ROSA	3252	0	8
17612	MINA HUEMUL	5613	0	13
17613	MINA SANTA CRUZ	5613	0	13
17614	MOLINO	5613	0	13
17615	NIRE CO	5611	0	13
17616	SEXTO DISTRITO COLON	3287	0	8
17617	P PLANCHON	5613	0	13
17618	PATA MORA	5613	0	13
17619	PAYUN	5613	0	13
17620	PO DEL HUANACO	5613	0	13
17621	PO MALLAN	5613	0	13
17622	PO PEHUENCHE	5613	0	13
17623	PORTEZUELO CHOIQUE	5613	0	13
17628	ARROYO EL MOCHO	3212	0	8
17629	ARROYO HONDO	3216	0	8
17631	ARROYO LA VIRGEN	3212	0	8
17632	ARROYO MOREIRA	3181	0	8
17635	ALTO ALEGRE	3634	0	9
17636	PUESTO AGUA AMARGA	5613	0	13
17640	PUESTO ATAMISQUI	5613	0	13
17641	PUESTO GENDARMERIA NACIONAL PO	5613	0	13
17642	PUESTO LA VENTANA	5613	0	13
17643	PUESTO LORETO	5621	0	13
17644	PUESTO RINCON ESCALONA	5611	0	13
17645	QUIRCACO	5613	0	13
17646	RINCON CHICO	5613	0	13
17647	CAMPO DOMINGUEZ	3212	0	8
17648	RINCON DE LA RAMADA CHATO	5613	0	13
17649	RINCON ESCONDIDO	5613	0	13
17650	LA ARGENTINA	3714	0	4
17651	BAJO VERDE	3634	0	9
17652	TOSCAL DEL TORO	5613	0	13
17653	CARPINCHORIS	3183	0	8
17654	V N DE COCHIQUITA	5613	0	13
17655	VEGA FERRAINA	5549	0	13
17656	ARAGANITA	5569	0	13
17657	LA CHINA	3714	0	4
17658	BAJADA DE LA SALADA	5569	0	13
17659	BAJADA DE LOS GAUCHOS	5569	0	13
17660	BAJADA DE LOS PAPAGAYOS	5569	0	13
17661	BAJADA DE YAUCHA	5569	0	13
17662	BAJADA DEL AGUA ESCONDIDA	5569	0	13
17663	BAJADA DEL FUERTE	5569	0	13
17664	LA ILUSION	3714	0	4
17665	BA	5569	0	13
17666	BA	5569	0	13
17667	COPACABANA	2919	0	21
17668	BORDO AMARILLO DE LA CRUZ PIED	5569	0	13
17669	BORDO EL ALGARROBO	5569	0	13
17670	LA PALOMA	3714	0	4
17671	BORDO LECHUZO	5569	0	13
17672	BORDOS DEL PLUMERILLO	5569	0	13
17673	CAMP VIZCACHERAS YPF	5569	0	13
17674	CASAS VIEJAS	5569	0	13
17675	LA PINTA	3714	0	4
17676	CERRITO MORO	5569	0	13
17677	CIENAGA DEL ALTO	5569	0	13
17678	CAMPO EL SURI	3634	0	9
17679	CASILLAS	3460	0	7
17680	LA PROVIDENCIA	3714	0	4
17681	COLONIA JORGE FINK	3181	0	8
17682	CAPIRARI	3465	0	7
17683	CERRO ALTO DE LAS PE	5569	0	13
17684	CERRO LOS BAJOS	5569	0	13
17685	LA SARA	3714	0	4
17686	CERRO PIEDRA COLORADA	5569	0	13
17687	CERRO AGUA NEGRA	5569	0	13
17688	CERRO ALVARADO CENTRO	5569	0	13
17689	CHAQUITO	3465	0	7
17690	CERRO ARROYO HONDO	5569	0	13
17691	CERRO BALEADO	5569	0	13
17692	LA TRANQUILIDAD	3714	0	4
17693	CERRO BARBARAN O TRES PICOS	5569	0	13
17694	EL 	3460	0	7
17695	CERRO CHATO	5569	0	13
17696	LAS CARPAS	3714	0	4
17697	CERRO COLORADO DE LAS LAGUNILL	5569	0	13
17698	LAS DELICIAS	3714	0	4
17699	CERRO COLORADO	5569	0	13
17700	LAS FLORES	3714	0	4
17701	CERRO DE LA BANDEROLA	5569	0	13
17702	CERRO DE LOS LEONES	5569	0	13
17703	COLONIA LOS SAUCES	3200	0	8
17704	CERRO DEL POZO	5569	0	13
17705	CERRO DEL ZORRO	5569	0	13
17706	CERRO DIVISADERO DE LA CIENEGU	5569	0	13
17707	LOS MAGOS	3714	0	4
17708	CERRO FIERO	5569	0	13
17709	CERRO GASPAR	5569	0	13
17710	CERRO GUADALOSO	5569	0	13
17711	CERRO LA INVERNADA	5569	0	13
17712	LOS TIGRES	3714	0	4
17713	CERRO LAS PIEDRAS	5569	0	13
17714	CERRO LOS BARROS	5569	0	13
17715	ESTANCIA EL CHA	3460	0	7
17716	CERRO NEGROS DE LAS MESILLAS	5569	0	13
17717	CERRO PLOMO	5569	0	13
17718	LOS TOBAS	3714	0	4
17719	CERRO POTRERILLOS	5569	0	13
17720	COLONIA ALAZANES	5569	0	13
17721	COLONIA ASPERA	5569	0	13
17722	COLONIA CHALET	5569	0	13
17723	COLONIA COLINA	5569	0	13
17724	LOTE 33	3714	0	4
17725	COLONIA CURNI	5569	0	13
17726	COLONIA DE LOS GUANAQUEROS	5569	0	13
17727	COLONIA DEL LEON	5569	0	13
17728	ESTANCIA LOS PARAISOS	3460	0	7
17729	MADRE DE DIOS	3714	0	4
17730	ESTANCIA SAN JULIO	3460	0	7
17731	COLONIA DIVISADERO DEL CARDAL	5569	0	13
17732	COLONIA DIVISADERO NEGRO	5569	0	13
17733	NUEVA YORK	3714	0	4
17734	COLONIA DURAZNO	5569	0	13
17735	GUAYCURU	3465	0	7
17736	COLONIA SANTA ROSA	3634	0	9
17737	COLONIA EL CAMPANARIO	5569	0	13
17738	COLONIA GUADAL	5569	0	13
17739	LA CA	3460	0	7
17740	COLONIA GUANACO	5569	0	13
17741	COLONIA LOLA	5569	0	13
17742	COLONIA LOS HUEVOS	5569	0	13
17743	COLONIA MIRADOR	5569	0	13
17744	COLONIA MURALLA	5569	0	13
17745	PALO BLANCO	3714	0	4
17746	LA CAUTIVA	3460	0	7
17747	COLONIA NACIONAL DE LOS INDIOS	5569	0	13
17748	COLONIA NEGRO	5569	0	13
17749	COLONIA OSAMENTA	5569	0	13
17750	LA FLOR	3461	0	7
17751	COLONIA PAPAL	5569	0	13
17752	PAMPA BOLSA	3714	0	4
17753	COLONIA PEDERNALES	5569	0	13
17754	COLONIA PENCAL	5569	0	13
17755	LA FLORENTINA	3461	0	7
17756	COLONIA PICO COLORADO	5569	0	13
17757	COLONIA SAN AGUSTIN	5569	0	13
17758	LA FORTUNA	3461	0	7
17759	COLONIA TORRECILLAS	5569	0	13
17760	PAMPA CABURE	3714	0	4
17761	LA LEONTINA	3466	0	7
17762	ACHAVAL RODRIGUEZ	2344	0	21
17763	COLONIA TORRECITO	5569	0	13
17764	LABORY	3460	0	7
17765	COLONIA TRES ALTITOS	5569	0	13
17766	PAMPA EL FOSFORITO	3714	0	4
17767	CONTROL YPF	5569	0	13
17768	LAS LOMAS	3461	0	7
17769	EL ACHERAL	3634	0	9
17770	CRUZ DE PIEDRA PTO GENDARMERIA	5569	0	13
17771	DIVISADERO COLORADO	5569	0	13
17772	EL CEPILLO	5569	0	13
17773	LAS VIOLETAS	3466	0	7
17774	EL GUADAL DE CAMPOS	5569	0	13
17775	EL LECHUCITO	5569	0	13
17776	PAMPA EL MANGRULLO	3714	0	4
17777	EL PARRAL	5569	0	13
17778	LOS TRES AMIGOS	3461	0	7
17779	EL PUMA	5569	0	13
17780	MARIA	3461	0	7
17781	EL RINCON	5569	0	13
17782	ESTANCIA AGUANDA	5569	0	13
17783	ESTANCIA ARROYO HONDO	5569	0	13
17784	PAMPA EL MOLLAR	3714	0	4
17785	EL AIBALITO	3634	0	9
17786	ESTANCIA CASAS VIEJAS	5569	0	13
17787	ESTANCIA LA PUMA	5569	0	13
17788	PAMPA PELADO	3714	0	4
17789	ESTANCIA VILUCO	5569	0	13
17790	ESTANCIA YAUCHA	5569	0	13
17791	HUAIQUERIA DE LA HORQUETA	5569	0	13
17792	HUAIQUERIA DE LOS BURROS	5569	0	13
17793	PAMPA PEREYRA	3714	0	4
17794	ISLA DEL CUCHILLO	5569	0	13
17795	J CAMPOS	5569	0	13
17796	J VERON	5569	0	13
17797	L PRADO	5569	0	13
17798	LA ARGENTINA	5569	0	13
17799	LA JAULA	5569	0	13
17800	EL BORDO SANTO	3634	0	9
17801	LA PICAZA	5569	0	13
17802	LAS MINAS	5569	0	13
17803	LAS PE	5569	0	13
17804	LOMA ALTA	5569	0	13
17805	PAMPA QUIMILI	3714	0	4
17806	LOMA DEL CERRO ASPERO	5569	0	13
17807	EL BRAGADO	3634	0	9
17808	LOMA DEL MEDIO	5569	0	13
17809	LOMA NEGRA GRANDE	5569	0	13
17810	PAMPA RALERA	3714	0	4
17811	COLONIA DOS ROSAS Y LA LEGUA	2349	0	21
17812	LOMA NEGRA	5569	0	13
17813	EL CA	3634	0	9
17814	LOMA PELADA	5569	0	13
17815	PAMPA VIRGEN	3714	0	4
17816	LOMITA LARGA	5569	0	13
17817	LOMITA MORADA	5569	0	13
17818	NINA	3461	0	7
17819	LOS ALAMOS	5569	0	13
17820	LOS PARAMILLOS	5569	0	13
17821	MESETA COLORADA	5569	0	13
17822	PARAJE INDEPENDENCIA	3714	0	4
17823	MINA VOLCAN OVERO	5569	0	13
17824	NUEVA GRANADA	3461	0	7
17825	EL CAVADO	3634	0	9
17826	MORRO DEL CUERO	5569	0	13
17827	PAMPA DE LOS BAYOS	5569	0	13
17828	PALMITAS	3461	0	7
17829	PASO DE LAS CARRETAS	5569	0	13
17830	PICOS BAYOS	5569	0	13
17831	PARAJE KILOMETRO 77	3714	0	4
17832	PARAISO	3460	0	7
17833	EL CORRALITO	3634	0	9
17834	PAMPA DE LAS YARETAS	5569	0	13
17835	EL MARCADO	3634	0	9
17836	PARAJE OJO DE AGUA	3714	0	4
17837	PIRCAS DE OSORIO	5569	0	13
17838	PARAJE SANTA CRUZ	3714	0	4
17839	PO ALVARADO NORTE	5569	0	13
17840	EL MOJON	3634	0	9
17841	PO ALVARADO SUR	5569	0	13
17842	EL PALO SANTO	3634	0	9
17843	PO AMARILLO	5569	0	13
17844	PO DE LOS ESCALONES	5569	0	13
17845	EL PARAISO	3634	0	9
17846	PO MAIPU	5569	0	13
17847	PORTILLO CRUZ DE PIEDRA	5569	0	13
17848	EL PILON	3634	0	9
17849	PORTILLO DE COLINA	5569	0	13
17850	SAN AGUSTIN	3714	0	4
17851	ESTANCIA SAN FRANCISCO	2344	0	21
17852	PORTILLO DE LA G  DEL CAMINO	5569	0	13
17853	PASO DE LAS PIEDRAS	3460	0	7
17856	EL EMBALSADO	3183	0	8
17858	SAN ANTONIO	3714	0	4
17861	PASO LOPEZ	3460	0	7
17863	PORTILLO CANALES	5569	0	13
17865	PUENTE AVALOS	3461	0	7
17866	RINCON	3460	0	7
17867	SAN JOSE	3714	0	4
17870	SAN CELESTINO	3466	0	7
17877	SAN PEDRO	3461	0	7
17879	SAN RAFAEL	3461	0	7
17880	SAN LUIS	3714	0	4
17883	SANTA MARIA	3466	0	7
17884	PUESTO A MARTINEZ	5569	0	13
17885	SANTA ROSA	3466	0	7
17886	PUESTO AGUA DE LA ZORRA	5569	0	13
17887	PUESTO DE LA SALADA	5569	0	13
17888	PUESTO EL JAGUAL	5569	0	13
17889	PUESTO F TELLO	5569	0	13
17890	SAN MARTIN	3714	0	4
17891	PUESTO HORQUETA	5569	0	13
17892	PUESTO J ALVAREZ	5569	0	13
17893	PUESTO LAS AGUADAS	5569	0	13
17894	SAN TELMO	3714	0	4
17895	PUESTO LAS CORTADERAS	5569	0	13
17896	PUESTO LOS RAMBLONES	5569	0	13
17897	PUESTO MANGA DE ARRIBA	5569	0	13
17898	PUESTO NIEVES NEGRAS	5569	0	13
17899	EL REMANSO	3634	0	9
17900	JORGE FINK	3181	0	8
17901	SANTA AGUEDA	3714	0	4
17902	PUESTO P MIRANDA	5569	0	13
17903	PUESTO PUNTA DEL AGUA	5569	0	13
17904	EL SIMBOLAR	3634	0	9
17905	PUESTO QUIROGA	5569	0	13
17906	PUESTO S PEREZ	5569	0	13
17907	PUESTO ULTIMA AGUADA	5569	0	13
17908	R BARRI	5569	0	13
17909	SANTA ELENA	3714	0	4
17910	EL SOMBRERO NEGRO	3634	0	9
17911	REAL BAYO	5569	0	13
17912	REAL DE MOYANO	5569	0	13
17913	EL SURR	3634	0	9
17914	REAL DEL COLORADO	5569	0	13
17915	SANTA ROSA	3714	0	4
17916	REAL DEL LEON	5569	0	13
17917	REAL DEL PELAMBRE	5569	0	13
17918	SANTA TERESA DE CARBALLO	3714	0	4
17919	REAL LOMA BLANCA	5569	0	13
17920	URUNDEL	3714	0	4
17921	REAL ESCONDIDO	5569	0	13
17922	KILOMETRO 11	3203	0	8
17923	REAL PIEDRA HORADADA	5569	0	13
17924	REAL PRIMER RIO	5569	0	13
17925	REAL RINCON DE LAS OVEJAS	5569	0	13
17926	EL YULO	3634	0	9
17927	REFUGIO LA FAJA	5569	0	13
17928	REFUGIO VIALIDAD	5569	0	13
17929	RINCON HUAIQUERIAS	5569	0	13
17930	CABRAL	3730	0	4
17931	RIVAS	5569	0	13
17932	S ESTRELLA	5569	0	13
17933	VIUDA DE SATELO	5569	0	13
17934	VEGA DE PRASO	5569	0	13
17935	VEGAS DE LAS OVEJAS	5569	0	13
17936	VOLCAN MAIPU	5569	0	13
17937	KILOMETRO 24	3203	0	8
17940	CAMPO FERRANDO	3730	0	4
17942	ALBERTO FLORES	5582	0	13
17943	AZCURRA	5582	0	13
17944	EX FORTIN SOLA	3634	0	9
17945	KILOMETRO 32	3200	0	8
17946	BALDE DE LA JARILLA	5582	0	13
17947	BALDE DE LOS GAUCHOS	5582	0	13
17948	BALDE JOFRE	5582	0	13
17949	EX POSTA GENERAL LAVALLE	3634	0	9
17950	BALDE LA PICHANA VIEJA	5582	0	13
17951	BALDE LAS CARPAS	5582	0	13
17952	BALDE LAS CATITAS	5582	0	13
17953	KILOMETRO 329	3212	0	8
17954	COLONIA BARRERA	3730	0	4
17955	BALDE SAN AGUSTIN	5582	0	13
17956	BALDE E AQUERA	5582	0	13
17957	LOLA MORA	5582	0	13
17958	COLONIA MONTE CASEROS	5582	0	13
17959	EL PLUMERO	5582	0	13
17960	EL PUNTIAGUDO	5582	0	13
17961	KILOMETRO 33	3203	0	8
17962	FLORINDO FLORES	5582	0	13
17963	ISABEL FLORES	5582	0	13
17964	LA PICHANA	5582	0	13
17965	COLONIA LOS ZAPALLOS	3003	0	21
17966	LA VERDE	5582	0	13
17967	LAS TORRECITAS	5582	0	13
17968	LOS AHUMADOS	5582	0	13
17969	LOS TORDILLOS	5582	0	13
17970	KILOMETRO 333	3212	0	8
17971	COLONIA SCHMIDT	3730	0	4
17972	MASA	5582	0	13
17973	PUESTO LA FLORIDA	5582	0	13
17974	PUESTO LAS JUNTITAS	5582	0	13
17975	PUESTO LAS PICHANAS	5582	0	13
17976	KILOMETRO 342	3200	0	8
17977	PUESTO LAS VIBORAS	5582	0	13
17979	PUESTO LOS CAUSES	5582	0	13
17980	KILOMETRO 355	3216	0	8
17981	EL PICASO	3730	0	4
17982	PUESTO LOS GAUCHOS	5582	0	13
17983	KILOMETRO 373	3214	0	8
17984	PUESTO SAN JOSE	5582	0	13
17985	PUESTO SAN MIGUEL	5582	0	13
17986	BERNACHEA	3418	0	7
17987	PUESTO SANTA MARIA	5582	0	13
17988	PUESTO VEGA	5582	0	13
17990	CA	3418	0	7
17991	KILOMETRO 376	3214	0	8
17992	TAPERA NEGRA	5582	0	13
17996	COLONIA BROUGNES	3418	0	7
17998	INDIA MUERTA	3730	0	4
18000	COSTA DE EMPEDRADO	3416	0	7
18002	KILOMETRO 6	3201	0	8
18004	EMPEDRADO LIMPIO	3418	0	7
18005	LA LIBERTAD	3634	0	9
18006	IPORA GUAZU	3730	0	4
18007	LA MANIJA	3634	0	9
18008	KILOMETRO 476	3416	0	7
18009	LOS GUALCOS	3730	0	4
18010	LA MEDIA LUNA	3634	0	9
18011	KILOMETRO 485	3416	0	7
18012	ALTO CON ZAMPA	5594	0	13
18013	LA NOBLEZA	3634	0	9
18014	ARANCIBIA	5594	0	13
18015	ARANZABAL	5594	0	13
18016	B DE ARAYA	5594	0	13
18017	B DE QUEBRADO	5594	0	13
18018	KILOMETRO 492	3416	0	7
18019	BAJO DEL YUYO	5594	0	13
18020	BALDE LAS LAGUNITAS	5594	0	13
18021	LOTE 77	3730	0	4
18022	BALDE NUEVO	5594	0	13
18023	BANDERITA	5594	0	13
18024	MANSION DE INVIERNO	3418	0	7
18025	BELLE VILLE	5594	0	13
18026	OCANTO CUE	3418	0	7
18027	BORDE DE LA LINEA	5594	0	13
18028	LA PALMITA	3634	0	9
18029	PAGO POI	3418	0	7
18030	CASA DE ADOBE	5594	0	13
18031	LA PRIMAVERA	3634	0	9
18032	CHILOTE	5594	0	13
18033	CLODOMIRO RETA	5594	0	13
18034	PUEBLITO SAN JUAN	3416	0	7
18035	COLONIA SAN JORGE	5594	0	13
18036	LA REPRESA	3634	0	9
18037	PAMPA AVILA	3730	0	4
18038	CRISTOBAL LOPEZ	5594	0	13
18039	D LOPEZ	5594	0	13
18040	RAMONES	3427	0	7
18041	DIVISADERO	5594	0	13
18042	EL ALGARROBO	5594	0	13
18043	EL BONITO	5594	0	13
18044	EL CABAO VIEJO	5594	0	13
18045	EL CARMEN	5594	0	13
18046	SECCION PRIMERA SAN JUAN	3416	0	7
18047	EL CHACALLAL	5594	0	13
18048	EL CORBALNO	5594	0	13
18049	EL DIVISADERO	5594	0	13
18050	VILLA SAN JUAN	3418	0	7
18051	EL ESCONDIDO	5594	0	13
18052	PEHUAHO	3416	0	7
18053	EL GORGINO	5594	0	13
18054	EL GUANACO	5594	0	13
18055	PAMPA CEJAS	3730	0	4
18056	EL LEMINO	5594	0	13
18057	EL MARCADO	5594	0	13
18058	EL MARUCHO	5594	0	13
18059	EL MAURINO	5594	0	13
18060	EL MOLINO	5594	0	13
18061	EL PLUMERO	5594	0	13
18062	LAMADRID	3634	0	9
18063	EL PORVENIR	5594	0	13
18064	EL RETAMOSO	5594	0	13
18065	EL TAMARINDO	5594	0	13
18066	LAS AVISPAS	3634	0	9
18067	EL VALLE	5594	0	13
18068	PAMPA DEL CIELO	3730	0	4
18069	EL ZAMPAL	5594	0	13
18070	LAS BOLIVIANAS	3634	0	9
18071	EL ZORZAL	5594	0	13
18072	EMILIANO LUCERO	5594	0	13
18073	ERNESTO LOPEZ	5594	0	13
18074	ESCUDERO	5594	0	13
18075	ESTANCIA GIL	5594	0	13
18076	ESTANCIA EL BONITO	5594	0	13
18077	LOS CLAVELES	3601	0	9
18078	PAMPA FLORES	3730	0	4
18079	ESTANCIA LA CHU	5594	0	13
18080	FELIPE PEREZ	5594	0	13
18081	CRUZ GIMENEZ	5594	0	13
18082	LOS GALPONES	3634	0	9
18083	LOS NIDOS	3634	0	9
18084	HUAICOS DE RUFINO	5594	0	13
18085	JARILLOSO	5594	0	13
18086	JOFRE	5594	0	13
18087	JOSE CAMPOS	5594	0	13
18088	JOSE SOSA	5594	0	13
18089	LOS POCITOS	3634	0	9
18090	KILOMETRO 947	5594	0	13
18091	L DEL AGUERO	5594	0	13
18092	CICARELLI	2500	0	21
18093	L PEREZ	5594	0	13
18094	LA ANGELINA	5594	0	13
18095	LA ARGENTINA	5594	0	13
18096	LA CHUNA	5595	0	13
18097	LA CIENAGUITA	5594	0	13
18098	LA CLARITA	5594	0	13
18099	LA FLORIDA	5594	0	13
18100	LA JACINTO	5594	0	13
18101	LOS SAUER	3200	0	8
18102	LA LAGUNITA	5594	0	13
18103	LA PORTE	5594	0	13
18104	LA SOMBRILLA	5594	0	13
18105	LAS ARABIAS	5594	0	13
18106	MIGUEL CANE	3634	0	9
18107	LAS GATITAS	5594	0	13
18108	LAS RAJADURAS	5594	0	13
18109	LAS VAYAS	5594	0	13
18110	LEZCANO	5594	0	13
18111	LIRA	5594	0	13
18112	LOMA DEL CHA	5594	0	13
18113	MISION EL CARMEN	3634	0	9
18114	LOMAS BLANCAS	5594	0	13
18115	LOMAS COLORADAS	5594	0	13
18116	LOS MEDANOS NEGROS	5594	0	13
18117	MISION EVANGELICA LAG YACARE	3634	0	9
18118	LOS MOROS	5594	0	13
18119	LOS VERDES	5594	0	13
18120	LOS YOLES	5594	0	13
18121	EL LUQUINO	5594	0	13
18122	PASO DEL GALLO	3212	0	8
18123	NUEVO PILCOMAYO	3630	0	9
18124	MATURANA	5594	0	13
18125	MELITON CAMPOS	5594	0	13
18126	MIGUEZ	5594	0	13
18127	MORON CHICO	5594	0	13
18128	MORON VIEJO	5594	0	13
18129	PASO MARGARI	3200	0	8
18130	N ZAPATA	5594	0	13
18131		5595	0	13
18132	NAVARRO	5594	0	13
18133	OLEGARIO VICTOR ANDRADE	3630	0	9
18134	P ROSALES	5594	0	13
18135	PE	5594	0	13
18136	PONCE	5594	0	13
18137	PALMA SOLA	3636	0	9
18138	PUESTO EL TRUENO	5594	0	13
18139	PASO SOCIEDAD	3181	0	8
18140	PUESTO GARCIA	5594	0	13
18141	PUESTO LORCA	5594	0	13
18142	PUESTO SAN VICENTE	5594	0	13
18143	PUNTA DEL CANAL	5594	0	13
18144	R BUSTOS	5594	0	13
18145	RODRIGUEZ	5594	0	13
18146	SAN PEDRO	5594	0	13
18147	SANTA ANA	5594	0	13
18148	SANTA MARIA	5594	0	13
18149	SANTO DOMINGO	5594	0	13
18150	T OROZCO	5594	0	13
18151	TALQUENCA	5594	0	13
18152	URISA	5594	0	13
18153	EL MANZANO HISTORICO	5560	0	13
18154	DOCTOR ANTONIO SOOMAS	5560	0	13
18155	LAS TROJAS	2500	0	21
18156	PONCHO QUEMADO	3634	0	9
18157	PAMPA GAMBA	3700	0	4
18158	POSTA LENCINA	3634	0	9
18159	PUNTAS DE MOREIRA	3181	0	8
18160	POZO DE LAS BOTIJAS	3634	0	9
18161	QUEBRACHO	3212	0	8
18162	POZO DE MAZA	3634	0	9
18163	POZO DE PIEDRA	3634	0	9
18164	POZO DEL CUCHILLO	3634	0	9
18165	POZO DEL LEON	3634	0	9
18166	SAUCE NORTE	3183	0	8
18167	VILLA LA RIBERA	2500	0	21
18168	TRES MOJONES	3733	0	4
18169	SUBCENTRAL SANTA MARIA	3180	0	8
18170	VILLAMIL	3181	0	8
18171	TRES MONJES	3541	0	4
18172	VENADOS GRANDES	3733	0	4
18173	CAMPO LAS PUERTAS	3541	0	4
18174	KILOMETRO 344	3212	0	8
18175	CAMPO NUEVO	3541	0	4
18176	KILOMETRO 347	3200	0	8
18177	COLONIA EL CURUPI	3541	0	4
18178	PUERTO URQUIZA	3705	0	4
18179	SAN ANTONIO	3705	0	4
18180	ALDEA SAN FRANCISCO	3101	0	8
18181	LORO BLANCO	3718	0	4
18182	ALDEA SANTAFECINA	3103	0	8
18183	PAMPA ALSINA	3718	0	4
18184	PAMPA CUVALO	3718	0	4
18185	EL AGUILA	5636	0	13
18186	PAMPA GRANDE	3718	0	4
18187	CAMPO RIQUELME	3101	0	8
18188	PUESTO CARRIZO	3718	0	4
18240	SANTA TECLA	3302	0	7
18242	RUTA 9 KILOMETRO 72	2804	0	1
18243	LOTE 9 ESCUELA 140	6315	0	11
18244	LOS MORROS	8138	0	11
18245	LOTE 14	8138	0	11
18246	EL CINCO	8201	0	11
18249	FRANCISCO CASAL	6230	0	1
18251	BUCHANAN	1903	0	1
18252	CAMINO CENTENARIO KM 11500	1896	0	1
18253	IGNACIO CORREAS ARANA	1909	0	1
18254	JUAN VUCETICH EX DR R LEVENE	1894	0	1
18255	HORNOS	1739	0	1
18256	VILLA LAZA	7000	0	1
18257	CERRO DE LA GLORIA CANAL 15	7101	0	1
18260	LA CORINA	7114	0	1
18261	COLONIA BELLA VISTA	8000	0	1
18263	ESCRIBANO P NICOLAS	7135	0	1
18265	ESPARTILLAR	7135	0	1
18266	VILLA ROCH	7101	0	1
18267	SAN RAFAEL	7130	0	1
18269	EMILIO AYERZA	6628	0	1
18270	BASE AERONAVAL CMTE ESPORA	8107	0	1
18271	VILLA IGOLLO	2930	0	1
18272	SAUCE CORTO	7540	0	1
18273	ANDERSON	6621	0	1
18276	EL LUCERO	7513	0	1
18277	CAMPOMAR VI	1625	0	1
18278	LA CALETA	7609	0	1
18279	MAR DE COBO	7609	0	1
18296	GENERAL MANSILLA	1911	0	1
18302	ROBERTO PAYRO	1915	0	1
18307	SANTA ELENA	7609	0	1
18308	KILOMETRO 125	6600	0	1
18309	SAUCE GRANDE	8150	0	1
18310	PUERTO UBAJAY	3302	0	7
18312	12 DE AGOSTO	2701	0	1
18313	PILINCHO	3302	0	7
18314	LOS LAURELES	3302	0	7
18317	CAABI POI	3463	0	7
18318	CAMBIRETA	3302	0	7
18319	EL PLATA	3302	0	7
18320	BELGRANO	8201	0	11
18321	EL HUITRU	8201	0	11
18322	LA CHIRLANDIA	8203	0	11
18323	LOS OLIVOS	8203	0	11
18324	SAN ANTONIO	8203	0	11
18325	SAN ERNESTO	8203	0	11
18326	SAN SIMON	8200	0	11
18327	SANTA ELENA	8201	0	11
18328	SANTO DOMINGO	8203	0	11
18329	ESCUELA ALBERDI	3114	0	8
18330	ESTABLECIMIENTO EL CARMEN	3114	0	8
18331	ESTABLECIMIENTO LA ESPERANZA	3114	0	8
18332	ESTABLECIMIENTO LAS MARGARITAS	3114	0	8
18333	KILOMETRO 43	3116	0	8
18334	LIBERTADOR SAN MARTIN	3103	0	8
18335	LOS BURGOS APEADERO FCGU	3116	0	8
18336	PUENTE DE LAS PENCAS	3101	0	8
18338	LOTE 8 ESCUELA 141	6369	0	11
18339	PUENTE DEL DOLL	3101	0	8
18340	BOCA P 25	2600	0	21
18341	PUERTO DIAMANTE	3105	0	8
18342	PUERTO LAS CUEVAS	3101	0	8
18343	CHATEAUBRIAND	2600	0	21
18344	SANATORIO APEADERO FCGU	3101	0	8
18345	LA SIN NOMBRE	8203	0	11
18346	ESTACION TEODELINA	2600	0	21
18349	ALBARI	3183	0	8
18350	SANTA TERESA	6106	0	21
18351	BELLA UNION PARAJE	3206	0	8
18352	LA PASTORA	7500	0	1
18353	RICARDO LAVALLE	6312	0	11
18354	RABIOLA	2600	0	21
18355	VILLA ESTELA	2726	0	21
18356	CAMPO UBAJO	3560	0	21
18357	COLONIA LA ARGENTINA	3206	0	8
18358	COLONIA EL VEINTICINCO	3560	0	21
18359	COLONIA SAN RAMON	3229	0	8
18360	COLONIA YAGUARETE	3560	0	21
18361	COLONIA SANTA ELOISA	3206	0	8
18362	COLONIA SANTA ELVIRA	3229	0	8
18363	LAS ANINTAS	3560	0	21
18365	LAS CATALINAS	3560	0	21
18366	LA POMONA	6214	0	11
18367	BARRIO SAN JACINTO	2800	0	1
18368	LAS GARSITAS	3560	0	21
18369	ESTACION SANTA ANA	3206	0	8
18370	LA PRIMAVERA CHAMAICO	6214	0	11
18371	ESTANCIA LA FLORESTA	3206	0	8
18372	TRES BOCAS	3560	0	21
18373	ESTANCIA SALINAS	3229	0	8
18374	ESTANCIA SAN JOSE	3206	0	8
18375	COLONIA SAN ROQUE	3005	0	21
18376	EL CEIBO	3005	0	21
18377	COLONIA SANTA ELVIRA	6365	0	11
18378	EL GUSANO	3005	0	21
18379	EL PARA	3005	0	21
18380	FLORIDA	3229	0	8
18381	OMBU NORTE	3005	0	21
18382	FORTUNA	3183	0	8
18383	FRONTERAS	3185	0	8
18384	ASUNCION MARIA	3040	0	21
18385	COLONIA LOS PIOJOS	8201	0	11
18386	COLONIA SAN IGNACIO	8201	0	11
18387	GUARACO	8201	0	11
18388	EL SOMBRERERO	3046	0	21
18389	KILOMETRO 37	3204	0	8
18390	KILOMETRO 44	3204	0	8
18391	ESTANCIA LA CONSTANCIA	3040	0	21
18392	KILOMETRO 47	3206	0	8
18393	ESTANCIA PRUSIA	3040	0	21
18394	KILOMETRO 51	3206	0	8
18395	AGUSTONI	6361	0	11
18396	LA CAPILLA	3040	0	21
18397	DORILA	6365	0	11
18398	EL EUCALIPTO	6361	0	11
18399	KILOMETRO 84	3228	0	8
18400	EL SAUCE	6361	0	11
18401	MASCIAS	3041	0	21
18402	LA ELSA	6331	0	11
18403	LA MARIA	6361	0	11
18404	LA VERDE	6331	0	11
18405	TREBOLARES	6361	0	11
18406	LA BLANQUEADA	3224	0	8
18407	SCHIFFNER	2451	0	21
18410	LOTE 48 COLONIA MIXTA	3514	0	4
18411	LA SELVA	3185	0	8
18412	ALLENDE	3550	0	21
18413	LA SOLEDAD	3229	0	8
18414	LOS PARAISOS	3228	0	8
18415	CERRITO	3550	0	21
18416	MANDISOVI	3228	0	8
18417	LOTE 53 COLONIA MIXTA	3514	0	4
18418	MONTE CHICO	3206	0	8
18419	EL 38	3550	0	21
18420	MONTE VERDE	3228	0	8
18421	EL 44	3550	0	21
18422	NUEVA VIZCAYA	3212	0	8
18423	EL CINCUENTA	3550	0	21
18424	PUERTO ALGARROBO	3206	0	8
18425	EL BONETE	3550	0	21
18426	ESTANCIA LAS ISLETAS	8148	0	1
18427	LA FRATERNIDAD Y SANTA JUANA	3228	0	8
18429	PARAJE KILOMETRO 12	3550	0	21
18430	SURST	3228	0	8
18431	PUEBLO GOLONDRINA	3551	0	21
18432	BAJO HONDO	3705	0	4
18436	LA PASTORIL	6323	0	11
18483	ALVAREZ JONTE	1921	0	1
18484	LAS TAHONAS	1921	0	1
18485	LUIS CHICO	1917	0	1
18486	PANCHO DIAZ	1921	0	1
18487	BAJO VERDE	3705	0	4
18488	BERLIN	3705	0	4
18489	BOLSA GRANDE	3705	0	4
18490	CALIFORNIA	3705	0	4
18491	CAMPO EL AIBAL	3705	0	4
18492	CAMPO EL ONZA	3705	0	4
18493	CAMPO GRANDE	3705	0	4
18494	CAMPO OVEROS	3705	0	4
18495	BARRIO LAGUNA	8520	0	16
18496	COLONIA CABEZA DE BUEY	3705	0	4
18497	COLONIA EL ALAZAN	3705	0	4
18498	COLONIA ESPERANZA	3705	0	4
18499	COLONIA FORTUNI	3705	0	4
18500	COLONIA INDIGENA	3705	0	4
18501	COLONIA JUAN JOSE CASTELLI	3705	0	4
18502	COLONIA LA FLORIDA CHICA	3705	0	4
18503	COLONIA LA FLORIDA GRANDE	3705	0	4
18504	COLONIA MONTE QUEMADO	3705	0	4
18505	COLONIA SAN ANTONIO	3705	0	4
18506	COMANDANCIA FRIAS	3705	0	4
18507	CORRALITO	3705	0	4
18508	PICHI MERICO	6321	0	11
18509	DO	3705	0	4
18510	EL 15	3705	0	4
18511	EL AIBAL	3705	0	4
18512	EL ASUSTADO	3705	0	4
18513	EL DESIERTO	3705	0	4
18514	EL RECREO	3705	0	4
18515	EL SAUZAL	3705	0	4
18516	COLONIA 17 DE AGOSTO	8204	0	11
18517	EL SIMBOLAR	3705	0	4
18518	COLONIA LAS TRES PIEDRAS	8204	0	11
18519	DOS CHA	8204	0	11
18520	GERVASIO ORTIZ DE ROSAS	8204	0	11
18521	LA ESPERANZA	8204	0	11
18522	LOTE 11 BERNASCONI	8212	0	11
18523	LOTE 12	8204	0	11
18524	MARIA	8204	0	11
18525	NARCISO LEVEN	8204	0	11
18527	SAN BERNARDO	8204	0	11
18528	SAN FERNANDO	8204	0	11
18529	SAN JOSE	8204	0	11
18530	EL VISCACHERAL	3705	0	4
18531	ESTANCIA LOMA ALTA	3705	0	4
18532	EX FORTIN ZELAYA	3705	0	4
18533	EX FORTIN ARENALES	3705	0	4
18534	EX FORTIN COMANDANTE FRIAS	3705	0	4
18535	EX FORTIN LAVALLE	3705	0	4
18536	EX FORTIN PEREZ MILLAN	3705	0	4
18537	EX FORTIN WILDE	3705	0	4
18538	EX FORTIN ZELAVA	3705	0	4
18539	LA ARMONIA	3705	0	4
18540	LA CA	3705	0	4
18541	LA COSTOSA	3705	0	4
18542	LA ENTRADA	3705	0	4
18543	LA ESPERANZA	3705	0	4
18544	CAMPO DE LOS TOROS	6311	0	11
18545	LA ESTACION	3705	0	4
18546	LA FIDELIDAD	3705	0	4
18547	LA FLOJERA	3705	0	4
18548	LA GRINGA	3705	0	4
18549	LA INVERNADA	3705	0	4
18550	LA MEDIA LUNA	3705	0	4
18551	LA MORA	3705	0	4
18552	LA RINCONADA	3705	0	4
18553	LA SALTARINA	3705	0	4
18554	LA SOLEDAD	3705	0	4
18555	COLONIA LA CHISPA	6309	0	11
18556	LA ZANJA	3705	0	4
18557	COLONIA LAS VIZCACHERAS	6309	0	11
18558	COLONIA LOS TOROS	6311	0	11
18559	LAS BLANCAS	3705	0	4
18560	COLONIA SANTA ANA	6309	0	11
18561	LAS FLORES	3705	0	4
18562	LAS HACHERAS	3705	0	4
18563	LAS MARAVILLAS	3705	0	4
18564	LAS VERTIENTES	3705	0	4
18565	LOS BARRILES	3705	0	4
18566	LOS PORONGOS	3705	0	4
18568	LOS QUIRQUINCHOS	3705	0	4
18569	LOS TUNALES	3705	0	4
18570	LOTE OCHO	3705	0	4
18571	MIRAMAR	3705	0	4
18572	MISION ANGELICANA	3705	0	4
18573	LAS PIEDRAS	8134	0	16
18574	MOLLE MARCADO	3705	0	4
18575	MONTE CASEROS	3705	0	4
18576	RIO SALADO	8134	0	16
18577	NUEVA UNION	3705	0	4
18578	PRIMER DISTRITO	2840	0	8
18579	PALO MARCADO	3705	0	4
18580	PAMPA CASTRO	3705	0	4
18581	SEPTIMO DISTRITO	2840	0	8
18582	COLONIA EL DESTINO	6381	0	11
18583	PAMPA EL SILENCIO	3705	0	4
18584	LOTE 25 CONHELO	6381	0	11
18585	PAMPA LOS BEDOGNI	3705	0	4
18586	LOTE 25 ESCUELA 146	6381	0	11
18587	PAMPA MACHETE	3705	0	4
18588	TTE GRAL EMILIO MITRE	6381	0	11
18589	MEDANOS NEGROS	8134	0	16
18590	PAMPA TOLOSA CHICA	3705	0	4
18591	PAMPA TOLOSA GRANDE	3705	0	4
18592	PARAJE EL COLCHON	3705	0	4
18593	BUENA VISTA PARAJE	2840	0	8
18594	PASO DE LOS LIBRES	3705	0	4
18595	PARAJE EL COLORADO	3705	0	4
18596	CUATRO BOCAS	2840	0	8
18597	KILOMETRO 40	3705	0	4
18598	KILOMETRO 290	2841	0	8
18599	POZO DE LA LINEA	3705	0	4
18600	POZO DE LA MULA	3705	0	4
18601	POZO DE LA PAVA	3705	0	4
18602	KILOMETRO 303	2841	0	8
18604	POZO DE LA TUNA	3705	0	4
18605	KILOMETRO 306	2840	0	8
18606	POZO DE LOS SURIS	3705	0	4
18607	POZO DEL CINCUENTA	3705	0	4
18608	PUENTE PELLEGRINI	2840	0	8
18609	POZO DEL GATO	3705	0	4
18610	PUERTO BARRILES	2840	0	8
18611	POZO DEL GRIS	3705	0	4
18612	POZO DEL MOLLE	3705	0	4
18613	COLONIA TREQUEN	6220	0	11
18614	POZO DEL NEGRO	3705	0	4
18615	POZO DEL TALA	3705	0	4
18616	LA JUANITA	6212	0	11
18617	POZO DEL TIGRE	3705	0	4
18618	MALVINAS ARGENTINAS	6228	0	11
18620	RINCON DEL NOGOYA SUR	2840	0	8
18621	PUEBLO ALASSA	6212	0	11
18622	CUESTA DEL TERNERO	9210	0	16
18623	SAN HILARIO	6212	0	11
18624	POZO LA BREA	3705	0	4
18625	POZO LA OSCA	3705	0	4
18626	PUERTO LAVALLE	3705	0	4
18627	REDUCCION DE LA CANGAYE	3705	0	4
18628	REDUCC SAN BERNARDO DE VERTIZ	3705	0	4
18629	SEXTO DISTRITO	3155	0	8
18630	ROSALES	3705	0	4
18631	SAN AGUSTIN	3705	0	4
18632	SAN JUANCITO	3705	0	4
18633	SAN LORENZO	3705	0	4
18634	SANTA RITA	3705	0	4
18635	SANTO DOMINGO	3705	0	4
18636	SOL DE MAYO	3705	0	4
18637	ARBOL SOLO	6323	0	11
18638	TARTAGAL	3705	0	4
18639	BUTALO	6323	0	11
18640	TOLDERIAS	3705	0	4
18641	LA ESPERANZA	6323	0	11
18642	TRES POZOS	3705	0	4
18643	LA PU	6323	0	11
18644	LOS TURCOS	6323	0	11
18645	MEDANOS NEGROS	6323	0	11
18646	AERO CLUB CANAL	2823	0	8
18647	SAN FRANCISCO DE LA RAMADA	6323	0	11
18648	RIO AGUILA	2805	0	8
18649	ALDEA SAN JUAN	2826	0	8
18650	ALDEA SANTA CELIA	2826	0	8
18651	ARROYO BALTAZAR	1647	0	8
18652	ARROYO BALTAZAR CHICO	1647	0	8
18653	ARROYO BICHO FEO	1649	0	8
18654	ARROYO BOCA FALSA	1647	0	8
18655	ARROYO BRASILERO	2805	0	8
18656	ARROYO BRAVO GUTIERREZ	1647	0	8
18657	TUNQUELEN	8409	0	16
18658	ARROYO BRAZO CHICO	1647	0	8
18659	ARROYO BRAZO DE LA TINTA	1647	0	8
18660	ARROYO BUEN PASTOR	2823	0	8
18661	ARROYO CABALLO	2823	0	8
18662	ARROYO CARBON	1647	0	8
18663	ARROYO CARBONCITO	1647	0	8
18664	ARROYO CARPINCHO	1647	0	8
18665	ARROYO CEIBITO	1649	0	8
18666	ARTURO ALMARAZ	6330	0	11
18667	ARROYO CORRENTOSO	1647	0	8
18668	SAN JOAQUIN	6341	0	11
18669	ARROYO CUCHARAS	1649	0	8
18670	ARROYO CUZCO	1647	0	8
18671	COLONIA LA GAVIOTA	6354	0	11
18672	LA FORTUNA	6300	0	11
18673	LA MALVINA	6300	0	11
18674	ARROYO DE LA ROSA	1647	0	8
18675	LA GRANJA	8501	0	16
18676	LA ROSA	8133	0	11
18677	ARROYO DESAGUAD DEL GUTIERREZ	1647	0	8
18678	LA TOSCA	8138	0	11
18679	LOTE 17	8138	0	11
18680	ARROYO DESAGUADERO DEL SAUCE	1647	0	8
18681	LOTE 18	8138	0	11
18682	LOTE 19  COLONIA N LEVEN	8138	0	11
18683	ARROYO GARCETE	1649	0	8
18684	LOTE 22	8138	0	11
18685	LOTE 23	8138	0	11
18686	LOTE 24	8138	0	11
18687	ARROYO GUTIERREZ CHICO	1647	0	8
18688	LOTE 6	8138	0	11
18689	LOTE 7	8138	0	11
18690	LOTE 8	8138	0	11
18691	ARROYO IBICUYCITO	2805	0	8
18692	ARROYO LA PACIENCIA	2805	0	8
18693	LOTE 8  ESCUELA 179	8206	0	11
18694	SALINAS	8138	0	11
18695	ARROYO LA TINTA	1647	0	8
18696	ARROYO LARA	1649	0	8
18697	ARROYO LAS ANIMAS	1649	0	8
18698	ARROYO LLORONES	1649	0	8
18699	ARROYO LOS PLATOS	2805	0	8
18700	ARROYO MALAMBO	1647	0	8
18701	ARROYO MANZANO	1649	0	8
18702	ARROYO MERLO	1649	0	8
18703	ARROYO MOSQUITO	1649	0	8
18704	SANTA STELLA	6305	0	11
18705	ARROYO 	1647	0	8
18706	ARROYO NEGRO	1647	0	8
18707	ARROYO PACIENCIA CHICO	1647	0	8
18708	ARROYO PACIENCIA GRANDE	1647	0	8
18709	ARROYO PELADO	1647	0	8
18710	ARROYO PERDIDO CEIBO	1647	0	8
18711	ARROYO PERDIDO MOSQUITO	1647	0	8
18712	ARROYO PEREYRA	1649	0	8
18713	ARROYO PIEDRAS	1647	0	8
18714	ARROYO PITO	1649	0	8
18715	AMARFIL	5443	0	18
18716	CHA	5443	0	18
18717	ARROYO PLATITOS	1649	0	8
18718	CRUZ DE SAN PEDRO	5443	0	18
18719	ARROYO PRINCIPAL	2823	0	8
18720	DIAZ VELEZ	5443	0	18
18721	ARROYO SAGASTUME CHICO	1647	0	8
18722	LA RINCONADA	5443	0	18
18723	LAS HIGUERITAS	5443	0	18
18724	VALLECITO	5443	0	18
18725	ARROYO SALADO	2823	0	8
18726	AEROPUERTO SAN JUAN	5417	0	18
18727	COLONIA FIORITO	5417	0	18
18728	ARROYO SANCHEZ CHICO	2823	0	8
18729	ARROYO SANCHEZ GRANDE	2823	0	8
18730	EST ALBARDON	5419	0	18
18731	BA	5419	0	18
18732	CERRO BOLA	5419	0	18
18733	ARROYO SANTOS CHICO	1647	0	8
18734	ARROYO SANTOS GRANDE	1647	0	8
18735	POZO EL CHA	3705	0	4
18736	ARROYO TIROLES	1647	0	8
18737	CERRO VILLICUN	5419	0	18
18738	ARROYO VENERATO	2821	0	8
18739	TIERRA ADENTRO	5419	0	18
18740	ARROYO ZAPALLO	2823	0	8
18741	LA CA	5415	0	18
18742	RANCHOS DE FAMACOA	5415	0	18
18743	AGUA Y ENERGIA	5405	0	18
18744	BARREALES	5405	0	18
18745	CANAL NUEVO	1647	0	8
18746	BARRIALITOS	5403	0	18
18747	CAMPO DEL LEONCITO	5405	0	18
18748	CASTA	5405	0	18
18749	CERRO BAYO	5405	0	18
18750	CANAL PRINCIPAL	2823	0	8
18751	CERRO BLANCO	5405	0	18
18752	CERRO BONETE	5405	0	18
18753	CERRO BRAMADERO	5405	0	18
18754	CANAL SAN MARTIN	1647	0	8
18755	CERRO CHIQUERO	5405	0	18
18756	CERRO CORTADERA	5405	0	18
18757	CERRO DE LAS VACAS	5405	0	18
18758	POZO DEL TORO	3705	0	4
18759	CERRO DEL TOME	5405	0	18
18760	COLONIA EL POTRERO	2820	0	8
18761	CERRO GRANDE	5405	0	18
18762	CERRO GUANAQUERO	5405	0	18
18763	CERRO HORNITO	5405	0	18
18764	CERRO LA FORTUNA	5405	0	18
18765	COLONIA STAUWER	2820	0	8
18766	CERRO LAS MULAS	5405	0	18
18767	CERRO LOS PATOS	5405	0	18
18768	CERRO MERCEDARIO	5405	0	18
18769	CERRO MUDADERO	5405	0	18
18770	COSTA URUGUAY SUR	2821	0	8
18771	CERRO PANTEON	5405	0	18
18772	CERRO PICHEREGUAS	5405	0	18
18773	CERRO PUNTUDO	5405	0	18
18774	LA CUCHILLA	3716	0	4
18775	CUATRO BOCAS PARAJE	2820	0	8
18776	CERRO AMARILLO	5405	0	18
18777	LA FLECHA	3716	0	4
18779	CERRO DE LOS POZOS	5405	0	18
18780	LOTE 34	3706	0	4
18781	EL NUEVO RINCON	2820	0	8
18782	EL SAUCE	2823	0	8
18783	ESTANCIA EL TOTORAL	5405	0	18
18784	ESTANCIA LA PUNTILLA	5405	0	18
18785	ESTANCIA LEONCITO	5405	0	18
18786	EL LEONCITO	5405	0	18
18787	ESTANCIA CASA RIO BLANCO	5405	0	18
18788	ESTABLECIMIENTO SAN MARTIN	2823	0	8
18789	GENDARMERIA NACIONAL	5405	0	18
18790	LA ALUMBRERA	5405	0	18
18791	LA CAPILLA	5405	0	18
18792	LAS HORNILLAS	5405	0	18
18793	MANANTIALES	5405	0	18
18794	PACHACO	5405	0	18
18795	FEBRE	3151	0	8
18796	PE	5405	0	18
18797	MICHI HONOCA	8333	0	16
18798	LA CAPILLA	3246	0	8
18799	LA CHILENA CANAL	1647	0	8
18800	ZANJA LA CHILENA	1647	0	8
18801	PO DE BARAHONA	5405	0	18
18802	PO DE LAS LLARETAS	5405	0	18
18803	PO DE LAS OJOTAS	5405	0	18
18804	PO DE LOS PIUQUENES	5405	0	18
18805	PO DE LOS TEATINOS	5405	0	18
18806	PO DEL PORTILLO	5405	0	18
18807	PO DE LA GUARDIA	5405	0	18
18808	PORT DE LONGOMICHE	5405	0	18
18809	POTRERILLOS	5405	0	18
18810	PTO SANTA ROSA DE ABAJO	5405	0	18
18811	TIRA LARGA	5405	0	18
18812	TONTAL	5405	0	18
18813	YACIMIENTO DE COBRE EL PACHON	5405	0	18
18814	COLONIA BERMEJO	3509	0	4
18815	ZONDA	5401	0	18
18816	COLONIA EL CIERVO	3509	0	4
18817	COLONIA EL FISCAL	3509	0	4
18818	COLONIA ESPERANZA	3509	0	4
18819	COLONIA LA FILOMENA	3509	0	4
18820	COLONIA SABINA	3509	0	4
18821	COLONIA SAN ANTONIO	3509	0	4
18822	COLONIA TRES LAGUNAS	3509	0	4
18824	EL 15	3509	0	4
18825	EL PERDIDO	3509	0	4
18826	CHACRAS DE ALLEN	8328	0	16
18827	KILOMETRO 62	3509	0	4
18828	LOMA ALTA	3509	0	4
18829	LOMA FLORIDA	3509	0	4
18830	PAMPA CHICA	3509	0	4
18831	PAMPA LARGA	3509	0	4
18832	PARAJE LAS TABLAS	3509	0	4
18833	VILLA DOS	3509	0	4
18834	ZAPARINQUI	3705	0	4
18835	LOBOS ARROYO	1649	0	8
18836	BALDE DEL LUCERO	5446	0	18
18837	CERRO TIGRE	5442	0	18
18838	EL POZO DEL 20	5442	0	18
18839	GUAYAGUAS	5442	0	18
18840	KILOMETRO 810	5442	0	18
18841	LAS LIEBRES	5442	0	18
18842	LUCIENVILLE 1	2828	0	8
18843	LOS MELLIZOS	5442	0	18
18844	PUERTO ALEGRE	5442	0	18
18845	LUCIENVILLE 2	2828	0	8
18846	PUERTO TAPONES DE MAYA	5442	0	18
18847	LUCIENVILLE 3	2828	0	8
18848	APEADERO LAS CHIMBAS	5413	0	18
18849	LUCIENVILLE 4	2828	0	8
18850	LOS VI	5413	0	18
18851	EL MOGOTE CHIMBAS	5413	0	18
18852	VILLA P A DE SARMIENTO	5413	0	18
18853	PARAJE PALAVEROI	2805	0	8
18854	ACERILLOS	5467	0	18
18855	AGUA DE LA ZANJA	5467	0	18
18856	ARREQUINTIN	5467	0	18
18857	BA	5467	0	18
18858	BA	5467	0	18
18859	CAJON DE LOS TAMBILLOS	5467	0	18
18860	COLONIA CODUTTI	3513	0	4
18861	RIO PARANACITO	1647	0	8
18862	CARRIZALITO	5467	0	18
18863	COLONIA LUCINDA	3513	0	4
18864	CACHO ANCHO	5467	0	18
18865	CHAMPONES	5467	0	18
18866	CHAPARRO	5467	0	18
18868	CHIGUA DE ABAJO	5467	0	18
18869	CIENAGUILLOS	5467	0	18
18870	KILOMETRO 523	3505	0	4
18871	CERRO LAS YEGUAS	5467	0	18
18872	LA LUCINDA	3513	0	4
18873	CERRO BOLEADORA	5467	0	18
18874	LA NEGRA	3513	0	4
18875	CERRO BRAVO	5467	0	18
18876	LA RAQUEL	3513	0	4
18877	CERRO CORTADERA	5467	0	18
18878	RIO PASAJE AL AGUILA	2805	0	8
18879	CERRO  D  L  BA	5467	0	18
18880	CERRO DE CONCONTA	5467	0	18
18881	CERRO DE DOLORES	5467	0	18
18882	CERRO DE LA CUESTA DEL VIENTO	5467	0	18
18883	PASAJE TALAVERA	2804	0	8
18884	CERRO DE LOS BURROS	5467	0	18
18885	CERRO DEL AGUA DE LAS VACAS	5467	0	18
18886	CERRO DEL ALUMBRE	5467	0	18
18887	CERRO DEL CACHIYUYAL	5467	0	18
18888	CERRO DEL COQUIMBITO	5467	0	18
18890	CERRO DEL GUANACO	5467	0	18
18891	CERRO DEL SALADO	5467	0	18
18892	KILOMETRO 519	3513	0	4
18893	CERRO EL BRONCE	5467	0	18
18894	CERRO EL CEPO	5467	0	18
18895	CERRO EL FRANCES	5467	0	18
18896	CERRO ESPANTAJO	5467	0	18
18897	CERRO HEDIONDO	5467	0	18
18898	PESQUERIA DIAMANTINO	2820	0	8
18899	CERRO IMAN	5467	0	18
18900	CERRO JOAQUIN	5467	0	18
18901	CERRO LA BOLSA	5467	0	18
18902	CERRO LA ORTIGA	5467	0	18
18903	CERRO LAS MULITAS	5467	0	18
18904	CERRO LAVADEROS	5467	0	18
18905	CERRO LOS MOGOTES	5467	0	18
18906	PUENTE 	2823	0	8
18907	CABA	3703	0	4
18908	COLONIA ALELAY	3703	0	4
18909	EL DESTIERRO	3703	0	4
18910	KILOMETRO 855 ESTACION	3703	0	4
18911	CERRO NEGRO DE CHITA	5467	0	18
18912	LA MATANZA	3703	0	4
18913	CERRO NICO	5467	0	18
18914	CERRO OCUCAROS	5467	0	18
18915	CERRO PATA DE INDIO	5467	0	18
18916	CERRO PINTADO	5467	0	18
18917	CERRO POTRERITO DE AGUA BLANCO	5467	0	18
18918	RINCON DEL CINTO	2826	0	8
18919	CERRO SENDA AZUL	5467	0	18
18920	NTRA SE	3703	0	4
18921	CERRO SILVO	5467	0	18
18922	PAMPA ALELAI	3703	0	4
18923	PAMPA EL 11	3703	0	4
18924	PAMPA EL 12	3703	0	4
18925	TRES NACIONES	3703	0	4
18926	CERRO ALTO DEL DESCUBRIMIENTO	5467	0	18
18927	CERRO AMARILLO	5467	0	18
18928	CERRO CABALLO BAYO	5467	0	18
18929	CERRO COLORADO	5467	0	18
18930	RIO ALFEREZ NELSON PAGE	2805	0	8
18931	RIO CEIBO	2805	0	8
18932	CERRO DE LA SEPULTURA	5467	0	18
18933	CERRO LAGUNITA	5467	0	18
18934	CERRO LAS RAICES	5467	0	18
18935	CERRO LOS POZOS	5467	0	18
18936	CERRO SILVIO	5467	0	18
18938	RIO PARANA GUAZU	2805	0	8
18939	CONCOTA	5467	0	18
18940	DIVISADERO DE LA MUJER HELADA	5467	0	18
18941	RIO SAUCE	2805	0	8
18942	EL RETIRO	5467	0	18
18943	EL SALADO	5467	0	18
18944	FIERRO	5467	0	18
18945	FIERRO NUEVO	5467	0	18
18946	FIERRO VIEJO	5467	0	18
18947	RIO TALAVERA	2805	0	8
18948	FINCA EL TORO	5467	0	18
18949	HACHANGO	5467	0	18
18950	SAGASTUME	2823	0	8
18951	HUA	5467	0	18
18952	HUESO QUEBRADO	5467	0	18
18953	JAGUELITO	5467	0	18
18954	JARILLITO	5467	0	18
18955	JUNTA DE SANTA ROSA	5467	0	18
18956	EL CUARENTA Y SEIS	3703	0	4
18957	JUNTAS DE LA JARILLA	5467	0	18
18958	JUNTAS DE LA SAL	5467	0	18
18959	JUNTAS DEL FRIO	5467	0	18
18961	LA ANGOSTURA	5467	0	18
18962	LA CA	5465	0	18
18963	LA ESTRECHURA	5467	0	18
18964	LAS CASITAS	5467	0	18
18965	SAUCE RIO	1649	0	8
18966	LAS CUEVAS	5467	0	18
18967	LAS HIGUERAS	5467	0	18
18968	LAS PE	5467	0	18
18969	LA SUIZA	3540	0	4
18970	LOMAS BLANCAS	5467	0	18
18971	LOTE 10	3540	0	4
18972	LOS COGOTES	5467	0	18
18973	LOTE 12	3543	0	4
18974	LOS LOROS	5467	0	18
18975	LOS PENITENTES	5467	0	18
18976	TRES ESQUINAS	2820	0	8
18977	COLONIA LOTE 10	3540	0	4
18978	LOS SAPITOS	5467	0	18
18979	COLONIA LOTE 12	3543	0	4
18980	MAIPIRINQUI	5467	0	18
18981	COLONIA LOTE 3	3543	0	4
18982	MAJADITA	5449	0	18
18983	MALIMAN ARRIBA	5467	0	18
18984	MALIMAN DE ABAJO	5467	0	18
18985	COLONIA LA AVANZADA	3540	0	4
18986	MINA DE LAS CARACHAS	5467	0	18
18987	MONDACA	5467	0	18
18988	COLONIA LAS AVISPAS	3540	0	4
18989	OJOS DE AGUA	5467	0	18
18990	LA MANUELA	3540	0	4
18991	LA TAPERA	3540	0	4
18992	PASO DEL AGUA NEGRA	5467	0	18
18993	LA VIRUELA	3540	0	4
18994	LAS GOLONDRINAS SUR	3540	0	4
18995	PE	5467	0	18
18996	LAS MORERAS	3540	0	4
18997	PE	5467	0	18
18998	VILLA ELEONORA	2820	0	8
18999	TRES BOLICHES	3540	0	4
19000	PIEDRAS BLANCAS	5467	0	18
19001	COLONIA LOS GANZOS	3540	0	4
19002	PIRCAS BLANCAS	5467	0	18
19003	PIRCAS NEGRAS	5467	0	18
19004	LAS GOLONDRINAS	3540	0	4
19005	PISMANIA	5467	0	18
19006	PO CAJON DE LA BREA	5467	0	18
19007	PO DEL CHOLLAY	5467	0	18
19008	PO DEL INCA	5467	0	18
19009	PO LAS TORTOLAS	5467	0	18
19010	PORT SAN GUILLERMO	5467	0	18
19011	PORT DE LA PUNILLA	5467	0	18
19012	PORT LAS CARACACHAS	5467	0	18
19013	PORT SANTA ROSA	5467	0	18
19014	POTREROS LOS AMADORES	5467	0	18
19015	PTO GEN	5467	0	18
19016	EL EMPALME PARAJE	2846	0	8
19017	PUERTA DEL INFIERNILLO	5467	0	18
19018	QUILINQUIL	5467	0	18
19019	REFUGIO	5467	0	18
19020	LIBERTADOR GRAL SAN MARTIN	2846	0	8
19021	RINCON DE LA BREA	5467	0	18
19022	RINCON DE LA OLLITA	5467	0	18
19023	PUERTO IBICUY	2846	0	8
19024	RINCON DE LOS CHINCHILLEROS	5467	0	18
19025	ANAHI	2846	0	8
19026	RUINAS INDIGENAS	5467	0	18
19027	TAMBERIAS	5467	0	18
19028	ARROYO MARTINEZ	1647	0	8
19029	TERMAS CENTENARIO	5467	0	18
19030	TOCOTA	5467	0	18
19031	TRES QUEBRADITAS	5467	0	18
19032	TUTIANCA	5467	0	18
19033	ARROYO SAGASTUME GRANDE	1647	0	8
19034	VALLE DEL CURA	5467	0	18
19035	VENILLO	5467	0	18
19036	PUERTO MARQUEZ	3190	0	8
19037	CABRAL	3196	0	7
19038	EL CARMEN	3196	0	7
19039	ESTANCIA CAFFERATTA	3196	0	7
19040	AGUA DE LA ZORRA	5460	0	18
19041	ESTANCIA EL CARMEN	3196	0	7
19042	ARROYO CEIBO	3191	0	8
19043	ALGARROBO DEL CURA	5460	0	18
19044	ESTANCIA LAGUNA LIMPIA	3196	0	7
19045	ALMIRANTE BROWN	3701	0	4
19046	ARROYO HONDO	3190	0	8
19047	ASCHICHUSCA	5460	0	18
19049	BARRANCA DE LOS LOROS	5460	0	18
19050	ESTANCIA MARQUEZ LUI	3196	0	7
19051	BARRANCAS BLANCAS	5460	0	18
19052	LA CHACO	3701	0	4
19054	CAMPO LOS POZOS	5460	0	18
19055	LA CASUALIDAD	3196	0	7
19056	LAS CUATRO BOCAS	3701	0	4
19057	CASA VIEJA	5460	0	18
19058	LOTE 10	3701	0	4
19059	BA	3137	0	8
19060	CHA	5460	0	18
19061	LOTE 11	3701	0	4
19062	CHEPICAL	5460	0	18
19063	MALEZAL	3196	0	7
19064	PAMPA DE LAS FLORES	3701	0	4
19065	CERRO ASPERO	5460	0	18
19066	CERRO DE LOS CABALLOS	5460	0	18
19067	CERRO LA CA	5460	0	18
19068	MALVINAS NORTE	3196	0	7
19069	MALVINAS SUR	3199	0	7
19070	CERRO LAJITAS	5460	0	18
19071	FORTIN TOTORALITA LUGAR HISTOR	3701	0	4
19072	CERRO NEGRO DEL CORRAL	5460	0	18
19074	CERRO POTRERO	5460	0	18
19075	CERRO CABALLO ANCA	5460	0	18
19076	CERRO COLORADO	5460	0	18
19077	CERRO EL DURAZNO	5460	0	18
19078	CERRO IMAN	5460	0	18
19079	DIQUE CAUQUENES	5460	0	18
19080	BOCAS	3536	0	4
19082	EL CHACRERO	5460	0	18
19083	EL RAIGONAL	3536	0	4
19084	EL CHAMIZUDO	5460	0	18
19086	LOTE 4 COLONIA PASTORIL	3536	0	4
19087	EL CORRALITO	5460	0	18
19088	EL JABONCITO	5460	0	18
19089	CURANDU	3532	0	4
19090	EL MEDANO	5460	0	18
19092	EL PALMAR	3536	0	4
19093	EL QUEMADO	5460	0	18
19094	EL SALITRE	5460	0	18
19095	EL TAPON	5460	0	18
19096	EL TREINTA	5460	0	18
19097	EST NIQUIVIL	5460	0	18
19098	CENTENARIO LA PAZ	3263	0	8
19099	GUACHIPAMPA	5460	0	18
19100	HOSTERIA EL BALDE	5460	0	18
19101	INDIO MUERTO	5460	0	18
19102	LA CIENAGA DE CUMILLANGO	5460	0	18
19103	LA ESQUINA	5460	0	18
19104	LA ESTACA	5460	0	18
19105	LA LEGUA	5460	0	18
19106	LA TOMA	5460	0	18
19107	LA VALENTINA	5460	0	18
19108	COLONIA CARRASCO	3190	0	8
19109	LAS CIENAGAS VERDES	5460	0	18
19110	LAS ESPINAS	5460	0	18
19111	LAS PUESTAS	5460	0	18
19112	LOMA NEGRA	5460	0	18
19113	LOS PUESTOS	5460	0	18
19114	LOS TERREMOTOS	5460	0	18
19115	MINA DE GUACHI	5460	0	18
19116	MINA EL ALGARROBO	5460	0	18
19117	MINA EL PESCADO	5460	0	18
19118	MINA ESCONDIDA	5460	0	18
19119	ESTANCIA LA LOMA	3344	0	7
19120	MINA GENERAL BELGRANO	5460	0	18
19121	MINA LA ABUNDANCIA	5460	0	18
19122	COLONIA LAS GAMAS	3190	0	8
19123	MINA LA DELFINA	5460	0	18
19124	ESTANCIA LAS MAGNOLIAS	3344	0	7
19125	MINA LA ESPERANZA	5460	0	18
19126	ESTANCIA LAS TUNAS	3344	0	7
19127	COLONIA MAXIMO CASTRO	3190	0	8
19128	ALDEA FORESTAL	3530	0	4
19129	MINA LA SALAMANTA	5460	0	18
19130	COLONIA EL PARAISAL	3530	0	4
19131	MINA LOS CABALLOS	5460	0	18
19132	CUATRO BOCAS	3530	0	4
19133	MINA MONTOSA	5460	0	18
19134	MINA SAN ANTONIO	5460	0	18
19135	OJOS DE AGUA	5461	0	18
19136	EL PALMAR	3531	0	4
19137	PASLEAM	5460	0	18
19138	PASO DE OTAROLA	5460	0	18
19139	EL TACURUZAL	3530	0	4
19140	LA LOMA	3344	0	7
19141	PIEDRA PARADA	5460	0	18
19142	EL ZANJON	3530	0	4
19143	PO DE USNO	5460	0	18
19144	LA MAGNOLIA	3344	0	7
19145	PORTON GRANDE	5460	0	18
19146	LOTE 4 QUITILIPI	3530	0	4
19147	LAS MERCEDES	3344	0	7
19149	LAS PALMAS	3344	0	7
19150	COLONIA OFICIAL N 11	3190	0	8
19151	PTO AG DEL BURRO	5460	0	18
19152	LAS PALMITAS	3344	0	7
19153	PTO AGUADITA	5460	0	18
19154	PTO AGUADITA DE ABAJO	5460	0	18
19155	PAMPA LA PELIGROSA	3530	0	4
19156	PTO DURAZNO	5460	0	18
19157	PAMPA LEGUA CUATRO	3530	0	4
19158	PTO LA ESPINA	5460	0	18
19159	PTO LA REPRESA	5460	0	18
19160	PTO LA VIRGENCITA	5460	0	18
19161	PTO LOS ALAMOS	5460	0	18
19162	LAS PALMIRAS	3344	0	7
19163	PTO PAJARITO	5460	0	18
19164	PTO POTRERILLO	5460	0	18
19165	LOS ARBOLES	3344	0	7
19166	PTO TRAPICHE	5460	0	18
19167	MALEZAL	3344	0	7
19168	PTO CUMILLANGO	5460	0	18
19169	MIRA FLORES	3344	0	7
19170	PTO EL ARBOL LIGUDO	5460	0	18
19171	PTO EL SARCO	5460	0	18
19172	PTO EL TORO	5460	0	18
19173	PTO FIGUEROA	5460	0	18
19174	PARAJE SAN ISIDRO	3454	0	7
19175	PTO LA CHILCA	5460	0	18
19176	PTO MAJADITA	5460	0	18
19177	PTO PANTANITO	5460	0	18
19178	PTO PESCADO	5460	0	18
19179	PTO PIMPA	5460	0	18
19180	PTO PUNILLA	5460	0	18
19181	PTO SABATO	5460	0	18
19182	LOTE 43 ESCUELA 250	3530	0	4
19183	PTO SEGOVIA	5460	0	18
19184	PTO VALLECITO	5460	0	18
19185	PTO VAREJON	5460	0	18
19186	PTO ANJULIO	5460	0	18
19187	PTO LA CORTADERA	5460	0	18
19188	PTO LA TUNA	5460	0	18
19189	PTO LOS POZOS	5460	0	18
19190	PTO PERICO	5460	0	18
19191	PTO PORTEZUELO HONDO	5460	0	18
19192	PTO RECREO	5460	0	18
19194	RINCON COLORADO	5460	0	18
19195	RINCON DEL GATO	5460	0	18
19196	SAN ISIDRO	5461	0	18
19197	TAP GALLARDO	5460	0	18
19198	CA	3405	0	7
19199	TERMAS AGUA HEDIONDA	5460	0	18
19200	TERMAS DE AGUA NEGRA	5460	0	18
19201	TRAVESIA DE MOGNA	5460	0	18
19202	TUMINICO	5460	0	18
19203	CHIRCAL	3407	0	7
19207	COLONIA AMADEI	3407	0	7
19209	COLONIA DANUZZO	3407	0	7
19210	COLONIA DURAZNO	3407	0	7
19211	VALLE DE LAS LE	5612	0	13
19212	ESTANCIA CHACAICO	5621	0	13
19213	LAS COMPUERTAS NEGRAS	5632	0	13
19214	MOJON OCHO	5636	0	13
19215	OCHENTA Y CUATRO	5633	0	13
19216	PASO DE LOS GAUCHOS	5636	0	13
19217	POSTA DE HIERRO	5621	0	13
19218	PUESTO DE LA CORONA	5636	0	13
19219	PUESTO DEL BUEN PASTOR	5636	0	13
19220	PUESTO LA CALDENADA	5621	0	13
19221	PUESTO LA SE	5636	0	13
19222	PUESTO LUNINA	5621	0	13
19223	PUESTO VUELTA DEL ZANJON	5636	0	13
19224	EL DIECISIETE	3190	0	8
19225	SANTA ELENA	5634	0	13
19226	LOS CORRALITOS	5527	0	13
19227	ESTANCIA SAN JUAN	3190	0	8
19228	ISLA LA PAZ	3190	0	8
19229	ISLAS ALCARAZ	3190	0	8
19230	EL JUME	5572	0	13
19231	COLONIA FLORENCIA	3407	0	7
19232	COLONIA JUAN PUJOL	3405	0	7
19233	COLONIA PUCHETA	3450	0	7
19234	COLONIA SAN MARTIN	3407	0	7
19235	COLONIA FLORENCIA	3500	0	4
19236	COLONIA PALMIRA	3500	0	4
19237	COLONIA TACUARALITO	3407	0	7
19238	APEADERO QUIROGA	5427	0	18
19239	ESTANCIA LA AURORA	3516	0	4
19240	COLONIA CANTONI	5427	0	18
19241	COLONIA CASTRO PADIN	5427	0	18
19242	LAS MERCEDES	3516	0	4
19243	COLONIA MOYA	5427	0	18
19244	COSTA SANTA LUCIA	3405	0	7
19245	PASO GARIBALDI	3192	0	8
19246	PUESTO RETIRO	5431	0	18
19247	COSTAS	3407	0	7
19248	VILLA PARANACITO	3500	0	4
19249	PASO MEDINA	3190	0	8
19250	VILLA SANTA ANITA	5423	0	18
19251	EL SALVADOR	3407	0	7
19252	PASO POTRILLO	3127	0	8
19253	VILLA GENERAL ACHA	5425	0	18
19254	LAS MAQUINAS	8520	0	16
19255	PASO PUERTO AUGUSTO	3190	0	8
19256	FERNANDEZ	3405	0	7
19257	FRONTERA	3405	0	7
19258	MANCHA BLANCA	8520	0	16
19259	GENERAL PAZ	3407	0	7
19260	VILLA DOMINGUITO	5439	0	18
19261	POZO MORO	8520	0	16
19262	KILOMETRO 151	3405	0	7
19263	PASO TELEGRAFO	3194	0	8
19264	LA FLECHA	3405	0	7
19265	LA JAULA	3407	0	7
19266	CALLECITA	5438	0	18
19268	VILLA GENERAL LAS HERAS	5411	0	18
19269	LA PARADA	3405	0	7
19270	VILLA BERMEJITO	5411	0	18
19271	LOMA ALTA	3405	0	7
19272	VILLA ESTEVEZ	5411	0	18
19273	VILLA MU	5411	0	18
19274	LOMA VILLANUEVA	3407	0	7
19275	VILLA SARGENTO CABRAL	5411	0	18
19276	LOMAS DE VERGARA	3405	0	7
19277	VILLA PUEYRREDON	5411	0	18
19278	LOMAS RAMIREZ	3405	0	7
19279	VILLA 20 DE JUNIO	5411	0	18
19280	PUERTO ALGARROBO	3127	0	8
19281	LOMAS REDONDAS	3407	0	7
19282	VILLA GOBERNADOR CHAVEZ	5411	0	18
19283	LOTE 17	3543	0	4
19284	LOMAS VAZQUEZ	3405	0	7
19285	LOTE 24	3543	0	4
19286	VILLA J C SARMIENTO	5411	0	18
19287	LOTE 25	3543	0	4
19288	PUERTO CADENAS	3192	0	8
19289	VILLA LUZ DEL MUNDO	5411	0	18
19290	LOS VENCES	3405	0	7
19291	LOTE 7	3543	0	4
19292	LOTE 8	3543	0	4
19293	MALOYITA	3405	0	7
19294	PUERTO LA ESMERALDA	3190	0	8
19295	VILLA PATRICIAS SANJUANINAS	5411	0	18
19296	NARANJATY	3405	0	7
19297	VILLA RIZZO	5411	0	18
19298	VILLA RUFINO GOMEZ	5411	0	18
19299	OBRAJE CUE	3405	0	7
19300	VILLA N LARRAIN	5411	0	18
19301	PUERTO YUNQUE	3190	0	8
19302	OMBU LOMAS	3405	0	7
19303	PASO GALLEGO	3407	0	7
19304	PASO SALDA	3407	0	7
19305	PUESTO LATA	3480	0	7
19306	PUNTA GRANDE	3427	0	7
19307	RINCON DE VENCES	3407	0	7
19308	RINCON ZALAZAR	3405	0	7
19309	RODEITO	3405	0	7
19310	APEADERO GUANACACHE	5431	0	18
19311	ROSADITO	3407	0	7
19312	KILOMETRO 10650	5431	0	18
19314	BA	5431	0	18
19315	BODEGA SAN ANTONIO	5431	0	18
19316	TIMBO CORA	3407	0	7
19317	CARBOMETAL	5431	0	18
19318	SANTA INES	3191	0	8
19319	VILLA SAN RAMON	3407	0	7
19320	CIENAGUITA	5431	0	18
19321	CERRO DE LOS BURROS	5431	0	18
19322	CERRO DEL MEDIO	5431	0	18
19323	ZAPALLOS	3407	0	7
19324	CERRO HEDIONDO	5431	0	18
19325	CERRO RIQUILIPONCHE	5431	0	18
19326	BATELITO	3451	0	7
19327	CERRO LOS POZOS	5431	0	18
19328	DIQUE LAS CRUCECITAS	5431	0	18
19329	COLONIA LA CARMEN	3451	0	7
19332	EL INFIERNO	5431	0	18
19333	COLONIA MERCEDES COSSIO	3450	0	7
19334	ESTANCIA ACEQUION	5431	0	18
19335	ESTANCIA EL DURAZNO	5431	0	18
19336	LA CHILCA	5431	0	18
19337	COLONIA PORVENIR	3451	0	7
19338	LOMAS DEL AGUADITAS	5431	0	18
19339	COLONIA ROLON COSSIO	3450	0	7
19340	LOS NOGALES	5431	0	18
19341	POTRANCA	5431	0	18
19342	COLONIA SAUCE	3450	0	7
19346	CORONA	3450	0	7
19348	CURTIEMBRE	3450	0	7
19349	YESO OESTE	3190	0	8
19350	PUESTO LA CHILCA DE ABAJO	5431	0	18
19351	EL ROSARIO	3450	0	7
19352	PUNTA DEL MEDANO	5435	0	18
19353	SANTA CLARA	5431	0	18
19354	EL TATARE	3454	0	7
19355	VILLA GENERAL SARMIENTO	5431	0	18
19356	EL TRANSITO	3454	0	7
19357	FANEGAS	3454	0	7
19358	GRANJA AMELIA	3450	0	7
19361	ISLA SOLA	3450	0	7
19362	AURORA	5409	0	18
19363	ITA CURUBI	3450	0	7
19364	BARRIO AGUA Y ENERGIA	5409	0	18
19366	BARRIO COLON	5409	0	18
19367	LA CARLINA	3454	0	7
19368	CAMP D P V LA CIENAGA	5409	0	18
19369	LA CELIA	3454	0	7
19370	CASTA	5409	0	18
19371	CIENAGUITA	5409	0	18
19372	LA CRUZ	3454	0	7
19373	CERRO LA VENTANITA	5409	0	18
19374	CERRO TAMBOLAR	5409	0	18
19375	LA DIANA	3454	0	7
19376	CERRO VILLA LONCITO	5409	0	18
19377	LA ELVIRA	3454	0	7
19378	LAGUNA PUCU	3450	0	7
19380	EL CHILOTE	5409	0	18
19381	LOS CEIBOS	3454	0	7
19382	IMSA	5409	0	18
19383	ISLA DEL SAUCE	5409	0	18
19384	MANCHITA	3453	0	7
19385	MINA GUALILAN	5409	0	18
19386	MARUCHITAS	3450	0	7
19387	PORT DEL COLORADO	5409	0	18
19388	REFUGIO D P V	5409	0	18
19389	CUARTO DISTRITO	3150	0	8
19390	MASDEU ESCUELA 197	3453	0	7
19391	REFUGIO LOS GAUCHOS	5409	0	18
19392	SEPTIMO DISTRITO	3150	0	8
19393	ALDEA SAN MIGUEL	3116	0	8
19394		3453	0	7
19395	8 DE DICIEMBRE	3450	0	7
19396	ALDEA SANTA MARIA	3123	0	8
19397	PASO BANDERA	3454	0	7
19398	PASO CORONEL	3450	0	7
19399	EL TUPI KILOMETRO 474	3513	0	4
19400	AGUA CERCADA	5447	0	18
19401	ALGARROBITOS 1RO	3150	0	8
19402	INVERNADA	3543	0	4
19403	PASO LOS ANGELES	3454	0	7
19404	KILOMETRO 474	3513	0	4
19405	PUENTE MACHUCA	3454	0	7
19406	BALDE PLUMERITO	5447	0	18
19407	LOTE 1	3543	0	4
19408	BALDE SAN CARLOS	5447	0	18
19410	ALMIRANTE IGLESIAS	3150	0	8
19411	PUNTA IFRAN	3453	0	7
19412	LOTE 23 SAMUHU	3543	0	4
19413	RANEGAS	3450	0	7
19414	LOTE 15 LA SABANA	3513	0	4
19415	LOTE 9	3513	0	4
19416	REMANSO	3450	0	7
19417	PUESTO COCHERI	3513	0	4
19418	RINCON DE GOMEZ	3450	0	7
19419	PUESTO MENDIZABAL	3513	0	4
19421	ESTANCIA EL SABALO	3513	0	4
19422	RINCON DE PAGO	3451	0	7
19423	KILOMETRO 53	3543	0	4
19424	BARRANCA COLORADA	5447	0	18
19425	ROLON JACINTO	3450	0	7
19426	CA	5447	0	18
19427	CA	5447	0	18
19428	SAN DIONISIO	3450	0	7
19429	CASA DE JAVIER	5447	0	18
19430	SAN GREGORIO	3450	0	7
19431	CHANCHOS	5447	0	18
19432	CHICA NEGRA	5447	0	18
19433	BOCA DEL TIGRE	3150	0	8
19434	CIENAGA	5447	0	18
19435	SAN PEDRO	3451	0	7
19436	CERRO ASILAN	5447	0	18
19437	SOLEDAD	3450	0	7
19438	CERRO LA COLORADA	5447	0	18
19439	CERRO TRES PUNTAS	5447	0	18
19440	TARTARIA	3450	0	7
19441	CONDOR MUERTO	5447	0	18
19442	CAMPO ESCALES	3156	0	8
19443	CORRAL DE PIRCA	5447	0	18
19444	CUESTA VIEJO	5447	0	18
19445	CULEBRA	5447	0	18
19446	CAMPS	3150	0	8
19447	DOS MOJONES	5447	0	18
19449	VILLA ROLON	3451	0	7
19450	CHILECITO	3412	0	7
19451	CORSA CUE	3414	0	7
19452	LA PALMIRA	3414	0	7
19454	MBALGUIAPU	3414	0	7
19455	PARAJE IRIBU CUA	3412	0	7
19457	SAN FRANCISCO CUE	3414	0	7
19460	SAN ISIDRO	3414	0	7
19463	SAN JOSE	3414	0	7
19466	SAN SALVADOR	3414	0	7
19468	CRUCESITAS URQUIZA	3150	0	8
19470	YAGUA ROCAU	3414	0	7
19472	EL BARRIALITO	5447	0	18
19473	EL LECHUZO	5447	0	18
19474	EL PLUMERITO	5447	0	18
19475	EL RINCON	5447	0	18
19476	EL SALTO	5447	0	18
19477	CENTINELA	3302	0	7
19478	DISTRITO EL SAUCE	3150	0	8
19479	EST DE HERRERA VEGAS	5447	0	18
19480	EST MARAYES	5447	0	18
19481	COLONIA SAN ANTONIO	3302	0	7
19482	FILO DEL MOCHO	5447	0	18
19483	COLONIA URDANIZ	3302	0	7
19484	FINCA DEL JAPONES	5447	0	18
19485	COSTA GUAZU	3302	0	7
19486	ICHIGUALASTO	5447	0	18
19487	ISCHIGUALASTO	5447	0	18
19488	EL CENTINELA	3302	0	7
19489	JARILLA CHICA	5447	0	18
19490	EMPEDRADO LIMPIO	3302	0	7
19491	JUNTAS DEL GUANDACOL	5447	0	18
19492	ESTANCIA SAN JAVIER	3302	0	7
19493	LA CARPA	5447	0	18
19494	LA CERCADA	5447	0	18
19495	FLORIDA	3302	0	7
19496	LA CIENAGUITA	5447	0	18
19497	LA CRUZ	5447	0	18
19498	GARCITAS	3302	0	7
19499	LA ESQUINA	5447	0	18
19500	LA MAJADITA	5449	0	18
19501	IBIRITANGAY	3302	0	7
19502	LA ORQUETA	5447	0	18
19503	LA PENCA	5447	0	18
19504	LA RIPIERA	5447	0	18
19505	LA ROSITA	5447	0	18
19506	LA CELESTE	3302	0	7
19507	LA SAL	5447	0	18
19508	LAPRIDA	5447	0	18
19509	LAS HERMANAS	5447	0	18
19511	LAS JUNTAS	5447	0	18
19512	LAS RAMADITAS	5447	0	18
19513	LA HILEORICA	3302	0	7
19514	EL TROPEZON	3150	0	8
19515	LAS YEGUAS	5447	0	18
19516	LOMA ANCHA	5447	0	18
19517	LOMA DE COCHO	5447	0	18
19518	LAS ANIMAS	3302	0	7
19519	LOMA LEONES	5447	0	18
19520	LOS LAGARES	5447	0	18
19521	LAS DELICIAS	3302	0	7
19522	LAS TRES HERMANAS	3302	0	7
19535	LOS TRES HERMANOS	3302	0	7
19536	PASO TIRANTE	3302	0	7
19537	KILOMETRO 148	3151	0	8
19538	PUERTO NARANJITO	3302	0	7
19539	LA CORVINA	3150	0	8
19540	PUNTA MERCEDES	3302	0	7
19541	LOS PORONGOS	5447	0	18
19542	LOS SANCHEZ	5447	0	18
19543	RINCON CHICO	3302	0	7
19544	MESADA AGUADA	5447	0	18
19545	MICA	5447	0	18
19546	RINCON DEL ROSARIO	3302	0	7
19547	SALINAS	3302	0	7
19548	SAN ISIDRO	3302	0	7
19549	LA FLORENCIA	3151	0	8
19550	SAN JAVIER	3302	0	7
19551	SAN JERONIMO	3302	0	7
19552	LA ILUSION	3150	0	8
19554	SAN JUAN	3302	0	7
19555	SAN JULIAN	3302	0	7
19556	SAN PEDRO	3302	0	7
19557	LA LOMA	3151	0	8
19558	SANGARA	3302	0	7
19559	SANTA ANA	3302	0	7
19560	SANTA MARIA	3302	0	7
19561	SANTO DOMINGO	3302	0	7
19562	TRES ARBOLES	3302	0	7
19563	MILAGRO	5447	0	18
19564	MORTERITO	5447	0	18
19565	ULAJAY	3302	0	7
19566	NAQUERA	5447	0	18
19567	URIBURU	3302	0	7
19568	PAMPA DE LOS CABALLOS	5447	0	18
19569	VILLA P ARGENTINA	3302	0	7
19583	PAMPA GRANDE	5447	0	18
19584	VIZCAINO	3302	0	7
19585	PASO DE FERREIRA	5447	0	18
19586	PASO DE LAMAS	5447	0	18
19587	PIEDRA BLANCA	5447	0	18
19588	COLONIA GENERAL URIBURU	3302	0	7
19590	PIEDRA RAJADA	5447	0	18
19591	PILA DE MACHO	5447	0	18
19592	LOS CATUTOS	8340	0	15
19593	PORT LAS CHILCAS	5447	0	18
19594	PORT LAS FRANCAS	5447	0	18
19595	POZO DE AGUADITA	5447	0	18
19596	PTO CHANQUIA	5447	0	18
19597	PTO GORDILLO	5447	0	18
19599	PTO LIMA	5447	0	18
19600	PTO ROMERO	5447	0	18
19601	PTO SAN ISIDRO	5447	0	18
19602	BATAL	3445	0	7
19604	PTO VEGA	5447	0	18
19605	PTO CHAVEZ	5447	0	18
19606	PTO HUASI	5447	0	18
19608	BONETE	3445	0	7
19609	PUERTA DE LA CHILCA	5447	0	18
19610	PUNTA BLANCA	5447	0	18
19611	PUNTA NORTE	5447	0	18
19612	REFUGIO	5447	0	18
19613	CABANA	3445	0	7
19615	RICHARD	5447	0	18
19616	RINCON CHICO	5447	0	18
19617	RINCON GRANDE	5447	0	18
19618	SANJUANINO	5447	0	18
19619	CERRITO	3445	0	7
19620	SANTO DOMINGO	5447	0	18
19621	SARMIENTO	5447	0	18
19622	TAMBERIAS	5447	0	18
19623	COLONIA LUJAN	3440	0	7
19624	SAN AGUSTIN DEL VALLE FERTIL	5449	0	18
19626	YERBA BUENA	5447	0	18
19627	COLONIA SAN EUGENIO	3440	0	7
19628	COLONIA SAN JOSE	3440	0	7
19629	EL COLORADO	5595	0	13
19630	COLONIA VEDOYA	3445	0	7
19631	ALCETE	3127	0	8
19632	CERRO AGUADITAS	5401	0	18
19633	EL GIGANTILLO	5591	0	13
19634	CERRO AGUILA	5401	0	18
19635	COSTA BATEL	3445	0	7
19636	ALDEA CHALECO	3116	0	8
19637	CERRO BLANCO	5401	0	18
19638	CERRO CASA DE PIEDRA	5401	0	18
19639	CRUCECITAS	3445	0	7
19640	CERRO DIVISADERO	5401	0	18
19641	CERRO INFIERNILLO	5401	0	18
19642	ALDEA CUESTA	3116	0	8
19643	CERRO JAGUEL	5401	0	18
19644	CERRO LA FLECHA	5401	0	18
19645	ESTANCIA LA SALCEDINA	5590	0	13
19646	CERRO LA JARILLA	5401	0	18
19647	FERRO	3440	0	7
19648	CERRO LAS BARRANCAS	5401	0	18
19649	ALDEA EIGENFELD	3116	0	8
19650	CERRO LAS PLACETAS	5401	0	18
19651	CERRO NEGRO	5401	0	18
19652	CERRO PACHACO	5401	0	18
19653	KILOMETRO 410	3445	0	7
19654	CERRO PIRCAS	5401	0	18
19655	CERRO SANTA ROSA	5401	0	18
19656	CERRO SASITO	5401	0	18
19657	FLORENCIO GARRO	5590	0	13
19658	CERRO TAMBOLAR	5401	0	18
19659	COLONIA MEROU	3116	0	8
19660	CERRO TRES MOGOTES	5401	0	18
19661	KILOMETRO 416	3445	0	7
19662	CERRO LA CIENAGA	5401	0	18
19663	CERRO LA RINCONADA	5401	0	18
19664	LA FAVORITA	5591	0	13
19665	ALDEA SAN JOSE	3116	0	8
19666	DIQUE SOLDANO	5401	0	18
19668	HUAICOS	5401	0	18
19669	LOS PARAMILLOS	5401	0	18
19670	LA CELIA	3445	0	7
19671	BARRIO EL TONTAL	5401	0	18
19672	LA PASTORIL	3440	0	7
19673	PORT DE LOS SOMBREROS	5401	0	18
19674	PTO LAS CUEVAS	5401	0	18
19675	PTO CORDOVA	5401	0	18
19676	LAGUNA SIRENA	3445	0	7
19677	PTO DEL AGUA DE PINTO	5401	0	18
19678	PTO EL MOLLE	5401	0	18
19679	ALDEA SANTA ROSA	3116	0	8
19680	PTO LOS PAPAGALLOS	5401	0	18
19681	VILLA MEDIA AGUA	5401	0	18
19682	LA JACINTITA	5591	0	13
19683	LA PORTE	5591	0	13
19684	LOS ANGELES DEL BATEL	3445	0	7
19685	ARROYO BURGOS	3133	0	8
19686	MONTE FLORIDO	3440	0	7
19687	LAS TOTORITAS	5591	0	13
19688	NARANJITO	3440	0	7
19689	ARROYO MARIA	3133	0	8
19690	PUENTE BATEL	3445	0	7
19691	PUERTA IFRAN	3445	0	7
19692	ARROYO PANCHO	3111	0	8
19693	LAS VIZCACHAS	5590	0	13
19694	BA	3100	0	8
19695	CAMPO FERNANDEZ	3427	0	7
19696	ALTO GRANDE	5543	0	13
19697	ARENALES	5539	0	13
19698	BARREAL DE LA PAMPA SECA	5539	0	13
19699	CARDOZO PHI	3427	0	7
19700	BARREAL PAJARO MUERTO	5539	0	13
19701	BUITRERA	5539	0	13
19702	CHACRAS	3427	0	7
19703	BOCA DEL TIGRE APEADERO FCGU	3116	0	8
19704	CA DEL DIABLO	5539	0	13
19705	CHAMORRO	3427	0	7
19706	CARACOLES	5557	0	13
19707	CASILLA	5539	0	13
19708	COSTA	3427	0	7
19709	CA	5621	0	13
19710	COSTA SAN LORENZO	3427	0	7
19711	CAMINO A DIAMANTE KM 1	3100	0	8
19712	EL PAGO	3427	0	7
19713	CERRILLOS NEGROS	5539	0	13
19714	CERRO CUPULA	5539	0	13
19715	FRANCISCO GAUNA	3427	0	7
19716	CERRO LOS DIENTITOS	5539	0	13
19717	LA HERMINIA	3427	0	7
19718	CERRO POZO	5539	0	13
19719	CERRO YALGUARAS	5621	0	13
19720	CERRO PELADO	5549	0	13
19721	ORATORIO	3427	0	7
19722	CERRO ACONCAGUA	5500	0	13
19723	CERRO AGUA SALADA	5539	0	13
19724	PASITO	3427	0	7
19725	CERRO AGUADITA	5539	0	13
19726	CA	3111	0	8
19727	POTRERO GRANDE	3427	0	7
19728	PUNTA GRANDE	3405	0	7
19729	SAN ANTONIO	3427	0	7
19730	ARROYO GRANDE	3470	0	7
19731	CERRO ALOJAMIENTO	5539	0	13
19732	CERRO ANGOSTURA	5539	0	13
19733	CERRO ASPERO	5539	0	13
19734	CALLEJON	3470	0	7
19735	CERRO BARAUCA	5539	0	13
19736	CAPI VARI	3470	0	7
19737	CERRO BAY	5539	0	13
19738	CAPIGUARI	3470	0	7
19739	CERRO BLANCO	5539	0	13
19740	CERRO BONETE	5545	0	13
19741	CERRO BRAVO	5539	0	13
19742	CERRO CATEDRAL	5539	0	13
19743	CERRO CHIQUERO	5539	0	13
19744	CERRO CIELO	5539	0	13
19745	CERRO CLEMENTINO	5539	0	13
19746	ESTANCIA AGUACEROS	3470	0	7
19747	CERRO COLOR	5539	0	13
19748	CERRO CORTADERAS	5539	0	13
19749	CERRO CUERNO	5539	0	13
19750	ESTANCIA CERRO VERDE	3470	0	7
19751	ESTANCIA GONZALEZ CRUZ	3470	0	7
19752	COLONIA LA GAMA	3136	0	8
19753	ESTANCIA ITA CAABO	3470	0	7
19754	ESTANCIA LA CALERA	3470	0	7
19755	ESTANCIA LA MARIA	3470	0	7
19756	ESTANCIA MANDURE	3470	0	7
19757	ESTANCIA ROSARIO	3470	0	7
19758	ESTANCIA SANTA CRUZ	3470	0	7
19759	ESTANCIA TUNAS	3470	0	7
19760	IBIRA PITA	3470	0	7
19761	CERRO DE LAS LE	5539	0	13
19762	CERRO DE LOS BURROS	5539	0	13
19763	CERRO DE LOS DEDOS	5539	0	13
19764	JUSTINO SOLARI	3476	0	7
19765	CERRO DE LOS POTRERILLOS	5500	0	13
19766	CERRO DEL CHACAY	5621	0	13
19767	CERRO DEL MEDIO	5539	0	13
19768	CERRO DEL RINCON BAYO	5539	0	13
19769	KILOMETRO 287 FCGU	3470	0	7
19770	CERRO DURAZNO	5539	0	13
19771	CERRO EL GUANACO	5539	0	13
19772	KILOMETRO 296	3470	0	7
19773	CERRO FUNDICION	5539	0	13
19774	CERRO GRANDE	5539	0	13
19775	CERRO HORQUETA	5539	0	13
19776	LA ESTRELLA	3476	0	7
19777	CERRO INVERNADA	5539	0	13
19778	CERRO JUAN POBRE	5539	0	13
19779	MARIA DEL CARMEN	3476	0	7
19780	CERRO L CORRALES	5539	0	13
19781	MARIA IDALINA	3476	0	7
19782	CERRO LA MANO	5539	0	13
19783	NARANJITO	3472	0	7
19784	PAIMBRE	3472	0	7
19785	PASAJE SANTA JUANA	3470	0	7
19786	PASO MESA	3470	0	7
19787	LAS CORTADERAS	8353	0	15
19788	PASO PUCHETA	3472	0	7
19789	PIEDRA ITA PUCU	3470	0	7
19790	CERRO LAGA	5539	0	13
19791	CERRO MANANTIAL	5539	0	13
19792	CERRO MASILLAS	5539	0	13
19793	RINCON TRANQUERA GENERAL	3470	0	7
19794	SALTO ITA JHASE	3470	0	7
19795	SAN CARLOS	3472	0	7
19796	SAN EDUARDO	3472	0	7
19797	EL PORTON	8353	0	15
19798	SAN NICOLAS	3472	0	7
19799	EST SOLARI	3476	0	7
19800	LAS CHACRAS	8353	0	15
19801	TACURAL	3470	0	7
19802	CERRO MELOCOTON	5539	0	13
19803	CERRO MEXICO	5539	0	13
19804	CERRO MONTURA	5539	0	13
19805	CERRO NEVADO	5621	0	13
19806	TARANGULLO	3472	0	7
19807	CERRO PAMPA SECA	5539	0	13
19808	CERRO PAN DE AZUCAR	5539	0	13
19809	TATARE	3472	0	7
19810	CERRO PANTA	5539	0	13
19811	CERRO PONDERADO	5539	0	13
19812	ARROYO HORQUETA	3466	0	7
19813	CERRO PUNTA DE AGUA	5539	0	13
19814	CERRO PUNTILLA NEGRA	5539	0	13
19815	COLONIA BARRIENTES	3220	0	7
19816	CERRO PUNTUDO	5539	0	13
19817	CUATRO BOCAS	3220	0	7
19818	CERRO PUQUIOS	5539	0	13
19819	RANQUIL VEGA	8353	0	15
19820	KILOMETRO 120	3222	0	7
19821	CERRO RIQUITIPANCHE	5539	0	13
19822	CERRO SAN LORENZO	5539	0	13
19823	CERRO SANTA MARIA	5539	0	13
19824	CERRO SAPO	5539	0	13
19825	CERRO TIGRE	5539	0	13
19826	CERRO TOLOSA	5539	0	13
19827	ESPINILLO NORTE	3116	0	8
19828	CERRO TUNDUQUERA	5539	0	13
19829	CERRO YARETA	5539	0	13
19830	COLON SANDALHO	5545	0	13
19831	CERROS COLORADOS	5539	0	13
19832	ESTABLECIMIENTO EL CIMARRON	3114	0	8
19833	CTO DEL TIGRE	5539	0	13
19834	ESTANCIA VILLAVICENCIO	5539	0	13
19835	ESTANCIA CASA DE PIEDRA	5539	0	13
19836	ESTABLECIMIENTO EL TALA	3118	0	8
19837	ESTANCIA CUEVA DEL TORO	5539	0	13
19838	ESTANCIA EL CARRIZAL	5539	0	13
19839	ESTANCIA SAN MARTIN	5539	0	13
19840	ESTANCIA USPALLATA	5545	0	13
19841	ESTANCIA LA GAMA	3138	0	8
19842	ESTANCIA YALGUARAZ	5539	0	13
19843	EL CHA	5435	0	13
19844	EL INFIERNO	5539	0	13
19845	EL PUESTITO	5539	0	13
19846	ESTANCIA JOCOLI	5539	0	13
19847	MOYANO	5543	0	13
19848	LA BLANCA	3466	0	7
19849	GARGANTA DEL LEON	5539	0	13
19850	LA ANGOSTURA	5539	0	13
19851	LA BOVEDA	5539	0	13
19852	LA FLORESTA	3466	0	7
19853	LA CASA DEL TIGRE	5539	0	13
19854	RICHOIQUE	8349	0	15
19855	LA CORTADERA	5545	0	13
19856	LA FUNDICION	5539	0	13
19857	LA HORQUETA	5539	0	13
19858	MOTA PIEDRITAS	3220	0	7
19859	LA HULLERA	5549	0	13
19860	LA JAULA	5539	0	13
19861	LAS CORTADERAS	5545	0	13
19862	LAS CANTERAS	5539	0	13
19863	LOMA COLORADA	5539	0	13
19864	PASO ESTERITO	3220	0	7
19865	LOMA DE LOS BURROS	5539	0	13
19866	ISLA LYNCH	3100	0	8
19867	LOMA SOLA	5539	0	13
19868	PASO VALLEJOS	3220	0	7
19869	LOMAS BAYAS	5539	0	13
19870	SAENZ VALIENTE	3222	0	7
19871	LOS CHACAYES	5539	0	13
19872	KILOMETRO 116	3132	0	8
19873	MINAS SALAGASTA	5545	0	13
19874	MONTE BAYO	5539	0	13
19875	SAN FRANCISCO	3220	0	7
19876	KILOMETRO 131	3118	0	8
20010	ALBARDONES	3403	0	7
19877	MONUMENTO AL EJERCITO DE LOS A	5539	0	13
19878	SAN VICENTE	3466	0	7
19879	KILOMETRO 147	3118	0	8
19880	P SAN IGNACIO	5539	0	13
19881	SANTA JUANA	3466	0	7
19882	KILOMETRO 28	3114	0	8
19883	PAMPA YALGUARAZ	5539	0	13
19884	PARAMILLO DE LAS VACAS	5500	0	13
19885	PLAZA DE MULAS	5500	0	13
19886	KILOMETRO 45	3116	0	8
19887	SIETE ARBOLES	3460	0	7
19888	TEBLENARI	3476	0	7
19889	TRES BOCAS	3220	0	7
19890	PO DE CONTRABANDISTA	5539	0	13
19891	PO DE LA CUMBRE	5539	0	13
19892	PO DE LA QUEBRADA HONDA	5539	0	13
19893	PO DEL RUBIO	5539	0	13
19894	LA BALSA PARANA	3113	0	8
19895	CABRED	3232	0	7
19896	ESTANCIA LOMATORA	3230	0	7
19897	PO VALLE HERMOSO	5539	0	13
19898	ESTANCIA LA CAROLINA	3230	0	7
19899	POLVAREDAS	5551	0	13
19900		3230	0	7
19901	PORTILLO DE LOMAS COLORADAS	5539	0	13
19902	PASO ROSARIO	3230	0	7
19903	RINCON DE YAGUARY	3234	0	7
19904	PORTILLO QUEMADO	5539	0	13
19905	PORTILLO DE INDIO	5539	0	13
19906	SAN ISIDRO	3234	0	7
19907	PORTILLO DE LA LAGRIMA VIVA	5539	0	13
19908	PORTILLO LA PAMPA	5539	0	13
19909	PORTILLO DE LAS VACAS	5539	0	13
19910	PORTILLO DEL MEDIO	5539	0	13
19911	PORTILLO DEL NORTE	5539	0	13
19912	PORTILLO DEL TIGRE	5539	0	13
19913	ACU	3420	0	7
19914	PUESTO ESCONDIDO	5539	0	13
19915	PUESTO EL PERAL	5539	0	13
19916	ANGUA	3420	0	7
19917	PUESTO SANTA CLARA DE ARRIBA	5539	0	13
19918	PUESTO CARRIZALITO	5539	0	13
19919	ARROYO CEIBAL	3416	0	7
19920	PUESTO AGUA DE ZANJON	5539	0	13
19921	PUESTO CHAMBON	5539	0	13
19922	CARMAN	3420	0	7
19923	PUESTO EL TOTORAL	5539	0	13
19924	PUESTO GUAMPARITO	5539	0	13
19925	CASUARINAS	3420	0	7
19926	PUESTO LOS PAJARITOS	5539	0	13
19927	PUESTO LA GRUTA	5539	0	13
19928	PUESTO LA MOJADA	5539	0	13
19929	PUESTO LAS HIGUERAS	5539	0	13
19930	COSTA DE ARROYO SAN LORENZO	3416	0	7
19931	PUESTO LOS ALOJAMIENTOS	5539	0	13
19932	COLONIA ZABALA	5425	0	18
19933	DOS OMBUES	3416	0	7
19934	EL CARMEN	3420	0	7
19935	KM 425	3420	0	7
19936	PUESTO RIQUITIPANCHE	5539	0	13
19937	RODEO GRANDE	5539	0	13
19938	GUAZU CORA	3420	0	7
19940	JARDIN FLORIDO	3420	0	7
19942	LA QUERENCIA	3420	0	7
19944	LAGO ARIAS	3420	0	7
19945	SAN IGNACIO	5539	0	13
19946	LAURETTI	3420	0	7
19947	SANTA ELENA	5539	0	13
19948	LOMAS	3420	0	7
19949	LOMAS SALADAS	3420	0	7
19950	VALLE DE USPALLATA	5545	0	13
19951	LOS LIRIOS	3420	0	7
19953	VEGA DE LOS BURROS	5539	0	13
19954	MEDIODIA	3420	0	7
19955	VEGAS DE LOS CORRALES DE ARAYA	5539	0	13
19956	MIRA FLORES	3420	0	7
19957	VILLAVICENCIO	5539	0	13
19958	MUCHAS ISLAS	3420	0	7
19959	VRA DE LAS VACAS	5539	0	13
19960	PAGO ARIAS	3420	0	7
19961	ALGARROBITO	5537	0	13
19962	ALTO AMARILLO	5537	0	13
19963	PARAJE AUGUA	3420	0	7
19964	PASO NARANJITO	3420	0	7
19965	PASTORES	3420	0	7
19966	PASO DE LA ARENA	3118	0	8
19967	REAL CUE	3416	0	7
19968	CRUZ BLANCA	5537	0	13
19969	RINCON DE SAN LORENZO	3416	0	7
19970	PASO DE LA BALZA	3113	0	8
19971	RINCON SAN PEDRO	3420	0	7
19972	PASO DE LAS PIEDRAS	3118	0	8
19973	SAN EMILIO	3420	0	7
19974	SAN FRANCISCO	3420	0	7
19975	ANGACO SUD	5417	0	18
19976	SAN NICOLAS	3420	0	7
19977	SANTO DOMINGO	3420	0	7
19978	SOLEDAD	3420	0	7
19979	SOSA CUE	3420	0	7
19980	ALBARDON	3412	0	7
19981	ARROYO PELON	3401	0	7
19982	BUENA VISTA	3412	0	7
19983	COLONIA ALVAREZ	3401	0	7
19984	COLONIA MARIA ESTHER	3401	0	7
19985	PUENTE CARMONA	3118	0	8
19986	COLONIA MATILDE	3401	0	7
19987	COSTA	3401	0	7
19988	PUENTE DEL CHA	3111	0	8
19989	PUERTO VIBORAS	3129	0	8
19990	COSTA RIO PARANA	3401	0	7
19991	PUERTO VIEJO	3100	0	8
19993	DESAGUADERO	3403	0	7
19994	PUERTO VILLARRUEL	3127	0	8
19995	ENSENADA GRANDE	3412	0	7
19996	ENSENADITA	3412	0	7
19997	QUEBRACHO	3109	0	8
19998	INGENIO PRIMER CORRENTINO	3401	0	7
19999	ISLA IBATAY	3401	0	7
20000	JUAN RAMON VIDAL	3401	0	7
20001	MANDINGA	3412	0	7
20002	PUERTO GONZALEZ	3409	0	7
20003	SAN JOSE	3401	0	7
20004	TALA CORA	3401	0	7
20005	VILLA CUE	3412	0	7
20006	RUTA 138 KILOMETRO 1	3100	0	8
20007	AGUIRRE CUE	3403	0	7
20008	AGUIRRE LOMAS	3403	0	7
20009	CERRO CIENAGA	5539	0	13
20011	ALTA MORA	3403	0	7
20012	SAN MARTIN	3113	0	8
20013	ARROYO PONTON	3401	0	7
20014	BARGONE	3403	0	7
20015	ESTANCIA LA POSTA	5431	0	18
20016	BROJA CUE	3403	0	7
20017	BREGAIN CUE	3403	0	7
20018	BRIGANIS	3403	0	7
20019	RINCON CHICO	8401	0	15
20020	CAMPO GRANDE	3403	0	7
20021	CA	3403	0	7
20022	CARABAJAL	3403	0	7
20023	PUESTO ANGOSTURA	5431	0	18
20024	CARUSO APEADERO FCGU	3403	0	7
20025	SANTA MARIA	8401	0	15
20026	CAVIA CUE	3403	0	7
20027	PUESTO DE ARRIBA	5431	0	18
20028	COLONIA LLANO	3403	0	7
20029	PUESTO OLGUIN	5431	0	18
20030	EL PONTON	3403	0	7
20031	EL VASCO	3403	0	7
20032	PUESTO SANTA ROSA	5431	0	18
20033	EMPEDRADO LIMPIO	3403	0	7
20034	ESQUIVEL CUE	3403	0	7
20035	GARABATA	3403	0	7
20036	ARROYO RANQUILCO	8347	0	15
20037	GARRIDO	3403	0	7
20038	GDOR JUAN EUSEBIO TORREN	3403	0	7
20039	KILOMETRO 31	3403	0	7
20040	KILOMETRO 42	3403	0	7
20041	KILOMETRO 49	3403	0	7
20042	EST LA CIENAGA DE GUALILA	5409	0	18
20043	KILOMETRO 55	3403	0	7
20044	KILOMETRO 57	3403	0	7
20045	KILOMETRO 61	3403	0	7
20047	KILOMETRO 76	3403	0	7
20048	KILOMETRO 84	3403	0	7
20049	KILOMETRO 89	3403	0	7
20050	KILOMETRO 95	3403	0	7
20051	ESTANCIA BAJO DE LAS TUMANAS	5447	0	18
20052	LA ELOISA	3403	0	7
20053	LAGUNA ALFONSO	3403	0	7
20054	LAS PALMITAS	3403	0	7
20055	ESTANCIA EL CHA	5447	0	18
20056	LOMAS DE GALARZA	3403	0	7
20057	ANTONIO TOMAS	3125	0	8
20058	ESTANCIA EL JUMEAL	5447	0	18
20059	ESTANCIA EL MOLINO	5447	0	18
20060	LOMAS ESQUIVEL	3403	0	7
20061	MALOYA	3403	0	7
20062	MONTE GRANDE	3403	0	7
20063	ORATORIO	3403	0	7
20064	PUEBLITO ESPINOSA	3403	0	7
20065	RALERA SUD	3401	0	7
20066	ESTANCIA LA ESCALERA	5447	0	18
20067	ESTANCIA LA FLORIDA	5447	0	18
20068	ESTANCIA LA LATA	5447	0	18
20069	RIACHUELITO	3403	0	7
20070	ESTANCIA QUIROGA	5447	0	18
20071	RIACHUELO BARDECI	3403	0	7
20072	ALTAMIRANO NORTE	3177	0	8
20073	ESTANCIA RIO VERDE	5447	0	18
20074	RINCON DE LAS MERCEDES	3403	0	7
20075	ESTANCIA SAN ROQUE	5447	0	18
20076	SANTA TERESA	3403	0	7
20077	ALTAMIRANO SUD	3174	0	8
20078	SANTOS LUGARES	3403	0	7
20079	SOMBRERO	3403	0	7
20080	TIQUINO	3403	0	7
20081	ARROYO OBISPO	3174	0	8
20082	TRES CRUCES	3403	0	7
20083	TRIPOLI	3403	0	7
20084	VECINDAD	3403	0	7
20085	BACACAY	3346	0	7
20087	COSTA GUAVIRAVI	3346	0	7
20088	ESTANCIA EL POLEAR	5447	0	18
20089	ESTANCIA ELIZONDO	5447	0	18
20090	CUATRO BOCAS	3174	0	8
20091	EL CHAJA	3174	0	8
20092	ESTABLECIMIENTO SAN EDUARDO	3177	0	8
20093	ESTABLECIMIENTO SAN EUSEBIO	3177	0	8
20094	ESTABLECIMIENTO SAN FRANCISCO	3177	0	8
20095	HIPODROMO	3174	0	8
20096	KILOMETRO 183	3176	0	8
20097	KILOMETRO 220	3174	0	8
20098	MOLINO BOB	3174	0	8
20099	PRIMER CUARTEL	3174	0	8
20100	PUENTE OBISPO	3174	0	8
20101	DIST RAICES AL NORTE	3177	0	8
20102	SAUCE NORTE	3174	0	8
20103	SEGUNDO CUARTEL	3174	0	8
20104	SOLA	3176	0	8
20105	ESTACION SOLA	3176	0	8
20106	KILOMETRO 180	3174	0	8
20107	KILOMETRO 189	3174	0	8
20108	KILOMETRO 192	3174	0	8
20109	KILOMETRO 200	3177	0	8
20110	QUITA QUINA	8370	0	15
20111	ESTANCIA LA ARBOLEDA	3231	0	7
20112	ESTANCIA EL PORVENIR	3231	0	7
20113	ESTANCIA LA LOMA ALTA	3231	0	7
20114	ESTANCIA LOS MILAGROS	3231	0	7
20115	ESTANCIA POZO CUADRADO	3231	0	7
20116	ESTANCIA SAN JUAN	3231	0	7
20117	ESTANCIA SAN SOLANO	3231	0	7
20118	ESTANCIA SOLEDAD	3231	0	7
20119	ESTINGANA	3346	0	7
20120	LA OLLITA	3174	0	8
20121	SAN MIGUEL	3231	0	7
20122	ARROYO BALMACEDA	3483	0	7
20123	BASTIDORES	3483	0	7
20124	CARANDAITI	3485	0	7
20125	CARRETA PASO	3485	0	7
20126	RINCON DE LAS GUACHAS	3174	0	8
20127	CASUALIDAD	3483	0	7
20128	COLONIA	3485	0	7
20129	COLONIA LA UNION	3485	0	7
20130	COLONIA MADARIAGA	3485	0	7
20131	ARROYO MOLINO	3260	0	8
20132	CURUPAYTI	3485	0	7
20133	CURUZU LAUREL	3485	0	7
20134	IPACARAPA	3485	0	7
20135	LOS SAUCES	3485	0	7
20136	MBOI CUA	3485	0	7
20137	MONTA	3485	0	7
20138	ESTANCIA MARADONA	5401	0	18
20139	CATALAN CUE	3483	0	7
20140	OBRAJE DEL VASCO	3403	0	7
20141	BALENGO	3448	0	7
20142	CAFARRE	3445	0	7
20143	COSTA SANTA LUCIA	3445	0	7
20144	CAPITA MINI	3448	0	7
20145	EL SOCORRO	3445	0	7
20146	ESTANCIA DEL MEDIO	3474	0	7
20147	COLONIA BELGA AMERICANA	3244	0	8
20148	ESTERO PIRU	3474	0	7
20149	ISLA ALTA	3448	0	7
20150	KILOMETRO 382	3448	0	7
20151	CAMPO LAS LIEBRES	5460	0	18
20152	LA ARMONIA	3446	0	7
20153	LA CELINA	3474	0	7
20154	LA LOLITA	3446	0	7
20155	LA MATILDE	3445	0	7
20156	LAGUNA AVALOS	3448	0	7
20157	LAS LAGUNAS	3446	0	7
20158	LAS MATRERAS	3445	0	7
20159	LAUREL	3448	0	7
20160	COLONIA LEVEN	3244	0	8
20161	LEON CUA	3445	0	7
20162	LOMAS FLORIDAS	3445	0	7
20163	LUIS GOMEZ	3445	0	7
20164	MANANTIALES	3448	0	7
20165	MATRERA	3448	0	7
20166	MOJON	3448	0	7
20167	PASO CHA	3474	0	7
20168	PIRRA PUY	3448	0	7
20169	AGUADITAS	5461	0	18
20170	ROSADO GRANDE	3448	0	7
20171	SALDANA	3405	0	7
20172	SALINAS GANDES	3448	0	7
20173	SAN GUILLERMO	3474	0	7
20174	SAN JUAN	3448	0	7
20175	SANTA IRENE	3474	0	7
20176	SERIANO CUE	3446	0	7
20177	TACUARITAS	3474	0	7
20178	YAPUCA	3474	0	7
20179	YATAY CORA	3474	0	7
20180	PIEDRA COLORADA	5447	0	18
20181	COLONIA UBAJAY	3260	0	8
20182	ALGARROBO PARAJE	3445	0	7
20183	PALMIRA	3448	0	7
20184	PUEBLO DE JULIO	3445	0	7
20185	SAN ANTONIO	3474	0	7
20186	EL POTRERO	2821	0	8
20187	BOQUERON	3340	0	7
20188	CAMBAL	3340	0	7
20189	COLONIA SAN MATEO	3340	0	7
20190	RAMBLON	5435	0	13
20191	COLONIA GOBERNADOR RUIZ	3340	0	7
20192	SIERRA ANSILTA	5539	0	13
20193	SIERRA DE LAS HIGUERAS	5545	0	13
20194	CUAY CHICO	3340	0	7
20195	SIERRA DEL TONTAL	5539	0	13
20196	DON MAXIMO	3340	0	7
20197	ESTANCIA BUENA VISTA	3340	0	7
20198	ESTANCIA CASURINA	3340	0	7
20199	ESTANCIA BELLA VISTA	3272	0	8
20200	ESTANCIA DURRUTI	3340	0	7
20201	ESTANCIA EL OMBU	3340	0	7
20202	ESTANCIA SAN MATEO	3340	0	7
20203	ESTANCIA SAN MIGUEL	3340	0	7
20204	ESTANCIA COLONIA EL OMBU	3272	0	8
20205	GOBERNADOR RUIZ	3340	0	7
20206	GUAY GRANDE	3340	0	7
20207	ISLA SAN MATEO	3340	0	7
20208	KILOMETRO 891	5313	0	12
20209	ESTANCIA COLONIA EL TOROPI	3272	0	8
20210	ITA CUA	3340	0	7
20211	KILOMETRO 921	5313	0	12
20212	LOS BRETES	3340	0	7
20213	NUEVO PARAISO	3340	0	7
20214	ESTANCIA CNIA LA PRIMAVERA	3272	0	8
20215	ESTANCIA COLONIA LA TAPERA	3272	0	8
20216	ESTANCIA COLONIA PERIBEBUY	3272	0	8
20217	ALGARROBO	5533	0	13
20218	ESTANCIA COLONIA SAN PEDRO	3272	0	8
20219	PASO CONCEPCION	3340	0	7
20220	PUERTO LAS LAJAS	3340	0	7
20221	ESTANCIA CNIA SANTA ELENA	3272	0	8
20222	LAS TUSCAS	5310	0	12
20223	ESTANCIA COLONIA SANTA ELOISA	3272	0	8
20224	SE	5310	0	12
20225	PUERTO LAS TACUARITAS	3340	0	7
20226	PUERTO PIEDRA	3340	0	7
20227	ESTANCIA COLONIA SANTA JUANA	3272	0	8
20228	SAN ANTONIO	3340	0	7
20229	ESTANCIA CNIA STA TERESA	3272	0	8
20230	SAN FRANCISCO	3340	0	7
20231	SAN GABRIEL	3340	0	7
20232	NOGUEIRA	8315	0	15
20233	ESTANCIA EL TOROPI	3272	0	8
20234	TABLADA	3340	0	7
20235	RINCON MERCEDES ESTANCIA	3340	0	7
20236	ESTANCIA LOS VASCOS	3272	0	8
20237	TOPADOR	3340	0	7
20238	TRES TAPERAS	3340	0	7
20240	GERIBEBUY	3248	0	8
20241	ARISTIA	3463	0	7
20242	GOBERNADOR URQUIZA	3248	0	8
20243	ARROYO SECO	3463	0	7
20244	BARRANCAS	3463	0	7
20245	BUENA VENTURA	3463	0	7
20246	BUENA VISTA	3463	0	7
20247	CAMPO MAIDANA	3463	0	7
20248	CAMPO POY	3463	0	7
20249	GRUPO PARRERO	3244	0	8
20250	CAVI POY	3463	0	7
20251	DOS HERMANAS	3463	0	7
20252	EL TESORO	3463	0	7
20253	EL TIGRE	3463	0	7
20254	ESTANCIA RINCON GRANDE	3463	0	7
20255	FERRET	3463	0	7
20256	LA CONCEPCION	3463	0	7
20257	KILOMETRO 108	3260	0	8
20258	LA DELICIA	3463	0	7
20259	LA ESTRELLA	3463	0	7
20260	LA FE	3463	0	7
20261	LA GARCIA	3463	0	7
20262	KILOMETRO 112	3260	0	8
20263	LA LEONOR	3463	0	7
20264	LA PORTE	3463	0	7
20265	KILOMETRO 115	3260	0	8
20266	LAS TAPERAS	3463	0	7
20267	LIMAS CUE	3463	0	7
20268	KILOMETRO 208	3172	0	8
20269	LOMA ALTA	3463	0	7
20270	MARTIN GARCIA	3463	0	7
20271	KILOMETRO 231	3170	0	8
20272	PASO BERMUDEZ	3463	0	7
20273	PASO DE MULA	3463	0	7
20274	KILOMETRO 242	3272	0	8
20275	PUJOL BEDOYA	3463	0	7
20276	PUNTAS DE FRANCISCO GOMEZ	3463	0	7
20277	PUNTAS DEL TIGRE	3463	0	7
20278	KILOMETRO 244	3272	0	8
20279	RINCON DE ANIMAS	3463	0	7
20280	RINCON DEL TIGRE	3463	0	7
20281	KILOMETRO 253	3272	0	8
20282	SAN JOSE	3463	0	7
20283	SAN LUIS CUE	3463	0	7
20284	LOS SAUCES	5537	0	13
20285	SANTA ROSA	3463	0	7
20286	SANTA TERESA	3463	0	7
20287	EL TROMEN	8353	0	15
20288	KILOMETRO 268	3263	0	8
20289	SAUCESITO	3463	0	7
20290	TULUMAYA	5533	0	13
20291	SOTO	3463	0	7
20292	VILLA ORTIZ	3463	0	7
20293	SAN MARTIN	3463	0	7
20294	KILOMETRO 270	3261	0	8
20295	VILLA SOTO	3463	0	7
20296	VILLA TESARO	3463	0	7
20297	KILOMETRO 283	3263	0	8
20298	CERRILLOS AL SUD	5501	0	13
20300	KILOMETRO 293	3263	0	8
20301	COLONIA FUNES	5509	0	13
20302	DIQUE RIO MENDOZA	5507	0	13
20303	EL CARRIZAL DE ABAJO	5509	0	13
20304	LA AMIGUITA	3244	0	8
20305	EL SALTO	5549	0	13
20306	GLACIARES DEL RIO BLANCO	5549	0	13
20307	LOS FILTROS	5505	0	13
20308	PUESTO LA JARILLA	5507	0	13
20309	LA BARRACA	3260	0	8
20310	LUIN COCO	8353	0	15
20311	VILLA LUJAN	3481	0	7
20312	LA GOYA	3260	0	8
20313	LA SESTEADA	3260	0	8
20314	PALAU	8353	0	15
20315	ALTO DEL PLOMO	5549	0	13
20316	CA	8375	0	15
20317	LAS CARDITAS	5549	0	13
20318	ESTANCIA EL CARMEN	3460	0	7
20319	LAS COLONIAS	5509	0	13
20320	PASO ANCHO	3460	0	7
20321	ADOLFO E CARRANZA	5263	0	12
20322	AMPATA	5300	0	12
20323	CARRIZAL	5306	0	12
20324	CARRIZAL ESTACION FCGB	5300	0	12
20325	CHUMBICHA	5300	0	12
20326	EL BARRIAL	5301	0	12
20327	LINEA 19	3244	0	8
20328	EL CANTADERO	5300	0	12
20329	LINEA 20	3244	0	8
20330	FINCA LOS ALAMOS	5531	0	13
20331	EL MEDANO	5263	0	12
20332	EL PLUMERILLO	5300	0	12
20333	EL QUEBRACHO	5301	0	12
20334	LINEA 24	3170	0	8
20335	ESTACION 69	5300	0	12
20336	FLAMENCO	5300	0	12
20337	JESUS MARIA	5300	0	12
20338	LINEA 25	3170	0	8
20339	KILOMETRO 861	5300	0	12
20340	KILOMETRO 875	5300	0	12
20341	LA FLOR	5300	0	12
20342	LA LANCHA	5300	0	12
20343	LIONEL	3244	0	8
20344	LA LATA	5300	0	12
20345	LAS CA	5300	0	12
20346	AGUA DE DIAZ	5545	0	13
20347	LAS HIGUERILLAS	5300	0	12
20348	BARRA BONITA	3357	0	14
20349	LAS PADERCITAS	5300	0	12
20350	QUININELIU	8341	0	15
20351	POZO ESCONDIDO	5300	0	12
20352	CAMPOS SALLES	3363	0	14
20353	SAN AGUSTIN	5300	0	12
20354	SAN GUILLERMO	5300	0	12
20355	FILEMON POSE	3363	0	14
20356	SAN JAVIER	5300	0	12
20357	SAN JUAN	5300	0	12
20358	SANTA ROSA	5300	0	12
20359	SANTO DOMINGO	5300	0	12
20360	AGUA RICA	5611	0	13
20361	COLONIA AZARA	3350	0	14
20362	NOVIBUCO PRIMERO	3170	0	8
20363	SIERRA BRAVA	5301	0	12
20364	BARREAL JOSE LUIS	5613	0	13
20365	BA	5611	0	13
20366	PUERTO AZARA	3350	0	14
20367	LOTE 117	3317	0	14
20368	ARROYO	3300	0	14
20369	PASO DEL MOLINO	3260	0	8
20370	DON HORACIO	3300	0	14
20371	EL REPOSO	3300	0	14
20372	EL TROPEZON	3300	0	14
20373	ESTANCIA ITAEMBE	3300	0	14
20374	ITAEMBE MINI	3300	0	14
20375	CHARCO VACAS	5613	0	13
20376	COIHUECO NORTE	5611	0	13
20377	EL CENIZO	5645	0	13
20379	KILOMETRO 595	3300	0	14
20380	EL MOLLAR	5611	0	13
20381	LA MILAGROSA	3300	0	14
20382	EX FORTIN MALARGUE	5611	0	13
20383	PUEBLO NUEVO	3170	0	8
20384	LA DIVISORIA	5549	0	13
20385	LAS VERTIENTES	3300	0	14
20386	LA VALENCIANA	5611	0	13
20387	PEDRO NU	3300	0	14
20388	PUERTO RINCON ESCALONA	5613	0	13
20389	PUERTO CAMPINCHUELO	3261	0	8
20390	PUESTO AGUA DE LA MERINA	5613	0	13
20391	SANTA CATALINA	3196	0	7
20392	PUESTO GENTILE	5611	0	13
20393	PUERTO VIEJO	3260	0	8
20394	REFUGIO MILITAR GRAL ALVARADO	5613	0	13
20411	SAN JOSE CAACATI	3407	0	7
20416	TAPERA DE LOS VIEJOS	5613	0	13
20418	LAS TAGUAS	5613	0	13
20420	LOMA JAGUEL DEL GAUCHO	5613	0	13
20421	LOS ARROYOS	5611	0	13
20422	ALGARROBAL PUISOYE	3405	0	7
20423	PUERTO LUJAN	3300	0	14
20424	LUANCO	5611	0	13
20426	OJO DE AGUA	5611	0	13
20427	LA ROTONDA	3300	0	14
20428	VILLA EMILIA	3300	0	14
20429	TRES ALDEAS	3170	0	8
20430	LA LOMA TORRENT	3344	0	7
20431	SANTA CRUZ	5301	0	12
20432	COLONIA CUNCI	3382	0	14
20433	COLONIA DELICIA	3382	0	14
20434	COLONIA DURAN	3382	0	14
20435	PUERTO MADO	3382	0	14
20436	PUERTO PATICAA	3382	0	14
20437	VILLA SAN JUSTO	3262	0	8
20438	PUERTO EL DORADO	3382	0	14
20439	CAMPI	3366	0	14
20440	PARAJE ESTELINA	3366	0	14
20441	PARAJE DOS HERMANAS	3360	0	14
20442	PARAJE GRANADO	3366	0	14
20443	PARAJE INTERCONTINENTAL	3366	0	14
20444	CAMPO ALEGRE	3366	0	14
20445	COLONIA EL PESADO	3366	0	14
20446	INVERNADA	3454	0	7
20447	COLONIA TRES MARIAS	3366	0	14
20448	PARAJE AZOPARDO	3366	0	14
20449	HOTEL PORTEZUELO DEL VIENTO	5613	0	13
20450	PARAJE VILLA UNION	3366	0	14
20451	ARROYO JACINTO	3101	0	8
20452	ALTA UNION	3364	0	14
20453	COLONIA CHAFARIZ	3364	0	14
20454	COLONIA PRIMAVERA	3364	0	14
20455	PALO LABRADO	5380	0	12
20456	CRUCE LONDERO	3364	0	14
20457	GUAIBICHU	3364	0	14
20458	LAS MERCEDES	3364	0	14
20459	MESA REDONDA	3364	0	14
20460	MIGUEL GUEMES	3364	0	14
20461	MOCONA	3364	0	14
20462	PUERTO PARAISO	3364	0	14
20463	RIO YABOTAY	3364	0	14
20464	ESTABLECIMIENTO PUNTA ALTA	3155	0	8
20465	CU	3364	0	14
20466	EL SOCORRO	3364	0	14
20467	CAA CARAI	3302	0	7
20468	KILOMETRO 286	3364	0	14
20469	LUJAN	3364	0	14
20470	LOS CORRALES	5621	0	13
20471	PARAISO	3364	0	14
20472	PUERTO LIBERTAD	3370	0	14
20473	SEGUNDA ZONA	3374	0	14
20474	PLANCHADA BANDERITA	3370	0	14
20475	PUERTO CANOAS	3370	0	14
20476	PUERTO PAULITO	3370	0	14
20477	LA PUPI	3358	0	7
20478	PUERTO YACUY	3370	0	14
20479	VILLA FLOR	3370	0	14
20480	PUERTO WANDA	3370	0	14
20481	TIRICA	3370	0	14
20482	LIBERTAD	3302	0	7
20484	LOMA ALTA	3302	0	7
20485	LOMA NEGRA	3302	0	7
20486	LOMA POY	3302	0	7
20487	LOS GEMELOS	3302	0	7
20488	PUESTO LA CACHACA	5613	0	13
20489	PUESTO LA NEGRITA	5613	0	13
20490	PUESTO LA NIEBLA	5613	0	13
20491	PUESTO LA PORTE	5613	0	13
20492	COLONIA TARANCO	3315	0	14
20493	KILOMETRO 26	3315	0	14
20494	PUESTO LA SUIZA	5613	0	13
20495	CITRUS	3384	0	14
20496	COLONIA SANTA TERESA	3384	0	14
20497	ESTANCIA SANTA RITA	3384	0	14
20498	KILOMETRO 34	3384	0	14
20499	PUESTO MARFIL	5611	0	13
20500	KILOMETRO 60	3384	0	14
20501	PUESTO RINCON DEL SAUCE	5613	0	13
20502	LA MISIONERA	3384	0	14
20503	PUESTO LA INVERNADA	5613	0	13
20504	LA POSTA	3384	0	14
20505	PUESTO MALO	5613	0	13
20506	MACACA	3384	0	14
20507	MACACO	3384	0	14
20508	VILLA OJO DE AGUA	3384	0	14
20509	KILMETRO 165	3153	0	8
20510	CRUCECITAS SANTA LUCIA	3440	0	7
20511	DO	3360	0	14
20512	VILLA SARUBBI	3360	0	14
20513	VILLA UNION	3384	0	14
20514	COLONIA FLORIDA	3384	0	14
20515	SIERRA DE ORO	3360	0	14
20516	PUERTO NUEVO	3322	0	14
20517	TACUARA	3322	0	14
20518	SANTA LUCIA 9 DE JULIO	3445	0	7
20519	INVERNADA DE ITACARUARE	3353	0	14
20520	ASERRADERO ECHEVERRIA	3364	0	14
20521	ASERRADERO PI	3364	0	14
20522	COLONIA FORTALEZA	3364	0	14
20523	COLONIA GRAMADO	3364	0	14
20524	COLONIA JUANITA	3364	0	14
20525	PASO DEL ABRA	3153	0	8
20526	COLONIA LA CHILLITA	3364	0	14
20527	COLONIA LA GRUTA	3364	0	14
20528	COLONIA LA POLACA	3364	0	14
20529	COLONIA MONDORI	3364	0	14
20530	COLONIA PADUAN	3364	0	14
20531	PUERTO ESQUINA	3155	0	8
20532	COLONIA PALMERA	3364	0	14
20533	COLONIA PUERTO ROSALES	3364	0	14
20534	COLONIA SIETE ESTRELLAS	3364	0	14
20535	PUERTO LOPEZ	3101	0	8
20536	SANTA ROSA	3364	0	14
20537	VILLA DON BOSCO	3364	0	14
20538	QUEBRACHITOS	3153	0	8
20539	RINCON DE CORREA	5611	0	13
20540	ESTANCIA LA ARGENTINA	5577	0	13
20541	RINCON DE NOGOYA	3155	0	8
20542	BAJADA DEL SAUCE	5569	0	13
20543	CEPILLO VIEJO	5569	0	13
20544	COLONIA CHATO	5569	0	13
20545	DIVISADERO NEGRO	5569	0	13
20546	JAUCHA	5569	0	13
20547	LOS TOSCALES	5569	0	13
20548	VILLA ANGELICA	2000	0	8
20549	VILLA LIBERTAD	3228	0	8
20550	ALDEA SAN GREGORIO	3287	0	8
20551	ALDEA SAN JORGE	3252	0	8
20552	SAN FRANCISCO GUAVIRARI	3232	0	7
20553	CAMPO DE VILLAMIL	3241	0	8
20554	PORTILLO DE LA YESERA	5569	0	13
20555	PORTILLO DE LAS CABEZAS	5569	0	13
20556	PORTILLO DEL PAPAL	5569	0	13
20557	PORTILLO DEL VIENTO	5569	0	13
20558	PORTILLO OCCIDENTAL DEL BAYO	5569	0	13
20559	PORTILLO PEDERNALES	5569	0	13
20560	LA CIENAGA	5350	0	12
20561	PUESTO CANALES	5569	0	13
20562	PUESTO EL CARRIZALITO	5569	0	13
20563	PUESTO J CASTRO	5569	0	13
20564	SAN JOSE	5350	0	12
20565	PUESTO LUFFI	5569	0	13
20566	PUESTO LUNA	5569	0	13
20567	PUESTO MALLIN	5569	0	13
20568	PUESTO OJO DE AGUA	5569	0	13
20569	PUESTO P MONTRIEL	5569	0	13
20570	PUESTO RINCON DE LA PAMPA	5569	0	13
20571	PUESTO SECO	5569	0	13
20572	PUESTO SOSA	5569	0	13
20573	PUESTO VIUDA DE ESTRELLA	5569	0	13
20574	COLONIA GAIMAN	3485	0	7
20575	COLONIA EGIDO	3240	0	8
20576	COLONIA ESPINDOLA	3252	0	8
20577	NARANJITO SAN ROQUE	3448	0	7
20578	COLONIA FEIMBERG	3252	0	8
20579	COLONIA GUIBURG	3252	0	8
20580	SALDANA 9 DE JULIO	3445	0	7
20581	COLONIA LA BLANQUITA	3254	0	8
20582	LAGUNA DE VACAS	9121	0	5
20583	COLONIA ATUEL	5623	0	13
20584	COLONIA LA MORENITA	3254	0	8
20585	COM NAC DE ENERGIA ATOMICA	5600	0	13
20586	COLONIA LA PAMPA	3254	0	8
20587	CUPILES	5595	0	13
20588	CARRIZALILLO	5385	0	12
20589	CASAGATE	5385	0	12
20590	EL CARRIZAL	5475	0	12
20591	EL ALGARROBO	5595	0	13
20592	LA AGUADITA	5385	0	12
20593	LAS BARRANCAS	5471	0	12
20594	EL VILTEGUINO	5594	0	13
20595	ESTANCIA LAS CHILCAS	5595	0	13
20596	LA LATA	5600	0	13
20597	LAGUNITA	5527	0	13
20598	FRONTERA DE RIO PICO	9225	0	5
20599	NEGRO QUEMADO	5623	0	13
20600	NIHUIL	5605	0	13
20601	LAGO PAZ	9225	0	5
20602	COLONIA VILLAGUAYCITO	3241	0	8
20603	CURUPI	3240	0	8
20604	EL CARBALINO	5592	0	13
20605	LA BANDERA	5592	0	13
20606	LOMA LARGA	5385	0	12
20607	EMPALME NEILD	3240	0	8
20608	PULUCHAN	5385	0	12
20609	SAN PEDRO	5385	0	12
20610	SAN RAMON	5385	0	12
20611	CASA DE LAS PE	5560	0	13
20612	SAN ROQUE	5385	0	12
20613	COLONIA DE LAS MULAS	5560	0	13
20614	COLONIA DEL DIABLO	5560	0	13
20615	COLONIA FARO	5560	0	13
20616	COLONIA LA ESCONDIDA	5560	0	13
20617	COLONIA LA TORRECILLA	5560	0	13
20618	COLONIA LOS OSCUROS	5560	0	13
20619	COLONIA LOS TAPONES	5560	0	13
20620	DIQUE DEL VALLE DE UCO	5560	0	13
20621	EL PORTILLO	5560	0	13
20622	KILOMETRO 160	3142	0	8
20623	EL TOPON	5560	0	13
20624	EL TOSCAL	5560	0	13
20625	ESTANCIA MALLEA	5560	0	13
20626	ESTANCIA AVEIRO	5560	0	13
20627	ESTANCIA BELLA VISTA	5560	0	13
20628	KILOMETRO 279	3240	0	8
20629	ESTANCIA CORREA	5560	0	13
20630	ESTANCIA EL CARRIZALITO	5560	0	13
20631	ESTANCIA GUINAZU	5560	0	13
20632	KILOMETRO 284	3240	0	8
20633	ESTANCIA LA ROSA	5560	0	13
20634	ESTANCIA LAS HIGUERAS	5560	0	13
20635	ESTANCIA LOS CHACAYES	5560	0	13
20636	KILOMETRO 285	3240	0	8
20637	ESTANCIA SILVA	5560	0	13
20638	LAS PINTADAS	5560	0	13
20639	LOMA CHATA	5560	0	13
20640	LOS COMETIERRAS	5560	0	13
20641	KILOMETRO 288	3240	0	8
20642	PASO LOS PALOS	5560	0	13
20643	PORTILLO DE PINQUENES	5560	0	13
20644	PORTILLO DEL DIABLO	5560	0	13
20645	POTRERO SAN PABLO	5560	0	13
20646	KILOMETRO 306	3252	0	8
20647	PUESTO EL MANZANO	5560	0	13
20648	PUESTO LA TOSCA	5560	0	13
20649	PUESTO MANZANITO	5560	0	13
20650	KILOMETRO 325	3254	0	8
20651	PUESTO MIRONDA	5560	0	13
20652	PUESTO SANTA MARIA	5560	0	13
20653	LA JOYA	3244	0	8
20654	EL ZAMPAL	5561	0	13
20655	GUALTALLARY	5561	0	13
20656	LA ARBOLEDA	5561	0	13
20657	PUESTO ALFARFA	5561	0	13
20658	PUESTO LA JERILLA	5561	0	13
20659	LAGUNA LARGA	3241	0	8
20660	SANTA CLARA	5561	0	13
20661	LAS PAJITAS	3240	0	8
20662	LUCAS NORTE	3241	0	8
20663	MIGUEL J PERLIZA	3246	0	8
20664	MOJONES NORTE	3241	0	8
20665	CHA	5361	0	12
20667	MOJONES SUR PRIMERO	3241	0	8
20668	EL POTRERILLO	5361	0	12
20669	LA HIGUERA	5361	0	12
20670	MOJONES SUR SEGUNDO	3241	0	8
20671	SANTO DOMINGO FAMATINA	5361	0	12
20672	PASO DE LA LAGUNA	3241	0	8
20673	PASO DE LA LEGUA	3240	0	8
20674	PUEBLO DOMINGUEZ	3246	0	8
20675	PUENTE DE LUCAS	3216	0	8
20676	RACHEL	3246	0	8
20678	DIST RAICES AL SUD	3177	0	8
20679	RINCON LUCAS NORTE	3241	0	8
20680	RINCON LUCAS SUD	3241	0	8
20681	EL GARABATO	5380	0	12
20682	EL QUEMADO	5380	0	12
20683	GOBERNADOR GORDILLO	5380	0	12
20684	LA INVERNADA	5380	0	12
20685	POZO DE LA ORILLA	5380	0	12
20686	QUEBRACHO HERRADO	5380	0	12
20687	ZENON ROCA	3240	0	8
20688	PARECITAS	5355	0	12
20689	PASTOS LARGOS	5355	0	12
20690	PUNTA DE AGUA	5355	0	12
20692	ARBOL NEGRO	2356	0	22
20693	AZUCENA	2356	0	22
20694	CAMPO RAMON LAPLACE	2356	0	22
20695	CAPILLA	2356	0	22
20696	CLEVELAND	2356	0	22
20697	ALGARROBO GRANDE	5473	0	12
20699	BAJO HONDO	5473	0	12
20700	BALDE DEL QUEBRACHO	5473	0	12
20701	CORTADERAS EMBARCADERO FCGB	5474	0	12
20702	EL ABRA	5473	0	12
20703	EL VALDECITO	5473	0	12
20704	KILOMETRO 732	5717	0	12
20705	KILOMETRO 682	5275	0	12
20706	LA AMERICA	5473	0	12
20707	LA CHILCA	5473	0	12
20708	LA ENVIDIA	5473	0	12
20709	LA ESQUINA	5473	0	12
20710	LA LIBERTAD	5473	0	12
20711	LA REPRESA	5471	0	12
20712	AGUA COLORADA	4119	0	24
20713	POZO DE PIEDRA	5473	0	12
20714	SAN NICOLAS	5473	0	12
20715	SAN SOLANO	5473	0	12
20716	BAJO CORRAL DE ISAAC	5473	0	12
20717	AGUAS BLANCAS	4119	0	24
20718	ALTO DE MEDINA	4117	0	24
20719	ALTO VERDE	4119	0	24
20720	COLONIA ERMELINDA	2356	0	22
20721	COLONIA PAULA	2356	0	22
20722	DO	2356	0	22
20723	EL DESTINO	2356	0	22
20726	ANTU MAPU	4119	0	24
20727	ASNA YACO	4119	0	24
20728	BENJAMIN ARAOZ	4119	0	24
20729	BENJAMIN PAZ	4119	0	24
20730	BURRUYACU	4119	0	24
20731	CALERA ACONQUIJA	4119	0	24
20732	CALIFORNIA	4119	0	24
20733	CA	4119	0	24
20734	CA	4119	0	24
20735	CASA DEL ALTO	4119	0	24
20736	CASALES	4119	0	24
20737	CHAMICO	4119	0	24
20738	EL CHALET	9207	0	5
20739	CHORRILLOS	4119	0	24
20740	COLONIA SARMIENTO	4101	0	24
20741	CONCEPCION	4119	0	24
20742	COOPERATIVA AGRONOMICA	4119	0	24
20743	COROMAMA	4119	0	24
20744	EL ALTO	5383	0	12
20745	EL BORDO	5276	0	12
20746	CRUZ DE ABAJO	4119	0	24
20747	EL QUEBRACHAL	5383	0	12
20748	KILOMETRO 645	5276	0	12
20749	LA CHIMENEA	5383	0	12
20750	LA CIENAGA	5381	0	12
20751	DESCANSO	4119	0	24
20752	MONTE GRANDE	5383	0	12
20753	SAN RAMON	5383	0	12
20754	DESMONTE	4119	0	24
20755	TRES CRUCES	5383	0	12
20756	EL ASERRADERO	4119	0	24
20757	EL ATACAL	4119	0	24
20758	EL AZUL	4119	0	24
20759	EL CASTORAL	4119	0	24
20760	EL CHURQUI	4119	0	24
20761	EL CRUCE	4119	0	24
20762	EL ESTABLO	4119	0	24
20763	EL FRASQUILLO	4119	0	24
20764	EL GUAYACAN	4178	0	24
20765	EL INTERES	4119	0	24
20766	EL JARDIN	4119	0	24
20767	EL MATAL	4119	0	24
20768	LAGUNA RINCON DEL MORO	9207	0	5
20769	EL MORADO	4119	0	24
20770	EL NARANJITO	4119	0	24
20771	EL ONCE	4119	0	24
20772	EL PALOMAR	4187	0	24
20773	EL PORVENIR	4119	0	24
20774	BALDE SALADO	5274	0	12
20775	CUATRO ESQUINAS	5274	0	12
20776	EL CONSUELO	5274	0	12
20777	EL MEDANITO	5272	0	12
20778	HUNQUILLAL	5274	0	12
20779	KILOMETRO 619	5272	0	12
20780	LOS BARRIALITOS	5274	0	12
20781	EL SINQUIAL	4119	0	24
20782	EL SUNCHAL	4119	0	24
20783	EL TIPAL	4119	0	24
20784	EL TRIUNFO	4119	0	24
20785	GUALJAINA	9201	0	5
20786	ESCUELA 112	4187	0	24
20787	ESCUELA 118	4187	0	24
20788	ESCUELA 149	4187	0	24
20789	ESCUELA 150	4187	0	24
20790	ESCUELA 152	4187	0	24
20791	ESCUELA 166	4187	0	24
20792	ESCUELA 167	4187	0	24
20793	ESCUELA 173	4187	0	24
20794	ESCUELA 177	4187	0	24
20795	ESCUELA 205	4187	0	24
20796	ESCUELA 208	4187	0	24
20797	ESCUELA 211	4187	0	24
20798	ESCUELA 242	4187	0	24
20799	ESCUELA 246	4187	0	24
20800	ESCUELA 250	4187	0	24
20801	ESCUELA 262	4187	0	24
20802	ESCUELA 275	4187	0	24
20803	ESCUELA 276	4187	0	24
20804	BAJO DE GALLO	5386	0	12
20805	ESCUELA 278	4187	0	24
20807	ESCUELA 292	4187	0	24
20808	ESCUELA 30	4187	0	24
20809	CUEVA DEL CHACHO	5386	0	12
20810	ESCUELA 310	4187	0	24
20811	EL CHIFLON	5386	0	12
20812	ESCUELA 313	4187	0	24
20813	GUAYAPA	5386	0	12
20814	LOS BALDECITOS	5386	0	12
20815	ESCUELA 314	4187	0	24
20816	ESCUELA 326	4187	0	24
20817	LOS MOGOTES COLORADOS	5386	0	12
20818	ESCUELA 331	4187	0	24
20819	PUESTO TALITA	5386	0	12
20820	REPRESA DE LA PUNTA	5386	0	12
20821	TERMAS	5386	0	12
20822	ESCUELA 339	4187	0	24
20823	ESCUELA 34	4187	0	24
20824	ESCUELA 344	4187	0	24
20825	BALDE SAN ISIDRO	5386	0	12
20826	ESCUELA 347	4187	0	24
20827	ESCUELA 353	4187	0	24
20828	ESCUELA 366	4187	0	24
20829	ESCUELA 368	4187	0	24
20830	ESCUELA 369	4187	0	24
20831	ESCUELA 375	4187	0	24
20832	ESCUELA 386	4187	0	24
20833	ESCUELA 4	4187	0	24
20834	ESCUELA 5	4187	0	24
20835	LAS PADERCITAS	5355	0	12
20836	ESCUELA 57	4187	0	24
20837	ESCUELA 60	4187	0	24
20838	ESCUELA 61	4187	0	24
20839	ESCUELA 62	4187	0	24
20840	ESCUELA 7	4187	0	24
20841	ESCUELA 83	4187	0	24
20842	ESCUELA 91	4187	0	24
20843	ESCUELA ADOLFO ALSINA	4187	0	24
20844	ESCUELA ALBERTO SOLDATI	4187	0	24
20845	ESCUELA ALVAREZ CONDARCO	4187	0	24
20846	LA ESPERANZA	4448	0	17
20847	ESCUELA CAMPAMENTO EL PLUMERIL	4187	0	24
20848	LA LOMITA	4448	0	17
20849	ESCUELA CAP CANDELARIA	4187	0	24
20850	ESCUELA CAUPOLICAN MOLINA	4187	0	24
20851	LAGUNITA	4446	0	17
20852	LAS CA	4434	0	17
20853	ESCUELA DIEGO DE VILLAFA	4187	0	24
20854	LAS FLECHAS	4448	0	17
20855	ESCUELA LEO HUASI	4187	0	24
20856	LAS HECHERAS	4434	0	17
20857	ESCUELA MANUEL COSSIO	4187	0	24
20858	LAS VATEAS	4449	0	17
20859	ESCUELA MARIANO SALAS	4187	0	24
20860	LOS MOLLINEDOS	4448	0	17
20861	ESCUELA PEDRO ARAOZ	4187	0	24
20862	MIRAFLORES	4448	0	17
20863	ESCUELA PUESTITO DE ARRIBA	4187	0	24
20864	PALO A PIQUE	4449	0	17
20865	ESCUELA SALVADOR ALONSO	4187	0	24
20866	POSO DE ALGARROBO	4448	0	17
20867	PASO LA CRUZ	4446	0	17
20868	POZO CANTADO	4448	0	17
20869	ESQUINA	4176	0	24
20870	POZO DEL GREAL	4448	0	17
20871	PUERTA BLANCA	4448	0	17
20872	SALADILLO DE JUAREZ	4448	0	17
20873	SALTA FORESTAL KILOMETRO 50	4449	0	17
20874	SAN FERNANDO	4448	0	17
20875	SAN IGNACIO	4448	0	17
20876	ESTANCIA EL DIAMANTE	4119	0	24
20877	SAN JORGE	4448	0	17
20878	SANTA ANA	4448	0	17
20879	FINCA ANCHORENA	4119	0	24
20880	FINCA CRISTINA	4119	0	24
20881	SANTA TERESA	4190	0	17
20882	FINCA PIEDRA BLANCA	4119	0	24
20883	SANTO DOMINGO ANTA	4449	0	17
20884	SAPO QUEMADO	4448	0	17
20885	SAUZAL	4446	0	17
20886	SIMBOLITO	4448	0	17
20887	TALA MUYO	4446	0	17
20888	GRAMILLA	4119	0	24
20889	SANTA VICTORIA	4128	0	17
20890	VIEJA POZO	4448	0	17
20891	JULIANA	4119	0	24
20893	VINALITO	4452	0	17
20894	WEISBURG	4448	0	17
20895	KILOMETRO 80	4119	0	24
20896	KILOMETRO 94	4119	0	24
20897	LA AGUITA	4119	0	24
20898	LA BANDA	4119	0	24
20899	LA CALERA	4119	0	24
20900	MAR DEL PLATA	7600	0	1
20901	LA CAUTIVA	4119	0	24
20902	LA CORZUELA	4119	0	24
20903	BUENA VISTA	4415	0	17
20904	CACHI ADENTRO	4417	0	17
20905	EL POTRERO	4415	0	17
20906	LA CRUZ DE ARRIBA	4119	0	24
20907	ESCALCHI	4417	0	17
20908	LA ESPERANZA	4187	0	24
20909	LAS CORTADERAS	4415	0	17
20910	LAS PAILAS	4417	0	17
20911	PIUL	4415	0	17
20912	BAYO MUERTO	5470	0	12
20913	CHELCOS	5475	0	12
20914	LA FORTUNA	4119	0	24
20915	POTRERO	4415	0	17
20916	CHEPES VIEJOS	5470	0	12
20917	EL BARRIAL	5471	0	12
20918	LA JUNTA	4119	0	24
20919	RUMIHUASI	4417	0	17
20920	LA LOMA	4119	0	24
20922	EL POTRERILLO R V PE	5475	0	12
20923	LA MARTA	4119	0	24
20924	EL RODEO	5471	0	12
20925	ILLISCA	5471	0	12
20926	LA CARRIZANA	5470	0	12
20927	LA POLA	4119	0	24
20928	LA ESCONDIDA	5471	0	12
20929	LOS OLMOS	5470	0	12
20930	LA PUERTA DE LUCA	4119	0	24
20931	REPRESA DEL MONTE	5470	0	12
20932	SAN ANTONIO	5470	0	12
20933	SAN VICENTE	5470	0	12
20934	LA RUDA	4119	0	24
20935	LA SOLEDAD	4119	0	24
20936	FINCA LA ROSA	4427	0	17
20937	LA TALA	4178	0	24
20938	LA TOMA	4119	0	24
20939	LA CIENEGUITA	4141	0	17
20940	LA TUNA	4149	0	24
20941	LOS ALAMOS	4427	0	17
20942	LA UNION	4119	0	24
20943	MACHO RASTROJO	4141	0	17
20944	QUISCA GRANDE	4141	0	17
20945	LA VERDE	4119	0	24
20946	SAN ISIDRO	4427	0	17
20947	YANCHUYA	4427	0	17
20948	LAS CHACRAS	4119	0	24
20949	ROSARIO	2000	0	21
20950	LAS TRANCAS TRANQUITAS	4101	0	24
20951	LOMA NEGRA	4119	0	24
20952	LOS EUCALIPTOS	4119	0	24
20953	LOS GONZALES	4119	0	24
20954	CAPIHUAS	5327	0	12
20955	CERRO NEGRO	5327	0	12
20956	CORDOBITA	5327	0	12
20957	EL PUEBLITO	5327	0	12
20958	LOS PEDRAZA	4119	0	24
20959	LOS PINOS B	4000	0	24
20961	LAS PE	5301	0	12
20962	MOLLE CHATO	4119	0	24
20963	MONTE REDOMON	4162	0	24
20964	ANTONIO ALICE	4401	0	17
20965	NIO EL PUESTITO	4119	0	24
20966	CALDERA	4401	0	17
20967	CALDERILLA	4401	0	17
20968	BUENA VISTA	5359	0	12
20969	CURUZU	4401	0	17
20970	LA PAMPA	5359	0	12
20971	EL GALLINATO	4401	0	17
20972	PACARA	4119	0	24
20973	KILOMETRO 1125	4401	0	17
20974	LESSER	4401	0	17
20975	LOS MERCADOS	4401	0	17
20976	LOS PE	4401	0	17
20977	DIQUE LOS SAUCES	5300	0	12
20978	LOS SAUCES	4401	0	17
20979	MAYO TORITO	4401	0	17
20980	MONTE	4401	0	17
20981	POTRERO DE CASTILLA	4401	0	17
20982	SAN ALEJO	4401	0	17
20983	SANTA RUFINA	4401	0	17
20984	BOCA DE LA QUEBRADA	5359	0	12
20985	LA ARMONIA	5359	0	12
20986	VAQUEROS	4401	0	17
20987	VELARDES	4401	0	17
20988	VILLA SAN JOSE DE VINCHINA	5359	0	12
20989	YACONES	4401	0	17
20990	EL GALPON	2356	0	22
20991	EL SOLITARIO	2356	0	22
20992	GUARDIA VIEJA	2356	0	22
20993	LA CASIMIRA	2356	0	22
20994	LAS ABRAS DE SAN ANTONIO	2356	0	22
20995	LAS ALMAS	2356	0	22
20996	LAS DELICIAS	2356	0	22
20997	LIBERTAD	2356	0	22
20998	ALEM	4126	0	17
20999	LOS MILAGROS	2356	0	22
21000	MARTIN PASO	2356	0	22
21001	BARADERO	4126	0	17
21002	MONTE CRECIDO	2356	0	22
21003	CEIBAL	4126	0	17
21004	EL BRETE	4126	0	17
21005	PUNTA DEL GARABATO	2356	0	22
21006	PUNTA DEL MONTE	2356	0	22
21007	EL CUIBAL	4126	0	17
21008	QUEBRACHITOS	2356	0	22
21009	SAN AGUSTIN	2356	0	22
21010	SAN JOSE	2356	0	22
21011	SAN RUFINO	2356	0	22
21012	TOME Y TRAIGA	2356	0	22
21013	EL NARANJO	4126	0	17
21014	EL SUNCHAL	4126	0	17
21015	LA ASUNCION	4126	0	17
21016	AIBALITO	3747	0	22
21017	ALBERDI	3747	0	22
21018	LA CANDELARIA	4126	0	17
21019	EL SIMBOLAR	3474	0	22
21020	ESTANCIA LA AGUSTINA	3747	0	22
21021	LA MARAVILLA	4126	0	17
21022	KILOMETRO 20	3747	0	22
21023	LA POBLACION	4126	0	17
21024	LOS MOGOTES	4126	0	17
21025	MIRAFLORES	4126	0	17
21026	LA FLORIDA	4301	0	22
21027	OVEJERO	4126	0	17
21028	POTRERILLOS	4126	0	17
21029	SAN RAMON	4301	0	22
21030	RUIZ DE LOS LLANOS	4126	0	17
21031	PUNTA RIELES	3712	0	22
21032	SALAZAR	4126	0	17
21033	SAN PEDRO DE ARANDA	4126	0	17
21034	PACARA PINTADO	4119	0	24
21035	EL TALA EST R DE LOS LLANOS	4126	0	17
21036	BURRO POZO	4317	0	22
21037	CARBON POZO	4317	0	22
21038	CHILQUITAS	4317	0	22
21039	CHU	4208	0	22
21040	PASO DE LAS LANZAS	4119	0	24
21041	COLLERA HUIRCUNA	4315	0	22
21042	EL PERU	4317	0	22
21043	ESCALERA	4317	0	22
21044	ESPERANZA	4317	0	22
21045	HIGUERILLAS	4317	0	22
21046	HORNILLOS	4317	0	22
21047	JUANILLO	4317	0	22
21048	LOS SAUCES	4317	0	22
21049	ATOCHA	4401	0	17
21050	PAMPALLAJTA	4317	0	22
21051	PIEDRA TENDIDA	4119	0	24
21052	BELGRANO	4400	0	17
21053	PUEBLITO	4317	0	22
21054	PUNTA POZO	4317	0	22
21055	BUENA VISTA	4400	0	17
21056	SALINAS	4317	0	22
21057	SAN GREGORIO	4317	0	22
21058	POTRERILLO	4101	0	24
21059	SAUCEN	4317	0	22
21060	SAUCIOJ	4317	0	22
21061	VENTURA PAMPA	4317	0	22
21063	CHA	4328	0	22
21064	COLONIA ISLA	4328	0	22
21065	EL TRECE	4328	0	22
21066	GUA	4328	0	22
21067	LUJAN	4328	0	22
21068	CAMPO CASEROS	4400	0	17
21069	MALLIN VIEJO	4328	0	22
21070	CASTELLANOS	4401	0	17
21071	MOCONZA	4328	0	22
21072	REPRESA	4328	0	22
21073	EREZCANO	2903	0	1
21074	GENERAL CONESA	2907	0	1
21075	SAN NICOLAS DE LOS ARROYOS	2900	0	1
21076	CHAMICAL	4400	0	17
21077	RINCON DE LA ESPERANZA	4328	0	22
21078	COBAS	4400	0	17
21079	SALVIAIOJ GAITAN	4328	0	22
21080	EL AYBAL	4400	0	17
21081	SAN ANTONIO DE COPO	4328	0	22
21082	EL PRADO	4400	0	17
21084	SAN PEDRO	4328	0	22
21085	SAN RAMON	4328	0	22
21086	TALA	4328	0	22
21087	LA COSTA	4334	0	22
21088	PUERTA DE PALAVECINO	4101	0	24
21089	ESTOLA	4400	0	17
21090	LAGO MUYOJ	4334	0	22
21091	MAL PASO	4334	0	22
21092	ORO PAMPA	4334	0	22
21093	GENERAL ALVARADO	4401	0	17
21094	PUERTA QUEMADA	4119	0	24
21095	POZO CABADO	4334	0	22
21096	HIGUERILLAS	4400	0	17
21097	TIESTITUYOS	4334	0	22
21098	TORO PAMPA	4334	0	22
21099	KILOMETRO 1129	4400	0	17
21100	TRONCO BLANCO	4334	0	22
21101	LA CRUZ	4400	0	17
21102	YACASNIOJ	4334	0	22
21103	LA ISLA	4401	0	17
21105	LA LAGUNILLA	4400	0	17
21106	CHU	4326	0	22
21107	CODO POZO	4326	0	22
21108	LA MONTA	4400	0	17
21109	CONCHAYOS	4326	0	22
21110	PUESTO DE AVILA	4117	0	24
21111	CONSUL	4326	0	22
21112	LA PEDRERA	4400	0	17
21113	CRUZ POZO	4326	0	22
21114	LA QUESERA	4400	0	17
21115	GUARDIA	4326	0	22
21116	GUI	4326	0	22
21117	PUESTITO DE ARRIBA	4119	0	24
21118	LA TROJA	4400	0	17
21119	NOVILLO	4326	0	22
21120	PAAJ RODEO	4326	0	22
21121	LA UNION	4401	0	17
21122	PUNTA POZO	4326	0	22
21123	PUESTO CEVIL CON AGUA	4119	0	24
21124	LAS COSTAS	4401	0	17
21125	SAN ISIDRO	4326	0	22
21126	LIMACHE	4400	0	17
21127	SAN LUIS	4326	0	22
21128	LOS ALAMOS	4401	0	17
21129	SAN ROQUE	4326	0	22
21130	LOS NOQUES	4400	0	17
21131	SANTO DOMINGO	4326	0	22
21132	SAUCE BAJADA	4326	0	22
21133	PAREDES	4401	0	17
21134	ZAPI POZO	4326	0	22
21135	PE	4401	0	17
21136	RIO ANCHO	4400	0	17
21137	PUESTO VILLAGRA	4119	0	24
21138	SAN PEDRO	4326	0	22
21139	SAN JOSE	4326	0	22
21140	SAN LORENZO	4193	0	17
21141	PUNTA DEL AGUA	4119	0	24
21142	BAJO GRANDE	4338	0	22
21143	BAYO MUERTO	4338	0	22
21144	CONDOR HUASI	4338	0	22
21145	EL FAVORITO	4338	0	22
21146	FAVORITA	4338	0	22
21147	KILOMETRO 629	4338	0	22
21148	LAGUNA LARGA	4338	0	22
21149	LAS CHACRAS	4338	0	22
21150	NEGRA MUERTA	4338	0	22
21151	PALMARES	4338	0	22
21152	PALMITAS	4338	0	22
21153	RUMIOS	4338	0	22
21154	SAN FELIPE	4338	0	22
21155	SAN FRANCISCO LAVALLE	4338	0	22
21156	SAN JAVIER	4338	0	22
21157	SANTA ROSA DE VITERVO	4338	0	22
21158	SANTO DOMINGO	4338	0	22
21159	AHI VEREMOS	4300	0	22
21162	EL CRUCE KILOMETRO 659	4300	0	22
21164	JUMIALITO	4300	0	22
21165	KILOMETRO 1033	4300	0	22
21167	KILOMETRO 659	4300	0	22
21168	LA CAPILLA	4300	0	22
21170	LA GRANJA	4300	0	22
21174	COLONIA ALSINA	3064	0	22
21175	CAMPO BELGRANO	3062	0	22
21176	DESVIO POZO DULCE	3062	0	22
21177	EL CA	3062	0	22
21178	EL CRUCERO	3062	0	22
21179	EL JARDIN	3062	0	22
21180	EL ONCE	3062	0	22
21181	SAN GERONIMO	4119	0	24
21182	COLON	4403	0	17
21183	SAN JOSE DE SAN MARTIN	4119	0	24
21184	EL COLEGIO	4403	0	17
21185	EL HUAICO	4403	0	17
21186	SAN LORENZO	4119	0	24
21187	HUMAITA	4401	0	17
21188	LA CANDELARIA	4126	0	17
21189	LA FALDA	4403	0	17
21190	LA ISLA	4400	0	17
21191	LAS BLANCAS	4403	0	17
21192	LAS PALMAS	4403	0	17
21193	LOS ALAMOS	4403	0	17
21194	SAN AGUSTIN	4421	0	17
21195	SAN CLEMENTE	4403	0	17
21196	SANTA LUCIA	4119	0	24
21197	ZANJON	4403	0	17
21198	SANTOS LUGARES	4119	0	24
21200	SORAIRE	4119	0	24
21201	TALA PAMPA	4119	0	24
21202	TIERRAS BLANCAS	4119	0	24
21203	TOQUELLO	4119	0	24
21204	TOTORILLA	4141	0	24
21205	AMPATA	4415	0	17
21206	ATUDILLO	4415	0	17
21207	CERRO MAL CANTO	4415	0	17
21208	CHORRO BLANCO	4415	0	17
21209	COLONIA EL FUERTE	4421	0	17
21210	CUESTA CHICA	4415	0	17
21211	EL MOLLAR	4405	0	17
21212	TRINIDAD	4151	0	24
21213	EL NOGALAR	4415	0	17
21214	EL POTRERO DE DIAZ	4421	0	17
21215	EL RODEO	4415	0	17
21216	TUNALITO	4119	0	24
21217	EL SIMBOLAR	4421	0	17
21218	EL SUNCHAL	4415	0	17
21219	ESCOIPE	4421	0	17
21220	ESTACION ZUVIRIA	4421	0	17
21221	TUSCA PAMPA	4119	0	24
21222	HUAYRA HUASY	4415	0	17
21223	LA HERRADURA	4415	0	17
21224	LA YESERA	4415	0	17
21225	LOS LAURELES	4415	0	17
21226	MAL CANTE	4415	0	17
21227	MOLINO DE GONGORA	4415	0	17
21228	PIE DE LA CUESTA	4415	0	17
21229	PIEDRA DEL MOLINO	4421	0	17
21230	TORO YACO	4415	0	17
21231	VALLE ENCANTADO	4415	0	17
21232	VILLA LA COLMENA	4103	0	24
21233	ZAPALLAR	4242	0	24
21234	CERRO ALEMANIA	4425	0	17
21235	EL FRAILE	4425	0	17
21236	EL OBELISCO	4425	0	17
21237	EL SAPO	4425	0	17
21238	LAS JUNTAS DE ALEMANIA	4425	0	17
21239	LOS CASTILLOS	4425	0	17
21240	MORALES	4425	0	17
21241	POTRERILLOS	4425	0	17
21242	VAQUERIA	4191	0	17
21243	VAQUERIA LOS SAUCES	4425	0	17
21244	ALTOS HORNOS GUEMES	4432	0	17
21245	COLONIA SANTA ROSA DE LIMA	4432	0	17
21246	DIQUE EMBALSE CAMPO ALEGRE	4432	0	17
21247	EST EL BORDO	4430	0	17
21248	EL CEIBAL	4430	0	17
21249	EL PRADO	4432	0	17
21250	EL SALTO	4434	0	17
21251	EL ZAPALLAR	4430	0	17
21252	LA DEFENSA	4430	0	17
21253	RIO LAVALLEN	4432	0	17
21254	SANTA LUCIA	4432	0	17
21255	SANTA RITA	4430	0	17
21256	AGUAS BLANCAS	4530	0	17
21257	CHACAR	4633	0	17
21258	COLORADO	4633	0	17
21259	CORTADERAS	4411	0	17
21260	EL TAPIAL	4633	0	17
21261	JUNTAS DE SAN ANTONIO	4530	0	17
21262	LAS CA	4633	0	17
21263	LIMONCITO	4530	0	17
21264	PUEBLO VIEJO	4633	0	17
21265	SOLAZUTI	4530	0	17
21266	TITICOITE	4633	0	17
21267	TRES MORROS	4633	0	17
21268	UCHUYOC	4633	0	17
21269	VALLE DELGADO	4633	0	17
21270	CANGREJILLOS	4415	0	17
21271	EL MOLINO	4415	0	17
21272	EL POTRERO	4415	0	17
21273	LA ESPERANZA	4415	0	17
21274	LOS PATOS	4411	0	17
21275	POMPEYA	4415	0	17
21276	PUEBLO NUEVO	4415	0	17
21277	20 DE FEBRERO	4425	0	17
21278	EL CRESTON	4425	0	17
21279	FINCA EL CARMEN	4425	0	17
21280	LA BODEGUITA	4421	0	17
21281	LA REPRESA	4425	0	17
21282	LAS MERCEDES	4421	0	17
21283	SAN ROQUE	4425	0	17
21284	SANTA MARIA	4421	0	17
21285	AGUADITAS	5707	0	19
21286	BALDE DE ESCUDERO	5715	0	19
21287	BALDE DE LA LINEA	5713	0	19
21288	BA	5709	0	19
21289	BECERRA	5711	0	19
21290	BELLA VISTA BOTIJAS	5707	0	19
21291	CHACRAS DEL CANTARO	5719	0	19
21292	CHARLONES	5719	0	19
21293	EL CHARABON	5719	0	19
21294	EL QUEBRACHO	5711	0	19
21295	EL RETAMO	5711	0	19
21296	ESTANCIA LA BLANCA	5711	0	19
21297	ESTANCIA LA UNION	5711	0	19
21298	GUALTARAN	5719	0	19
21299	LA JUANITA	5719	0	19
21300	LA MERCED	5719	0	19
21301	LA REPRESITA	5711	0	19
21302	LAS CLARITAS	5711	0	19
21303	LOS CHENAS	5711	0	19
21304	MOYARCITO	5719	0	19
21305	POZO SANTIAGO	5703	0	19
21306	PUERTO ALEGRE	5719	0	19
21307	RECONQUISTA	5707	0	19
21308	SAN JORGE	5715	0	19
21309	SAN ROQUE	5719	0	19
21310	SANTA ROSA	5719	0	19
21311	SANTA VICTORIA	5707	0	19
21312	SERAFINA	5707	0	19
21313	SOL DE ABRIL	5707	0	19
21314	AHI VEREMOS	5703	0	19
21315	BALDE DE AMIRA	5703	0	19
21316	BALDE DEL ROSARIO	5703	0	19
21317	EL DICHOSO	5719	0	19
21319	ESTANCIA EL MEDANO	5719	0	19
21320	LA CHA	5719	0	19
21321	LA QUEBRADA	5703	0	19
21322	LA SALUD	5703	0	19
21323	POZO SIMON	5703	0	19
21324	RETIRO	5703	0	19
21325	SAN JOSE	5719	0	19
21326	ALTO NEGRO	5719	0	19
21327	EL CALDEN	5719	0	19
21328	EL MOLLE	5719	0	19
21329	EL ALGARROBAL	5775	0	19
21330	BAJO GRANDE	5775	0	19
21331	CUATRO ESQUINAS	5773	0	19
21332	LA ESCONDIDA	5775	0	19
21333	CAUCHARI	4413	0	17
21334	MOLLECITO	5759	0	19
21335	PISCOYACO	5775	0	19
21336	CHACHAS	4413	0	17
21337	SAN ANTONIO	5835	0	19
21338	SAN RAMON SUD	5775	0	19
21339	CHUCULAQUI	4413	0	17
21340	VALLE SAN AGUSTIN	5775	0	19
21341	VALLE SAN JOSE	5775	0	19
21342	GRANDES PASTOS	4411	0	17
21343	BOCA DE LA QUEBRADA	6216	0	19
21344	INCACHULI	4413	0	17
21345	EL ESPINILLO	6279	0	19
21346	EL PIGUE	6216	0	19
21347	FAVELLI	5636	0	19
21348	LA CHERINDU	6216	0	19
21349	LA COLONIA	6216	0	19
21350	JUNCALITO	4413	0	17
21351	LA LECHUGA	5637	0	19
21352	KILOMETRO 1369	4413	0	17
21353	LA RESERVA	6216	0	19
21354	LOS DUEROS	6216	0	19
21355	KILOMETRO 1373	4413	0	17
21356	NUEVA CONSTITUCION	5636	0	19
21357	KILOMETRO 1424	4413	0	17
21358	SANTA TERESA	6279	0	19
21359	MINA LA CASUALIDAD	4413	0	17
21360	EL PLUMERITO	5637	0	19
21361	EL RECUERDO	6279	0	19
21362	LA CA	5637	0	19
21363	LAS CARRETAS	6279	0	19
21364	LAGUNA SECA	4413	0	17
21365	PLUMERITO	5637	0	19
21366	TOSCAL	5636	0	19
21367	30 DE OCTUBRE	5637	0	19
21368	LOS COLORADOS	4413	0	17
21369	USIYAL	5637	0	19
21372	MINA JULIO	4411	0	17
21375	MINA TINCALAYA	4413	0	17
21379	MU	4411	0	17
21381	OLACAPATO CHICO	4413	0	17
21382	OLACAPATO GRANDE	4413	0	17
21383	POTRERILLOS	4411	0	17
21384	POTRERO DE POYOGASTA	4411	0	17
21385	QUEBRADA DEL AGUA	4413	0	17
21386	20 DE FEBRERO	5730	0	19
21387	9 DE JULIO	5831	0	19
21388	SALAR DE POCITOS	4413	0	17
21389	AGUADA	5831	0	19
21390	BAJOS HONDOS	5741	0	19
21391	CAPELEN	5741	0	19
21392	STA ROSA DE LOS PASTOS GRANDES	4411	0	17
21393	CHACRA LA PRIMAVERA	5730	0	19
21394	SOCOMPA	4413	0	17
21395	TACA TACA ESTACION FCGB	4413	0	17
21396	TOLAR CHICO	4413	0	17
21397	TOLAR GRANDE	4413	0	17
21398	EL CALDEN	5741	0	19
21399	ESTANCIA EL CHAMICO	5730	0	19
21400	ESTANCIA EL DIVISADERO	5730	0	19
21401	UNQUILLAL EMBARCADERO FCGB	4413	0	17
21402	ESTANCIA EL QUEBRACHAL	5730	0	19
21403	ESTANCIA EL SAUCECITO	5730	0	19
21404	ESTANCIA LA GUARDIA	5730	0	19
21405	ESTANCIA LA GUILLERMINA	5731	0	19
21406	VEGA DE ARIZARO	4413	0	17
21407	ESTANCIA LA MORENA	5731	0	19
21408	ESTANCIA LA RESERVA	5730	0	19
21409	ESTANCIA LA ZULEMITA	5730	0	19
21410	ESTANCIA LAS BEBIDAS	5730	0	19
21411	ESTANCIA LOS HERMANOS	5730	0	19
21412	ESTANCIA LOS NOGALES	5730	0	19
21413	ESTANCIA SAN ALBERTO	5730	0	19
21414	ESTANCIA SAN ANTONIO	5731	0	19
21415	ESTANCIA SAN FRANCISCO	5730	0	19
21416	JUANTE	5731	0	19
21417	LA ELISA	5741	0	19
21418	LA FLECHA	5741	0	19
21419	LA ISABEL	5743	0	19
21420	LA JOSEFINA	5741	0	19
21421	LA PALMIRA	5741	0	19
21422	LA PRIMAVERA	5730	0	19
21423	LA REALIDAD	5741	0	19
21424	LA SILESIA	5741	0	19
21425	LAGUNA CAPELEN	5741	0	19
21426	LAGUNA SAYAPE	5741	0	19
21427	MEDANO CHICO	5730	0	19
21428	MEDANO GRANDE	5730	0	19
21430	NOSSAR	5741	0	19
21431	PORTADA DEL SAUCE	5741	0	19
21432	AGUA DEL PORTEZUELO	5730	0	19
21433	PUESTO BELLA VISTA	5730	0	19
21434	PUESTO EL TALA	5730	0	19
21435	SAN ALBERTO	5831	0	19
21436	SAN CAMILO	5743	0	19
21437	SAN JOSE DEL DURAZNO	5741	0	19
21438	13 DE ENERO	5741	0	19
21439	VILLA SANTIAGO	5730	0	19
21441	ESTANCIA TRES ARBOLES	5881	0	19
21442	LA CELIA	5873	0	19
21443	LA FINCA	5871	0	19
21444	LAS CHILCAS	5777	0	19
21445	LOS MOLLES	5883	0	19
21447	REPRESA DEL MONTE	5711	0	19
21448	LA CUMBRE	5883	0	19
21449	VACAS MUERTAS	5721	0	19
21450	ACASAPE	5722	0	19
21451	ALTO BLANCO	5700	0	19
21452	ALTO DEL LEON	5722	0	19
21453	ALTO DEL VALLE	5721	0	19
21454	BALDA	5722	0	19
21455	BELLA VISTA	5724	0	19
21456	CUCHI CORRAL	5701	0	19
21457	CAMPO DE SAN PEDRO	5722	0	19
21458	COLONIA SANTA VIRGINIA	5721	0	19
21459	CORTADERAS	5700	0	19
21460	EL NEGRO	5724	0	19
21461	FORTIN SALTO	5721	0	19
21462	JUAN W GEZ	5722	0	19
21463	LA AGUA NUEVA	5721	0	19
21464	LA AMARGA	5721	0	19
21465	LA BREA	5724	0	19
21466	LA CORTADERA	5700	0	19
21467	LA COSTA	5721	0	19
21468	LA DULCE	5721	0	19
21469	LA ESPESURA	5700	0	19
21470	LA JERGA	5721	0	19
21471	LA NELIDA	5700	0	19
21472	LA REFORMA	5724	0	19
21473	LA TOTORA	5721	0	19
21474	LAS CA	5722	0	19
21475	LAS CHACRAS DE SAN MARTIN	5701	0	19
21476	POSADAS	3300	0	14
21477	LAS PIEDRITAS	5721	0	19
21478	LINCE	5722	0	19
21479	LOS CLAVELES	5721	0	19
21480	LOS COROS	5721	0	19
21481	MATACO	5724	0	19
21482	PALOMAR	5724	0	19
21483	PASO DE LA TIERRA	5721	0	19
21484	PESCADORES	5700	0	19
21485	POZO ESCONDIDO	5700	0	19
21486	PUENTE LA ORQUETA	5721	0	19
21487	PUERTA DE LA ISLA	5721	0	19
21488	PUNTOS DE AGUA	5721	0	19
21489	REFORMA CHICA	5724	0	19
21490	SAN GERONIMO	5721	0	19
21491	SANTA DIONISIA	5722	0	19
21492	SANTA ISABEL	5721	0	19
21493	NECOCHEA	7630	0	1
21494	SANTA TERESA	5700	0	19
21495	SANTO DOMINGO	5700	0	19
21496	TAMASCANES	5721	0	19
21497	TRANSVAL	5721	0	19
21498	EL QUEBRACHO	5700	0	19
21499	ALGARROBAL VIEJO	4446	0	17
21500	ESTANCIA RIVADAVIA	5719	0	19
21501	TRES MARIAS	5700	0	19
21502	BAJO GRANDE DESVIO FCGB	4444	0	17
21503	CORRAL QUEMADO	4446	0	17
21504	EL VALLECITO	4440	0	17
21505	ALTO DE LA LE	5750	0	19
21506	FOGUISTA J F JUAREZ	4444	0	17
21507	ALTO GRANDE	5722	0	19
21508	ARBOLEDA	5750	0	19
21509	HOSTERIA JURAMENTO	4440	0	17
21510	CA	5750	0	19
21511	LA COSTOSA	4440	0	17
21512	CUATRO ESQUINAS	5750	0	19
21513	DIQUE LA FLORIDA	5750	0	19
21514	LOS BA	4440	0	17
21515	EL SALADO	5750	0	19
21516	EL TALA	5701	0	19
21517	EL VALLECITO	5750	0	19
21518	PASO DE BALDERRAMA	4440	0	17
21519	PIQUETE DE ANTA	4434	0	17
21520	POBLACION	4446	0	17
21521	ESTANCIA EL SALADO	5750	0	19
21522	LA ADELA	5736	0	19
21523	LA ATALAYA	5750	0	19
21524	RIO PIEDRAS	4434	0	17
21525	LA DELIA	5722	0	19
21526	LA MARIA	5722	0	19
21527	SAN JAVIER	4440	0	17
21528	LA PROVIDENCIA	5750	0	19
21529	LA YERBA BUENA	5722	0	19
21530	LAS HIGUERAS	5722	0	19
21531	LOMA DEL MEDIO	5750	0	19
21532	EL BORDO	4432	0	17
21533	MINA CAROLINA	5701	0	19
21534	OJO DE AGUA	5750	0	19
21535	PAINES	5736	0	19
21536	PAMPA DE LOS GOBERNADORES	5701	0	19
21537	MIRAFLORES M	4444	0	17
21538	SAN LORENZO	5757	0	19
21539	SANTA CLARA	5751	0	19
21540	EL PANTANO	5753	0	19
21541	EL SALADO DE AMAYA	5771	0	19
21542	EL SALTO	5753	0	19
21544	PIEDRAS BLANCAS	5750	0	19
21545	RIECITO	5750	0	19
21546	SOLOLOSTA	5750	0	19
21547	TAMBOREO	5750	0	19
21548	EL HORNITO	5755	0	19
21549	EL RINCON	5755	0	19
21550	LA CRUCESITA	5773	0	19
21551	LA MESILLA	5773	0	19
21552	LA MINA	5755	0	19
21553	AMAICHA	4419	0	17
21554	LAGUNA DE PATOS	5771	0	19
21555	CHICOANA	4419	0	17
21556	LAS RAICES	5773	0	19
21557	COLOME	4419	0	17
21558	CUCHIYACO	4419	0	17
21559	LOS SAUCES	5753	0	19
21560	EL CARMEN	4419	0	17
21561	GUALFIN	4419	0	17
21562	PIEDRAS ANCHAS	5755	0	19
21563	LA PUERTA	4419	0	17
21564	MONTE GRANDE	4419	0	17
21565	SAN MARTIN	4419	0	17
21566	POZO FRIO	5773	0	19
21568	SANTA CLARA	5701	0	19
21569	SANTA MARIA	5773	0	19
21570	VIEJA ESTANCIA	5773	0	19
21571	9 DE JULIO	5701	0	19
21573	ABRA GRANDE	4530	0	17
21574	COLONIA A	4530	0	17
21575	COLONIA AGRICOLA SAN AGUSTIN	4530	0	17
21576	COLONIA D	4530	0	17
21577	COLONIA SANTA MARIA	4530	0	17
21578	EL CARMEN	4530	0	17
21579	EL DESMONTE	4538	0	17
21580	EL QUEMADO	4530	0	17
21581	FINCA LA TOMA	4538	0	17
21582	FINCA MISION ZENTA	4530	0	17
21583	FORTIN BELGRANO	4530	0	17
21584	LA TOMA	4530	0	17
21585	LAS CORTADERAS	4530	0	17
21586	LAS MARAVILLAS	4538	0	17
21587	LOMAS DE OLMEDO	4530	0	17
21588	LOTE JOSEFINA	4530	0	17
21589	LOTE LUCRECIA	4530	0	17
21590	LOTE MARCELA	4530	0	17
21591	LOTE SARITA	4530	0	17
21592	MARIA JOSE	4530	0	17
21593	MARTINEZ DEL TINCO	4537	0	17
21594	MINAS YPF	4530	0	17
21595	POZO DE LA PIEDRA	4530	0	17
21596	POZO PRINGLES	4530	0	17
21597	PUESTO DE MOTIJO	4530	0	17
21598	QUE	4530	0	17
21599	POSTA DEL PORTEZUELO	5705	0	19
21600	SAN IGNACIO DE LOYOLA	4530	0	17
21601	VADO HONDO	4530	0	17
21602	AGUA VERDE	4561	0	17
21603	BALBUENA	4561	0	17
21604	BUENA FE	4561	0	17
21605	CAMPO LARGO	4554	0	17
21606	CHIRETE	4554	0	17
21607	CIERVO CANSADO	4535	0	17
21608	COLONIA BUENAVENTURA	4561	0	17
21610	DOS YUCHANES	4554	0	17
21611	EL BREAL	4535	0	17
21612	EL COLGADO	4430	0	17
21613	EL ESPINILLO	4430	0	17
21614	EL MIRADOR	4535	0	17
21615	EL 	4561	0	17
21616	EL PERTIGO	4554	0	17
21617	EL TALAR	4554	0	17
21618	EL TARTAGAL	4554	0	17
21619	EL YACON	4535	0	17
21620	EL ZAPALLO	4534	0	17
21621	LA CURVA	4554	0	17
21622	LA ENTRADA	4554	0	17
21623	LA ESPERANZA	4535	0	17
21624	LA MORA	4554	0	17
21625	LAS HORQUETAS	4554	0	17
21626	MADREJON	4554	0	17
21627	MISION SANTA LUCIA	4561	0	17
21628	MISIONES	4554	0	17
21629	PALO SANTO	4554	0	17
21630	PARAMAMAYA	4430	0	17
21631	PLUMA DEL PATO	4554	0	17
21632	POZO CERCADO	3636	0	17
21633	POZO DEL CHA	4554	0	17
21634	POZO DEL CUICO	4554	0	17
21635	POZO DEL SAUCE	4535	0	17
21636	POZO EL ALGARROBO	4430	0	17
21637	POZO HONDO	4554	0	17
21638	PUERTO DE DIAZ	4430	0	17
21639	PUESTO DEL PA	4554	0	17
21640	SAN AGUSTIN	4193	0	17
21641	SAN MIGUEL	4535	0	17
21642	SANTA ROSA	4535	0	17
21643	SANTOS LUGARES	4535	0	17
21644	SARGENTO CRISTOBAL	4430	0	17
21645	TRES YUCHANES	4430	0	17
21646	VUELTA DE LAS TOBAS	4554	0	17
21647	SAN VICENTE	4190	0	17
21648	PALOMAR	4190	0	17
21649	PASO VERDE	4198	0	17
21650	POTRERO	4195	0	17
21651	ROSARIO FUNCA	4190	0	17
21652	SAN JUAN	4193	0	17
21653	LAS MOJARRITAS	4195	0	17
21654	LOS CANTEROS	4195	0	17
21655	SAN PEDRO DE LOS CORRALES	4191	0	17
21656	AGUAS CALIENTES	4190	0	17
21657	ALMIRANTE BROWN	4193	0	17
21658	ARENAL	4198	0	17
21659	ARJUNTAS	4430	0	17
21660	BAJADA	4190	0	17
21661	BAJADA DE GAVI	4198	0	17
21662	BAJADA GRANDE	4198	0	17
21663	BALBOA	4193	0	17
21664	BA	4190	0	17
21665	BELLA VISTA	4193	0	17
21666	CAMARA	4198	0	17
21667	CONDOR	4193	0	17
21668	COPO QUILE	4193	0	17
21669	COSME	4190	0	17
21670	DIAMANTE	4198	0	17
21671	DURAZNITO	4190	0	17
21672	EL BORDO	4193	0	17
21673	EL CONDOR	4193	0	17
21674	EL CORRAL VIEJO	4198	0	17
21675	EL MORANILLO	4430	0	17
21676	EL NARANJO	4191	0	17
21677	EL OJITO	4198	0	17
21678	EL PORTEZUELO	4190	0	17
21679	EL POTRERO	4193	0	17
21680	EL PUESTITO	4198	0	17
21681	EL QUEMADO	4198	0	17
21682	EL TANDIL	4198	0	17
21683	FEDERACION	4198	0	17
21684	FUERTE QUEMADO	4430	0	17
21685	HORCONES	4198	0	17
21686	LA BANDA	4190	0	17
21687	LA CIENAGA	4193	0	17
21688	LA HOYADA	4198	0	17
21689	LA MATILDE	4190	0	17
21690	LA PALATA	4198	0	17
21691	LA PLATA	4198	0	17
21692	LAS MOJARRAS	4198	0	17
21693	LAS PIEDRITAS	4190	0	17
21694	LAS VENTANAS	4198	0	17
21695	LOS BA	4193	0	17
21696	LOS CHURQUIS	4198	0	17
21697	LOS ROSALES	4193	0	17
21698	LOS ZANJONES	4198	0	17
21699	MADARIAGA	4193	0	17
21700	MORENILLO	4193	0	17
21701	OJO DE AGUA	4190	0	17
21702	OVANDO	4190	0	17
21703	OVEJERIA	4198	0	17
21704	POTRERILLO	4190	0	17
21705	POZO VERDE	4198	0	17
21706	POZOS LARGOS	4198	0	17
21707	PUENTE DE PLATA	4193	0	17
21708	RIO URUE	4193	0	17
21709	SAN ESTEBAN	4190	0	17
21710	SAN FELIPE	4198	0	17
21711	SAN LORENZO HORCONES	4198	0	17
21712	SAN LUIS	4193	0	17
21713	SANTA ANA	4430	0	17
21714	SANTA CRUZ	4430	0	17
21715	SANTA ROSA	4198	0	17
21716	SIMBOL YACO	4430	0	17
21717	TAMAS CORTADAS	4198	0	17
21718	VAQUERIA	4430	0	17
21719	VIADUCTO EL MU	4190	0	17
21720	VILLA AURELIA	4190	0	17
21721	LOS POCITOS	4190	0	17
21722	CARAPACHAY	1605	0	1
21723	FLORIDA	1602	0	1
21724	FLORIDA OESTE	1602	0	1
21725	LA LUCILA	1636	0	1
21726	MUNRO	1605	0	1
21727	OLIVOS	1636	0	1
21728	VICENTE LOPEZ	1638	0	1
21729	VILLA MARTELLI	1603	0	1
21730	ALEJO DE ALBERRO	4407	0	17
21731	ALFARCITO	4409	0	17
21732	BALLENAL	4405	0	17
21733	CAMARA	4405	0	17
21734	CARABAJAL	4405	0	17
21735	CERRO BAYO	4409	0	17
21736	CERRO NEGRO	4190	0	17
21737	CHORRILLITOS	4409	0	17
21738	CHORRILLOS	4409	0	17
21739	DAMIAN M TORINO	4409	0	17
21740	DIEGO DE ALMAGRO	4409	0	17
21741	DOCTOR FACUNDO ZUVIRIA	4421	0	17
21742	EL ALFREDITO	4409	0	17
21743	EL ALISAL	4409	0	17
21744	EL CARMEN	4405	0	17
21745	EL CORRALITO	4405	0	17
21746	EL DORADO	4405	0	17
21747	EL ENCON	4407	0	17
21748	EL GOLGOTA	4409	0	17
21749	EL MANZANO	4405	0	17
21750	EL MOLLAR	4405	0	17
21751	EL PORVENIR	4405	0	17
21752	EL PUCARA	4405	0	17
21753	EL PUYIL	4405	0	17
21754	EL ROSAL	4405	0	17
21755	EL TIMBO	4405	0	17
21756	EL TORO	4409	0	17
21757	ELTUNAL	4407	0	17
21758	ENCRUCIJADA	4409	0	17
21759	ENCRUCIJADA DE TASTIL	4409	0	17
21760	GOBERNADOR MANUEL SOLA	4409	0	17
21761	GOBERNADOR SARAVIA	4409	0	17
21762	HUAICONDO	4409	0	17
21763	INCAHUASI	4409	0	17
21764	INCAMAYO	4409	0	17
21765	INGENIERO MAURY	4409	0	17
21766	KILOMETRO 1172	4407	0	17
21767	LA ESTELA	4405	0	17
21768	LAS ARCAS	4407	0	17
21769	LAS ARENAS	4405	0	17
21770	LAS CAPILLAS	4409	0	17
21771	LAS CEBADAS	4409	0	17
21772	LAS CUEVAS	4409	0	17
21773	LAS MESADAS	4405	0	17
21774	LAS ROSAS	4405	0	17
21775	MEDIA LUNA	4405	0	17
21776	MERCED DE ARRIBA	4405	0	17
21777	MESETA	4409	0	17
21778	MINA CAROLINA	4409	0	17
21779	PASCHA	4405	0	17
21780	PIE DE LA CUESTA	4405	0	17
21781	POTRERO DE LINARES	4407	0	17
21782	POTRERO DE URIBURU	4407	0	17
21783	PUERTA DE TASTIL	4409	0	17
21784	QUEBRADA DEL TORO	4409	0	17
21785	QUEBRADA MU	4409	0	17
21786	SANTA ROSA DE TASTIL	4409	0	17
21787	TACUARA	4409	0	17
21788	TORO	4409	0	17
21789	TRES CRUCES	4409	0	17
21790	VILLA SOLA	4409	0	17
21791	VIRREY TOLEDO	4407	0	17
21792	ANGOSTURA	4415	0	17
21793	ISONZA	4427	0	17
21794	LA CABA	4427	0	17
21795	LA MERCED	4427	0	17
21796	LAS VI	4427	0	17
21797	MINA DON OTTO	4425	0	17
21798	PALO PINTADO	4427	0	17
21799	RUMIUARCO	4427	0	17
21800	ANGOSTURA	4560	0	17
21801	BARRIO SAN CAYETANO	4400	0	17
21802	CAPIAZUTTI	4560	0	17
21803	CARAPARI	4560	0	17
21804	COLONIA ZANJA DEL TIGRE	4560	0	17
21805	DIQUE ITIRUYO	4568	0	17
21806	EL CHORRO	4560	0	17
21807	EL CIENAGO	4554	0	17
21808	FRONTERA TRES	4560	0	17
21809	FRONTERA 4	4560	0	17
21810	FRONTERA 5	4560	0	17
21811	BARRIO LA LOMA	4400	0	17
21812	LA SOLEDAD	4560	0	17
21813	LOTE 27	4560	0	17
21814	MISION FRANCISCANA	4560	0	17
21815	PARAJE CAMPO LARGO	4560	0	17
21816	LA PORCELANA	4560	0	17
21817	POZO BERMEJO	4560	0	17
21818	PUERTO BAULES	4552	0	17
21819	RIO SECO	4552	0	17
21820	S JOLLIN	4560	0	17
21821	SAN LAURENCIO	4560	0	17
21822	TUYUNTI	4560	0	17
21823	VILLA GENERAL GUEMES	4560	0	17
21824	BARRIO SAN ANTONIO	4560	0	17
21825	YACAY	4560	0	17
21826	YACIMIENTO TONONO	4560	0	17
21827	ZANJA HONDA	4560	0	17
21828	ANGOSTO PESCADO	4651	0	17
21830	CAPILLA FUERTE	4651	0	17
21831	CONDADO	4651	0	17
21832	CUESTA AZUL	4651	0	17
21833	EL AGUILAR	4651	0	17
21834	HUERTA	4651	0	17
21835	LIPEO	4651	0	17
21836	MECOYITA	4651	0	17
21837	POSCAYA	4651	0	17
21838	PUNCO VISCANA	4651	0	17
21839	SAN MARCOS	4651	0	17
21840	SANTO DOMINGO SANTA VICTORIA	4449	0	17
21841	SOLEDANI	4651	0	17
21842	TRUSUCA	4651	0	17
21843	VISCACHANI	4651	0	17
21844	ANCHUMBIL	5361	0	12
21845	EL CHUSCHIN	5361	0	12
21846	ESTANCIA DE MAIZ	5361	0	12
21847	KILOMETRO 180	4000	0	24
21848	LAS TUCUMANESAS	5361	0	12
21849	PIEDRA PINTADA	5361	0	12
21850	PIEDRA DE TALAMPAYA	5361	0	12
21851	VILLA ANGELINA	4105	0	24
21852	SALINAS DEL LEONCITO	5361	0	12
21854	EL PORTEZUELO	9201	0	5
21855	TRES CERROS	5361	0	12
21856	ALTO LAS LECHUZAS	4147	0	24
21857	AROCAS	4174	0	24
21858	BARRIO TEXTIL	4146	0	24
21859	CALERA DE CHIRIMAYO	4146	0	24
21860	CAMPO SOLCO LOS COCHAMOLLES	4146	0	24
21861	COCHAMOLLE	4146	0	24
21862	SANTA ELENA	5361	0	12
21863	COSTA DEL RIO SECO	4149	0	24
21864	EL PUESTO	4149	0	24
21865	ENSENADA	4174	0	24
21866	ESCUELA 115	4146	0	24
21867	ESCUELA 168	4146	0	24
21868	ESCUELA 17	4146	0	24
21869	CACHEL	9201	0	5
21870	ESCUELA 18	4146	0	24
21871	ESCUELA 118	4146	0	24
21872	ESCUELA 186	4146	0	24
21873	ESCUELA 19	4146	0	24
21874	ESCUELA 234	4146	0	24
21875	ESCUELA 239	4146	0	24
21876	ESCUELA 268	4146	0	24
21877	ESCUELA 365	4146	0	24
21878	ESCUELA 387	4146	0	24
21879	ESCUELA 6	4146	0	24
21880	ESCUELA 65	4146	0	24
21881	ESCUELA 85	4146	0	24
21882	ESCUELA ALMIRANTE BROWN	4146	0	24
21883	ESCUELA FLORENCIO VARELA	4146	0	24
21884	ESCUELA GREGORIA LAMADRID	4146	0	24
21885	ESCUELA MANUEL DOMINGO BASSAIL	4146	0	24
21886	ESCUELA MERCEDES PACHECO	4146	0	24
21887	ISCHILLON	4146	0	24
21888	LA BANDERITA	4132	0	24
21889	LAS CUEVAS	4146	0	24
21890	LAS GUCHAS LOS GUCHEA	4151	0	24
21891	LAS LENGUAS LAS LEGUAS	4149	0	24
21892	LAS PAVAS	4146	0	24
21893	LA AIDA	3062	0	22
21894	LA DELIA	3062	0	22
21895	LA DORA	3062	0	22
21896	LA FELICIANA	3062	0	22
21897	LOS AGUEROS	4174	0	24
21898	LA ISLETA	3062	0	22
21899	LA LIBIA	3062	0	22
21900	LA MAGDALENA	3062	0	22
21901	LOS AGUIRRE	4174	0	24
21902	LA SANTAFECINA	3062	0	22
21903	LAS CHILCAS	3062	0	22
21904	LAS ISLETAS	3062	0	22
21905	LAS MOCHAS	3062	0	22
21906	LAS TERESAS	3062	0	22
21907	SAN GERMAN	3062	0	22
21909	LOS LESCANOS	4174	0	24
21910	LOS TIMBOS	4101	0	24
21911	ALEJITO	4350	0	22
21912	AZOGASTA	4350	0	22
21913	AMPA	4350	0	22
21914	CARRETERO	4350	0	22
21915	CORRAL GRANDE	4350	0	22
21916	CRUZ CHULA	4350	0	22
21917	CRUZ LOMA	4350	0	22
21918	DOLORES	4350	0	22
21919	DOS HERMANOS	4350	0	22
21920	EL QUEMADO	4350	0	22
21921	EL SAUCE	4350	0	22
21922	GUAYPE	4350	0	22
21923	MUYO	4146	0	24
21924	IUCHAN	4350	0	22
21925	JUMI POZO	4350	0	22
21926	PIEDRA GRANDE	4146	0	24
21927	LA REDUCCION	4350	0	22
21928	LASPA	4350	0	22
21929	LAURELES	4350	0	22
21930	NUEVA GRANADA	4350	0	22
21931	LA CASTELLANA	9111	0	5
21932	RIEGASTA	4174	0	24
21936	PADUA	4350	0	22
21937	PAMPA POZO	4350	0	22
21939	POZO GRANDE	4350	0	22
21941	PUENTE RIO SALADO	4350	0	22
21943	REPECHO DIAZ	4350	0	22
21944	REPECHO MONTENEGRO	4350	0	22
21945	BARRIO ASTRA	9003	0	5
21946	RODEO BAJADA	4350	0	22
21947	SAN ANTONIO	4350	0	22
21948	SAN FRANCISCO	4350	0	22
21949	SAN PEDRO	4350	0	22
21950	SAN RAMON	4350	0	22
21951	SAN SIMON	4350	0	22
21952	CALETA CORDOVA	9003	0	5
21954	SANTA MARIA	4350	0	22
21955	SIN DESCANSO	4350	0	22
21956	SURI	4350	0	22
21957	TRES HERMANAS	4350	0	22
21958	SAN ANTONIO	4174	0	24
21959	CONTRERAS ESTABLECIMIENTO	4200	0	22
21960	EL PUESTITO	4200	0	22
21961	SAN CARLOS	4146	0	24
21962	EL VINALAR	4200	0	22
21963	MERCEDES	4200	0	22
21964	PUESTO DEL MEDIO	4200	0	22
21965	VILLA CONSTANTINA	4200	0	22
21966	VILLA GRIMANESA	4200	0	22
21967	SAN RAMON	4149	0	24
21968	25 DE MAYO	4231	0	22
21969	ARBOL SOLO	4205	0	22
21970	BELLA VISTA	4230	0	22
21971	SANTA ROSA	4242	0	24
21972	BELTRAN LORETO	4230	0	22
21973	CAMPO DE AMOR	4230	0	22
21974	CHAVES	4205	0	22
21975	EL NERIO	4205	0	22
21976	EL SE	4205	0	22
21977	ENVIDIA	4230	0	22
21978	LA BLANCA	4205	0	22
21979	LA CORTADERA	4205	0	22
21980	LA LAURA	4230	0	22
21981	LA MELADA	4205	0	22
21982	LA POLVAREDA	4205	0	22
21983	LA PROVIDENCIA	4205	0	22
21984	VILLA DEVOTO	4146	0	24
21985	LA VIUDA	4205	0	22
21986	INGENIERO ENRIQUE H FAURE	3636	0	9
21987	LAS DOS FLORES	4230	0	22
21988	LOS CERRILLOS	4205	0	22
21990	YUNCA SUMA	4146	0	24
21991	PAMPA POZO	4230	0	22
21992	PORONGAL	4230	0	22
21993	SAN AGUSTIN	4205	0	22
21994	SAN BENITO	4205	0	22
21995	SAN IGNACIO	4230	0	22
21996	SAN LUIS	4230	0	22
21997	SAN MANUEL	4205	0	22
21998	SAN PASTOR	4205	0	22
21999	SAN RAMON	4205	0	22
22000	SAN ROQUE	4205	0	22
22001	SANTA ANA	4205	0	22
22002	SANTA ROSA DE CORONEL	4230	0	22
22003	SANTA ROSA	4230	0	22
22004	TRES BAJADAS	4230	0	22
22005	KILOMETRO 11	9000	0	5
22006	ATAHUALPA	3714	0	22
22007	COLOMBIA	3714	0	22
22008	EL CERRITO	4301	0	22
22009	EL PALMAR	3714	0	22
22010	EL PALOMAR	3714	0	22
22011	FIERRO	3714	0	22
22012	GENERAL FRANCISCO B BOSCH	3632	0	9
22013	OBRAJE LOS TIGRES	3714	0	22
22014	AGUADITA	4178	0	24
22015	CAMPO LA ANGELITA	3712	0	22
22016	COLONIA EL PELIGRO	3712	0	22
22017	EL AEROLITO	3712	0	22
22018	EL PERSEGUIDO	3712	0	22
22019	EL SILENCIO	3712	0	22
22020	ESTADOS UNIDOS	3712	0	22
22021	ALABAMA NUEVA	4178	0	24
22022	KILOMETRO 1297	3712	0	22
22023	LA ANGELITA	3712	0	22
22024	LA ARMONIA	3712	0	22
22025	LA GRANJA	3712	0	22
22026	LAS PERFORACIONES	3714	0	22
22027	LAVALLE	3712	0	22
22028	PINEDO	3712	0	22
22029	POZO VIL	3712	0	22
22030	PUESTO DEL MEDIO	3712	0	22
22031	ALTO LAS LECHUZAS	4178	0	24
22032	SAN PEDRO	3712	0	22
22033	URUNDEL	3712	0	22
22034	ANCHORIGA	4313	0	22
22035	ASPA SINCHI	4313	0	22
22036	BARRANCAS	4313	0	22
22037	BOQUERON	4313	0	22
22038	ANDRES FERREYRA	4178	0	24
22039	CHARQUINA	4313	0	22
22040	CHILPA MAYO	4313	0	22
22041	EL DORADO	4313	0	22
22042	GARCEANO	4313	0	22
22043	BAJO GRANDE	4111	0	24
22044	ISLA VERDE	4313	0	22
22045	BELLO HORIZONTE	4178	0	24
22046	KILOMETRO 437	4313	0	22
22047	KILOMETRO 473	4313	0	22
22048	BRACHO VIEJO	4178	0	24
22049	BUSTAMANTE	4184	0	24
22050	LA BLANCA	4313	0	22
22052	RESERVA NATURAL FORMOSA	3634	0	9
22053	LAGUNA BLANCA	4313	0	22
22054	RIO MUERTO	3634	0	9
22055	LINTON	4313	0	22
22056	SAN ANTONIO	3634	0	9
22057	MAJADAS	4313	0	22
22058	SAN CAMILO	3606	0	9
22059	PAMPA ATUN	4313	0	22
22060	MAJADAS SUD	4313	0	22
22062	PUESTO DEL ROSARIO	4313	0	22
22063	SAN ISIDRO	3634	0	9
22064	SUNCHO POZO	4613	0	22
22065	TIO CHACRA	4313	0	22
22066	TRES POZOS	3634	0	9
22068	TULUN	4313	0	22
22069	TTE CNEL GASPAR CAMPOS	3630	0	9
22070	CAMPO LA FLOR LOS RALOS	4182	0	24
22071	VILLA ELENA	4313	0	22
22072	VACA PERDIDA	3636	0	9
22073	VEINTIOCHO DE MARZO	3760	0	22
22074	BINAL ESQUINA	3760	0	22
22075	EL MATACO	3760	0	22
22076	KILOMETRO 515	3760	0	22
22077	LA ENCALADA	3760	0	22
22078	LA ESTANCIA	3760	0	22
22079	SUNCHO POZO	3760	0	22
22080	TINAP JERAYOJ	3760	0	22
22081	BOCA DEL TIGRE	4184	0	22
22082	CERCO CUATRO	4178	0	24
22083	CACHICO	4306	0	22
22084	CHARCO VIEJO	4184	0	22
22085	EL A	4306	0	22
22086	EL GUAYACAN	4306	0	22
22087	LAS ABRAS	4306	0	22
22088	POLEO POZO	4184	0	22
22089	TORO POZO	4306	0	22
22090	A	4184	0	22
22091	ANIMAS	4184	0	22
22092	ARBOLITOS	4184	0	22
22093	COLONIA EL PUESTO	4178	0	24
22094	BAJO HONDO	4184	0	22
22095	BELLA VISTA	4184	0	22
22096	CEJA POZO	4184	0	22
22097	COLONIA EL TARCO	4178	0	24
22098	DON BARTOLO	4184	0	22
22099	EL CAMBIADO	4184	0	22
22100	COLONIA LA BONARIA	4178	0	24
22101	EL MOLAR	4184	0	22
22102	EL PARANA	4184	0	22
22103	GASPAR SUAREZ	4184	0	22
22104	LA LANCHA	9200	0	5
22105	HUMAITA	4184	0	22
22106	LA ESPERANZA	4184	0	22
22107	LOS RALOS	4184	0	22
22108	COLONIA LA ORTIZ	4178	0	24
22109	POZO LERDO	4184	0	22
22110	POZO LINDO	4184	0	22
22111	COLONIA LA ROCA	4178	0	24
22112	LAGO CARLOS PELLEGRINI	9217	0	5
22113	PUERTA GRANDE	4184	0	22
22114	RETIRO	4184	0	22
22115	SUNCHO PUJIO	4184	0	22
22116	TENENE	4184	0	22
22118	TUSCA POZO	4184	0	22
22119	UCLAR	4184	0	22
22120	UTRUNJOS	4184	0	22
22121	VITEACA	4184	0	22
22123	COLONIA MERCEDES	4178	0	24
22124	COLONIA MISTOL	4178	0	24
22125	COLONIA MONTEROS	4178	0	24
22126	COLONIA SAN LUIS	4178	0	24
22127	COLONIA SAN MIGUEL	4178	0	24
22128	ALBARDON	4208	0	22
22129	COLONIA SANTA RITA	4178	0	24
22130	BURRA HUA	4208	0	22
22131	CRUZ ALTA	4178	0	24
22132	LA DORMIDA	4208	0	22
22133	LA RAMADITA	4208	0	22
22134	SANTA BARBARA	4208	0	22
22135	SAUCE SOLO	4208	0	22
22136	ANCHILO	3740	0	22
22137	TINAJERALOJ	3740	0	22
22138	PARAJE EL PRADO	3740	0	22
22139	PARAJE LA PAMPA	3740	0	22
22140	EL CARBON	4184	0	24
22141	PARAJE LILO VIEJO	3740	0	22
22142	PARAJE MILAGRO	3740	0	22
22143	EL CARDENAL	4178	0	24
22144	PARAJE OBRAJE MARIA ANGELICA	3740	0	22
22145	PARAJE VILLA YOLANDA	3740	0	22
22146	EL CARMEN PUENTE ALTO	4178	0	24
22147	PROVIRU	3740	0	22
22148	BOCA DEL RIACHO DE PILAGA	3600	0	9
22149	CA	3600	0	9
22150	AGUA BLANCA	5250	0	22
22151	CAPILLA SAN ANTONIO	3600	0	9
22152	ANTUCO	5250	0	22
22153	ARBOLITOS	5250	0	22
22154	COLONIA PUENTE PUCU	3600	0	9
22155	BALBUENA	5250	0	22
22156	BUENA VISTA	5250	0	22
22157	CALERAS	5250	0	22
22158	COLONIA PUENTE URIBURU	3600	0	9
22159	GUAYCOLEC	3600	0	9
22160	HOSPITAL RURAL	3600	0	9
22161	ISLA 9 DE JULIO	3600	0	9
22162	ISLA OCA	3600	0	9
22163	LA COLONIA	3600	0	9
22164	LA FLORIDA	3600	0	9
22165	LOTE 4	3600	0	9
22166	EL CEVILAR	4178	0	24
22167	MONTE AGUDO	3600	0	9
22168	MONTE LINDO	3600	0	9
22169	MONTEAGUDO	3600	0	9
22170	EL CORTE	4178	0	24
22171	EL CRUCE	4178	0	24
22172	PQUE BOT FORESTAL L TORTORELLI	3600	0	9
22173	EL CUADRO	4178	0	24
22174	COSTA DEL TAMBO	5801	0	6
22175	PRESIDENTE YRIGOYEN	3601	0	9
22176	PUERTO DALMACIA	3600	0	9
22177	SANTA CATALINA	3600	0	9
22178	TIMBO PORA	3600	0	9
22179	TRES MARIAS	3600	0	9
22180	EL PAJAL	4178	0	24
22181	VILLA EMILIA	3600	0	9
22182	COLONIA DALMACIA	3600	0	9
22183	EL PALOMAR	4186	0	24
22184	COLONIA ISLA ALVAREZ	3600	0	9
22185	COLONIA ISLA DE ORO	3600	0	9
22186	EL PRADO	4184	0	24
22187	EL TALAR	4178	0	24
22188	CA	5250	0	22
22189	CANTAMAMPA	5250	0	22
22190	ESCUELA BLAS PARERA	4178	0	24
22191	CARANCHI YACO	5250	0	22
22192	ESCUELA 106	4178	0	24
22193	SIERRA CHICA	9121	0	5
22194	CARRERA VIEJA	5250	0	22
22195	ESCUELA 108	4178	0	24
22196	CHA	5250	0	22
22197	ESCUELA 109	4178	0	24
22198	ESCUELA 110	4178	0	24
22199	CHA	5251	0	22
22200	ESCUELA 111	4178	0	24
22201	CORTADERAS	5250	0	22
22202	EL DIVISADERO	5250	0	22
22203	ESCUELA 12 DE OCTUBRE	4178	0	24
22204	EL PUESTO	5250	0	22
22205	EL RETIRO	5251	0	22
22206	ESCUELA 141	4178	0	24
22207	EL SAUCE	5250	0	22
22208	ESCUELA 142	4178	0	24
22209	EL SEGUNDO	5250	0	22
22210	ESPERANZA	5250	0	22
22211	ESCUELA 220	4178	0	24
22212	ESPINILLO	5250	0	22
22213	JUME	5250	0	22
22214	ESCUELA 225	4178	0	24
22215	LA CA	5250	0	22
22216	ESCUELA 228	4178	0	24
22217	LA CLEMIRA	5250	0	22
22218	LA CRUZ	5250	0	22
22219	ESCUELA 270	4178	0	24
22220	LA PRIMAVERA	5250	0	22
22221	ESCUELA 277	4178	0	24
22222	LA RESBALOSA	5250	0	22
22223	LA RINCONADA	5250	0	22
22224	ESCUELA 283	4178	0	24
22225	ESCUELA 284	4178	0	24
22226	ESCUELA 291	4178	0	24
22227	LA TOTORILLA	5250	0	22
22228	ESCUELA 3	4178	0	24
22229	LA VERDE	5250	0	22
22230	ESCUELA 308	4178	0	24
22231	LAS AGUILAS	5250	0	22
22232	LAS CHACRAS	5250	0	22
22233	ESCUELA 312	4178	0	24
22234	LAS HORQUETAS	5250	0	22
22235	LAS TALAS	5250	0	22
22236	ESCUELA 327	4178	0	24
22237	ESCUELA 329	4178	0	24
22238	LESCANO	5250	0	22
22239	LLAMA PAMPA	5250	0	22
22240	ESCUELA 330	4178	0	24
22241	LOMA COLORADA	5250	0	22
22242	ESCUELA 334	4178	0	24
22243	LOS ALGARROBOS	5250	0	22
22244	ESCUELA 335	4178	0	24
22245	LOS CHA	5250	0	22
22246	ESCUELA 56	4178	0	24
22247	LOS SUNCHOS	5250	0	22
22248	ESCUELA 76	4178	0	24
22249	MANFLOA	5250	0	22
22250	ESCUELA 86	4178	0	24
22251	MOLLE POZO	5250	0	22
22252	ESCUELA 9	4178	0	24
22253	POZO CABADO	5250	0	22
22254	POZO DEL CHA	5250	0	22
22255	POZO DEL MACHO	5250	0	22
22256	POZO ESCONDIDO	5250	0	22
22257	POZO REDONDO	5250	0	22
22259	SAN LORENZO	5250	0	22
22260	ESCUELA ALMAFUERTE	4178	0	24
22261	SAN PEDRO	5250	0	22
22262	SOLEDAD	5250	0	22
22263	ESCUELA ARENALES	4178	0	24
22264	TACO MISQUI	5250	0	22
22265	TALA YACU	5250	0	22
22266	ESCUELA CORONEL ROCA	4178	0	24
22267	TIGRE MUERTO	5250	0	22
22268	ESCUELA E DE LUCAS	4178	0	24
22269	YLUMAMPA	5250	0	22
22270	ESCUELA G DE VEGA	4178	0	24
22271	ARBOL SOLO	5253	0	22
22272	ESCUELA GUIDO SPANO	4178	0	24
22273	CA	5253	0	22
22274	ESCUELA INGENIERO BASCARY	4178	0	24
22275	CASA DE DIOS	5253	0	22
22276	COSTA VIEJA	5253	0	22
22277	ESCUELA JOSE COLOMBRES	4178	0	24
22278	EL BAJO	5253	0	22
22279	EL MOLLE	5253	0	22
22280	ESCUELA JOSE POSSE	4178	0	24
22281	EL NARANJO	5251	0	22
22282	ESCUELA JUANA MANSO	4178	0	24
22283	EL PALOMAR	5253	0	22
22284	EL VENTICINCO	4233	0	22
22285	ESCUELA N VERGARA	4178	0	24
22286	LA BELLA CRIOLLA	5253	0	22
22287	LA COLINA	5253	0	22
22288	LA PORFIA	5253	0	22
22289	LAS FLORES	5253	0	22
22290	ESCUELA R J FREYRE	4178	0	24
22291	LOS PAREDONES	5253	0	22
22292	MEDANOS	5253	0	22
22293	ESCUELA SANTIAGO GALLO	4178	0	24
22294	PAJARO BLANCO	5253	0	22
22295	PALOMAR	5253	0	22
22296	POZO DEL CHA	5253	0	22
22297	POZO VERDE	5253	0	22
22298	PUNITA NORTE	5253	0	22
22299	ESCUELA SARGENTO CABRAL	4178	0	24
22300	PUNITA SUD	5253	0	22
22301	ESCUELA W POSSE	4178	0	24
22302	SAN CARLOS	5253	0	22
22303	SAN JAVIER	5253	0	22
22304	SAN MATEO	5253	0	22
22305	ALTA GRACIA	4220	0	22
22306	ESCUELA 57	4220	0	22
22307	ESCUELA 1080	4220	0	22
22308	ESCUELA 109	4220	0	22
22309	FINCA EL CEIBO	4178	0	24
22310	POSTA SANITARIA POCITOS	4220	0	22
22311	FINCA LEILA	4178	0	24
22312	FINCA LOPEZ	4117	0	24
22313	LA COLORADA	5831	0	6
22314	FINCA SAN LUIS	4132	0	24
22315	LA CUMBRE	5801	0	6
22316	LA DORMIDA	5817	0	6
22317	LA ESQUINA	5801	0	6
22318	INGENIO ESPERANZA	4187	0	24
22319	CHA	2354	0	22
22320	INGENIO LOS RALOS	4182	0	24
22321	COLONIA LA VICTORIA	2354	0	22
22322	KILOMETRO 781	4184	0	24
22323	EL ASPIRANTE	2354	0	22
22324	KILOMETRO 784	4184	0	24
22325	KILOMETRO 794	4184	0	24
22326	EL ARENAL	4166	0	24
22327	GRAL IGNACIO H FOTHERINGHAM	3526	0	9
22328	KILOMETRO 1270	4178	0	24
22329	EL CHARABON	2354	0	22
22330	KILOMETRO 34	4178	0	24
22331	KILOMETRO 771	4178	0	24
22332	EL OSO	2354	0	22
22333	EL UCLE	2354	0	22
22334	EL INDIO	4142	0	24
22335	FORTIN LA VIUDA	2354	0	22
22336	LA CANTINA	4178	0	24
22337	EL NARANJAL	4142	0	24
22338	LA CORNELIA	4178	0	24
22339	KILOMETRO 735	2354	0	22
22340	LA BLANCA	2354	0	22
22341	LA ERCILIA	4178	0	24
22342	LA CAROLINA	2354	0	22
22343	LA CENTELLA	2354	0	22
22344	LA ESMERALDA	2354	0	22
22345	LA RECOMPENSA	2354	0	22
22346	LA ROMELIA	2354	0	22
22347	LA UNION	2354	0	22
22348	LA VICTORIA	2354	0	22
22349	EL PALCARA	4151	0	24
22350	LAS PALMAS	2354	0	22
22351	LOS ENCANTOS	2354	0	22
22352	ESCUELA	4142	0	24
22353	ESCUELA 101	4142	0	24
22354	LA GUILLERMINA	4178	0	24
22355	ESCUELA 121	4142	0	24
22356	ESCUELA 13	4142	0	24
22357	ESCUELA 135	4142	0	24
22358	ESCUELA 139	4142	0	24
22359	ESCUELA 14	4142	0	24
22360	ESCUELA 143	4142	0	24
22361	ESCUELA 144	4142	0	24
22362	LA MEDIA AGUA	4178	0	24
22363	ESCUELA 148	4142	0	24
22364	ESCUELA 165	4142	0	24
22365	MARAVILLA	2354	0	22
22366	ESCUELA 202	4142	0	24
22367	NUEVA TRINIDAD	2354	0	22
22368	ESCUELA 236	4142	0	24
22369	ESCUELA 258	4142	0	24
22370	ESCUELA 281	4142	0	24
22371	ESCUELA 285	4142	0	24
22372	ESCUELA 29	4142	0	24
22373	ESCUELA 290	4142	0	24
22374	ESCUELA 297	4142	0	24
22375	ESCUELA 315	4142	0	24
22376	ESCUELA 319	4142	0	24
22377	ESCUELA 35	4142	0	24
22378	ESCUELA 361	4142	0	24
22379	ESCUELA 53	4142	0	24
22380	SAN JOSE	2354	0	22
22381	SAN SEBASTIAN	2354	0	22
22382	LOLITA NUEVA	4182	0	24
22383	ESCUELA FRAY M ESQUIU	4142	0	24
22384	SANTA ANA	2354	0	22
22385	ESCUELA IBATIN	4142	0	24
22386	TRES POZOS	2354	0	22
22387	LOPEZ DOMINGUEZ	4184	0	24
22388	ESCUELA J CASTELLANO	4142	0	24
22389	ASPA SINCHI	4322	0	22
22390	ESCUELA M ARIZA	4142	0	24
22391	CHAGUAR PUNCU	4322	0	22
22392	LOS BULACIO	4111	0	24
22393	ESCUELA MANUEL BORDA	4142	0	24
22394	ESCUELA TAMBOR DE TACUARI	4142	0	24
22395	NUEVA INDUSTRIA	4322	0	22
22396	ESCUELA 380	4142	0	24
22397	MARIA DELICIA	4322	0	22
22398	FIN DEL MUNDO	4142	0	24
22399	SAN JAVIER	4322	0	22
22400	IBATIN	4142	0	24
22401	TRES LAGUNAS	3601	0	9
22402	SOLDADO EDMUNDO SOSA	3603	0	9
22403	RIACHO LINDO	3601	0	9
22404	POTRERO DE LOS CABALLOS	3526	0	9
22405	INGENIO SANTA LUCIA	4135	0	24
22406	LA ESPERANZA	3606	0	9
22407	SAN RAMON	4322	0	22
22408	KILOMETRO 100	3526	0	9
22409	MARTA	4178	0	24
22410	MORELLO	4312	0	22
22411	ISLA SAN JOSE SUD	4142	0	24
22412	KILOMETRO 128	3608	0	9
22413	COLONIA SAN ISIDRO	3526	0	9
22414	COLONIA CANO	3601	0	9
22415	KILOMETRO 1213	4172	0	24
22416	NARANJITO	4115	0	24
22417	KILOMETRO 1500	4142	0	24
22418	KILOMETRO 93	4142	0	24
22419	OVERO POZO	4178	0	24
22420	P G MENDEZ	4117	0	24
22421	LA HELADERA	4142	0	24
22422	LA QUINTA	4142	0	24
22423	LUIS PASTEUR	4178	0	24
22424	PEREYRA NORTE	4178	0	24
22425	LA INVERNADA	5801	0	6
22426	LAS PAMPITAS	4142	0	24
22427	ANCA	4321	0	22
22428	LAS TALITAS	4242	0	24
22429	PEREYRA SUR	4178	0	24
22431	CERRILLOS	4321	0	22
22432	EL CINCUENTA	4321	0	22
22433	LA MERCANTIL	5841	0	6
22434	HUTCU CHACRA	4321	0	22
22435	LAS LOMAS	4321	0	22
22436	PASO DEL SALADILLO	4321	0	22
22437	LA MESADA	5801	0	6
22438	SAN FERNANDO	4321	0	22
22439	TACO ISLA	4321	0	22
22440	TRONCAL	4321	0	22
22441	LA RAMONCITA	5813	0	6
22442	POTRERO DE LOS ALAMOS	4178	0	24
22443	CARBON POZO	4324	0	22
22444	LA SIERRITA	5813	0	6
22445	CAZADORES	4324	0	22
22446	COLLUJLIOJ	4324	0	22
22447	POZO ALTO	4111	0	24
22448	CORASPINO	4324	0	22
22449	LA VERONICA	5801	0	6
22450	DIASPA	4324	0	22
22451	EL BAJO	4324	0	22
22452	EL JUNCAL	4324	0	22
22453	LAGUNA CLARA	5813	0	6
22454	POZO DEL ALTO	4184	0	24
22455	GUAIPI	4324	0	22
22456	HORNILLOS	4324	0	22
22457	LA BLANCA	4324	0	22
22458	LA CRUZ	4324	0	22
22459	LAGUNA OSCURA	6144	0	6
22460	LA FALDA	4324	0	22
22461	LA OVERA	4324	0	22
22462	LAPA	4324	0	22
22463	MOLLE	4324	0	22
22464	NUEVE MISTOLES	4324	0	22
22465	LAGUNA SECA	5829	0	6
22466	POZO	4324	0	22
22467	POZO MORO	4324	0	22
22468	POZO MOSOJ	4324	0	22
22469	MONTEROS VIEJO	4142	0	24
22470	QUIMILLOJ	4324	0	22
22471	LAS ABAHACAS	5801	0	6
22472	ROSIYULLOJ	4324	0	22
22473	SAN JOSE	4324	0	22
22474	MOTHE	4172	0	24
22475	SAN PEDRO	4324	0	22
22476	TACO HUACO	4324	0	22
22477	TACO SUYO	4324	0	22
22478	QUINTEROS 1	4144	0	24
22479	TORO POZO	4324	0	22
22480	YACANO	4324	0	22
22481	LAS CALECITAS	5801	0	6
22482	YALAN	4324	0	22
22483	QUINTEROS 2	4144	0	24
22484	BUEY RODEO	4206	0	22
22485	CAMPO ALEGRE	4206	0	22
22486	RAFAELA POZO	4115	0	24
22487	CAMPO GRANDE	4206	0	22
22488	LAS CA	5801	0	6
22489	CAMPO NUEVO	4206	0	22
22490	CHA	4206	0	22
22491	CRUZ POZO	4206	0	22
22492	LAS CINCO CUADRAS	5841	0	6
22493	LAS ENSENADAS	5825	0	6
22494	EL MARNE	4206	0	22
22495	EL MOJON	4206	0	22
22496	LAS GAMAS	5819	0	6
22497	ESTABLECIMIENTO 14 DE SETIEMBR	4206	0	22
22498	RUTA NACIONAL 9	4178	0	24
22499	RUTA PROVINCIAL 302	4178	0	24
22500	PIEDRAS COLORADAS	4142	0	24
22501	LAS GUINDAS	5801	0	6
22502	RUTA PROVINCIAL 303	4178	0	24
22503	KILOMETRO 135	4206	0	22
22504	EZCURRA	4206	0	22
22505	LAS MORAS	5801	0	6
22506	RUTA PROVINCIAL 304	4178	0	24
22507	KILOMETRO 153	4206	0	22
22508	RUTA PROVINCIAL 306	4178	0	24
22509	LA ABRITA	4206	0	22
22510	LAS PE	5817	0	6
22511	LA ESPERANZA	4206	0	22
22512	RUTA PROVINCIAL 319	4178	0	24
22513	LA PORTE	4206	0	22
22514	PLAYA LARGA	4142	0	24
22515	LA SARITA	4206	0	22
22516	LAS PE	5819	0	6
22517	LAS FLORES	4206	0	22
22518	MACO	4206	0	22
22519	MAQUITO	4206	0	22
22520	MONTE RICO	4206	0	22
22521	RUTA PROVINCIAL 335	4178	0	24
22523	PUEBLO NUEVO	4206	0	22
22524	PUESTITO DE SAN ANTONIO	4206	0	22
22525	SAN AGUSTIN	4206	0	22
22526	RANCHO DE CASCADA	4142	0	24
22527	SAN ANDRES	4206	0	22
22528	LAS TAPIAS	5801	0	6
22529	SAN BENITO	4206	0	22
22530	LOS JAGUELES	5839	0	6
22531	RINCON GRANDE	4142	0	24
22532	LOS MEDANOS	5815	0	6
22533	SAN IGNACIO	4206	0	22
22534	SAN ISIDRO	4201	0	22
22535	SAN PEDRO	4206	0	22
22536	LOS TRES POZOS	5851	0	6
22537	SAN SEBASTIAN	4206	0	22
22538	SANTA ROSA	4206	0	22
22539	SANTO DOMINGO	4206	0	22
22540	TROZO POZO	4206	0	22
22541	RUTA NACIONAL 38	4142	0	24
22542	EL MISTOLAR	3636	0	9
22543	MONTE LA INVERNADA	5801	0	6
22544	UPIANITA	4206	0	22
22545	EL POTRERITO	3636	0	9
22546	VUELTA DE LA BARRANCA	4206	0	22
22547	EL TOTORAL	3636	0	9
22548	YANDA	4206	0	22
22549	LA FLORENCIA	3636	0	9
22550	PASO CABRAL	5817	0	6
22551	LA JUNTA	3636	0	9
22552	LAS CA	3636	0	9
22554	SANTA TERESA	3636	0	9
22555	SAN ANDRES	4111	0	24
22556	PASO DEL DURAZNO	5803	0	6
22557	TTE GRAL ROSENDO N FRA	3636	0	9
22558	PERMANENTES	5801	0	6
22560	PIEDRA BLANCA	5801	0	6
22563	PRETOT FREYRE	6140	0	6
22564	PUEBLO ALBERDI	5800	0	6
22565	ATHOS PAMPA	5194	0	6
22566	PUENTE LOS MOLLES	5809	0	6
22567	ALTO DEL TALA	5295	0	6
22568	PUERTA COLORADA	5817	0	6
22569	AMBOY	5199	0	6
22570	PUNTA DEL AGUA	5839	0	6
22571	RIO SECO	5801	0	6
22572	ARROYO SAN ANTONIO	5859	0	6
22573	RODEO VIEJO	5801	0	6
22574	SAN AMBROSIO	5848	0	6
22575	ARROYO SANTANA	5819	0	6
22576	SAN BARTOLOME	5801	0	6
22577	ESQUINITAS	3636	0	9
22578	SAN BERNARDO	5848	0	6
22579	ARROYO SECO	5196	0	6
22580	SAN LUCAS NORTE	5837	0	6
22581	SANTA RITA	4178	0	24
22582	SORIA	5829	0	6
22583	ARROYO TOLEDO	5819	0	6
22584	SINQUIAL	4178	0	24
22585	SUCO	5837	0	6
22586	TAMBOR DE TACUARI	4117	0	24
22587	TEGUA	5813	0	6
22588	VA RECASTE	4178	0	24
22589	ATUMI PAMPA	5196	0	6
22590	VILLA EL CHACAY	5801	0	6
22591	SAN JOSE	4186	0	24
22592	SANTO DOMINGO	4142	0	24
22593	VILLA SANTA RITA	5801	0	6
22594	BAJO DEL CARMEN	5189	0	6
22595	VILLA BRAVA	4142	0	24
22596	YONOPONGO SUD	4142	0	24
22597	YATAY	5841	0	6
22598	CALMAYO	5191	0	6
22599	ZANJON MASCIO	4172	0	24
22600	ZAVALIA	4142	0	24
22601	ZAPOLOCO	5839	0	6
22602	AGUA BLANCA	4132	0	24
22603	CAMPO SAN ANTONIO	5821	0	6
22604	BAJADA NUEVA	5813	0	6
22605	CA	5819	0	6
22606	BARRANCAS COLORADAS	4132	0	24
22607	LA CAROLINA	5841	0	6
22608	LA GILDA	5848	0	6
22609	CA	5199	0	6
22610	CA	5196	0	6
22611	CAMPO REDONDO	4168	0	24
22612	CA	5817	0	6
22613	CA	5859	0	6
22614	COLONIA ACEVEDO	4132	0	24
22615	CARAHUASI	5196	0	6
22616	COLONIA BASCARY	4132	0	24
22617	CERRO BLANCO	5191	0	6
22618	CERRO COLORADO	5821	0	6
22619	CERRO SAN LORENZO	5821	0	6
22620	COLONIA PACARA	4132	0	24
22621	CERROS ASPEROS	5859	0	6
22622	COLONIA NUEVA TRINIDAD	4152	0	24
22623	CUESTA DE LA CHILCA	4153	0	24
22624	COLONIA SANTA LUCIA	4132	0	24
22625	EL CEBIL	4152	0	24
22626	COLONIA SANTA RITA	4132	0	24
22627	ESCUELA 137	4152	0	24
22628	ESCUELA 140	4152	0	24
22629	EL MATADERO	4132	0	24
22630	ESCUELA 176	4152	0	24
22631	ESCUELA 21	4152	0	24
22632	ESCUELA 264	4152	0	24
22633	COLONIA ALEMANA	5196	0	6
22634	ESCUELA 274	4152	0	24
22635	ESCUELA 279	4152	0	24
22636	EL TROPEZON	4132	0	24
22637	ESCUELA 280	4152	0	24
22638	ESCUELA 287	4152	0	24
22639	ESCUELA 288	4152	0	24
22640	ESCUELA 289	4152	0	24
22641	ESCUELA 100	4132	0	24
22642	ESCUELA 124	4132	0	24
22643	ESCUELA 320	4152	0	24
22644	ESCUELA 64	4152	0	24
22645	ESCUELA 66	4152	0	24
22646	ESCUELA 154	4132	0	24
22647	ESCUELA 160	4132	0	24
22648	ESCUELA 67	4152	0	24
22649	COLONIA LA CALLE	5196	0	6
22650	ESCUELA 197	4132	0	24
22651	ESCUELA ALFONSINA STORNI	4152	0	24
22652	ESCUELA CARLOS PELLEGRINI	4152	0	24
22653	ESCUELA 200	4132	0	24
22654	ESCUELA DOMINGO GARCIA	4152	0	24
22655	ESCUELA 206	4132	0	24
22656	CNIA VACACIONES DE EMPLEADO	5857	0	6
22657	ESCUELA 257	4132	0	24
22658	ESCUELA LUIS GIANNEO	4152	0	24
22659	ESCUELA 261	4132	0	24
22660	ESCUELA 298	4132	0	24
22661	ESCUELA 321	4132	0	24
22662	DOS ARROYOS	5189	0	6
22663	ESCUELA 356	4132	0	24
22664	ESCUELA 373	4132	0	24
22665	ESCUELA 63	4132	0	24
22666	ESCUELA 88	4132	0	24
22667	EL CARMEN	5197	0	6
22668	ESCUELA CONGRESALES TUCUMANOS	4132	0	24
22669	EL MANANTIAL	5819	0	6
22670	ESCUELA GUILLERMINA MOREIRA	4132	0	24
22671	BAJO DE FERNANDEZ	5101	0	6
22672	ESCUELA MONTE GRANDE	4132	0	24
22673	EL PARADOR DE LA MONTA	5197	0	6
22674	ESCUELA VELEZ SARSFIELD	4132	0	24
22675	BALNEARIO GUGLIERI	5137	0	6
22676	ESQUINA NORTE	4132	0	24
22677	BUEY MUERTO	5135	0	6
22678	EL PORTEZUELO	5196	0	6
22679	CAMPO RAMALLO	5225	0	6
22680	FINCA ARAOZ	4168	0	24
22681	EL QUEBRACHO	5854	0	6
22682	EL SAUCE	5196	0	6
22683	CA	5135	0	6
22684	EL TORREON	5864	0	6
22685	CA	5101	0	6
22686	INGENIO LA FRONTERITA	4132	0	24
22687	FABRICA MILITAR	5189	0	6
22688	CA	5961	0	6
22689	CA	5227	0	6
22690	FALDA DE LOS REARTES	5189	0	6
22691	CAPILLA DE DOLORES	5125	0	6
22692	KILOMETRO 1240	4168	0	24
22693	LA CALERA	5819	0	6
22694	KILOMETRO 1244	4168	0	24
22695	LA CASCADA	5854	0	6
22696	CAPILLA LA ESPERANZA	5129	0	6
22697	CASTELLANOS	5135	0	6
22698	LA CHOZA	5196	0	6
22699	CHARCAS NORTE	5127	0	6
22700	CHALACEA	5229	0	6
22701	LA CUMBRECITA	5194	0	6
22702	COLONIA CA	5137	0	6
22703	LAS BAJADAS	5851	0	6
22704	COLONIA LA ARGENTINA	5137	0	6
22705	LAS CALERAS	5819	0	6
22706	LAS HIGUERITAS	5199	0	6
22707	COLONIA LAS CUATRO ESQUINAS	5135	0	6
22708	COLONIA SAGRADA FAMILIA	5125	0	6
22709	LAS SIERRITAS	5199	0	6
22710	COLONIA SAN IGNACIO	5189	0	6
22711	LOMA REDONDA	5299	0	6
22712	COLONIA YARETA	5137	0	6
22713	CONSTITUCION	5125	0	6
22714	CORRAL DE GOMEZ	5135	0	6
22715	COSTA DEL CASTA	5137	0	6
22716	MAYOR MARCELO T ROJAS	3620	0	9
22717	KILOMETRO 108	4132	0	24
22718	LA AGUADA	4111	0	24
22719	LA PINTA Y LA CUARENTA	4132	0	24
22720	LAS RATAS	4132	0	24
22721	LAS TRES FLORES	4132	0	24
22722	INGENIO SANTA ANA	4155	0	24
22723	KILOMETRO 1455	4152	0	24
22724	LAS TUSCAS TUSCAL	4155	0	24
22725	LOS OCHO CUARTOS	4152	0	24
22726	LAURELES NORTE	4132	0	24
22727	MORAS MINUCAS	4152	0	24
22728	POTRERO DE LAS CABRAS	4152	0	24
22729	LAURELES SUR	4132	0	24
22733	VILLA VIEJA SANTA ANA	4155	0	24
22734	LOS SIFONES	4132	0	24
22735	DESVIO CHALACEA	5229	0	6
22736	EL ALCALDE	5131	0	6
22737	EL BAGUAL	5137	0	6
22738	LOS CERROS NEGROS	5821	0	6
22739	LOS REARTES	5194	0	6
22740	EL CARRIZAL	5135	0	6
22741	LUTTI	5859	0	6
22742	MAR AZUL	5199	0	6
22743	MONSALVO	5851	0	6
22744	PASO SANDIALITO	5819	0	6
22745	PERMANENTES	5821	0	6
22746	EL CRISPIN	5129	0	6
22747	POTRERO DE LUJAN	5191	0	6
22748	PUESTO MULITA	5189	0	6
22749	EL ESPINAL	5133	0	6
22750	EL QUEBRACHO	5101	0	6
22751	RINCON DE LUNA	5197	0	6
22752	EL TOSTADO	5137	0	6
22753	ESCUELA DE ARTILLERIA	5101	0	6
22754	ESPERANZA	5131	0	6
22755	RIO DEL DURAZNO	5197	0	6
22756	RUTA NACIONAL 157	4132	0	24
22757	RUTA NACIONAL 38	4132	0	24
22758	ESPINILLO	5129	0	6
22759	RIO GRANDE AMBOY	5199	0	6
22760	RUTA PROVINCIAL 322	4132	0	24
22761	RUTA PROVINCIAL 334	4132	0	24
22762	RODEO LAS YEGUAS	5821	0	6
22763	GENERAL LAS HERAS	5101	0	6
22764	RUTA PROVINCIAL 380	4132	0	24
22765	SAN IGNACIO	5199	0	6
22766	ISLA DEL CERRO	5129	0	6
22767	ISLA LARGA	5129	0	6
22768	SAN ROQUE	5199	0	6
22769	ISLA VERDE	5225	0	6
22770	ANDRES FLORES	3620	0	9
22771	CAMPO ALEGRE	3630	0	9
22772	SANTA MONICA	5197	0	6
22773	CAMPO OSWALD	3608	0	9
22774	KILOMETRO 271	5139	0	6
22775	CAMPO REDONDO	3630	0	9
22776	KILOMETRO 294	5137	0	6
22777	COLONIA SANTA CATALINA	3630	0	9
22778	SARLACO	5196	0	6
22779	COLONIA 8 DE SEPTIEMBRE	3630	0	9
22780	KILOMETRO 316	5137	0	6
22781	SAUCE PARTIDO	4132	0	24
22782	SEGUNDA USINA	5857	0	6
22783	CNIA ABORIGEN BME DE LAS CASAS	3630	0	9
22784	COLONIA ALTO TIGRE	3620	0	9
22785	KILOMETRO 658	5125	0	6
22786	SIERRA BLANCA	5819	0	6
22787	COLONIA LOS TRES REYES	3630	0	9
22788	KILOMETRO 691	5125	0	6
22789	SIERRAS MORENAS	5189	0	6
22790	COLONIA SAN BERNARDO	3630	0	9
22791	SOCONCHO	5191	0	6
22792	COLONIA SAN PABLO	3630	0	9
22793	LA BUENA PARADA	5129	0	6
22794	COLONIA SANTORO	3630	0	9
22795	SOLAR LOS MOLINOS	5189	0	6
22796	LA CA	5101	0	6
22797	TALA CRUZ	5859	0	6
22798	LA CELINA	5125	0	6
22799	TERCERA	5189	0	6
22800	COLONIA SIETE QUEBRADOS	3624	0	9
22801	ALTO DEL PUESTO	4176	0	24
22802	TIGRE MUERTO	5859	0	6
22803	COLONIA VILLA RICA	3630	0	9
22804	LA CIENAGA	5133	0	6
22805	ALTO VERDE	4176	0	24
22806	EL COATI	3630	0	9
22807	USINA NUCLEAR EMBALSE	5859	0	6
22808	EL CORREDERO	3630	0	9
22809	AMIMPA	4176	0	24
22810	EL MIRADOR	3630	0	9
22811	LA ESTRELLA	5129	0	6
22812	VALLE DORADO	5864	0	6
22813	LA MOSTAZA	5137	0	6
22814	EL 	3608	0	9
22815	EL PERDIDO	3630	0	9
22816	VILLA AGUADA DE LOS REYES	5857	0	6
22817	ANIMAS	4176	0	24
22818	LA POSTA	5227	0	6
22819	VILLA ALPINA	5194	0	6
22820	EL QUEBRACHO	3630	0	9
22821	LA QUINTA	5135	0	6
22822	EL TACURUZAL	3630	0	9
22823	VILLA AMANCAY	5199	0	6
22824	ARBOLES VERDES	4176	0	24
22825	EL TOTORAL	3630	0	9
22826	EL YACARE	3630	0	9
22827	LAS ACACIAS	5129	0	6
22828	VILLA DEL PARQUE	5864	0	6
22830	ESPINILLO	3630	0	9
22831	BARRANQUERAS	4176	0	24
22832	LAS BANDURRIAS NORTE	5225	0	6
22833	FORTIN MEDIA LUNA	3634	0	9
22834	VILLA DEL TALA	5859	0	6
22835	BARROSA	4176	0	24
22836	GABRIELA MISTRAL	3626	0	9
22837	GENERAL MANUEL BELGRANO	3615	0	9
22838	VILLA EL TORREON	5199	0	6
22839	LAS CABRAS	5127	0	6
22840	KILOMETRO 15	3630	0	9
22841	VILLA LA COBA	5819	0	6
22842	CAJAS VIEJAS	4162	0	24
22843	KILOMETRO 1695	3632	0	9
22844	VILLA LAGO AZUL	5199	0	6
22845	CAMPO ALEGRE	4176	0	24
22846	KILOMETRO 525	3630	0	9
22848	CA	4176	0	24
22849	BALDERRAMA SUR	4174	0	24
22850	VILLA NATURALEZA	5864	0	6
22851	BUENA YERBA	4174	0	24
22852	CORONA	4174	0	24
22853	EL DURAZNO	4174	0	24
22854	CASA SANTA	4176	0	24
22855	LAS GRAMILLAS	5135	0	6
22856	EL MOLLAR	4174	0	24
22857	VILLA QUILLINZO	5859	0	6
22859	EL RODEO	4174	0	24
22860	LA SOLEDAD	3630	0	9
22861	ENTRE RIOS	4174	0	24
22862	LAS HERAS	5101	0	6
22863	LAS DELICIAS	3630	0	9
22864	ESCUELA 116	4172	0	24
22865	VILLA SAN JAVIER	5199	0	6
22866	LOS BALDES	3630	0	9
22867	ESCUELA 126	4172	0	24
22868	LOS CLAVELES	3630	0	9
22869	LAS HIGUERILLAS	5131	0	6
22870	LOS SUSPIROS	3630	0	9
22871	VILLA SIERRAS DEL LAGO	5857	0	6
22872	CHA	4176	0	24
22873	LOS TRES REYES	3630	0	9
22874	LAS HILERAS	5137	0	6
22875	ESCUELA 129	4172	0	24
22877	CHA	4242	0	24
22878	VISTA ALEGRE	5197	0	6
22879	ESCUELA 131	4172	0	24
22880	PASO NALTE	3630	0	9
22881	PAVAO	3630	0	9
22882	ESCUELA 133	4172	0	24
22883	LAS PALMITAS	5227	0	6
22884	LAS PE	5823	0	6
22885	POSTA SAN MARTIN 1	3628	0	9
22886	POSTA SAN MARTIN 2	3621	0	9
22887	LAS PIGUAS	5129	0	6
22888	LOS COCOS	5821	0	6
22889	POZO DE LOS CHANCHOS	3630	0	9
22890	LOMAS DEL TROZO	5137	0	6
22893	POZO EL LECHERON	3630	0	9
22894	LOS ALGARROBITOS	5225	0	6
22895	POZO HONDO	3630	0	9
22896	POZO LA CHINA	3630	0	9
22897	PUERTO RAMONA	3630	0	9
22898	PUESTO AGUARA	3630	0	9
22899	LOS ALVAREZ	5133	0	6
22900	REDUCCION CACIQUE COQUENA	3630	0	9
22901	RINCON 	3608	0	9
22902	MODESTO ACU	5823	0	6
22903	RIO CUE	3630	0	9
22904	LOS AVILES	5137	0	6
22905	SAN ISIDRO	3630	0	9
22906	RODEO DE LOS CABALLOS	5821	0	6
22907	SAN MARTIN 1	3630	0	9
22908	LOS CASTA	5137	0	6
22909	SAN MIGUEL	3630	0	9
22910	SAN RAMON	3630	0	9
22911	SANTA ROSA	3630	0	9
22912	VILLA EL CORCOVADO	5199	0	6
22913	LOS CERROS	5137	0	6
22914	LOS CHA	5133	0	6
22916	LOS GUINDOS	5127	0	6
22918	TATU PIRE	3630	0	9
22919	LOS MANSILLAS	5127	0	6
22920	LOS MIGUELITOS	5137	0	6
22922	LOS POZOS	5225	0	6
22924	FORTIN CABO 1RO CHAVEZ	3630	0	9
22925	CONSIMO	4174	0	24
22926	MAQUINISTA GALLINI	5227	0	6
22927	DOS POZOS	4176	0	24
22928	MIGUELITO	5225	0	6
22929	MONTE DE TORO PUJIO	5135	0	6
22930	NUEVA ANDALUCIA	5101	0	6
22931	EL BA	4176	0	24
22932	PASO DEL SAUCE	5101	0	6
22933	EL BARRANQUERO	4176	0	24
22934	PEDRO E VIVAS	5127	0	6
22935	ESCUELA 134	4172	0	24
22936	ESCUELA 15	4172	0	24
22937	EL CAMPO	4176	0	24
22938	ESCUELA 16	4172	0	24
22939	ESCUELA 162	4172	0	24
22940	EL ESPINAL	4137	0	24
22941	ESCUELA 183	4172	0	24
22942	ESCUELA 193	4172	0	24
22943	ESCUELA 198	4172	0	24
22944	ESCUELA 199	4172	0	24
22945	ESCUELA 20	4172	0	24
22946	ESCUELA 201	4172	0	24
22947	EL MISTOL	4176	0	24
22948	ESCUELA 203	4172	0	24
22949	PLAZA DE MERCEDES	5137	0	6
22950	ESCUELA 237	4172	0	24
22951	ESCUELA 241	4172	0	24
22952	EL MOJON	4117	0	24
22953	ESCUELA 266	4172	0	24
22954	ESCUELA 269	4172	0	24
22955	POZO DE LA ESQUINA	5133	0	6
22956	ESCUELA 286	4172	0	24
22957	EL NIAL	4176	0	24
22958	ESCUELA 297	4172	0	24
22959	ESCUELA 317	4172	0	24
22960	ESCUELA 322	4172	0	24
22961	ESCUELA 332	4172	0	24
22962	EL PALANCHO	4176	0	24
22963	ESCUELA 345	4172	0	24
22964	POZO DE LA LOMA	5125	0	6
22966	ESCUELA 36	4172	0	24
22967	POZO DE LOS TRONCOS	5137	0	6
22968	ESCUELA 391	4172	0	24
22969	ESCUELA 41	4172	0	24
22971	ESCUELA 43	4172	0	24
22972	POZO DEL MORO	5225	0	6
22973	ESCUELA 55	4172	0	24
22974	ESCUELA 68	4172	0	24
22975	BAJO CHICO BAJO GRANDE	5101	0	6
22976	ESCUELA 84	4172	0	24
22977	POZO LA PIEDRA	5135	0	6
22978	ESCUELA 93	4172	0	24
22979	ESCUELA 94	4172	0	24
22980	ESCUELA 95	4172	0	24
22981	EL RODEO	4176	0	24
22982	ESCUELA 97	4172	0	24
22984	PUEBLO PIANELLI	5131	0	6
22985	ESCUELA 99	4172	0	24
22986	EL SAUZAL	4176	0	24
22987	PUESTO DE AFUERA	5131	0	6
22988	ESCUELA AGUEDA DE POSSE	4172	0	24
22989	ESCUELA ARAOZ ALFARO	4172	0	24
22990	PUESTO DE FIERRO	5227	0	6
22992	ESCUELA CNEL GERONIMO HELGUERA	4172	0	24
22993	PUESTO DE PUCHETA	5225	0	6
22994	ESCUELA CORNELIO SAAVEDRA	4172	0	24
22995	ESCUELA GOMEZ	4172	0	24
22996	ESCUELA LOPEZ MA	4172	0	24
22998	EL VALLECITO	4176	0	24
22999	ESCUELA LOPEZ Y PLANES	4172	0	24
23000	PUNTA DEL AGUA	5129	0	6
23001	ESCUELA LUGONES	4172	0	24
23003	ESCUELA MATIENZO	4172	0	24
23004	ESTANCIA SURI YACO	4174	0	24
23005	QUEBRACHOS	5131	0	6
23006	EMBALSE RIO HONDO	4176	0	24
23007	FINCA PACARA	4111	0	24
23009	GRAMAJOS	4159	0	24
23010	RAMALLO	5225	0	6
23011	INGAS	4174	0	24
23012	KILOMETRO 1213	4172	0	24
23014	LA FLORIDA	4174	0	24
23015	RANGEL	5131	0	6
23016	LA LOMA	4174	0	24
23017	LA PLANTA	4174	0	24
23018	LA REINA	4174	0	24
23019	LA TUNA	4174	0	24
23021	SAN RAMON	5137	0	6
23022	LOMA GRANDE	4174	0	24
23023	ESCUELA 151	4176	0	24
23024	LOS TRES BAJOS	4161	0	24
23025	LOVAR	4174	0	24
23026	ESCUELA 158	4176	0	24
23027	SAN SALVADOR	5227	0	6
23028	MASCIO PILCO	4172	0	24
23030	ESCUELA 172	4176	0	24
23031	SOLEDAD	5137	0	6
23032	ESCUELA 178	4176	0	24
23033	ESCUELA 179	4176	0	24
23034	TALA NORTE	5131	0	6
23035	ESCUELA 180	4176	0	24
23036	ESCUELA 182	4176	0	24
23037	CASEROS ESTE	5123	0	6
23038	TALA SUD	5127	0	6
23039	ESCUELA 184	4176	0	24
23040	ESCUELA 187	4176	0	24
23041	TORDILLA NORTE	5135	0	6
23042	ESCUELA 189	4176	0	24
23043	CNIA HOGAR VELEZ SARSFIELD	5119	0	6
23044	ESCUELA 191	4176	0	24
23045	TOTORAL	5229	0	6
23047	ESCUELA 245	4176	0	24
23048	ESCUELA 302	4176	0	24
23049	ESCUELA 303	4176	0	24
23051	VILLA MAR CHIQUITA	5137	0	6
23052	ESCUELA 306	4176	0	24
23054	ESCUELA 316	4176	0	24
23055	HIGUERILLAS	5125	0	6
23056	ESCUELA 343	4176	0	24
23058	ESCUELA 346	4176	0	24
23059	ESCUELA 72	4176	0	24
23060	ESCUELA 74	4176	0	24
23062	ESCUELA 75	4176	0	24
23063	KILOMETRO 1185	4174	0	24
23064	ESCUELA 90	4176	0	24
23065	ESCUELA 92	4176	0	24
23066	ESCUELA 96	4176	0	24
23067	PAMPA MAYO	4172	0	24
23068	PLANTA COMPRESORA YPF	4174	0	24
23069	ESCUELA CAP DIEGO FCO PEREYRA	4176	0	24
23070	POLIAR	4174	0	24
23072	ESCUELA CRISTOBAL COLON	4176	0	24
23073	ESCUELA 123	4176	0	24
23077	ESQUINA	4176	0	24
23079	SAN CARLOS	4174	0	24
23080	SAN PEDRO MARTIR	4172	0	24
23081	SANTA CRUZ	4149	0	24
23082	SUELDO	4111	0	24
23086	IGUANA	4242	0	24
23088	KILOMETRO 12	4176	0	24
23092	AGUA DE ORO	5248	0	6
23094	KM 12	4159	0	24
23095	AROMITO	2341	0	6
23097	LA BRAMA	4176	0	24
23098	BAJO HONDO	5231	0	6
23100	BALBUENA	5248	0	6
23101	LA CONCEPCION	4176	0	24
23102	LA COSTA PALAMPA	4176	0	24
23103	LA ESPERANZA	4176	0	24
23104	LA ESTRELLA	4176	0	24
23105	KILOMETRO 642	3630	0	9
23106	LA LOMA	4176	0	24
23107	LA SOLEDAD	4176	0	24
23109	BA	5248	0	6
23112	PASO LA CRUZ	3630	0	9
23113	BARRETO	5246	0	6
23114	BUENA VISTA	5249	0	6
23115	CAMOATI	5231	0	6
23116	CAMPO GRANDE	5231	0	6
23117	CA	5248	0	6
23118	CA	5249	0	6
23119	EL CARMEN GUI	5145	0	6
23120	VILLA CANDELARIA NORTE	5249	0	6
23121	EL CHINGOLO	5145	0	6
23122	LAGUNA LARGA	4176	0	24
23123	EL OCHENTA	5123	0	6
23124	EST CANDELARIA NORTE	5235	0	6
23125	EL QUEBRACHAL	5101	0	6
23126	PEDANIA CANDELARIA SUD	5233	0	6
23127	POZO DE NAVAGAN	3630	0	9
23128	EMPALME BARRIO FLORES	5103	0	6
23129	CARNERO YACO	5246	0	6
23130	ABRA BAYA	4137	0	24
23131	ABRA DE LA PICAZA	4137	0	24
23132	ABRA DE YARETA	4137	0	24
23133	CASAS VEJAS	5246	0	6
23135	ABRA DEL INFIERNILLO	4137	0	24
23136	AGUA SALADA	4141	0	24
23137	AGUADA	4137	0	24
23138	CHA	5246	0	6
23139	HARAS SANTA MARTHA	5123	0	6
23140	ALTO CAZADERA	4137	0	24
23141	ALTO DE LOS REALES	4137	0	24
23142	ALTO DEL HUASCHO	4137	0	24
23143	LAS PARRITAS	4176	0	24
23144	KILOMETRO 25 LA CARBONADA	5123	0	6
23145	ALTO DEL LAMPAZO	4137	0	24
23146	CHILE CORRAL AL AGUADA	5246	0	6
23147	ALTO LOS CARDONES	4137	0	24
23148	AMPIMPA	4137	0	24
23149	ANTIGUO QUILMES	4137	0	24
23150	CHILLI CORRAL	5246	0	6
23151	BANDA	4137	0	24
23152	LAS ZANJITAS	4176	0	24
23153	CAMPO BLANCO	4137	0	24
23154	KILOMETRO 679	5123	0	6
23155	CAMPO DE LAS GALLINAS	4137	0	24
23156	CAMPO DE LOS CARDONES	4137	0	24
23157	CORRAL DEL REY	5249	0	6
23158	CAMPO DE LOS CHA	4137	0	24
23159	KILOMETRO 680 RUTA 9	5123	0	6
23160	CAMPO ZAUZAL	4137	0	24
23161	CORRAL VIEJO	5246	0	6
23162	CARAPUNCO	4137	0	24
23163	CASA DE CAMPO	4137	0	24
23164	KILOMETRO 692	5123	0	6
23165	EL ALGARROBAL	5249	0	6
23166	CASA DE PIEDRAS	4158	0	24
23167	CASA DE ZINC	4137	0	24
23168	CHILCAS	4119	0	24
23169	CIENAGUITA	4137	0	24
23170	CORRAL BLANCO	4137	0	24
23171	CORRAL GRANDE	4137	0	24
23172	EL ANTIGAL	4137	0	24
23173	EL ARBOLITO	4187	0	24
23174	EL ARQUEAL	4137	0	24
23175	EL CARMEN	4137	0	24
23176	LOS MISTOLES	4162	0	24
23177	LOS PANCHILLOS	4176	0	24
23178	LOS RUIZ	4176	0	24
23179	LOS SARACHO	4176	0	24
23180	LOS SORAIRE	4176	0	24
23182	EL BA	5248	0	6
23183	LOS SOTELO	4176	0	24
23184	LOS VAZQUEZ	4105	0	24
23185	KILOMETRO 730	5145	0	6
23186	EL CORO	5248	0	6
23187	LA ARABIA	5123	0	6
23188	EL DURAZNO	5249	0	6
23189	MOLLES	4242	0	24
23191	LA PORFIA	5119	0	6
23192	EL GABINO	5248	0	6
23193	LAS SESENTA CUADRAS	5119	0	6
23194	EL GALLEGO	5249	0	6
23198	EL GUANACO	5231	0	6
23199	PALO SECO	4176	0	24
23200	EL JORDAN	5248	0	6
23201	MARIA LASTENIA	5145	0	6
23202	EL LAUREL	5248	0	6
23203	PALOS QUEMADOS	4176	0	24
23205	EL YUCHAN	3630	0	9
23206	EL MANGRULLO	5249	0	6
23207	EL PANTANILLO	5246	0	6
23208	RECREO VICTORIA	5144	0	6
23209	PAMPA MAYO	4172	0	24
23210	EL POZO	5233	0	6
23212	PAMPA MUYO	4176	0	24
23213	EL PRADO	5248	0	6
23215	EL PUESTO	5249	0	6
23216	PAMPA ROSA	4176	0	24
23218	EL QUEBRACHO	5249	0	6
23219	PASO DE LOS NIEVAS	4176	0	24
23220	EL RODEO	5249	0	6
23221	PASO GRANDE	4176	0	24
23223	EL SILVERIO	5248	0	6
23225	POZO EL QUEBRACHO	4176	0	24
23226	EL SIMBOL	5249	0	6
23228	EL TULE	5249	0	6
23229	POZO VERDE	4176	0	24
23231	EL VISMAL	5233	0	6
23232	PUEBLO NUEVO	4164	0	24
23233	EL ZAPALLAR	5233	0	6
23235	ENCRUCIJADA	5231	0	6
23236	VILLA CORAZON DE MARIA	5101	0	6
23237	ESTANCIA PATI	5249	0	6
23238	PUESTO BELEN	4176	0	24
23239	VILLA ESQUIU	5101	0	6
23240	EUFRASIO LOZA	5248	0	6
23241	PUESTO DE GALVANES	4176	0	24
23242	VILLA MIREA	5123	0	6
23243	LA BANDA	5249	0	6
23244	PUESTO DEL MEDIO	4187	0	24
23245	LA BARRANCA	5248	0	6
23246	VILLA POSSE	5123	0	6
23247	LA CA	5231	0	6
23249	LA CHICHARRA	5249	0	6
23250	LA COSTA	5249	0	6
23251	PUESTO LOS BARRAZA	4176	0	24
23252	LA CRUZ	5249	0	6
23253	LA ESTANCIA	5249	0	6
23254	LA MAZA	5231	0	6
23255	LA OSCURIDAD	5255	0	6
23256	PUESTO LOS GALVEZ	4176	0	24
23257	LA PALMA	5231	0	6
23258	LA PENCA	5231	0	6
23259	PUESTO LOS ROBLES	4142	0	24
23260	LA PIEDRA BLANCA	5246	0	6
23261	LA PINTADA	5248	0	6
23262	LA QUINTANA	5249	0	6
23263	LA RINCONADA	5233	0	6
23264	RIO HONDITO	4176	0	24
23265	LA RINCONADA CANDELARIA	5249	0	6
23266	RUMI COCHA	4176	0	24
23267	LA SOLEDAD	5249	0	6
23269	RUTA NACIONAL 157	4176	0	24
23270	AYUDANTE PAREDES	3611	0	9
23271	CHAGADAY	3615	0	9
23272	LAS CA	5246	0	6
23273	RUTA PROVINCIAL 333	4176	0	24
23274	COLONIA 25 DE MAYO	3615	0	9
23275	RUTA PROVINCIAL 334	4176	0	24
23276	LAS CARDAS	5248	0	6
23277	COLONIA SANTA ROSA	3615	0	9
23278	EL POMBERO	3611	0	9
23279	LAS CHACRAS	5249	0	6
23280	FLORENTINO AMEGHINO	3611	0	9
23281	ISLA CARAYA	3611	0	9
23282	LAS CORTADERAS	5249	0	6
23283	MONTE CLARO	3611	0	9
23284	SAN ANDRES	4111	0	24
23285	PIGO	3611	0	9
23286	LAS FLORES	5249	0	6
23287	PUERTO SAN CARLOS	3615	0	9
23288	PUNTA PORA	3611	0	9
23289	LAS GRAMILLAS	5246	0	6
23290	RODEO TAPITI	3611	0	9
23291	ROZADITO	3611	0	9
23292	LAS MERCEDES	5249	0	6
23293	SAN ANTONIO	3611	0	9
23294	TRES LAGUNAS	3620	0	9
23295	LAS TRANCAS	5246	0	6
23296	TTE CNEL GASPAR CAMPOS	3615	0	9
23297	VILLA HERMOSA	3615	0	9
23298	LO MACHADO	5246	0	6
23299	LOS CAJONES	5246	0	6
23300	LOS CERRILLOS	5246	0	6
23301	SANTA CLARA SUD	4168	0	24
23302	EL CASIAL	4137	0	24
23303	EL CASIALITO	4137	0	24
23304	EL CHORRO	4124	0	24
23305	EL INFIERNILLO	4137	0	24
23306	EL LAMEDERO	4137	0	24
23307	EL LAMPARAZO	4137	0	24
23308	EL MOLLE	4137	0	24
23309	EL MOLLE VIEJO	4137	0	24
23310	EL PAYANAL	4137	0	24
23311	LOS COCOS	5246	0	6
23313	LOS HOYOS	5249	0	6
23314	LOS JUSTES	5249	0	6
23315	TRISTAN NARVAJA	5149	0	6
23316	LOS POCITOS	5249	0	6
23317	EL PORTEZUELO	4117	0	24
23318	EL POTRERILLO	4137	0	24
23319	EL POZO	4137	0	24
23320	EL REMATE	4195	0	24
23321	EL TORO	4137	0	24
23322	ESCUELA 213	4137	0	24
23323	ESCUELA 217	4137	0	24
23324	ESCUELA 22	4137	0	24
23325	ESCUELA 23	4137	0	24
23326	ESCUELA 28	4137	0	24
23327	ESCUELA 325	4137	0	24
23328	ESCUELA 33	4137	0	24
23329	ESCUELA 336	4137	0	24
23330	ESCUELA 337	4137	0	24
23331	ESCUELA 338	4137	0	24
23332	SESTEADERO	4242	0	24
23333	ESCUELA 340	4137	0	24
23334	ESCUELA 342	4137	0	24
23335	ESCUELA 357	4137	0	24
23336	ESCUELA 37	4137	0	24
23337	ESCUELA 371	4137	0	24
23338	ABBURRA	5220	0	6
23339	ESCUELA 374	4137	0	24
23340	ESCUELA 379	4137	0	24
23341	SUNCHO PUNTA	4164	0	24
23342	ESCUELA 38	4137	0	24
23343	ESCUELA 390	4137	0	24
23344	ESCUELA 50	4137	0	24
23345	ESCUELA CNEL IGNACIO MURGA	4137	0	24
23346	ESCUELA GOB JOSE MANUEL SILVA	4137	0	24
23347	ESCUELA MANUELA PEDRAZA	4137	0	24
23348	ESPIADERO	4137	0	24
23349	ESQUINA DEL VALLE	4137	0	24
23350	FUERTE QUEMADO	4137	0	24
23351	IGLESIAS	4107	0	24
23352	KILOMETRO 1025	4137	0	24
23353	TALA SACHA	4176	0	24
23354	KILOMETRO 1041	4137	0	24
23355	KILOMETRO 118	4137	0	24
23356	LOS POZOS	5249	0	6
23357	KILOMETRO 52	4137	0	24
23358	KILOMETRO 62	4137	0	24
23359	LA BOLSA	4137	0	24
23360	LA COMBADA	4137	0	24
23361	LOS QUEBRACHOS	5246	0	6
23362	LA FALDA	4103	0	24
23363	LA MARAVILLA	4137	0	24
23364	TOSTADO	4242	0	24
23365	BARRIO 9 DE JULIO	4600	0	10
23366	LOS TAJAMARES	5233	0	6
23367	BARRIO ALTO LA VI	4600	0	10
23368	BARRIO BAJO LA VI	4600	0	10
23369	LOS TRONCOS	5246	0	6
23370	BARRIO ALTO LA LOMA	4600	0	10
23371	PASO DEL SILVERIO	5246	0	6
23372	BARRIO PARQUE 19 DE ABRIL	4600	0	10
23374	VILLA PUJIO	4176	0	24
23376	CERROS ZAPLA	4612	0	10
23377	POCITO DEL CAMPO	5248	0	6
23378	CHA	4616	0	10
23379	BARRIO CHIJRA	4600	0	10
23380	CHUQUINA	4600	0	10
23381	CORRAL DE PIEDRAS	4601	0	10
23382	EL ALGARROBAL	4600	0	10
23383	POZO DE JUANCHO	5246	0	6
23384	YUMILLURA	4242	0	24
23385	EL AMANCAY	4600	0	10
23386	EL ARENAL	4601	0	10
23388	EL CUCHO	4600	0	10
23389	EL REMATE	4612	0	10
23392	ITUAICOCHICO	4601	0	10
23393	POZO DE LAS OLLAS	5249	0	6
23394	JUAN GALAN	4600	0	10
23395	JUAN MANUEL DE ROSAS	4612	0	10
23396	LA ALMONA	4600	0	10
23397	POZO DE LOS ARBOLES	5249	0	6
23398	LA CUESTA	4600	0	10
23399	EL PABELLON	4137	0	24
23400	EL CHURQUI	4158	0	24
23401	LAGUNAS DE YALA	4616	0	10
23402	POZO DE MOLINA	5249	0	6
23403	LAS CAPILLAS	4600	0	10
23404	LAS ESCALERAS	4600	0	10
23405	EL DIVISADERO	4158	0	24
23406	POZO DEL SIMBOL	5249	0	6
23407	LAS HIGUERILLAS	4600	0	10
23408	LEON	4616	0	10
23409	EL LAMEDERO	4158	0	24
23410	LOS ALISOS	4600	0	10
23411	LOS BLANCOS	4600	0	10
23412	MINA 9 DE OCTUBRE	4612	0	10
23413	NAZARENO	4600	0	10
23414	ESCABA DE ABAJO	4158	0	24
23415	PALPALA	4612	0	10
23416	ESCABA DE ARRIBA	4158	0	24
23417	ESCUELA 138	4158	0	24
23418	ESCUELA 190	4158	0	24
23419	ESCUELA 26	4158	0	24
23420	ESCUELA 263	4158	0	24
23421	PASTOS CHICOS	4641	0	10
23422	ESCUELA 267	4158	0	24
23423	PAYO	4600	0	10
23424	ESCUELA 307	4158	0	24
23425	PUERTA DE SALAS	4612	0	10
23426	VILLA JARDIN DE REYES	4600	0	10
23427	ESCUELA 318	4158	0	24
23428	RIO BLANCO	4601	0	10
23429	ESCUELA 328	4158	0	24
23431	ESCUELA 352	4158	0	24
23433	ESCUELA 376	4158	0	24
23435	ESCUELA 69	4158	0	24
23436	SAN PABLO DE REYES	4600	0	10
23437	TESORERO	4600	0	10
23438	ZAPLA	4612	0	10
23439	ESCUELA V GENERALA	4158	0	24
23440	FUERTE ALTO	4158	0	24
23441	AGUA DE CASTILLA	4640	0	10
23442	PUESTO DE CASTRO	5233	0	6
23443	CHULIN O INCA NUEVA	4640	0	10
23444	LA CALERA	4158	0	24
23445	COCHAGATE	4640	0	10
23446	EL POTRERO DE LA PUNA	4641	0	10
23447	LA BANDA	4640	0	10
23448	LAS TABLITAS	4158	0	24
23449	LLAMERIA	4644	0	10
23450	PUESTO DE LOS ALAMOS	5249	0	6
23451	ANGOSTURA	3611	0	9
23452	MAYILTE	4644	0	10
23453	LOS ALAMITOS	4158	0	24
23454	MOCORAITE	4644	0	10
23455	PUESTO DE LUNA	5233	0	6
23456	BARRIO SAN MARTIN	3610	0	9
23457	PUNTA DE AGUA	4644	0	10
23458	QUEBRALE	4640	0	10
23459	BARRIO SUD AMERICA	3610	0	9
23460	QUENTI TACO	4644	0	10
23461	BOCARIN	3611	0	9
23462	PUNTA DEL MONTE	5249	0	6
23463	RAMALLO	4640	0	10
23465	RUTA NACIONAL 38	4158	0	24
23467	BRIGADIER GENERAL PUEYRREDON	3610	0	9
23469	RACEDO	5249	0	6
23471	RUTA PROVINCIAL 308	4158	0	24
23472	CEIBO TRECE	3610	0	9
23474	RAYO CORTADO	5246	0	6
23476	CURTIEMBRE CUE	3611	0	9
23478	SAN BERNARDO B	4000	0	24
23481	RIO DULCE	5249	0	6
23483	SORCUYO	4640	0	10
23484	RIO PEDRO	5246	0	6
23485	TUITE	4644	0	10
23486	UCUCHACRA	4158	0	24
23488	CADILLA	4608	0	10
23489	EL MOLLAR	4608	0	10
23490	ESTANCIA LAS HORQUETAS	3610	0	9
23491	ENTRE RIOS	4608	0	10
23492	FINCA LEACH	4504	0	10
23493	ISLA APANDO	3611	0	9
23494	RIO SAN MIGUEL	5249	0	6
23495	HORNILLOS	4608	0	10
23496	IRIARTE	4608	0	10
23497	JOSE CANCIO	3620	0	9
23498	LA OLLADA	4603	0	10
23499	LOMA HERMOSA	3610	0	9
23500	RIO VIEJO	5249	0	6
23501	LA UNION	4608	0	10
23502	LUCERO CUE	3611	0	9
23503	SAN BARTOLO	5249	0	6
23504	LAGUNILLA EL CARMEN	4608	0	10
23506	PERICO SAN JUAN	4603	0	10
23507	POZO DE LAS AVISPAS	4608	0	10
23508	PARQUE NACIONAL	3610	0	9
23512	PRESIDENTE AVELLANEDA	3611	0	9
23513	SAN IGNACIO	5248	0	6
23514	SAN GABRIEL	4608	0	10
23515	PRIMAVERA	3610	0	9
23516	SAN JUANCITO	5249	0	6
23517	SAN JUANCITO	4608	0	10
23518	CAMPO DE TALAMAYO	4158	0	24
23519	PUNTA GUIA	3610	0	9
23520	SAN RAFAEL	4608	0	10
23521	SANTA RITA	4608	0	10
23522	SAN MARTIN	5249	0	6
23523	RIACHO NEGRO	3610	0	9
23524	DIQUE ESCABA	4158	0	24
23525	VENECIAS ARGENTINAS	4608	0	10
23526	VILLA ARGENTINA	4608	0	10
23527	SAN PEDRO	5249	0	6
23528	SOL DE MAYO	3610	0	9
23529	SAN RAMON	5249	0	6
23530	TTE GRAL JUAN C SANCHEZ	3611	0	9
23531	LAS HIGUERILLAS	4144	0	24
23532	VIRASOL	3610	0	9
23533	ANTUMPA	4632	0	10
23534	BALLIAZO	4630	0	10
23535	SANTA CATALINA	5248	0	6
23536	CALETE	4630	0	10
23537	CAPLA	4626	0	10
23538	CASA GRANDE	4634	0	10
23539	CASAYOCK	4632	0	10
23540	CASILLA	4632	0	10
23541	CHORRILLOS	4630	0	10
23542	SANTA ELENA	5246	0	6
23544	ESQUINAS BLANCAS	4634	0	10
23545	GALETA	4630	0	10
23546	SANTA ISABEL	5249	0	6
23547	KILOMETRO 1289	4630	0	10
23548	VILLA ALBERDI ESTACION	4158	0	24
23549	KILOMETRO 1321	4634	0	10
23550	LA CUEVA	4632	0	10
23551	MOLINOS	4616	0	10
23552	SANTANILLA	5248	0	6
23553	PISUNGO	4632	0	10
23554	QUIMAZO	4630	0	10
23555	RIO GRANDE	4634	0	10
23556	TACO POZO	5249	0	6
23559	TAJAMARES	5233	0	6
23562	BATIRUANA	4162	0	24
23563	SAN ANDRES	4630	0	10
23564	VANGUARDIA	5246	0	6
23565	AGUASACHA	5221	0	6
23566	SAN PEDRO DE IRUYA	4633	0	10
23567	YANACATO	5248	0	6
23568	BOCA DE LA QUEBRADA	4162	0	24
23569	VICU	4634	0	10
23570	ALTO DE CASTILLO	5145	0	6
23571	VOLCAN HIGUERA	4633	0	10
23572	EL PROGRESO	5249	0	6
23573	YACORAITE	4634	0	10
23574	ANIMI	5107	0	6
23575	AGUA NEGRA	4512	0	10
23576	ALGARROBAL	4600	0	10
23577	ASCOCHINGA	5117	0	6
23578	ANIMAS	4512	0	10
23579	APAREJO	4512	0	10
23580	BATEAS	4512	0	10
23581	BELLA VISTA	4512	0	10
23582	AUGUSTO VANDERSANDE	5145	0	6
23583	CAMPO BAJO	4512	0	10
23584	BARRIO LOZA	5111	0	6
23585	LA MESADA	4137	0	24
23586	LA PUNTILLA	4137	0	24
23587	LA QUESERIA	4137	0	24
23588	LA SALA	4137	0	24
23589	LA SALAMANCA	4137	0	24
23590	LA SILLA	4137	0	24
23591	LA TRANCA	4137	0	24
23592	LA VI	4137	0	24
23593	LACAVERA	4103	0	24
23594	LAMPARCITO	4137	0	24
23595	LAS BOLSAS	4137	0	24
23596	LAS MELLIZAS	4107	0	24
23597	LOMA REDONDA	4137	0	24
23598	CAMPO COLORADO	4512	0	10
23599	CANDELARIA	4512	0	10
23600	CEVILAR	4512	0	10
23601	CHA	4516	0	10
23602	CHA	4516	0	10
23603	LOS POCITOS	4137	0	24
23604	CIENAGA	4512	0	10
23605	CORTADERAS	4512	0	10
23606	MACHO HUA	4137	0	24
23607	DON JORGE	4512	0	10
23608	EL COLCOLAR	4162	0	24
23609	MESADA DE ENCIMA	4137	0	24
23610	MOLLE DE ABAJO	4137	0	24
23611	MOLLE YACO	4137	0	24
23612	DURAZNAL	4512	0	10
23613	NOGALITA	4137	0	24
23614	EL AIBAL	4512	0	10
23615	EL DURAZNITO	4162	0	24
23616	PALO GACHO	4137	0	24
23617	EL BANANAL	4512	0	10
23618	PE	4137	0	24
23619	EL CAULARIO	4512	0	10
23620	PE	4137	0	24
23621	EL MANANTIAL	4512	0	10
23622	PIEDRA BLANCA	4119	0	24
23623	EL NARANJO	4512	0	10
23624	PIEDRAS BLANCAS	4137	0	24
23625	EL RIO NEGRO	4504	0	10
23626	PORT DE LAS ANIMAS	4137	0	24
23627	EL JARDIN	4162	0	24
23628	EL SAUCE	4512	0	10
23629	PORT DE TOMAS	4137	0	24
23630	ESQUINA	4512	0	10
23631	FALDA DEL QUEBRACHAL	4512	0	10
23632	PUERTA DE JULIPAO	4141	0	24
23633	FALDA MOJON	4512	0	10
23634	PUERTO COCHUCHO	4105	0	24
23635	PUESTO DE JULIPAO	4141	0	24
23636	FALDA MONTOSA	4512	0	10
23637	PUESTO DE ALUMBRE	4137	0	24
23638	EL PILA	4162	0	24
23639	PUESTO DE ZARZO	4137	0	24
23640	FINCA AGUA SALADA	4516	0	10
23641	PUESTO DE ENCALILLO	4137	0	24
23642	FINCA AGUA TAPADA	4516	0	10
23643	PUESTO LA RAMADITA	4135	0	24
23644	BELEN	5220	0	6
23645	PUESTO VIEJO	4137	0	24
23646	FINCA LA LUCRECIA	4516	0	10
23647	REARTE	4137	0	24
23648	FINCA LA REALIDAD	4516	0	10
23649	RINCON DE LAS TACANAS	4178	0	24
23650	RINCON DE QUILMES	4141	0	24
23651	FINCA SANTA CORNELIA	4516	0	10
23652	RIO BLANCO	4137	0	24
23653	BLAS DE ROSALES	5125	0	6
23654	FLORENCIA	4512	0	10
23656	ESCUELA 125	4162	0	24
23657	GUACHAN	4512	0	10
23659	ESCUELA 159	4162	0	24
23661	HIGUERITAS	4512	0	10
23662	ESCUELA 188	4162	0	24
23663	JARAMILLO	4504	0	10
23664	ESCUELA 24	4162	0	24
23665	LA CALERA	4512	0	10
23666	ESCUELA 244	4162	0	24
23667	LA PUERTA	4512	0	10
23668	ESCUELA 25	4162	0	24
23669	CAMPAMENTO MINNETTI	5149	0	6
23670	LAGUNILLA LEDESMA	4608	0	10
23671	ESCUELA 282	4162	0	24
23672	LAPACHAL LEDESMA	4501	0	10
23673	ESCUELA 294	4162	0	24
23674	LAS HIGUERITAS	4512	0	10
23675	LAS QUINTAS	4512	0	10
23676	LECHERIA	4514	0	10
23677	LEDESMA	4512	0	10
23678	ESCUELA 355	4162	0	24
23679	LOMA DEL MEDIO	4512	0	10
23680	ESCUELA 363	4162	0	24
23681	LOS BA	4516	0	10
23682	ESCUELA 73	4162	0	24
23683	CAMPO BOURDICHON	5149	0	6
23684	LOS CATRES	4512	0	10
23685	ESCUELA 89	4162	0	24
23686	LOTE PREDILIANA	4512	0	10
23687	LOTE ZORA	4504	0	10
23688	CA	5131	0	6
23689	MAL PASO	4512	0	10
23690	MARTA	4512	0	10
23691	ESCUELA JOAQUIN V GONZALEZ	4162	0	24
23692	MOJON AZUCENA	4512	0	10
23693	CANDONGA	5111	0	6
23694	MOLULAR	4512	0	10
23695	ESCUELA MARIO BRAVO	4162	0	24
23696	NARANJITO	4512	0	10
23697	PALO A PIQUE	4512	0	10
23698	CANTERAS EL MANZANO	5107	0	6
23699	PAMPA LARGA	4512	0	10
23700	PAULETE	4512	0	10
23701	ESCUELA OLEGARIO ANDRADE	4162	0	24
23702	PAULINA	4512	0	10
23703	PIEDRA BLANCA	4512	0	10
23704	ESCUELA PEDRO MEDRANO	4162	0	24
23705	CANTERAS LA CALERA	5151	0	6
23706	CAROYA	5223	0	6
23707	HUACRA	4162	0	24
23708	POSTA GDAPARQUE NAC CALILEGUA	4514	0	10
23709	CASA BAMBA	5151	0	6
23710	POTRERO	4640	0	10
23711	POTRERO ALEGRE	4512	0	10
23712	COLONIA HOLANDESA	5131	0	6
23713	POZO CAVADO	4512	0	10
23714	HUASA PAMPA SUR	4162	0	24
23715	POZO VERDE	4512	0	10
23716	COLONIA TIROLESA	5101	0	6
23717	PREDILIANA	4512	0	10
23718	PUEBLO NUEVO	4512	0	10
23719	PUERTA VIEJA	4512	0	10
23720	RAMADA	4512	0	10
23721	RASTROJOS	4504	0	10
23722	RIO SECO	4512	0	10
23728	COLONIA VICENTE AGUERO	5221	0	6
23729	SALADILLO LEDESMA	4522	0	10
23730	SAN ANTONIO	4503	0	10
23732	SAN LORENZO	4514	0	10
23733	COLUMBO	5220	0	6
23734	SANTILLO	4512	0	10
23735	SAUZAL	4501	0	10
23736	LOS BATEONES	4137	0	24
23738	SAUZALITO	4512	0	10
23739	SEPULTURA	4512	0	10
23740	TERCER CUERPO DEL EJERCITO	5101	0	6
23741	SOCABON	4512	0	10
23742	SOLEDAD	4512	0	10
23743	TARIJITA	4512	0	10
23744	TOBA	4606	0	10
23745	TOQUILLERA	4512	0	10
23746	DOLORES NU	5131	0	6
23747	TREMENTINAL	4512	0	10
23748	TUCUMANCITO	4512	0	10
23749	YERBA BUENA LEDESMA	4622	0	10
23750	EL ALGODONAL	5107	0	6
23751	OBRAJE SAN JOSE	4516	0	10
23753	EL ESPINILLO	5131	0	6
23754	EL GATEADO	5101	0	6
23755	EL MOLINO	5220	0	6
23756	SAN JOSE DE LA RINCONADA	4643	0	10
23757	EL PASTOR	5151	0	6
23758	ANTIGUYOS	4643	0	10
23759	EL PAYADOR	5151	0	6
23760	KILOMETRO 1402	4162	0	24
23761	EL QUEBRACHITO	5109	0	6
23762	BAJO DE GOMEZ	5961	0	6
23763	KILOMETRO 1412	4162	0	24
23764	EL REYMUNDO	5220	0	6
23765	KILOMETRO 1438	4162	0	24
23766	BAJO GALINDEZ	5961	0	6
23767	KILOMETRO 19	4162	0	24
23768	EL TALAR	5107	0	6
23769	CAMPO AMBROGGIO	5915	0	6
23770	EL TOMILLO	5149	0	6
23771	CA	5963	0	6
23772	LA HUERTA	4162	0	24
23773	EL ZAINO	5149	0	6
23774	CAPILLA DEL CARMEN	5963	0	6
23775	CERRO REDONDO	4643	0	10
23776	ESPINILLO NU	5131	0	6
23777	CINCEL	4643	0	10
23778	COLONIA VIDELA	5865	0	6
23779	FARILLON	4643	0	10
23780	LA LAGUNITA	4137	0	24
23781	GRANADAS	4643	0	10
23782	COSTA ALEGRE	5963	0	6
23783	ESTACION CAROYA	5220	0	6
23784	LA VETA	4643	0	10
23785	LAGUNILLAS	4640	0	10
23786	EL CARRIZAL	5963	0	6
23787	ESTACION COLONIA TIROLESA	5131	0	6
23788	MINA AJEDREZ	4643	0	10
23789	MINIAIO	4643	0	10
23790	EL CARRILITO	5963	0	6
23791	PE	4632	0	10
23792	QUERA	4643	0	10
23793	ESTANCIA EL CARMEN	5131	0	6
23796	ESTACION CALCHIN	5969	0	6
23797	ESTANCIA LAS CA	5131	0	6
23801	ESTANCIA LOS MATORRALES	5987	0	6
23802	GENERAL ORTIZ DE OCAMPO	5151	0	6
23803	SALITRE	4643	0	10
23804	LOA DIAZ	4162	0	24
23805	TIO MAYO	4643	0	10
23806	GALPON CHICO	5967	0	6
23807	HIGUERIAS	5131	0	6
23808	ALISOS DE ARRIBA	4605	0	10
23809	ATALAYA	4600	0	10
23810	EL OLLERO	4605	0	10
23811	LA BLANCA	3606	0	9
23812	IMPIRA	5987	0	6
23813	RIO BLANCO	4605	0	10
23814	9 DE JULIO	3606	0	9
23816	INDEPENDENCIA	5988	0	6
23817	EST JUAREZ CELMAN	5145	0	6
23818	KILOMETRO 25	5107	0	6
23819	AGENTE ARGENTINO ALEGRE	3608	0	9
23820	LA ISLETA	5963	0	6
23821	BARRIO LA PROVIDENCIA	4500	0	10
23822	PONZACON	4162	0	24
23823	BALLON	3620	0	9
23824	EL ACHERAL	4500	0	10
23825	EL BA	3606	0	9
23826	ENSENADA	4500	0	10
23827	POTRERILLOS	4162	0	24
23828	ESQUINA DE QUISTO	4500	0	10
23829	LA PALMERINA	5913	0	6
23830	INGENIO LA ESPERANZA	4503	0	10
23831	MORALITO	4500	0	10
23832	LA ZARA	5913	0	6
23833	RIO GRANDE	4522	0	10
23834	CABO NORO	3606	0	9
23836	COLONIA HARDY	3606	0	9
23838	CAMPO RIGONATO	3606	0	9
23840	CASCO CUE	3606	0	9
23841	LA ZARITA	5913	0	6
23842	COLONIA 5 DE OCTUBRE	3606	0	9
23843	ABRA DEL TRIGO	4501	0	10
23844	COLONIA CORONEL DORREGO	3620	0	9
23846	PUESTO LOS ROBLES	4162	0	24
23847	LAGUNA LARGA SUD	5988	0	6
23848	AGUAS BLANCAS	4501	0	10
23849	COLONIA EL ALBA	3606	0	9
23850	ARROYO DEL MEDIO	4501	0	10
23851	BELLA VISTA	4501	0	10
23852	KILOMETRO 711	5125	0	6
23853	CACHI PUNCO	4501	0	10
23854	LAGUNILLA	5972	0	6
23855	COLONIA EL OLVIDO	3606	0	9
23856	COLONIA EL ZAPALLITO	3606	0	9
23857	QUEBRACHITO	4242	0	24
23858	KILOMETRO 745	5220	0	6
23859	COLONIA LA DISCIPLINA	3606	0	9
23860	COLONIA PALMAR GRANDE	3606	0	9
23861	COLONIA SABINA	3606	0	9
23862	RUTA NACIONAL 38	4162	0	24
23863	RUTA NACIONAL 64	4162	0	24
23864	RUTA PROVINCIAL 334	4162	0	24
23865	CMTE PRINCIPAL ISMAEL ST	3628	0	9
23866	LA COTITA	5220	0	6
23867	CORONEL JOSE I WARNES	3606	0	9
23868	COSTA SALADO	3606	0	9
23869	LA ESTANCITA	5111	0	6
23870	19 DE MARZO	3630	0	9
23871	EL ALGARROBO	3606	0	9
23872	LA QUEBRADA	5107	0	6
23873	EL GUAJHO	3606	0	9
23874	EL PALMAR	3606	0	9
23875	EL POI	3606	0	9
23876	LA REDENCION	5105	0	6
23877	SAN JOSE DE LA COCHA	4163	0	24
23878	EL QUEBRANTO	3606	0	9
23879	EL MISTOL	4501	0	10
23880	EL OLVIDO	4501	0	10
23881	EL RESGUARDO	3606	0	9
23882	EL SUNCHAL	4501	0	10
23883	LA REDUCCION	5105	0	6
23884	ESTANCIA EL CIERVO	3606	0	9
23885	ESTERO GRANDE	3608	0	9
23886	LA TUNA TINOCO	5131	0	6
23887	EL TIPAL	4501	0	10
23888	ESTERO PATI	3608	0	9
23889	GOBERNADOR OVEJERO	4501	0	10
23890	FORTIN FONTANA	3620	0	9
23891	LA OLLADA	4501	0	10
23892	TALITA POZO	4119	0	24
23893	LA QUINTA	4501	0	10
23894	GENDARME VIVIANO GARCETE	3606	0	9
23895	LA RONDA	4501	0	10
23896	LA VERTIENTE	4501	0	10
23897	TATA YACU	4162	0	24
23898	GENERAL PABLO RICCHIERI	3603	0	9
23899	LAGUNA SAN MIGUEL	4501	0	10
23900	LAGUNA TOTORILLAS	4501	0	10
23901	LA VIRGINIA	5220	0	6
23902	HIPOLITO VIEYTES	3603	0	9
23903	YANIMA	4158	0	24
23904	ISLA TOLDO	3606	0	9
23905	LAPACHAL SANTA BARBARA	4501	0	10
23906	LAS ASTILLAS	5220	0	6
23907	LOMA PELADA	4501	0	10
23908	JOSE HERNANDEZ	3606	0	9
23909	LOS MATOS	4501	0	10
23910	MILAN	4501	0	10
23911	KILOMETRO 109	3606	0	9
23912	PIE DE LA CUESTA	4501	0	10
23913	LAS CA	5101	0	6
23914	PUNTA DEL AGUA	4644	0	10
23915	KILOMETRO 193	3603	0	9
23918	SANTA RITA	4501	0	10
23919	KILOMETRO 213	3603	0	9
23920	CALAHOYO	4655	0	10
23921	KILOMETRO 224	3621	0	9
23922	CANCHUELA	4655	0	10
23923	CORRAL BLANCO	4655	0	10
23924	GUAYATAYOC	4653	0	10
23925	LA CIENAGA	4618	0	10
23926	KILOMETRO 254	3511	0	9
23927	MERCO	4655	0	10
23928	LA SIRENA	3606	0	9
23929	MINAS AZULES	4655	0	10
23930	LAGUNA MURUA	3608	0	9
23931	MIRES	4655	0	10
23932	MORRO	4655	0	10
23933	ORNILLO	4653	0	10
23934	LOMA SENES	3606	0	9
23935	PE	4655	0	10
23936	POTRERO	4653	0	10
23938	COLONIA CAMPO VILLAFA	3601	0	9
23940	NICORA	3620	0	9
23943	NUEVA ITALIA	3620	0	9
23944	SAN JUAN	4655	0	10
23946	SAN JUAN DE OROS	4655	0	10
23947	TIO MAYO	4653	0	10
23948	PALMAR CHICO	3606	0	9
23949	CAUCHARI	4641	0	10
23950	EL PORVENIR	4641	0	10
23951	PILAGA III	3606	0	9
23952	OLACAPATO	4643	0	10
23953	RINCON 	3606	0	9
23954	SALADILLO	3620	0	9
23955	KILOMETRO 1369	4641	0	10
23956	SALADO	3620	0	9
23957	OLAROZ GRANDE	4641	0	10
23958	SAN JACINTO	3606	0	9
23959	PAIRIQUE CHICO	4643	0	10
23961	PAIRIQUE GRANDE	4643	0	10
23963	VILLA MERCEDES	3624	0	9
23965	YUNCA	3620	0	9
23967	SIJES	4641	0	10
23968	ZORRILLA CUE	3606	0	9
23969	SOYSOLAYTE	4643	0	10
23970	COSTA RIO NEGRO	3603	0	9
23971	TANQUES	4641	0	10
23972	TOCOL	4643	0	10
23973	TURILARI	4641	0	10
23974	TURU TARI	4641	0	10
23975	ANGOSTO DEL PERCHEL	4626	0	10
23976	BELLA VISTA	4622	0	10
23977	CACHIHUAICO	4622	0	10
23978	CA	4624	0	10
23979	EL CALLEJON	4622	0	10
23981	LAS CHICAPENAS	4622	0	10
23982	PUESTO	4624	0	10
23983	PUNTA DEL CAMPO	4622	0	10
23985	TACTA	4622	0	10
23986	YERBA BUENA TILCARA	4622	0	10
23987	ABRA DE PIVES	4618	0	10
23988	ACHACAMAYOC	4618	0	10
23989	AGUA BENDITA	4618	0	10
23990	AGUA CHICA	4640	0	10
23991	AGUA PALOMAR	4618	0	10
23992	ALTO DE CASA	4618	0	10
23993	ALTO DE LOZANO	4618	0	10
23994	ALTO DE MOJON	4618	0	10
23995	ALTO DEL ANGOSTO	4618	0	10
23996	ALTO DEL SALADILLO	4522	0	10
23997	ALTO HUANCAR	4618	0	10
23998	ALTO MINERO	4618	0	10
23999	ALTO POTRERILLO	4618	0	10
24000	ALTO QUEMADO	4618	0	10
24001	ALTO QUIRQUINCHO	4618	0	10
24002	BOLETERIA	4618	0	10
24003	CAMPO OCULTO	4618	0	10
24004	CANCHAHUASI	4618	0	10
24005	CAPACHACRA	4618	0	10
24006	CARCEL	4618	0	10
24007	CASA NEGRA	4618	0	10
24008	CASA VIEJA	4618	0	10
24009	CHA	4618	0	10
24010	CHA	4618	0	10
24011	CHILCAR	4618	0	10
24012	CHORRILLO	4618	0	10
24013	CIENAGA GRANDE	4643	0	10
24014	COIRURO	4618	0	10
24015	CONDOR	4618	0	10
24016	CORTADERAS	4618	0	10
24017	COSTILLAR	4618	0	10
24018	CRUZ NIDO	4618	0	10
24019	EL COLORADO	4618	0	10
24020	EL MOLINO	4618	0	10
24021	EL MORRO	4618	0	10
24022	ENCRUCIJADA	4618	0	10
24023	ESQUINA DE HUANCAR	4618	0	10
24024	ESQUINA GRANDE	4618	0	10
24025	ESTANCIA GRANDE	4618	0	10
24026	HIGUERITAS	4618	0	10
24027	HUANCAR	4618	0	10
24028	INCA HUASI	4618	0	10
24029	LA PUERTA	4618	0	10
24030	LAGUNAS	4618	0	10
24031	LINDERO	4618	0	10
24032	LIPAN	4618	0	10
24033	LOMA LARGA	4618	0	10
24034	MINAS DE BORATO	4618	0	10
24035	MOLLI PUNCO	4618	0	10
24037	MORENO CHICO	4618	0	10
24038	MORRITO	4618	0	10
24039	PIEDRA CHOTA	4618	0	10
24040	PIEDRAS AMONTONADAS	4618	0	10
24041	PIEDRAS BLANCAS	4618	0	10
24042	PORVENIR	4618	0	10
24043	POSTA DE HORNILLOS	4622	0	10
24044	POZO BRAVO	4618	0	10
24045	POZO COLORADO	4618	0	10
24046	PUEBLO PLA	4618	0	10
24047	PUERTA DE COLORADOS	4618	0	10
24048	PUERTA PATACAL	4618	0	10
24049	PUNTA CANAL	4618	0	10
24050	PUNTAS DE COLORADOS	4618	0	10
24051	QUISQUINE	4618	0	10
24052	RECEPTORIA	4618	0	10
24053	RIVERITO	4618	0	10
24058	SALA	4618	0	10
24059	SAN JAVIER	4618	0	10
24060	SANTA ROSA TUMBAYA	4618	0	10
24061	SUSUYACO	4618	0	10
24062	TALA GRUSA	4618	0	10
24063	TOTORITO	4618	0	10
24064	TRIUNVIRATO	4618	0	10
24065	TUMBAYA GRANDE	4618	0	10
24066	ANTIGUO	4631	0	10
24067	CHILCAR	4631	0	10
24068	CORTADERAS	4631	0	10
24069	FUNDICIONES	4513	0	10
24070	GOBERNADOR TELLO	4513	0	10
24071	PISCUNO	4651	0	10
24072	POTRERILLO	4631	0	10
24073	PUERTO TOLAVA	4513	0	10
24074	RAMADA	4631	0	10
24076	SANTA CLARA	4513	0	10
24077	SANTA ROSA VALLE GRANDE	4618	0	10
24078	SOLEDAD	4631	0	10
24079	TABLON	4631	0	10
24080	TORO MUERTO	4631	0	10
24081	TRANCAS	4631	0	10
24082	VIZACACHAL	4631	0	10
24084	CAJAS	4651	0	10
24085	CERRILLOS	4653	0	10
24086	CONDOR	4630	0	10
24087	CORRAL BLANCO	4655	0	10
24088	CORRALITO	4650	0	10
24089	KILOMETRO 1397	4644	0	10
24090	LA INTERMEDIA	4650	0	10
24091	MINA SOL DE MAYO	4644	0	10
24092	MULLI PUNCO	4650	0	10
24093	RODEO	4651	0	10
24098	SAN SIMON	3606	0	9
24099	SAN CARLITOS	4137	0	24
24100	SAN FRANCISCO	4137	0	24
24101	TORO YACO	4137	0	24
24102	YACO	4122	0	24
24103	LOS CHA	5125	0	6
24104	LOS PANTANILLOS	5125	0	6
24105	MONTE REDONDO	5963	0	6
24106	ORATORIO DE PERALTA	5125	0	6
24108	LAS CHACRAS RUTA 111 KILOMETRO	5101	0	6
24109	PALO NEGRO	5961	0	6
24110	EL ALAMBRADO	3636	0	9
24111	EL DESMONTE	3636	0	9
24112	EL ROSADO	3636	0	9
24113	MEDIA LUNA	3636	0	9
24114	MISTOL MARCADO	3636	0	9
24115	PASO DE VELEZ	5972	0	6
24116	PALMAR LARGO	3636	0	9
24117	ANGOSTURA	4124	0	24
24118	PALMARCITO	3636	0	9
24119	BAJO DE RACO	4103	0	24
24120	EL CADILLAL	4103	0	24
24121	PLAZA MINETTI	5967	0	6
24122	POZO DE LOS CHANCHOS	3636	0	9
24123	EL PELADO	4103	0	24
24124	SAN ISIDRO	3636	0	9
24125	ESCUELA 107	4101	0	24
24126	PLAZA RODRIGUEZ	5987	0	6
24127	ESCUELA 163	4101	0	24
24128	ESCUELA 164	4101	0	24
24129	POZO DE LAS YEGUAS	5125	0	6
24130	ESCUELA 210	4101	0	24
24131	LAS CUSENADAS	5109	0	6
24132	ESCUELA 215	4101	0	24
24133	ESCUELA 218	4101	0	24
24134	RINCON	5961	0	6
24135	ESCUELA 219	4101	0	24
24136	ESCUELA 256	4101	0	24
24137	ESCUELA 299	4101	0	24
24138	LAS ENCADENADAS	5109	0	6
24139	ESCUELA 300 LA PICADA	4101	0	24
24140	ESCUELA 350	4101	0	24
24141	ESCUELA 393	4101	0	24
24142	RINCON CASA GRANDE	5162	0	6
24143	ESCUELA 48	4101	0	24
24144	ESCUELA 59	4101	0	24
24145	SAN JERONIMO	5963	0	6
24146	ESCUELA 70	4101	0	24
24147	LAS VERTIENTES DE LA GRANJA	5107	0	6
24148	ESCUELA CAPITAN GASPAR DE MEDI	4101	0	24
24149	ESCUELA EE UU	4101	0	24
24150	SAN JOSE	5961	0	6
24151	LOS CALLEJONES	5220	0	6
24152	ESCUELA FORTUNATA GARCIA	4101	0	24
24153	ESCUELA MIGUEL AZCUENAGA	4101	0	24
24154	SAN RAFAEL	5960	0	6
24155	ESCUELA MIGUEL CERVANTES	4101	0	24
24156	LOS CHA	5220	0	6
24157	ESCUELA RAMON CARRILLO	4101	0	24
24158	TRES POZOS	5972	0	6
24159	ESCUELA 255	4101	0	24
24160	LOS CIGARRALES	5107	0	6
24161	VILLA MU	4000	0	24
24162	GRAL ANSELMO ROJO	4103	0	24
24163	KILOMETRO 925	4103	0	24
24164	LA BANDA	4124	0	24
24165	LOS POCITOS	5145	0	6
24166	LA HOYADA	4105	0	24
24167	LA MANGA	4103	0	24
24168	LA RAMADA	4103	0	24
24169	LA SALA	4119	0	24
24170	LAGUNA GRANDE	4103	0	24
24171	LOS QUEBRACHITOS	5221	0	6
24172	LAS CA	4103	0	24
24173	LOS VAZQUEZ	5125	0	6
24174	MEDIA LUNA	5125	0	6
24175	MULA MUERTA	5221	0	6
24176	NINTES	5220	0	6
24177		5111	0	6
24178	NU	5131	0	6
24179	OJO DE AGUA	5220	0	6
24180	PAJAS BLANCAS	5111	0	6
24181	PASO CASTELLANOS	5145	0	6
24182	POZO DEL TIGRE	5145	0	6
24183	PUESTO DE LA OVEJA	5131	0	6
24184	RIO CHICO	5221	0	6
24185	RUTA 111 KILOMETRO 14	5101	0	6
24186	RUTA 19 KILOMETRO 317	5125	0	6
24187	SAN CRISTOBAL	5107	0	6
24188	ALGARROBAL	5885	0	6
24189	ALTAUTINA	5871	0	6
24190	ALTO GRANDE	5893	0	6
24191	AMBUL	5299	0	6
24192	SAN ISIDRO	5220	0	6
24193	ARROYO	5297	0	6
24194	SAN PABLO	5220	0	6
24195	ARROYO LA HIGUERA	5889	0	6
24196	SANTA ELENA	5131	0	6
24197	ARROYO LOS PATOS	5889	0	6
24198	SANTA TERESA	5221	0	6
24199	BAJO EL MOLINO	5887	0	6
24200	LOS ZARAGOZA	4103	0	24
24201	SANTO TOMAS	5220	0	6
24202	LUZ Y FUERZA	4103	0	24
24203	BALDE DE LA MORA	5871	0	6
24204	PORTEZUELO	4117	0	24
24205	TEJEDA	5125	0	6
24206	PUESTO CIENAGA AMARILLA	4103	0	24
24207	BALDE LINDO	5871	0	6
24212	BA	5871	0	6
24213	TINOCO	5131	0	6
24215	SANTA LUCIA	4135	0	24
24216	BUENA VISTA	5297	0	6
24217	SAUCE YACO	4162	0	24
24218	TRONCO POZO	5223	0	6
24221	CA	5297	0	6
24222	VALLE VERDE	5115	0	6
24223	CA	5891	0	6
24224	VILLA DEL LAGO	5152	0	6
24225	CA	5889	0	6
24226	CARRIZAL	5299	0	6
24227	VILLA DIAZ	5109	0	6
24228	CASA DE PIEDRA	5891	0	6
24229	VILLA LEONOR	5109	0	6
24230	VILLA LOS ALTOS	5111	0	6
24231	MONASTERIO	4103	0	24
24232	VILLA MARIA	5220	0	6
24233	CERRO NEGRO	5297	0	6
24234	VILLA SAN MIGUEL	5111	0	6
24235	CHUA	5871	0	6
24237	CIENAGA DE ALLENDE	5891	0	6
24238	VILLA TORTOSA	5109	0	6
24239	ABRA RICA	4178	0	24
24240	LOS DOS RIOS	5220	0	6
24241	COMECHINGONES	5153	0	6
24242	LOS DURAZNOS	5220	0	6
24243	CONCEPCION	5871	0	6
24244	AGUA AZUL	4115	0	24
24245	CONDOR HUASI	5871	0	6
24246	VALLE DEL SOL	5107	0	6
24247	DOS RIOS	5297	0	6
24248	VILLA LAS MERCEDES	5107	0	6
24249	AGUA DULCE	4168	0	24
24250	CALERA CENTRAL	5151	0	6
24251	EL ALGADOBAL	5885	0	6
24252	EL ALTO	5887	0	6
24254	AGUA SALADA	4168	0	24
24255	EL BAJO	5889	0	6
24256	EL BORDO	5871	0	6
24257	EL CORTE	5889	0	6
24258	EL MIRADOR	5891	0	6
24259	EL PANTANILLO	5885	0	6
24260	ANEGADOS	4168	0	24
24261	PIEDRA BLANCA	5285	0	6
24262	EL PASO DE LA PAMPA	5871	0	6
24263	ARAOZ	4178	0	24
24264	EL PERCHEL	5885	0	6
24265	EL SAUZAL	5887	0	6
24266	EL TAJAMAR	5885	0	6
24267	HUCLE	5887	0	6
24268	ISLA VERDE	5893	0	6
24269	JUAN BAUTISTA ALBERDI	5891	0	6
24270	BILCA POZO	4111	0	24
24271	LA AGUADITA	5887	0	6
24272	LA COCHA	5893	0	6
24273	BUENA VISTA OESTE	4168	0	24
24274	ABRA EL CANDADO	4124	0	24
24275	AGUA EL SIMBO	4124	0	24
24276	AGUADA DE JORGE	4124	0	24
24277	ALIZAL	4122	0	24
24278	ALTO DE LA ANGOSTURA	4124	0	24
24279	LA COMPASION	5871	0	6
24280	ALTO DE LOS GIMENEZ	4124	0	24
24281	CACHI HUASI	4113	0	24
24282	ALTO LA TOTORA	4124	0	24
24283	ALURRALDE	4122	0	24
24284	ANTA	4434	0	24
24285	ARAGON	4122	0	24
24286	CACHI YACO	4178	0	24
24287	BOBA YACU	4124	0	24
24288	LA CONCEPCION	5870	0	6
24289	CACHI YACO	4124	0	24
24290	CAMPO REDONDO	4124	0	24
24291	CAPILLA	4124	0	24
24292	CASAS VIEJAS	4124	0	24
24293	LA CORTADERA	5871	0	6
24294	CERVALITO	4124	0	24
24295	CRIOLLAS	4122	0	24
24296	CACHI YACO APEADERO FCGB	4113	0	24
24297	LA COSTA	5885	0	6
24298	EL ALPIZAR	4124	0	24
24299	EL ARENAL	4124	0	24
24300	EL ASERRADERO	4117	0	24
24301	EL BOYERO	4124	0	24
24302	LA GUARDIA	5891	0	6
24303	EL BRETE	4126	0	24
24304	EL CADILLAL	4124	0	24
24305	EL JUNQUILLAR	4124	0	24
24306	EL MILAGRO	4124	0	24
24307	LA LINEA	5871	0	6
24308	EL MOLINO	4124	0	24
24309	EL MOLLAR	4124	0	24
24310	LA MAJADA	5887	0	6
24311	EL PELADO	4124	0	24
24312	CACHIYACO	4168	0	24
24313	EL PELADO DE PARANILLO	4124	0	24
24314	EL PORVENIR	4124	0	24
24315	LA QUEBRADA	5297	0	6
24316	CAMAS AMONTONADAS	4115	0	24
24317	LA QUINTA	5887	0	6
24318	CAMPANA	4111	0	24
24319	CAMPO AZUL	4115	0	24
24320	LA TRAMPA	5871	0	6
24321	CAMPO EL LUISITO	4178	0	24
24322	LAS CALLES	5885	0	6
24323	LAS CEBOLLAS	5885	0	6
24324	CAMPO EL MOLLAR	4178	0	24
24325	LAS CONANITAS	5885	0	6
24327	CA	4178	0	24
24328	CA	4124	0	24
24329	LAS ENSENADAS	5153	0	6
24330	CANDELILLAL	4111	0	24
24332	LAS PALMITAS	5889	0	6
24333	CARANCHO POZO	4168	0	24
24334	LAS RABONAS	5885	0	6
24336	CEVILARCITO	4111	0	24
24337	LAS TOSCAS	5871	0	6
24339	LOS ALGARROBOS	5887	0	6
24340	CHA	4168	0	24
24341	CHA	4168	0	24
24342	LOS CALLEJONES	5871	0	6
24344	CHA	4168	0	24
24345	LOS HUESOS	5153	0	6
24347	LOS MOLLES	5887	0	6
24349	MESILLAS	5153	0	6
24351	MINA ARAUJO	5297	0	6
24353	CHILCAL	4111	0	24
24354	MONTE REDONDO	5889	0	6
24355	MUSSI	5299	0	6
24356	NIDO DEL AGUILA	5889	0	6
24357	NI	5889	0	6
24358	COLONIA SOBRECASA	4168	0	24
24359	OJO DE AGUA	5887	0	6
24360	PACHANGO	5893	0	6
24361	AGUA DE CRESPIN	5285	0	6
24362	PAMPA DE ACHALA	5153	0	6
24363	ALTO DE LOS QUEBRACHOS	5281	0	6
24364	BAJO LINDO	5270	0	6
24365	BA	5285	0	6
24366	EL AGUILAR	4168	0	24
24367	BARRIALITOS	5284	0	6
24368	PANAHOLMA	5893	0	6
24369	EL ATACAT	4168	0	24
24370	PASO LAS TROPAS	5887	0	6
24371	BELLA VISTA	5284	0	6
24372	EL BAGUAL	4178	0	24
24373	CACHIYULLO	5284	0	6
24374	POZO DE LA PAMPA	5871	0	6
24375	PUERTA DE LA QUEBRADA	5297	0	6
24376	CA	5280	0	6
24377	PUESTO GUZMAN	5153	0	6
24378	CANTERAS QUILPO	5281	0	6
24379	QUEBRACHO SOLO	5871	0	6
24380	EL CASTORAL	4168	0	24
24381	CANTERAS IGUAZU	5285	0	6
24382	QUEBRADA DEL HORNO	5889	0	6
24383	EL CEIBAL	4168	0	24
24384	CANDELARIA	5287	0	6
24385	RIO ARRIBA	5887	0	6
24386	CARRIZAL	5285	0	6
24387	SAN LORENZO	5893	0	6
24388	SAN RAFAEL	5871	0	6
24389	CASAS VIEJAS	5285	0	6
24390	CHACRAS	5284	0	6
24391	SAN SEBASTIAN	5889	0	6
24392	SAN VICENTE	5871	0	6
24393	CHACRAS DEL POTRERO	5284	0	6
24394	SANTA RITA	5893	0	6
24395	CHARACATO	5287	0	6
24396	SANTO DOMINGO	5871	0	6
24397	DESAGUADERO	5284	0	6
24398	TARUCA PAMPA	5299	0	6
24399	TASMA	5893	0	6
24400	EL BARRIAL	5285	0	6
24401	EL CALLEJON	5172	0	6
24402	VILLA ANGELICA	5885	0	6
24403	EL CARACOL	5284	0	6
24404	VILLA CLODOMIRA	5885	0	6
24405	EL FRANCES	5282	0	6
24406	VILLA RAFAEL BENEGAS	5885	0	6
24407	EL GUAICO	5285	0	6
24408	ARCOYO	5297	0	6
24409	ESCUELA 1	4168	0	24
24410	EL PUESTO	5284	0	6
24411	PIEDRA BLANCA	5887	0	6
24412	ESCUELA 102	4168	0	24
24413	ESCUELA 103	4168	0	24
24414	ESCUELA 104	4168	0	24
24415	EL QUICHO	5270	0	6
24416	SANTA MARIA	5889	0	6
24417	ESCUELA 105	4168	0	24
24418	ESCUELA 11	4168	0	24
24419	ESCUELA 114	4168	0	24
24420	EL RINCON	5282	0	6
24421	ESCUELA 122	4168	0	24
24422	EL SIMBOLAR	5281	0	6
24423	EL VALLECITO	5172	0	6
24424	ESCUELA 132	4168	0	24
24425	ESCUELA 145	4168	0	24
24426	ESQUINA DEL ALAMBRE	5281	0	6
24427	ESCUELA 146	4168	0	24
24428	ESCUELA 147	4168	0	24
24429	ESCUELA 153	4168	0	24
24430	ESCUELA 156	4168	0	24
24431	ESTACION SOTO	5284	0	6
24432	ESCUELA 157	4168	0	24
24433	ESCUELA 174	4168	0	24
24434	ESCUELA 175	4168	0	24
24435	GUANACO MUERTO	5281	0	6
24436	ESCUELA 185	4168	0	24
24437	ESCUELA 192	4168	0	24
24438	HUASCHA	5218	0	6
24439	ESCUELA 194	4168	0	24
24440	ESCUELA 195	4168	0	24
24441	ESCUELA 1 JUNTA	4168	0	24
24442	IGLESIA VIEJA	5270	0	6
24443	ESCUELA 207	4168	0	24
24444	ESCUELA 209	4168	0	24
24445	KILOMETRO 505	5280	0	6
24446	ESCUELA 224	4168	0	24
24447	EL POTRERO	4124	0	24
24448	ESCUELA 226	4168	0	24
24449	EL POZO	4124	0	24
24450	EL PUESTITO	4124	0	24
24451	ESCUELA 227	4168	0	24
24452	EL SUNCAL	4124	0	24
24453	KILOMETRO 541	5284	0	6
24454	EL TALAR	4124	0	24
24455	ESCUELA 229	4168	0	24
24456	EL ZAUZAL	4124	0	24
24457	ESCUELA 231	4168	0	24
24458	ESCUELA 128	4124	0	24
24459	ESCUELA 232	4168	0	24
24460	LA ABRA	5281	0	6
24461	ESCUELA 170	4124	0	24
24462	ESCUELA 235	4168	0	24
24463	ESCUELA 171	4124	0	24
24464	ESCUELA 204	4124	0	24
24465	ESCUELA 238	4168	0	24
24466	ESCUELA 214	4124	0	24
24467	ESCUELA 221	4124	0	24
24468	ESCUELA 25 DE MAYO	4168	0	24
24469	LA AGUADA	5285	0	6
24470	ESCUELA 233	4124	0	24
24471	ESCUELA 27	4168	0	24
24472	ESCUELA 265	4124	0	24
24473	ESCUELA 272	4168	0	24
24474	ESCUELA 309	4124	0	24
24475	LA BATEA	5270	0	6
24476	ESCUELA 273	4168	0	24
24477	ESCUELA 293	4168	0	24
24478	ESCUELA 31	4124	0	24
24479	ESCUELA 341	4124	0	24
24480	ESCUELA 323	4168	0	24
24481	LA CARBONERA	5280	0	6
24482	ESCUELA 349	4124	0	24
24483	ESCUELA 354	4168	0	24
24484	ESCUELA 356	4124	0	24
24485	ESCUELA 364	4168	0	24
24486	ESCUELA 362	4124	0	24
24487	ESCUELA 385	4124	0	24
24488	LA FLORIDA	5281	0	6
24489	ESCUELA 370	4168	0	24
24490	ESCUELA 389	4124	0	24
24491	ESCUELA 392	4124	0	24
24492	ESCUELA 52	4168	0	24
24493	ESCUELA 42	4124	0	24
24494	ESCUELA 77	4168	0	24
24495	ESCUELA 44	4124	0	24
24496	LA FRONDA	5282	0	6
24497	ESCUELA 45	4124	0	24
24498	ESCUELA 78	4168	0	24
24499	ESCUELA 47	4124	0	24
24500	ESCUELA 79	4168	0	24
24501	ESCUELA GDOR LOPEZ	4124	0	24
24502	LA GRAMILLA	5282	0	6
24503	ESCUELA HERNAN MIRAVAL	4124	0	24
24504	ESCUELA 80	4168	0	24
24505	ESCUELA 81	4168	0	24
24506	ESCUELA J J THAMES	4124	0	24
24507	ESCUELA 82	4168	0	24
24508	LA LILIA	5281	0	6
24509	ESCUELA JUAN JOSE PASO	4124	0	24
24510	ESCUELA 216	4124	0	24
24511	ESCUELA ALEJANDRO HEREDIA	4168	0	24
24512	ESCUELA ANGEL PADILLA	4168	0	24
24513	ESTANQUE	4124	0	24
24514	LA MESILLA	5285	0	6
24515	HUALINCHAY	4124	0	24
24516	ESCUELA BATALLA DE TUCUMAN	4168	0	24
24517	HUASAMAYO	4122	0	24
24518	HUASAMAYO SUD	4122	0	24
24519	INDIA MUERTA	4124	0	24
24520	ESCUELA CACIQUE MANAMICO	4168	0	24
24521	KILOMETRO 1340	4124	0	24
24522	LA PRIMAVERA	5139	0	6
24523	KILOMETRO 847	4124	0	24
24524	LA AGUADA	4124	0	24
24525	LA CIENAGA	4101	0	24
24526	ESCUELA ESTANISLAO ZEBALLOS	4168	0	24
24527	LA PUERTA	5281	0	6
24528	LA COLONIA	4115	0	24
24529	LA CUEVA	4126	0	24
24530	LA ESPERANZA	4151	0	24
24531	LA ESQUINA	4124	0	24
24532	LA LAGUNA	4124	0	24
24533	LAS BOTIJAS	4124	0	24
24534	LAS BURRAS	4124	0	24
24535	LAS CA	4124	0	24
24536	LAS JUNTAS	4122	0	24
24537	LAS PIRCAS	4124	0	24
24538	LOS ANGELES	4178	0	24
24539	LOS BORDOS	4124	0	24
24540	ESCUELA GOBERNADOR MIGUEL NOGU	4168	0	24
24541	LA TOMA	5280	0	6
24542	ESCUELA GRANILLO	4168	0	24
24543	ESCUELA IGNACIO BAS	4168	0	24
24544	ESCUELA LA ASUNCION	4168	0	24
24545	ESCUELA M DE PUEYRREDON	4168	0	24
24546	ESCUELA P DE MENDOZA	4168	0	24
24547	LA VIRGINIA	5281	0	6
24548	ESCUELA PEDRO ECHEVERRY	4168	0	24
24549	ESCUELA R ROJAS	4168	0	24
24550	LAS ALERAS	5270	0	6
24551	LAS CA	5284	0	6
24552	LAS LOMAS	5284	0	6
24553	LAS PIEDRITAS	5281	0	6
24554	LAS PLAYAS	5285	0	6
24555	ESQUINA	4111	0	24
24556	LAS TAPIAS	5281	0	6
24557	ESTABLECIMIENTO LAS COLONIAS	4115	0	24
24558	LAS TINAJERAS	5284	0	6
24559	LAS TOTORITAS	5285	0	6
24560	LOS ALGARROBITOS	5281	0	6
24561	ACHIRAS	5875	0	6
24562	ESTACION DE ZOOTECNIA B	4000	0	24
24563	ALTO DE LAS MULAS	5875	0	6
24564	LOS CHA	5281	0	6
24565	ESTANCIA LA PRINCESA	4168	0	24
24566	ALTO RESBALOSO	5885	0	6
24567	LOS ESLABONES	5270	0	6
24568	FINCA TINTA	4168	0	24
24569	FINCA LOS LLANOS	4168	0	24
24570	ARBOLES BLANCOS	5873	0	6
24571	BANDA DE VARELA	5875	0	6
24572	BARRIO LA FERIA	5870	0	6
24573	BOCA DEL RIO	5885	0	6
24574	CA	5873	0	6
24575	CAPILLA DE ROMERO	5873	0	6
24576	CARTABEROL	5871	0	6
24577	CHAQUINCHUNA	5870	0	6
24578	CHUCHIRAS	5875	0	6
24579	COLONIA MONTES NEGROS	5875	0	6
24580	COME TIERRA	5875	0	6
24581	CONLARA	5873	0	6
24582	CORRALITO SAN JAVIER	5879	0	6
24583	DIQUE LA VI	5885	0	6
24584	EL ALTO	5885	0	6
24585	EL BALDECITO	5870	0	6
24586	KILOMETRO 1231	4168	0	24
24587	EL CERRO	5875	0	6
24588	LOS HORMIGUEROS	5281	0	6
24589	EL MANANTIAL	5873	0	6
24590	EL PUEBLITO	5875	0	6
24591	LOS MISTOLES	5281	0	6
24592	GUANACO BOLEADO	5875	0	6
24593	LOS PANTALLES	5284	0	6
24594	HORNILLOS	5885	0	6
24595	LOS PIQUILLINES	5201	0	6
24596	HUASTA	5875	0	6
24597	LOS SAUCES	5282	0	6
24598	LA CA	5870	0	6
24599	LA FUENTE	5879	0	6
24600	LOS VALDES	5270	0	6
24601	LA POBLACION	5875	0	6
24602	LA SIENA	5875	0	6
24603	MAJADA DE SANTIAGO	5287	0	6
24604	LA TRAVESIA	5875	0	6
24605	MANDALA	5284	0	6
24606	LA VENTANA	5870	0	6
24607	LAS CA	5870	0	6
24608	MEDIA NARANJA	5281	0	6
24609	LAS ENCRUCIJADAS	5871	0	6
24610	LAS PALOMAS	5870	0	6
24611	MESA DE MARIANO	5285	0	6
24612	NEGRO HUASI	5280	0	6
24613	LAS TRES PIEDRAS	5879	0	6
24614	LOMA BOLA	5879	0	6
24615	LOMITAS	5875	0	6
24616	LOS CHA	5873	0	6
24617	LOS CHA	5873	0	6
24618	LOS MANGUITOS	5873	0	6
24619	LOS MOLLES	5885	0	6
24620	LOS POZOS	5870	0	6
24621	MANGUITAS	5873	0	6
24622	NICHO	5870	0	6
24623	POZO DEL MOLLE	5873	0	6
24624	QUEBRADA DE LOS POZOS	5885	0	6
24625	RIO DE JAIME	5875	0	6
24626	RIO HONDO	5875	0	6
24627	RODEO DE PIEDRA	5875	0	6
24628	SAGRADA FAMILIA	5875	0	6
24629	SALTO	5873	0	6
24630	LOS PUESTOS	4124	0	24
24631	SAN ANTONIO	5870	0	6
24632	MIMILLO	4124	0	24
24633	MOLLE YACO	4124	0	24
24634	SAN ISIDRO	5875	0	6
24635	SAN JAVIER	5875	0	6
24636		4122	0	24
24637	PANTANILLO	4124	0	24
24638	PORTEZUELO	4124	0	24
24639	POSTA VIEJA	4122	0	24
24640	POTRERO GRANDE	4168	0	24
24641	POTRO YACO	4122	0	24
24642	CHANCANI	5871	0	6
24643	POZO SUNCHO	4124	0	24
24644	PRADERA ALEGRE	4124	0	24
24645	PUESTO VARELA	4124	0	24
24646	REARTE	4124	0	24
24647	RODEO	4122	0	24
24649	SAN MIGUEL SAN VICENTE	5871	0	6
24655	SAN NICOLAS	5871	0	6
24656	SAN CARLOS	4124	0	24
24657	SANTA RITA	4124	0	24
24658	TACANAS	4124	0	24
24659	TACO LLANO	4124	0	24
24660	SAN ROQUE	5870	0	6
24661	TACO PUNCO	4124	0	24
24662	TACO YACO	4124	0	24
24663	TIPA MAYO	4124	0	24
24664	TABANILLO	5870	0	6
24665	TIPAS	4105	0	24
24666	TRANCAS	4124	0	24
24667	VESUBIO	4122	0	24
24668	TILQUICHO	5873	0	6
24669	VILLA GLORIA	4124	0	24
24670	VILLA RITA	4124	0	24
24671	VILLA VIEJA	4124	0	24
24672	ZAPATA	5873	0	6
24673	CORRAL DE CABALLOS	5870	0	6
24674	DIEZ RIOS	5875	0	6
24675	POZO DEL CHA	5873	0	6
24676	NUEVA ESPERANZA	5280	0	6
24677	ORO GRUESO	5287	0	6
24678	PALO CORTADO	5280	0	6
24679	PALO LABRADO	5281	0	6
24680	PALO PARADO	5281	0	6
24681	PALO QUEMADO	5284	0	6
24682	PALOMA POZO	5284	0	6
24683	PASO DE MONTOYA	5284	0	6
24684	PICHANAS	5284	0	6
24685	PIEDRAS AMONTONADAS	5284	0	6
24686	PIEDRAS ANCHAS	5284	0	6
24687	POZO DEL SIMBOL	5281	0	6
24688	PUESTO DEL GALLO	5281	0	6
24689	QUILMES	5270	0	6
24690	YARAMI	4124	0	24
24691	RAMBLON	5284	0	6
24692	YUCHACO	4124	0	24
24693	REPRESA DE MORALES	5285	0	6
24694	RIO DE LA POBLACION	5280	0	6
24695	RIO SECO	5284	0	6
24696	SAN ANTONIO	5281	0	6
24697	SAN ISIDRO	5281	0	6
24698	SAN JOSE	5281	0	6
24699	SANTA ANA	5284	0	6
24700	SENDAS GRANDES	5284	0	6
24701	SIMBOLAR	5281	0	6
24702	TABAQUILLO	5281	0	6
24703	TALA DEL RIO SECO	5284	0	6
24704	TRES ARBOLES	5285	0	6
24705	VILLA LOS LEONES	5281	0	6
24706	ESCUELA	4105	0	24
24707	ESCUELA 113	4105	0	24
24708	ESCUELA 311	4105	0	24
24709	BARRIAL	5281	0	6
24710	ESCUELA ANTONIO MEDINA	4105	0	24
24711	ESCUELA GRANADEROS DE SAN MART	4105	0	24
24712	LAS ABRAS	5270	0	6
24713	ESCUELA OTILDE DE TORO	4105	0	24
24714	HORCO MOLLE	4105	0	24
24715	LA SALA	4105	0	24
24716	LOMAS DE IMBAUD	4105	0	24
24717	RUTA PROVINCIAL 338	4105	0	24
24718	VILLA SAN JAVIER	4105	0	24
24719	OLIVARES SAN NICOLAS	5280	0	6
24726	ARBOL CHATO	2432	0	6
24727	ARROYO DE ALVAREZ	2434	0	6
24728	BARRIO MULLER	5143	0	6
24729	CAMPO BANDILLO	5943	0	6
24730	CAMPO BEIRO	2421	0	6
24731	CAMPO BOERO	2426	0	6
24732	CAMPO CALVO	2423	0	6
24733	CAMPO COYUNDA	5139	0	6
24734	CAMPO LA LUISA	2423	0	6
24735	CAPILLA SAN ANTONIO	2432	0	6
24736	CAPILLA SANTA ROSA	2415	0	6
24737	COLONIA ANGELITA	5941	0	6
24738	COLONIA ANITA	2413	0	6
24739	COLONIA ARROYO DE ALVAREZ	2436	0	6
24740	COLONIA BEIRO	2421	0	6
24742	COLONIA BOTTURI	2419	0	6
24743	ANTONIO CATALANO	6271	0	6
24744	COLONIA CEFERINA	2415	0	6
24745	COLONIA CORTADERA	2436	0	6
24746	BURMEISTER	6225	0	6
24747	COLONIA COYUNDA	2435	0	6
24748	CAMPO SAN JUAN	6271	0	6
24749	COLONIA CRISTINA	2424	0	6
24750	CA	6275	0	6
24751	COLONIA DEL BANCO NACION	2428	0	6
24752	COLONIA DOS HERMANOS	2421	0	6
24753	COLONIA BOERO	6270	0	6
24754	COLONIA DOROTEA	6270	0	6
24755	COLONIA EL MILAGRO	2424	0	6
24756	COLONIA EL TRABAJO	2424	0	6
24757	COSTA DEL RIO QUINTO	6271	0	6
24758	DE LA SERNA	6271	0	6
24759	COLONIA EUGENIA	2413	0	6
24760	EL ARBOL	6127	0	6
24761	EL NOY	6127	0	6
24762	COLONIA GORCHS	2415	0	6
24763	COLONIA GENERAL DEHEZA	5945	0	6
24764	EL PAMPERO	6273	0	6
24765	COLONIA ITURRASPE	2413	0	6
24766	SANTA MAGDALENA	6127	0	6
24767	COLONIA LA MOROCHA	2423	0	6
24768	LA LUZ	6271	0	6
24769	COLONIA LA TORDILLA	2435	0	6
24770	COLONIA LA TRINCHERA	2417	0	6
24771	LA NACIONAL	6275	0	6
24772	LA PENCA	6279	0	6
24773	COLONIA LAVARELLO	2415	0	6
24774	LA PERLITA	6271	0	6
24775	COLONIA MAUNIER	2349	0	6
24776	LARSEN	6275	0	6
24777	COLONIA MILESSI	2349	0	6
24778	LECUEDER	6273	0	6
24779	COLONIA NUEVO PIAMONTE	2415	0	6
24780	COLONIA PALO LABRADO	2415	0	6
24781	LOS ALFALFARES	6275	0	6
24782	COLONIA PRODAMONTE	2413	0	6
24783	COLONIA SAN PEDRO	2421	0	6
24784	LOS GAUCHOS DE GUEMES	6127	0	6
24785	COLONIA SANTA MARIA	2423	0	6
24786	MELIDEO	6270	0	6
24787	COLONIA SANTA RITA	2411	0	6
24788	MODESTINO PIZARRO	6273	0	6
24789	COLONIA TACURALES	2421	0	6
24790	NAZCA	6270	0	6
24791	PINCEN	6271	0	6
24792	COLONIA TORO PUJIO	5139	0	6
24793	RANQUELES	6271	0	6
24794	COLONIA UDINE	2417	0	6
24795	COLONIAS	2436	0	6
24796	TOMAS ECHENIQUE	6271	0	6
24797	CORRAL DE GOMEZ	5139	0	6
24798	VILLA MODERNA	6275	0	6
24799	CORRAL DE GUARDIA	5940	0	6
24800	CORRAL DE MULAS	5945	0	6
24801	VILLA SARMIENTO	6273	0	6
24802	COTAGAITA	2419	0	6
24803	WATT	6270	0	6
24804	CRISTINA	2424	0	6
24805	DOS ROSAS	2349	0	6
24807	EL FUERTECITO	2428	0	6
24808	EL JUMIAL	5947	0	6
24809	EL TRABAJO	2424	0	6
24810	ESTANCIA EL CHA	2428	0	6
24811	ESTANCIA LA CHIQUITA	2428	0	6
24812	ESTANCIA LA MOROCHA	2428	0	6
24813	INDIA MUERTA	5909	0	6
24814	JEANMAIRE	2424	0	6
24815	JERONIMO CORTES	5141	0	6
24816	KILOMETRO 531	2424	0	6
24817	KILOMETRO 581	2428	0	6
24819	LA CURVA	2434	0	6
24820	EL FLORIDA	2432	0	6
24821	LA FRONTERA	2433	0	6
24822	LA MILKA	2400	0	6
24823	LA POBLADORA	5945	0	6
24824	PRIMAVERA	5139	0	6
24825	LA REPRESA	2436	0	6
24826	LA TRINCHERA	2417	0	6
24827	LA UDINE	2413	0	6
24828	LA VICENTA	2417	0	6
24829	LAS CA	2428	0	6
24830	LAS DELICIAS	2433	0	6
24831	LOS ALGARROBITOS	2432	0	6
24832	LOS DESAGUES	2421	0	6
24833	LUIS SAUZE	2423	0	6
24834	MAUNIER	2421	0	6
24835	MONTE GRANDE	2417	0	6
24836	MONTE REDONDO	2423	0	6
24837	ARROYO DEL PINO	5901	0	6
24838	PASO DE LOS GALLEGOS	2433	0	6
24839	PLAYA GRANDE	5139	0	6
24840	AMERICA UNIDA	1862	0	1
24841	GUERNICA	1862	0	1
24842	VILLA NUMANCIA	1858	0	1
24843	PLAZA BRUNO	2436	0	6
24844	PLAZA SAN FRANCISCO	2401	0	6
24845	PLUJUNTA	5141	0	6
24846	POZO DEL AVESTRUZ	5947	0	6
24847	POZO DEL CHAJA	2433	0	6
24849	POZO DEL CHA	2435	0	6
24851	PUENTE RIO PLUJUNTA	5139	0	6
24852	QUEBRACHITOS	2436	0	6
24854	TORO PUJIO	5139	0	6
24857	TRINCHERA	5909	0	6
24858	VACAS BLANCAS	5143	0	6
24859	CAPILLA SAN ANTONIO DE YUCAT	5936	0	6
24860	VILLA SAN ESTEBAN	5947	0	6
24861	CARLOMAGNO	5925	0	6
24862	VILLA VAUDAGNA	2435	0	6
24863	CAYUQUEO	5901	0	6
24864	VILLA VIEJA	2426	0	6
24865	COLONIA SANTA RITA	5936	0	6
24866	COLONIA YUCAT SUD	5917	0	6
24867	FABRICA MILITAR	5900	0	6
24868	COLONIA SAN RAFAEL	2433	0	6
24869	FERREYRA	5925	0	6
24870	KILOMETRO 267	5901	0	6
24871	LA HERRADURA	5900	0	6
24872	SAN RAFAEL	5139	0	6
24873	SANTA RITA	2413	0	6
24874	LA REINA	5925	0	6
24875	LAS CUATRO ESQUINAS	5900	0	6
24876	LAS MOJARRAS	5909	0	6
24877	LAS PICHANAS	5900	0	6
24878	LOS REYUNOS	5925	0	6
24879	MARIA	5925	0	6
24880	MONTE DE LOS LAZOS	5900	0	6
24881	PAUNERO	5738	0	6
24882	RAMON J CARCANO	5900	0	6
24883	SAN ANTONIO DE YUCAT	5936	0	6
24884	SANABRIA	5901	0	6
24885	SANTA ROSA	5909	0	6
24886	SANTA VICTORIA	2675	0	6
24887	SARMICA	5925	0	6
24888	VILLA AURORA	5900	0	6
24889	VILLA DEL PARQUE	5903	0	6
24890	VILLA EMILIA	5900	0	6
24892	AGUA PINTADA	5212	0	6
24893	ALGARROBO	5221	0	6
24894	AVELLANEDA	5212	0	6
24895	BAJO DE OLMOS	5221	0	6
24896	KILOMETRO 1260	4168	0	24
24897	BARRANCA YACO	5212	0	6
24898	KILOMETRO 35	4168	0	24
24899	CA	5221	0	6
24900	CA	5218	0	6
24901	LA BOLSA	4128	0	24
24902	LA DONOSA	4168	0	24
24903	CA	5221	0	6
24904	CANTERA LOS VIERAS	5212	0	6
24905	LA ENCANTADA	4111	0	24
24906	ALTO ALEGRE	5121	0	6
24907	CANTERAS KILOMETRO 428	5200	0	6
24908	CERRO DE LA CRUZ	5200	0	6
24909	ALTO DE FIERRO	5119	0	6
24910	LA ISLA	4168	0	24
24911	CERRO NEGRO	5221	0	6
24912	LA PRINCESA	4168	0	24
24913	BAJO CHICO	5189	0	6
24914	CORIMAYO	5184	0	6
24915	CORITO	5200	0	6
24916	ALTO DEL DURAZNO	5119	0	6
24917	CRUZ MOJADA	5212	0	6
24918	BAJO GRANDE	5101	0	6
24919	EL ALGARROBO	5221	0	6
24920	BARRIO DEAN FUNES	5123	0	6
24921	LAS BARRANCAS	4168	0	24
24922	EL BA	5214	0	6
24923	BUENA VISTA	5121	0	6
24924	EL CHANCHITO	5218	0	6
24925	CAMINO A PUNTA DEL AGUA	5101	0	6
24926	EL CORO	5212	0	6
24927	EL DIVISADERO	5212	0	6
24928	CANTERAS ALTA GRACIA	5186	0	6
24929	EL ESTANQUE	5212	0	6
24930	CAPILLA DE COSME	5101	0	6
24931	EL IALITA	5212	0	6
24932	LAS CUATRO ESQUINAS	4168	0	24
24933	EL JUME	5218	0	6
24934	COLONIA COSME SUD	5101	0	6
24935	EL MOJONCITO	5218	0	6
24936	COLONIA SAN ISIDRO	5189	0	6
24937	COLONIA SANTA CATALINA	5851	0	6
24938	LAS JUNTAS	4168	0	24
24939	EL MOLINO	5214	0	6
24940	EL PARAISO	5218	0	6
24941	DIQUE LOS MOLINOS	5192	0	6
24942	EL PORTILLO	5200	0	6
24943	DUARTE QUIROS	5119	0	6
24944	EL PUESTO LOS CABRERA	5218	0	6
24945	LAS PIRVAS	4168	0	24
24946	ESTANCIA LA PUNTA DEL AGUA	5187	0	6
24947	EL QUEBRACHO	5218	0	6
24948	LAS TALAS	4178	0	24
24949	GOLPE DE AGUA	5187	0	6
24950	JOSE DE LA QUINTANA	5189	0	6
24951	EL RANCHITO	5218	0	6
24952	LA BETANIA	5189	0	6
24953	EL TALA	5201	0	6
24954	LEALES	4113	0	24
24955	EL TALITA	5212	0	6
24956	LA COCHA	5101	0	6
24957	LOS AGUDOS	4168	0	24
24958	FALDA DEL CARMEN	5187	0	6
24959	EL TAMBERO	5212	0	6
24960	LA GRANADILLA	5187	0	6
24961	EL VEINTICINCO	5214	0	6
24962	LA ISOLINA	5186	0	6
24963	ESTANCIA GOROSITO	5212	0	6
24964	LA LAGUNILLA	5119	0	6
24965	INGENIERO BERTINI	5200	0	6
24966	ISCHILIN	5201	0	6
24967	LA PAISANITA	5186	0	6
24968	JAIME PETER	5218	0	6
24969	LOS DECIMA	4168	0	24
24970	JUAN GARCIA	5212	0	6
24971	KILOMETRO 430	5200	0	6
24972	KILOMETRO 450	5218	0	6
24973	LAGUNILLA	5101	0	6
24974	KILOMETRO 784	5212	0	6
24975	LOS GRAMAJO	4159	0	24
24976	LAS HIGUERITAS	5186	0	6
24977	KILOMETRO 807	5212	0	6
24978	LAS PLAYAS LOZADA	5101	0	6
24979	KILOMETRO 827	5212	0	6
24980	LOS ALGARROBOS	5189	0	6
24981	KILOMETRO 832	5200	0	6
24982	LOS CERRILLOS	5101	0	6
24983	LOS POCITOS	4168	0	24
24984	KILOMETRO 859	5214	0	6
24985	LOS OLIVARES	5101	0	6
24986	KILOMETRO 865	5214	0	6
24987	LOS PARAISOS	5187	0	6
24988	KILOMETRO 881	5214	0	6
24989	MI VALLE	5101	0	6
24990	LA AGUADA	5212	0	6
24991	MONTE GRANDE RAFAEL GARCIA	5119	0	6
24992	LA AURA	5218	0	6
24993	OBREGON	5189	0	6
24994	LA BARRANCA	5214	0	6
24995	POTRERO DE FUNES	5189	0	6
24996	LOS VALDES	4168	0	24
24997	LA BATALLA	5201	0	6
24998	LOS VILLAGRA	4178	0	24
24999	POTRERO DE GARAY	5189	0	6
25000	POTRERO DE TUTZER	5186	0	6
25001	RIO LOS MOLINOS	5189	0	6
25002	MASCIO SUR	4172	0	24
25003	SAN ANTONIO	5121	0	6
25004	LA BOTIJA	5214	0	6
25005	MANCOPA CHICO	4115	0	24
25006	LA CALERA	5218	0	6
25007	SAN ANTONIO NORTE	5119	0	6
25008	LA CA	5218	0	6
25009	ESCUELA 324	4128	0	24
25010	ESCUELA 333	4128	0	24
25011	ESCUELA 348	4128	0	24
25012	ESCUELA 39	4128	0	24
25013	ESCUELA 51	4128	0	24
25014	LA CHACRA	5212	0	6
25015	ESCUELA DE MANUALIDADES	4128	0	24
25016	ESCUELA DE MANUALIDADES OUANTA	4128	0	24
25017	ESCUELA DEAN SALCEDO	4128	0	24
25018	ESCUELA E CANTON	4128	0	24
25019	MOLLE POZO	4168	0	24
25020	ESCUELA F NOGUES	4128	0	24
25021	SANTA RITA	5189	0	6
25022	ESCUELA F N LAPRIDA	4128	0	24
25023	LA COLONIA	5201	0	6
25024	ESCUELA IGNACIO COLOMBRES	4128	0	24
25025	LA ESTACADA	5212	0	6
25026	ESCUELA ING BERTRE	4128	0	24
25027	VILLA CARLOS PELLEGRINI	5186	0	6
25028	ESCUELA L BLANCO	4128	0	24
25029	VILLA localidades DE AMERICA	5189	0	6
25030	ESCUELA MALVINAS	4128	0	24
25031	LA FLORIDA	5214	0	6
25032	ESCUELA MANUEL SAVIO	4128	0	24
25033	FAGSA	4105	0	24
25034	FINCA TINA	4105	0	24
25035	HITACHI	4105	0	24
25036	VILLA LA RANCHERITA	5189	0	6
25037	LA HIGUERITA	5201	0	6
25038	ING MERCEDES	4152	0	24
25039	JAVA	4149	0	24
25040	LA BOMBA	4105	0	24
25041	LAS JUNTAS	4105	0	24
25042	LOS ALAMOS	4105	0	24
25043	LOS CHAMICOS	4105	0	24
25044	MISKY	4105	0	24
25045	LA ISABELA	5200	0	6
25046	VILLA LOS AROMOS	5186	0	6
25047	MUNDO NUEVO	4105	0	24
25048	POTRERILLO	4105	0	24
25049	LA MAJADA	5212	0	6
25050	RUTA NACIONAL 157	4128	0	24
25051	VILLA SATYTA	5189	0	6
25052	RUTA NACIONAL 38	4128	0	24
25053	PAJA BLANCA	4168	0	24
25054	RUTA PROVINCIAL 301	4128	0	24
25055	LA ISLA	5186	0	6
25056	LA MESADA	5200	0	6
25057	RUTA PROVINCIAL 338	4128	0	24
25058	RUTA PROVINCIAL 380	4128	0	24
25059	LA RUDA	5214	0	6
25060	SAN MIGUEL	4105	0	24
25061	LA SELVA	5212	0	6
25062	TECOTEX	4105	0	24
25063	YERBA HUASI	4105	0	24
25064	LA TUNA	5212	0	6
25065	LAS CA	5201	0	6
25066	PAMPA MAYO NOROESTE	4172	0	24
25067	LAS CANTERAS	5218	0	6
25068	LAS CHACRAS	5214	0	6
25069	PLANTA DE BOMBEO DE YPF	4168	0	24
25070	AGUADA DEL MONTE	5209	0	6
25071	LAS CRUCECITAS	5201	0	6
25072	PORVENIR	4178	0	24
25073	AGUADITA	5209	0	6
25074	LAS DELICIAS	5212	0	6
25075	BORDO DE LOS ESPINOSA	5209	0	6
25076	LAS LOMITAS	5212	0	6
25077	CACHI YACO	5209	0	6
25078	CALASUYA	5201	0	6
25079	LAS MANZANAS	5212	0	6
25080	CAMPO ALEGRE	5209	0	6
25081	CA	5244	0	6
25082	LAS PALMAS	5201	0	6
25083	CASPICHUMA	5209	0	6
25084	LAS PALMITAS	5221	0	6
25085	CHACRAS DEL SAUCE	5244	0	6
25086	LAS PALOMITAS	5201	0	6
25087	CHU	5201	0	6
25088	LAS PENCAS	5200	0	6
25089	COPACABANA	5201	0	6
25090	LAS PIEDRAS ANCHAS	5212	0	6
25091	LAS SIERRAS	5212	0	6
25092	EL CARRIZAL CHU	5201	0	6
25093	LAS TOSCAS	5214	0	6
25094	EL PANTANO	5244	0	6
25095	LAS TUSCAS	5218	0	6
25096	EL PERTIGO	5201	0	6
25097	LOBERA	5201	0	6
25098	EL RODEITO	5201	0	6
25099	GRACIELA	5209	0	6
25100	LOS BRINZES	5201	0	6
25101	INVERNADA	5209	0	6
25102	LOS CADILLOS	5214	0	6
25103	JARILLAS	5209	0	6
25104	PUNTA DE RIELES	4115	0	24
25105	LOS CEJAS	5201	0	6
25106	JUME	5209	0	6
25107	LA ESPERANZA	5209	0	6
25108	LOS CHA	5212	0	6
25109	LA PLAZA	5244	0	6
25110	ALTO DE LEIVA	4142	0	24
25111	ALTO VERDE	4142	0	24
25112	LOS COQUITOS	5201	0	6
25113	LA POSTA CHU	5201	0	6
25114	APARADERO MILITAR GRAL MU	4142	0	24
25115	ARANILLA	4134	0	24
25116	LOS MIQUILES	5221	0	6
25117	B ZORRILLA	4142	0	24
25118	LA QUINTA	5209	0	6
25119	CAPITAN CACERES	4142	0	24
25120	CASPICHANGO VIEJO	4142	0	24
25121	LA TOTORILLA	5209	0	6
25122	LOS MORTEROS	5214	0	6
25123	CASTILLAS	4172	0	24
25124	CHILCAR	4172	0	24
25125	LOS PEDERNALES	5212	0	6
25126	COLONIA SANTA MARINA	4142	0	24
25127	LA ZANJA	5201	0	6
25128	LOS POZOS	5212	0	6
25129	LAS AGUADITAS	5201	0	6
25130	LOS PUESTITOS	5200	0	6
25131	LAS JARILLAS	5209	0	6
25132	RUTA NACIONAL 157	4168	0	24
25133	LOMA BLANCA	5209	0	6
25134	RUTA NACIONAL 9	4168	0	24
25135	LOMITAS	5209	0	6
25136	RUTA PROVINCIAL 302	4168	0	24
25137	LOS RUICES	5201	0	6
25138	LOS BORDOS	5209	0	6
25139	RUTA PROVINCIAL 306	4168	0	24
25140	LOS CERRILLOS	5209	0	6
25141	COLONIA 6	4142	0	24
25142	MAJADILLA	5209	0	6
25143	MANANTIALES	5209	0	6
25144	LOS SOCABONES	5214	0	6
25145	RUTA PROVINCIAL 320	4168	0	24
25146	RUTA PROVINCIAL 323	4168	0	24
25147	MOVADO	5209	0	6
25148	RUTA PROVINCIAL 366	4168	0	24
25149	LOS TARTAGOS	5218	0	6
25150	NAVARRO	5209	0	6
25151	POZO DEL TIGRE	5209	0	6
25152	MIQUILOS	5221	0	6
25153	PUESTO NUEVO	5209	0	6
25154	MOLINOS	5212	0	6
25155	RUTA PROVINCIAL 374	4168	0	24
25156	RODEITO	5209	0	6
25157	SAN LUIS	5209	0	6
25158	ONGAMIRA	5184	0	6
25159	SAN PABLO	5209	0	6
25160	ORCOSUNI	5214	0	6
25161	RUTA PROVINCIAL 375	4168	0	24
25162	SANTA ANA	5209	0	6
25463	LA CAJUELA	2563	0	6
25163	SANTA MARIA DE SOBREMONTE	5209	0	6
25164	SANTO DOMINGO	5209	0	6
25165	SOCORRO	5209	0	6
25166	SAN CARLOS	4186	0	24
25167	TOTRILLA	5201	0	6
25168	PUESTO DE ARRIBA	5214	0	6
25169	CASPICUCHANA	5209	0	6
25170	PUESTO DE BATALLA	5218	0	6
25171	PUESTO DE LOS RODRIGUEZ	5200	0	6
25172	PUESTO DE CERRO	5200	0	6
25173	PUESTO DEL MEDIO	5117	0	6
25174	QUEBRADA DE NONA	5184	0	6
25175	RIO DE LAS MANZANAS	5212	0	6
25176	TALILAR	4168	0	24
25177	VICLOS	4178	0	24
25178	VIZCACHERA	4168	0	24
25179	YACUCHIRI	4174	0	24
25180	YANGALLO	4168	0	24
25181	BARRIO DEL LIBERTADOR	5850	0	6
25182	CAMPO ROSSIANO	5987	0	6
25183	COLONIA ALMADA	5987	0	6
25184	COLONIA GARZON	5987	0	6
25185	COLONIA HAMBURGO	5933	0	6
25186	COLONIA LA PRIMAVERA	5933	0	6
25187	COLONIA LUQUE	5850	0	6
25188	COLONIA SANTA MARGARITA	5933	0	6
25189	EL PORTE	5933	0	6
25190	EL SALTO NORTE	5854	0	6
25191	ABRA DEL TAFI	4105	0	24
25192	FABRICA MILITAR RIO TERCERO	5850	0	6
25193	CALIMAYO	4105	0	24
25194	CAMPO REDONDO	4105	0	24
25195	COLONIA FELIPE	4105	0	24
25196	LAS ISLETILLAS	5931	0	6
25197	COLONIA LOS CHASALES	4105	0	24
25198	LOS POTREROS	5850	0	6
25199	MONTE DEL FRAYLE	5931	0	6
25200	COLONIA TACAPUNCO	4105	0	24
25201	PUNTA DEL AGUA	5931	0	6
25202	EL CARMEN	4128	0	24
25203	EL DURAZNILLO	4105	0	24
25204	ESCUELA 12	4128	0	24
25205	ESCUELA 130	4128	0	24
25206	ESCUELA 212	4128	0	24
25207	ESCUELA 222	4128	0	24
25208	ESCUELA 243	4128	0	24
25209	ESCUELA 247	4128	0	24
25210	ESCUELA 251	4128	0	24
25211	ESCUELA 253	4128	0	24
25212	ESCUELA 254	4128	0	24
25213	ESCUELA 260	4128	0	24
25214	RIO DE LOS TALAS	5221	0	6
25215	RIO PINTO	5221	0	6
25216	SAJON	5200	0	6
25217	SAN BERNARDO	5201	0	6
25218	SAN CARLOS	5212	0	6
25219	SAN MIGUEL	5212	0	6
25220	SAN NICOLAS	5281	0	6
25221	SAN PEDRO DE TOYOS	5201	0	6
25222	SAN VICENTE	5200	0	6
25223	SANTA RITA	5200	0	6
25224	SAUCE CHIQUITO	5200	0	6
25225	SAUCE PUNCO	5200	0	6
25226	TODOS LOS SANTOS	5201	0	6
25227	TORO MUERTO	5200	0	6
25228	VILLA ALBERTINA	5221	0	6
25229	VILLA CERRO NEGRO	5221	0	6
25230	AGUA DE LAS PIEDRAS	5221	0	6
25231	VILLA COLIMBA	5201	0	6
25232	CABINDO	5221	0	6
25233	CAMPO ALEGRE	5221	0	6
25234	VILLA GUTIERREZ	5212	0	6
25235	CAMPO ALVAREZ	5229	0	6
25236	YERBA BUENA	5200	0	6
25237	CAMPO DE LAS PIEDRAS	5236	0	6
25238	CA	5200	0	6
25239	CAMPO LA PIEDRA	5221	0	6
25240	CA	5221	0	6
25241	CA	5221	0	6
25242	CANDELARIA SUD	5221	0	6
25243	CANTERAS LOS MORALES	5238	0	6
25244	CAPILLA DE SITON	5231	0	6
25245	CASAS VIEJAS	5236	0	6
25246	CHACRAS VIEJAS	5242	0	6
25248	CORRAL DE BARRANCA	5221	0	6
25249	CRUZ DEL QUEMADO	5221	0	6
25250	DOCTOR NICASIO SALAS ORO	5221	0	6
25251	EL BOSQUE	5229	0	6
25252	EL PEDACITO	5236	0	6
25253	EL RINCON	5231	0	6
25254	EL TALITA VILLA GRAL MITRE	5236	0	6
25255	ESPINILLO	5221	0	6
25256	ESTANCIA BOTTARO	5229	0	6
25257	ESTANCIA EL TACO	5229	0	6
25258	ESTANCIA LAS MERCEDES	5229	0	6
25259	ESTANCIA LAS ROSAS	5229	0	6
25260	ASSUNTA	2671	0	6
25261	BARRETO	2671	0	6
25262	HARAS SAN ANTONIO	5236	0	6
25263	COLONIA DOLORES	5809	0	6
25264	KILOMETRO 364	5229	0	6
25265	COLONIA MAIPU	2684	0	6
25266	KILOMETRO 394	5238	0	6
25267	LA AGUADA	5211	0	6
25268	COLONIA SANTA PAULA	5805	0	6
25269	COLONIA VALLE GRANDE	6121	0	6
25270	DEMARCHI	2684	0	6
25271	LA DORA	5229	0	6
25272	EL RASTREADOR	6121	0	6
25273	ESTANCIA LAS MARGARITAS	2671	0	6
25274	LA PAMPA	5117	0	6
25275	LA PAZ	5117	0	6
25276	HUANCHILLA SUD	6121	0	6
25277	LA PORTE	5221	0	6
25278	LA CA	5803	0	6
25279	LAS BANDURRIAS	5236	0	6
25280	LOS COMETIERRA	5221	0	6
25281	LOS MISTOLES	5229	0	6
25282	LAGUNILLAS	5807	0	6
25283	MACHA	5211	0	6
25284	LOS CISNES	2684	0	6
25285	POZO CONCA	5221	0	6
25286	POZO CORREA	5221	0	6
25287	MANANTIALES	2671	0	6
25288	PUESTO DEL ROSARIO	5236	0	6
25289	PUESTO SAN JOSE	5242	0	6
25290	OLMOS	2684	0	6
25291	QUISCASACATE	5221	0	6
25292	PASTOS ALTOS	5807	0	6
25293	RIO DE LOS SAUCES	5221	0	6
25294	SAN ANTONIO DE BELLA VISTA	5236	0	6
25295	PAVIN	6121	0	6
25296	SAN JORGE	5117	0	6
25297	SAN JOSE	5242	0	6
25298	SAN LORENZO	5221	0	6
25299	SAN MIGUEL	5117	0	6
25300	SAN PELLEGRINO	5221	0	6
25301	SANTA LUCIA	5229	0	6
25302	SANTA MARIA	5236	0	6
25303	SANTA SABINA	5221	0	6
25304	SIMBOLAR	5242	0	6
25305	PEDRO E FUNES	2671	0	6
25306	TINTIZACO	5229	0	6
25308	VILLA GENERAL MITRE	5236	0	6
25309	CABEZA DE BUEY	5229	0	6
25310	EL CRESTON DE PIEDRA	5236	0	6
25311	ACOLLARADO	5216	0	6
25312	AGUA DEL TALA	5243	0	6
25314	AGUA HEDIONDA	5216	0	6
25316	ALTO DE FLORES	5203	0	6
25317	ALTO VERDE	5205	0	6
25318	ARBOL BLANCO	5216	0	6
25319	BEUCE	5244	0	6
25320	CAMARONES	5205	0	6
25321	CHIPITIN	5244	0	6
25322	CHURQUI CA	5246	0	6
25323	DURAZNO	5244	0	6
25324	EL CERRITO	5205	0	6
25325	EL DESMONTE	5205	0	6
25326	EL DURAZNO	5231	0	6
25327	EL GUINDO	5244	0	6
25328	EL OJO DE AGUA	5203	0	6
25329	EL PASO	5203	0	6
25330	EL PERCHEL	5244	0	6
25331	EL RODEO	5246	0	6
25332	EL ROSARIO	5205	0	6
25333	EL SEBIL	5244	0	6
25334	EL TUSCAL	5216	0	6
25335	EL VENCE	5231	0	6
25336	ESPINILLO	5203	0	6
25337	ESTANCIA EL NACIONAL	5244	0	6
25338	GUALLASCATE	5244	0	6
25339	ISLA DE SAN ANTONIO	5214	0	6
25340	ITI HUASI	5203	0	6
25341	KILOMETRO 907	5216	0	6
25342	KILOMETRO 931	5216	0	6
25343	LA CA	5201	0	6
25344	LA COSTA	5244	0	6
25345	LA ESPERANZA	5231	0	6
25346	LA HIGUERITA	5244	0	6
25347	LA LAGUNA	5205	0	6
25348	LA PROVIDENCIA	5231	0	6
25349	LADERA YACUS	5246	0	6
25350	LAGUNA BRAVA	5244	0	6
25351	LAGUNA DE GOMEZ	5244	0	6
25352	BAJO DEL BURRO	2662	0	6
25353	LAS AROMAS	5231	0	6
25354	LAS CA	5216	0	6
25355	BARRIO LA FORTUNA	2594	0	6
25356	LAS HORQUETAS	5244	0	6
25357	LAS JUNTAS	5203	0	6
25358	LAS LOMITAS	5244	0	6
25359	LAS MASITAS	5231	0	6
25360	LAS PALMAS	5231	0	6
25361	LAS QUINTAS	5244	0	6
25362	LOMA DE PIEDRA	5244	0	6
25363	COLONIA 25 LOS SURGENTES	2581	0	6
25364	LOS ALAMOS	5244	0	6
25365	LOS POZOS	5244	0	6
25366	COLONIA BALLESTEROS	2662	0	6
25367	COLONIA BARGE	2659	0	6
25368	MAJADILLA	5203	0	6
25369	MIRAFLORES	5244	0	6
25370	COLONIA CALCHAQUI	2580	0	6
25371	PISCO HUASI	5244	0	6
25372	POZO SOLO	5244	0	6
25373	COLONIA EL CHAJA	2594	0	6
25374	PROVIDENCIA	5231	0	6
25375	COLONIA LA MURIUCHA	2580	0	6
25376	PUESTO VIEJO	5244	0	6
25377	ROJAS	5246	0	6
25378	SAN GABRIEL	5244	0	6
25379	COLONIA LA PALESTINA	2645	0	6
25380	SAN GERONIMO	5297	0	6
25381	COLONIA LEDESMA	2662	0	6
25382	SAN JOSE	5216	0	6
25383	COLONIA LOS VASCOS	2189	0	6
25384	SAN ROQUE LAS ARRIAS	5231	0	6
25385	SANTA CRUZ	5201	0	6
25386	COLONIA PROGRESO	2645	0	6
25387	SEVILLA	5205	0	6
25388	COLONIA VEINTICINCO	2592	0	6
25389	TOTORALEJOS	5216	0	6
25390	CORTADERAS	2661	0	6
25391	VILLA ROSARIO DEL SALADILLO	5233	0	6
25392	EL PANAL	2580	0	6
25393	SAN ROQUE	5227	0	6
25394	ENFERMERA KELLY	2587	0	6
25395	TUSCAL	5216	0	6
25396	FLORA	2525	0	6
25397	KILEGRUMAN	2625	0	6
25398	KILOMETRO 57	2619	0	6
25399	LA REDUCCION	2594	0	6
25400	LATAN HALL	2625	0	6
25401	PIEDRAS ANCHAS	2645	0	6
25402	PUEBLO ARGENTINO	2580	0	6
25403	PUEBLO CARLOS SAUVERAN	2581	0	6
25404	PUEBLO GAMBANDE	2627	0	6
25405	PUEBLO RIO TERCERO	2581	0	6
25406	SAN JOSE DEL SALTE	2563	0	6
25407	DESVIO KILOMETRO 57	2625	0	6
25417	ANA ZUMARAN	5905	0	6
25419	BARRIO BELGRANO	2550	0	6
25421	CAMPO GENERAL PAZ	2555	0	6
25423	CAMPO SOL DE MAYO	2679	0	6
25425	CAPILLA DE SAN ANTONIO	2559	0	6
25427	COLONIA BREMEN	2651	0	6
25429	COLONIA LA LEONCITA	2559	0	6
25431	COLONIA LA LOLA	2650	0	6
25445	COLONIA MASCHI	2559	0	6
25446	CORRAL DEL BAJO	5913	0	6
25448	CUATRO CAMINOS	2551	0	6
25450	EL PORVENIR	2651	0	6
25451	EL CARMEN	2550	0	6
25453	EL DORADO	2651	0	6
25455	EL FLORENTINO	5951	0	6
25457	EL OVERO	2563	0	6
25458	EL PARAISO	2559	0	6
25459	EL TRIANGULO	2572	0	6
25460	ESTACION BELL VILLE	2550	0	6
25461	GENERAL VIAMONTE	2671	0	6
25462	ISLETA NEGRA	2559	0	6
25464	LA ITALIANA	2651	0	6
25465	LA ROSARINA	5951	0	6
25466	LA TIGRA	5949	0	6
25467	LAS LAGUNITAS	2568	0	6
25468	LAS MERCEDITAS	2572	0	6
25469	LAS OVERIAS	2559	0	6
25470	LAS PALMERAS	2559	0	6
25471	LOS MOLLES	2561	0	6
25472	LOS TASIS	2559	0	6
25473	LOS UCLES	2559	0	6
25474	MATACOS	2659	0	6
25475	MONTE CASTILLO	2563	0	6
25476	MONTE LE	2564	0	6
25477	OVERA NEGRA	5951	0	6
25478	PUEBLO VIEJO	2555	0	6
25479	SAN CARLOS	2572	0	6
25480	SAN JOSE	2563	0	6
25481	SAN MELITON	2664	0	6
25482	SAN PEDRO	2559	0	6
25483	SAN VICENTE	2550	0	6
25484	SANTA MARIA	2651	0	6
25485	SANTA ROSA	5913	0	6
25486	ATAHONA	5225	0	6
25487	COLONIA LA PIEDRA	5801	0	6
25488	MIRAMAR	5143	0	6
25489	PINAS	2572	0	6
25490	LA BARRANQUITA	5833	0	6
25491	LA BRIANZA	5848	0	6
25492	LA CALERA	5813	0	6
25493	9 DE JULIO	5272	0	6
25494	SAUCE DE LOS QUEVEDOS	5297	0	6
25495	AGUAS DE RAMON	5284	0	6
25496	TALA CA	5297	0	6
25497	TORO MUERTO	5295	0	6
25498	TRES CHA	5295	0	6
25499	CA	5291	0	6
25500	CERRO BOLA	5293	0	6
25501	VILLA TANINGA	5295	0	6
25502	VISO	5295	0	6
25503	CHA	5291	0	6
25504	CIENAGA DEL CORO	5289	0	6
25505	EL BARREAL	5270	0	6
25506	EL CHACHO	5272	0	6
25507	EL DURAZNO	5293	0	6
25508	EL MOYANO	5272	0	6
25509	EL RIO	5285	0	6
25510	EL RODEO	5291	0	6
25511	EL SAUCE	5289	0	6
25512	EL SUNCHAL	5291	0	6
25513	EL VALLESITO	5291	0	6
25514	ESTANCIA DE GUADALUPE	5291	0	6
25515	COLONIA LA MAGDALENA DE ORO	6132	0	6
25516	GUASAPAMPA	5285	0	6
25517	COLONIA LA PROVIDENCIA	6134	0	6
25518	LA ARGENTINA	5293	0	6
25519	COLONIA SANTA ANA	6123	0	6
25520	LA BISMUTINA	5291	0	6
25521	CURAPALIGUE	6120	0	6
25522	FRAY CAYETANO RODRIGUEZ	6120	0	6
25523	LA ESTANCIA	5291	0	6
25524	GAVILAN	6132	0	6
25525	LA PINTADA	5271	0	6
25526	GUARDIA VIEJA	6120	0	6
25527	LA PLAYA	5285	0	6
25528	JULIO ARGENTINO ROCA	6134	0	6
25529	LA RAMADA	6123	0	6
25530	LAS CHACRAS	5284	0	6
25531	LEGUIZAMON	6128	0	6
25532	LAS CORTADERAS	5293	0	6
25533	MIGUEL SALAS	6128	0	6
25534	LAS LATAS	5272	0	6
25535	RUIZ DIAZ DE GUZMAN	6120	0	6
25536	SALGUERO	6120	0	6
25537	LOS BARRIALES	5291	0	6
25538	SAN JOAQUIN	6123	0	6
25539	SANTA CLARA	6123	0	6
25540	OJO DE AGUA DE TOTOX	5293	0	6
25541	SANTA CRISTINA	6134	0	6
25542	MINA LA BISMUTINA	5291	0	6
25543	MIRAFLORES	5272	0	6
25544	MOGOTE VERDE	5291	0	6
25545	TACUREL	6123	0	6
25546	NINALQUIN	5291	0	6
25547	VIVERO	6128	0	6
25548	OJO DE AGUA	5293	0	6
25549	PAJONAL	5291	0	6
25550	PASO GRANDE	5291	0	6
25551	PIEDRAS ANCHAS	5291	0	6
25552	PIEDRITA BLANCA	5271	0	6
25553	POTRERO DE MARQUES	5297	0	6
25554	POZO DEL BARRIAL	5272	0	6
25555	POZO SECO	5285	0	6
25556	PUESTO DE VERA	5271	0	6
25557	RAMIREZ	5289	0	6
25558	RARA FORTUNA	5287	0	6
25559	AGUA DE TALA	5155	0	6
25560	RUMIACO	5289	0	6
25561	ALTO CASTRO	5182	0	6
25562	RUMIHUASI	5285	0	6
25563	ALTO DE SAN PEDRO	5174	0	6
25564	ANGOSTURA	5155	0	6
25565	EL SALTO	5282	0	6
25566	BATAN	5155	0	6
25567	SAPANSOTO	5291	0	6
25568	BOSQUE ALEGRE	5187	0	6
25569	BUEN RETIRO	5155	0	6
25570	LA CUCHILLA	3734	0	4
25571	CAJON DEL RIO	5184	0	6
25572	SIERRA DE ABREGU	5291	0	6
25573	CALABALUMBA	5282	0	6
25574	SIERRA DE LAS PAREDES	5291	0	6
25575	SUNCHAL	5291	0	6
25576	TALAINI	5291	0	6
25577	CA	5184	0	6
25578	TASACUNA	5284	0	6
25579	CASA NUEVA	5155	0	6
25580	TOSNO	5289	0	6
25581	CASA SERRANA HUERTA GRANDE	5175	0	6
25582	TOTORA GUASI	5284	0	6
25583	CASCADAS	5178	0	6
25584	TOTORITAS	5291	0	6
25585	TRES ESQUINAS	5291	0	6
25586	TRES LOMAS	5291	0	6
25587	CASSAFFOUSTH ESTACION FCGB	5149	0	6
25588	CHACHA DEL REY	5282	0	6
25589	CHARBONIER	5282	0	6
25590	COLONIA BANCO PCIA BS AS	5155	0	6
25591	COPINA	5153	0	6
25592	CUCHILLA NEVADA	5155	0	6
25593	ACOSTILLA	5871	0	6
25594	DIQUE LAS VAQUERIAS	5168	0	6
25595	BALDE DE LA ORILLA	5871	0	6
25596	DIQUE SAN ROQUE	5149	0	6
25597	DOLORES SAN ESTEBAN	5182	0	6
25598	BUENA VISTA	5295	0	6
25599	DOMINGO FUNES	5164	0	6
25600	CA	5299	0	6
25601	CA	5299	0	6
25602	DOS RIOS	5155	0	6
25603	EL AGUILA BLANCA	5184	0	6
25604	CASA BLANCA	5299	0	6
25605	EL CARRIZAL	5282	0	6
25606	CHAMICO	5299	0	6
25607	EL CUADRADO	5172	0	6
25608	CUCHILLO YACO	5295	0	6
25609	EL DURAZNO	5155	0	6
25610	EL PERCHEL	5166	0	6
25611	EL CARRIZAL	5299	0	6
25612	EL PERUEL	5155	0	6
25613	EL POTRERO	5295	0	6
25614	EL PILCADO	5155	0	6
25615	EL RINCON	5871	0	6
25616	EL PINGO	5178	0	6
25617	LA AGUADITA	5299	0	6
25618	EL POTRERO	5155	0	6
25619	EL PUENTE	5172	0	6
25620	EL VERGEL	5155	0	6
25621	LA CALERA	5297	0	6
25622	EL ZAPATO	5184	0	6
25623	ESCOBAS	5282	0	6
25624	ESTANCIA DOS RIOS	5155	0	6
25625	LA ESQUINA	5295	0	6
25626	GRUTA DE SAN ANTONIO	5172	0	6
25627	GUASTA	5155	0	6
25628	LA JARILLA	5871	0	6
25629	IRIGOYEN	5168	0	6
25630	KILOMETRO 579	5168	0	6
25631	LA MUDANA	5299	0	6
25632	KILOMETRO 592	5166	0	6
25633	KILOMETRO 608	5149	0	6
25634	LA CA	5155	0	6
25635	LA CANTERA	5168	0	6
25636	LA COSTA	5282	0	6
25637	LA PIEDRA MOVEDIZA	5184	0	6
25638	LA QUEBRADA	5172	0	6
25639	LA USINA	5168	0	6
25640	LAS CASITAS	5158	0	6
25641	LAS GEMELAS	5184	0	6
25642	LAS PAMPILLAS	5182	0	6
25643	LAS PLAYAS	5172	0	6
25644	LAS VAQUERIAS	5184	0	6
25645	LOS GIGANTES	5155	0	6
25646	LOS GUEVARA	5282	0	6
25647	LOS HELECHOS	5168	0	6
25648	LOS MOGOTES	5182	0	6
25649	LOS PAREDONES	5282	0	6
25650	LOS PUENTES	5158	0	6
25651	LOS TERRONES	5184	0	6
25652	MALLIN	5155	0	6
25653	MOLINARI	5166	0	6
25654	PAMPA DE OLAEN	5166	0	6
25655	PARQUE SIQUIMAN	5158	0	6
25656	PIEDRA GRANDE	5168	0	6
25657	PIEDRA MOVEDIZA	5174	0	6
25658	PIEDRAS BLANCAS	5174	0	6
25659	PIEDRAS GRANDES	5172	0	6
25660	PUNILLA	5184	0	6
25661	QUEBRADA DE LUNA	5282	0	6
25662	RIO GRANDE	5172	0	6
25663	SAN BUENAVENTURA	5164	0	6
25664	SAN IGNACIO	5182	0	6
25665	SAN JOSE	5166	0	6
25666	SAN ROQUE	5149	0	6
25667	SAN SALVADOR	5282	0	6
25668	LA PATRIA	5871	0	6
25669	LA SIERRITA	5297	0	6
25670	LA TABLADA	5299	0	6
25671	LAS CHACRAS	5297	0	6
25672	LAS CORTADERAS	5295	0	6
25673	SANTA ISABEL	5282	0	6
25674	SANTA ROSA	5166	0	6
25675	LAS OSCURAS	5871	0	6
25676	SANTA ROSA HUERTA GRANDE	5174	0	6
25677	LAS PALMAS	5299	0	6
25678	SAUCE ARRIBA	5182	0	6
25679	LAS ROSAS	5295	0	6
25680	SUNCHO HUICO	5184	0	6
25681	TANTI LOMAS	5155	0	6
25682	LOS DOS POZOS	5871	0	6
25683	TANTI NUEVO	5155	0	6
25684	URITORCO	5184	0	6
25685	LOS MEDANITOS	5871	0	6
25686	VILLA AHORA	5166	0	6
25687	MOGIGASTA	5891	0	6
25688	VILLA BUSTOS	5164	0	6
25689	PIEDRITAS ROSADAS	5295	0	6
25690	VILLA CAEIRO	5164	0	6
25691	PITOA	5295	0	6
25692	VILLA COSTA AZUL	5153	0	6
25693	POCHO	5299	0	6
25694	VILLA FLOR SERRANA	5155	0	6
25695	PUSISUNA	5299	0	6
25696	VILLA GRACIA	5153	0	6
25697	RIO HONDO	5297	0	6
25698	SAGRADA FAMILIA	5297	0	6
25699	VILLA INDEPENDENCIA	5153	0	6
25700	VILLA SUIZA ARGENTINA	5156	0	6
25702	EL VADO	5182	0	6
25703	VILLA CUESTA BLANCA	5153	0	6
25704	HOSPITAL FLIA DOMINGO FUNES	5165	0	6
25705	ALPA CORRAL	5801	0	6
25706	ALPAPUCA	5813	0	6
25707	ARROYO SANTA CATALINA	5825	0	6
25708	ARSENAL JOSE MARIA ROJAS	5825	0	6
25709	CAMPO DE LA TORRE	5801	0	6
25710	CAPILLA DE TEGUA	5813	0	6
25711	CHA	5829	0	6
25712	COLONIA LA ARGENTINA	6140	0	6
25713	COLONIA DEAN FUNES	5847	0	6
25714	COLONIA EL CARMEN PARAJE	5801	0	6
25715	COLONIA LA CARMENSITA	6141	0	6
25716	COLONIA LA CELESTINA	5847	0	6
25717	COLONIA ORCOVI	5841	0	6
25718	COLONIA PASO CARRIL	5801	0	6
25719	CUATRO VIENTOS	5801	0	6
25720	DOS LAGUNAS	5813	0	6
25721	EL BARREAL	5813	0	6
25722	EL BA	5801	0	6
25723	EL CANO	5821	0	6
25724	EL CHIQUILLAN	5813	0	6
25725	EL DURAZNITO	5801	0	6
25726	EL ESPINILLAL	5813	0	6
25727	EL POTOSI	5801	0	6
25728	EL TAMBO	5801	0	6
25729	ESPINILLO	5811	0	6
25730	ESTACION ACHIRAS	5831	0	6
25731	ESTACION PUNTA DE AGUA	5839	0	6
25732	FRAGUEYRO	5847	0	6
25733	GENERAL PUEYRREDON	6140	0	6
25734	GENERAL SOLER	6142	0	6
25736	GLORIALDO FERNANDEZ	5837	0	6
25737	GUINDAS	5821	0	6
25738	HOLMBERG	5825	0	6
25739	LA AGUADA	5801	0	6
25740	KILOMETRO 545	6142	0	6
25764	SANTA CATALINA	5221	0	6
25765	KILOMETRO 55	6121	0	6
25766	EL BALDECITO	5182	0	6
25767	LA PUERTA VILLA DE SOTO	5284	0	6
25768	SAN EUSEBIO	2561	0	6
25769	SANTA CECILIA	2561	0	6
25772	TRELEW	9100	0	5
25773	GENERAL RODRIGUEZ	1748	0	1
25774	LA FRATERNIDAD	1748	0	1
25775	LAS MALVINAS	1748	0	1
25776	EL GUADAL	9300	0	20
25778	AGUADA A PIQUE	9051	0	20
25779	AGUADA LA OVEJA	9051	0	20
25780	CERRO REDONDO	9051	0	20
25781	EL CHARA	9051	0	20
25782	LA AGUADA	9051	0	20
25783	LA ESTELA	9051	0	20
25784	LA VICTORIA	9051	0	20
25785	TRES PUNTAS	9051	0	20
25786	LEANDRO NICEFORO ALEM	9017	0	20
25787	LAGO BUENOS AIRES	9017	0	20
25788	CUEVA DE LAS MANOS	9017	0	20
25789	KILOMETRO 8	9050	0	20
25790	EL LORO	9051	0	20
25791	LA FECUNDIDAD	9051	0	20
25792	DESAMPARADOS	9053	0	20
25793	AGUADA ALEGRE	9310	0	20
25794	BAHIA LAURA	9310	0	20
25795	INGENIERO ATILIO CAPPA	9400	0	20
25796	CAMPAMENTO DOROTEA	9407	0	20
25797	ROSPENTEK AIKE	9407	0	20
25798	RIO CALAFATE	9405	0	20
25799	RIO MITRE	9405	0	20
25800	RIO FENIX	9040	0	20
25801	BAJO FUEGO	9310	0	20
25802	CA	9310	0	20
25803	PASO GREGORES	9050	0	20
25804	LAGO PUEYRREDON	9310	0	20
25806	LA PENINSULA	9311	0	20
25807	CA	9311	0	20
25808	CERRILLO	4336	0	22
25809	EL DIAMANTE	4336	0	22
25810	LOS HERRERAS	4336	0	22
25811	LOS MARCOS	4336	0	22
25812	SAN FELIX	4336	0	22
25813	SAN NICOLAS	4336	0	22
25814	SAN PEDRO	4336	0	22
25815	KILOMETRO 443	4350	0	22
25816	LA BALANZA	4350	0	22
25817	LA RECONQUISTA	4350	0	22
25818	LOTE 15	4350	0	22
25819	EL MISTOL	3752	0	22
25820	POZO COLORADO	3752	0	22
25821	QUEBRACHO PINTADO	3752	0	22
25822	CHA	4452	0	22
25823	CRUZ BAJADA	4452	0	22
25824	GUAYACAN	4452	0	22
25825	LAS PUERTAS	4452	0	22
25826	LOS COLORADOS	4452	0	22
25827	MERCEDES	4452	0	22
25828	MISTOLITO	4452	0	22
25829	PICOS DE AMOR	4452	0	22
25830	PICOS DE ARROZ	4452	0	22
25831	PLATERO	4452	0	22
25832	ROMA	4452	0	22
25833	SAN ISIDRO	4452	0	22
25834	TACIOJ	4452	0	22
25835	TACO ESQUINA	4452	0	22
25836	VINAL MACHO	4452	0	22
25837	VINALITO	4452	0	22
25838	AGUA DULCE	3766	0	22
25839	GUALAMBA	3766	0	22
25840	LA ESMERALDA	3760	0	22
25841	LAS FLORES	3766	0	22
25842	LOS POCITOS	3766	0	22
25843	LOTE 27 ESCUELA 286	3766	0	22
25845	KILOMETRO 450	3763	0	22
25846	OBRAJE MAILIN	3763	0	22
25847	BAJADITA	4208	0	22
25848	CODO	4208	0	22
25849	COLLERA HURCUNA	4208	0	22
25851	LOS ANGELES	4208	0	22
25852	PAAJ MUYO	4208	0	22
25853	PIRUITAS	4315	0	22
25854	SAN LUIS	4205	0	22
25855	SANTA ISABEL	4208	0	22
25856	SAUCES	4315	0	22
25857	SOL DE MAYO	4208	0	22
25858	TACO POZO	4208	0	22
25859	YACUCHIRI	4208	0	22
25862	ANCHANGA	4201	0	22
25863	ARAGONES	4201	0	22
25864	ARBOL SOLO	4201	0	22
25865	BREA PU	4201	0	22
25866	CANCINOS	4201	0	22
25867	CANDELARIA	4201	0	22
25869	CHUIQUI	4317	0	22
25870	COROPAMPA	4317	0	22
25872	EL CARMEN	4317	0	22
25873	EL DEAN	4317	0	22
25874	HOYON	4317	0	22
25875	HUACHANA	4317	0	22
25876	ISLA DE ARAGONES	4317	0	22
25877	KENTI TACO	4317	0	22
25878	LA DARSENA	4317	0	22
25879	LA ESQUINA	4317	0	22
25880	LA PERLITA	4317	0	22
25881	LEIVA	4317	0	22
25882	LEZCANOS	4317	0	22
25883	LOMITAS	4317	0	22
25884	LOS QUIROGA	4317	0	22
25885	MANOGASTA	4317	0	22
25886	MIRANDAS	4317	0	22
25887	POZO CERCADO	4317	0	22
25888	POZO GRANDE	4317	0	22
25889	PUENTE DEL SALADO	4317	0	22
25890	PUESTO DE DIAZ	4317	0	22
25891	RAMADITAS	4317	0	22
25892	RODEO DE SORIA	4317	0	22
25893	RODEO DE VALDEZ	4317	0	22
25894	SAN ANTONIO	4317	0	22
25895	SAN ANTONIO DE LOS CACERES	4317	0	22
25896	SAN CARLOS	4317	0	22
25897	SAN DIONISIO	4201	0	22
25898	SAN ISIDRO	4317	0	22
25899	SAN MARTIN	4317	0	22
25900	SANTA MARIA	4317	0	22
25901	SAUZAL	4317	0	22
25902	SIMBOL POZO	4201	0	22
25903	SOL DE MAYO	4315	0	22
25904	TIPIRO	4317	0	22
25905	EL DURAZNO	4187	0	22
25906	EL GRAMILLAR	4197	0	22
25907	ENSENADA	4197	0	22
25908	ISLA MOTA	4197	0	22
25909	LA LUNA	4187	0	22
25910	LA MARAVILLA	4197	0	22
25911	LA MELADA	4197	0	22
25912	LAS CHACRAS	4187	0	22
25913	LAS PUERTAS	4187	0	22
25914	MONTE POTRERO	4195	0	22
25915	MONTESINO	4187	0	22
25916	PIEDRA BUENA	4197	0	22
25917	SANTO DOMINGO	4197	0	22
25918	TRASLADO	4187	0	22
25919	QUEMADITO	4195	0	22
25920	KILOMETRO 645	4197	0	22
25921	KILOMETRO 651	4197	0	22
25922	SAN NICOLAS	4197	0	22
25923	SANTA ROSA	4197	0	22
25924	SE	4197	0	22
25925	LA FORTUNA	4220	0	22
25926	LAS ORELLANAS	4220	0	22
25927	LAS TIGRERAS	4220	0	22
25928	LOS QUEBRACHOS	4220	0	22
25929	LOS ROBLES	4220	0	22
25930	SALADILLO	4304	0	22
25931	SOTELOS	4304	0	22
25932	TUNALES	4220	0	22
25933	BANDERA BAJADA	4308	0	22
25934	BLANCA	4308	0	22
25935	CASILLA DEL MEDIO	4308	0	22
25936	EL CRECE	4308	0	22
25937	EL SALADILLO	4308	0	22
25938	HIGUERA CHAQUI	4308	0	22
25939	JANTA	4308	0	22
25940	LA BARROSA	4308	0	22
25941	LA FLORIDA	4308	0	22
25942	LA INVERNADA	4308	0	22
25943	LAS COLINAS	4308	0	22
25944	MIRCA	4308	0	22
25945	MORCILLO	4308	0	22
25946	PUMITAYOJ	4308	0	22
25947	SAN GUILLERMO	4308	0	22
25948	SAN IGNACIO	4308	0	22
25949	SAN PASCUAL	4308	0	22
25950	SAN SALVADOR	4308	0	22
25951	SANTA INES	4308	0	22
25952	TACO PUJIO	4308	0	22
25953	TOTORILLA NUEVO	4308	0	22
25954	TRAMO VEINTISEIS	4308	0	22
25955	TUSCA POZO	4308	0	22
25956	YANTA	4308	0	22
25957	MACO	4322	0	22
25958	MADERAS	4322	0	22
25959	REMANSITO	4322	0	22
25960	RIO DE GALLO	4322	0	22
25961	SAN CAYETANO	4322	0	22
25962	SAN VICENTE	4322	0	22
25963	SANTA ROSA	4322	0	22
25964	SEPULTURAS	4322	0	22
25965	TRANCAS	4322	0	22
25966	TRES CHA	4322	0	22
25967	VILA ISLA	4322	0	22
25968	ALTO POZO	4322	0	22
25969	ARDILES DE LA COSTA	4302	0	22
25970	COLONIAS	4322	0	22
25971	CORVALANES	4322	0	22
25972	EL CEBOLLIN	4322	0	22
25973	EL OJO DE AGUA	4322	0	22
25974	EL PUENTE	4322	0	22
25975	KISKA HURMANA	4322	0	22
25976	LA CA	4322	0	22
25977	LA COLONIA	4322	0	22
25978	LA CUARTEADA	4322	0	22
25979	LA FALDA	4322	0	22
25980	LA GERMANIA	4322	0	22
25981	LOMA NEGRA	4322	0	22
25982	LOS ALDERETE	4322	0	22
25983	LOS DIAZ	4322	0	22
25984	LOS DOCE QUEBRACHOS	4322	0	22
25985	LOS GALLARDOS	4322	0	22
25986	LOS GUERREROS	4322	0	22
25987	LOS HERREROS	4322	0	22
25988	LOS PUESTOS	4322	0	22
25989	LOS PUNTOS	4322	0	22
25990	PALERMO	4322	0	22
25991	QUISHCA	4322	0	22
25992	QUITA PUNCO	4322	0	22
25993	SAN ANDRES	4302	0	22
25994	SAN LORENZO	4322	0	22
25995	SAN MARTIN	4322	0	22
25996	SAN ROQUE	4322	0	22
25997	SANTA CRUZ	4322	0	22
25998	SANTA RITA	4322	0	22
25999	SAINQUEN PUNCO	4322	0	22
26000	SURI POZO	4322	0	22
26001	TAPERAS	4322	0	22
26002	ARBOLITOS	4322	0	22
26003	BUENA VISTA	4322	0	22
26004	CACHI	4322	0	22
26005	CAMPO VERDE	4322	0	22
26006	CANDELARIA	4322	0	22
26007	CAVADITO	4322	0	22
26008	CAVADO	4322	0	22
26009	EL AIBAL	4322	0	22
26010	EL CUELLO	4322	0	22
26011	EL VIZCACHERAL	4322	0	22
26012	JUME ESQUINA	4322	0	22
26013	LA BOTA	4322	0	22
26014	LA CRUZ	4322	0	22
26015	LA ESPERANZA	4322	0	22
26016	LA LOMA	4322	0	22
26017	LA PETRONILA	4322	0	22
26018	LA PRIMITIVA	4322	0	22
26019	LA RAMADA	4322	0	22
26020	LOMITAS	4322	0	22
26021	CA	4319	0	22
26022	CHILENO	4319	0	22
26023	GUERRA	4319	0	22
26024	LA PALOMA	4319	0	22
26025	LECHUZAS	4319	0	22
26026	MAL PASO	4319	0	22
26027	MISTOL POZO	4319	0	22
26028	PERALTA	4319	0	22
26030	SALADILLO	4319	0	22
26031	SANTA LUCIA	4319	0	22
26032	TACO TOTARAYOL	4319	0	22
26033	TAGAN	4319	0	22
26034	TIO ALTO	4319	0	22
26035	TOLOZAS	4319	0	22
26036	TOROPAN	4319	0	22
26037	TOTORA	4319	0	22
26038	VARAS CUCHUNA	4319	0	22
26039	VERON	4319	0	22
26040	CARDAJAL	4321	0	22
26041	CHA	5257	0	22
26042	EL PUEBLITO	4321	0	22
26043	LA GOLONDRINA	4321	0	22
26044	LA GRINGA	4321	0	22
26045	LA GRITERIA	5257	0	22
26046	LA PAMPA	4321	0	22
26047	LA PROTEGIDA	4321	0	22
26048	LA PUERTA DEL MONTE	4321	0	22
26049	LOS CA	4321	0	22
26050	MANCHIN	4321	0	22
26051	NAVARRO	5257	0	22
26052	PALO A PIQUE	5257	0	22
26053	POLVAREDA	4319	0	22
26054	PORTALIS	4321	0	22
26055	POZO DEL MONTE	4321	0	22
26056	PUESTO DEL MEDIO	4321	0	22
26057	RAMA PASO	5257	0	22
26058	RAMADITA	4321	0	22
26059	RAMI YACU	4321	0	22
26060	REMANSOS	4321	0	22
26061	RUMI JACO	4321	0	22
26062	SAN NICOLAS	5257	0	22
26063	SANTA BRIGIDA	4321	0	22
26064	SANTA MARIA	4321	0	22
26065	AGUA CALIENTE	5251	0	22
26066	AGUA TURBIA	5251	0	22
26067	AGUADITA	5251	0	22
26068	AHI VEREMOS	5251	0	22
26069	ALPAPUCA	5251	0	22
26070	ANCOCHE	5251	0	22
26071	BAJO LAS PIEDRAS	5250	0	22
26072	CAJON	5250	0	22
26073	CAMPO ALEGRE	5251	0	22
26074	CHACRAS	5250	0	22
26075	CHILCA	5251	0	22
26076	CHUCHI	5251	0	22
26077	CORRALITO	5251	0	22
26078	EL ABRA	5251	0	22
26079	EL BAJO	5251	0	22
26080	EL CERRO	5251	0	22
26081	EL RODEO	5251	0	22
26082	GIBIALTO	5251	0	22
26083	GRAMILLAL	5251	0	22
26084	GUARDIA DE LA ESQUINA	5251	0	22
26085	HILUMAMPA	5251	0	22
26086	HORCOS TUCUCUNA	5250	0	22
26087	HUASCAN	5251	0	22
26088	JACIMAMPA	5250	0	22
26089	LA CALERA	5251	0	22
26090	LA CAPILLA	5251	0	22
26091	LA CUESTA	5251	0	22
26092	LA ESPERANZA	5251	0	22
26093	LA FLORIDA	5251	0	22
26094	LA PINTADA	5251	0	22
26095	LA PUERTA	5251	0	22
26096	LAS CIENAGAS	5251	0	22
26097	LAS COLONIAS	5250	0	22
26098	LAS FLORES	5251	0	22
26099	LAS LOMAS	5251	0	22
26100	LAS LOMITAS	5251	0	22
26101	LAS PARVAS	5251	0	22
26102	LAS ROSAS	5251	0	22
26103	LOMITAS	5251	0	22
26104	MISTOLES	5251	0	22
26105	MOLLES	5251	0	22
26106	NARANJITOS	5251	0	22
26107	PALERMO	5251	0	22
26108	PORTEZUELO	5251	0	22
26109	PUESTO	5251	0	22
26110	QUEBRACHITO	5251	0	22
26111	REMANSO	5251	0	22
26112	RETIRO	5251	0	22
26113	RINCON	5251	0	22
26114	ROSADA	5251	0	22
26115	RUMI HUASI	5251	0	22
26116	SAN LUIS	5251	0	22
26117	SANTA ANA	5250	0	22
26120	CORDOBA	5000	0	6
26121	SANTA MARIA	5251	0	22
26122	SANTA ROSA	5251	0	22
26123	SANTO DOMINGO CHICO	5251	0	22
26124	SIMBOLAR	5251	0	22
26125	WI	5250	0	22
26126	YUMAMPA	5251	0	22
26127	9 DE JULIO	5255	0	22
26128	BUENA ESPERANZA	5255	0	22
26129	CAMPO RICO	5250	0	22
26130	CHA	5250	0	22
26131	COLONIA MERCEDES	5255	0	22
26132	CORRAL DE CARCOS	5250	0	22
26133	CORRAL DEL REY	5250	0	22
26134	CUCHI CORRAL	5250	0	22
26135	EL AGUILA	5250	0	22
26136	EL ALGARROBO	5255	0	22
26137	EL ARBOL DE PIEDRA	5250	0	22
26138	EL ARBOLITO	5250	0	22
26139	EL BORDITO	5255	0	22
26140	EL CARMEN	5255	0	22
26141	EL DIAMANTE	5255	0	22
26142	EL FUERTE	5250	0	22
26143	EL PILAR	5250	0	22
26144	EL PORVENIR	5250	0	22
26145	EL UNCO	5250	0	22
26146	EL VI	5255	0	22
26147	LA CHILCA	5251	0	22
26148	LA GRANA	5255	0	22
26149	LA GRANADA	5255	0	22
26150	LA PALMA	5255	0	22
26151	LA PAMPA	5255	0	22
26152	LA SELVA	5255	0	22
26153	LA SOLEDAD	5250	0	22
26154	LA TRAMPA	5250	0	22
26155	LA TUSCA	5250	0	22
26156	LAGUNA DEL SUNCHO	5250	0	22
26157	LAGUNITAS	5255	0	22
26158	LAS CA	5250	0	22
26159	LAS CRUCES	5255	0	22
26160	LOS ARBOLITOS	5250	0	22
26161	LOS MOLLES	5250	0	22
26162	LOS REMANSOS	5250	0	22
26163	MANCHIN	5255	0	22
26164	MILAGRO	5255	0	22
26165	MIRAMONTE	5250	0	22
26166	MISTOL LOMA	5250	0	22
26167	MONTE VERDE	5255	0	22
26168	POZO DEL ALGARROBO	5255	0	22
26169	POZO DEL GARABATO	5255	0	22
26170	PRIMAVERA	5250	0	22
26171	PROGRESO DE JUME	5250	0	22
26172	PUESTO DE ARRIBA	5255	0	22
26173	PUESTO DEL MEDIO	5255	0	22
26175	PUNTA DEL AGUA	5255	0	22
26176	QUENTI TACO	5255	0	22
26177	REY VIEJO	5250	0	22
26178	SAN ANDRES	5250	0	22
26179	SAN FRANCISCO	5258	0	22
26180	SAN ISIDRO	5255	0	22
26181	SAN JORGE	5250	0	22
26182	SAN RAMON	5255	0	22
26184	SANTA ELENA	5250	0	22
26185	NEGRA MUERTA	5258	0	22
26186	SAN JAVIER	5258	0	22
26187	SAN PEDRO KILOMETRO 49	5258	0	22
26188	AIBAL	3740	0	22
26189	ALZA NUEVA	4353	0	22
26190	BELLA VISTA	3740	0	22
26191	CAMPO LIMPIO	3740	0	22
26192	CA	3740	0	22
26193	CARTAVIO	3740	0	22
26194	CELESTINA	4353	0	22
26195	COLONIA MEDIA	3740	0	22
26196	DOLORES	3740	0	22
26197	DOLORES CENTRAL	4353	0	22
26198	DOS HERMANAS	3740	0	22
26199	EL AIBALITO	3740	0	22
26200	EL BRAGADO	4353	0	22
26201	EL CRUCERO	3740	0	22
26202	EL DESCANSO	3740	0	22
26203	EL ROSARIO	4353	0	22
26204	JUNCAL GRANDE	3740	0	22
26205	LA LOMA	3740	0	22
26206	LOS PUENTES	3740	0	22
26207	MARAVILLA	3740	0	22
26208	MARIA	3740	0	22
26209	MERCEDES	4353	0	22
26210	MINERVA	3740	0	22
26211	NOGALES	3740	0	22
26212	NUEVA ALZA	4353	0	22
26213	PACIENCIA	4353	0	22
26214	PALOMAR	4353	0	22
26215	PAMPA POZO	4353	0	22
26216	PIRHUAS	3740	0	22
26217	PUESTO DE MENA	3740	0	22
26218	QUIS	4353	0	22
26219	REMANSITO	4353	0	22
26220	ROSARIO	4353	0	22
26221	RUMI	3740	0	22
26223	SAN FELIPE	4353	0	22
26224	SAN FRANCISCO	4353	0	22
26225	SAN ISIDRO	4353	0	22
26226	SAN JOSE	3740	0	22
26227	SAN LUIS	4353	0	22
26228	SAN MARTIN	4353	0	22
26229	SAN NICOLAS	3740	0	22
26230	SAN PEDRO	4353	0	22
26231	SAN RAMON	4353	0	22
26232	SAN ROQUE	4353	0	22
26233	SANTA LUCIA	4353	0	22
26234	SANTA MARIA	4353	0	22
26235	SANTA RITA	4353	0	22
26236	SANTO DOMINGO	4353	0	22
26237	TRINIDAD	4353	0	22
26238	UTURUNCO	4353	0	22
26239	VILLA GUA	3740	0	22
26240	DOS EULACIAS	3740	0	22
26241	EL FISCO	3740	0	22
26242	EL NOVENTA	3740	0	22
26243	EL TANQUE	3741	0	22
26244	GENOVEVA	3741	0	22
26245	KILOMETRO 719	3741	0	22
26246	LA CURVA	3741	0	22
26247	LA MARTA	3741	0	22
26248	LAS PORTE	3741	0	22
26249	LOS GATOS	3741	0	22
26250	LOS PECARIEL	3741	0	22
26251	LOS PORTE	3741	0	22
26252	LOTE F	3741	0	22
26253	MORAYOS	3741	0	22
26254	OCTAVIA	3741	0	22
26255	SAN ALBERTO	3741	0	22
26256	SAN MIGUEL	3741	0	22
26257	SANTA ELENA	3741	0	22
26258	AGUA SALADA	3736	0	22
26259	CALDERON	3736	0	22
26260	CAMPO DEL INFIERNO	3736	0	22
26261	CAMPO EL ROSARIO	3736	0	22
26263	DOS REPRESAS	3736	0	22
26264	EL URUNDAY	3736	0	22
26265	EL VEINTE	3736	0	22
26266	ESTANCIA NUEVA ESPERANZA	3736	0	22
26267	HUCHUPAYANA	3736	0	22
26268	TACO FURA	3736	0	22
26270	CAMPO VERDE	4351	0	22
26271	EL CARMEN	4351	0	22
26272	EL PALOMAR	4351	0	22
26273	FLORESTA	4351	0	22
26274	HUACANITAS	4351	0	22
26275	KISKA LORO	4351	0	22
26276	LA POTOCHA	4351	0	22
26277	LOTE S	4351	0	22
26278	PUNTA DE RIELES	4351	0	22
26279	SEGUNDO POZO	4351	0	22
26280	SIMBOLAR	4351	0	22
26281	TABEANITA	4351	0	22
26282	TABIANA	4351	0	22
26284	VILLA FANNY	4351	0	22
26285	JUNIN	6000	0	1
26286	RIO GALLEGOS	9400	0	20
26287	VILLA SANTA ROSA	5133	0	6
26288	PARAJE MONTE GRANDE	5276	0	12
26289	BUTALON	8353	0	15
26290	FORTIN GUA	8353	0	15
26291	HUARACO	8353	0	15
26292	LOS CHACALES	8353	0	15
26293	LOS BOLILLOS	8353	0	15
26294	MANZANO AMARGO	8353	0	15
26295	FUERTE ALTO	4417	0	17
26296	LAS ARCAS	4417	0	17
26297	LAS TRANCAS	4417	0	17
26299	BARRIO PARABOLICA	4417	0	17
26300	FINCA BELGRANO	4415	0	17
26301	OJO DE AGUA	4415	0	17
26302	TONCO	4415	0	17
26303	VILLA MARIA	5900	0	6
26304	PILAR	1629	0	1
26305	ADROGUE	1846	0	1
26306	BURZACO	1852	0	1
26307	CLAYPOLE	1849	0	1
26308	GLEW	1856	0	1
26309	JOSE MARMOL	1846	0	1
26310	LONGCHAMPS	1854	0	1
26311	MALVINAS ARGENTINAS	1846	0	1
26312	MINISTRO RIVADAVIA	1852	0	1
26313	RAFAEL CALZADA	1847	0	1
26314	SAN JOSE	1846	0	1
26315	SAN FRANCISCO SOLANO	1846	0	1
26316	LUJAN	6700	0	1
26317	RIO CUARTO	5800	0	6
26318	INGENIERO WHITE	8103	1	1
26320	SAN PEDRO	5255	0	22
26322	BOCA DEL TIGRE	4306	0	22
26323	CASHICO	4306	0	22
26324	LA PLATA	1900	0	1
26326	CASILLA DEL MEDIO	4306	0	22
26327	ALARCON	2356	0	22
26328	CASARES	2354	0	22
26329	ARGENTINA	2354	0	22
26330	CHA	2354	0	22
26331	EL AIBAL	2354	0	22
26332	EL ASPIRANTE	2354	0	22
26333	EL OSO	2354	0	22
26334	EL UCLE	2354	0	22
26335	FORTIN LA VIUDA	2354	0	22
26336	KILOMETRO 735	2354	0	22
26337	KILOMETRO 764	2356	0	22
26338	LA BLANCA	2354	0	22
26339	LA CAROLINA	2354	0	22
26340	LA CENTELLA	2354	0	22
26341	LA ESMERALDA	2354	0	22
26342	LA RECOMPENSA	2354	0	22
26343	LAS PALMAS	2354	0	22
26344	MARAVILLA	2354	0	22
26345	NUEVA TRINIDAD	2354	0	22
26346	PALMAS	2354	0	22
26351	SAN SEBASTIAN	2354	0	22
26352	SANTA ANA	2354	0	22
26353	TRES LAGUNAS	2354	0	22
26354	TRES POZOS	2354	0	22
26356	AGUA BLANCA	3749	0	22
26357	AGUSTINA LIBARONA	3741	0	22
26358	CAMPO ALEGRE	3749	0	22
26359	CENTRAL DOLORES	3745	0	22
26360	CORONEL MANUEL LEONCIO RICO	3712	0	22
26361	CUQUERO	3749	0	22
26362	DOBLE TERO	3741	0	22
26363	DONADEU	3741	0	22
26364	DOS EULALIAS	3741	0	22
26365	EL CAMBIADO	3749	0	22
26366	EL COLMENAR	3749	0	22
26367	EL FISCO	3741	0	22
26368	EL NOVENTA	3741	0	22
26369	EL OSCURO	3749	0	22
26370	EL SETENTA	3062	0	22
26371	EL SIMBOL	3749	0	22
26372	EL TRASLADO	3749	0	22
26373	FLORIDA	3747	0	22
26374	VILLA HAZAN	3749	0	22
26375	KILOMETRO 1362	3712	0	22
26376	KILOMETRO 1380	3712	0	22
26377	KILOMETRO 1391	3712	0	22
26378	LA AMERICA	3747	0	22
26379	LA ARGENTINA	3749	0	22
26380	LA ARMONIA	3749	0	22
26381	LA FORTUNA	3747	0	22
26382	LA MANGA	4301	0	22
26383	LAS AGUILAS	3749	0	22
26384	LAS CARPAS	3747	0	22
26385	LAS PERFORACIONES	3712	0	22
26386	LOS CARRIZOS	3749	0	22
26387	MAIDANA	3749	0	22
26388	MOJON	4197	0	22
26389	MONTE VERDE	3747	0	22
26390	NUEVO LIBANO	3749	0	22
26391	NUEVO LUJAN	3749	0	22
26392	OBRAJE IRIONDO	3747	0	22
26393	POZO MUERTO	3747	0	22
26394	POZO SALADO	3747	0	22
26395	RIVADAVIA	3749	0	22
26401	CHANCHILLOS	4201	0	22
26403	SALADILLO	4301	0	22
26404	CHILQUITA I	4201	0	22
26405	LA CANCHA	9200	0	5
26406	SAN ANTONIO	3747	0	22
26407	CHUIQUI	4201	0	22
26408	NEGRA MUERTA	4201	0	22
26409	CORO ABRA	4336	0	22
26410	SAN ENRIQUE	4324	0	22
26411	COROPAMPA	4201	0	22
26412	PAAJ MUYO	4315	0	22
26413	SEPULTURA	4301	0	22
26414	YUNTA POZO	3747	0	22
26415	EL OJO DE AGUA	4302	0	22
26416	PINEDA	4317	0	22
26417	ZANJA	4301	0	22
26418	HUYAMAMPA	4336	0	22
26419	PUESTO DEL ROSARIO	4313	0	22
26420	JUMI POZO	4338	0	22
26421	ABRITA CHICA	4201	0	22
26422	KILOMETRO 645	4339	0	22
26423	REMANSITO	4317	0	22
26425	KILOMETRO 651	4339	0	22
26426	ABRITA GRANDE	4201	0	22
26427	LA AURORA	4336	0	22
26429	ANCOCHA	4201	0	22
26430	SAN LUIS	4315	0	22
26431	LA COLONIA	4302	0	22
26432	BAJADITA	4315	0	22
26433	LAS SALINAS	4300	0	22
26434	SANTA ISABEL	4315	0	22
26435	BOQUERON	4313	0	22
26436	LAS ZANJAS	4300	0	22
26437	SOCONCHO	4317	0	22
26438	LOMA NEGRA	4302	0	22
26439	BUENA VISTA	4201	0	22
26440	LOS GUERREROS	4302	0	22
26441	TACO POZO	4315	0	22
26442	MEDIA FLOR	4302	0	22
26443	CANEINOS	4201	0	22
26444	PALOS QUEMADOS	4336	0	22
26445	CHAUCHILLAS	4201	0	22
26446	PAMPA MAYO	4336	0	22
26447	CHILCA ALBARDON	4317	0	22
26448	PUESTO LOS MARCOS	4336	0	22
26449	CHILCAS LA LOMA	4201	0	22
26450	RUTA NACIONAL 34	4326	0	22
26451	CHILQUITA	4317	0	22
26452	TULUM	4313	0	22
26453	RUTA PROVINCIAL 11	4326	0	22
26454	RUTA PROVINCIAL 130	4326	0	22
26455	RUTA PROVINCIAL 17	4326	0	22
26456	YACUCHIRI	4315	0	22
26457	RUTA PROVINCIAL 40	4326	0	22
26458	CODO	4315	0	22
26459	RUTA PROVINCIAL 5	4326	0	22
26461	RUTA PROVINCIAL 8	4326	0	22
26462	CODO VIEJO	4315	0	22
26463	SAN ISIDRO	4338	0	22
26464	BAHIA LAPATAIA	9410	0	23
26465	COLLERA HUIRI	4317	0	22
26466	SAN NICOLAS	4339	0	22
26467	ESTANCIA HARBERTON	9410	0	23
26468	SAN PABLO	4338	0	22
26470	KILOMETRO 436	4317	0	22
26472	EL DORADO	4313	0	22
26474	SANTA ROSA	4339	0	22
26475	ESTACION ATAMISQUI	4315	0	22
26477	SE	4339	0	22
26478	GUANACO SOMBRIANA	4212	0	22
26479	HUAJIA	4318	0	22
26480	SIMBOL CA	4336	0	22
26481	LAGUNA	4203	0	22
26482	KILOMETRO 437	4313	0	22
26483	EL CABURE	3712	0	22
26484	TRAMO 20	4300	0	22
26485	DOLORES	4353	0	22
26487	DOS HERMANAS	4353	0	22
26488	EL 21	3745	0	22
26489	EL AIBAL	4354	0	22
26490	VALDIVIA	4300	0	22
26491	EL AIBALITO	4353	0	22
26492	EL CRUCERO	4353	0	22
26493	LA NORIA	4315	0	22
26495	EL NEGRITO	4353	0	22
26496	EL VIZCACHERAL	4354	0	22
26497	ESTANCIA LA INVERNADA	4353	0	22
26498	DON PIETRO	3064	0	22
26500	HUALO CANCANA	3745	0	22
26501	LA RESBALOSA	5250	0	22
26502	MACO YANDA	4206	0	22
26503	HUILLA CATINA	3745	0	22
26504	JUME ESQUINA	4354	0	22
26506	EL AGRICULTOR	3064	0	22
26507	MAGUITO	4206	0	22
26508	JUMIAL GRANDE	4353	0	22
26509	JUMIALITO	4353	0	22
26510	JUNCAL GRANDE	4353	0	22
26511	MAQUITA	4206	0	22
26512	LOS ANGELES	4315	0	22
26513	EL CANDELERO	3064	0	22
26515	KILOMETRO 613	4354	0	22
26516	LA BOTA	4354	0	22
26517	EL CERRITO MONTE QUEMADO	3714	0	22
26518	EL SIMBOL	3062	0	22
26519	LA CA	4354	0	22
26520	MAQUITIS	4206	0	22
26521	LA CHEJCHILLA	3745	0	22
26523	LOS MOLLARES	4317	0	22
26524	NANDA	4206	0	22
26525	LA CONCEPCION	4354	0	22
26526	EL CORRIDO	3749	0	22
26528	ISLA BAJA	3064	0	22
26529	NAQUITO	4206	0	22
26530	MEDELLIN	4313	0	22
26531	EL ROSARIO	3749	0	22
26532	PAMPA MUYOJ	4203	0	22
26533	HOSTERIA KAIKEN	9410	0	23
26534	LA ALEMANA	3064	0	22
26535	POZO NUEVO	5209	0	22
26536	LA DOLORES	3064	0	22
26537	EL VALLE	3749	0	22
26538	PUESTITO	4313	0	22
26539	EL VALLE DE ORIENTE	3749	0	22
26540	ASERRADERO ARROYO	9420	0	23
26541	GUARCAN	4301	0	22
26542	CABA	9420	0	23
26543	KILOMETRO 1210	3714	0	22
26544	AVE MARIA	4326	0	22
26545	PUESTO NUEVO	4203	0	22
26546	KILOMETRO 1255	3714	0	22
26547	BLANCA POZO	4332	0	22
26548	QUEBRACHO HERRADO	4206	0	22
26549	KILOMETRO 1314	3712	0	22
26550	REMES	4203	0	22
26551	CABO SAN PABLO	9420	0	23
26552	CAMPAMENTO CENTRAL YPF	9420	0	23
26553	KILOMETRO 1338	3712	0	22
26554	CAMPAMENTO LOS CHORRILLOS	9420	0	23
26555	COMISARIA RADMAN	9420	0	23
26556	BRACHO	4332	0	22
26557	LA CA	3749	0	22
26558	LAS PALOMITAS	4230	0	22
26559	LA ESPERANZA	3064	0	22
26560	BREALOJ	4328	0	22
26563	CALOJ	4326	0	22
26564	LAS TEJAS	4230	0	22
26565	LA EULALIA	3064	0	22
26567	LA DEFENSA	3749	0	22
26568	ESTACION AERONAVAL	9411	0	23
26569	LAS TRINCHERAS	4230	0	22
26570	CATORCE QUEBRACHOS	4201	0	22
26571	LA FRANCISCA	3064	0	22
26572	ESTACION OSN	9420	0	23
26573	LA ESPERANZA	3749	0	22
26574	COLLUN LIOJ	4324	0	22
26575	LOMITAS	4233	0	22
26576	LA HIEDRA	3064	0	22
26577	LA ESPERANZA	4354	0	22
26578	LA GUARDIA	4301	0	22
26579	LA INVERNADA	4353	0	22
26580	ESTANCIA AURELIA	9420	0	23
26581	LA ESMERALDA	3766	0	22
26582	LA LOMA	4301	0	22
26583	SAN ISIDRO	4206	0	22
26584	LA HUERTA	3064	0	22
26585	LA FIRMEZA	3714	0	22
26586	LA PRIMITIVA	4354	0	22
26587	LA RAMADA	4354	0	22
26588	ESTANCIA BUENOS AIRES	9420	0	23
26589	SAN LORENZO	4203	0	22
26590	LA PAMPA	3064	0	22
26591	ESTANCIA CARMEN	9420	0	23
26592	LA TAPA	4354	0	22
26593	LA UNION	3749	0	22
26594	LUJAN	4230	0	22
26595	ESTANCIA CAUCHICO	9420	0	23
26596	LIBANESA	4332	0	22
26597	LOMITAS	4354	0	22
26598	ESTANCIA COSTANCIA	9420	0	23
26599	SAN PEDRO	4206	0	22
26600	LOS PUENTES	4353	0	22
26601	ESTANCIA CULLEN	9420	0	23
26602	MACO	4354	0	22
26603	LA PANCHITA	3064	0	22
26604	ESTANCIA DOS HEMANAS	9420	0	23
26605	MADERAS	4354	0	22
26606	LA VIRTUD	3714	0	22
26607	MARAVILLA	4353	0	22
26608	ESTANCIA EL ROBLE	9420	0	23
26609	MAQUIJATA	4203	0	22
26610	MARIA	4353	0	22
26611	MAILIN	4328	0	22
26612	SANTA MARIA	4206	0	22
26613	ESTANCIA EL RODEO	9420	0	23
26614	MINERVA	4353	0	22
26615	NOGALES	4353	0	22
26616	ESTANCIA EL SALVADOR	9420	0	23
26617	LA ROSILLA	3064	0	22
26618	LOS MORTEROS	3712	0	22
26619	PIRHUAS	4353	0	22
26620	ESTANCIA GUAZU CUE	9420	0	23
26621	MARAVILLA	4203	0	22
26622	PASO GRANDE	4326	0	22
26623	SANTA ROSA	4206	0	22
26624	POZO CASTA	3745	0	22
26625	ESTANCIA HERMINITA	9420	0	23
26626	ESTANCIA INES	9420	0	23
26627	PUESTO DE MENA	4353	0	22
26628	ESTANCIA JOSE MENENDEZ	9420	0	23
26629	LA SIMONA	3064	0	22
26630	LOS PIRPINTOS	3712	0	22
26631	PUESTO DEL MEDIO	3745	0	22
26632	ESTANCIA LA CRIOLLA	9420	0	23
26633	MATE PAMPA	4203	0	22
26634	PASO MOSOJ	4324	0	22
26635	QUIMILIOJ	4353	0	22
26636	REMANSITO	4354	0	22
26637	RUMI	4353	0	22
26638	LA SUSANA	3064	0	22
26639	PERCAS	4324	0	22
26640	ESTANCIA LA FUEGUINA	9420	0	23
26641	LA TERESA	3064	0	22
26643	MONTE REDONDO	4230	0	22
26644	ESTANCIA LA INDIANA	9420	0	23
26646	ESTANCIA LA PORTE	9420	0	23
26647	LOS TIGRES	3712	0	22
26648	ESTANCIA LAS HIJAS	9420	0	23
26650	SANTA ROSA ARRAGA	4206	0	22
26651	ESTANCIA LAS VIOLETAS	9420	0	23
26652	LAS AGUADAS	3064	0	22
26653	ESTANCIA LAURA	9420	0	23
26655	MONTEAGUDO	4230	0	22
26656	POZO MARCADO	4326	0	22
26657	MARAVILLA	3749	0	22
26658	ESTANCIA LIBERTAD	9420	0	23
26660	SANTO DOMINGO	4206	0	22
26661	ESTANCIA LOS CERROS	9420	0	23
26662	ESTANCIA LOS FLAMENCOS	9420	0	23
26664	PUENTE NEGRO	4332	0	22
26666	ESTANCIA MARIA BEHETY	9420	0	23
26667	NUEVA ESPERANZA	3714	0	22
26668	ESTANCIA MARIA CRISTINA	9420	0	23
26669	SALADILLO	3745	0	22
26670	TALA POZO	4200	0	22
26672	SAN FELIPE	4353	0	22
26673	ONCAJAN	4233	0	22
26674	ESTANCIA MARIA LUISA	9420	0	23
26675	PUNTA CORRAL	4326	0	22
26676	UPIANITA	4200	0	22
26677	PAAJ POZO	3714	0	22
26678	SAN NICOLAS	4353	0	22
26679	SAN SALVADOR	4354	0	22
26680	ESTANCIA MARINA	9420	0	23
26681	SANTA MARIA	4353	0	22
26683	LAS GAMAS	3064	0	22
26684	ESTANCIA MIRAMONTE	9420	0	23
26685	PALERMO	3749	0	22
26686	ESTANCIA PIRINAICA	9420	0	23
26687	PALO LINDO	4230	0	22
26688	SANTO DOMINGO	4353	0	22
26689	SEPULTURAS	4354	0	22
26690	PARANA	3749	0	22
26692	ESTANCIA POLICARPO	9420	0	23
26693	TRANCAS	4354	0	22
26694	VILLA DE LA BARRANCA	4206	0	22
26695	ESTANCIA RIO CLARO	9420	0	23
26696	LOS PARAISOS	3064	0	22
26697	TRES CHA	4354	0	22
26698	TUSCA POZO	4353	0	22
26699	ESTANCIA RIO EWAN	9420	0	23
26700	ESTANCIA RIO IRIGOYEN	9420	0	23
26701	VILLA FIGUEROA	4353	0	22
26702	PUESTO CORDOBA	3712	0	22
26703	LOS TABLEROS	3062	0	22
26704	ESTANCIA RIVADAVIA	9420	0	23
26705	VILLA HUA	4301	0	22
26706	VILLA ZANJON	4206	0	22
26708	ESTANCIA ROLITO	9420	0	23
26709	VILLA TOLOJNA	4354	0	22
26711	ESTANCIA ROSITA	9420	0	23
26713	ESTANCIA RUBY	9420	0	23
26715	YACU HICHACUNA	4353	0	22
26716	NUEVA AURORA	3064	0	22
26717	SAN ANTONIO	4326	0	22
26719	YACU HURMANA	4354	0	22
26720	YANDA	4206	0	22
26722	SAN CARLOS	3749	0	22
26723	POZO DULCE	3062	0	22
26724	SAN JOSE DE FLORES	4324	0	22
26728	ESTANCIA SAN JOSE	9420	0	23
26729	SAN HORACIO	3712	0	22
26731	ESTANCIA SAN JULIO	9420	0	23
26732	LOS ROBLES	4304	0	22
26733	SAN JUAN	3749	0	22
26734	PALO PARADO	4230	0	22
26735	ESTANCIA SAN JUSTO	9420	0	23
26737	ESTANCIA SAN MARTIN	9420	0	23
26738	ESTANCIA SAN PABLO	9420	0	23
26739	ABRAS DEL MEDIO	4233	0	22
26740	ESTANCIA SANTA ANA	9420	0	23
26742	PARANA	5266	0	22
26743	ESTANCIA SARA	9420	0	23
26744	ESTANCIA TEPI	9420	0	23
26745	SANTA CATALINA	3064	0	22
26746	ESTANCIA VIAMONTE	9420	0	23
26747	MONTE POTRERO	4187	0	22
26748	ALTO ALEGRE	4233	0	22
26749	ESTANCIA DESPEDIDA	9420	0	23
26750	FRIGORIFICO CAP	9421	0	23
26751	LAGO KHAMI	9420	0	23
26752	SANTA CRUZ	4301	0	22
26753	ALTO BELLO	4203	0	22
26754	PUNTA MARIA	9420	0	23
26755	SUNCHITUYOJ	4332	0	22
26756	SELVA BLANCA	3064	0	22
26757	SECCION AVILES  ESTANCIA SAN J	9420	0	23
26758	BAJO HONDO	4230	0	22
26759	PIEDRA BUENA	4187	0	22
26760	TRES LAGUNAS	3062	0	22
26761	POCITO DE LA LOMA	4233	0	22
26763	BUENOS AIRES	4230	0	22
26764	POZANCONES	4230	0	22
26765	TACO ATUN	4328	0	22
26767	POZO CERCADO	4203	0	22
26768	CA	4203	0	22
26769	TACON ESQUINA	4332	0	22
26770	CANARIO	4233	0	22
26772	POZO DEL CAMPO	4233	0	22
26773	CERRILLOS DE SAN ISIDRO	4230	0	22
26774	SANTA MARIA	3712	0	22
26775	PUEDA SER	4233	0	22
26776	BARRIO VILLA COHESA	4200	0	22
26778	PUERTA DEL CIELO	4203	0	22
26779	CAMPO GRANDE	4206	0	22
26780	PUESTO	4233	0	22
26781	CHA	4203	0	22
26783	CARDOZOS	4201	0	22
26784	QUEBRACHOS	4203	0	22
26785	SANTA ROSA COPO	3714	0	22
26787	LAS RAMADITAS	2357	0	22
26788	COSTA RICA	4206	0	22
26789	RODEITO	4233	0	22
26790	SAN FELIX	4187	0	22
26791	RODEO	4203	0	22
26792	TORO PAMPA	4452	0	22
26793	CHOYA	4233	0	22
26795	DIQUE LOS QUIROGA	4201	0	22
26796	SAN JAVIER	4184	0	22
26797	URUTAU	3714	0	22
26798	CORTADERA	4203	0	22
26799	VILLA MATOQUE	4452	0	22
26801	VINAL POZO	3749	0	22
26802	CUICHICA	4203	0	22
26804	DIVISADERO	4233	0	22
26806	EL BAJO	4233	0	22
26811	SAN PEDRO	4184	0	22
26812	SANTO DOMINGO	4187	0	22
26813	SAN ANTONIO DE LAS FLORES	4233	0	22
26814	SAN CARLOS	4230	0	22
26815	SAN DELFIN	4233	0	22
26816	SUPERINTENDENTE LEDESMA	4184	0	22
26817	EL CARMEN	4201	0	22
26818	TACANAS	4184	0	22
26819	LAS VIBORITAS	2354	0	22
26820	EL DEAN	4201	0	22
26821	TRES CRUCES	4306	0	22
26822	MARTINEZ	2357	0	22
26823	INGENIERO EZCURRA	4206	0	22
26824	TRES FLORES	4184	0	22
26825	RETIRO	2357	0	22
26826	KILOMETRO 153	4206	0	22
26827	LA ESPERANZA	4206	0	22
26829	TUNALES	4304	0	22
26830	LA PORTE	4206	0	22
26831	SAN JUSTO	4203	0	22
26833	LA VUELTA	4206	0	22
26834	LAS FLORES	4206	0	22
26835	SAN MIGUEL	4233	0	22
26837	LOS QUIROGA	4206	0	22
26838	SAN PATRICIO	4230	0	22
26839	SANTA PAULA	2356	0	22
26840	YACO MISQUI	2357	0	22
26841	SAN JOSE DTO FIGUEROA	4353	0	22
26842	25 DE MAYO	4353	0	22
26843	SANTA MARIA DTO FIGUEROA	4354	0	22
26844	AEROLITO	3741	0	22
26845	SAN ROMANO	4233	0	22
26846	EL RAJO	4233	0	22
26847	SANTA LUCIA	4233	0	22
26848	BELLA VISTA	4205	0	22
26849	EL CHA	5260	0	22
26850	AIBAL	4353	0	22
26851	SAYACO	4203	0	22
26852	EL ESCONDIDO	4230	0	22
26853	ARBOL BLANCO	3731	0	22
26854	SERRANO MUERTO	4230	0	22
26855	ARBOLITOS	4354	0	22
26856	BELTRAN LORETO	4205	0	22
26857	BELLA VISTA	4353	0	22
26858	SHISHI POZO	4205	0	22
26859	CAMPO DE AMOR	4205	0	22
26860	BUENA VISTA	4354	0	22
26861	CAMPO LIMPIO	4353	0	22
26862	SINCHI CA	4203	0	22
26863	CHIMPA MACHO	4313	0	22
26864	CAMPO VERDE	4354	0	22
26865	SOL DE MAYO	4203	0	22
26866	CA	4353	0	22
26867	ENVIDIA	4205	0	22
26868	SUNCHO POZO	4230	0	22
26869	QUILUMPA	3745	0	22
26870	CARTAVIO	4353	0	22
26871	SUNCHO PUJIO	4230	0	22
26872	ISLA VERDE	4313	0	22
26873	TACO QUINKA	4230	0	22
26874	ROVERSI	3736	0	22
26875	TRONCOS QUEMADOS	4230	0	22
26876	LA LAURA	4205	0	22
26878	25 DE MAYO DE BARNEGAS	4205	0	22
26879	CAVADITO	4354	0	22
26881	LAGUNA BLANCA	4313	0	22
26882	VILLA ADELA	4230	0	22
26884	VILLA ELVIRA	4203	0	22
26886	CAVADO	4354	0	22
26887	LAS DOS FLORES	4205	0	22
26888	YESO ALTO	4203	0	22
26889	COLONIA MEDIA	4353	0	22
26891	EL MILAGRO	4230	0	22
26892	LINTON	4313	0	22
26893	COLONIA SAN JUAN	4353	0	22
26898	CRUZ GRANDE	4354	0	22
26901	LOS RALOS	4205	0	22
26902	BARRIO OBRERO	3740	0	22
26903	SALDIVAR	3740	0	22
26905	PAMPA POZO	4205	0	22
26907	CEJOLAO	3741	0	22
26912	SAN ANTONIO	4353	0	22
26913	COLONIA ESPA	3740	0	22
26914	PORONGAL	4205	0	22
26917	RIO NAMBI	4208	0	22
26918	SAN CARLOS	4353	0	22
26920	SAN PABLO	4353	0	22
26924	EL ARBOLITO	3734	0	22
26925	ALTA GRACIA	4203	0	22
26927	SANTA JUSTINA	3740	0	22
26928	ARROYO TALA	4203	0	22
26929	BELGRANO	4203	0	22
26931	CABRA	4203	0	22
26933	EL BRAVO	3734	0	22
26934	CERRILLOS	4203	0	22
26935	CONZO	4203	0	22
26937	SANTA ROSA	4351	0	22
26938	ESCUELA 1050	4203	0	22
26939	SAN IGNACIO	4205	0	22
26940	EL HOYO	3745	0	22
26941	ESCUELA 20	4203	0	22
26943	ESCUELA 665	4203	0	22
26944	ESCUELA 708	4203	0	22
26946	STAYLE	4351	0	22
26947	FAMATINA	4203	0	22
26948	LA CALERA	4203	0	22
26950	LA ENSENADA	4203	0	22
26951	EL OJO DE AGUA	3740	0	22
26952	LAS CHACRAS	4203	0	22
26953	LAVALLE	4234	0	22
26954	SANTA ROSA DE CORONEL	4205	0	22
26955	SURIHUAYA	4351	0	22
26956	LUJAN	4203	0	22
26957	PALMA FLOR	4203	0	22
26958	PARANA	4203	0	22
26959	PIEDRITAS	4203	0	22
26960	PUERTA CHIQUITA	4203	0	22
26961	TRES MOJONES	3736	0	22
26963	SANTA CATALINA	4203	0	22
26964	SANTA ROSA	4203	0	22
26965	TIO POZO	4315	0	22
26966	SANTOS LUGARES	4203	0	22
26967	TRONCO JURAS	4203	0	22
26968	VILLA LA PUNTA	4203	0	22
26969	TRES POZOS	4351	0	22
26970	VILLA MERCEDES	4189	0	22
26971	VIZCACHERAL	4203	0	22
26972	TRES BAJADAS	4205	0	22
26973	VILLA BRANA	4351	0	22
26974	VILLA MATILDE	3740	0	22
26975	EL PERTIGO	4351	0	22
26976	EL HUAICO	2357	0	22
26977	VILLA YOLANDA	3743	0	22
26978	EL PRADO	3743	0	22
26979	ALGARROBO	5251	0	22
26980	ESTANCIA EL CARMEN	2357	0	22
26981	EL VEINTISIETE	3743	0	22
26982	ARGENTINA	3749	0	22
26983	LAS MOSTAZAS	2357	0	22
26984	AMBARGASTA	5251	0	22
26985	BAHIA BLANCA	3749	0	22
26986	ESTACION PAMPA MUYOJ	3743	0	22
26987	AMIMAN	5251	0	22
26988	BAJO GRANDE	4301	0	22
26989	EL RECREO	4230	0	22
26990	BELGICA	3712	0	22
26991	ESTANCIA LA ELSITA	3740	0	22
26992	AMOLADERAS	5255	0	22
26993	RIO SALADILLO	5250	0	22
26994	EL RINCON	4203	0	22
26995	BOTIJA	4452	0	22
26996	EL RODEO	4230	0	22
26998	EL ROSARIO	4230	0	22
26999	BAEZ	5255	0	22
27000	CAMPO ALEGRE	3749	0	22
27001	GRANADERO GATICA	3741	0	22
27002	EL TACIAL	4233	0	22
27003	CAMPO DEL AGUILA	3749	0	22
27004	BARRIALITO	5251	0	22
27005	EL TALA	4203	0	22
27006	CAMPO VERDE	3749	0	22
27007	HAASE	3741	0	22
27009	EL VEINTICINCO DE MAYO	4233	0	22
27010	CERRITO	5258	0	22
27011	ESCUELA 879	4230	0	22
27012	ESPERANZA	4233	0	22
27014	CHAINIMA	3749	0	22
27015	FAROL	4203	0	22
27016	HERNAN MEJIA MIRAVAL	3741	0	22
27017	FAVORINA	4203	0	22
27018	CHA	3749	0	22
27022	EL BARRIAL	5249	0	22
27023	SALINAS	5250	0	22
27024	JARDIN DE LAS DELICIAS	3740	0	22
27025	GUARDIA DEL NORTE	4203	0	22
27026	DESVIO KILOMETRO 1342	3712	0	22
27027	EL CACHI	5251	0	22
27028	ICHAGON	4203	0	22
27029	EL JUME	5250	0	22
27030	DOS VARONES	3749	0	22
27031	INTI HUASI	4230	0	22
27032	SAN JUAN	5258	0	22
27033	FIVIALTOS	5250	0	22
27034	KILOMETRO 606	3741	0	22
27035	EL CAJON	5250	0	22
27036	JUMEAL O JUMIAL	4230	0	22
27037	KILOMETRO 55	4205	0	22
27038	INTI HUASI	5250	0	22
27039	SANTO DOMINGO	5251	0	22
27040	KILOMETRO 10	4233	0	22
27041	KILOMETRO 694	3745	0	22
27042	EL CUARENTA Y NUEVE	5250	0	22
27043	LA ABRA	4237	0	22
27044	KILOMETRO 301	5255	0	22
27045	KILOMETRO 48	3740	0	22
27046	LA PUNTA	4203	0	22
27047	LA ABRA	5251	0	22
27048	LA AGUADITA	5251	0	22
27049	LA ARGENTINA	5251	0	22
27050	LA PALOMA	3736	0	22
27051	COLONIA ALPINA	2341	0	22
27052	LA PAMPA	3743	0	22
27053	SURI POZO	5251	0	22
27054	COLONIA GERALDINA	2341	0	22
27055	LAGUNA BAYA	3740	0	22
27056	COLONIA MACKINLAY	2354	0	22
27057	LAS RANDAS	4351	0	22
27058	CHILCA	5255	0	22
27059	LA GERALDINA	2341	0	22
27060	AGUA AMARGA	4197	0	22
27061	PALO NEGRO	2354	0	22
27062	AGUA AZUL	4189	0	22
27063	LAS LOMITAS	5255	0	22
27064	LOMITAS BLANCAS	5251	0	22
27065	LOS PORONGOS	2344	0	22
27066	AHI VEREMOS	4197	0	22
27067	LAS TINAJAS	4351	0	22
27068	LOS CRUCES	5255	0	22
27069	PORONGOS	4308	0	22
27070	LILO VIEJO	3745	0	22
27071	LOS PAREDONES	5253	0	22
27073	LINCHO	4350	0	22
27074	ALGARROBAL VIEJO	4197	0	22
27075	LOS POZOS	5250	0	22
27077	ARMONIA	4353	0	22
27078	OJO DE AGUA	5255	0	22
27079	LOS MILAGROS	3741	0	22
27080	OJO DE AGUA	5250	0	22
27081	BAGUAL MUERTO	4197	0	22
27082	LOS PENSAMIENTOS	3740	0	22
27083	ONCAN	5251	0	22
27084	LUJAN	4353	0	22
27085	BELGRANO	4197	0	22
27086	PAMPA GRANDE	5251	0	22
27087	BUEY MUERTO	4308	0	22
27088	MAGDALENA	3741	0	22
27089	BRANDAN	4197	0	22
27090	EL ROSARIO	4322	0	22
27091	PASO REDUCIDO	5250	0	22
27092	PARADA KILOMETRO 101	5250	0	22
27093	BUEN LUGAR	4197	0	22
27094	MILAGRO	3743	0	22
27095	HURITU HUASI	4354	0	22
27096	CAMPO AMARILLO	4189	0	22
27097	PIEDRA BLANCA	5258	0	22
27098	POZO GRANDE	5251	0	22
27099	INDUSTRIA NUEVA	4322	0	22
27100	MISTOL PAMPA	4351	0	22
27101	PUERTA DE LOS RIOS	5249	0	22
27102	JIMENEZ	4322	0	22
27103	MONTE ALTO	3743	0	22
27104	QUEBRACHAL	5251	0	22
27105	CHA	4197	0	22
27106	LA BREA	4354	0	22
27107	OBRAJE MARIA ANGELICA	3743	0	22
27108	OTUMPA	3741	0	22
27109	MILI	4312	0	22
27110	BAJO HONDO	4356	0	22
27111	CAMPO DEL CIELO	3736	0	22
27112	CASA ALTA	4356	0	22
27113	PALERMO	4350	0	22
27114	CHURQUI ESQUINA	4301	0	22
27115	CODO BAJADA	4350	0	22
27116	PAMPA MUYOJ	4351	0	22
27117	COLONIA PAZ	4356	0	22
27118	EL AIBAL	4356	0	22
27119	EL CANAL	4356	0	22
27120	EL CHINCHILLAR	4356	0	22
27121	EL COLORADO	3741	0	22
27122	COPO VIEJO	4189	0	22
27123	RIVADAVIA	4322	0	22
27124	EL DESCANSO	4353	0	22
27125	EL SALADILLO	4356	0	22
27127	PARAJE GAUNA	3740	0	22
27128	KILOMETRO 546	4350	0	22
27130	CORRAL QUEMADO	4197	0	22
27131	KILOMETRO 494	4356	0	22
27132	LA CRUZ	4354	0	22
27133	LAGUNILLA	4356	0	22
27134	LEDESMA	4356	0	22
27136	PATAY	3745	0	22
27137	LLAJTA MAUCA	4356	0	22
27138	LOJLO	4350	0	22
27140	LOTE 29	4356	0	22
27142	EL BALDE	4197	0	22
27143	MELERO	4356	0	22
27144	NASALO	3752	0	22
27145	PUMA	3740	0	22
27146	NOGE	3752	0	22
27147	NUEVA COLONIA	4353	0	22
27148	POZO DEL TOBA	3741	0	22
27149	TUSCA POZO	4322	0	22
27150	PUENTE BAJADA	4356	0	22
27151	PUNCO	4350	0	22
27152	EL BALDECITO	4197	0	22
27153	PUNA	3752	0	22
27154	RINCON ESPERANZA	4356	0	22
27155	ROLDAN	4356	0	22
27156	RUMIARCO	4415	0	22
27157	EL CAJON	4189	0	22
27158	SAN CARLOS	4350	0	22
27159	VILLA ROBLES	4301	0	22
27160	SAN LUIS	4351	0	22
27161	SAN MIGUEL DEL MATARA	4356	0	22
27162	SOLEDAD	4356	0	22
27163	TARUY	4356	0	22
27164	TIUN PUNCO	4356	0	22
27165	YASO	4322	0	22
27166	VILLA ESQUINA	4356	0	22
27167	YUCHAN	4351	0	22
27168	EL CAMBIADO	4187	0	22
27169	ANGA	4321	0	22
27170	BORDO PAMPA	4321	0	22
27171	LOMA GRANDE	4197	0	22
27172	EL DIABLO	4197	0	22
27173	JACIMAMPA	5251	0	22
27174	LOMAS BLANCAS	4197	0	22
27176	LOS CERROS	4189	0	22
27177	EL FLORIDO	4197	0	22
27178	LOS MOLLES	4189	0	22
27179	EL POTRERO	4197	0	22
27180	LOS MOYAS	4189	0	22
27181	MARAVILLA	4197	0	22
27182	EL QUEMADO	4197	0	22
27183	JUME	5253	0	22
27184	EL REAL	4197	0	22
27185	MASUMPA	4197	0	22
27186	KENTI TACKO	5253	0	22
27187	EL ROSARIO	4197	0	22
27188	MEDIA LUNA	4197	0	22
27189	MOLLEOJ	4197	0	22
27190	EL SALADILLO	4197	0	22
27191	MONTE QUEMADO	4195	0	22
27192	KILOMETRO 364	4321	0	22
27193	EL SAUCE	4197	0	22
27194	PALMA POZO	4301	0	22
27195	PAMPA POZO	4189	0	22
27196	LA CLEMIRA	5250	0	22
27197	GUANACUYOJ	4189	0	22
27198	PELUDO WARCUNA	4197	0	22
27199	LA GOLONDRINA	5257	0	22
27200	POZO BETBEDER	4189	0	22
27201	HAHUANCUYOS	4197	0	22
27202	LA GRINGA	5257	0	22
27203	CHARCO VIEJO	4306	0	22
27204	PUESTO DEL MEDIO	4197	0	22
27205	LA PAMPA	5257	0	22
27206	PUESTO DEL SIMBOL	4197	0	22
27207	PUESTO NUEVO	4197	0	22
27208	JUNALITO	4197	0	22
27209	LA AGUADA	4197	0	22
27210	QUEBRACHO COTO	4195	0	22
27211	EL ARBOLITO	4176	0	22
27212	LA ALOJA	4189	0	22
27213	LA PROTEGIDA	5257	0	22
27214	EL BAGUAL	4178	0	22
27215	LA BLANCA	4189	0	22
27216	EL BARRIAL	4301	0	22
27217	QUEBRADA ESQUINA	4197	0	22
27218	LA PUERTA DEL MONTE	5257	0	22
27219	LA CODICIA	4197	0	22
27220	EL FRAILE	4201	0	22
27221	RAPELLI	4189	0	22
27222	LA SOLEDAD	5255	0	22
27226	LA TRAMPA	5255	0	22
27227	EL PACARA	4178	0	22
27228	LA COSTOSA	4187	0	22
27230	LA TUSCA	5255	0	22
27232	LA FLORIDA	4197	0	22
27233	EL PERAL	4201	0	22
27235	LA YERBA	5253	0	22
27236	SAN CRISTOBAL	4197	0	22
27237	SAN GREGORIO	4197	0	22
27238	LA FRAGUA	4197	0	22
27239	HOYO CON AGUA	4201	0	22
27240	LAGUNA DEL SUNCHO	5255	0	22
27241	SAN ISIDRO	4197	0	22
27242	LA JULIANA	4189	0	22
27243	LAS CA	5255	0	22
27244	HOYON	4201	0	22
27245	LAS COLONIAS	5251	0	22
27246	HUACHANA	4201	0	22
27247	SANSIOJ	4197	0	22
27248	SANTA CRUZ	4197	0	22
27249	ISLA DE ARAGONES	4201	0	22
27250	LAS ISLAS	5255	0	22
27251	LA MESADA	4197	0	22
27252	SANTA FELISA	4197	0	22
27253	KENTI TACO	4201	0	22
27254	LAS TALAS	5250	0	22
27255	SANTA MARIA DE LAS CHACRAS	4189	0	22
27256	LIMACHE	5255	0	22
27257	LA TALA	4189	0	22
27258	LA DARSENA	4201	0	22
27259	LOS ARBOLITOS	5255	0	22
27260	SESTEADERO	4187	0	22
27261	LA DONOSA	4221	0	22
27262	SIETE ARBOLES	4197	0	22
27263	LOS CA	5257	0	22
27264	LA ESQUINA	4201	0	22
27265	LAS DELICIAS	4189	0	22
27266	7 DE ABRIL	4197	0	22
27267	LOS MOLLES	5255	0	22
27268	SIMBOL HUASI	4197	0	22
27269	LA FLORIDA	4201	0	22
27270	LAS LAJAS	4189	0	22
27271	LOS QUEBRACHOS	5253	0	22
27272	SIMBOL POZO	4189	0	22
27273	LA GRAMA	4201	0	22
27274	SIMBOLAR	4189	0	22
27275	LOS REMANSOS	5255	0	22
27276	LAS LOMAS	4189	0	22
27277	LA PERLITA	4201	0	22
27278	MANCHIN	5257	0	22
27279	LAS CANTINAS	4178	0	22
27280	LAS QUEBRADAS	4197	0	22
27281	MIRAMONTE	5255	0	22
27282	LAS PALMERAS	4220	0	22
27283	TACO BAJADA	4197	0	22
27284	MISTOL LOMA	5255	0	22
27285	TACO PUNCO	4189	0	22
27286	LIBERTAD	4189	0	22
27287	ARENALES	4187	0	22
27288	LEIVA	4201	0	22
27289	PASO DE OSCARES	5257	0	22
27290	TRES BAJOS	4197	0	22
27291	BLANCO POZO	4184	0	22
27292	EA LA VERDE	4184	0	22
27293	EL BOBADAL	4187	0	22
27294	LESCANOS	4201	0	22
27295	TRES QUEBRACHOS	4197	0	22
27296	POLVAREDAS	5257	0	22
27297	EL CHURQUI	4184	0	22
27298	EL FISCO DE FATIMA	3741	0	22
27299	LOMITAS	4201	0	22
27300	TRES VARONES	4189	0	22
27301	EL GRAMILLAR	4187	0	22
27302	EL PALOMAR	4186	0	22
27303	EL RINCON	4184	0	22
27304	ENSENADA	4187	0	22
27305	HUTURUNGO	4184	0	22
27306	LOS NU	4201	0	22
27307	TUNAS PUNCO	4203	0	22
27308	ISCA YACU	4184	0	22
27309	LOS QUIROGA	4201	0	22
27311	PORTALIS	5257	0	22
27312	VILLA MERCEDES	4189	0	22
27313	ISLA MOTA	4187	0	22
27314	LA MARAVILLA	4187	0	22
27315	LA MELADA	4187	0	22
27316	LAS CEJAS	4184	0	22
27317	POZO DEL MONTE	5257	0	22
27318	LAS TIGRERAS	4304	0	22
27319	LOS QUEBRACHOS	4304	0	22
27320	MANOGASTA	4201	0	22
27321	PRIMAVERA	5255	0	22
27322	YUCHANCITO	4189	0	22
27323	PROGRESO DE JUME	5255	0	22
27324	MIRANDAS	4201	0	22
27325	MONTE CRISTO	4201	0	22
27326	PUESTO DEL MEDIO	5257	0	22
27327	PALMA LARGA	4176	0	22
27328	RAMADITA	5257	0	22
27329	RAMI YACU	5257	0	22
27330	POLEO POZO	4306	0	22
27331	AGUA TURBIA	5251	0	22
27332	BAJO LAS PIEDRAS	5251	0	22
27333	RAMIREZ DE VELAZCO	5257	0	22
27334	POZO DEL ARBOLITO	4176	0	22
27335	REMANSOS	5257	0	22
27336	BELGRANO	5253	0	22
27337	CHILCA JULIANA	4319	0	22
27338	RETIRO	5257	0	22
27339	BUENA VISTA	5253	0	22
27340	POZUELOS	4306	0	22
27341	REY VIEJO	5255	0	22
27342	CAJON	5251	0	22
27343	CHIRA	4321	0	22
27344	RIO VIEJO	5253	0	22
27345	SOTELILLOS	4304	0	22
27346	CAMPO RICO	5255	0	22
27347	KILOMETRO 390	4321	0	22
27348	RUMI JACO	5257	0	22
27349	TINCO COLONIA	4221	0	22
27350	CARDAJAL	5257	0	22
27351	LA PALIZA	4321	0	22
27353	VINARA	4223	0	22
27355	LOS CERRILLOS	4319	0	22
27357	CHACRAS	5251	0	22
27361	CHA	5255	0	22
27362	SAN ANDRES	5255	0	22
27363	ISCA YACU SEMAUL	4184	0	22
27364	MALOTA	4321	0	22
27365	CORONEL FERNANDEZ	5255	0	22
27367	CORRAL DE CARCOS	5255	0	22
27368	PUENTE DEL SALADILLO	4319	0	22
27369	CORRAL DEL REY	5255	0	22
27370	CUCHI CORRAL	5255	0	22
27371	SAN FRANCISCO	5253	0	22
27372	EL ABRA	5251	0	22
27373	EL AGUILA	5255	0	22
27374	SAN JORGE	5255	0	22
27375	PUERTA DEL MONTE	5257	0	22
27376	EL ARBOL DE PIEDRA	5255	0	22
27377	EL ARBOLITO	5255	0	22
27378	QUIMILI PASO	4321	0	22
27379	SAN LORENZO	5253	0	22
27380	EL FUERTE	5255	0	22
27381	EL MISTOL	5253	0	22
27383	SAN MARTIN	5253	0	22
27384	EL PARAISO	5255	0	22
27386	EL PILAR	5255	0	22
27387	SABAGASTA	4319	0	22
27388	EL PORVENIR	5255	0	22
27389	VILLA SALAVINA	4319	0	22
27390	KILOMETRO 454	3766	0	22
27391	SAN NICOLAS	5253	0	22
27392	EL PUEBLITO	5257	0	22
27393	VACA HUMAN	4319	0	22
27394	EL UNCO	5255	0	22
27395	SAN RAMON QUEBRACHOS	5255	0	22
27396	KILOMETRO 477	3765	0	22
27397	EL VEINTICINCO	4233	0	22
27398	YACU HURMANA	4321	0	22
27399	SANTA ANA	5251	0	22
27400	KILOMETRO 433	3766	0	22
27401	EL VEINTICINCO  SUMAMPA	5253	0	22
27402	LA LOMA	4354	0	22
27403	LA PAZ	4354	0	22
27404	HORCOS TUCUCUNA	5251	0	22
27405	SANTA BRIGIDA	5257	0	22
27406	LA PETRONILA	4354	0	22
27407	LA BALANZA	3765	0	22
27408	RIO DE GALLO	4354	0	22
27409	SANTA ELENA	5255	0	22
27410	SAN CAYETANO	4354	0	22
27411	SAN MARCOS	4324	0	22
27412	INGENIERO CARLOS CHRISTIERNSON	5257	0	22
27413	SAN VICENTE	4354	0	22
27414	VILLA ISLA	4354	0	22
27415	SANTA MARIA	5257	0	22
27416	VILLA MATARA	4356	0	22
27417	ABRITA	4206	0	22
27418	KILOMETRO 117	4206	0	22
27419	MORALES	4201	0	22
27420	NARANJITO	4201	0	22
27421	OVEJEROS	4201	0	22
27422	POCITOS	4201	0	22
27423	POZO CERCADO	4201	0	22
27424	POZO GRANDE	4201	0	22
27425	PUENTE DEL SALADO	4201	0	22
27426	PUESTO DE DIAZ	4201	0	22
27427	RAMADITAS	4201	0	22
27428	RODEO DE SORIA	4201	0	22
27429	RODEO DE VALDEZ	4201	0	22
27430	SAN ANTONIO	4201	0	22
27431	SAN ANTONIO DE LOS CACERES	4201	0	22
27432	SAN CARLOS	4201	0	22
27433	SAN DIONISIO	4201	0	22
27434	SAN MARTIN	4201	0	22
27435	SAN VICENTE	4206	0	22
27436	SANTA MARIA	4201	0	22
27437	SAUZAL	4201	0	22
27438	SILIPICA	4206	0	22
27439	SIMBOL	4206	0	22
27440	SIMBOL POZO	4201	0	22
27441	SOL DE MAYO	4201	0	22
27442	SUMAMAO	4201	0	22
27443	TIPIRO	4201	0	22
27444	LA HIGUERA	4206	0	22
27445	PUESTO DEL MEDIO	4200	0	22
27446	TORO HUMAN	4201	0	22
27447	VILLA JIMENEZ	4201	0	22
27448	ZANJON	4206	0	22
27449	BARRIO LA LE	3760	0	22
27450	BARRIO VILLA FERNANDEZ	3760	0	22
27451	CORONEL BARROS	3760	0	22
27453	EL TOBIANO	3064	0	22
27454	KILOMETRO 443 TABOADA	3765	0	22
27455	KILOMETRO 499	3752	0	22
27456	LA NENA	3765	0	22
27457	LA RECONQUISTA	3765	0	22
27458	LA SIMONA	3763	0	22
27459	LOS LINARES	3761	0	22
27460	LOTE 15	3760	0	22
27461	LOTE 42	3765	0	22
27462	SANTA ROSA	5257	0	22
27463	MIEL DE PALO	3761	0	22
27464	POZO HERRERA	3761	0	22
27465	PUNI TAJO	3760	0	22
27470	ATOJ POZO	4313	0	22
27473	BARRANCA COLORADA	4313	0	22
27477	BARRIAL ALTO	4313	0	22
27478	SANAVIRONES	3064	0	22
27479	BREA POZO VIEJO	4313	0	22
27480	SANTA ANA	3760	0	22
27481	CAZADORES	4324	0	22
27482	SIMBOL BAJO	3760	0	22
27483	TACA	3766	0	22
27484	CORASPINO	4324	0	22
27485	TOMAS YOUNG	3765	0	22
27486	EL BAJO	4324	0	22
27487	COLONIA PINTO	4313	0	22
27488	3 DE MARZO	3766	0	22
27489	TRES POZOS	3763	0	22
27490	EL PUENTE	4313	0	22
27491	GALLEGOS	4313	0	22
27492	VILLA ABREGU	3760	0	22
27493	LA CA	4313	0	22
27494	PERCHIL BAJO	4313	0	22
27495	PENAL PROVINCIAL	4313	0	22
27496	POZO MORO	4324	0	22
27497	POZO MOSOJ	4324	0	22
27498	ROBLES	4313	0	22
27499	SIEMPRE VERDE	5253	0	22
27501	TABOADA ESTACION	4324	0	22
27502	TACO HUACO	4324	0	22
27503	TACOYOJ	4313	0	22
27504	TALA POZO	4313	0	22
27505	TRES JAZMINES	4313	0	22
27506	VILLA NUEVA	4313	0	22
27507	SUMAMPA VIEJO	5253	0	22
27508	YACANO	4324	0	22
27509	TACO PALTA	5253	0	22
27511	TACO POZO	5255	0	22
27512	TENTI TACO	5255	0	22
27513	BLANCA	4324	0	22
27514	TRONCO QUEMADO	5253	0	22
27515	CACHI	4354	0	22
27516	VILLA QUEBRACHOS	5251	0	22
27517	CAMPO DEL CISNE	5255	0	22
27518	CANDELARIA	4354	0	22
27519	WI	5251	0	22
27520	CONCEPCION	4324	0	22
27521	YLUMAMPA	5250	0	22
27522	ACOS	4176	0	22
27523	EL CUELLO	4354	0	22
27524	AMICHA	4225	0	22
27525	EL EMPACHADO	4324	0	22
27526	LAS FLORES	4203	0	22
27527	MARCOS PAZ	1727	0	1
27528	MISION FRANCISCANA	4530	0	17
27529	EL CABRAL	4608	0	10
27530	EL ALGARROBAL	4448	0	17
27531	CHIVILCOY	6620	0	1
27532	RUMIHUASI	4419	0	17
27534	FINCA LA CHINA	4434	0	17
27535	MERCEDES	6600	0	1
27537	FRIAS	4230	0	22
27538	GUAMPACHA	4203	0	22
27539	ISLA MARTIN GARCIA	1601	0	1
27540	RIOS DE LOS COLCOLES	5385	0	12
27541	RIOS DE LAS MESADAS	5385	0	12
27542	GENERAL ROJO	2905	0	1
27543	VACA PASO	3461	0	7
27545	BELGRANO	3313	0	14
27546	CUARTA SECCION LOMAS	3461	0	7
27547	VILLA INTA	3313	0	14
27549	CAMPO SAN JUAN	3313	0	14
27550	ADOLFO J POMAR	3337	0	14
27551	FRIGO	3337	0	14
27552	MILAGRO	3337	0	14
27553	DORADITO	3337	0	14
27554	LOMA PORA	3337	0	14
27555	LAS FLORES	3338	0	14
27556	2 DE ABRIL	3338	0	14
27557	MARIANO MORENO	3338	0	14
27558	MANUEL BELGRANO	3338	0	14
27559	RINCON QUIROZ	3461	0	7
27560	EL LAPACHO	3338	0	14
27561	PICADA MANDARINA	3338	0	14
27562	KM 18	3338	0	14
27563	LECHUZA	3338	0	14
27564	17 DE AGOSTO	3338	0	14
27565	FRAY LUIS BELTRAN	3338	0	14
27566	VIRGEN DE LOURDES	3338	0	14
27567	LA BONITA	3338	0	14
27568	ITA PASO	3483	0	7
27569	COSTA CENISAL	3483	0	7
27570	COLONIA MOTA	3226	0	7
27571	FRAGA CUE	3353	0	14
27572	LAS BANANERAS	3353	0	14
27573	PIEDRITAS	3226	0	7
27575	LAS MANDARINAS	3353	0	14
27577	BUENA VISTA	3226	0	7
27578	LA VENTA	3226	0	7
27579	INDUMAR	3337	0	14
27580	INTEGRACION	3337	0	14
27581	JUAN DOMINGO PERON	3337	0	14
27582	SOL NACIENTE	3337	0	14
27583	CARRIL DE ANTA	3337	0	14
27584	RINCON	3409	0	7
27585	CASCUDA	3337	0	14
27586	LAPACHO	3337	0	14
27587	SAN JUAN	3409	0	7
27588	KM1228	3337	0	14
27589	KM 1230	3337	0	14
27590	KM 1246	3337	0	14
27591	KM 1247	3337	0	14
27593	JULUMAO	4740	0	3
27594	ZONA DELTA TIGRE	1649	0	1
27595	COSTA DEL ESTE	7108	0	1
27596	FINCA LA DOROTEA	5012	0	6
27597	CORONEL OLMEDO	5014	0	6
27598	ZONA DELTA ZARATE	2800	0	1
27599	ZONA DELTA CAMPANA	2804	0	1
27600	ZONA DELTA GUALEGUAYCHU	2820	0	8
27601	PACHECO DE MELO	6121	0	6
27602	NORDELTA	1670	0	1
27603	EL CHELFORO	7530	0	1
27614	LA PUNTA	5710	0	19
27615	PARAJE LA BAJADA	4300	0	22
27616	LA RIBERA	5734	0	19
27617	ANTINACO	5341	0	3
27618	SANTA LUCIA	5380	0	12
27619	AGUA DE CASTILLA	4651	0	10
27620	BELLA VISTA	4715	0	3
27621	SAN PEDRO DE SAN ALBERTO	5871	0	6
27624	VILLA SARMIENTO	3514	0	4
27625	LOS AGUDOS	4152	0	24
27626	EL POTRILLO	3636	0	9
27627	BASE CIENTIFICA TTE JUBANY	9411	0	23
27628	BASE ORCADAS	9411	0	23
27629	BASE BELGRANO 2	9411	0	23
27630	JUAREZ CELMAN	5145	0	6
27631	ISLAS SANDWICH DEL SUR	9411	0	23
27632	RAMON M CASTRO	8340	0	15
27633	OCTAVIO PICO	8319	0	15
27634	LA REFORMA	8201	0	11
27635	LAGUNA QUIROGA	8201	0	11
27636	MINAS CAPILLITAS	4740	0	3
27637	ONAGOITY	6227	0	6
27638	COLONIA 10 DE JULIO	2349	0	6
27639	LORO HUASI	4139	0	3
27640	LAMPASITO	4139	0	3
27641	LA VICTORIA	5231	0	6
27642	SAN AGUSTIN	3196	0	7
27643	LA LAGUNILLA	5825	0	6
27644	VILLA ERRECABORDE	3350	0	14
27645	VILLA ORTIZ PEREIRA	3358	0	14
27646	LA SANGA	4622	0	10
27647	EL DESCANSO	2434	0	6
27648	LA CORTADERA	2434	0	6
27649	PALMAR	3481	0	7
27650	CARRIZAL	5361	0	12
27651	SAN JOSE	3407	0	7
27652	SAN JOSE	3302	0	7
27653	COLONIA PUEBLO VIEJO	3531	0	4
27654	PUNTA DE AGUA	5345	0	3
27655	LOS OVEJEROS	4220	0	22
27657	VILLA VENTANA	8160	1	1
27658	COLONIA TA	3733	0	4
27659	COLONIA QUEBRACHALES	3733	0	4
27660	LA LEONOR	1814	0	1
27661	PARAJE FRA PAL	7530	0	1
27662	PARAJE SANTA ANA	7540	0	1
27663	SAN JOSE	3016	0	21
27664	PI	2119	0	21
27666	CRUZ DE CA	5287	0	6
27667	CIENAGA DE BRITOS	5297	0	6
27668	PUESTO EL ABRA	5284	0	6
27669	VILLA BERNA	5194	0	6
27670	VILLA ELISA	2594	0	6
27671	LAS JARILLAS	5871	0	6
27672	EL MEDANITO	5871	0	6
27673	SAN JERONIMO	5297	0	6
27675	LAS ALBAHACAS	5801	0	6
27677	MONTE DEL ROSARIO	5129	0	6
27678	LOS TALARES	5299	0	6
27680	ESTANCIA VIEJA	5152	0	6
27681	DESVIO EL VOLCAN	5299	0	6
27682	SAUCE ARRIBA	5871	0	6
27683	LOS CEDROS	5101	0	6
27684	COLONIA LAS PICHANAS	2433	0	6
27685	LA TOMA	5244	0	6
27686	EL BA	5244	0	6
27687	POZO NUEVO	5209	0	6
27688	VILLA LOS PATOS	2551	0	6
27689	LA CONCEPCION	5281	0	6
27690	VILLA localidades PQUE LOS REARTES	5189	0	6
27691	LOS AMAYA	4174	0	24
27692	EL TIMBO VIEJO	4101	0	24
27693	COLONIA 4	4178	0	24
27694	CUATRO BOCAS	3061	0	22
27695	AHI VEREMOS	4452	0	22
27696	TOTORILLAS	4301	0	22
27697	EL ARENAL	4187	0	22
27698	SAN JOSE	4313	0	22
27699	REMEDIOS DE ESCALADA	4313	0	22
27700	VILLA NUEVA	4313	0	22
27701	VILLA VIEJA	4313	0	22
27702	ALBARDON	5253	0	22
27703	LOMA BLANCA	4321	0	22
27704	NUEVO LIBANO	4300	0	22
27705	TAPSO	4230	0	22
27706	VILLA RIVADAVIA	4233	0	22
27707	PALMITAS DE JEREZ	4301	0	22
27708	TRAMO 26	4300	0	22
27709	ISOQUI	3346	0	7
27710	COLONIA JUAN B CABRAL	3420	0	7
27712	JUAN DIAZ	3449	0	7
27713	CAMPO GRANDE	3401	0	7
27714	IBIRAY	3414	0	7
27715	OBISPO ZAPATA	5419	0	18
27716	CURA CO	8353	0	15
27717	HUANTRAICO	8353	0	15
27718	MALLIN DE LOS CABALLOS	8340	0	15
27719	LA PICAZA	8340	0	15
27720	LAGO PULMARI	8345	0	15
27721	LAGO 	8345	0	15
27722	COLLON CURA	8375	0	15
27724	QUEMQUEMTREU	8375	0	15
27725	ATREUCO	8371	0	15
27726	VILLA RINCON CHICO	8315	0	15
27727	MEDIA LUNA	8341	0	15
27729	SIERRA DE LOS QUINTEROS	5385	0	12
27730	QUEBRADA DE LOS CONDORES	5385	0	12
27731	SAN RAMON	5385	0	12
27732	EL RETAMAL	5385	0	12
27733	SAN ISIDRO	5471	0	12
27734	SANTA CRUZ	5471	0	12
27735	PUERTA DE CORRAL QUEMADO	4751	0	3
27736	SAN PEDRO	4723	0	3
27737	LAGUNA BLANCA	8417	0	16
27738	CUBANEA	8501	0	16
27739	LAS ISLETAS	5730	0	19
27740	LOMAS BLANCAS	5719	0	19
27741	CHIPISCU	5719	0	19
27742	LA ESQUINA	5759	0	19
27743	SAN JOSE DEL MORRO	5731	0	19
27745	PICHI MAHUIDA	8214	0	11
27746	COSTA URUGUAY NORTE	2821	0	8
27747	COLONIA BERTOZZI	3192	0	8
27748	COLONIA LA MARTA	3185	0	8
27749	TATUTI	3229	0	8
27750	COLONIA NUEVA NORTE	3265	0	8
27751	COLONIA NUEVA SUR	3265	0	8
27752	COLONIA 1 DE MAYO	3265	0	8
27753	ESTANCIA GRANDE	3201	0	8
27754	ISLETAS	3164	0	8
27755	ISLETAS NORTE	3164	0	8
27756	CA	3228	0	8
27757	COLONIA AYLMAN	3228	0	8
27758	COLONIA SAN LORENZO	3181	0	8
27759	EL GATO	3180	0	8
27760	LAMBARE	2841	0	8
27761	LAS COLONIAS	3254	0	8
27762	PUEBLO PRIMERO	3174	0	8
27763	CORRALES	3151	0	8
27764	COLONIA ADIVINOS	3142	0	8
27765	PUEBLO ILLIA	3337	0	14
27766	CAA YARI	3315	0	14
27767	COLONIA LA NUEVA	3364	0	14
27768	LA FLOR	3364	0	14
27769	COLONIA APARECIDA	3363	0	14
27770	COLONIA GENERAL PAZ	3530	0	4
27771	COLONIA LEANDRO N ALEM	3534	0	4
27772	LOTE 18 POZO COLORADO	3545	0	4
27773	ISLA GRAL BELGRANO	3610	0	9
27774	POSTA SANTA FE	3630	0	9
27775	PUNTA DE AGUA	3630	0	9
27776	PESCADO NEGRO	3636	0	9
27777	COLONIA EL RINCON	3601	0	9
27778	COLONIA JOSE M PAZ	3613	0	9
27779	EL RECODO	3611	0	9
27780	EL TUCUMANCITO	3636	0	9
27781	MISION EL QUEBRACHO	3636	0	9
27782	LAS PAJAS	7150	0	1
27783	EL BOQUERON	7150	0	1
27784	LA VERDE	7214	0	1
27785	CUARTEL II	7300	0	1
27786	LOS CHUCAROS	7263	0	1
27787	LA UNION	7160	0	1
27788	DANTAS	1987	0	1
27789	CUARTEL VII	6050	0	1
27791	CAMPO MAIPU	6013	0	1
27792	CUARTEL IV	6032	0	1
27793	CUARTEL V	6000	0	1
27794	EL CHAGUARAL	4500	0	10
27795	EL TURBIO	9210	0	5
27796	MISION SALESIANA M	9420	0	23
27797	COLONIA 4 DE COLOMBRES	4178	0	24
27798	SAN ALBERTO	7620	0	1
27799	EL CRUCE	7620	0	1
27800	PASO MARTINEZ	3401	0	7
27803	SAN IGNACIO	5250	0	22
27805	SAN IGNACIO P BLANCA	5258	0	22
27806	EL ESPINAL	4126	0	17
27807	LA MESADA GRANDE	4633	0	17
27808	LA MESADA CHICA	4633	0	17
27809	LAS VERTIENTES	4561	0	17
27810	SAN BERNARDO DE LAS ZORRAS	4409	0	17
27811	ABRA DE ARAGUYOC	4633	0	17
27816	ALTO LOS CARDALES	2814	0	1
27817	COLONIA EL SAUZAL	8201	0	11
27818	CASA DE PIEDRA	8201	0	11
27819	COLONIA CHICA	8201	0	11
27820	CERRO AGUA CALIENTE	4641	0	10
27821	AGUAS CALIENTES	4518	0	10
27822	ZONA CANGREJALES	8103	0	1
27823	EL ESTANQUITO	5301	0	12
27827	ALDEA SAN ANTONIO	3117	0	8
27828	LOS CEIBOS	3261	0	8
27829	DIQUE CHICO	5189	0	6
27830	COLAN CONHUE	8418	0	16
27831	SANTA MARIA NORTE	3011	0	21
27832	COLONIA TUNAS	3185	0	8
27833	SAN ROQUE	3228	0	8
27834	DIEGO LOPEZ	3180	0	8
27835	LOMA LIMPIA	3188	0	8
27836	PASO DUARTE	3181	0	8
27837	SANTA LUCIA	3183	0	8
27838	LAGUNA BENITEZ	3183	0	8
27839	MULAS GRANDES	3187	0	8
27840	ARROYO CLE	2841	0	8
27841	MONTE REDONDO	2840	0	8
27842	ESTAQUITAS	3191	0	8
27843	ESTACION RAICES	3241	0	8
27844	PICADA BERON	3190	0	8
27845	ARROYO CORRALITO	3122	0	8
27846	ARROYO PALO SECO	3133	0	8
27847	ARROYO MATURRANGO	3133	0	8
27848	CORANZULI	4643	0	10
27849	GENERAL URQUIZA	3326	0	14
27850	AGUADA SAN ROQUE	8305	0	15
27851	LA POSTA	7153	0	1
27852	SAN ANDRES	6551	0	1
27853	CUARTEL IV	7110	0	1
27854	SABBI	7303	0	1
27855	COSTA DEL TOBA	3553	0	21
27856	CANDELARIA	4231	0	3
27857	LAS VEGAS	5549	0	13
3029	JUAN A PRADERE	8142	0	1
3175	HUANGUELEN	7545	0	1
4421	DARREGUEIRA	8183	0	1
4445	VILLA IRIS	8126	0	1
4610	DUFAUR	8164	0	1
4611	ESPARTILLAR	8171	0	1
4937	ALGARROBO	8136	0	1
7689	CHOS MALAL	8353	1	15
7941	COCHICO	8347	1	15
7944	COLI MALAL	8351	1	15
7957	LAS LAJAS	8347	1	15
7702	LOS MENUCOS	8353	1	15
7755	NEUQUEN	8300	1	15
7929	PICUN LEUFU	8313	1	15
7726	PIEDRA DEL AGUILA	8315	1	15
7984	VACA MUERTA	8351	1	15
7858	VILLA LA ANGOSTURA	8407	1	15
8017	ZAPALA	8340	1	15
\.


--
-- Data for Name: materiales; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.materiales (id, descripcion, unidad, stock_minimo, ean_13, cantidad_uni_compra, peso_uni_compra, estado, fecha_baja) FROM stdin;
1	Ladrillos	uni	500.00	\N	10000.00	\N	0	\N
\.


--
-- Data for Name: monedas; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.monedas (id, denominacion, codigo_afip, estado, simbolo) FROM stdin;
3	Euro	060       	1	&euro
1	Peso	PES       	0	$
2	Dólar	DOL       	0	U$S
\.


--
-- Data for Name: movimientos_bancarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.movimientos_bancarios (id, fecha, importe, cuenta_bancaria_id, tipo_movimiento_caja_id, cuenta_corriente_id, estado, moneda_id, cotizacion_divisa, importe_divisa, numero, comentario) FROM stdin;
\.


--
-- Data for Name: movimientos_cheques; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.movimientos_cheques (id, cuenta_corriente_caja_id, banco_id, fecha_emision, fecha_acreditacion, importe, cotizacion, chequera_id, estado, serie, numero, moneda_id) FROM stdin;
\.


--
-- Data for Name: permisos; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.permisos (id, denominacion, estado) FROM stdin;
\.


--
-- Data for Name: permisos_usuarios; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.permisos_usuarios (id, usuario_id, permiso_id, estado) FROM stdin;
\.


--
-- Data for Name: presupuestos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.presupuestos (id, fecha_inicio, fecha_final, comentario, importe_inicial, importe_final, entidad_id, proyecto_id, titulo, estado, moneda_id) FROM stdin;
2	2024-05-01	2024-05-01		1500000.00	1500000.00	73	4	Porton	0	1
1	2024-04-21	2024-04-21	ccccccccccccccccccc	12345678.00	12345678.00	62	3	qqqqqqqqqqqqqq	1	1
\.


--
-- Data for Name: provincias; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.provincias (id, nombre) FROM stdin;
1	Buenos Aires
2	Capital Federal
3	Catamarca
4	Chaco
5	Chubut
6	Córdoba
7	Corrientes
8	Entre Ríos
9	Formosa
10	Jujuy
11	La Pampa
12	La Rioja
13	Mendoza
14	Misiones
15	Neuquén
16	Río Negro
17	Salta
18	San Juan
19	San Luis
20	Santa Cruz
21	Santa Fé
22	Santiago del Estero
23	Tierra del Fuego
24	Tucumán
\.


--
-- Data for Name: proyectos; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.proyectos (id, nombre, caracteristicas, fecha_inicio, fecha_finalizacion, comentario, calle, numero, localidad_id, tipo_proyecto_id, tipo_obra_id, estado, fecha_baja) FROM stdin;
3	Fideicomiso Rhodas	\N	2020-08-14	2024-12-31		Rodriguez	340	16353	1	1	0	\N
1	Proyecto 1	\N	2021-12-01	\N		xxxxxxxx	11111	16353	5	1	1	\N
2	Proyecto 2	\N	2022-12-01	\N		zzzz	333	16353	4	1	1	\N
6	Fideicomiso Avenida Argentina	\N	\N	\N				4126	1	1	0	\N
7	Fideicomiso Costanera MH	\N	\N	\N				4126	1	1	0	\N
4	Fideicomiso Islas Malvinas	\N	2019-01-07	2024-03-06		Islas Malvinas	920	7755	1	1	0	\N
5	Fideicomiso Rio Desaguadero	\N	2022-11-17	2025-10-20		Rio desaguadero 	597	7755	1	1	0	\N
8	Dario Perrone	\N	\N	\N				16353	1	1	0	\N
\.


--
-- Data for Name: proyectos_entidades; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.proyectos_entidades (id, entidad_id, proyecto_id, estado, fecha_baja) FROM stdin;
1	2	1	0	\N
2	1	1	0	\N
3	3	2	0	\N
4	2	2	0	\N
5	7	2	0	\N
8	4	1	0	\N
9	7	1	0	\N
10	6	1	0	\N
11	4	2	0	\N
12	6	2	0	\N
13	4	3	1	\N
14	10	3	1	\N
15	11	3	0	\N
16	12	3	0	\N
17	27	3	0	\N
18	13	3	0	\N
19	39	3	1	\N
20	48	3	1	\N
21	25	3	0	\N
22	14	3	0	\N
23	15	3	0	\N
24	17	3	0	\N
25	18	3	0	\N
26	19	3	0	\N
27	21	3	0	\N
28	23	3	0	\N
29	22	3	0	\N
30	26	3	0	\N
31	30	4	0	\N
32	35	4	0	\N
33	32	4	0	\N
34	31	4	0	\N
35	37	4	0	\N
36	11	4	0	\N
37	29	4	0	\N
38	36	4	0	\N
39	34	4	0	\N
40	39	5	0	\N
41	28	3	0	\N
42	24	3	0	\N
43	104	4	0	\N
44	107	3	0	\N
45	34	3	0	\N
46	38	5	0	\N
47	40	5	0	\N
48	41	5	0	\N
49	42	5	0	\N
50	105	5	0	\N
51	30	5	0	\N
52	45	5	0	\N
53	36	5	0	\N
54	29	5	0	\N
55	47	5	0	\N
56	48	5	0	\N
57	106	5	0	\N
58	50	5	0	\N
59	11	5	0	\N
60	51	5	0	\N
61	34	5	0	\N
62	109	5	0	\N
63	108	5	0	\N
64	39	4	0	\N
\.


--
-- Data for Name: proyectos_tipos_propiedades; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.proyectos_tipos_propiedades (id, cantidad, tipo_propiedad_id, proyecto_id, comentario, estado, coeficiente, fecha_baja) FROM stdin;
9	\N	1	3		1	\N	\N
10	\N	6	3		1	1.0000	\N
12	\N	1	3		1	100.0000	\N
11	\N	6	3		1	100.0000	\N
13	\N	1	3		1	100.0000	\N
14	\N	1	3		1	100.0000	\N
46	\N	15	4	Orio SA	0	1.0000	\N
17	\N	12	3		1	10.0000	\N
47	\N	15	4	Rubenacker Alexis	0	1.0000	\N
48	\N	15	4	Sardi Ricardo	0	1.0000	\N
49	\N	1	5		0	\N	\N
19	\N	11	3		1	5.0000	\N
51	\N	9	5	Colombero Gabriel	0	1.0000	\N
50	\N	9	5	Alterio Juan Carlos	0	1.0000	\N
30	\N	1	3	Pirola Gabriel 7 B	1	5.0000	\N
52	\N	8	5	Comobero Adriana	0	1.0000	\N
26	\N	11	3	Ferrero Monica Sandra	1	5.0000	\N
53	\N	9	5	Neschenko Paola	0	1.0000	\N
1	\N	1	1		1	\N	\N
6	\N	1	2		1	100.0000	\N
2	\N	2	1	1er	1	\N	\N
3	\N	2	1	2do	1	\N	\N
5	\N	3	1	2do	1	\N	\N
4	\N	3	1	1er	1	\N	\N
8	\N	5	2	Segunda oficina	1	50.0000	\N
7	\N	5	2	Primera oficina	1	50.0000	\N
54	\N	9	5	Laco Leandro 	0	1.0000	\N
55	\N	8	5	Amaolo Sofia	0	1.0000	\N
56	\N	8	5	Rubenacker Alexis	0	1.0000	\N
57	\N	9	5	Rubenacker Alexis	0	1.0000	\N
58	\N	8	5	Fardighini Federico	0	1.0000	\N
29	\N	11	3	Pirola Heber Gabriel	1	5.0000	\N
59	\N	9	5	Fardighini Federico	0	1.0000	\N
34	\N	12	3	Ramos Lionel	1	10.0000	\N
60	\N	8	5	Ferraris Roberto	0	1.0000	\N
61	\N	9	5	Ferraris Roberto	0	1.0000	\N
15	\N	14	3	Atuns	0	1.0000	\N
16	\N	11	3	Promar 2 A	0	1.0000	\N
18	\N	12	3	Ramos Lionel- Bellegia Sandra Edith	0	2.0000	\N
20	\N	11	3	Franz Pablo Bruno - 3 A	0	1.0000	\N
21	\N	11	3	Ramos Marcelo 8 A	0	1.0000	\N
22	\N	11	3	Ramos Marcelo 8 B	0	1.0000	\N
23	\N	11	3	Manceñido Buide Daiana	0	1.0000	\N
24	\N	11	3	Schneider Jorge Eduardo	0	1.0000	\N
25	\N	11	3	Randone Claudio Fabian- Ferrero Sandra Monica	0	1.0000	\N
27	\N	11	3	Petz Dario Hernan	0	1.0000	\N
28	\N	11	3	Tamone Miguel Angel	0	1.0000	\N
31	\N	11	3	Pirola - Paoloni 7 B	0	1.0000	\N
32	\N	11	3	Petz Enrique Fabricio	0	1.0000	\N
33	\N	11	3	Promar 5 A	0	1.0000	\N
36	\N	11	3	Franz Pablo Bruno - 6 A	0	1.0000	\N
37	\N	11	3	Grioli Roberto	0	1.0000	\N
38	\N	11	3	Perrone Dario - 9 A	0	1.0000	\N
39	\N	11	3	Perrone Dario - 2 B	0	1.0000	\N
62	\N	8	5	Benedictino	0	1.0000	\N
35	\N	15	4	Dahir	0	1.0000	\N
41	\N	16	4	Benedictino SA	0	0.5000	\N
42	\N	17	4	Perrone Dario	0	0.5000	\N
43	\N	15	4	Ferraris Roberto	0	1.0000	\N
44	\N	15	4	Malan Juan Pablo	0	1.0000	\N
45	\N	15	4	Matarazzo Antonio	0	1.0000	\N
63	\N	9	5	Benedictino	0	1.0000	\N
64	\N	8	5	Benedictino	0	1.0000	\N
65	\N	7	5	Benedictino	0	1.0000	\N
66	\N	8	5	Diaz Javier	0	1.0000	\N
67	\N	9	5	Garcia Adrian	0	1.0000	\N
68	\N	8	5	Sgallippa Karina	0	1.0000	\N
69	\N	9	5	Lascas SRL	0	1.0000	\N
70	\N	8	5	Iribas Rafael	0	1.0000	\N
71	\N	9	5	Pugliese Constanza	0	1.0000	\N
72	\N	8	5	Promar	0	1.0000	\N
73	\N	8	5	Promar	0	1.0000	\N
74	\N	9	5	Promar	0	1.0000	\N
75	\N	9	5	Promar	0	1.0000	\N
76	\N	8	5	Pocai Gabriel	0	1.0000	\N
77	\N	9	5	Pocai Gabriel	0	1.0000	\N
78	\N	8	5	Perrone Dario	0	1.0000	\N
79	\N	9	5	Perrone Dario	0	1.0000	\N
40	\N	11	3	Perrone Dario -1 B	0	1.0000	\N
80	\N	15	4	Promar SRL	0	1.0000	\N
\.


--
-- Data for Name: relacion_ctas_ctes; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.relacion_ctas_ctes (id, cuenta_corriente_id, relacion_id, estado, fecha, importe_divisa, monto_divisa, monto_pesos, fecha_baja) FROM stdin;
263	746	747	1	2024-04-11 10:26:27.495637	0.00	0.00	377819.44	2024-04-11 10:58:11.248068
264	746	749	0	2024-04-11 10:58:11.25741	0.00	0.00	16470.46	\N
265	746	748	0	2024-04-11 10:58:11.260404	0.00	0.00	87340.52	\N
266	746	747	0	2024-04-11 10:58:11.262977	0.00	0.00	377819.44	\N
267	753	754	0	2024-04-11 12:37:09.506619	0.00	0.00	679200.00	\N
268	758	759	0	2024-04-11 13:30:53.289959	0.00	0.00	200000.00	\N
269	760	761	0	2024-04-11 13:32:36.864302	0.00	0.00	400000.00	\N
270	762	763	0	2024-04-11 13:34:20.805553	0.00	0.00	350000.00	\N
271	764	765	0	2024-04-11 13:35:54.215369	0.00	0.00	200000.00	\N
272	766	767	0	2024-04-11 14:58:06.122964	0.00	0.00	168000.00	\N
273	770	771	0	2024-04-12 09:48:57.915363	0.00	0.00	246277.98	\N
274	787	788	0	2024-04-16 14:55:12.966744	0.00	0.00	600000.00	\N
275	789	790	0	2024-04-16 15:08:41.801838	0.00	0.00	29000.00	\N
276	794	796	1	2024-04-18 12:25:27.814843	0.00	0.00	64000.00	2024-04-18 12:29:59.950415
277	795	797	1	2024-04-18 12:28:01.325708	0.00	0.00	268848.53	2024-04-18 12:29:59.950415
278	795	797	0	2024-04-18 12:29:59.964689	0.00	0.00	272000.00	\N
279	794	796	0	2024-04-18 12:29:59.967842	0.00	0.00	64000.00	\N
280	799	800	1	2024-04-18 13:33:52.951878	0.00	0.00	160717.60	2024-04-18 13:35:23.838556
281	799	800	0	2024-04-18 13:35:23.848596	0.00	0.00	162309.99	\N
282	803	804	0	2024-05-06 09:53:36.984057	0.00	0.00	200000.00	\N
283	809	810	0	2024-05-10 09:58:01.737074	0.00	0.00	500000.00	\N
\.


--
-- Data for Name: relacion_presu_ctactes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.relacion_presu_ctactes (id, cuenta_corriente_id, presupuesto_id, estado) FROM stdin;
2	803	2	0
\.


--
-- Data for Name: tipos_comprobantes; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.tipos_comprobantes (id, descripcion, signo, abreviado, numero, estado, afecta_caja, tipos_entidad, modelo, concepto, aplica_impu, signo_en_caja, fecha_baja, template) FROM stdin;
5	Débito varios inversor	1	DEB.VARIOS INVERSOR	3	0	0	{"tipos_entidad":["1"]}	2	1	1	0	\N	\N
10	Extracción administrador	1	EXTRACCION ADM	2	1	1	{"tipos_entidad":["4"]}	5	1	1	0	\N	\N
11	Aporte administrador	1	APORTE ADM	1	1	1	{"tipos_entidad":["4"]}	2	1	1	0	\N	\N
6	Débito terreno inversor	1	DEB.TERRENO INVERSOR	60	0	0	{"tipos_entidad":["1"]}	2	2	1	0	\N	\N
7	Débito materiales inversor	1	DEB.MATERIALES INVERSOR	26	0	0	{"tipos_entidad":["1"]}	2	3	1	0	\N	\N
3	Nota crédito proveedor	1	N.CRED.PROVEEDOR	11	0	0	{"tipos_entidad":["2"]}	3	1	1	0	\N	\N
12	Factura proveedor sin impu	-1	FAC.PROVEE.SIN APLIC.	56	0	0	{"tipos_entidad":["2"]}	1	1	0	0	\N	\N
2	Nota débito proveedor ajuste	-1	N.DEB.PROVEEDOR AJUS.	5	1	0	{"tipos_entidad":["2"]}	2	1	1	0	2024-05-07 09:27:58.593884	\N
13	Recibo por préstamo	-1	RECIBO PRESTAMO	6	0	1	{"tipos_entidad":["3"]}	4	1	1	0	\N	\N
15	Ingreso por préstamo	-1	INGRESO PRESTAMO	0	1	1	{"tipos_entidad":["3"]}	1	1	1	0	2024-03-23 19:45:40.198576	\N
9	Recibo pago inversor	-1	RECIBO PAGO INVERSOR	164	0	1	{"tipos_entidad":["1"]}	4	1	1	1	\N	\N
1	Factura proveedor	-1	FACT.PROVEEDOR	84	0	0	{"tipos_entidad":["2"]}	1	1	1	0	\N	\N
14	Orden de pago por préstamo	1	ORDEN PAGO PRESTAMO	3	0	1	{"tipos_entidad":["3"]}	5	1	1	0	\N	\N
4	Orden de pago proveedor	1	ORD.PAGO.PROVEEDOR	162	0	1	{"tipos_entidad":["2"]}	5	1	1	-1	\N	\N
8	Débito obra inversor	1	DEB.OBRA INVERSOR	220	0	0	{"tipos_entidad":["1"]}	2	4	1	0	\N	\N
\.


--
-- Data for Name: tipos_entidades; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.tipos_entidades (id, denominacion, estado) FROM stdin;
2	Proveedor	0
1	Inversor	0
4	Administrador	1
3	Prestamista	0
\.


--
-- Data for Name: tipos_movimientos_caja; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.tipos_movimientos_caja (id, descripcion, signo, estado, gestiona_cheques, gestiona_ctas_bancarias, movimiento, orden, afec_enti, e_chq, gestiona_banco, mov_en_banco, txt_info_caja, mov_internos, entre_proyectos, pide_proyectos, tipo_mov, fidei_act_c_impu, fidei_act_s_impu, fidei_otr_c_impu, fidei_otr_s_impu, chq_a_depo) FROM stdin;
3	Tarjetas	1	1	0	1		0	\N	0	1	0	Tarjetas	0	0	0	0	0	0	0	0	0
1	Retenciones sufridas	1	0	0	0	E	11	1	0	0	0	Retenciones sufridas	0	0	0	0	0	0	0	0	0
2	Pagare emitido	1	1	0	0		0	\N	0	0	0	Pagare	0	0	0	0	0	0	0	0	0
4	Pagare recibido	1	1	0	0		0	\N	0	0	0	Pagare 	0	0	0	0	0	0	0	0	0
5	EChqs pago diferido recibidos	1	1	1	0		0	1,3	1	1	0	EChqs pago diferido	0	0	0	0	0	0	0	0	0
6	Chqs pago diferido recibidos	1	1	1	0		0	1,3	0	1	0	Chqs pago diferido 	0	0	0	0	0	0	0	0	0
7	EChqs pago diferido emitidos	1	1	1	1		0	1,2,3	1	1	0	EChqs pago diferido	0	0	0	0	0	0	0	0	0
8	Chqs pago diferido emitidos	1	1	1	1		0	1,2,3	0	1	0	Chqs pago diferido	0	0	0	0	0	0	0	0	0
16	Cobro por banco	1	0	0	1	E	8	1,3	0	1	2	Cobro por banco	0	0	0	6	0	0	0	0	0
14	Chqs. prop.emitidos	1	1	1	1	S	6	2	0	1	2	Chqs. prop.	0	0	0	4	0	0	0	0	0
15	EChqs.prop.emitidos	1	1	1	1	S	7	2	1	1	2	EChqs.prop.	0	0	0	5	0	0	0	0	0
17	Pago por banco	1	0	0	1	S	9	2	0	1	2	Pago por banco	0	0	0	6	1	0	0	0	0
19	Efectivo retiro	-1	1	0	1	X	1	1,2,3	0	1	1	Efectivo	0	0	0	1	1	1	1	1	0
25	Retenciones de ganancias realizadas	1	0	0	0	S	11	2	0	0	4	Reten.ganan.realizadas	0	0	0	8	1	0	0	0	0
26	Retenciones de ganancias realizadas otros proyectos	1	0	0	0	S	11	2	0	0	4	Reten.ganan.realiz. o/proy.	0	0	1	8	0	0	1	0	0
27	Canje	1	0	0	0	X	12	2	0	0	5	Canje	1	1	0	9	1	1	1	1	0
29	Retenciones IIBB realizadas otros proyectos	1	0	0	0	S	11	2	0	0	4	Reten IIBB realiz. o/proy.	0	0	1	8	0	0	1	0	0
18	Gastos bancarios	1	1	0	1	E	10	\N	0	1	6	Gastos bancarios	0	0	0	7	0	0	0	0	0
30	Cobro por banco otras cuentas	1	0	0	1	E	9	2	0	1	2	Cobro  por banco otras cuentas	0	1	0	6	0	0	1	0	0
24	Pago por banco otras cuentas	1	0	0	1	S	9	2	0	1	2	Pago por banco otras cuentas	0	1	0	6	1	0	1	0	0
9	Efectivo	1	0	0	0	X	1	1,2,3	0	1	1	Efectivo	1	0	0	1	1	1	1	1	0
10	Chqs. 3ro.recibidos	1	0	1	0	E	2	1,3	0	1	0	Chqs. 3ro.	0	0	0	2	0	1	0	1	0
11	EChqs.3ro.recibidos	1	0	1	0	E	3	1,3	1	1	0	EChqs.3ro.	0	0	0	3	0	1	0	1	0
12	Chqs. 3ro.disponibles	1	0	1	0	S	4	2	0	1	1	Chqs. 3ro.	1	0	0	2	0	1	0	1	0
13	EChqs.3ro.disponibles	1	0	1	0	S	5	2	1	1	1	EChqs.3ro.	1	0	0	3	0	1	0	1	0
20	Chqs.3ro.recibidos a depositar	1	0	1	0	E	2	1,3	0	1	0	Chqs.3ro a depo.	0	0	0	2	1	0	1	0	1
21	EChqs.3ros.recibidos a depositar	1	0	1	0	E	3	1,3	0	1	0	EChqs.3ro a depo.	0	0	0	3	1	0	1	0	1
31	Chqs.3ro.disponibles a depositar	1	0	1	0	S	4	2	0	1	1	Chqs.3ro.a depositar	0	0	0	2	1	0	1	0	1
32	EChqs.3ro.disponibles a depositar	1	0	1	0	S	5	2	1	1	1	EChqs.3ro.a depositar	0	0	0	3	1	0	1	0	1
28	Retenciones de IIBB realizadas\n	1	0	0	0	S	11	2	0	0	4	Reten.IIBB realizadas	0	0	0	8	1	0	0	0	0
22	Chqs.prop.emitidos otras cuentas	1	0	1	1	S	6	2	0	1	2	Chqs.prop.otras ctas.	0	1	0	2	1	0	1	0	0
23	EChqs.prop.emitid.otras cuentas\n	1	0	1	1	S	7	2	1	1	2	EChqs.prop.otras ctas.	0	1	0	3	1	0	1	0	0
\.


--
-- Data for Name: tipos_obras; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.tipos_obras (id, descripcion, estado) FROM stdin;
1	Obra al costo	0
2	Obra a precio cerrado	0
\.


--
-- Data for Name: tipos_propiedades; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.tipos_propiedades (id, descripcion, obligatorio, estado, fecha_baja) FROM stdin;
1	Terreno	1	0	\N
2	Departamento 2 ambientes	\N	1	\N
3	Departamento 3 ambientes	\N	1	\N
4	Departamento 4 ambientes	\N	1	\N
5	Oficina	\N	1	\N
6	Departamento Funcional	\N	0	\N
7	Departamento Funcional con cochera	\N	0	\N
8	Departamento 1 dormitorio	\N	0	\N
9	Departamento 1 dormitorio con cochera	\N	0	\N
10	Departamento 2 dormitorios 	\N	0	\N
11	Departamento 2 dormitorios con cochera	\N	0	\N
12	Piso	\N	0	\N
13	Piso con cochera	\N	0	\N
14	Oficina	\N	0	\N
15	6 departamentos con 4 cocheras	\N	0	\N
16	3 departamentos 	\N	0	\N
17	3 departamentos con 1 cochera	\N	0	\N
\.


--
-- Data for Name: tipos_proyectos; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.tipos_proyectos (id, descripcion, estado) FROM stdin;
1	Edificio	0
2	Dúplex	0
3	Casa	0
4	Oficinas	0
5	Departamentos	0
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: root
--

COPY public.usuarios (id, nombre, password, usuario, estado, nivel, fecha_baja) FROM stdin;
4	Prueba	81dc9bdb52d04dc20036dbd8313ed055	prueba	0	0	\N
5	Prueba	81dc9bdb52d04dc20036dbd8313ed055	pru	0	0	\N
1	Oscar  Ru	81dc9bdb52d04dc20036dbd8313ed055	orc	0	1	\N
2	Emiliano	81dc9bdb52d04dc20036dbd8313ed055	emiliano	0	1	\N
3	Ulises	81dc9bdb52d04dc20036dbd8313ed055	uli	0	1	\N
\.


--
-- Name: cajas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.cajas_id_seq', 1, false);


--
-- Name: chequeras_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.chequeras_id_seq', 6, true);


--
-- Name: conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.conceptos_id_seq', 4, true);


--
-- Name: cotizaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.cotizaciones_id_seq', 6, true);


--
-- Name: cuentas_bancarias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.cuentas_bancarias_id_seq', 6, true);


--
-- Name: cuentas_corrientes_caja_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.cuentas_corrientes_caja_id_seq', 526, true);


--
-- Name: cuentas_corrientes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.cuentas_corrientes_id_seq', 810, true);


--
-- Name: detalle_proyecto_tipos_propiedades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.detalle_proyecto_tipos_propiedades_id_seq', 1052, true);


--
-- Name: entidades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.entidades_id_seq', 118, true);


--
-- Name: informes_proyectos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.informes_proyectos_id_seq', 1, false);


--
-- Name: localidades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.localidades_id_seq', 1, false);


--
-- Name: materiales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.materiales_id_seq', 1, true);


--
-- Name: monedas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.monedas_id_seq', 3, true);


--
-- Name: movimientos_bancarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.movimientos_bancarios_id_seq', 1, true);


--
-- Name: movimientos_cheques_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.movimientos_cheques_id_seq', 1, false);


--
-- Name: permisos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.permisos_id_seq', 1, false);


--
-- Name: permisos_usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.permisos_usuarios_id_seq', 1, false);


--
-- Name: presupuestos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.presupuestos_id_seq', 2, true);


--
-- Name: provincias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.provincias_id_seq', 1, false);


--
-- Name: proyectos_entidades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.proyectos_entidades_id_seq', 64, true);


--
-- Name: proyectos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.proyectos_id_seq', 8, true);


--
-- Name: proyectos_tipos_propiedades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.proyectos_tipos_propiedades_id_seq', 80, true);


--
-- Name: relacion_ctas_ctes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.relacion_ctas_ctes_id_seq', 283, true);


--
-- Name: relacion_presu_ctactes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.relacion_presu_ctactes_id_seq', 2, true);


--
-- Name: tipos_comprobantes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.tipos_comprobantes_id_seq', 15, true);


--
-- Name: tipos_entidades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.tipos_entidades_id_seq', 4, true);


--
-- Name: tipos_movimientos_caja_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.tipos_movimientos_caja_id_seq', 32, true);


--
-- Name: tipos_obras_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.tipos_obras_id_seq', 2, true);


--
-- Name: tipos_propiedades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.tipos_propiedades_id_seq', 17, true);


--
-- Name: tipos_proyectos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.tipos_proyectos_id_seq', 5, true);


--
-- Name: usuarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.usuarios_id_seq', 5, true);


--
-- Name: tipos_comprobantes abreviado; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tipos_comprobantes
    ADD CONSTRAINT abreviado UNIQUE (abreviado);


--
-- Name: conceptos conceptos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conceptos
    ADD CONSTRAINT conceptos_pkey PRIMARY KEY (id);


--
-- Name: materiales materiales_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.materiales
    ADD CONSTRAINT materiales_pkey PRIMARY KEY (id);


--
-- Name: bancos pk_bancos; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.bancos
    ADD CONSTRAINT pk_bancos PRIMARY KEY (id);


--
-- Name: cajas pk_cajas; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cajas
    ADD CONSTRAINT pk_cajas PRIMARY KEY (id);


--
-- Name: chequeras pk_chequeras; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.chequeras
    ADD CONSTRAINT pk_chequeras PRIMARY KEY (id);


--
-- Name: cotizaciones pk_cotizaciones; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cotizaciones
    ADD CONSTRAINT pk_cotizaciones PRIMARY KEY (id);


--
-- Name: cuentas_bancarias pk_cuentas_bancarias; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_bancarias
    ADD CONSTRAINT pk_cuentas_bancarias PRIMARY KEY (id);


--
-- Name: cuentas_corrientes pk_cuentas_corrientes; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes
    ADD CONSTRAINT pk_cuentas_corrientes PRIMARY KEY (id);


--
-- Name: cuentas_corrientes_caja pk_cuentas_corrientes_caja; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes_caja
    ADD CONSTRAINT pk_cuentas_corrientes_caja PRIMARY KEY (id);


--
-- Name: detalle_proyecto_tipos_propiedades pk_detalle_proyecto_tipos_propiedades; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.detalle_proyecto_tipos_propiedades
    ADD CONSTRAINT pk_detalle_proyecto_tipos_propiedades PRIMARY KEY (id);


--
-- Name: entidades pk_entidades; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.entidades
    ADD CONSTRAINT pk_entidades PRIMARY KEY (id);


--
-- Name: informes_proyectos pk_informes_proyectos; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.informes_proyectos
    ADD CONSTRAINT pk_informes_proyectos PRIMARY KEY (id);


--
-- Name: localidades pk_localidades; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT pk_localidades PRIMARY KEY (id);


--
-- Name: monedas pk_monedas; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.monedas
    ADD CONSTRAINT pk_monedas PRIMARY KEY (id);


--
-- Name: movimientos_bancarios pk_movimientos_bancarios; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_bancarios
    ADD CONSTRAINT pk_movimientos_bancarios PRIMARY KEY (id);


--
-- Name: movimientos_cheques pk_movimientos_cheques; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.movimientos_cheques
    ADD CONSTRAINT pk_movimientos_cheques PRIMARY KEY (id);


--
-- Name: permisos pk_permisos; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.permisos
    ADD CONSTRAINT pk_permisos PRIMARY KEY (id);


--
-- Name: permisos_usuarios pk_permisos_usuarios; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.permisos_usuarios
    ADD CONSTRAINT pk_permisos_usuarios PRIMARY KEY (id);


--
-- Name: provincias pk_provincias; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.provincias
    ADD CONSTRAINT pk_provincias PRIMARY KEY (id);


--
-- Name: proyectos pk_proyectos; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.proyectos
    ADD CONSTRAINT pk_proyectos PRIMARY KEY (id);


--
-- Name: proyectos_entidades pk_proyectos_entidades; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.proyectos_entidades
    ADD CONSTRAINT pk_proyectos_entidades PRIMARY KEY (id);


--
-- Name: proyectos_tipos_propiedades pk_proyectos_tipos_propiedades; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.proyectos_tipos_propiedades
    ADD CONSTRAINT pk_proyectos_tipos_propiedades PRIMARY KEY (id);


--
-- Name: relacion_ctas_ctes pk_relacion_ctas_ctes; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.relacion_ctas_ctes
    ADD CONSTRAINT pk_relacion_ctas_ctes PRIMARY KEY (id);


--
-- Name: tipos_comprobantes pk_tipos_comprobantes; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tipos_comprobantes
    ADD CONSTRAINT pk_tipos_comprobantes PRIMARY KEY (id);


--
-- Name: tipos_entidades pk_tipos_entidades; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tipos_entidades
    ADD CONSTRAINT pk_tipos_entidades PRIMARY KEY (id);


--
-- Name: tipos_obras pk_tipos_obras; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tipos_obras
    ADD CONSTRAINT pk_tipos_obras PRIMARY KEY (id);


--
-- Name: tipos_propiedades pk_tipos_propiedades; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tipos_propiedades
    ADD CONSTRAINT pk_tipos_propiedades PRIMARY KEY (id);


--
-- Name: tipos_proyectos pk_tipos_proyectos; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tipos_proyectos
    ADD CONSTRAINT pk_tipos_proyectos PRIMARY KEY (id);


--
-- Name: usuarios pk_usuarios; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT pk_usuarios PRIMARY KEY (id);


--
-- Name: presupuestos presupuestos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.presupuestos
    ADD CONSTRAINT presupuestos_pkey PRIMARY KEY (id);


--
-- Name: relacion_presu_ctactes relacion_presu_ctactes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relacion_presu_ctactes
    ADD CONSTRAINT relacion_presu_ctactes_pkey PRIMARY KEY (id);


--
-- Name: tipos_movimientos_caja tipos_movimientos_caja_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.tipos_movimientos_caja
    ADD CONSTRAINT tipos_movimientos_caja_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuario; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuario UNIQUE (usuario);


--
-- Name: fki_relship12; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX fki_relship12 ON public.cuentas_corrientes_caja USING btree (cuenta_corriente_id);


--
-- Name: index1; Type: INDEX; Schema: public; Owner: root
--

CREATE UNIQUE INDEX index1 ON public.cotizaciones USING btree (moneda_id, fecha);


--
-- Name: index1cc; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX index1cc ON public.cuentas_corrientes USING btree (fecha);


--
-- Name: index2cc; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX index2cc ON public.cuentas_corrientes USING btree (fecha, tipo_comprobante_id);


--
-- Name: index3cc; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX index3cc ON public.cuentas_corrientes USING btree (entidad_id, fecha);


--
-- Name: inx_relship7; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX inx_relship7 ON public.informes_proyectos USING btree (entidad_id);


--
-- Name: ix_relationship12; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship12 ON public.cuentas_corrientes_caja USING btree (cuenta_corriente_id);


--
-- Name: ix_relationship24; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship24 ON public.movimientos_cheques USING btree (cuenta_corriente_caja_id);


--
-- Name: ix_relationship27; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship27 ON public.chequeras USING btree (cuenta_bancaria_id);


--
-- Name: ix_relationship29; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship29 ON public.cuentas_bancarias USING btree (banco_id);


--
-- Name: ix_relationship30; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship30 ON public.movimientos_cheques USING btree (banco_id);


--
-- Name: ix_relationship31; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship31 ON public.cuentas_corrientes USING btree (moneda_id);


--
-- Name: ix_relationship32; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship32 ON public.cotizaciones USING btree (moneda_id);


--
-- Name: ix_relationship33; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship33 ON public.relacion_ctas_ctes USING btree (cuenta_corriente_id);


--
-- Name: ix_relationship34; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship34 ON public.relacion_ctas_ctes USING btree (relacion_id);


--
-- Name: ix_relationship35; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship35 ON public.cuentas_corrientes_caja USING btree (moneda_id);


--
-- Name: ix_relationship36; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship36 ON public.localidades USING btree (provincia_id);


--
-- Name: ix_relationship37; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship37 ON public.entidades USING btree (localidad_id);


--
-- Name: ix_relationship38; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship38 ON public.cuentas_corrientes USING btree (entidad_id);


--
-- Name: ix_relationship39; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship39 ON public.proyectos USING btree (localidad_id);


--
-- Name: ix_relationship40; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship40 ON public.proyectos USING btree (tipo_proyecto_id);


--
-- Name: ix_relationship41; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship41 ON public.proyectos_tipos_propiedades USING btree (tipo_propiedad_id);


--
-- Name: ix_relationship43; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship43 ON public.proyectos_tipos_propiedades USING btree (proyecto_id);


--
-- Name: ix_relationship44; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship44 ON public.detalle_proyecto_tipos_propiedades USING btree (proyecto_tipo_propiedad_id);


--
-- Name: ix_relationship45; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship45 ON public.detalle_proyecto_tipos_propiedades USING btree (entidad_id);


--
-- Name: ix_relationship46; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship46 ON public.proyectos USING btree (tipo_obra_id);


--
-- Name: ix_relationship49; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship49 ON public.cuentas_corrientes USING btree (detalle_proyecto_tipo_propiedad_id);


--
-- Name: ix_relationship50; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship50 ON public.cuentas_corrientes USING btree (proyecto_id);


--
-- Name: ix_relationship51; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship51 ON public.cuentas_corrientes USING btree (usuario_id);


--
-- Name: ix_relationship52; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship52 ON public.chequeras USING btree (moneda_id);


--
-- Name: ix_relationship54; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship54 ON public.movimientos_cheques USING btree (chequera_id);


--
-- Name: ix_relationship55; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship55 ON public.proyectos_entidades USING btree (entidad_id);


--
-- Name: ix_relationship56; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship56 ON public.proyectos_entidades USING btree (proyecto_id);


--
-- Name: ix_relationship57; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship57 ON public.cuentas_bancarias USING btree (proyecto_id);


--
-- Name: ix_relationship59; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship59 ON public.cuentas_corrientes_caja USING btree (tipo_movimiento_caja_id);


--
-- Name: ix_relationship6; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship6 ON public.informes_proyectos USING btree (proyecto_id);


--
-- Name: ix_relationship60; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship60 ON public.cuentas_corrientes_caja USING btree (cuenta_bancaria_id);


--
-- Name: ix_relationship61; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship61 ON public.cuentas_corrientes_caja USING btree (caja_id);


--
-- Name: ix_relationship63; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship63 ON public.movimientos_cheques USING btree (moneda_id);


--
-- Name: ix_relationship64; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship64 ON public.cuentas_corrientes_caja USING btree (chequera_id);


--
-- Name: ix_relationship66; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship66 ON public.cuentas_corrientes_caja USING btree (banco_id);


--
-- Name: ix_relationship66a; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship66a ON public.cuentas_corrientes_caja USING btree (cta_cte_caja_origen_id);


--
-- Name: ix_relationship66b; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship66b ON public.cuentas_corrientes_caja USING btree (numero, serie);


--
-- Name: ix_relationship67; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_relationship67 ON public.movimientos_bancarios USING btree (cuenta_bancaria_id);


--
-- Name: ix_relationship68; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_relationship68 ON public.movimientos_bancarios USING btree (tipo_movimiento_caja_id);


--
-- Name: ix_relationship69; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_relationship69 ON public.movimientos_bancarios USING btree (cuenta_corriente_id);


--
-- Name: ix_relationship7; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship7 ON public.cuentas_corrientes USING btree (tipo_comprobante_id);


--
-- Name: ix_relationship70; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_relationship70 ON public.movimientos_bancarios USING btree (moneda_id);


--
-- Name: ix_relationship8; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship8 ON public.permisos_usuarios USING btree (usuario_id);


--
-- Name: ix_relationship9; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_relationship9 ON public.permisos_usuarios USING btree (permiso_id);


--
-- Name: ix_relationshipuni_1; Type: INDEX; Schema: public; Owner: root
--

CREATE UNIQUE INDEX ix_relationshipuni_1 ON public.detalle_proyecto_tipos_propiedades USING btree (proyecto_tipo_propiedad_id, entidad_id);


--
-- Name: ix_unique_55; Type: INDEX; Schema: public; Owner: root
--

CREATE UNIQUE INDEX ix_unique_55 ON public.proyectos_entidades USING btree (entidad_id, proyecto_id);


--
-- Name: cotizaciones trigg_cotizaciones_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_cotizaciones_update BEFORE UPDATE ON public.cotizaciones FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: cuentas_bancarias trigg_cuentas_bancarias_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_cuentas_bancarias_update BEFORE UPDATE ON public.cuentas_bancarias FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: cuentas_corrientes_caja trigg_cuentas_corrientes_caja_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_cuentas_corrientes_caja_update BEFORE UPDATE ON public.cuentas_corrientes_caja FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: cuentas_corrientes trigg_cuentas_corrientes_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_cuentas_corrientes_update BEFORE UPDATE ON public.cuentas_corrientes FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: detalle_proyecto_tipos_propiedades trigg_detalle_proyecto_tipos_propiedades_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_detalle_proyecto_tipos_propiedades_update BEFORE UPDATE ON public.detalle_proyecto_tipos_propiedades FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: entidades trigg_entidades_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_entidades_update BEFORE UPDATE ON public.entidades FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: informes_proyectos trigg_informes_proyectos_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_informes_proyectos_update BEFORE UPDATE ON public.informes_proyectos FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: materiales trigg_materiales_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigg_materiales_update BEFORE UPDATE ON public.materiales FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: proyectos_entidades trigg_proyectos_entidades_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_proyectos_entidades_update BEFORE UPDATE ON public.proyectos_entidades FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: proyectos_tipos_propiedades trigg_proyectos_tipos_propiedades_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_proyectos_tipos_propiedades_update BEFORE UPDATE ON public.proyectos_tipos_propiedades FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: proyectos trigg_proyectos_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_proyectos_update BEFORE UPDATE ON public.proyectos FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: relacion_ctas_ctes trigg_relacion_ctas_ctes_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_relacion_ctas_ctes_update BEFORE UPDATE ON public.relacion_ctas_ctes FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: tipos_comprobantes trigg_tipos_comprobantes_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_tipos_comprobantes_update BEFORE UPDATE ON public.tipos_comprobantes FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: tipos_propiedades trigg_tipos_propiedades_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_tipos_propiedades_update BEFORE UPDATE ON public.tipos_propiedades FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: usuarios trigg_usuarios_update; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER trigg_usuarios_update BEFORE UPDATE ON public.usuarios FOR EACH ROW EXECUTE FUNCTION public.fecha_baja_trigger();


--
-- Name: presupuestos presupuestos_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.presupuestos
    ADD CONSTRAINT presupuestos_fk1 FOREIGN KEY (entidad_id) REFERENCES public.entidades(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: presupuestos presupuestos_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.presupuestos
    ADD CONSTRAINT presupuestos_fk2 FOREIGN KEY (proyecto_id) REFERENCES public.proyectos(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: presupuestos presupuestos_fk3; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.presupuestos
    ADD CONSTRAINT presupuestos_fk3 FOREIGN KEY (moneda_id) REFERENCES public.monedas(id) NOT VALID;


--
-- Name: relacion_presu_ctactes relacion_presu_ctactes_fk1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relacion_presu_ctactes
    ADD CONSTRAINT relacion_presu_ctactes_fk1 FOREIGN KEY (cuenta_corriente_id) REFERENCES public.cuentas_corrientes(id) NOT VALID;


--
-- Name: relacion_presu_ctactes relacion_presu_ctactes_fk2; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.relacion_presu_ctactes
    ADD CONSTRAINT relacion_presu_ctactes_fk2 FOREIGN KEY (presupuesto_id) REFERENCES public.presupuestos(id) NOT VALID;


--
-- Name: chequeras relationship27; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.chequeras
    ADD CONSTRAINT relationship27 FOREIGN KEY (cuenta_bancaria_id) REFERENCES public.cuentas_bancarias(id);


--
-- Name: cuentas_bancarias relationship29; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_bancarias
    ADD CONSTRAINT relationship29 FOREIGN KEY (banco_id) REFERENCES public.bancos(id);


--
-- Name: cuentas_corrientes relationship31; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes
    ADD CONSTRAINT relationship31 FOREIGN KEY (moneda_id) REFERENCES public.monedas(id);


--
-- Name: cotizaciones relationship32; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cotizaciones
    ADD CONSTRAINT relationship32 FOREIGN KEY (moneda_id) REFERENCES public.monedas(id);


--
-- Name: relacion_ctas_ctes relationship33; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.relacion_ctas_ctes
    ADD CONSTRAINT relationship33 FOREIGN KEY (cuenta_corriente_id) REFERENCES public.cuentas_corrientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: relacion_ctas_ctes relationship34; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.relacion_ctas_ctes
    ADD CONSTRAINT relationship34 FOREIGN KEY (relacion_id) REFERENCES public.cuentas_corrientes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cuentas_corrientes_caja relationship35; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes_caja
    ADD CONSTRAINT relationship35 FOREIGN KEY (moneda_id) REFERENCES public.monedas(id);


--
-- Name: localidades relationship36; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT relationship36 FOREIGN KEY (provincia_id) REFERENCES public.provincias(id);


--
-- Name: entidades relationship37; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.entidades
    ADD CONSTRAINT relationship37 FOREIGN KEY (localidad_id) REFERENCES public.localidades(id);


--
-- Name: entidades relationship377; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.entidades
    ADD CONSTRAINT relationship377 FOREIGN KEY (proyecto_id) REFERENCES public.proyectos(id) NOT VALID;


--
-- Name: cuentas_corrientes relationship38; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes
    ADD CONSTRAINT relationship38 FOREIGN KEY (entidad_id) REFERENCES public.entidades(id);


--
-- Name: proyectos relationship39; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.proyectos
    ADD CONSTRAINT relationship39 FOREIGN KEY (localidad_id) REFERENCES public.localidades(id);


--
-- Name: proyectos relationship40; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.proyectos
    ADD CONSTRAINT relationship40 FOREIGN KEY (tipo_proyecto_id) REFERENCES public.tipos_proyectos(id);


--
-- Name: proyectos_tipos_propiedades relationship41; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.proyectos_tipos_propiedades
    ADD CONSTRAINT relationship41 FOREIGN KEY (tipo_propiedad_id) REFERENCES public.tipos_propiedades(id);


--
-- Name: proyectos_tipos_propiedades relationship43; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.proyectos_tipos_propiedades
    ADD CONSTRAINT relationship43 FOREIGN KEY (proyecto_id) REFERENCES public.proyectos(id);


--
-- Name: detalle_proyecto_tipos_propiedades relationship44; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.detalle_proyecto_tipos_propiedades
    ADD CONSTRAINT relationship44 FOREIGN KEY (proyecto_tipo_propiedad_id) REFERENCES public.proyectos_tipos_propiedades(id);


--
-- Name: detalle_proyecto_tipos_propiedades relationship45; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.detalle_proyecto_tipos_propiedades
    ADD CONSTRAINT relationship45 FOREIGN KEY (entidad_id) REFERENCES public.entidades(id);


--
-- Name: proyectos relationship46; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.proyectos
    ADD CONSTRAINT relationship46 FOREIGN KEY (tipo_obra_id) REFERENCES public.tipos_obras(id);


--
-- Name: informes_proyectos relationship47; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.informes_proyectos
    ADD CONSTRAINT relationship47 FOREIGN KEY (entidad_id) REFERENCES public.entidades(id);


--
-- Name: cuentas_corrientes relationship49; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes
    ADD CONSTRAINT relationship49 FOREIGN KEY (detalle_proyecto_tipo_propiedad_id) REFERENCES public.detalle_proyecto_tipos_propiedades(id);


--
-- Name: cuentas_corrientes relationship50; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes
    ADD CONSTRAINT relationship50 FOREIGN KEY (proyecto_id) REFERENCES public.proyectos(id);


--
-- Name: cuentas_corrientes relationship51; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes
    ADD CONSTRAINT relationship51 FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: chequeras relationship52; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.chequeras
    ADD CONSTRAINT relationship52 FOREIGN KEY (moneda_id) REFERENCES public.monedas(id);


--
-- Name: proyectos_entidades relationship55; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.proyectos_entidades
    ADD CONSTRAINT relationship55 FOREIGN KEY (entidad_id) REFERENCES public.entidades(id);


--
-- Name: proyectos_entidades relationship56; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.proyectos_entidades
    ADD CONSTRAINT relationship56 FOREIGN KEY (proyecto_id) REFERENCES public.proyectos(id);


--
-- Name: cuentas_bancarias relationship57; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_bancarias
    ADD CONSTRAINT relationship57 FOREIGN KEY (proyecto_id) REFERENCES public.proyectos(id);


--
-- Name: cuentas_corrientes_caja relationship59; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes_caja
    ADD CONSTRAINT relationship59 FOREIGN KEY (tipo_movimiento_caja_id) REFERENCES public.tipos_movimientos_caja(id);


--
-- Name: informes_proyectos relationship6; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.informes_proyectos
    ADD CONSTRAINT relationship6 FOREIGN KEY (proyecto_id) REFERENCES public.proyectos(id);


--
-- Name: cuentas_corrientes_caja relationship60; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes_caja
    ADD CONSTRAINT relationship60 FOREIGN KEY (cuenta_bancaria_id) REFERENCES public.cuentas_bancarias(id);


--
-- Name: cuentas_corrientes_caja relationship61; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes_caja
    ADD CONSTRAINT relationship61 FOREIGN KEY (caja_id) REFERENCES public.cajas(id);


--
-- Name: cuentas_corrientes_caja relationship64; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes_caja
    ADD CONSTRAINT relationship64 FOREIGN KEY (chequera_id) REFERENCES public.chequeras(id);


--
-- Name: cuentas_corrientes_caja relationship66; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes_caja
    ADD CONSTRAINT relationship66 FOREIGN KEY (banco_id) REFERENCES public.bancos(id);


--
-- Name: movimientos_bancarios relationship67; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_bancarios
    ADD CONSTRAINT relationship67 FOREIGN KEY (cuenta_bancaria_id) REFERENCES public.cuentas_bancarias(id);


--
-- Name: movimientos_bancarios relationship68; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_bancarios
    ADD CONSTRAINT relationship68 FOREIGN KEY (tipo_movimiento_caja_id) REFERENCES public.tipos_movimientos_caja(id);


--
-- Name: movimientos_bancarios relationship69; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_bancarios
    ADD CONSTRAINT relationship69 FOREIGN KEY (cuenta_corriente_id) REFERENCES public.cuentas_corrientes_caja(id);


--
-- Name: cuentas_corrientes relationship7; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes
    ADD CONSTRAINT relationship7 FOREIGN KEY (tipo_comprobante_id) REFERENCES public.tipos_comprobantes(id);


--
-- Name: movimientos_bancarios relationship70; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimientos_bancarios
    ADD CONSTRAINT relationship70 FOREIGN KEY (moneda_id) REFERENCES public.monedas(id);


--
-- Name: cuentas_corrientes_caja relationship77; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes_caja
    ADD CONSTRAINT relationship77 FOREIGN KEY (proyecto_id) REFERENCES public.proyectos(id) NOT VALID;


--
-- Name: permisos_usuarios relationship8; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.permisos_usuarios
    ADD CONSTRAINT relationship8 FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: permisos_usuarios relationship9; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.permisos_usuarios
    ADD CONSTRAINT relationship9 FOREIGN KEY (permiso_id) REFERENCES public.permisos(id);


--
-- Name: cuentas_corrientes_caja relship12; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.cuentas_corrientes_caja
    ADD CONSTRAINT relship12 FOREIGN KEY (cuenta_corriente_id) REFERENCES public.cuentas_corrientes(id) NOT VALID;


--
-- PostgreSQL database dump complete
--

