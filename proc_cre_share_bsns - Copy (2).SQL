CREATE OR REPLACE PROCEDURE proc_cre_share_bsns(
p_bu			VARCHAR2,
p_plnt			VARCHAR2,
p_rqst_pfx		VARCHAR2,
p_rqst_no		VARCHAR2,
p_rqst_seq_no		NUMBER,
p_rqst_sub_seq_no	NUMBER,
p_date			DATE,
p_prod_id		VARCHAR2,
p_prod_rev		VARCHAR2,
p_prl_uom		VARCHAR2,
p_qty			NUMBER,
--p_mode			VARCHAR2,
p_user			VARCHAR2,
p_flag	       OUT      VARCHAR2,
p_commit		VARCHAR2       DEFAULT 'N'
)
IS
  tot_qty		NUMBER(17,5);
  var_qty		NUMBER(17,5);
  tot_pct		NUMBER(5,2);
  var_cnt		NUMBER(10);
  var_rec_cnt		NUMBER(10);
  var_suplr_uom		VARCHAR2(5);
  
/* This cursor is used to select the supplier having rownum=1 to insert the total qty to that particular
   when count of PUR_REQ_LN_SCHLD_SUPLRS is 0*/
   
CURSOR C2
IS
SELECT *
  FROM prod_deflt_suplr_hd,
       prod_deflt_suplr_ln
 WHERE pdshd_bu = p_bu
   AND pdshd_plnt = p_plnt
   AND pdshd_bu      =   pdsln_bu
   --AND pdshd_plnt    =   pdsln_plnt
   AND pdshd_doc_no  =   pdsln_doc_no
   AND pdshd_prod_id =   p_prod_id
   AND pdshd_prod_rev=   p_prod_rev
   AND pdshd_plnt = p_plnt
   AND pdshd_status='A'
   AND (TRUNC(SYSDATE) between trunc(pdshd_eff_from) and trunc(pdshd_eff_to))
   AND ROWNUM=1;
   
 CR2 C2%ROWTYPE;

BEGIN
p_flag:='Y';
--DBMS_OUTPUT.PUT_LINE(1||P_FLAG);
/* This query is used to delete the records before inserting the records to PUR_REQ_LN_SCHLD_SUPLRS 
   for same request*/
   --RAISE_APPLICATION_ERROR(-20999,'ERR');
/*DELETE FROM PUR_REQ_LN_SCHLD_SUPLRS
WHERE   prlss_bu =p_bu
  AND 	prlss_rqst_pfx=p_rqst_pfx         
  AND 	prlss_rqst_no =p_rqst_no         
  AND   prlss_rqst_seq_no =p_rqst_seq_no     
  AND	prlss_rqst_sub_seq_no=p_rqst_sub_seq_no;*/
  
 SELECT COUNT(*) INTO var_rec_cnt 
   FROM pur_req_ln_schld_suplrs
  WHERE prlss_bu =p_bu
    AND prlss_rqst_pfx=p_rqst_pfx         
    AND prlss_rqst_no =p_rqst_no         
    AND prlss_rqst_seq_no =p_rqst_seq_no     
    AND	prlss_rqst_sub_seq_no=p_rqst_sub_seq_no;

/* This query is used to find the sum of share percentage */
IF var_rec_cnt = 0 THEN   
SELECT SUM(pdsln_pct) INTO tot_pct
  FROM prod_deflt_suplr_hd,
       prod_deflt_suplr_ln
 WHERE pdshd_bu = p_bu
   AND pdshd_plnt = p_plnt
   AND pdshd_bu      =   pdsln_bu
   --AND pdshd_plnt    =   pdsln_plnt
   AND pdshd_doc_no  =   pdsln_doc_no
   AND pdshd_prod_id =   p_prod_id
   AND pdshd_prod_rev=   p_prod_rev
   AND pdshd_plnt = p_plnt
   AND (SYSDATE between trunc(PDSHD_EFF_FROM) and trunc(PDSHD_EFF_TO))
   AND pdshd_status='A';
  
/* This query is used to insert the records into PUR_REQ_LN_SCHLD_SUPLRS basedon the share of business*/

