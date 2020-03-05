 CREATE OR REPLACE PROCEDURE proc_ins_proc_po
(
 var_bu 		VARCHAR2,
 var_user 		VARCHAR2,
 var_mode		VARCHAR2,
 p_order_no 	    OUT VARCHAR2
)
IS
   CURSOR c1
   IS
	SELECT	prl_bu, 
		prl_rqst_pfx, 
		prl_rqst_no,
		prlss_suplr_id, 
		prl_prod_id,
		prl_prod_rev,
		prls_store_id,
		prls_store_name,
		prl_prod_temp_id,
		prl_prod_temp_rev,
		prl_class_id,
		prl_sub_cls_id,
		prl_sub_cls_desc,
		prl_bc_unit_cost,
		prlss_ordered_qty,
		prl_prod_uom, 
		prl_uom,
		prl_seq_no,
		prls_sub_seq_no,
		prls_approved_qty,
		prls_sc_suplr_flag,
		prls_rfq,
		prls_plnt,
		prls_buyer_id,
		func_find_po_user_class_pfx(var_bu,var_user,'PC') user_pfx,
		DECODE (
			SIGN (
				TO_DATE (prls_required_date)
					- (TO_DATE (
			    				TRUNC (SYSDATE)
			     			 	+ NVL (
								func_find_prod_suplr_leadtime
								(var_bu,
								 prls_plnt,
								 prlss_suplr_id,
								 prl_prod_temp_id,
								 prl_prod_temp_rev,
								 prls_approved_qty
								),
				      				0
				    		 	)
			     		  	  )
		   			)
			    ),
		-1,
			(TRUNC (SYSDATE)
		  	+ NVL (
			 	func_find_prod_suplr_leadtime 
					(var_bu,
					 prls_plnt,
					 prlss_suplr_id,
					 prl_prod_temp_id,
					 prl_prod_temp_rev,
					 prls_approved_qty
					 ),
			      		0
			      )
			 ),
			prls_required_date
		    ) prls_required_date  
	FROM 	pur_req_hd,
		pur_req_ln,
		pur_req_ln_schedule,
		pur_req_ln_schld_suplrs
	WHERE 	prh_bu = prl_bu
	AND 	prh_rqst_pfx = prl_rqst_pfx
	AND 	prh_rqst_no = prl_rqst_no
	AND 	prl_bu = prls_bu
	AND	prl_rqst_pfx = prls_rqst_pfx
	AND 	prl_rqst_no = prls_rqst_no
	AND 	prl_seq_no = prls_seq_no
	AND 	prls_bu = prlss_bu
	AND 	prls_rqst_pfx = prlss_rqst_pfx
	AND 	prls_rqst_no = prlss_rqst_no
	AND 	prls_seq_no = prlss_rqst_seq_no
	AND 	prls_sub_seq_no = prlss_rqst_sub_seq_no
	AND 	prh_bu = var_bu
	--AND 	prh_mode = var_mode
	AND 	prls_quote_pfx IS NULL
	AND 	(prls_quote_no IS NULL or prls_quote_no = 0)
	AND 	prl_order_pfx IS NULL
	AND 	(prl_order_no IS NULL or prl_order_no = 0)
	AND 	prls_rfq = 'M'		--prls_rfq = 'N'
	AND 	prl_status = 'A'
	AND 	prls_select_flag = 'Y'
	AND 	prls_procr_id = var_user
	AND	prlss_ordered_qty > 0
	--AND (   prls_ordered_qty IS NULL
	--     OR (prls_approved_qty - NVL (prls_ordered_qty, 0)) > 0
	--    )
	AND	(prls_approved_qty - NVL (prls_ordered_qty, 0)) > 0
	AND 	prlss_status = 'N'
	AND	prlss_mode = 'PR'
	ORDER BY prlss_suplr_id,prl_prod_temp_id, prl_prod_temp_rev,prls_required_date;
               

   CURSOR c3 (var_supid VARCHAR2)
   IS
      SELECT suplr_suplr_id,
      	     suplr_currency,
      	     suplr_term_id,
      	     suplr_shipvia_id,
             suplr_fob_id,
             suplr_buyer_id
        FROM suppliers
       WHERE suplr_bu = var_bu
         AND suplr_suplr_id = var_supid
         AND suplr_status = 'A';

