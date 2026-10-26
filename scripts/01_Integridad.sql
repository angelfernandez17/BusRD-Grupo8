
--SOLUCIONES APLICADAS

--Limpiar datos sucios (boletos duplicados)

--Detectar datos sucios

SELECT * FROM Pagos;
SELECT * FROM Boletos;
SELECT * FROM Asientos;

--Pagos huerfanos

SELECT p.PagoID, p.BoletoID                       --Seleciona la columna de PagoID Y BoletoID en la tabla Pagos (p)
FROM Pagos p									  	
left join Boletos b ON p.BoletoID = b.BoletoID    --Devuelve la tabla de la derecha (p) y las coincidencias de la de la derecha (b)
WHERE b.BoletoID IS NULL;						  --Cuando el BoletoID tiene datos Null es porque tiene pagos que apuntaban a nada, o que no pertenecían a un boleto y por eso estaba con datos Null

-- Limpiar pagos huerfanos
DELETE FROM Pagos
WHERE BoletoID NOT IN (SELECT BoletoID FROM Boletos);



--Datos sucios (Boletos duplicados)

SELECT b. *											
FROM Boletos b
INNER JOIN (					
SELECT ViajeID, NumeroAsiento
FROM Boletos										-- Este primer bloque lo que hace es que de la tabla Boletos (b) selecciona las columnas ViajeID y NumeroAsiento y el INNER JOIN es para que nos muestre solo las coincidencias  
GROUP BY ViajeID, NumeroAsiento					    
HAVING COUNT(*) > 1									-- Las agrupa o filtra exactamente por ViajeID y NumeroAsiento siempre y cuándo haya más de 1, esto asegura que solo devuelva los que se repitan más de una vez y no datos únicos
) duplicados
ON b.ViajeID = duplicados.ViajeID
AND b.NumeroAsiento = duplicados.NumeroAsiento;
GO													-- Este bloque lo que hace es ordenar a la base datos como se va a unir la tabla original y la de duplicados ya que con el ON taremos el Viaje ID y con el AND le decimos que obligatoriamente también debe coincidir el numero de asiento
													-- Así solo tare un registro cuando esas dos columnas sean identicas 		
--Eliminar los duplicados

WITH CTE_Duplicados AS (										--Crea una tabla temporal que existe mientras se ejecuta el comando y le damos nombre CTE_Duplicados para que agrupe y enumere los boleto
SELECT *, 
ROW_NUMBER () OVER (PARTITION BY [ViajeID], [NumeroAsiento]		--Agrupa las filas por viaje, numero de asiento independiente gracias a un contador para cada uno
ORDER BY [FechaVenta] ASC) as FilaNum															
FROM Boletos)													--Ordena las filas por fecha garantizando que el más antiguo o el primero que se vende obtenga el numero 1 que es original y las copias con un numero mayor a 1 (2,3) de la tabla Boletos
DELETE FROM CTE_Duplicados																			
WHERE FilaNum > 1;												--Ordenamos que se borren los datos que cayeron en la tabla CTE_duplicados cuando el numero del dato sea mayor a 1 porque 1 es el numero del dato original y las copias reciben numero mayores (2, 3...)
													

-- LLAVES FORANEAS

-- de asientos a autobuses
ALTER TABLE Asientos 
ADD CONSTRAINT FK_ASIENTOS_ID
FOREIGN KEY(AutobusID)
REFERENCES Autobuses(AutobusId);

EXEC sp_help 'Asientos'; --Para verificar si la fk conecta las tablas correctamente.

--De Viajes a Rutas
ALTER TABLE Viajes
ADD CONSTRAINT FK_RUTA_ID
FOREIGN KEY (RutaID)
REFERENCES Rutas(RutaID);

EXEC sp_help 'Viajes';

--De viajes a Autobus
ALTER TABLE Viajes
ADD CONSTRAINT FK_AUTOBUS_ID
FOREIGN KEY (AutobusID)
REFERENCES Autobuses(AutobusID);

EXEC sp_help 'Viajes';

