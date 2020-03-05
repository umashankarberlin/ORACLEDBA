CREATE OR REPLACE PROCEDURE proc_ins_rg23_pa_2
(
	p_bu			VARCHAR2,
	p_date			DATE,
	p_year			NUMBER,
	p_period		NUMBER,
	p_type			VARCHAR2,
	p_trans_type		VARCHAR2,
	p_doc_type		VARCHAR2,
	p_tc_type		VARCHAR2,
	p_tc_amount		NUMBER,
	p_doc_pfx		VARCHAR2,
	p_doc_no		VARCHAR2,
	p_seq_no		NUMBER,
	p_suplr_id		VARCHAR2,
	p_suplr_ecc_no		VARCHAR2,
	p_suplr_div_code	VARCHAR2,
	p_suplr_det		VARCHAR2,
	p_folio_no		VARCHAR2,
	p_folio_seq_no		VARCHAR2,
	p_tariff_no		VARCHAR2,
	p_ecc_no		VARCHAR2,
	p_user			VARCHAR2,
	p_suplr_desc		VARCHAR2,
	p_suplr_doc_no 		VARCHAR2,
	p_suplr_doc_date	DATE,
	p_suplr_dc_no		VARCHAR2,
	p_suplr_dc_date		DATE,
	p_pfx			VARCHAR2,
	p_rcpt_no		VARCHAR2,
	p_ac_value              NUMBER,
        p_p2_folio_no	IN OUT	NUMBER ,
	p_p2_seq_no	IN OUT	NUMBER,
	p_commit_flag		VARCHAR2 DEFAULT 'Y',
	p_plant			VARCHAR2
)
IS

v_folio_no	NUMBER;
v_seq_no 	NUMBER;
v_count		NUMBER;

BEGIN
	v_folio_no := p_p2_folio_no;
	v_seq_no := p_p2_seq_no;
	IF p_p2_folio_no IS NULL AND p_p2_seq_no IS NULL THEN
		proc_find_folio_no
		(
			p_bu,
			p_type,
			p_year,
			p_period,
			null,
			null,
			p_user,
			p_plant,
			v_folio_no,
			v_seq_no
		);
	END IF;
	
	p_p2_folio_no := v_folio_no;
	p_p2_seq_no := v_seq_no;
	
	SELECT	count(*)
	INTO	v_count
	FROM	rg23acp2_pla_hd
	WHERE	rg23acp2hd_bu = p_bu
	AND	rg23acp2hd_year = p_year
	AND	rg23acp2hd_period = p_period
	AND	rg23acp2hd_type = p_type
	AND	rg23acp2hd_folio_no = v_folio_no
	AND     rg23acp2hd_plnt = p_plant;
	
	IF v_count = 0 THEN
	
		INSERT INTO rg23acp2_pla_hd VALUES
		(
			p_bu          ,        
			p_year        ,        
			p_period      ,        
			p_type        ,        
			v_folio_no    ,        
			p_user	      ,        
			sysdate	      ,        
			NULL	      ,        
			NULL,
			p_plant
		);
	END IF;
	
	
	INSERT INTO rg23acp2_pla_ln
	(
		rg23acp2ln_bu             ,
		rg23acp2ln_type     ,
		rg23acp2ln_folio_no   ,
		rg23acp2ln_seq_no         ,
		rg23acp2ln_trans_type     ,
		rg23acp2ln_doc_type       ,
		rg23acp2ln_date           ,
		rg23acp2ln_year           ,
		rg23acp2ln_period         ,
		rg23acp2ln_tc_type        ,
		rg23acp2ln_tc_amount      ,
		rg23acp2ln_fca_ref_doc_nos,
		rg23acp2ln_suplr_ecc_no   ,
		rg23acp2ln_suplr_div_code ,
		rg23acp2ln_suplr_id       ,
		rg23acp2ln_suplr_det      ,
		rg23acp2ln_rg23ap1_folio  ,
		rg23acp2ln_rg23ap1_seq_no ,
		rg23acp2ln_rg23cp1_folio  ,
		rg23acp2ln_rg23cp1_seq_no ,
		rg23acp2ln_dr_ref_doc_nos ,
		rg23acp2ln_dr_ref_date    ,
		rg23acp2ln_tariff_hd_no   ,
		rg23acp2ln_cust_ecc_no    ,
		rg23acp2ln_cre_by         ,
		rg23acp2ln_cre_date       ,
		rg23acp2ln_suplr_desc1	  ,         
		rg23acp2ln_suplr_doc_no   ,        
		rg23acp2ln_suplr_doc_date ,      
		rg23acp2ln_suplr_dc_no    ,         
		rg23acp2ln_suplr_dc_date  ,       
		rg23acp2ln_receipt_pfx    ,         
		rg23acp2ln_receipt_no     ,
                rg23acp2ln_ac_value 	  ,
                rg23acp2ln_plnt
	)
	VALUES
	(
		p_bu,
		p_type,
		v_folio_no,
		v_seq_no,
		p_trans_type,
		p_doc_type,
		p_date,
		p_year,
		p_period,
		p_tc_type,
		p_tc_amount,
		p_doc_pfx||' / '||p_doc_no ||' / '||p_seq_no,
		p_suplr_ecc_no		,
		p_suplr_div_code	,
		p_suplr_id		,
		p_suplr_det		,
		p_folio_no,
		p_folio_seq_no,
		p_folio_no,
		p_folio_seq_no,
		p_doc_pfx||' / '||p_doc_no ||' / '||p_seq_no,
		p_date,
		p_tariff_no,
		p_ecc_no,
		p_user,
		sysdate,
		p_suplr_desc,
		p_suplr_doc_no,
		p_suplr_doc_date,
		p_suplr_dc_no,
		p_suplr_dc_date,
		p_pfx,
		p_rcpt_no,
		p_ac_value,
		p_plant
	);
	IF p_commit_flag = 'Y' THEN
		COMMIT;	
	END IF;
END;
/