-- for checking total order qty exceeds balace order qty
cursor c4
is
SELECT   prlss_bu, prlss_rqst_pfx, prlss_rqst_no, prlss_rqst_seq_no,
            prlss_rqst_sub_seq_no,
         (SELECT prls_approved_qty
            FROM pur_req_ln_schedule
           WHERE prls_bu = var_bu
             AND prls_rqst_pfx = prlss_rqst_pfx
             AND prls_rqst_no = prlss_rqst_no
             AND prls_seq_no = prlss_rqst_seq_no
             AND prls_sub_seq_no = prlss_rqst_sub_seq_no)
               AS "approved_qty",
         (SELECT prls_ordered_qty
            FROM pur_req_ln_schedule
           WHERE prls_bu = var_bu
             AND prls_rqst_pfx = prlss_rqst_pfx
             AND prls_rqst_no = prlss_rqst_no
             AND prls_seq_no = prlss_rqst_seq_no
             AND prls_sub_seq_no = prlss_rqst_sub_seq_no)
               AS "Ordered_qty",
         SUM (prlss_ordered_qty) order_qty
    FROM pur_req_ln,
         pur_req_ln_schedule,
         pur_req_ln_schld_suplrs
   WHERE prls_bu = prl_bu
     AND prls_rqst_pfx = prl_rqst_pfx
     AND prls_rqst_no = prl_rqst_no
     AND prls_seq_no = prl_seq_no
     AND prls_bu = prlss_bu
     AND prls_rqst_pfx = prlss_rqst_pfx
     AND prls_rqst_no = prlss_rqst_no
     AND prls_seq_no = prlss_rqst_seq_no
     AND prls_sub_seq_no = prlss_rqst_sub_seq_no
     AND prlss_status = 'N'
     AND prl_bu = var_bu
     AND prl_order_no IS NULL
     AND prls_rfq = 'M'		--prls_rfq = 'N'
     AND prl_status = 'A'
     AND prls_select_flag = 'Y'
     AND prls_procr_id = var_user
     AND prlss_ordered_qty > 0
     AND prlss_mode = 'PR'
     AND (   prls_ordered_qty IS NULL
            OR (prls_approved_qty - NVL (prls_ordered_qty, 0)) > 0
         )
     AND (SELECT prls_approved_qty
            FROM pur_req_ln_schedule
           WHERE prls_bu = var_bu
             AND prls_rqst_pfx = prlss_rqst_pfx
             AND prls_rqst_no = prlss_rqst_no
             AND prls_seq_no = prlss_rqst_seq_no
             AND prls_sub_seq_no = prlss_rqst_sub_seq_no) <>
             (SELECT prls_ordered_qty
	      FROM pur_req_ln_schedule
	    WHERE prls_bu = var_bu
	      AND prls_rqst_pfx = prlss_rqst_pfx
	      AND prls_rqst_no = prlss_rqst_no
	      AND prls_seq_no = prlss_rqst_seq_no
	      AND prls_sub_seq_no = prlss_rqst_sub_seq_no)
GROUP BY prlss_bu,
         prlss_rqst_pfx,
         prlss_rqst_no,
         prlss_rqst_seq_no,
         prlss_rqst_sub_seq_no
  HAVING ((SELECT prls_approved_qty
       	     FROM pur_req_ln_schedule
            WHERE prls_bu = var_bu
	      AND prls_rqst_pfx = prlss_rqst_pfx
	      AND prls_rqst_no = prlss_rqst_no
   	      AND prls_seq_no = prlss_rqst_seq_no
	      AND prls_sub_seq_no =
			 prlss_rqst_sub_seq_no)
        - (SELECT prls_ordered_qty
             FROM pur_req_ln_schedule
	    WHERE prls_bu = var_bu
	      AND prls_rqst_pfx = prlss_rqst_pfx
	      AND prls_rqst_no = prlss_rqst_no
	      AND prls_seq_no = prlss_rqst_seq_no
	      AND prls_sub_seq_no = prlss_rqst_sub_seq_no)) < SUM (prlss_ordered_qty);

 CURSOR c9
   IS
      SELECT pomctrl_net_flag
        FROM pom_control
       WHERE pomctrl_bu = var_bu;
 
 CURSOR c16 IS
      	   (SELECT prh_rec_source
      	      FROM pur_req_hd,
                    pur_req_ln,
                    pur_req_ln_schedule             
              WHERE prh_bu = prl_bu
                AND prh_rqst_pfx = prl_rqst_pfx
                AND prh_rqst_no = prl_rqst_no
                AND prh_bu = var_bu
                --AND prh_mode = var_mode
                AND prl_bu = prls_bu
                AND prl_rqst_pfx = prls_rqst_pfx
                AND prl_rqst_no = prls_rqst_no
                AND prl_seq_no = prls_seq_no
                AND prl_status = 'A'
                AND prls_rfq = 'M'
                AND prls_select_flag = 'Y'
                AND (prls_ordered_qty IS NULL OR NVL (prls_ordered_qty, 0)=0)
                AND (   prls_quote_no IS NULL
                     OR prls_quote_no = '0'
                    )
                AND (   prls_order_no IS NULL
                     OR prls_order_no = '0'
                    )
                AND prls_procr_id = var_user
                AND prh_rec_source IN ('T','R','F','E')
               AND ROWNUM = 1);

