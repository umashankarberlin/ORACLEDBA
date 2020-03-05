/*

  Revision History
  -------------------------------------------------------------------------
  |Revision |Last Update By     | Last Update Date |Purpose                |
  |         |                   |                  |                       |
  -------------------------------------------------------------------------
  |1        | Selva kumar. T    | 22-Aug-2007      |Coding and development |
  |         |                   |                  |                       |
  -------------------------------------------------------------------------


  Description of the Procedure:
	
	 

  Referenced by  :

  References     :
	   
*/
CREATE OR REPLACE PROCEDURE proc_ins_tqm(
     p_bu                  VARCHAR2,
     p_pln_pfx             VARCHAR2,
     p_pln_no              VARCHAR2,
     p_year		   NUMBER,
     p_rev                 NUMBER,
     p_period		   NUMBER,
     p_oper		   VARCHAR2,
     p_mode                VARCHAR2,
     p_qc_type 		   VARCHAR2,
     p_qc_id 		   VARCHAR2,
     p_control_person      VARCHAR2,
     p_reference           VARCHAR2,
     p_user                VARCHAR2,
     p_res        OUT     VARCHAR2,
     p_plant               VARCHAR2 
) IS 
         
	CURSOR c1 	
	IS
	SELECT  *
	FROM 	tqm_qc_plan_ln 
	WHERE 	tqpln_bu = p_bu 
	AND 	tqpln_pln_pfx = p_pln_pfx
	AND 	tqpln_pln_no = p_pln_no
	AND 	tqpln_status  IN('N','P')  
	AND 	((p_oper = 'P' AND tqpln_temp_qty >0) OR P_OPER ='W');

      
     

     v_doc_no                VARCHAR2(15);  /*to store the document next no */
     v_year                  NUMBER(6);	    /* to store the year of the date */	
     v_period                NUMBER(2);	    /* to store the period of the date */
     v_seq_no                NUMBER(3):= 0; /* to store the auto generated seq no. */
     v_prod_ser_lot_type     VARCHAR2(1);   /* to store product lot serial option */
     v_sub_seq_no	     NUMBER;	
     v_sub_ser_seq_no	     NUMBER;		
     v_ln_seq_no             NUMBER;        /* to store the auto generated seq no. */
     v_lot_seq_no            NUMBER;	    /* to store the auto generated seq no. */
     v_ser_seq_no            NUMBER;	    /* to store the auto generated seq no. */
     v_issuer_id             VARCHAR2(10);  /* to store the employee id */	
     v_issuer_name           VARCHAR2(100); /* to store the employee name */
     v_issuer_pos_id         VARCHAR2(10);  /* to store employee position */
     v_issuer_pos_name       VARCHAR2(50);  /* to store employee positon */
     v_dummy                 VARCHAR2(50);  /* dummy variable to store unwanted values which is return from procedure */
     v_plant                 VARCHAR2(10);  /* to store the plant */
     v_order_date             DATE;	    /* to store the production order date */	
     v_count_hd              NUMBER;    
