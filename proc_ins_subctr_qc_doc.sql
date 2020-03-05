/*

  Revision History
  -------------------------------------------------------------------------
  |Revision |Last Update By     | Last Update Date |Purpose                |
  |         |                   |                  |                       |
  -------------------------------------------------------------------------
  |1        |Rajesh S.          | 14-Mar-2006     |Coding and development |
  |         |                   |                  |                       |
  -------------------------------------------------------------------------

  Description of the Procedure:
	Procedure that insert qc document for sub contract receipt. It checks the qc prefix is defined.
	It checks the supplier qoh order/ supplier wise based on the item back flush or order wise.

  Referenced by  :

  References     :
  	
*/

CREATE OR REPLACE PROCEDURE proc_ins_subctr_qc_doc
(
     p_bu                      VARCHAR2,
     p_receipt_pfx             VARCHAR2,
     p_receipt_no              VARCHAR2,
     p_user                    VARCHAR2,
     p_mode                  VARCHAR2,
     p_res           OUT     VARCHAR2
) IS 
     /*cursor get the required field form purchase receipt qc quantity view and products*/
     CURSOR c1 IS
          SELECT DISTINCT porh_receipt_pfx,
                          porh_receipt_no,
                          porh_suplr_id,
                          prodplnt_qc_user_pfx,
                          prodplnt_plnt
                     FROM pur_rct_qc_qty_view,
                          prod_plants
                    WHERE porh_bu  		= 	prodplnt_bu
                    AND   pol_prod_id		=	prodplnt_prod_id 
                    AND   pol_prod_rev  	= 	prodplnt_prod_rev
                    AND   porl_plnt		=	prodplnt_plnt
                    AND   porl_storage_store_id	=	prodplnt_deflt_store_id 	
   		    AND   porh_bu 		= 	p_bu
                    AND   porh_receipt_pfx 	= 	p_receipt_pfx
                    AND   porh_receipt_no 	= 	p_receipt_no;
     
     /*Cursor get all the fields from pur receipt qc quantity view for the given parameter*/
     CURSOR c2(
          c_receipt_pfx     VARCHAR2,
          c_receipt_no      VARCHAR2,
          c_suplr_id        VARCHAR2,
          c_pfx             VARCHAR2
     ) IS
          SELECT *
            FROM pur_rct_qc_qty_view,
                 prod_plants
           WHERE porh_bu  		= 	prodplnt_bu
             AND pol_prod_id  		= 	prodplnt_prod_id
             AND pol_prod_rev  		= 	prodplnt_prod_rev
             AND porl_plnt		=	prodplnt_plnt
             AND porl_storage_store_id	=	prodplnt_deflt_store_id 	
             AND prodplnt_qc_user_pfx 	= 	c_pfx
             AND porh_bu 		= 	p_bu
             AND porh_receipt_pfx 	= 	c_receipt_pfx
	     AND porh_receipt_no 	= 	c_receipt_no
             AND porh_suplr_id 		= 	c_suplr_id;

     /* cursor get the user id for the given parameter from 
     user prefix access*/
     CURSOR c3(
          c_pfx     VARCHAR2
     ) IS
          SELECT upa_user_id
            FROM user_prefix_access
           WHERE upa_bu = p_bu
             AND upa_pfx = c_pfx
             AND upa_dflt_flag = 'Y';

     cr1                       c1%ROWTYPE;
     cr2                       c2%ROWTYPE;
     cr3                       c3%ROWTYPE;
     
     v_qc_doc_no             VARCHAR2(15);
     v_seq_no                NUMBER(5):=0;
     v_sub_seq_no	     NUMBER(5):=0;
     v_sub_seqno	     NUMBER(5):=0;
     v_pfx_user              VARCHAR2(15);
     v_prod_ser_lot_type     VARCHAR2(1);
     v_ref                   VARCHAR2(50);
