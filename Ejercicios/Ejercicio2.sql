DROP TABLE IF EXISTS "USUARIO" CASCADE;
DROP TABLE IF EXISTS "ROL" CASCADE;
DROP TABLE IF EXISTS "ROLES" CASCADE;
DROP TABLE IF EXISTS "HISTORIALPASSWORD" CASCADE;

-- 2.a Crear tablas e insertar datos
-- 2.a.1 Crear tablas
CREATE TABLE "USUARIO" (
	Nombre TEXT NOT NULL,
	Password TEXT NOT NULL,
	PRIMARY KEY (Nombre)
);

CREATE TABLE "ROL" (
	Nombre TEXT NOT NULL,
	Nivel INT NOT NULL CHECK (Nivel >= 0),
	PRIMARY KEY (Nombre)
);

CREATE TABLE "ROLES" (
	Usuario TEXT NOT NULL,
	Rol TEXT NOT NULL,
	PRIMARY KEY (Usuario, Rol),
	FOREIGN KEY (Usuario) REFERENCES "USUARIO" (Nombre) ON UPDATE RESTRICT ON DELETE CASCADE,
	FOREIGN KEY (Rol) REFERENCES "ROL" (Nombre) ON UPDATE RESTRICT ON DELETE CASCADE
);

CREATE TABLE "HISTORIALPASSWORD" (
	Usuario TEXT NOT NULL,
	Password TEXT NOT NULL,
	Fecha TIMESTAMP NOT NULL,
	PRIMARY KEY (Usuario, Fecha),
	FOREIGN KEY (Usuario) REFERENCES "USUARIO" (Nombre) ON UPDATE RESTRICT ON DELETE CASCADE
);

-- 2.a.2 Insertar Datos
-- USUARIO
INSERT INTO "USUARIO" (Nombre, Password) VALUES ('jperez', 'pass1');
INSERT INTO "USUARIO" (Nombre, Password) VALUES ('mgomez', 'pass1');
INSERT INTO "USUARIO" (Nombre, Password) VALUES ('tbalbin', 'pass1');
INSERT INTO "USUARIO" (Nombre, Password) VALUES ('ucampos', 'pass1');

-- ROL
INSERT INTO "ROL" (Nombre, Nivel) VALUES ('secretaria', 0);
INSERT INTO "ROL" (Nombre, Nivel) VALUES ('gerente', 1);
INSERT INTO "ROL" (Nombre, Nivel) VALUES ('revisor', 2);

-- ROLES
INSERT INTO "ROLES" (Usuario, Rol) VALUES ('jperez', 'secretaria');
INSERT INTO "ROLES" (Usuario, Rol) VALUES ('mgomez', 'secretaria');
INSERT INTO "ROLES" (Usuario, Rol) VALUES ('tbalbin', 'secretaria');
INSERT INTO "ROLES" (Usuario, Rol) VALUES ('tbalbin', 'gerente');
INSERT INTO "ROLES" (Usuario, Rol) VALUES ('ucampos', 'revisor');

-- HISTORIALPASSWORD
INSERT INTO "HISTORIALPASSWORD" (Usuario, Password, Fecha) VALUES ('mgomez', 'pass2', '01/01/2019 00:00:00');
INSERT INTO "HISTORIALPASSWORD" (Usuario, Password, Fecha) VALUES ('tbalbin', 'pass15', '01/01/2019 00:00:00');
INSERT INTO "HISTORIALPASSWORD" (Usuario, Password, Fecha) VALUES ('tbalbin', 'pass14', '01/02/2019 00:00:00');
INSERT INTO "HISTORIALPASSWORD" (Usuario, Password, Fecha) VALUES ('ucampos', 'pass2', '01/01/2019 00:00:00');
INSERT INTO "HISTORIALPASSWORD" (Usuario, Password, Fecha) VALUES ('ucampos', 'pass3', '01/02/2019 00:00:00');
INSERT INTO "HISTORIALPASSWORD" (Usuario, Password, Fecha) VALUES ('ucampos', 'pass4', '01/03/2019 00:00:00');
