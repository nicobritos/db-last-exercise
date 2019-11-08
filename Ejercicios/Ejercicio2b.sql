DROP FUNCTION IF EXISTS get_n_old_passwords CASCADE;
DROP FUNCTION IF EXISTS repeats_password CASCADE;
DROP FUNCTION IF EXISTS validacion_contrasena_funcion CASCADE;
DROP TRIGGER IF EXISTS validacion_contrasena_trigger ON USUARIO CASCADE;

-- Funciones
CREATE FUNCTION get_n_old_passwords(usuario TEXT) RETURNS INT
	AS $function$
	BEGIN
		RETURN (
			SELECT MAX(Nivel) FROM ROL
				INNER JOIN ROLES ON ROLES.Rol = ROL.Nombre
				WHERE ROLES.Usuario = usuario
		);
	END;
	$function$
	LANGUAGE plpgsql;

CREATE FUNCTION repeats_password(usuario TEXT, pw TEXT, n INT) RETURNS BOOL
	AS $function$
	BEGIN
		RETURN pw IN (
			SELECT Password FROM HISTORIALPASSWORD
				WHERE Usuario = usuario
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
