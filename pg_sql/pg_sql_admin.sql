-- # Admin scripts

SELECT * FROM pg_stat_activity;

SELECT * FROM pg_roles;

SELECT * FROM information_schema.role_table_grants WHERE grantee = 'uhlldw';
SELECT * FROM pg_tables WHERE tableowner = 'uhlldw';

SELECT datname,oid,pg_catalog.pg_get_userbyid(datdba) as "Owner",* FROM pg_database;
SELECT * FROM pg_tablespace;

SELECT d.datname as "Name", pg_catalog.pg_get_userbyid(d.datdba) as "Owner" FROM pg_catalog.pg_database d WHERE d.datname = 'hlldw';
ORDER BY 1;

SELECT  table_name,  column_name,  data_type FROM  information_schema.columns WHERE  table_name = 'playerstats';

SELECT relfilenode,* FROM pg_class WHERE relkind='r';

SELECT * FROM pg_tables

SELECT * FROM pg_settings WHERE name = 'extra_float_digits';

SELECT * FROM pg_settings WHERE name = 'port';
select inet_server_addr( ), inet_server_port( );
SELECT * FROM pg_conversion;
SELECT * FROM information_schema.character_sets

select * from information_schema.TABLES
SELECT DISTINCT pg_catalog.pg_encoding_to_char(conforencoding) from pg_catalog.pg_conversion;
SELECT * FROM pg_stat_activity

SELECT * FROM pg_database;
SELECT * FROM pg_collation

SELECT 'a'='a';
SELECT 'a'='á';
SELECT 'a'='A';
SELECT 'A'='A';
SELECT 'n'='ñ';

--Mostrar los tipos de operadores de ordenación de índices (Postgres 14)
SELECT am.amname AS index_method,
       opc.opcname AS opclass_name,
       opc.opcintype::regtype AS indexed_type,
       opc.opcdefault AS is_default
    FROM pg_am am, pg_opclass opc
    WHERE opc.opcmethod = am.oid
    ORDER BY index_method, opclass_name;

	SELECT  table_name,  column_name,  data_type FROM  information_schema.columns WHERE  table_name = 'pg_amop';