--De Boletos a Clientes
 ALTER TABLE Boletos
 ADD CONSTRAINT FK_CLIENTE_ID
 FOREIGN KEY (ClienteID)
 REFERENCES Clientes(ClienteID);

 EXEC sp_help 'Boletos';

 --De Boletos Viajes
 ALTER TABLE Boletos
 ADD CONSTRAINT FK_VIAJES_ID
 FOREIGN KEY (ViajeID)
 REFERENCES Viajes(ViajeID);

 EXEC sp_help 'Boletos';

 --De pagos a Boletos
 ALTER TABLE Pagos
 ADD CONSTRAINT FK_BOLETOS_ID
 FOREIGN KEY (BoletoID)
 REFERENCES Boletos(BoletoID);

EXEC sp_help 'Pagos';


--RESTRICCIONES CHECK Y UNIQUE

--RUTAS
ALTER TABLE Rutas
ADD CONSTRAINT CHK_PRECIO_BASE CHECK (PrecioBase > 0);   --Check para que el precio base sea mayor a 0 siempre
GO

--AUTOBUSES
ALTER TABLE Autobuses
ADD CONSTRAINT UQ_PLACA_UNICA UNIQUE (PLACA);			--Obliga a que los datos de la columna placa sean unicos porque las placas nunca se repiten

ALTER TABLE Autobuses
ADD CONSTRAINT CHK_TIPO_ESTANDAR_EJECUTIVO CHECK (Tipo IN ('Estandar', 'Ejecutivo'));

ALTER TABLE Autobuses
ADD CONSTRAINT CHK_CAPACIDAD CHECK (Capacidad > 0);
GO

--ASIENTOS
ALTER TABLE Asientos
ADD CONSTRAINT CHK_UBICACION CHECK (Ubicacion IN ('Pasillo', 'Ventana'));
GO

--VIAJES
ALTER TABLE Viajes
ADD CONSTRAINT CHK_ESTADO_VIAJE CHECK (Estado IN ('Programado', 'Completado', 'Cancelado'));
GO

--CLIENTES
ALTER TABLE Clientes
ADD CONSTRAINT UQ_EMAIL_UNICO UNIQUE (Email);   -- Para que no se repitan registros de clientes con el mismo email

ALTER TABLE Clientes
ALTER COLUMN Email VARCHAR(50) NOT NULL;	 --unico. cambiar de null a not null para que sea obligatorio en caso de comunicacion 

ALTER TABLE Clientes
ALTER COLUMN Telefono VARCHAR(20) NOT NULL;	  --cambiar el tipo de dato a INT para evitar texto y de null a not null para que sea obligatorio en caso de comunicacion 

ALTER TABLE Clientes
ADD CONSTRAINT CHK_Telefono_solo_numeros CHECK (Telefono NOT LIKE '%[^0-9]%');	--prohibe en la base de datos aceptar espacios, letras o caracteres de texto y se queda unicamente con valores numericos

ALTER TABLE Clientes
ADD CONSTRAINT UQ_CEDULA_UNICA UNIQUE (Cedula);		--La cedula de cada persona es unica y no se repite
GO

--BOLETOS
ALTER TABLE Boletos
ADD CONSTRAINT UQ_NUMASIENTO_VIAJE UNIQUE (NumeroAsiento, ViajeID);

ALTER TABLE Boletos
ADD CONSTRAINT CHK_WEB_TAQUILLA CHECK ( Canal In ( 'Taquilla', 'Web'));

ALTER TABLE Boletos
ADD CONSTRAINT CHK_PRECIO CHECK (Precio > 0);

ALTER TABLE Boletos
ADD CONSTRAINT CHK_ESTADO CHECK ( Estado In ( 'Activo', 'Anulado'));
GO

--PAGOS
ALTER TABLE Pagos
ADD CONSTRAINT CHK_METODO_PAGO CHECK ( Metodo IN ( 'Efectivo', 'Tarjeta', 'Transferencia'));

ALTER TABLE Pagos
ADD CONSTRAINT CHK_MONTO_PAGO CHECK (MONTO > 0);
GO

