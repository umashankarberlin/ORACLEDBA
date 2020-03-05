CREATE OR REPLACE PROCEDURE proc_ins_rg57f4
(
  	p_bu			VARCHAR2,
  	p_type			VARCHAR2,
	p_date			DATE,
	p_year			NUMBER,
	p_period		NUMBER,
	p_doc_type		VARCHAR2,
	p_doc_no		VARCHAR2,
	p_ord_pfx		VARCHAR2,
	p_ord_no		VARCHAR2,
	p_rcpt_pfx		VARCHAR2,
	p_rcpt_no		VARCHAR2,
	p_prod_id		VARCHAR2,
	p_prod_rev		NUMBER,
	p_prod_desc		VARCHAR2,
	p_comdty_code		VARCHAR2,
	p_input_desc		VARCHAR2,
	p_qty			NUMBER,
	p_seq_no		NUMBER,
	p_suplr_id		VARCHAR2,
	p_suplr_address 	VARCHAR2,
	p_assessee_code		VARCHAR2,
	p_suplr_div_code 	VARCHAR2,
	p_user			VARCHAR2,
	p_cons_qty		NUMBER   DEFAULT 0,
	p_rcpt_qty		NUMBER	 DEFAULT 0,
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
	FROM	rg57f4_hd
	WHERE	rg57f4hd_bu = p_bu
	AND	rg57f4hd_plnt = p_plant
	AND	rg57f4hd_year = p_year
	AND	rg57f4hd_period = p_period
	AND	rg57f4hd_prod_id = p_prod_id
	AND	rg57f4hd_prod_rev = p_prod_rev
	AND	rg57f4hd_folio_no = v_folio_no;
	
	
	IF v_count = 0 THEN
		INSERT INTO rg57f4_hd VALUES
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
	
	/*SELECT	NVL(SUM(rg57f4_ln_bal_qty),0)
	INTO	v_bal_qty
	FROM	rg57f4_ln,rg23ap1_hd
	WHERE   rg57f4hd_bu = rg57f4_ln_bu
	AND     rg57f4hd_folio_no = rg57f4_ln_folio_no
	AND     rg57f4hd_year = rg57f4_ln_year
	AND     rg57f4hd_period = rg57f4_ln_period
	AND	rg57f4ln_folio_no = v_folio_no
	AND	rg57f4ln_seq_no = v_seq_no -1
	AND     rg57f4ln_bu = p_bu
	AND     rg57f4hd_prod_id = p_prod_id
	AND     rg57f4hd_prod_rev = p_prod_rev;*/	
	
	
	IF p_doc_type IN ('MI','ME','VS') THEN
		--raise_application_error(-20999,'rg23-'||p_doc_type||'-'||p_bu||p_year||v_folio_no);
--raise_application_error(-20999,p_rcpt_qty);
		INSERT INTO rg57f4_ln
		(
			rg57f4ln_bu			,                    
			rg57f4ln_plnt			,                    			
			rg57f4ln_year			,                  
			rg57f4ln_period			,                
			rg57f4ln_folio_no		,              
			rg57f4ln_seq_no  		,              
			rg57f4ln_trans_type		,            
			rg57f4ln_doc_type  		, 
			rg57f4ln_doc_no			,
			rg57f4ln_date      		,            
			rg57f4ln_input_desc		,            
			rg57f4ln_comdty_code		,           
			rg57f4ln_pur_ref_doc_nos 	,      
			rg57f4ln_sup_ref_doc_nos 	,	      
			rg57f4ln_suplr_id              	,
			rg57f4ln_suplr_det             	,
			rg57f4ln_assessee_code         	,
			rg57f4ln_suplr_div_code        	,
			rg57f4ln_chit_no               	,
			rg57f4ln_chit_date             	,
			rg57f4ln_issue_qty             	,
			rg57f4ln_sales_ref_doc_nos     	,
			rg57f4ln_oth_doc_det           	,
			rg57f4ln_cre_by                	,
			rg57f4ln_cre_date              	,
			rg57f4ln_upd_by                	,
			rg57f4ln_upd_date              	,
			rg57f4ln_ord_pfx               	,
			rg57f4ln_ord_no			,
			rg57f4ln_cons_qty		,
			rg57f4ln_receipt_qty		,
			rg57f4ln_receipt_pfx		,  
			rg57f4ln_receipt_no    
		)
		VALUES
		(
			p_bu				,
			p_plant				,
			p_year				,
			p_period			,
			v_folio_no			,
			v_seq_no			,
			'T'				,
			p_doc_type			,
			p_doc_no			,
			p_date				,
			NULL				,
			NULL				,
			NULL				,
			NULL				,
			p_suplr_id			,
			func_find_suplr_address(p_bu,p_suplr_id),
			NULL				,
			NULL				,
			NULL				,
			NULL				,
			p_qty				,
			NULL				,
			NULL				,
			p_user				,
			sysdate				,
			NULL				,
			NULL				,
			p_ord_pfx			,
			p_ord_no			,
			p_cons_qty			,
			p_rcpt_qty			,
			p_rcpt_pfx			,
			p_rcpt_no		
		);

	END IF;
COMMIT;
END;
/

show errors;