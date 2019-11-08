-- Ejercicio 1
DROP FUNCTION IF EXISTS CargaResumenContrato CASCADE;
DROP FUNCTION IF EXISTS copy_contrato CASCADE;
DROP TABLE IF EXISTS RESUMENCONTRATO CASCADE;
DROP TABLE IF EXISTS CONTRATO CASCADE;

-- Tablas
-- 1.a
CREATE TABLE CONTRATO (
        FechaDesde DATE NOT NULL,
        FechaHasta DATE NOT NULL,
        DeptoId INT NOT NULL,
        PersonaId INT NOT NULL,
        PRIMARY KEY (FechaDesde, FechaHasta, DeptoId)
);

-- 1.c
CREATE TABLE RESUMENCONTRATO (
        FechaDesde DATE NOT NULL,
        FechaHasta DATE NOT NULL,
        DeptoId INT NOT NULL,
	    PRIMARY KEY (FechaDesde, FechaHasta, DeptoId)
);

-- Funciones
-- 1.b
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
  
  
  
-- Ejercicio 2
DROP FUNCTION IF EXISTS get_n_old_passwords CASCADE;
DROP FUNCTION IF EXISTS repeats_password CASCADE;
DROP FUNCTION IF EXISTS validacion_contrasena_funcion CASCADE;
DROP TRIGGER IF EXISTS validacion_contrasena_trigger ON USUARIO CASCADE;

DROP TABLE IF EXISTS USUARIO CASCADE;
DROP TABLE IF EXISTS ROL CASCADE;
DROP TABLE IF EXISTS ROLES CASCADE;
DROP TABLE IF EXISTS HISTORIALPASSWORD CASCADE;

-- 2.a Crear tablas e insertar datos
-- 2.a.1 Crear tablas
CREATE TABLE USUARIO (
	Nombre TEXT NOT NULL,
	Password TEXT NOT NULL,
	PRIMARY KEY (Nombre)
);

CREATE TABLE ROL (
	Nombre TEXT NOT NULL,
	Nivel INT NOT NULL CHECK (Nivel >= 0),
	PRIMARY KEY (Nombre)
);

CREATE TABLE ROLES (
	Usuario TEXT NOT NULL,
	Rol TEXT NOT NULL,
	PRIMARY KEY (Usuario, Rol),
	FOREIGN KEY (Usuario) REFERENCES USUARIO (Nombre) ON UPDATE RESTRICT ON DELETE CASCADE,
	FOREIGN KEY (Rol) REFERENCES ROL (Nombre) ON UPDATE RESTRICT ON DELETE CASCADE
);

CREATE TABLE HISTORIALPASSWORD (
	Usuario TEXT NOT NULL,
	Password TEXT NOT NULL,
	Fecha TIMESTAMP NOT NULL,
	PRIMARY KEY (Usuario, Fecha),
	FOREIGN KEY (Usuario) REFERENCES USUARIO (Nombre) ON UPDATE RESTRICT ON DELETE CASCADE
);

-- 2.a.2 Insertar Datos
-- USUARIO
INSERT INTO USUARIO (Nombre, Password) VALUES ('jperez', 'pass1');
INSERT INTO USUARIO (Nombre, Password) VALUES ('mgomez', 'pass1');
INSERT INTO USUARIO (Nombre, Password) VALUES ('tbalbin', 'pass1');
INSERT INTO USUARIO (Nombre, Password) VALUES ('ucampos', 'pass1');

-- ROL
INSERT INTO ROL (Nombre, Nivel) VALUES ('secretaria', 0);
INSERT INTO ROL (Nombre, Nivel) VALUES ('gerente', 1);
INSERT INTO ROL (Nombre, Nivel) VALUES ('revisor', 2);

-- ROLES
INSERT INTO ROLES (Usuario, Rol) VALUES ('jperez', 'secretaria');
INSERT INTO ROLES (Usuario, Rol) VALUES ('mgomez', 'secretaria');
INSERT INTO ROLES (Usuario, Rol) VALUES ('tbalbin', 'secretaria');
INSERT INTO ROLES (Usuario, Rol) VALUES ('tbalbin', 'gerente');
INSERT INTO ROLES (Usuario, Rol) VALUES ('ucampos', 'revisor');

-- HISTORIALPASSWORD
INSERT INTO HISTORIALPASSWORD (Usuario, Password, Fecha) VALUES ('mgomez', 'pass2', '01/01/2019 00:00:00');
INSERT INTO HISTORIALPASSWORD (Usuario, Password, Fecha) VALUES ('tbalbin', 'pass15', '01/01/2019 00:00:00');
INSERT INTO HISTORIALPASSWORD (Usuario, Password, Fecha) VALUES ('tbalbin', 'pass44', '01/02/2019 00:00:00');
INSERT INTO HISTORIALPASSWORD (Usuario, Password, Fecha) VALUES ('ucampos', 'pass2', '01/01/2019 00:00:00');
INSERT INTO HISTORIALPASSWORD (Usuario, Password, Fecha) VALUES ('ucampos', 'pass3', '01/02/2019 00:00:00');
INSERT INTO HISTORIALPASSWORD (Usuario, Password, Fecha) VALUES ('ucampos', 'pass4', '01/03/2019 00:00:00');


-- 2.b Trigger de validacion de contrasena
-- Funciones
CREATE FUNCTION get_n_old_passwords(usuarioIn TEXT) RETURNS INT
	AS $function$
	BEGIN
		RETURN (
			SELECT MAX(Nivel) FROM ROL
				INNER JOIN ROLES ON ROLES.Rol = ROL.Nombre
				WHERE ROLES.Usuario = usuarioIn
		);
	END;
	$function$
	LANGUAGE plpgsql;

CREATE FUNCTION repeats_password(usuarioIn TEXT, pw TEXT, n INT) RETURNS BOOL
	AS $function$
	BEGIN
		RETURN pw IN (
			SELECT Password FROM HISTORIALPASSWORD
				WHERE Usuario = usuarioIn
				ORDER BY Fecha DESC
				LIMIT n
		);
	END;
	$function$
	LANGUAGE plpgsql;

CREATE FUNCTION validacion_contrasena_funcion() RETURNS TRIGGER
	AS $function$
	DECLARE
		n INT := get_n_old_passwords(OLD.Nombre);
	BEGIN
		IF (OLD.Password = NEW.Password) THEN
			RAISE EXCEPTION 'No puede repetir el password anterior';
		END IF;
		
		IF (repeats_password(OLD.Nombre, NEW.Password, n)) THEN
			RAISE EXCEPTION 'El password no debe de coincidir con ninguno de los % passwords anteriores', n;
		END IF;
		
		INSERT INTO HISTORIALPASSWORD (Usuario, Password, Fecha) VALUES (OLD.Nombre, OLD.Password, NOW());
		
		RETURN NEW;
	END;
	$function$
	LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER validacion_contrasena_trigger BEFORE UPDATE
	ON USUARIO
	FOR EACH ROW
	EXECUTE PROCEDURE validacion_contrasena_funcion();