BEGIN

          
	  		INSERT INTO tqm_qc_hd 
	  		(
	  			tqhd_bu                ,
	  			tqhd_qc_pfx            ,
	  			tqhd_qc_no             ,
	  			tqhd_qc_rev	       , 
	  			tqhd_date              ,
	  			tqhd_insp_mode         ,
	  			tqhd_qc_type           ,
	  			tqhd_qc_id             ,
	  			tqhd_control_person    ,
	  			tqhd_doc_action	       ,
	  			tqhd_reference	       ,
	  			tqhd_status            ,
	  			tqhd_cre_by            ,
	  			tqhd_cre_date 		,
	  			tqhd_plnt
	  		)
	  		VALUES
	  		(
	  			p_bu			,
	  			p_pln_pfx	  	,
	  			p_pln_no   		,
	  			p_rev			,
	  			trunc(sysdate)		,
	  			p_mode			,
	  			p_qc_type 		,
	  			p_qc_id			,
	  			p_control_person 	,
	  			'N'			,
	  			p_reference		,
	  			'N'			,
	  			p_user			,
	  			sysdate			,
	  			p_plant
			);
		
		 
		
         		
		
		  
		FOR cr1 IN c1
         	LOOP
         		 
         		v_seq_no := v_seq_no + 1;   
         		
         		IF p_qc_type = 'V' AND  p_mode = 'PR' THEN
         		--RAISE_APPLICATION_ERROR(-20999,'TEST'||cr1.tqpln_receipt_qty||' -'|| cr1.tqpln_qc_qty);
         			INSERT INTO tqm_qc_pur_rct_ln	 
				(					  							                
						tqprln_bu 		,                     
						tqprln_qc_pfx		,                  
						tqprln_qc_no 		,                  
						tqprln_qc_rev		,                  
						tqprln_seq_no		,                  
						tqprln_pln_seq_no	,              
						tqprln_prod_id   	,              
						tqprln_prod_rev  	,              
						tqprln_uom       	,              
						tqprln_no_of_samples	,           
						tqprln_sample_qty   	,           
						tqprln_no_of_obs    	,           
						tqprln_std_acc_qty  	,           
						tqprln_std_rej_qty  	,           
						tqprln_attained_res 	,           
						tqprln_auto_flag    	,   
						tqprln_receipt_qty  	,           
						tqprln_accept_qty   	,           
						tqprln_aod_qty      	,           
						tqprln_reject_qty   	,           
						tqprln_qc_qty       	,           
						tqprln_control_person	,          
						tqprln_doc_action    	,          
						tqprln_reference     	,          
						tqprln_appr_id       	,          
						tqprln_appr_pos      	,          
						tqprln_appr_date     	,          
						tqprln_appr_commnt   	,          
						tqprln_status        	,          
						tqprln_receipt_pfx   	,          
						tqprln_receipt_no    	,          
						tqprln_receipt_seq_no	,          
						tqprln_cre_by        	,          
						tqprln_cre_date      	 ,
						tqprln_accept_basis
					 	
					)												        
					VALUES											       
					(
						cr1.tqpln_bu            ,      
						cr1.tqpln_pln_pfx       ,	         
						cr1.tqpln_pln_no        ,       
						p_rev                   ,
						v_seq_no,
						cr1.tqpln_seq_no        ,         
						cr1.tqpln_prod_id       ,     
						cr1.tqpln_prod_rev      ,      
						cr1.tqpln_uom           ,      
						0           		,
						DECODE(p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
						0               	,
						0             		,
						0             		,
						0            		,
						'M'		        ,
						DECODE(p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
						0			,    
						0                 	,
						0              		,
						0                  	,
						p_control_person	,         
						'N'			,     
						cr1.tqpln_reference     ,  
						NULL                	,
						NULL                	,
						NULL               	,
						NULL             	,
						'N'                  	,
						cr1.tqpln_doc_pfx   	,       
						cr1.tqpln_doc_no    	,       
						cr1.tqpln_doc_seq_no	,       
						p_user		        ,       
						sysdate                 ,
						'AF'
				);
			END IF;
			
			
			IF p_qc_type = 'V' AND  p_mode = 'SC' THEN
			
         			INSERT INTO tqm_qc_pur_rct_ln	 
				(					  							                
						tqprln_bu 		,                     
						tqprln_qc_pfx		,                  
						tqprln_qc_no 		,                  
						tqprln_qc_rev		,                  
						tqprln_seq_no		,                  
						tqprln_pln_seq_no	,              
						tqprln_prod_id   	,              
						tqprln_prod_rev  	,              
						tqprln_uom       	,              
						tqprln_no_of_samples	,           
						tqprln_sample_qty   	,           
						tqprln_no_of_obs    	,           
						tqprln_std_acc_qty  	,           
						tqprln_std_rej_qty  	,           
						tqprln_attained_res 	,           
						tqprln_auto_flag    	,           
						tqprln_receipt_qty  	,          
						tqprln_accept_qty   	,           
						tqprln_aod_qty      	,           
						tqprln_reject_qty   	,           
						tqprln_qc_qty       	,           
						tqprln_control_person	,          
						tqprln_doc_action    	,          
						tqprln_reference     	,          
						tqprln_appr_id       	,          
						tqprln_appr_pos      	,          
						tqprln_appr_date     	,          
						tqprln_appr_commnt   	,          
						tqprln_status        	,          
						tqprln_receipt_pfx   	,          
						tqprln_receipt_no    	,          
						tqprln_receipt_seq_no	,          
						tqprln_cre_by        	,          
						tqprln_cre_date      	,
						tqprln_accept_basis     
					 	
					)												        
					VALUES											       
					(
						cr1.tqpln_bu            ,      
						cr1.tqpln_pln_pfx       ,	         
						cr1.tqpln_pln_no        ,       
						p_rev                   ,
						v_seq_no		,
						cr1.tqpln_seq_no        ,         
						cr1.tqpln_prod_id       ,     
						cr1.tqpln_prod_rev      ,      
						cr1.tqpln_uom           ,      
						0           		,
						DECODE(p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
						0               	,
						0             		,
						0             		,
						0            		,
						'M'		        , 
						DECODE(p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
						0		        ,    
						0                 	,
						0              		,
						0                  	,
						p_control_person	,         
						'N'			,     
						cr1.tqpln_reference     ,  
						NULL                	,
						NULL                	,
						NULL               	,
						NULL             	,
						'N'                  	,
						cr1.tqpln_doc_pfx   	,       
						cr1.tqpln_doc_no    	,       
						cr1.tqpln_doc_seq_no	,       
						p_user		        ,       
						sysdate                 ,
						'AF'
				);
			
			END IF;
			
			IF p_qc_type = 'D' AND  p_mode = 'FG' THEN
		
				INSERT INTO tqm_qc_fg_rct_ln	 
				(					  							                
						tqfrln_bu		,              
						tqfrln_qc_pfx		,          
						tqfrln_qc_no 		,          
						tqfrln_qc_rev		,          
						tqfrln_seq_no		,          
						tqfrln_pln_seq_no	,      
						tqfrln_prod_id   	,      
						tqfrln_prod_rev  	,      
						tqfrln_uom       	,      
						tqfrln_no_of_samples	,   
						tqfrln_sample_qty   	,   
						tqfrln_no_of_obs    	,   
						tqfrln_std_acc_qty  	,   
						tqfrln_std_rej_qty  	,   
						tqfrln_attained_res 	,   
						tqfrln_auto_flag    	,   
						tqfrln_receipt_qty  	,   
						tqfrln_accept_qty   	,   
						tqfrln_aod_qty      	,   
						tqfrln_reject_qty   	,   
						tqfrln_qc_qty       	,   
						tqfrln_control_person	,  
						tqfrln_doc_action    	,  
						tqfrln_reference     	,  
						tqfrln_appr_id       	,  
						tqfrln_appr_pos      	,  
						tqfrln_appr_date     	,  
						tqfrln_appr_commnt   	,  
						tqfrln_status        	,  
						tqfrln_store_id      	,  
						tqfrln_ord_type      	,  
						tqfrln_ord_no        	,  
						tqfrln_cre_by        	,  
						tqfrln_cre_date      	  			        
				)												        
				VALUES											       
				(
						cr1.tqpln_bu            ,     
						cr1.tqpln_pln_pfx    	,
						cr1.tqpln_pln_no      	,
						p_rev          		,
						v_seq_no		,
						cr1.tqpln_seq_no      	,
						cr1.tqpln_prod_id      	,
						cr1.tqpln_prod_rev     	,
						cr1.tqpln_uom          	,
						0   			,
						DECODE(p_oper,'W',(cr1.tqpln_receipt_qty- cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
						0       		,
						0     			,
						0     			,
						0		    	,
						'M'      		,
						DECODE(p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
						0		    	,
						0        		,
						0      			,
						0          		,
						p_control_person  	,
						'N'      		,
						cr1.tqpln_reference     ,  
						NULL         		,
						NULL        		,
						NULL       		,
						NULL     		,
						'N'          		,
						cr1.tqpln_store_proc_id ,   
						cr1.tqpln_ord_type    	,
						cr1.tqpln_ord_no       	,
						p_user          	,
						sysdate  
				);			
			END IF;
			
			IF p_qc_type = 'C' AND  p_mode = 'SR' THEN
				INSERT INTO tqm_qc_sale_rtn_ln
				(
					tqsarln_bu 		,            
					tqsarln_qc_pfx		,         
					tqsarln_qc_no 		,         
					tqsarln_qc_rev		,         
					tqsarln_seq_no		,         
					tqsarln_pln_seq_no	,     
					tqsarln_prod_id   	,     
					tqsarln_prod_rev  	,     
					tqsarln_uom       	,     
					tqsarln_no_of_samples	,  
					tqsarln_sample_qty   	,  
					tqsarln_no_of_obs    	,  
					tqsarln_std_acc_qty  	,  
					tqsarln_std_rej_qty  	,  
					tqsarln_attained_res 	,  
					tqsarln_auto_flag    	,  
					tqsarln_receipt_qty  	,  
					tqsarln_accept_qty   	,  
					tqsarln_aod_qty      	,  
					tqsarln_reject_qty   	,  
					tqsarln_qc_qty       	,  
					tqsarln_control_person	,
					tqsarln_doc_action    	, 
					tqsarln_reference     	, 
					tqsarln_appr_id       	, 
					tqsarln_appr_pos      	, 
					tqsarln_appr_date     	, 
					tqsarln_appr_commnt   	, 
					tqsarln_status        	, 
					tqsarln_so_pfx        	, 
					tqsarln_so_no         	, 
					tqsarln_so_seq_no     	, 
					tqsarln_so_sub_seq_no 	, 
					tqsarln_cre_by        	, 
					tqsarln_cre_date       
						        			
				)
				VALUES
				(
					cr1.tqpln_bu       	,     
					cr1.tqpln_pln_pfx  	,       
					cr1.tqpln_pln_no   	,       
					p_rev         		,
					v_seq_no		,
					cr1.tqpln_seq_no   	,      
					cr1.tqpln_prod_id  	,      
					cr1.tqpln_prod_rev 	,      
					cr1.tqpln_uom      	,      
					0  			,
					DECODE(p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
					0     			,
					0    			,
					0    			,
					0   			,
					'M'      		,
					DECODE(p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
					0        		,
					0     			,
					0         		,
					0         		,
					p_control_person	,
					'N'     		,
					cr1.tqpln_reference	,      
					NULL        		,
					NULL			,
					NULL			,
					NULL			,
					'N'         		,
					cr1.tqpln_doc_pfx  	,       
					cr1.tqpln_doc_no   	,       
					cr1.tqpln_doc_seq_no	,      
					cr1.tqpln_doc_sub_seq_no,  
					p_user         		,
					SYSDATE      		
						    
				);

			END IF;
			
			IF p_qc_type = 'D' AND  p_mode = 'SF' THEN
				INSERT INTO TQM_QC_SF_RCT_LN
				(
					tqsrln_bu   		,           
					tqsrln_qc_pfx		,          
					tqsrln_qc_no 		,          
					tqsrln_qc_rev		,          
					tqsrln_seq_no		,          
					tqsrln_pln_seq_no	,      
					tqsrln_prod_id   	,      
					tqsrln_prod_rev  	,      
					tqsrln_uom       	,      
					tqsrln_no_of_samples	,   
					tqsrln_sample_qty   	,   
					tqsrln_no_of_obs    	,   
					tqsrln_std_acc_qty  	,   
					tqsrln_std_rej_qty  	,   
					tqsrln_attained_res 	,   
					tqsrln_auto_flag    	,   
					tqsrln_receipt_qty  	,   
					tqsrln_accept_qty   	,   
					tqsrln_aod_qty      	,   
					tqsrln_reject_qty   	,   
					tqsrln_qc_qty       	,   
					tqsrln_control_person	,  
					tqsrln_doc_action    	,  
					tqsrln_reference     	,  
					tqsrln_appr_id       	,  
					tqsrln_appr_pos      	,  
					tqsrln_appr_date     	,  
					tqsrln_appr_commnt   	,  
					tqsrln_status        	,  
					tqsrln_proc_id       	,  
					tqsrln_ord_type      	,  
					tqsrln_ord_no        	,  
					tqsrln_cre_by        	,  
					tqsrln_cre_date        
							     
				)
				VALUES
				(
					cr1.tqpln_bu         	,     
					cr1.tqpln_pln_pfx    	,      
					cr1.tqpln_pln_no     	,      
					p_rev          		,
					v_seq_no		,
					cr1.tqpln_seq_no     	,     
					cr1.tqpln_prod_id    	,     
					cr1.tqpln_prod_rev   	,     
					cr1.tqpln_uom        	,     
					0   			,
					DECODE(p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
					0			,
					0			,
					0			,
					0			,
					'M'			,
					DECODE(p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
					0			,
					0			,		
					0			,
					0			,
					p_control_person	,  
					'N'      		,
					cr1.tqpln_reference	,       
					NULL			,
					NULL			,
					NULL			,
					NULL			,
					'N'			,
					cr1.tqpln_store_proc_id	,         
					cr1.tqpln_ord_type	,
					cr1.tqpln_ord_no	,
					p_user			,
					SYSDATE
				);		
			END IF;
			

			IF p_qc_type = 'D' AND  p_mode = 'MR' THEN
			INSERT INTO TQM_QC_MAT_RTN_LN
			(
					tqmrln_bu   		,           
					tqmrln_qc_pfx		,          
					tqmrln_qc_no 		,          
					tqmrln_qc_rev		,          
					tqmrln_seq_no		,          
					tqmrln_pln_seq_no	,      
					tqmrln_prod_id   	,      
					tqmrln_prod_rev  	,      
					tqmrln_uom       	,      
					tqmrln_no_of_samples	,   
					tqmrln_sample_qty   	,   
					tqmrln_no_of_obs    	,   
					tqmrln_std_acc_qty  	,   
					tqmrln_std_rej_qty  	,   
					tqmrln_attained_res 	,   
					tqmrln_auto_flag    	,   
					tqmrln_receipt_qty  	,   
					tqmrln_accept_qty   	,   
					tqmrln_aod_qty      	,   
					tqmrln_reject_qty   	,   
					tqmrln_qc_qty       	,   
					tqmrln_control_person	,  
					tqmrln_doc_action    	,  
					tqmrln_reference     	,  
					tqmrln_appr_id       	,  
					tqmrln_appr_pos      	,  
					tqmrln_appr_date     	,  
					tqmrln_appr_commnt   	,  
					tqmrln_status        	,  
					tqmrln_doc_no        	,  
					tqmrln_doc_seq_no    	,  
					tqmrln_cre_by        	,  
					tqmrln_cre_date        
							   
			)
			VALUES
			(
					cr1.tqpln_bu         	,     
					cr1.tqpln_pln_pfx    	,      
					cr1.tqpln_pln_no     	,      
					p_rev          		,
					v_seq_no		,
					cr1.tqpln_seq_no     	,     
					cr1.tqpln_prod_id    	,     
					cr1.tqpln_prod_rev   	,     
					cr1.tqpln_uom        	,     
					0   			,
					DECODE(p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
					0			,
					0			,
					0			,
					0			,
					'M'			,
					DECODE(p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
					0			,
					0			,
					0			,
					0			,
					p_control_person  	,
					'N'			,
					cr1.tqpln_reference  	,     
					NULL			,
					NULL			,
					NULL			,
					NULL			,
					'N'			,
					cr1.tqpln_doc_no     	,     
					cr1.tqpln_doc_seq_no 	,     
					p_user          	,
					SYSDATE
							
			);
			
			END IF;
			IF p_qc_type = 'D' AND  p_mode= 'SO' THEN
				INSERT INTO TQM_QC_SW_RCT_LN
				(
					tqswrln_bu    		,         
					tqswrln_qc_pfx		,         
					tqswrln_qc_no 		,         
					tqswrln_qc_rev		,         
					tqswrln_seq_no		,         
					tqswrln_pln_seq_no	,     
					tqswrln_prod_id   	,     
					tqswrln_prod_rev  	,     
					tqswrln_uom       	,     
					tqswrln_no_of_samples	,  
					tqswrln_sample_qty   	,  
					tqswrln_no_of_obs    	,  
					tqswrln_std_acc_qty  	,  
					tqswrln_std_rej_qty  	,  
					tqswrln_attained_res 	,  
					tqswrln_auto_flag    	,  
					tqswrln_receipt_qty  	,  
					tqswrln_accept_qty   	,  
					tqswrln_aod_qty      	,  
					tqswrln_reject_qty   	,  
					tqswrln_qc_qty       	,  
					tqswrln_control_person	, 
					tqswrln_doc_action    	, 
					tqswrln_reference     	, 
					tqswrln_appr_id       	, 
					tqswrln_appr_pos      	, 
					tqswrln_appr_date     	, 
					tqswrln_appr_commnt   	, 
					tqswrln_status        	, 
					tqswrln_store_id      	, 
					tqswrln_ord_type      	, 
					tqswrln_ord_no        	, 
					tqswrln_cre_by        	, 
					tqswrln_cre_date      	 

				)
				VALUES
				(
					cr1.tqpln_bu            ,
					cr1.tqpln_pln_pfx       , 
					cr1.tqpln_pln_no        ,  
					p_rev         		,
					v_seq_no		,
					cr1.tqpln_seq_no        , 
					cr1.tqpln_prod_id       , 
					cr1.tqpln_prod_rev      , 
					cr1.tqpln_uom           , 
					0			,
					DECODE(p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
					0			,
					0			,
					0			,
					0			,
					'M'			,
					DECODE(p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty),
					0			,
					0			,
					0			,
					0			,
					p_control_person 	,
					'N'			,
					cr1.tqpln_reference     , 
					NULL			,
					NULL			,
					NULL			,
					NULL			,
					'N'			,
					cr1.tqpln_store_proc_id ,      
					cr1.tqpln_ord_type      , 
					cr1.tqpln_ord_no        , 
					p_user         		,
					SYSDATE
				);
			END IF;
	

	                    
			/* function return the product serial lot type for the given parameter */
		     	  v_prod_ser_lot_type :=
	                    func_find_prod_ser_lot_type(
	                         p_bu,
	                         cr1.tqpln_prod_id,
	                         cr1.tqpln_prod_rev
                    );
	
	
	       		/* insert into serial/lot details based on the product serial lot type*/
               		IF v_prod_ser_lot_type IN ('L','O') THEN
               			v_sub_seq_no  := 0;

               			FOR rec_lot IN(
               					SELECT *
                                		FROM tqm_qc_plan_lot_dtls
                                		WHERE tqpld_bu = p_bu
                                		AND tqpld_pln_pfx = cr1.tqpln_pln_pfx
                                		AND tqpld_pln_no = cr1.tqpln_pln_no
                                		AND tqpld_seq_no = cr1.tqpln_seq_no
                                		AND ((p_oper = 'P' AND tqpld_temp_qty >0) OR p_oper ='W') 
                                       	      )
                       		LOOP
					 v_sub_seq_no := v_sub_seq_no +1;
				
				--raise_application_error(-20999,cr1.tqpln_seq_no||'-'||v_seq_no);  
					INSERT INTO tqm_lot_nos
					(
						tqml_bu  			,              
						tqml_qc_pfx			,            
						tqml_qc_no 			,            
						tqml_qc_rev			,            
						tqml_qc_doc_seq_no		, 
						tqml_pln_seq_no			,
						tqml_ls_type      		,     
						tqml_lot_no       		,     
						tqml_receipt_qty  		,     
						tqml_accepted_qty 		,     
						tqml_rejected_qty 		,     
						tqml_cre_by       		,     
						tqml_cre_date
					)
					VALUES 
					(
						p_bu				,                
						cr1.tqpln_pln_pfx		,
						cr1.tqpln_pln_no		,
						p_rev				, 
						v_seq_no			,
						cr1.tqpln_seq_no		,
						v_prod_ser_lot_type		,
						rec_lot.tqpld_lot_no		,            
						DECODE(p_oper,'W',(rec_lot.tqpld_lot_qty - rec_lot.tqpld_qc_qty),'P',rec_lot.tqpld_temp_qty),
						DECODE(p_oper,'W',(rec_lot.tqpld_lot_qty - rec_lot.tqpld_qc_qty),'P',rec_lot.tqpld_temp_qty),
						0				,
						p_user            		,
						SYSDATE		
					 );
                         

					UPDATE tqm_qc_plan_lot_dtls 
					SET
						tqpld_temp_qty = 0,
						tqpld_qc_qty = tqpld_qc_qty + 
						DECODE(
								p_oper,'W',(rec_lot.tqpld_lot_qty - rec_lot.tqpld_qc_qty),'P',rec_lot.tqpld_temp_qty
						      ),
						tqpld_upd_by = p_user,
						tqpld_upd_date = sysdate
					WHERE 	tqpld_bu = p_bu
					AND	tqpld_pln_pfx	 = cr1.tqpln_pln_pfx
					AND 	tqpld_pln_no	 = cr1.tqpln_pln_no
					AND 	tqpld_seq_no	 = cr1.tqpln_seq_no
					AND     tqpld_lot_no	 = rec_lot.tqpld_lot_no;                         
                         
                                     
					v_sub_ser_seq_no  := 0;
					IF v_prod_ser_lot_type IN ('O') THEN
					

					FOR rec_serial IN(
						      SELECT *
						      FROM tqm_qc_plan_serial_dtls
						      WHERE tqpsd_bu 	= p_bu
						      AND tqpsd_pln_pfx = cr1.tqpln_pln_pfx
						      AND tqpsd_pln_no 	= cr1.tqpln_pln_no
						      AND tqpsd_seq_no 	= cr1.tqpln_seq_no
						      AND tqpsd_lot_no	= rec_lot.tqpld_lot_no
						      AND ((p_oper = 'P' AND tqpsd_sel_flag = 'Y') OR P_OPER ='W' )
						      AND tqpsd_qc_pfx IS NULL
						      AND tqpsd_qc_no IS NULL
						      AND tqpsd_qc_seq_no IS NULL
						      
						     -- AND tqpsd_qc_rev IS NULL
							     )
					LOOP
					
					 

						INSERT INTO tqm_serial_nos
						(
							tqms_bu   		, 
							tqms_qc_pfx		,            
							tqms_qc_no 		,            
							tqms_qc_rev		,            
							tqms_qc_doc_seq_no	,
							tqms_pln_seq_no		,
							tqms_ls_type      	,     
							tqms_lot_no       	,     
							tqms_serial_no    	,     
							tqms_rej_flag     	,     
							tqms_cre_by       	,     
							tqms_cre_date          
						 )
						 VALUES 
						 (
							p_bu			,
							cr1.tqpln_pln_pfx	,
							cr1.tqpln_pln_no	,
							p_rev			, 
							v_seq_no		,
							cr1.tqpln_seq_no	,
							v_prod_ser_lot_type	,
							rec_serial.tqpsd_lot_no ,
							rec_serial.tqpsd_serial_no,
							'Y'			,
							p_user			,
							SYSDATE
						);

						UPDATE tqm_qc_plan_serial_dtls 
						SET
						tqpsd_qc_pfx	 = cr1.tqpln_pln_pfx,
						tqpsd_qc_no 	 = cr1.tqpln_pln_no,          
						tqpsd_qc_seq_no  = v_sub_seq_no,
						tqpsd_qc_rev     = p_rev,
						tqpsd_upd_by =  p_user,
						tqpsd_upd_date = sysdate
						WHERE 	tqpsd_bu = p_bu
						AND	tqpsd_pln_pfx	 = cr1.tqpln_pln_pfx
						AND 	tqpsd_pln_no	 = cr1.tqpln_pln_no
						AND 	tqpsd_seq_no	 = cr1.tqpln_seq_no
						AND     tqpsd_lot_no	 = rec_serial. tqpsd_lot_no
						AND     tqpsd_serial_no	 = rec_serial.tqpsd_serial_no;
						
					 
						
					
					END LOOP;
					END IF;	
                                     
                                     
                                     
				END LOOP;
			END IF;
	
		       /* insert into serial/lot details based on the product serial lot type*/
	               IF v_prod_ser_lot_type IN ('S') THEN
	                    v_sub_seq_no  := 0;
	 
	                    FOR rec_serial IN(
	                    		      SELECT *
	                                      FROM tqm_qc_plan_serial_dtls
	                                      WHERE tqpsd_bu = p_bu
	                                      AND tqpsd_pln_pfx = cr1.tqpln_pln_pfx
	                                      AND tqpsd_pln_no = cr1.tqpln_pln_no
	                                      AND tqpsd_seq_no = cr1.tqpln_seq_no
	                                      AND ((p_oper = 'P' AND tqpsd_sel_flag = 'Y') OR P_OPER ='W' )
	                                      AND tqpsd_qc_pfx IS NULL
	                                      AND tqpsd_qc_no IS NULL
	                                      AND tqpsd_qc_seq_no IS NULL
	                                     -- AND tqpsd_qc_rev IS NULL
	                                     )
	                    LOOP
	                        v_sub_seq_no := v_sub_seq_no +1;
	                        
				INSERT INTO tqm_serial_nos
				(
					tqms_bu   		,             
					tqms_qc_pfx		,            
					tqms_qc_no 		,            
					tqms_qc_rev		,            
					tqms_qc_doc_seq_no	,
					tqms_pln_seq_no		,
					tqms_ls_type      	,     
					tqms_lot_no       	,     
					tqms_serial_no    	,     
					tqms_rej_flag     	,     
					tqms_cre_by       	,     
					tqms_cre_date          
						                       
				 )
				 VALUES 
				 (
					p_bu			,
					cr1.tqpln_pln_pfx	,
					cr1.tqpln_pln_no	,
					p_rev			, 
					v_seq_no		,
					cr1.tqpln_seq_no	,
					v_prod_ser_lot_type	,
					rec_serial.tqpsd_lot_no	,
					rec_serial.tqpsd_serial_no	,
					'Y'			,
					p_user			,
					SYSDATE
				);
			
				UPDATE tqm_qc_plan_serial_dtls 
				SET
					tqpsd_qc_pfx	 = cr1.tqpln_pln_pfx,
					tqpsd_qc_no 	 = cr1.tqpln_pln_no,          
					tqpsd_qc_seq_no  = v_sub_seq_no,
					tqpsd_qc_rev     = p_rev,
					tqpsd_upd_by =  p_user,
					tqpsd_upd_date = sysdate
				WHERE 	tqpsd_bu = p_bu
	                        AND	tqpsd_pln_pfx	 = cr1.tqpln_pln_pfx
	                        AND 	tqpsd_pln_no	 = cr1.tqpln_pln_no
	                        AND 	tqpsd_seq_no	 = cr1.tqpln_seq_no
	                        AND     tqpsd_serial_no	 = rec_serial.tqpsd_serial_no;
				
				END LOOP;
				
			END IF;
			
		/* update the QC Qty as receipt qty or temp qty according to the document operation(whole or partial)
		   and update the temp qty as 0 after QC qty updated */	
				UPDATE tqm_qc_plan_ln
				SET 	tqpln_qc_qty = tqpln_qc_qty + 
					DECODE
					(
						p_oper,'W',(cr1.tqpln_receipt_qty - cr1.tqpln_qc_qty),'P',cr1.tqpln_temp_qty
					),
					tqpln_status = DECODE(p_oper,'W','C',
							      'P',DECODE
								  (
									SIGN(
										(tqpln_qc_qty - (cr1.tqpln_receipt_qty - cr1.tqpln_temp_qty))
									    ),0,'C','P'
								   )
							     ),
					tqpln_temp_qty=0,
					tqpln_upd_by = p_user,
					tqpln_upd_date = sysdate
				WHERE 	tqpln_bu	= p_bu
				AND	tqpln_pln_pfx	= cr1.tqpln_pln_pfx 
				AND	tqpln_pln_no 	= cr1.tqpln_pln_no
				AND     tqpln_seq_no	= cr1.tqpln_seq_no; 			
		END LOOP;
		
	  
				SELECT COUNT(*)
				INTO	 v_count_hd
				FROM 	tqm_qc_plan_ln
				WHERE	tqpln_bu = p_bu
				AND 	tqpln_pln_pfx = p_pln_pfx
				AND	tqpln_pln_no = p_pln_no 
				AND	(tqpln_qc_qty - tqpln_receipt_qty) < 0  
				AND	tqpln_status NOT IN ('L','C');



				UPDATE tqm_qc_plan_hd
				SET 	tqphd_status = DECODE(SIGN(v_count_hd),0,'C','P'),
					tqphd_upd_by  =   p_user,
					tqphd_upd_date = SYSDATE
				WHERE 	tqphd_bu  =  p_bu   
				AND	tqphd_pln_pfx  = p_pln_pfx
				AND	tqphd_pln_no  = p_pln_no;    

				 
				 
		
	
	
	
				/* update the the rev to perform the partial issue */	

				UPDATE tqm_qc_plan_hd
				SET 	tqphd_upd_rev =	p_rev +1       ,
					tqphd_upd_by = p_user,
					tqphd_upd_date = sysdate
				WHERE 	tqphd_bu	= p_bu
				AND	tqphd_pln_pfx	= p_pln_pfx 
				AND	tqphd_pln_no 	= p_pln_no; 	
				  	 	    	 	    
         	
COMMIT;
    p_res := 'Y';  
   
     
END;
/

SHOW ERR;
