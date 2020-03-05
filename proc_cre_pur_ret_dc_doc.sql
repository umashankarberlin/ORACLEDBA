-- VAR a varchar2(10);
-- EXEC proc_cre_pur_ret_dc_doc('MSIL','PRTN','200809000034','S0173','SARASWATHY',:a);
CREATE OR REPLACE PROCEDURE proc_cre_pur_ret_dc_doc
(
 p_bu		VARCHAR2,
 p_return_pfx	VARCHAR2,
 p_return_no	VARCHAR2,
 p_suplr_id	VARCHAR2,
 p_plnt		VARCHAR2,
 p_user		VARCHAR2,
 p_res	   OUT  VARCHAR2
) IS

CURSOR c1
IS
SELECT prtln_prod_id,
       prtln_prod_rev,
       pol_uom,
       prtln_return_qty,
       prtln_pur_unit_cost,
       prtln_receipt_pfx,
       prtln_receipt_no,
       prtln_upd_ref1
  FROM pur_return_ln,
       pur_order_ln
 WHERE prtln_bu = pol_bu
   AND prtln_po_pfx = pol_order_pfx
   AND prtln_po_no = pol_order_no
   AND prtln_po_seq_no = pol_seq_no
   AND prtln_bu = p_bu
   AND prtln_order_pfx = p_return_pfx
   AND prtln_order_no = p_return_no;

var_dc_no	  VARCHAR2(15);
var_year	  NUMBER(6);
var_period	  NUMBER(2);	
var_prod_desc1	  VARCHAR2(50);
var_prod_desc2    VARCHAR2(50);
var_seq_no	  NUMBER(5):=0;

BEGIN
        
         
	proc_find_year_period(p_bu,TO_DATE(SYSDATE),var_year,var_period);
	var_dc_no := func_find_dc_next_id(p_bu,var_year,'RC',p_user,p_plnt);
	
	INSERT INTO dc_hd(
			  dchd_bu,                
			  dchd_doc_no,            
			  dchd_date,              
			  dchd_suplr_id,          
			  dchd_type,              
			  dchd_order_pfx,         
			  dchd_order_no,          
			  dchd_return_flag,
			  dchd_reference,         
			  dchd_cre_by,            
			  dchd_cre_date,          
			  dchd_upd_by,            
			  dchd_upd_date,          
			  dchd_status,
			  dchd_plnt
			 )
	           VALUES(
	           	  p_bu,
	           	  var_dc_no,
	           	  TRUNC(sysdate),
	           	  p_suplr_id,
	           	  'PT',
	           	  p_return_pfx,
	           	  p_return_no,
	           	  'N',
	           	  NULL,
	           	  p_user,
	           	  SYSDATE,
	           	  NULL,
	           	  NULL,
	           	  'L',
	           	  p_plnt
	           	 );
	           	 
	FOR cr1 IN c1
	LOOP
		var_seq_no := var_seq_no + 1;
		proc_find_prod_desc(p_bu,cr1.prtln_prod_id,cr1.prtln_prod_rev,var_prod_desc1,var_prod_desc2);
		
		INSERT INTO dc_ln(
				  dcln_bu,                
				  dcln_doc_no,            
				  dcln_seq_no,            
				  dcln_prod_id,           
				  dcln_prod_rev,          
				  dcln_prod_desc1,        
				  dcln_prod_desc2,        
				  dcln_uom,               
				  dcln_qty,               
				  dcln_sc_unit_cost,
				  dcln_cre_by,            
				  dcln_cre_date,          
				  dcln_upd_by,            
				  dcln_upd_date,          
				  dcln_reference,
				  dcln_plnt
				 )
		           VALUES(
		                  p_bu,
		                  var_dc_no,
		                  var_seq_no,
		                  cr1.prtln_prod_id,
		                  cr1.prtln_prod_rev,
		                  var_prod_desc1,
		                  var_prod_desc2,
		                  cr1.pol_uom,
		                  cr1.prtln_return_qty,
		                  cr1.prtln_pur_unit_cost,
		                  p_user,
		                  SYSDATE,
		                  NULL,
		                  NULL,
		                  SUBSTR((cr1.prtln_receipt_pfx||'/'||cr1.prtln_receipt_no||cr1.prtln_upd_ref1),1,99),
		                  p_plnt
		                 );
	END LOOP;
p_res := var_dc_no;
commit;
END;
/

SHO ERR;