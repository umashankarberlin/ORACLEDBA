-- CREATED BY : U.SELVAGANAPATHY
CREATE OR REPLACE PROCEDURE proc_ins_po_receipt_tax
			    (
			     p_bu 		VARCHAR2,
			     p_order_pfx 	VARCHAR2,
			     p_order_no 	VARCHAR2,
			     p_order_seq_no	NUMBER,
			     p_order_sub_seq_no	NUMBER,
			     p_receipt_pfx 	VARCHAR2,
			     p_receipt_no 	VARCHAR2,
			     p_mode		VARCHAR2,
			     p_user 		VARCHAR2,
			     p_ses		VARCHAR2,
			     p_seq_no		NUMBER,
			     var_res    OUT	VARCHAR2
			    )
IS
CURSOR c1 IS SELECT porlt_po_seq_no,
		    porlt_po_sub_seq_no,
	       	    poptc_tc_id,
	       	    poptc_charge_flag,
	       	    poptc_tc_amt,
	       	    poptc_source_flag,
	       	    porlt_receipt_temp_qty,
	       	    pol_ordered_qty,
	       	    porlt_seq_no
	       FROM po_prod_tax_charges,
	       	    pur_ord_receipt_ln_tmp,
	            pur_order_ln
	      WHERE poptc_bu = p_bu
	        AND poptc_bu = porlt_bu
	   	AND poptc_po_pfx = porlt_po_pfx
	   	AND poptc_po_no = porlt_po_no
	   	AND poptc_seq_no = porlt_po_seq_no
	        AND poptc_mode = p_mode   --'PO'
	        AND poptc_po_pfx = p_order_pfx
	        AND poptc_po_no = p_order_no
	        AND porlt_select_flag = 'Y'
	        AND porlt_bu = pol_bu
	        AND porlt_po_pfx = pol_order_pfx
	        AND porlt_po_no = pol_order_no
	        AND porlt_po_seq_no = pol_seq_no
	        AND porlt_po_seq_no = p_order_seq_no
	        AND porlt_po_sub_seq_no = p_order_sub_seq_no
	        AND porlt_session_id = p_ses;

CURSOR c2 IS SELECT poctc_cls_id,
		    poctc_tc_id,
		    poctc_charge_flag,
	       	    poctc_tc_amt,
	       	    poctc_source_flag,
	       	    SUM(porlt_receipt_temp_qty) sum_porlt_receipt_temp_qty,
	       	    SUM(pol_ordered_qty) sum_pol_ordered_qty
	       FROM pur_order_ln,
	            po_class_tax_charges,
	            pur_ord_receipt_ln_tmp
	      WHERE pol_bu = p_bu
	   	AND pol_bu = poctc_bu
	   	AND pol_order_pfx = poctc_po_pfx
	   	AND pol_order_no = poctc_po_no
	   	AND pol_prod_cls = poctc_cls_id
	   	AND poctc_mode = p_mode		--'PO'
	   	AND pol_bu = porlt_bu
	   	AND pol_order_pfx = porlt_po_pfx
	   	AND pol_order_no = porlt_po_no
	   	AND pol_seq_no = porlt_po_seq_no
	   	AND porlt_select_flag = 'Y'
	   	AND porlt_po_pfx = p_order_pfx
	   	AND porlt_po_no = p_order_no
	   GROUP BY poctc_cls_id,poctc_tc_id,poctc_charge_flag,poctc_tc_amt,poctc_source_flag;
	   
CURSOR c3 IS SELECT potc_tc_id,
		    potc_charge_flag,
		    potc_tc_amt,
		    potc_source_flag,
		    SUM(porlt_receipt_temp_qty * DECODE(p_mode,'PO',porlt_sc_unit_cost,
		    					       'SC',porlt_scon_lbr_unit_cost))
		    sum_porlt_receipt_qty_amt
               FROM po_tax_charges,
               	    pur_ord_receipt_ln_tmp
	      WHERE potc_bu = p_bu
	      	AND potc_bu = porlt_bu
	      	AND potc_po_pfx = porlt_po_pfx
	      	AND potc_po_no = porlt_po_no
	      	AND potc_mode = p_mode    --'PO'
	      	AND potc_po_pfx = p_order_pfx
	        AND potc_po_no = p_order_no
	   GROUP BY potc_tc_id,potc_charge_flag,potc_tc_amt,potc_source_flag;
	        
