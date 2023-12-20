-- # POSTGRESQL util functions

CREATE OR REPLACE FUNCTION IIF(vCondition boolean, true_result anyelement, false_result anyelement) RETURNS anyelement AS $f$
  SELECT CASE WHEN vCondition THEN true_result ELSE false_result END
$f$  LANGUAGE SQL IMMUTABLE;

-- Invoking IIF(condition,when-true,when-false)