FOR CR1 IN (SELECT *
  FROM prod_deflt_suplr_hd,
       prod_deflt_suplr_ln
 WHERE pdshd_bu = p_bu 
   AND pdshd_plnt = p_plnt
   AND pdshd_bu      =   pdsln_bu
   --AND pdshd_plnt    =   pdsln_plnt
   AND pdshd_doc_no  =   pdsln_doc_no
   AND pdshd_prod_id =   p_prod_id
   AND pdshd_prod_rev=   p_prod_rev
   AND pdshd_plnt = p_plnt
   AND (SYSDATE between trunc(PDSHD_EFF_FROM) and trunc(PDSHD_EFF_TO))
   AND pdshd_status='A')
   LOOP
  -- var_qty:=ROUND(p_qty*(cr1.pdsln_pct/100));
  --RAISE_APPLICATION_ERROR(-20999,p_qty||'-'||cr1.pdsln_pct);
     var_qty:=ROUND(p_qty*(cr1.pdsln_pct/tot_pct));
     var_suplr_uom :=func_find_suplr_uom(p_bu,
     					 cr1.pdsln_suplr_id,
					 p_prod_id,
					 p_prod_rev);
  
   
   IF var_qty>=1 THEN
   INSERT INTO pur_req_ln_schld_suplrs (prlss_bu             ,
                                        prlss_rqst_pfx       ,         
					prlss_rqst_no        ,         
					prlss_rqst_seq_no    ,     
					prlss_rqst_sub_seq_no,
					prlss_suplr_id       ,  
					prlss_suplr_name     , 
					prlss_sob_qty	     ,
					prlss_ordered_qty    ,  
					prlss_suplr_curcy_id ,  
					prlss_exchange_rate  ,  
					prlss_uom	     ,
					prlss_conv_factor    ,
					prlss_cre_by         ,  
					prlss_cre_date       ,  
					prlss_upd_by         ,  
					prlss_upd_date       ,  
					prlss_status	     ,
					prlss_mode
					)
				VALUES
				      (	p_bu		,	
					p_rqst_pfx	,	
					p_rqst_no	,	
					p_rqst_seq_no	,	
					p_rqst_sub_seq_no	,
					cr1.pdsln_suplr_id	,	
					func_find_suplr_name(p_bu,cr1.pdsln_suplr_id),
					var_qty,
					var_qty,
					func_find_suplr_curry(p_bu,cr1.pdsln_suplr_id),
					func_find_exchange_rate(p_bu,func_find_suplr_curry(p_bu,cr1.pdsln_suplr_id),NULL,p_date),
					func_find_suplr_uom(p_bu,cr1.pdsln_suplr_id,p_prod_id,p_prod_rev),
					func_find_uom_conversion(p_bu,
								 p_prod_id,
								 p_prod_rev,
								 p_prl_uom,
								 var_suplr_uom),
					p_user,
					SYSDATE,
					NULL,
					NULL,
					'N',
					cr1.pdsln_type
					);
	END IF;
	IF p_commit='Y' then
               COMMIT;
        END IF;
        
END LOOP;
/* This query is used to find the sum of ordered qty in PUR_REQ_LN_SCHLD_SUPLRS once after inserting the records*/
SELECT SUM(prlss_ordered_qty) INTO tot_qty
  FROM pur_req_ln_schld_suplrs
 WHERE  prlss_bu =p_bu
  AND 	prlss_rqst_pfx=p_rqst_pfx         
  AND 	prlss_rqst_no =p_rqst_no         
  AND   prlss_rqst_seq_no =p_rqst_seq_no     
  AND	prlss_rqst_sub_seq_no=p_rqst_sub_seq_no;
  
 /* This query is used to update the variance qty in supplier having rownum 1 */ 
 
  IF TOT_QTY<>P_QTY THEN
  --RAISE_APPLICATION_ERROR(-20999,'TOT_QTY'||'-'||TOT_QTY||'-'||P_QTY);
  UPDATE pur_req_ln_schld_suplrs
     SET prlss_ordered_qty=NVL(prlss_ordered_qty,0)+(p_qty-tot_qty),
         prlss_sob_qty=NVL(prlss_sob_qty,0)+(p_qty-tot_qty)
   WHERE prlss_bu =p_bu
  AND 	prlss_rqst_pfx=p_rqst_pfx         
  AND 	prlss_rqst_no =p_rqst_no         
  AND   prlss_rqst_seq_no =p_rqst_seq_no     
  AND	prlss_rqst_sub_seq_no=p_rqst_sub_seq_no
  AND   prlss_suplr_id=(SELECT   pdsln_suplr_id
                  FROM prod_deflt_suplr_hd, prod_deflt_suplr_ln
                 WHERE pdshd_bu = p_bu
                   AND pdshd_plnt = p_plnt
                   AND pdshd_bu = pdsln_bu
                   --AND pdshd_plnt    =   pdsln_plnt
                   AND pdshd_doc_no = pdsln_doc_no
                   AND pdshd_prod_id = p_prod_id
		   AND pdshd_prod_rev = p_prod_rev
                   AND p_date BETWEEN pdshd_eff_from AND pdshd_eff_to
                   AND pdshd_status = 'A'
                   AND ROWNUM=1);
