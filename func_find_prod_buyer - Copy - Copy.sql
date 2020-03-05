--CRE BY   : SIVARAM
--CRE DATE : 23-JAN-2007
-- select func_find_prod_buyer('MEL','B0040',0) FROM DUAL;

CREATE OR REPLACE FUNCTION func_find_prod_buyer (
   var_bu         VARCHAR2,
   var_prod_id    VARCHAR2,
   var_prod_rev   NUMBER,
   var_plnt	  VARCHAR2
)
   RETURN VARCHAR2
IS 
   CURSOR c1
   IS
      SELECT *
        FROM prod_plants
       WHERE prodplnt_bu = var_bu
         AND prodplnt_prod_id = var_prod_id
         AND prodplnt_prod_rev = var_prod_rev
         AND prodplnt_plnt = var_plnt;

   cr1            c1%ROWTYPE;
   var_buyer_id   VARCHAR2 (10);
BEGIN
   OPEN c1;
   FETCH c1 INTO cr1;

   IF c1%FOUND THEN
      --raise_application_error (-20260, 'Refer Error Table');
   --ELSE
      var_buyer_id := cr1.prodplnt_buyer_id;
   END IF;
   RETURN NVL (var_buyer_id, NULL);
   CLOSE c1;
END;
/
.
SHOW ERRORS;