--End of cursor

   cr3                  c3%ROWTYPE;
   cr4			c4%ROWTYPE;
   cr9                  c9%ROWTYPE;
   cr16			c16%ROWTYPE;
   
   var_order_pfx        VARCHAR2 (5);
   var_order_no         VARCHAR2 (15);
   var_ex_rate          NUMBER;
   var_req_id           VARCHAR2 (10);
   var_req_name         VARCHAR2 (100);
   var_pos_id           VARCHAR2 (10);
   var_pos_name         VARCHAR2 (50);
   var_dept_id          VARCHAR2 (10);
   var_dept_name        VARCHAR2 (50);
   prod_price_basis     VARCHAR2 (1);
   var_conv_factor      NUMBER         := 0;
   var_ln_seq_no        NUMBER         := 0;
   var_ln_sche_seq_no   NUMBER         := 0;
   var_sub_seq_no	NUMBER	       := 0;
   p_year               NUMBER;
   p_period             NUMBER;
   var_suplr_id         VARCHAR2 (25)  := ' ';
   var_uom		VARCHAR2 (20)  := ' ';
   var_prod_id          VARCHAR2 (25)  := ' ';
   var_buyer_id		VARCHAR2 (10)  := ' ';
   var_plnt_id		VARCHAR2 (10)  := ' ';
   var_prod_rev         NUMBER	       := 0;
   var_update_qty	NUMBER	       := 0;	       
   var_ordered_qty	NUMBER         := 0;
   var_store_id		VARCHAR2(10)   := ' ';
   var_prod_desc1	VARCHAR2(50);
   var_prod_desc2	VARCHAR2(50);
   chk_user_class       VARCHAR2(5)    := ' ';
   var_prod_price	NUMBER	       := 0;
   var_prod_price_pct	NUMBER	       := 0;
   var_price		NUMBER	       := 0;
   var_contract_id      VARCHAR2 (15)   := NULL;
   --p_order_no         VARCHAR2 (500);
   VAR_QTY		NUMBER(10);
   p_order_no1         VARCHAR2 (4000);
   var_rec_source	VARCHAR2(2);
   v_vrnt_uom		VARCHAR2(20);
   var_plnt_po		VARCHAR2(1);
   var_out1		varchar2(4000);
   var_out		varchar2(4000);
   cnt			number:=0;
   
   
BEGIN

OPEN c16;
FETCH c16 INTO cr16;
     IF c16%FOUND THEN
       var_rec_source:= cr16.prh_rec_source;
     ELSE
       var_rec_source:='O';  -- 'O' for Other purchase requests
     END IF;
