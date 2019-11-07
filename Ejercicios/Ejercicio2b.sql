DROP FUNCTION IF EXISTS validacion_contrasena_funcion CASCADE;
DROP TRIGGER IF EXISTS validacion_contrasena_trigger ON USUARIO CASCADE;

-- Funcion
CREATE FUNCTION validacion_contrasena_funcion() RETURNS TRIGGER
	AS $$
	DECLARE
		n INT := (
			SELECT MAX(Nivel) FROM ROL 
				INNER JOIN ROLES ON ROLES.Rol = ROL.Nombre
				WHERE ROLES.Usuario = OLD.Nombre
		);
	BEGIN
		IF (OLD.Password = NEW.Password) THEN
			RAISE EXCEPTION 'No puede repetir el password anterior';
		END IF;
		
		IF (NEW.Password IN
			(
				SELECT Password FROM HISTORIALPASSWORD
					WHERE Usuario = OLD.Nombre
					ORDER BY Fecha DESC
					LIMIT n
			)
	    ) THEN
			RAISE EXCEPTION 'El password no debe de coincidir con ninguno de los % passwords anteriores', n;
		END IF;
		-- Insertar en historial
		INSERT INTO HISTORIALPASSWORD (Usuario, Password, Fecha) VALUES (OLD.Nombre, NEW.Password, NOW());
		
		RETURN NEW;
	END;
	$$
	LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER validacion_contrasena_trigger BEFORE UPDATE
	ON USUARIO
	FOR EACH ROW
	EXECUTE PROCEDURE validacion_contrasena_funcion();
