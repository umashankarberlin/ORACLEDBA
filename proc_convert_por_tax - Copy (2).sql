-- Upd BY   : M.sivaprakash
-- Upd Date : Wednesday, December 21, 2005

-- execute proc_convert_por_tax('300','GRN00009');

CREATE OR REPLACE PROCEDURE proc_convert_por_tax (
   var_bu            VARCHAR2,
   var_receipt_pfx   VARCHAR2,
   var_receipt_no    VARCHAR2,
   var_ex_rate       NUMBER
)
IS 
   CURSOR c9 (var_prod_cls VARCHAR2)
   IS
      SELECT SUM (((porl_sc_unit_cost - (porl_sc_unit_cost * porl_disc_pct / 100)) - 
      		   porl_sc_lm_disc_amt) * var_ex_rate * porl_receipt_qty) sum_of_cls_porl_amt,
             SUM(porl_acc_value * porl_receipt_qty) acc_value
        FROM pur_ord_receipt_ln, pur_order_ln
       WHERE porl_bu = var_bu
         AND porl_receipt_pfx = var_receipt_pfx
         AND porl_receipt_no = var_receipt_no
         AND pol_bu = porl_bu
         AND pol_order_pfx = porl_po_pfx
         AND pol_order_no = porl_po_no
         AND pol_seq_no = porl_po_seq_no
         AND pol_prod_cls = var_prod_cls;

   CURSOR c10
   IS
      SELECT SUM (((porl_sc_unit_cost - (porl_sc_unit_cost * porl_disc_pct / 100)) - 
      		   porl_sc_lm_disc_amt) * var_ex_rate * porl_receipt_qty) sum_of_porl_amt,
             SUM(porl_acc_value * porl_receipt_qty) acc_value
        FROM pur_ord_receipt_ln
       WHERE porl_bu = var_bu
         AND porl_receipt_pfx = var_receipt_pfx
         AND porl_receipt_no = var_receipt_no;

   cr10                     c10%ROWTYPE;
   cr9                      c9%ROWTYPE;
   var_aportion_cls_amt     NUMBER (17, 5);
   var_aportion_order_amt   NUMBER (17, 5);
   tax_asset_value          NUMBER (17, 5) := 0;
   tax_expense_value        NUMBER (17, 5) := 0;
   discount_value           NUMBER (17, 5) := 0;
   v_count		    NUMBER := 0;