IF p_commit='Y' then
               COMMIT;
        END IF;  
END IF;	

/* This query is used to delete the line having ordered qty zero*/

DELETE FROM PUR_REQ_LN_SCHLD_SUPLRS
WHERE   prlss_bu =p_bu
  AND 	prlss_rqst_pfx=p_rqst_pfx         
  AND 	prlss_rqst_no =p_rqst_no         
  AND   prlss_rqst_seq_no =p_rqst_seq_no     
  AND	prlss_rqst_sub_seq_no=p_rqst_sub_seq_no
  AND   prlss_ordered_qty=0;
 
 IF p_commit='Y' then
                COMMIT;
        END IF;
 
 /*This query is used to find the count of PUR_REQ_LN_SCHLD_SUPLRS*/
 
SELECT COUNT(*) INTO var_cnt
  FROM pur_req_ln_schld_suplrs
 WHERE  prlss_bu =p_bu
  AND 	prlss_rqst_pfx=p_rqst_pfx         
  AND 	prlss_rqst_no =p_rqst_no         
  AND   prlss_rqst_seq_no =p_rqst_seq_no     
  AND	prlss_rqst_sub_seq_no=p_rqst_sub_seq_no;
--DBMS_OUTPUT.PUT_LINE(2);  
 IF VAR_CNT=0 THEN
-- DBMS_OUTPUT.PUT_LINE(3||VAR_CNT);
 OPEN  C2;
 FETCH C2 INTO CR2;
 IF C2%NOTFOUND THEN
-- DBMS_OUTPUT.PUT_LINE(4||P_FLAG);
 p_flag:='N';
 --DBMS_OUTPUT.PUT_LINE(5||P_FLAG);
-- RAISE_APPLICATION_ERROR(-20999,'ERR'||p_flag);
 END IF;
 
 --DBMS_OUTPUT.PUT_LINE(6||P_FLAG);
 IF C2%FOUND THEN
 var_suplr_uom :=func_find_suplr_uom(p_bu,
      				     cr2.pdsln_suplr_id,
 				     p_prod_id,
				     p_prod_rev);
   INSERT 
     INTO 
   PUR_REQ_LN_SCHLD_SUPLRS 
                       (prlss_bu             ,
			prlss_rqst_pfx       ,         
			prlss_rqst_no        ,         
			prlss_rqst_seq_no    ,     
			prlss_rqst_sub_seq_no,
			prlss_suplr_id       ,  
			prlss_suplr_name     , 
			prlss_sob_qty	     ,
			prlss_ordered_qty    ,  
			prlss_suplr_curcy_id ,  
			prlss_exchange_rate  ,  
			prlss_uom            ,
			prlss_conv_factor    ,
			prlss_cre_by         ,  
			prlss_cre_date       ,  
			prlss_upd_by         ,  
			prlss_upd_date       ,  
			prlss_status	     ,
			prlss_mode
			)
		VALUES
		      (	p_bu		,	
			p_rqst_pfx	,	
			p_rqst_no	,	
			p_rqst_seq_no	,	
			p_rqst_sub_seq_no	,
			cr2.pdsln_suplr_id	,	
			func_find_suplr_name(p_bu,cr2.pdsln_suplr_id),
			p_qty,
			p_qty,
			func_find_suplr_curry(p_bu,cr2.pdsln_suplr_id),
			func_find_exchange_rate(p_bu,func_find_suplr_curry(p_bu,cr2.pdsln_suplr_id),NULL,p_date),
			func_find_suplr_uom(p_bu,cr2.pdsln_suplr_id,p_prod_id,p_prod_rev),
			func_find_uom_conversion(p_bu,
						 p_prod_id,
						 p_prod_rev,
						 p_prl_uom,
						 var_suplr_uom),
			p_user,
			SYSDATE,
			NULL,
			NULL,
			'N',
			cr2.pdsln_type
			);
-- DBMS_OUTPUT.PUT_LINE(7||P_FLAG);
 END IF;
CLOSE C2;			
END IF;	
END IF;--var_rec_cnt
IF p_commit='Y' then
               COMMIT;
        END IF;
-- DBMS_OUTPUT.PUT_LINE(8||P_FLAG);

--RAISE_APPLICATION_ERROR(-20999,'ERR'||P_FLAG);
END;
/

SHOW ERRORS;
					
					