CLOSE c16;
     
   --check order qty >(approved qty - order qty)
   OPEN c4;
   FETCH c4 INTO cr4;
   IF c4%FOUND THEN
   	raise_application_error(-20999,'Purchase Order qty must match with Balance requested qty');
   END IF;
   CLOSE c4;
   --end

   OPEN c9;
      FETCH c9 INTO cr9;

      IF c9%NOTFOUND
      THEN
         raise_application_error (
            -20337,
            'Purchase Order Control Discount Flag Not Exists'
         );
      END IF;
   CLOSE c9;

   FOR cr1 IN c1
   LOOP
   
   SELECT 	pomctrl_plnt_po
   INTO		var_plnt_po
   FROM		pom_control
   WHERE	pomctrl_bu = var_bu;
   
   prod_price_basis := func_find_prod_price_basis (
   				   var_bu,
   				   cr1.prl_prod_temp_id,
   				   cr1.prl_prod_temp_rev
				);
  
   IF prod_price_basis = 'U' THEN
   	var_prod_price := cr1.prl_bc_unit_cost;
   ELSIF prod_price_basis = 'C' THEN  
     		  
   proc_find_batch_contr_price (
   		  var_bu,
   		  cr1.prlss_suplr_id,
   		  cr1.prl_prod_temp_id,
   		  cr1.prl_prod_temp_rev,
   		  cr1.prlss_ordered_qty,			
   		  TRUNC (SYSDATE),
   		  'PR',
   		  cr1.prls_plnt,
   		   var_prod_price,
   		  var_prod_price_pct,
   		  var_contract_id
	       );
  END IF;
  

        IF (cr1.prlss_suplr_id <> var_suplr_id)
        OR (cr1.user_pfx <> chk_user_class)
        OR (cr1.prls_buyer_id <> var_buyer_id)
        OR (cr1.prls_plnt <> var_plnt_id 
        	AND var_plnt_po = 'N'
        	AND cr1.prlss_suplr_id = var_suplr_id
        	AND cr1.prl_prod_temp_id = var_prod_id 
        	AND cr1.prl_prod_temp_rev = var_prod_rev
        	AND cr1.prls_buyer_id = var_buyer_id)
        OR (cr1.prls_plnt <> var_plnt_id 
        	AND var_plnt_po = 'Y'
        	AND cr1.prlss_suplr_id = var_suplr_id
        	AND cr1.prl_prod_temp_id = var_prod_id 
        	AND cr1.prl_prod_temp_rev = var_prod_rev
        	AND cr1.prls_buyer_id = var_buyer_id
        	AND var_price <> var_prod_price)
        OR (cr1.prlss_suplr_id = var_suplr_id 
        	AND cr1.prls_buyer_id = var_buyer_id
        	AND cr1.prl_prod_temp_id = var_prod_id 
        	AND cr1.prl_prod_temp_rev = var_prod_rev
        	AND cr1.prl_uom <> var_uom)
        
      THEN
	cnt := cnt+1;
	var_out := var_out||'-'||chr(10)||'-'||cnt||'-'||cr1.prl_rqst_no||'-'||cr1.prls_plnt||'-'||var_plnt_id||'-'||
		   var_plnt_po||'-'||
		   cr1.prlss_suplr_id ||'-'|| var_suplr_id||'-'||
		   cr1.prl_prod_temp_id ||'-'|| var_prod_id ||'-'||
		   cr1.prl_prod_temp_rev ||'-'|| var_prod_rev||'-'||
        	   cr1.prls_buyer_id ||'-'|| var_buyer_id;
        
        dbms_output.put_line(var_out);
        		 
         var_order_pfx := cr1.user_pfx;
         proc_find_year_period (var_bu, TRUNC (SYSDATE), p_year, p_period);

      	var_order_no := func_find_pfx_nextno (
                            var_bu,
                            p_year,
                            var_order_pfx,
                            var_user
                         );

	/*
	   Below procedure will return employee id (var_req_id),employee name
	   (var_req_name), employee position(var_pos_id),employee name(var_pos_name),
	   employee department id(var_dept_id), employee department name(var_dept_name)
	   by passing user_id(var_cre_by)
	*/
         proc_get_emp_det (
            			var_bu,
            			var_user,
            			var_req_id,
            			var_req_name,
            			var_pos_id,
            			var_pos_name,
            			var_dept_id,
            			var_dept_name
         		  );

	
	--p_order_no   := p_order_no||var_order_pfx||'-'||var_order_no||' ';
	
	p_order_no1   := p_order_no1||var_order_pfx||'-'||var_order_no||' ';
		
	p_order_no:=p_order_no1;
         -- To get supplier details
         OPEN c3 (cr1.prlss_suplr_id);
         FETCH c3 INTO cr3;

         IF c3%NOTFOUND
         THEN
            raise_application_error (-20118, 'Refer Error Table');
         ELSE
            var_ex_rate := func_find_exchange_rate (
                              var_bu,
                              cr3.suplr_currency,
                              NULL,
                              TRUNC (SYSDATE)
                           );
         END IF;
         CLOSE c3;
				 
         INSERT INTO pur_order_hd
                     (poh_bu, 
                      poh_mode,
                      poh_type, 
                      poh_order_pfx, 
                      poh_order_no,
                      poh_suplr_id,
                      poh_suplr_name,
                      poh_order_date, 
                      poh_order_year, 
                      poh_order_period,
                      poh_currency, 
                      poh_exchange_rate, 
                      poh_status, --'N'
                      poh_shipvia_id, 
                      poh_term_id,
                      poh_fob_id, 
                      poh_control_person, 
                      poh_trace_action,
                      poh_trace_msg, 
                      poh_lcg_base_flag,
                      poh_buyer_id, 
                      poh_origin, 
                      poh_adv_payable, 
                      poh_adv_paid,
                      poh_part_ship_flag, 
                      poh_ack_require, 
                      poh_reqstr_id,
                      poh_reqstr_name, 
                      poh_reqstr_pos_id, 
                      poh_reqstr_pos_name,
                      poh_rqst_dept_id, 
                      poh_tax_flag, 
                      poh_sel_flag,
                      poh_cre_by, 
                      poh_cre_date,
                      poh_appl_source
                      )
              VALUES (var_bu, 
                      var_mode,--'ST', 
              	      DECODE(var_rec_source,'T','TS','R','RD','F','AW','E','SE','O','ST'),
              	      var_order_pfx, 
              	      var_order_no,
                      cr1.prlss_suplr_id,
                      func_find_suplr_name (var_bu, cr1.prlss_suplr_id),
                      TRUNC (SYSDATE), 
                      p_year, 
                      p_period,
                      cr3.suplr_currency, 
                      var_ex_rate, 
                      'N',
                      cr3.suplr_shipvia_id, 
                      cr3.suplr_term_id,
                      cr3.suplr_fob_id, 
                      var_user, 'R',
                      'Being Request for Purchase Order', 
                      'N',
                      cr1.prls_buyer_id,--cr3.suplr_buyer_id, 
                      'R', 
                       0, 
                       0,
                      'Y', 
                      'N', 
                      var_req_id,
                      var_req_name, 
                      var_pos_id, 
                      var_pos_name,
                      var_dept_id, 
                      'N',
                      'N',
                      var_user, 
                      SYSDATE,
                      'POM'
                     );

         var_ln_seq_no := 0;
         var_update_qty := 0;
                                             
      END IF;
      
	--var_update_qty := NVL(var_update_qty,0) + (cr1.prlss_ordered_qty/var_conv_factor);
	
	IF cr1.prl_prod_id <> cr1.prl_prod_temp_id THEN
		v_vrnt_uom := func_find_product_uom(var_bu,
						    cr1.prl_prod_temp_id,
						    cr1.prl_prod_temp_rev);
	ELSE
		v_vrnt_uom := cr1.prl_uom;
	END IF;
	---------------------------------------------------------
	var_conv_factor := func_find_uom_conversion (
	                                  var_bu,
	                                  cr1.prl_prod_temp_id,
	                                  cr1.prl_prod_temp_rev,
	                                  v_vrnt_uom,		--cr1.prl_uom,
	                                  func_find_suplr_uom(var_bu,
	                                  		      cr1.prlss_suplr_id,
	                                  		      cr1.prl_prod_temp_id,
	                                  		      cr1.prl_prod_temp_rev) --cr1.prl_prod_uom,
	                                              );
	                                              
	  var_update_qty := NVL(var_update_qty,0) + (cr1.prlss_ordered_qty*var_conv_factor);  
	  
    proc_find_prod_desc(var_bu,cr1.prl_prod_temp_id,cr1.prl_prod_temp_rev,var_prod_desc1,var_prod_desc2);

	  var_prod_price := 0;
	  var_prod_price_pct := 0;
	  prod_price_basis := func_find_prod_price_basis (
				   var_bu,
				   cr1.prl_prod_temp_id,
				   cr1.prl_prod_temp_rev
				);

	    IF (prod_price_basis = 'I')
	    THEN
	       var_prod_price :=
		  func_find_unitcost (
		     var_bu,
		     cr1.prl_prod_temp_id,
		     cr1.prl_prod_temp_rev,
		     func_find_deflt_storeid (
			var_bu,
			cr1.prls_plnt,
			cr1.prl_prod_temp_id,
			cr1.prl_prod_temp_rev,
			func_find_product_stock (
			   var_bu,
			   cr1.prl_prod_temp_id,
			   cr1.prl_prod_temp_rev
			)
		     )
		  );
	       /*var_prod_price :=   (var_prod_price / var_ex_rate)
				 / var_conv_factor;*/
		var_prod_price :=   (var_prod_price / var_ex_rate);
	    ELSIF (prod_price_basis = 'C')
	    THEN
	       proc_find_batch_contr_price (
		  var_bu,
		  cr1.prlss_suplr_id,
		  cr1.prl_prod_temp_id,
		  cr1.prl_prod_temp_rev,
		  var_update_qty,			
		  TRUNC (SYSDATE),
		  'PR',
		  cr1.prls_plnt,
		  var_prod_price,
		  var_prod_price_pct,
		  var_contract_id
	       );
	       --var_prod_price := var_prod_price / var_conv_factor;
	       
	       var_prod_price := var_prod_price;
	    ELSIF (prod_price_basis = 'S')
	    THEN
	       proc_find_catalog_price (
		  var_bu,
		  cr1.prlss_suplr_id,
		  cr1.prl_prod_temp_id,
		  cr1.prl_prod_temp_rev,
		  var_update_qty,
		  TRUNC (SYSDATE),
		  var_prod_price,
		  var_prod_price_pct,
		  var_contract_id
	       );
	       --var_prod_price := var_prod_price / var_conv_factor;
	    ELSIF prod_price_basis = 'L'
	    THEN
	       var_prod_price := func_find_last_pur_price (
				    var_bu,
				    cr1.prl_prod_temp_id,
				    cr1.prl_prod_temp_rev
				 );
	    ELSIF prod_price_basis = 'U'
	    THEN
	       var_prod_price := cr1.prl_bc_unit_cost;
 END IF;
      	---------------------------------------------------------
		
      	UPDATE pur_order_ln
	   SET pol_ordered_qty = NVL(pol_ordered_qty,0) + (cr1.prlss_ordered_qty*var_conv_factor),
	       pol_tolr_qty = NVL(pol_tolr_qty,0) + (cr1.prlss_ordered_qty*var_conv_factor),
	       pol_sc_unit_cost = DECODE (var_mode, 'PO', var_prod_price, 0),
	       pol_scon_lbr_unit_cost = DECODE (var_mode, 'SC', var_prod_price, 0),
	       pol_sc_old_cost = DECODE(var_mode, 'PO', var_prod_price, 0),
	       pol_upd_by = var_user,
	       pol_upd_date = SYSDATE
         WHERE pol_bu = var_bu
           AND pol_order_pfx = var_order_pfx
           AND pol_order_no = var_order_no
           AND pol_seq_no = var_ln_seq_no
           AND pol_prod_id = cr1.prl_prod_temp_id
           AND pol_prod_rev = cr1.prl_prod_temp_rev;
           
                           
           IF SQL%NOTFOUND THEN
           
             var_update_qty := 0;
             
             IF cr1.prl_prod_id <> cr1.prl_prod_temp_id THEN
	     		v_vrnt_uom := func_find_product_uom(var_bu,
	     						    cr1.prl_prod_temp_id,
	     						    cr1.prl_prod_temp_rev);
	     	ELSE
	     		v_vrnt_uom := cr1.prl_uom;
	     END IF;
             
           var_conv_factor := func_find_uom_conversion (
                                  var_bu,
                                  cr1.prl_prod_temp_id,
                                  cr1.prl_prod_temp_rev,
                                  v_vrnt_uom,			--cr1.prl_uom,
                                  func_find_suplr_uom(var_bu,
	                                	      cr1.prlss_suplr_id,
	                                  	      cr1.prl_prod_temp_id,
	                                  	      cr1.prl_prod_temp_rev)		--cr1.prl_prod_uom,
                                                        );
            
            proc_find_prod_desc(var_bu,cr1.prl_prod_temp_id,cr1.prl_prod_temp_rev,var_prod_desc1,var_prod_desc2);
           -----------------------
         	  var_prod_price := 0;
	          var_prod_price_pct := 0;
	          prod_price_basis := func_find_prod_price_basis (
	                                   var_bu,
	                                   cr1.prl_prod_temp_id,
	                                   cr1.prl_prod_temp_rev
	                                );

	            IF (prod_price_basis = 'I')
	            THEN
	               var_prod_price :=
	                  func_find_unitcost (
	                     var_bu,
	                     cr1.prl_prod_temp_id,
	                     cr1.prl_prod_temp_rev,
	                     func_find_deflt_storeid (
	                        var_bu,
	                        cr1.prls_plnt,
	                        cr1.prl_prod_temp_id,
	                        cr1.prl_prod_temp_rev,
	                        func_find_product_stock (
	                           var_bu,
	                           cr1.prl_prod_temp_id,
	                           cr1.prl_prod_temp_rev
	                        )
	                     )
	                  );
	               /*var_prod_price :=   (var_prod_price / var_ex_rate)
	                                 / var_conv_factor;*/
	                                 
	                 var_prod_price :=   (var_prod_price / var_ex_rate);
	                 
	            ELSIF (prod_price_basis = 'C')
	            THEN
	               proc_find_batch_contr_price (
	                  var_bu,
	                  cr1.prlss_suplr_id,
	                  cr1.prl_prod_temp_id,
	                  cr1.prl_prod_temp_rev,
	                  --cr1.prlss_ordered_qty/var_conv_factor,			
	                  cr1.prlss_ordered_qty*var_conv_factor,
	                  TRUNC (SYSDATE),
	                  'PR',
	                  cr1.prls_plnt,
	                  var_prod_price,
	                  var_prod_price_pct,
	                  var_contract_id
	               );
	               --var_prod_price := var_prod_price / var_conv_factor;
	            ELSIF (prod_price_basis = 'S')
	            THEN
	               proc_find_catalog_price (
	                  var_bu,
	                  cr1.prlss_suplr_id,
	                  cr1.prl_prod_temp_id,
	                  cr1.prl_prod_temp_rev,
	                  --cr1.prlss_ordered_qty/var_conv_factor,
	                  cr1.prlss_ordered_qty*var_conv_factor,
	                  TRUNC (SYSDATE),
	                  var_prod_price,
	                  var_prod_price_pct,
	                  var_contract_id
	               );
	               --var_prod_price := var_prod_price / var_conv_factor;
	            ELSIF prod_price_basis = 'L'
	            THEN
	               var_prod_price := func_find_last_pur_price (
	                                    var_bu,
	                                    cr1.prl_prod_temp_id,
	                                    cr1.prl_prod_temp_rev
	                                 );
	            ELSIF prod_price_basis = 'U'
	            THEN
	               var_prod_price := cr1.prl_bc_unit_cost;
         		END IF;
           ----------------------
         	
         	var_ln_seq_no := var_ln_seq_no + 1;
         	
	              INSERT INTO pur_order_ln
	  	                (
	  	                pol_bu,
	  	                pol_order_pfx,
	  	                pol_order_no,
	  	                pol_seq_no,
	  	                pol_prod_id,
	  	                pol_prod_rev,
	  	                pol_prod_desc1,
	  	                pol_prod_desc2,
	  	                pol_prod_cls,
	  	                pol_prod_cls_desc,
	  	                pol_prod_sub_cls,       
				pol_prod_sub_cls_desc,
	  	                pol_uom,
	  	                pol_prod_uom,
	  	                pol_conv_factor,
	  	                pol_cost_basis,
	  	                pol_contract_id,
	  	                pol_sc_unit_cost,
	  	                pol_disc_pct,
	  	                pol_scon_mat_unit_cost,
	  	                pol_scon_lbr_unit_cost,
	  	                pol_qc_required,
	  	                pol_stocked,
	  	                pol_ordered_qty,
	  	                pol_tolr_qty,
	  	                pol_received_qty,
	  	                pol_tot_received_qty,
				pol_rejected_qty,       
	  	                pol_deflt_schld_flag,
	  	                pol_net_disc_flag,
	  	                pol_origin,
	  	                pol_proj_flag,
	  	                pol_status,
	  	                pol_abc_cls,
	  	                pol_fv_cls,
	  	                pol_price_div_pct,
	  	                pol_sc_old_cost,
	  	                pol_cre_by,
	  	                pol_cre_date
	  	                )
	  	         VALUES (
	  	                var_bu,
	  	                var_order_pfx,
	  	                var_order_no,
	  	                var_ln_seq_no,
	  	                cr1.prl_prod_temp_id,
	  	                cr1.prl_prod_temp_rev,
	  	                var_prod_desc1,
	  	                var_prod_desc2,
	  	                cr1.prl_class_id,
	  	                func_find_class_desc(var_bu, cr1.prl_class_id),
	  	                cr1.prl_sub_cls_id,
	  	                cr1.prl_sub_cls_desc,
	  	                func_find_suplr_uom(var_bu,cr1.prlss_suplr_id,cr1.prl_prod_temp_id,cr1.prl_prod_temp_rev), --cr1.prl_uom,
	  	                cr1.prl_prod_uom,
	  	                var_conv_factor,
	  	                prod_price_basis,
	  	                var_contract_id,
	  	                DECODE (var_mode, 'PO', var_prod_price, 0),
	  	                var_prod_price_pct,
	  	                0,
	  	                DECODE (var_mode, 'SC', var_prod_price, 0),
	  	                func_find_product_qc_req(
	  	                     var_bu,
	  	                     cr1.prl_prod_temp_id,
	  	                     cr1.prl_prod_temp_rev
	  	                ),
	  	                func_find_product_stock(var_bu, cr1.prl_prod_temp_id, cr1.prl_prod_temp_rev),
	  	                (cr1.prlss_ordered_qty*var_conv_factor),
	  	                (cr1.prlss_ordered_qty*var_conv_factor),
	  	                0,
	  	                0,
	  	                0,
	  	                'Y',
	  	                cr9.pomctrl_net_flag,
	  	                'R',
	  	                'N',
	  	                'N',
	  	                func_find_product_abc_cls(
	  	                     var_bu,
	  	                     cr1.prl_prod_temp_id,
	  	                     cr1.prl_prod_temp_rev
	  	                ),
	  	                func_find_product_fc_cls(
	  	                     var_bu,
	  	                     cr1.prl_prod_temp_id,
	  	                     cr1.prl_prod_temp_rev
	  	                ),
	  	                0,
	  	                DECODE(var_mode, 'PO', var_prod_price, 0),
	  	                var_user,
	  	                SYSDATE
	                );
	                
	                var_ln_sche_seq_no := 0;
	                
