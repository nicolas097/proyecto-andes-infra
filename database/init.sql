CREATE TABLE IF NOT EXISTS empleado (
    id_empleado serial primary key,
    nombres varchar not null,
    apellidos varchar not null
);


ALTER TABLE empleado OWNER TO postgres;

-- 3. Permisos de acceso para tu usuario personal de IAM
-- Esto asegura que cuando entres como nico.gcp.dev@gmail.com tengas control total.
GRANT ALL PRIVILEGES ON TABLE empleado TO "nico.gcp.dev@gmail.com";

-- 4. Permisos para el grupo general de usuarios IAM (Opcional pero recomendado)
GRANT ALL PRIVILEGES ON TABLE empleado TO cloudsqliamuser;