BEGIN
     --raise_application_error(-20999, 'DSFDGSHRefere error table');
     FOR cr1 IN c1
     LOOP
     
          v_seq_no := 0;
          /*raise error when user prefix is not found*/
          OPEN c3(cr1.prodplnt_qc_user_pfx);
          FETCH c3 INTO cr3;

          IF c3%FOUND THEN
               v_pfx_user := cr3.upa_user_id;
          ELSE
               raise_application_error(-20190, 'Refere error table');
          END IF;

          CLOSE c3;
          v_qc_doc_no := func_find_pfx_nextno(
                                p_bu,
                                func_find_year(p_bu, TRUNC(SYSDATE)),
                                cr1.prodplnt_qc_user_pfx,
                                v_pfx_user
                           );
	  
	 /*insert quality document */
          INSERT INTO tqm_qc_plan_hd
	  (
		tqphd_bu,
		tqphd_pln_pfx,
		tqphd_pln_no,
		tqphd_pln_date,
		tqphd_pln_year,
		tqphd_pln_period,
		tqphd_insp_mode,
		tqphd_qc_type,
		tqphd_qc_id,
		tqphd_control_person,
		tqphd_reference,
		tqphd_status,
		tqphd_cre_by,
		tqphd_cre_date,
		tqphd_plnt
	)
	VALUES 
	(
		p_bu,
		cr1.prodplnt_qc_user_pfx,
		v_qc_doc_no,
		TRUNC(SYSDATE),
		func_find_year(p_bu,trunc(sysdate)),
		func_find_period(p_bu,trunc(sysdate)),
		p_mode,
		'V',
		cr1.porh_suplr_id,
		cr3.upa_user_id,
		'Inspection plan document',
		'N',
		p_user,
		SYSDATE,
		cr1.prodplnt_plnt
	);

          p_res := 'N';
	
	  /*checks the material consumption detail with the supplier qoh and update the used quantity else
	  raise error */
          FOR cr2 IN c2(
                          cr1.porh_receipt_pfx,
                          cr1.porh_receipt_no,
                          cr1.porh_suplr_id,
                          cr1.prodplnt_qc_user_pfx
                     )
          LOOP
         
               IF p_mode = 'SC' THEN
                         
                        
                        FOR cr6 IN (SELECT *
                                       FROM sub_contr_mat_cons_ln
                                      WHERE scmcl_bu = p_bu
                                        AND scmcl_receipt_pfx = cr2.porh_receipt_pfx
                                        AND scmcl_receipt_no = cr2.porh_receipt_no
                                        AND scmcl_seq_no = cr2.porl_seq_no
                                        AND scmcl_cons_qty > 0)
                         LOOP
                         
                              p_res := cr6.scmcl_prod_id;

                              FOR cr7 IN
                                   (SELECT avail_qty
                                      FROM (SELECT (  scq_qty_on_hand
                                                    - scq_used_qty
                                                   )
                                                             avail_qty
                                              FROM sub_contr_qty
                                             WHERE scq_bu = p_bu
                                               AND scq_suplr_id = cr1.porh_suplr_id
                                               AND scq_prod_id = cr6.scmcl_prod_id
                                               AND scq_prod_rev = cr6.scmcl_prod_rev
                                               AND func_find_sub_contr_stock( p_bu, scq_prod_id, scq_prod_rev ) = 'Y'
                                            UNION ALL
                                            SELECT (  scoq_qty_on_hand
                                                    - scoq_used_qty
                                                   )
                                                             avail_qty
                                              FROM sub_contr_order_qty
                                             WHERE scoq_bu = p_bu
                                               AND scoq_suplr_id = cr1.porh_suplr_id
                                               AND scoq_order_pfx = cr2.porl_po_pfx
                                               AND scoq_order_no = cr2.porl_po_no
                                               AND scoq_prod_id = cr6.scmcl_prod_id
                                               AND scoq_prod_rev = cr6.scmcl_prod_rev))
                              LOOP
                              
                                   IF cr7.avail_qty < cr6.scmcl_cons_qty THEN
                                        p_res := cr6.scmcl_prod_id;
                                        ROLLBACK;
                                        EXIT;
                                   ELSE
                                        UPDATE sub_contr_qty
                                           SET scq_used_qty = scq_used_qty + cr6.scmcl_cons_qty,
                                               scq_upd_order_pfx = cr2.porl_po_pfx,
                                               scq_upd_order_no = cr2.porl_po_no,
                                               scq_upd_receipt_pfx = cr2.porh_receipt_pfx,
                                               scq_upd_receipt_no = cr2.porh_receipt_no,
                                               scq_upd_by = p_user,
                                               scq_upd_date = SYSDATE
                                         WHERE scq_bu = p_bu
                                           AND scq_suplr_id = cr1.porh_suplr_id
                                           AND scq_prod_id = cr6.scmcl_prod_id
                                           AND scq_prod_rev = cr6.scmcl_prod_rev;

                                        p_res := 'Y';
                                   END IF;
                              END LOOP;

                              IF p_res <> 'Y' THEN
                                   ROLLBACK;
                                   EXIT;
                              END IF;
                         END LOOP;
               ELSE
                    p_res := 'Y';
               END IF;

               IF p_res <> 'Y' THEN
                    ROLLBACK;
                    EXIT;
               END IF;
	
               

		      v_seq_no := v_seq_no + 1;            

		/*inserting tqm qc detaqils into tqm qc pur receipt ln*/
		      INSERT INTO tqm_qc_plan_ln
				  (
					tqpln_bu           ,            
					tqpln_pln_pfx      ,            
					tqpln_pln_no       ,            
					tqpln_seq_no       ,            
					tqpln_prod_id      ,            
					tqpln_prod_rev     ,            
					tqpln_uom          ,            
					tqpln_doc_pfx      ,            
					tqpln_doc_no       ,            
					tqpln_doc_seq_no   ,            
					tqpln_receipt_qty   ,           
					tqpln_qc_qty,
					tqpln_reference     ,           
					tqpln_status        ,           
					tqpln_cre_by        ,           
					tqpln_cre_date      ,
					tqpln_insp_mode
				  )
			   VALUES (
				  p_bu,
				  cr1.prodplnt_qc_user_pfx,
				  v_qc_doc_no,
				  v_seq_no,
				  cr2.pol_prod_id,
				  cr2.pol_prod_rev,
				  cr2.pol_uom,
				  cr2.porh_receipt_pfx,
				  cr2.porh_receipt_no,
				  cr2.porl_seq_no,
				  cr2.porl_receipt_qty,
				  0,
				  'Inspection plan document',
				  'N',
				  p_user,
				  SYSDATE,
				  p_mode
				  );
			  p_res := 'Y';
	       		/* function return the product serial lot type for the given parameter */
		       v_prod_ser_lot_type :=
			    func_find_prod_ser_lot_type(
				 p_bu,
				 cr2.pol_prod_id,
				 cr2.pol_prod_rev
			    );
		       /* insert into serial/lot details based on the product serial lot type*/
		       IF v_prod_ser_lot_type IN ('L','O') THEN
			    v_sub_seq_no  := 0;
 
			    FOR rec_lot IN (SELECT *
					      FROM pur_rcpt_lot
					     WHERE prcl_bu = p_bu
					       AND prcl_doc_pfx = cr2.porh_receipt_pfx
					       AND prcl_doc_no = cr2.porh_receipt_no
					       AND prcl_doc_seq_no = cr2.porl_seq_no)
			    LOOP
				 v_sub_seq_no := v_sub_seq_no +1;
				 --raise_application_error(-20999,rec_lot.prcl_lot_no);
				 INSERT INTO tqm_qc_plan_lot_dtls
					     (
					     tqpld_bu         ,              
					     tqpld_pln_pfx    ,              
					     tqpld_pln_no     ,              
					     tqpld_seq_no     ,              
					     tqpld_sub_seq_no , 
					     tqpld_lot_type   ,
					     tqpld_lot_no     ,              
					     tqpld_lot_qty    ,              
					     tqpld_qc_qty     ,              
					     tqpld_cre_by     ,              
					     tqpld_cre_date                 
					     )
				      VALUES (
					     p_bu,
					     cr1.prodplnt_qc_user_pfx,
					     v_qc_doc_no,
					     v_seq_no,
					     v_sub_seq_no,
					     v_prod_ser_lot_type,
					     rec_lot.prcl_lot_no,
					     rec_lot.prcl_lot_qty,
					     0,
					     p_user,
					     SYSDATE
					     );
				v_sub_seqno := 0;

				FOR rec_lotser IN
				   (SELECT *
				      FROM pur_rct_serial_nos
				     WHERE prsn_doc_pfx = cr2.porh_receipt_pfx
				       AND prsn_doc_no = cr2.porh_receipt_no
				       AND prsn_doc_seq_no = cr2.porl_seq_no
				       AND prsn_lot_seq_no = rec_lot.prcl_seq_no)
				       --AND prsn_lot_seq_no = rec_lot.prcl_lot_no)
				LOOP
					   v_sub_seqno := v_sub_seqno +1;

					   INSERT INTO tqm_qc_plan_serial_dtls
						       (
							tqpsd_bu              ,         
							tqpsd_pln_pfx         ,         
							tqpsd_pln_no          ,         
							tqpsd_seq_no          ,         
							tqpsd_sub_seq_no      ,         
							tqpsd_lot_type        ,         
							tqpsd_lot_no          ,         
							tqpsd_serial_no       ,         
							tqpsd_sel_flag        ,         
							tqpsd_accept_flag     ,	
							tqpsd_cre_by          ,         
							tqpsd_cre_date        					              
						       )
						VALUES (
						       p_bu,
						       cr1.prodplnt_qc_user_pfx,
						       v_qc_doc_no,
						       v_seq_no,
						       v_sub_seqno,
						       v_prod_ser_lot_type,
						       rec_lot.prcl_lot_no,
						       rec_lotser.prsn_serial_no,
						       'N',
						       'Y',
						       p_user,
						       SYSDATE
						       );
				      END LOOP;	                                     
				END LOOP;
				END IF;
				IF v_prod_ser_lot_type = 'S' THEN
				     v_sub_seq_no  := 0;

				      FOR rec_lotser IN
					   (SELECT *
					      FROM pur_rct_serial_nos
					     WHERE prsn_doc_pfx = cr2.porh_receipt_pfx
					       AND prsn_doc_no = cr2.porh_receipt_no
					       AND prsn_doc_seq_no = cr2.porl_seq_no)
				      LOOP
					   v_sub_seq_no := v_sub_seq_no +1;

					   INSERT INTO tqm_qc_plan_serial_dtls
						       (
							tqpsd_bu              ,         
							tqpsd_pln_pfx         ,         
							tqpsd_pln_no          ,         
							tqpsd_seq_no          ,         
							tqpsd_sub_seq_no      ,         
							tqpsd_lot_type        ,         
							tqpsd_lot_no          ,         
							tqpsd_serial_no       ,         
							tqpsd_sel_flag        ,         
							tqpsd_accept_flag     ,	
							tqpsd_cre_by          ,         
							tqpsd_cre_date        					              
						       )
						VALUES (
						       p_bu,
						       cr1.prodplnt_qc_user_pfx,
						       v_qc_doc_no,
						       v_seq_no,
						       v_sub_seq_no,
						       v_prod_ser_lot_type,
						       null,
						       rec_lotser.prsn_serial_no,
						       'N',
						       'Y',
						       p_user,
						       SYSDATE
						       );
				      END LOOP;
			       END IF;


               UPDATE pur_ord_receipt_ln
                  SET porl_qc_doc_no = v_qc_doc_no,
                      porl_qc_doc_pfx = cr1.prodplnt_qc_user_pfx
                WHERE porl_bu = p_bu
                  AND porl_receipt_pfx = cr2.porh_receipt_pfx
                  AND porl_receipt_no = cr2.porh_receipt_no
                  AND porl_seq_no = cr2.porl_seq_no;
          END LOOP;

          IF p_res <> 'Y' THEN
               EXIT;
          END IF;
     END LOOP;

     --RAISE_APPLICATION_ERROR(-20999,p_res);
     IF p_res = 'Y' THEN
          COMMIT;
     ELSE
          ROLLBACK;
     END IF;
END;
/


SHOW err;
