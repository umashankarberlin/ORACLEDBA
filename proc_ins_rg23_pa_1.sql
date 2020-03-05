CREATE OR REPLACE PROCEDURE proc_ins_rg23_pa_1
(
  	p_bu			VARCHAR2,
  	p_type			VARCHAR2,
	p_date			DATE,
	p_year			NUMBER,
	p_period		NUMBER,
	p_prod_id		VARCHAR2,
	p_prod_rev		NUMBER,
	p_prod_desc		VARCHAR2,
	p_comdty_code		VARCHAR2,
	p_doc_type		VARCHAR2,
	p_input_desc		VARCHAR2,
	p_qty			NUMBER,
	p_suplr_ref		VARCHAR2,
	p_doc_pfx		VARCHAR2,
	p_doc_no		VARCHAR2,
	p_seq_no		NUMBER,
	p_suplr_id		VARCHAR2,
	p_suplr_desc		VARCHAR2,
	p_suplr_address 	VARCHAR2,
	p_assessee_code		VARCHAR2,
	p_suplr_div_code 	VARCHAR2,
	p_user			VARCHAR2,
	p_plant			VARCHAR2
)
IS

 v_bal_qty	number(12,3);
 v_folio_no	NUMBER;
 v_seq_no	NUMBER;
 v_count	NUMBER;

