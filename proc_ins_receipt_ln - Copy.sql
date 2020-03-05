/*

Revision History
-------------------------------------------------------------------------
|Revision |Last Update By     | Last Update Date |Purpose                |
|         |                   |                  |                       |
-------------------------------------------------------------------------
|1        |Rangarajan         | 26-Jan-2006      |Coding and development |
|         |                   |                  |                       |
-------------------------------------------------------------------------

Description of the Procedure:

   THIS PROCEDEDURE IS USED TO INSERT RECORD FROM  PUR_ORD_RECEIPT_LN_TMP TO  PUR_ORD_RECEIPT_LN TABLE
   AND FOR GIVEN RECEIPT PFX , NO, SESSION AND SELECTED LINES ONLY.

 The procedures takes the parameters like bu, p_receipt_pfx, p_receipt_no,
 p_user,p_session

Referenced by  :

References     :
*/

CREATE OR REPLACE PROCEDURE proc_ins_receipt_ln(
     p_bu              VARCHAR2,
     p_plnt	       VARCHAR2,
     p_receipt_pfx     VARCHAR2,
     p_receipt_no      VARCHAR2,
     p_user            VARCHAR2,
     p_session         VARCHAR2
) IS
     v_seq_no           NUMBER := 0;
     v_accepted_qty     NUMBER := 0;
     v_qc_qty           NUMBER := 0;
     v_store		VARCHAR2(10);
     v_store_name	VARCHAR2(50);
     var_res		VARCHAR2(5);

     /*
         BELOW CURSOR IS USED TO FETCH RECORD FROM  PUR_ORD_RECEIPT_LN_TMP TABLE.
    */
     CURSOR c1 IS
          SELECT *
            FROM pur_ord_receipt_ln_tmp
           WHERE porlt_bu = p_bu
             AND porlt_plnt = p_plnt
             AND porlt_select_flag = 'Y'
             AND porlt_session_id = p_session
             AND porlt_receipt_temp_qty > 0;
     
     CURSOR c2(p_order_pfx VARCHAR2,
                    p_order_no VARCHAR2,
                    p_seq_no NUMBER,
                    p_sub_seq_no NUMBER)
                 IS SELECT porlt_po_seq_no,
          		    porlt_po_sub_seq_no,
          	       	    poptc_tc_id,
          	       	    poptc_tc_amt,
          	       	    poptc_source_flag,
          	       	    porlt_receipt_temp_qty,
          	       	    pol_ordered_qty,
          	       	    poh_mode,
          	       	    porlt_seq_no
          	       FROM po_prod_tax_charges,
          	       	    pur_ord_receipt_ln_tmp,
          	            pur_order_ln,
			    pur_order_hd
          	      WHERE poptc_bu = p_bu
          	        AND poptc_bu = porlt_bu
          	        AND poptc_po_pfx = porlt_po_pfx
          	   	AND poptc_po_no = porlt_po_no
          	   	AND poptc_seq_no = porlt_po_seq_no
          	        AND poptc_mode = decode (poh_mode,'PO','PO','SC')
          	        AND poptc_po_pfx = p_order_pfx
          	        AND poptc_po_no = p_order_no
          	        AND porlt_select_flag = 'Y'
			AND poh_bu = pol_bu
			AND poh_order_pfx = pol_order_pfx
			AND poh_order_no = pol_order_no
          	        AND porlt_bu = pol_bu
          	        AND porlt_plnt = p_plnt
          	        AND porlt_po_pfx = pol_order_pfx
          	        AND porlt_po_no = pol_order_no
          	        AND porlt_po_seq_no = pol_seq_no
          	        AND porlt_po_seq_no = p_seq_no
          	        AND porlt_po_sub_seq_no = p_sub_seq_no
     	        	AND porlt_session_id = p_session;
     	        	
     	        	 CURSOR c3(p_order_pfx VARCHAR2,
					 p_order_no VARCHAR2,
					 p_seq_no NUMBER,
					 p_sub_seq_no NUMBER)
				      IS SELECT porlt_po_seq_no,
					    porlt_po_sub_seq_no,
					    potc_tc_id,
					    potc_tc_amt,
					    potc_source_flag,
					    porlt_receipt_temp_qty,
					    pol_ordered_qty,
					    poh_mode,
					    porlt_seq_no
				       FROM po_tax_charges,
					    pur_ord_receipt_ln_tmp,
					    pur_order_ln,
					    pur_order_hd
				      WHERE potc_bu = p_bu
					AND potc_bu = porlt_bu
					AND potc_po_pfx = porlt_po_pfx
					AND potc_po_no = porlt_po_no
					AND potc_mode = decode (poh_mode,'PO','PO','SC')
					AND potc_po_pfx = p_order_pfx
					AND potc_po_no = p_order_no
					AND porlt_select_flag = 'Y'
					AND poh_bu = pol_bu
					AND poh_order_pfx = pol_order_pfx
					AND poh_order_no = pol_order_no
					AND porlt_bu = pol_bu
					AND porlt_plnt = p_plnt
					AND porlt_po_pfx = pol_order_pfx
					AND porlt_po_no = pol_order_no
					AND porlt_po_seq_no = pol_seq_no
					AND porlt_po_seq_no = p_seq_no
					AND porlt_po_sub_seq_no = p_sub_seq_no
     	        			AND porlt_session_id = p_session;
      
 cr2		c2%ROWTYPE;  
 cr3            c3%ROWTYPE;
 var_mode	VARCHAR2(2);
  var_mode1	VARCHAR2(2);
 
