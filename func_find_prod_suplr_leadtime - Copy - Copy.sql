/*
Revision History
-------------------------------------------------------------------------
|Revision |Last Update By     | Last Update Date |Purpose                |
|         |                   |                  |                       |
-------------------------------------------------------------------------
|1        |K.Yoga Priya       | 02-Feb-2007      |Coding and development |
|         |                   |                  |                       |
-------------------------------------------------------------------------
|2        |Suresh             | 07-May-2007      |Documentation          |
|         |                   |                  |                       |
-------------------------------------------------------------------------
Description of the Functions:

 1.This Function is used to find the purchase lead time based on prod_lead_time_source value=P to 
   fetch value product table,prod_lead_time_source value=S to fetch value supplier product

 2.This function takes the parameters like bu,supplier id,product id, product rev.

 3.This function  return the value purchase lead time based notfound return value 0  */



CREATE OR REPLACE FUNCTION func_find_prod_suplr_leadtime(
     p_bu           VARCHAR2,
     p_plnt	    VARCHAR2,
     p_suplr_id     VARCHAR2,
     p_prod_id      VARCHAR2,
     p_prod_rev     NUMBER,
     p_rqrd_qty	    NUMBER
)
     RETURN NUMBER IS
     /* cursor c1 fetches the purchase lead time  from product table for given parameter*/
     CURSOR c1 IS
          SELECT prod_pur_lead_time,
                 prod_lead_time_source
            FROM products
           WHERE prod_bu = p_bu
             AND prod_id = p_prod_id
             AND prod_rev = p_prod_rev;

     /* cursor c2 fetches the purchase lead time  from supplier products table for given parameter*/
     CURSOR c2 IS
          SELECT suprprod_lead_time
            FROM suplr_products
           WHERE suprprod_bu = p_bu
             AND suprprod_suplr_id = p_suplr_id
             AND suprprod_prod_id = p_prod_id
             AND suprprod_prod_rev = p_prod_rev
             AND suprprod_plnt = p_plnt;

     cr1     		c1%ROWTYPE;
     cr2     		c2%ROWTYPE;
     var_lead_time	NUMBER;
     
BEGIN
     OPEN c1;
     FETCH c1 INTO cr1;

	     IF cr1.prod_lead_time_source = 'S' THEN
		  OPEN c2;
		  FETCH c2 INTO cr2;

		  IF c2%NOTFOUND THEN
		       var_lead_time:= 0;
		  ELSE
		       var_lead_time:= cr2.suprprod_lead_time;
		  END IF;

		  CLOSE c2;
	     ELSIF cr1.prod_lead_time_source = 'P' THEN
		  var_lead_time := func_find_product_leadtime(
						p_bu,
						p_plnt,
						p_prod_id,
						p_prod_rev,
						p_rqrd_qty,
						'POM');
	     END IF;

     CLOSE c1;
     
     RETURN var_lead_time;
END;
/

SHOW error;