BEGIN
   -- This cursor is used to navigate the purchase receipts line by line.

   	DELETE por_tax_charges
         WHERE portc_bu = var_bu
           AND portc_receipt_pfx = var_receipt_pfx
           AND portc_receipt_no = var_receipt_no
           AND portc_type IN ('R');

   FOR cr1 IN (SELECT porl_bu, porl_receipt_pfx, porl_receipt_no, porl_seq_no,porl_po_pfx,porl_po_no,
                      porl_po_seq_no, porl_po_sub_seq_no, porl_sc_unit_cost,porl_disc_pct,
                      porl_sc_lm_disc_amt,
                      porl_receipt_qty, porl_accepted_qty, porl_rejected_qty,
                      porl_cre_by, porl_cre_date, porl_upd_by, porl_upd_date,
                      (SELECT pol_prod_cls
                         FROM pur_order_ln
                        WHERE pol_bu = var_bu
                          AND pol_order_pfx = porl_po_pfx
                          AND pol_order_no = porl_po_no
                          AND pol_seq_no = porl_po_seq_no)
                            pol_prod_cls,porl_acc_value
                 FROM pur_ord_receipt_ln
                WHERE porl_bu = var_bu
                  AND porl_receipt_pfx = var_receipt_pfx
                  AND porl_receipt_no = var_receipt_no)
   LOOP
      -- This cursor is used to navigate the product taxes by giving arguments of a  specific product. 

      FOR cr2 IN (SELECT *
                    FROM por_prod_tax_charges
                   WHERE porptc_bu = cr1.porl_bu
                     AND porptc_receipt_pfx = cr1.porl_receipt_pfx
                     AND porptc_receipt_no = cr1.porl_receipt_no
                     AND porptc_receipt_seq_no = cr1.porl_seq_no
		     AND porptc_po_pfx = cr1.porl_po_pfx
                     AND porptc_po_no = cr1.porl_po_no
                     AND porptc_seq_no = cr1.porl_po_seq_no
                     AND porptc_sub_seq_no = cr1.porl_po_sub_seq_no
                     AND porptc_type = 'R')
      LOOP
         INSERT INTO por_tax_charges
                     (portc_bu, portc_receipt_pfx,
                      portc_receipt_no, portc_po_pfx,portc_po_no,
                      portc_seq_no, portc_sub_seq_no,
                      portc_tc_id, portc_charge_flag,
                      portc_tc_unit_amt,
                      portc_cre_by, portc_cre_date,portc_type,portc_receipt_seq_no)
              VALUES (cr2.porptc_bu, cr2.porptc_receipt_pfx,
                      cr2.porptc_receipt_no, cr2.porptc_po_pfx,cr2.porptc_po_no,
                      cr2.porptc_seq_no, cr2.porptc_sub_seq_no,
                      cr2.porptc_tc_id, cr2.porptc_charge_flag,
                      (cr2.porptc_tc_amt) / cr1.porl_receipt_qty,
                      cr2.porptc_cre_by, cr2.porptc_cre_date,cr2.porptc_type,cr2.porptc_receipt_seq_no);
      END LOOP;

      --This cursor is used to navigate the product class taxes by passing parameter as product class.

      FOR cr3 IN (SELECT *
                    FROM por_class_tax_charges
                   WHERE porctc_bu = var_bu
                     AND porctc_receipt_pfx = var_receipt_pfx
                     AND porctc_receipt_no = var_receipt_no
                     AND porctc_cls_id = cr1.pol_prod_cls
                     )
      LOOP
         OPEN c9 (cr1.pol_prod_cls);
         FETCH c9 INTO cr9;

         IF c9%NOTFOUND
         THEN -- purchase receipt total not found
            raise_application_error (-20312, 'refer table');
         END IF;

         CLOSE c9;
         var_aportion_cls_amt :=   (  (cr3.porctc_tc_amt)
                                    * (  ((cr1.porl_sc_unit_cost - (cr1.porl_sc_unit_cost * cr1.porl_disc_pct / 100)) - 
      		   			   cr1.porl_sc_lm_disc_amt) * var_ex_rate * cr1.porl_receipt_qty
                                      )
                                    / cr9.sum_of_cls_porl_amt
                                   )
                                 / cr1.porl_receipt_qty;

         INSERT INTO por_tax_charges
                     (portc_bu, portc_receipt_pfx, portc_receipt_no,
                      portc_po_pfx,portc_po_no, portc_seq_no,
                      portc_sub_seq_no, portc_tc_id, portc_charge_flag,
                      portc_tc_unit_amt, portc_cre_by,
                      portc_cre_date,portc_type)
              VALUES (cr1.porl_bu, cr1.porl_receipt_pfx, cr1.porl_receipt_no,
                      cr1.porl_po_pfx,cr1.porl_po_no, cr1.porl_po_seq_no,
                      cr1.porl_po_sub_seq_no, cr3.porctc_tc_id, cr3.porctc_charge_flag,
                      var_aportion_cls_amt, cr1.porl_cre_by,
                      cr1.porl_cre_date,'R');
      END LOOP;

      FOR cr4 IN (SELECT *
                    FROM po_receipt_tax_charges
                   WHERE porectc_bu = var_bu
                     AND porectc_receipt_pfx = var_receipt_pfx
                     AND porectc_receipt_no = var_receipt_no
                     AND porectc_type IN ('R'))
      LOOP
         OPEN c10;
         FETCH c10 INTO cr10;

         IF c10%NOTFOUND
         THEN
            raise_application_error (
               -20303,
               'The total value of purchase receipts not found'
            );
         END IF;

         CLOSE c10;
         var_aportion_order_amt :=   (  (cr4.porectc_tc_amt)
                                      * (  ((cr1.porl_sc_unit_cost - (cr1.porl_sc_unit_cost * cr1.porl_disc_pct / 100)) - 
      		   cr1.porl_sc_lm_disc_amt) * var_ex_rate * cr1.porl_receipt_qty
                                        )
                                      / cr10.sum_of_porl_amt
                                     )
                                   / cr1.porl_receipt_qty;
								   
		--raise_application_error(-20999,'var_aportion_order_amt'||var_aportion_order_amt);						   

         INSERT INTO por_tax_charges
                     (portc_bu, portc_receipt_pfx, portc_receipt_no,
                      portc_po_pfx,portc_po_no, portc_seq_no,
                      portc_sub_seq_no, portc_tc_id, portc_charge_flag,
                      portc_tc_unit_amt, portc_cre_by,
                      portc_cre_date,portc_type,portc_receipt_seq_no)
              VALUES (cr1.porl_bu, cr1.porl_receipt_pfx, cr1.porl_receipt_no,
                      cr1.porl_po_pfx,cr1.porl_po_no, cr1.porl_po_seq_no,
                      cr1.porl_po_sub_seq_no, cr4.porectc_tc_id, cr4.porectc_charge_flag,
                      var_aportion_order_amt, cr1.porl_cre_by,
                      cr1.porl_cre_date,cr4.porectc_type,cr1.porl_seq_no);
      END LOOP;
   END LOOP;

   FOR cr5 IN (SELECT porh_exchange_rate, porl_bu, porl_receipt_pfx,
                      porl_receipt_no, porl_seq_no, porl_po_pfx,porl_po_no, porl_po_seq_no,
                      porl_po_sub_seq_no, porl_sc_unit_cost, porl_receipt_qty,
                      porl_accepted_qty, porl_rejected_qty, 
                      porl_cre_by,
                      porl_cre_date, porl_upd_by, porl_upd_date
                 FROM pur_ord_receipt_hd, pur_ord_receipt_ln
                WHERE porh_bu = var_bu
                  AND porh_receipt_pfx = var_receipt_pfx
		  AND porh_receipt_no = var_receipt_no
                  AND porh_bu = porl_bu
                  AND porh_receipt_pfx = porl_receipt_pfx                  
                  AND porh_receipt_no = porl_receipt_no
	       )
   LOOP
     
	  SELECT NVL (SUM (portc_tc_unit_amt), 0)
        INTO tax_expense_value
        FROM por_tax_charges, tax_charges
       WHERE portc_bu = cr5.porl_bu
         AND portc_receipt_pfx = cr5.porl_receipt_pfx
         AND portc_receipt_no = cr5.porl_receipt_no
	 AND portc_po_pfx = cr5.porl_po_pfx
         AND portc_po_no = cr5.porl_po_no
         AND portc_seq_no = cr5.porl_po_seq_no
         AND portc_sub_seq_no = cr5.porl_po_sub_seq_no
         AND portc_type IN ('R')
         AND portc_bu = tc_bu
         AND portc_tc_id = tc_tc_id
         AND tc_prod_chargeable = 'N';		 		
        
      SELECT NVL (SUM (portc_tc_unit_amt), 0)
        INTO tax_asset_value
        FROM por_tax_charges, tax_charges
       WHERE portc_bu = cr5.porl_bu
         AND portc_receipt_pfx = cr5.porl_receipt_pfx
         AND portc_receipt_no = cr5.porl_receipt_no
	 AND portc_po_pfx = cr5.porl_po_pfx
         AND portc_po_no = cr5.porl_po_no
         AND portc_seq_no = cr5.porl_po_seq_no
         AND portc_sub_seq_no = cr5.porl_po_sub_seq_no
         AND portc_type IN ('R')
         AND portc_bu = tc_bu
         AND portc_tc_id = tc_tc_id
         AND tc_prod_chargeable <> 'N'
         AND tc_charge_flag <> 'D';		
                  

      SELECT NVL (SUM (portc_tc_unit_amt), 0)
        INTO discount_value
        FROM por_tax_charges, tax_charges
       WHERE portc_bu = cr5.porl_bu
         AND portc_receipt_pfx = cr5.porl_receipt_pfx
         AND portc_receipt_no = cr5.porl_receipt_no
	 AND portc_po_pfx = cr5.porl_po_pfx
         AND portc_po_no = cr5.porl_po_no
         AND portc_seq_no = cr5.porl_po_seq_no
         AND portc_sub_seq_no = cr5.porl_po_sub_seq_no
         AND portc_type IN ('R')
         AND portc_bu = tc_bu
         AND portc_tc_id = tc_tc_id
         AND tc_charge_flag = 'D';

      UPDATE pur_ord_receipt_ln
         SET porl_sc_chrg_amt = tax_asset_value,
             porl_sc_non_chrg_amt = tax_expense_value,
             porl_sc_lm_disc_amt = discount_value
       WHERE porl_bu = cr5.porl_bu
         AND porl_receipt_pfx = cr5.porl_receipt_pfx
         AND porl_receipt_no = cr5.porl_receipt_no
         AND porl_seq_no = cr5.porl_seq_no
	 AND porl_po_pfx = cr5.porl_po_pfx
         AND porl_po_no = cr5.porl_po_no
         AND porl_po_seq_no = cr5.porl_po_seq_no
         AND porl_po_sub_seq_no = cr5.porl_po_sub_seq_no;
   END LOOP;