BEGIN
     /*
            THIS PART WILL GET RECORD IF FETCH BUTTON PRESSED MORE THAN ONE TIMES.
         BELOW CURSOR IS USED TO NAVIGATE RECORD ONE BY ONE.
    */
     FOR cr_delete IN (SELECT *
                         FROM pur_ord_receipt_ln
                        WHERE porl_bu = p_bu
                          AND porl_receipt_pfx = p_receipt_pfx
                          AND porl_receipt_no = p_receipt_no
                          AND porl_status IN('N', 'Q'))
     LOOP
          /*
              BELOW CURSOR IS USED TO REDUCE QC TEMP QTY IN PUR_ORDER_LN, PUR_ORD_LN_SCHEDULE
              TABLE IF FETCH MORE THAN ONE TIME
         */
          UPDATE pur_order_ln
             SET pol_qc_temp_qty = pol_qc_temp_qty - cr_delete.porl_receipt_qty
           WHERE pol_bu = p_bu
             AND pol_order_pfx = cr_delete.porl_po_pfx
             AND pol_order_no = cr_delete.porl_po_no
             AND pol_seq_no = cr_delete.porl_po_seq_no;

          UPDATE pur_ord_ln_schedule
             SET pols_qc_temp_qty =   pols_qc_temp_qty
                                    - cr_delete.porl_receipt_qty
           WHERE pols_bu = p_bu
             AND pols_plnt = p_plnt
             AND pols_order_pfx = cr_delete.porl_po_pfx
             AND pols_order_no = cr_delete.porl_po_no
             AND pols_seq_no = cr_delete.porl_po_seq_no
             AND pols_sub_seq_no = cr_delete.porl_po_sub_seq_no;
     END LOOP;
     /*
            THIS PART WILL DELETE RECORD IF FETCH BUTTON PRESSED MORE THAN ONE TIMES.
         BELOW CURSOR IS USED TO DELETE RECORD IN PUR_ORD_RECEIPT_LN
         TABLE IF FETCH MORE THAN ONE TIME
    */
    --raise_application_error(-20999,'chk1');
    
        DELETE FROM por_prod_tax_charges
    	WHERE  porptc_bu = p_bu
    	AND    porptc_receipt_pfx = p_receipt_pfx
    	AND    porptc_receipt_no = p_receipt_no;
    	
    DELETE FROM pur_ord_receipt_ln
           WHERE porl_bu = p_bu
             AND porl_receipt_pfx = p_receipt_pfx
             AND porl_receipt_no = p_receipt_no;
      
    /*
         BELOW CURSOR IS USED TO FETCH RECORD FROM  PUR_ORD_RECEIPT_LN_TMP TABLE.
    */
     FOR cr1 IN c1
     LOOP
          SELECT NVL(MAX(porl_seq_no), 0) + 1
            INTO v_seq_no
            FROM pur_ord_receipt_ln
           WHERE porl_bu = p_bu
             AND porl_receipt_pfx = p_receipt_pfx
             AND porl_receipt_no = p_receipt_no;

          IF (cr1.porlt_qc_required = 'Y') THEN
               v_qc_qty := cr1.porlt_receipt_temp_qty;
               v_accepted_qty := 0;
          ELSIF (cr1.porlt_qc_required = 'N') THEN
               v_qc_qty := 0;
               v_accepted_qty := cr1.porlt_receipt_temp_qty;
          END IF;
          
          IF (cr1.porlt_sc_suplr_flag = 'Y') THEN
		 v_store := func_find_pom_ctrl_store(p_bu);
		 v_store_name := func_find_store_desc(p_bu,v_store);
	 ELSIF (cr1.porlt_sc_suplr_flag IN ('N','D')) THEN
		 v_store := cr1.porlt_storage_store_id;
		 v_store_name := cr1.porlt_storage_store_name;
          END IF;
          /*
              BELOW STATEMENT IS USED TO INSERT RECORD IN PUR_ORD_RECEIPT_LN TABLE.
         */
          INSERT INTO pur_ord_receipt_ln
                      (
                      porl_bu,
                      porl_receipt_pfx,
                      porl_receipt_no,
                      porl_seq_no,
                      porl_po_pfx,
                      porl_po_no,
                      porl_po_seq_no,
                      porl_po_sub_seq_no,
                      porl_sc_unit_cost,
                      porl_disc_pct,
                      porl_bc_land_cost,
                      porl_sc_chrg_amt,
                      porl_sc_non_chrg_amt,
                      porl_sc_lm_disc_amt,
                      porl_scon_mat_unit_cost,
                      porl_scon_lbr_unit_cost,
                      porl_receipt_qty,
                      porl_accepted_qty,
                      porl_rejected_qty,
                      porl_qc_qty,
                      porl_rtnto_suplr_qty,
                      porl_inv_qty,
                      porl_rtnd_doc_qty,
                      porl_net_disc_flag,
                      porl_status,
                      porl_cre_by,
                      porl_cre_date,
                      porl_bom_no,
                      porl_plnt,
                      porl_storage_store_id,
                      porl_storage_store_name,
                      porl_tot_accepted_qty,
                      porl_tot_rejected_qty,
                      porl_conv_factor,
                      porl_stock_receipt_qty,
                      porl_stk_upd_qty,
                      porl_lvl_prod_id,
                      porl_lvl_prod_rev,
                      porl_sc_suplr_flag,
                      porl_commodity_code
                      )
               VALUES (
                      p_bu,
                      p_receipt_pfx,
                      p_receipt_no,
                      v_seq_no,
                      cr1.porlt_po_pfx,
                      cr1.porlt_po_no,
                      cr1.porlt_po_seq_no,
                      cr1.porlt_po_sub_seq_no,
                      NVL(cr1.porlt_sc_unit_cost, 0),
                      cr1.porlt_disc_pct,
                      0,
                      0,
                      0,
                      0,
                      0,
                      NVL(cr1.porlt_scon_lbr_unit_cost,0),
                      cr1.porlt_receipt_temp_qty,
                      v_accepted_qty,
                      0,
                      v_qc_qty,
                      0,
                      0,
                      0,
                      cr1.porlt_net_disc_flag,
                      DECODE(cr1.porlt_qc_required, 'Y', 'N', 'N', 'Q'),
                      p_user,
                      SYSDATE,
                      cr1.porlt_bom_no,
                      cr1.porlt_plnt,
                      v_store,
                      v_store_name,
                      0,
                      0,
                      cr1.porlt_conv_factor,
                      cr1.porlt_receipt_temp_qty/cr1.porlt_conv_factor,
                      cr1.porlt_receipt_temp_qty/cr1.porlt_conv_factor,
                      cr1.porlt_lvl_prod_id,
                      cr1.porlt_lvl_prod_rev,
                      cr1.porlt_sc_suplr_flag,
                      cr1.porlt_commodity_code
                      );
          /* BELOW CURSOR IS USED TO INSERT THE TAX CHARGES AFTER IT HAS BEEN INSERTED IN PUR_ORD_RECEIPT_LN*/
	           OPEN c2(cr1.porlt_po_pfx,
	                   cr1.porlt_po_no,
	                   cr1.porlt_po_seq_no,
	                   cr1.porlt_po_sub_seq_no);
	           FETCH c2 INTO cr2;
	           
	           IF cr2.poh_mode = 'PO' THEN
	           	var_mode := 'PO';
	           ELSE
	           	var_mode := 'SC';
	           END IF;
	           	
	           IF c2%FOUND THEN 
	         --  Raise_application_error(-20999,'chk'||cr1.porlt_po_seq_no);
	           	proc_ins_po_receipt_tax(p_bu,
	  	   	                        cr1.porlt_po_pfx,
	  	   	                        cr1.porlt_po_no,
	  	   	                        cr1.porlt_po_seq_no,
	  	   	                        cr1.porlt_po_sub_seq_no,
	  	   	                        p_receipt_pfx,
	  					p_receipt_no,
	  					var_mode,
	  					p_user,
	  					p_session,
	  					v_seq_no,
	  					var_res
	    					);
	  	END IF;
		CLOSE c2;
		
		/* BELOW CURSOR IS USED TO INSERT THE ORDER TAX CHARGES AFTER IT HAS BEEN INSERTED IN PUR_ORD_RECEIPT_LN*/
			   OPEN C3(cr1.porlt_po_pfx,
				   cr1.porlt_po_no,
				   cr1.porlt_po_seq_no,
				   cr1.porlt_po_sub_seq_no);
			   FETCH C3 INTO CR3;

			   IF cr3.poh_mode = 'PO' THEN
						var_mode1 := 'PO';
					   ELSE
						var_mode1 := 'SC';
				 END IF;
			   IF C3%FOUND THEN 

			 --  Raise_application_error(-20999,'chk'||cr1.porlt_po_seq_no);
				proc_ins_po_receipt_tax(p_bu,
							 cr1.porlt_po_pfx,
							 cr1.porlt_po_no,
							 cr1.porlt_po_seq_no,
							 cr1.porlt_po_sub_seq_no,
							 p_receipt_pfx,
							 p_receipt_no,
							 var_mode1,
							 p_user,
							 p_session,
							 v_seq_no,
							 var_res
							);
			END IF;
	CLOSE C3;
          /*
              BELOW CURSOR IS USED TO INCREASE QC TEMP QTY IN PUR_ORDER_LN, PUR_ORD_LN_SCHEDULE
              TABLE
         */
          UPDATE pur_order_ln
             SET pol_qc_temp_qty = pol_qc_temp_qty + cr1.porlt_receipt_temp_qty
           WHERE pol_bu = p_bu
             AND pol_order_pfx = cr1.porlt_po_pfx
             AND pol_order_no = cr1.porlt_po_no
             AND pol_seq_no = cr1.porlt_po_seq_no;

          UPDATE pur_ord_ln_schedule
             SET pols_qc_temp_qty =   pols_qc_temp_qty + cr1.porlt_receipt_temp_qty
           WHERE pols_bu = p_bu
             AND pols_plnt = p_plnt
             AND pols_order_pfx = cr1.porlt_po_pfx
             AND pols_order_no = cr1.porlt_po_no
             AND pols_seq_no = cr1.porlt_po_seq_no
             AND pols_sub_seq_no = cr1.porlt_po_sub_seq_no;
     END LOOP;
       DELETE         pur_ord_receipt_ln_tmp
               WHERE porlt_session_id = p_session;
     COMMIT;
END;
/

SHOW ERRORS;