BEGIN
	proc_find_folio_no
	(
		p_bu,
		p_type,
		p_year,
		p_period,
		p_prod_id,
		p_prod_rev,
		p_user,
		p_plant,
		v_folio_no,
		v_seq_no
	);
	
		
	SELECT 	count(*)
	INTO	v_count
	FROM	rg23ap1_hd
	WHERE	rg23ap1hd_bu = p_bu
	AND	rg23ap1hd_year = p_year
	AND	rg23ap1hd_period = p_period
	AND	rg23ap1hd_prod_id = p_prod_id
	AND	rg23ap1hd_prod_rev = p_prod_rev
	AND     rg23ap1hd_plnt = p_plant
	AND	rg23ap1hd_folio_no = v_folio_no;
	
	
	IF v_count = 0 THEN
		INSERT INTO rg23ap1_hd VALUES
		(
			p_bu,
			p_year,         
			p_period       ,
			p_prod_id      ,
			p_prod_rev     ,
			v_folio_no     ,
			p_user,
			sysdate,
			null,
			null,
			p_plant
		);
		
	END IF;
	
	SELECT	NVL(SUM(rg23ap1ln_bal_qty),0)
	INTO	v_bal_qty
	FROM	rg23ap1_ln,rg23ap1_hd
	WHERE   rg23ap1hd_bu = rg23ap1ln_bu
	AND     rg23ap1hd_folio_no = rg23ap1ln_folio_no
	AND     rg23ap1hd_year = rg23ap1ln_year
	AND     rg23ap1hd_period = rg23ap1ln_period
	AND     rg23ap1hd_plnt = rg23ap1ln_plnt
	AND	rg23ap1ln_folio_no = v_folio_no
	AND	rg23ap1ln_seq_no = v_seq_no -1
	AND     rg23ap1ln_bu = p_bu
	AND     rg23ap1hd_prod_id = p_prod_id
	AND     rg23ap1hd_prod_rev = p_prod_rev
	AND     rg23ap1hd_plnt = p_plant;	
	
	
	IF p_doc_type  IN ('GRN','SRN') THEN
		
		      

		INSERT INTO rg23ap1_ln
		(
			rg23ap1ln_bu                   ,
			rg23ap1ln_year                 ,
			rg23ap1ln_period               ,
			rg23ap1ln_folio_no             ,
			rg23ap1ln_seq_no               ,
			rg23ap1ln_trans_type           ,
			rg23ap1ln_doc_type             ,
			rg23ap1ln_date                 ,
			rg23ap1ln_input_desc           ,
			rg23ap1ln_comdty_code	       ,
			rg23ap1ln_rcpt_r_rtn_qty       ,
			rg23ap1ln_pur_ref_doc_nos      ,
			rg23ap1ln_sup_ref_doc_nos      ,	
			rg23ap1ln_suplr_id             ,
			rg23ap1ln_suplr_det            ,
			rg23ap1ln_assessee_code        ,
			rg23ap1ln_suplr_div_code       ,
			rg23ap1ln_bal_qty              ,
			rg23ap1ln_cre_by               ,
			rg23ap1ln_cre_date             ,
			rg23ap1ln_plnt
		)
		VALUES
		(
			p_bu,
			p_year,
			p_period,
			v_folio_no,
			v_seq_no,
			'T',
			p_doc_type,
			p_date,
			p_prod_desc,
			p_comdty_code,
			p_qty,
			p_doc_pfx||decode(p_doc_pfx,null,null,' / ')||' / '||p_doc_no||' / '||p_seq_no,
			p_suplr_ref,
			p_suplr_id,
			p_suplr_desc ||'-'||p_suplr_address,
			p_assessee_code,
			p_suplr_div_code,
			(v_bal_qty + p_qty),
			p_user,
			sysdate,
			p_plant
		);
		
		UPDATE	pur_ord_receipt_ln
		SET	porl_folio_no = v_folio_no,
			porl_folio_seq_no   =  v_seq_no
		WHERE	porl_bu = p_bu
		AND	porl_receipt_pfx = p_doc_pfx
		AND	porl_receipt_no = p_doc_no
		AND	porl_seq_no =p_seq_no;
		
	ELSIF p_doc_type IN ('MI','ME') THEN
		--raise_application_error(-20999,'rg23-'||p_doc_type||'-'||p_bu||p_year||v_folio_no);

		INSERT INTO rg23ap1_ln
		(
			rg23ap1ln_bu                 ,  
			rg23ap1ln_year               ,  
			rg23ap1ln_period             ,  
			rg23ap1ln_folio_no           ,  
			rg23ap1ln_seq_no             ,  
			rg23ap1ln_trans_type         ,  
			rg23ap1ln_doc_type           ,  
			rg23ap1ln_date               ,  
			rg23ap1ln_input_desc         ,  
			rg23ap1ln_comdty_code	     ,
			rg23ap1ln_chit_no            ,  
			rg23ap1ln_chit_date          ,  
			rg23ap1ln_issue_qty          ,  
			rg23ap1ln_bal_qty            ,  
			rg23ap1ln_cre_by             ,  
			rg23ap1ln_cre_date    	     ,
			rg23ap1ln_plnt
		)
		VALUES
		(
			p_bu,
			p_year,
			p_period,
			v_folio_no,
			v_seq_no,
			'T',
			p_doc_type,
			p_date,
			p_prod_desc,
			p_comdty_code,
			p_doc_pfx||decode(p_doc_pfx,null,null,' / ')||' / '||p_doc_no||' / '||p_seq_no,
			p_date,
			p_qty,
			v_bal_qty + p_qty,
			p_user,
			sysdate,
			p_plant
		);
	ELSIF p_doc_type IN ('RRN') THEN
		INSERT INTO rg23ap1_ln
		(
			rg23ap1ln_bu           		,        
			rg23ap1ln_year           	,      
			rg23ap1ln_period         	,      
			rg23ap1ln_folio_no       	,      
			rg23ap1ln_seq_no         	,      
			rg23ap1ln_trans_type     	,      
			rg23ap1ln_doc_type       	,      
			rg23ap1ln_date           	,      
			rg23ap1ln_input_desc     	,
			rg23ap1ln_suplr_id             ,
			rg23ap1ln_suplr_det            ,
			rg23ap1ln_assessee_code        ,
			rg23ap1ln_suplr_div_code       ,
			rg23ap1ln_sales_ref_doc_nos    	,
			rg23ap1ln_pur_rtn_qty          	,
			rg23ap1ln_bal_qty              	,
			rg23ap1ln_cre_by               	,
			rg23ap1ln_cre_date		,
			rg23ap1ln_plnt
		)
		VALUES
		(
			p_bu,
			p_year,
			p_period,
			v_folio_no,
			v_seq_no,
			'T',
			p_doc_type,
			p_date,
			p_prod_desc,
			p_suplr_id,
			p_suplr_desc,
			p_assessee_code,
			p_suplr_div_code,
			p_doc_pfx||decode(p_doc_pfx,null,null,' / ')||' / '||p_doc_no||' / '||p_seq_no,
			p_qty,
			v_bal_qty + p_qty,
			p_user,
			sysdate,
			p_plant
		);
	ELSIF p_doc_type = 'OTHRS' THEN
		INSERT INTO RG23ap1_ln
		(
			rg23ap1ln_bu       ,                    
			rg23ap1ln_year     ,                    
			rg23ap1ln_period   ,                    
			rg23ap1ln_folio_no ,                    
			rg23ap1ln_seq_no   ,                    
			rg23ap1ln_trans_type,                   
			rg23ap1ln_doc_type  ,                   
			rg23ap1ln_date      ,                   
			rg23ap1ln_input_desc ,                        
			rg23ap1ln_oth_doc_det,                  
			rg23ap1ln_oth_qty    ,                  
			rg23ap1ln_bal_qty    ,                  
			rg23ap1ln_cre_by     ,                  
			rg23ap1ln_cre_date   ,
			rg23ap1ln_plnt
		)
		VALUES
		(
			p_bu,
			p_year,
			p_period,
			v_folio_no,
			v_seq_no,
			'T',
			p_doc_type,
			p_date,
			p_prod_desc,
			p_doc_pfx||decode(p_doc_pfx,null,null,' / ')||' / '||p_doc_no||' / '||p_seq_no,
			p_qty,
			v_bal_qty + p_qty,
			p_user,
			sysdate,
			p_plant
		);
	END IF;
commit;
END;
/

show errors;