END IF;
		var_update_qty := cr1.prlss_ordered_qty*var_conv_factor;
                              
		 -- LINE    -- SCHEDULE;
  
		 UPDATE pur_ord_ln_schedule
		    SET pols_ordered_qty = NVL(pols_ordered_qty,0) + (cr1.prlss_ordered_qty*var_conv_factor),
		        pols_tolr_qty = NVL(pols_ordered_qty,0) + (cr1.prlss_ordered_qty*var_conv_factor),
		        pols_ord_stk_qty = NVL(pols_ord_stk_qty,0) + cr1.prlss_ordered_qty,
		        pols_rcpt_stk_qty = 0,
			pols_upd_bY = var_user,
			pols_upd_date = SYSDATE
		  WHERE pols_bu = var_bu
		    AND	pols_order_pfx = var_order_pfx
		    AND	pols_order_no = var_order_no
		    AND	pols_seq_no = var_ln_seq_no
		    AND	pols_sub_seq_no = var_ln_sche_seq_no
		    AND	pols_store_id = cr1.prls_store_id
		    AND pols_required_date = cr1.prls_required_date;

		 IF SQL%NOTFOUND THEN

		 var_ln_sche_seq_no := var_ln_sche_seq_no + 1;
		 		 
		 INSERT INTO pur_ord_ln_schedule
			     (
			     pols_bu,
			     pols_order_pfx,
			     pols_order_no,
			     pols_seq_no,
			     pols_sub_seq_no,
			     pols_store_id,
			     pols_store_name,
			     pols_storage_store_id,
			     pols_storage_store_name,
			     pols_ordered_qty,
			     pols_tolr_qty,
			     pols_ord_stk_qty,
			     pols_rcpt_stk_qty,
			     pols_receipt_qty,
			     pols_tot_receipt_qty,
			     pols_rejected_qty,      
			     pols_required_date,
			     pols_promise_date,
			     pols_distribute_flag,
			     pols_sc_suplr_flag,
			     pols_plnt,
			     pols_cre_by,
			     pols_cre_date
			     )
		      VALUES (
			     var_bu,
			     var_order_pfx,
			     var_order_no,
			     var_ln_seq_no,
			     var_ln_sche_seq_no,
			     cr1.prls_store_id,
			     cr1.prls_store_name,--func_find_store_desc(var_bu, cr1.prls_store_id),
			     cr1.prls_store_id,
			     cr1.prls_store_name,--func_find_store_desc(var_bu, cr1.prls_store_id),
			     (cr1.prlss_ordered_qty*var_conv_factor),
			     (cr1.prlss_ordered_qty*var_conv_factor),
			     cr1.prlss_ordered_qty,
			     0,
			     0,
			     0,
			     0,
			     cr1.prls_required_date,
			     cr1.prls_required_date,
			     'Y',
			     cr1.prls_sc_suplr_flag,
			     cr1.prls_plnt,
			     var_user,
			     SYSDATE
			     );
			     
		 END IF;
		 -- SCHEDULE

       var_prod_id   := cr1.prl_prod_temp_id;
       var_prod_rev := cr1.prl_prod_temp_rev;
       var_uom := cr1.prl_uom;
       var_suplr_id  := cr1.prlss_suplr_id;
       var_store_id := cr1.prls_store_id;
       chk_user_class := cr1.user_pfx;
       var_buyer_id := cr1.prls_buyer_id;
       var_plnt_id := cr1.prls_plnt;
       var_price := var_prod_price;
       --p_order_no   := p_order_no||var_order_pfx||'-'||var_order_no||' ';

       -- OFFseting order qty lines

               UPDATE pur_req_ln_schedule
                  SET prls_ordered_qty = NVL(prls_ordered_qty,0) + cr1.prlss_ordered_qty
                WHERE prls_bu = var_bu
                  AND prls_rqst_pfx = cr1.prl_rqst_pfx
                  AND prls_rqst_no = cr1.prl_rqst_no
                  AND prls_seq_no = cr1.prl_seq_no
                  AND prls_sub_seq_no = cr1.prls_sub_seq_no;

               UPDATE pur_req_ln
                  SET prl_ordered_qty = NVL(prl_ordered_qty,0) + cr1.prlss_ordered_qty
                WHERE prl_bu = var_bu
                  AND prl_rqst_pfx = cr1.prl_rqst_pfx
                  AND prl_rqst_no = cr1.prl_rqst_no
                  AND prl_seq_no = cr1.prl_seq_no;

               UPDATE pur_req_ln_schld_suplrs
                  SET prlss_status = 'O'
                WHERE prlss_bu = var_bu
                  AND prlss_rqst_pfx = cr1.prl_rqst_pfx
                  AND prlss_rqst_no = cr1.prl_rqst_no
                  AND prlss_rqst_seq_no = cr1.prl_seq_no
                  AND prlss_rqst_sub_seq_no = cr1.prls_sub_seq_no
                  AND prlss_suplr_id = cr1.prlss_suplr_id;
                  
-- insert into schdule lines order no.
                  proc_ins_req_schld_ord
		  (
		     var_bu    ,
		     cr1.prl_rqst_pfx,
		     cr1.prl_rqst_no,
		     cr1.prl_seq_no  ,
		     cr1.prls_sub_seq_no,
		     NULL,
		     NULL,
		     NULL,
		     NULL,
		     var_order_pfx ,
		     var_order_no  ,
		     var_ln_seq_no,
		     var_ln_sche_seq_no,			
		     (cr1.prlss_ordered_qty*var_conv_factor),
		     cr1.prlss_ordered_qty,
		     cr1.prls_rfq,
		     var_user
		  );
		
   END LOOP; -- cursor c1
   var_out1 := var_out;
   --raise_application_error(-20999,var_out1);
 
 	IF p_order_no IS NOT NULL THEN
 	   p_order_no:=func_find_order_no_substr (p_order_no);
 	END IF;
	commit;
END;

/
SHOW ERROR;