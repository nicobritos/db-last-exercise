DROP TABLE IF EXISTS "CONTRATO";

-- TODO FOREIGN KEYS
CREATE TABLE "CONTRATO" (
        FechaDesde DATE NOT NULL,
        FechaHasta DATE NOT NULL,
        DeptoId INT NOT NULL,
        PersonaId INT NOT NULL,
        PRIMARY KEY (FechaDesde, FechaHasta, DeptoId)
--        FOREIGN KEY (DeptoId) REFERENCES "DEPARTAMENTOS" (DeptoId) ON UPDATE RESTRICT ON DELETE CASCADE
);

COPY "CONTRATO"
        FROM 'C:\Users\Nico\Documents\ITBA\2019C2\BD1\TPE\tpe-bd-g5\Enunciado\alquileres.csv'
        DELIMITERS ','
		CSV
		HEADER
