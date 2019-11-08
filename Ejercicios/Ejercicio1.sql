DROP FUNCTION IF EXISTS CargaResumenContrato CASCADE;
DROP FUNCTION IF EXISTS copy_contrato CASCADE;
DROP TABLE IF EXISTS RESUMENCONTRATO CASCADE;
DROP TABLE IF EXISTS CONTRATO CASCADE;

-- Tablas
-- 2.a
CREATE TABLE CONTRATO (
        FechaDesde DATE NOT NULL,
        FechaHasta DATE NOT NULL,
        DeptoId INT NOT NULL,
        PersonaId INT NOT NULL,
        PRIMARY KEY (FechaDesde, FechaHasta, DeptoId)
);

-- 2.c
CREATE TABLE RESUMENCONTRATO (
        FechaDesde DATE NOT NULL,
        FechaHasta DATE NOT NULL,
        DeptoId INT NOT NULL,
	    PRIMARY KEY (FechaDesde, FechaHasta, DeptoId)
);

-- Funciones
-- 2.b
CREATE FUNCTION copy_contrato(fp TEXT) RETURNS VOID
	AS $function$
	BEGIN
		CREATE TEMPORARY TABLE CONTRATO_TEMP (
			FechaDesde TEXT NOT NULL,
			FechaHasta TEXT NOT NULL,
			DeptoId INT NOT NULL,
			PersonaId INT NOT NULL
		);
		
		EXECUTE format('COPY CONTRATO_TEMP from %L DELIMITERS '','' CSV HEADER', fp);
		INSERT INTO CONTRATO (FechaDesde, FechaHasta, DeptoId, PersonaId)
			SELECT to_date(FechaDesde, 'YYYYMM'), to_date(FechaHasta, 'YYYYMM'), DeptoId, PersonaId
			FROM CONTRATO_TEMP;
		
		DROP TABLE CONTRATO_TEMP;
	END;
	$function$
	LANGUAGE plpgsql;

CREATE FUNCTION CargaResumenContrato() RETURNS VOID
	AS $function$
	BEGIN
		INSERT INTO RESUMENCONTRATO (FechaDesde, FechaHasta, DeptoId)
			(
				WITH RECURSIVE
					ResumenContrato(FechaDesde, FechaHasta, DeptoId) AS (
						SELECT FechaDesde, FechaHasta, DeptoId
						FROM CONTRATO
						UNION
						SELECT ResumenContrato.FechaDesde, CONTRATO.FechaHasta, CONTRATO.DeptoId
						FROM CONTRATO 
							INNER JOIN ResumenContrato 
							ON CONTRATO.FechaDesde = ResumenContrato.FechaHasta AND Contrato.DeptoId = ResumenContrato.DeptoId
					)

					SELECT *
					FROM ResumenContrato AS R1
					WHERE R1.FechaDesde NOT IN (
						SELECT FechaHasta FROM ResumenContrato as R2
						WHERE R1.DeptoId = R2.DeptoId
					) AND R1.FechaHasta NOT IN (
						SELECT FechaDesde FROM ResumenContrato as R2
						WHERE R1.DeptoId = R2.DeptoId
					)
			);
	END;
	$function$
	LANGUAGE plpgsql;