SELECT COUNT(*) INTO v_count
FROM 	por_tax_charges 
WHERE 	portc_bu = var_bu         
AND 	portc_receipt_pfx = var_receipt_pfx
AND 	portc_receipt_no = var_receipt_no;

IF v_count > 1 THEN
   UPDATE pur_ord_receipt_hd
      SET porh_tax_flag = 'Y'
    WHERE porh_bu = var_bu
      AND porh_receipt_pfx = var_receipt_pfx
      AND porh_receipt_no = var_receipt_no;
END IF;
      
   COMMIT;
END;
/

SHOW ERRORS;

-- 1. This procedure will have differenet tax values of each line of the purchase receipts.
-- 2. Each receipt may have taxes or charges for receipt line wise - por_prod_tax_charges.
-- 3. Each receipt may have taxes or charges for class wise        - por_class_tax_charges.
-- 4. Each receipt may have taxes or charges for receipt wise      - po_receipt_tax_charges.
-- 5. i) This procedure will get values from por_prod_tax_charges ,line by line and
--    and directly applied into por_tax_charges,which is having different tax values for each line.
--    ii) This procedure will get values from por_class_tax_charges and will be apportioned
--    and applied into por_tax_charges.
--    iii) This procedure will get values from po_receipt_tax_charges and will be apportioned
--    and applied into por_tax_charges.
-- 6. Each receipt will have different tax values in the por_tax_charges table
-- 7. Each receipt line tax or charges grouped by expenses and non expenses and applied into 
--    Chargeble and Non-Chargeble columns.
-- 8 . Chargeble and Non-chargeble values will updated for each receipt line.