CURSOR c4 IS SELECT porlt_po_seq_no,
		    porlt_po_sub_seq_no,
	       	    popts_tc_id,
	       	    popts_tc_amt,
	            porlt_receipt_temp_qty,
	            DECODE(p_mode,'PO',porlt_sc_unit_cost,
		    		  'SC',porlt_scon_lbr_unit_cost) porlt_sc_unit_cost,
	            pol_ordered_qty
	       FROM po_prod_tc_shares,
	            pur_ord_receipt_ln_tmp,
	            pur_order_ln
	      WHERE popts_bu = p_bu
	        AND popts_bu = porlt_bu
	   	AND popts_po_pfx = porlt_po_pfx
	   	AND popts_po_no = porlt_po_no
	   	AND popts_seq_no = porlt_po_seq_no
	   	AND popts_mode = p_mode   --'PO'
	   	AND porlt_select_flag = 'Y'
	   	AND porlt_bu = pol_bu
	   	AND porlt_po_pfx = pol_order_pfx
	   	AND porlt_po_no = pol_order_no
	   	AND porlt_po_seq_no = pol_seq_no
	   	AND porlt_po_pfx = p_order_pfx
	   	AND porlt_po_no = p_order_no;
	   	
CURSOR c5 IS SELECT SUM(pol_ordered_qty * DECODE(p_mode,'PO',pol_sc_unit_cost,
							'SC',pol_scon_lbr_unit_cost))
		    sum_pol_ordered_qty_amt
	       FROM pur_order_ln
	      WHERE pol_bu = p_bu
	        AND pol_order_pfx = p_order_pfx
	        AND pol_order_no = p_order_no;
	        
CURSOR c6 IS SELECT poh_tax_flag,
		    poh_tc_set_id
	       FROM pur_order_hd
	      WHERE poh_bu = p_bu
	        AND poh_order_pfx = p_order_pfx
	        AND poh_order_no = p_order_no
	        AND poh_tax_flag = 'Y';	        
	        
cr5	c5%ROWTYPE;
cr6	c6%ROWTYPE;
	   	
