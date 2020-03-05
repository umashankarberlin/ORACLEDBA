/*
Revision History
-------------------------------------------------------------------------
|Revision |Last Update By     | Last Update Date |Purpose                |
|         |                   |                  |                       |
-------------------------------------------------------------------------
|1        |M.Sivaprakash      | 01-MARCH-2006    |Coding and development |
|         |                   |                  |                       |
-------------------------------------------------------------------------
|2        |Ms.Suresh          | 07-May-2007      |Documentation          |
|         |                   |                  |                       |
-------------------------------------------------------------------------
Description of the Functions:

  1. This Function is used to find the purchase product cost basis.

  2. This function takes the parameters like bu,product id,rev.

  3. This function  return the value purchase product price basis.  */



CREATE OR REPLACE FUNCTION func_find_prod_price_basis(
     p_bu           VARCHAR2,
     p_prod_id      VARCHAR2,
     p_prod_rev     NUMBER
)
     RETURN VARCHAR2 IS
     /* cursor c1 fetches the purchase product price basis from product table for given parameter*/
     CURSOR c1 IS
          SELECT prod_pur_price_basis
            FROM products
           WHERE prod_bu = p_bu
             AND prod_id = p_prod_id
             AND prod_rev = p_prod_rev;

     cr1     c1%ROWTYPE;
BEGIN
     OPEN c1;
     FETCH c1 INTO cr1;

     IF c1%NOTFOUND THEN
          raise_application_error(-20330, 'Refer Error Table');
     ELSIF c1%FOUND THEN
          CLOSE c1;

          IF cr1.prod_pur_price_basis IS NULL THEN
               raise_application_error(-20330, 'Refer Error Table');
          END IF;

          RETURN cr1.prod_pur_price_basis;
     END IF;
END;
/