BEGIN

  DELETE por_prod_tax_charges
   WHERE porptc_bu = p_bu
     AND porptc_receipt_pfx = p_receipt_pfx
     AND porptc_receipt_no = p_receipt_no
     AND porptc_po_pfx = p_order_pfx
     AND porptc_po_no = p_order_pfx
     AND porptc_mode = DECODE (p_mode,'PO','PR','SC');
     
  DELETE por_class_tax_charges
   WHERE porctc_bu = p_bu
     AND porctc_receipt_pfx = p_receipt_pfx
     AND porctc_receipt_no = p_receipt_no
     AND porctc_mode = DECODE (p_mode,'PO','PR','SC');
     
  DELETE po_receipt_tax_charges
   WHERE porectc_bu = p_bu            
     AND porectc_receipt_pfx = p_receipt_pfx
     AND porectc_receipt_no = p_receipt_no   
     AND porectc_mode = DECODE (p_mode,'PO','PR','SC');
	 
  /*DELETE por_tax_charges
   WHERE portc_bu = p_bu              
     AND portc_receipt_pfx = p_receipt_pfx
     AND portc_receipt_no = p_receipt_no      
     AND portc_po_pfx = p_order_pfx         
     AND portc_po_no = p_order_no;    */ 
     
     
  FOR cr1 IN c1
  LOOP
    INSERT INTO por_prod_tax_charges
               (porptc_bu            ,  
		porptc_receipt_pfx   ,  
		porptc_receipt_no    ,  
		porptc_mode          ,  
		porptc_po_pfx        ,  
		porptc_po_no         ,  
		porptc_seq_no        ,  
		porptc_sub_seq_no    ,  
		porptc_tc_id         ,  
		porptc_tc_amt        ,  
		porptc_source_flag   ,  
		porptc_cre_by        ,  
		porptc_cre_date      , 
		porptc_upd_by        ,  
		porptc_upd_date      ,  
		porptc_charge_flag ,
		porptc_receipt_seq_no
		)
	 VALUES (
		 p_bu,              
		 p_receipt_pfx,
		 p_receipt_no,      
		 DECODE (p_mode,'PO','PR','SC'),            
		 p_order_pfx,          
		 p_order_no,           
		 cr1.porlt_po_seq_no,          
		 cr1.porlt_po_sub_seq_no,      
		 cr1.poptc_tc_id,
		 ((cr1.porlt_receipt_temp_qty / cr1.pol_ordered_qty)
					      * cr1.poptc_tc_amt),    
		 cr1.poptc_source_flag,
		 p_user,       
		 TRUNC(SYSDATE),        
		 NULL,          
		 NULL,
		 cr1.poptc_charge_flag,
		 p_seq_no		 --cr1.porlt_seq_no   
		);
    var_res := 'Y';		
  END LOOP;
  
  FOR cr2 IN c2
  LOOP
    INSERT INTO por_class_tax_charges
                (
                porctc_bu            ,  
		porctc_receipt_pfx   ,  
		porctc_receipt_no    ,  
		porctc_mode          ,  
		porctc_cls_id        ,  
		porctc_tc_id         ,  
		porctc_tc_amt        ,  
		porctc_source_flag   ,  
		porctc_cre_by        ,  
		porctc_cre_date      ,  
		porctc_upd_by        ,  
		porctc_upd_date      ,
		porctc_charge_flag
		
		)
        VALUES (
	   	 p_bu,              
	   	 p_receipt_pfx,
	   	 p_receipt_no,   
	   	 DECODE (p_mode,'PO','PR','SC'),            
	   	 cr2.poctc_cls_id,          
	   	 cr2.poctc_tc_id,
	   	 ((cr2.sum_porlt_receipt_temp_qty / cr2.sum_pol_ordered_qty)
	   	 			    	  * cr2.poctc_tc_amt),
	   	 cr2.poctc_source_flag,
	   	 p_user,          
	   	 TRUNC(SYSDATE),        
		 NULL,          
		 NULL,
		 cr2.poctc_charge_flag
	  	);
    var_res := 'Y';	  	
  END LOOP;
  
  OPEN c5;
  FETCH c5 INTO cr5;
  FOR cr3 IN c3
  LOOP
  --RAISE_APPLICATION_ERROR(-20999,'TEST');
    INSERT INTO po_receipt_tax_charges
                (
                porectc_bu            , 
		porectc_receipt_pfx   , 
		porectc_receipt_no    , 
		porectc_mode          , 
		porectc_tc_id         , 
		porectc_tc_amt        , 
		porectc_source_flag   , 
		porectc_cre_by        , 
		porectc_cre_date      , 
		porectc_upd_by        , 
		porectc_upd_date      , 
		porectc_charge_flag   
		)
         VALUES (
	     	 p_bu,             
	 	 p_receipt_pfx,
	 	 p_receipt_no,     
	 	 DECODE (p_mode,'PO','PR','SC'),           
	 	 cr3.potc_tc_id,
	 	 (cr3.sum_porlt_receipt_qty_amt / cr5.sum_pol_ordered_qty_amt)
	 	 		                * cr3.potc_tc_amt,
	 	 cr3.potc_source_flag,
	 	 p_user,         
	 	 TRUNC(SYSDATE),       
	 	 NULL,         
	 	 NULL ,
	 	 cr3.potc_charge_flag
		);
    var_res := 'Y';		
  END LOOP;  		

  /*FOR cr4 IN c4
  LOOP
    INSERT INTO por_tax_charges
         VALUES (
         	 p_bu,               
		 p_receipt_pfx,      
		 p_receipt_no,       
		 p_order_pfx,
		 p_order_no, 
		 cr4.porlt_po_seq_no,
		 cr4.porlt_po_sub_seq_no,       
		 cr4.popts_tc_id,            
		 ((cr4.porlt_receipt_temp_qty / cr4.pol_ordered_qty)
		 			      * cr4.popts_tc_amt),      
		 p_user,          
		 TRUNC(SYSDATE),        
		 NULL,          
		 NULL
		);
  END LOOP;*/
  
  OPEN c6;
  FETCH c6 INTO cr6;
  IF c6%FOUND THEN
    UPDATE pur_ord_receipt_hd
       SET porh_tax_flag = cr6.poh_tax_flag,
           porh_tc_set_id = cr6.poh_tc_set_id
     WHERE porh_bu = p_bu
       AND porh_receipt_pfx = p_receipt_pfx
       AND porh_receipt_no = p_receipt_no
       AND porh_mode = DECODE(p_mode,'PO','PR','SC');
       
    var_res := 'Y';
  END IF;
  CLOSE c6;
  CLOSE c5;
COMMIT;  
END;
/
.
SHOW ERRORS;