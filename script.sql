DROP PROCEDURE IF EXISTS whmcs.sync_services_config_options;

DELIMITER $$
$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `whmcs`.`sync_services_config_options`(IN product_id INT,IN service_id INT,IN just_report TINYINT)
BEGIN
###################################### CREATE VIEW BASED ON PRODUCT CONFIG OPTIONS ######################################################## 
	
	  DROP VIEW IF EXISTS products_config_options;
      CREATE VIEW products_config_options
      AS 
      (
		SELECT
			p.id as pr_id,
			p_c_o.gid as pr_config_group_id,
			p_c_o.id as pr_config_id,
			p_c_o.optionname as pr_config,
			p_c_o_s.id as pr_option_id,
			p_c_o_s.optionname as pr_option
		FROM tblproducts p
		INNER JOIN tblproductconfiglinks p_c_l ON p.id = p_c_l.pid
		INNER JOIN tblproductconfiggroups p_c_g ON p_c_g.id = p_c_l.gid
		INNER JOIN tblproductconfigoptions p_c_o ON p_c_o.gid = p_c_g.id
		INNER JOIN tblproductconfigoptionssub p_c_o_s ON p_c_o_s.configid = p_c_o.id 
      );
  
###################################### CREATE VIEW BASED ON SERVICE CONFIG OPTIONS ########################################################
     
      DROP VIEW IF EXISTS service_config_options;
      CREATE VIEW service_config_options
      AS 
       ( 
		SELECT 
			s.id as srv_id,
			s.packageid as srv_pr_id,
			s_c_o.id as srv_config_option_id,
			p_c_o.gid as srv_config_group_id,
			p_c_o.id as srv_config_id,
			p_c_o.optionname as srv_config,
			p_c_o_s.id as srv_option_id,
			p_c_o_s.optionname as srv_option
		FROM tblhosting s 
		INNER JOIN tblhostingconfigoptions s_c_o ON s.id = s_c_o.relid 
		INNER JOIN tblproductconfigoptionssub p_c_o_s ON p_c_o_s.id = s_c_o.optionid 
		INNER JOIN tblproductconfigoptions p_c_o ON p_c_o.id = s_c_o.configid 
       );
      
      
      
###################################### THE REPORT SHOWS ALL SERVICE CONFIG OPTIONS THAT WILL BE UPDATED #################################
      
      IF service_id = 0 AND just_report = 1
      	THEN
			 SELECT * FROM  tblhostingconfigoptions as t
			 INNER JOIN (
				     SELECT * FROM products_config_options p
				     INNER JOIN service_config_options s ON s.srv_option  = p.pr_option AND s.srv_config = p.pr_config  
				     WHERE pr_id = product_id AND srv_pr_id = product_id 
				     ORDER BY srv_id 
		      ) product_service_config ON product_service_config.srv_config_option_id = t.id;
	  ELSEIF service_id <> 0 AND just_report = 1 
  		THEN
			 SELECT * FROM tblhostingconfigoptions as t
			 INNER JOIN (
			     SELECT * FROM products_config_options p
			     INNER JOIN service_config_options s ON s.srv_option  = p.pr_option AND s.srv_config = p.pr_config  
			     WHERE pr_id = product_id AND srv_pr_id = product_id AND s.srv_id = service_id
			 ) product_service_config ON product_service_config.srv_config_option_id = t.id;
  	  END IF;
      
    
###################################### UPDATE SERVICE CONFIG OPTIONS ####################################################################
  	 
      IF service_id = 0 AND just_report = 0 
  		THEN  
			 UPDATE tblhostingconfigoptions as t
			 INNER JOIN (
			     SELECT * FROM products_config_options p
			     INNER JOIN service_config_options s ON s.srv_option  = p.pr_option AND s.srv_config = p.pr_config  
			     WHERE pr_id = product_id AND srv_pr_id = product_id 
			     ORDER BY srv_id 
			 ) product_service_config ON product_service_config.srv_config_option_id = t.id
			 SET t.optionid = product_service_config.pr_option_id, 
			     t.configid = product_service_config.pr_config_id;
	  ELSEIF service_id <> 0 AND just_report = 0 
  		THEN 
			 UPDATE tblhostingconfigoptions as t
			 INNER JOIN (
			     SELECT * FROM products_config_options p
			     INNER JOIN service_config_options s ON s.srv_option  = p.pr_option AND s.srv_config = p.pr_config  
			     WHERE pr_id = product_id AND srv_pr_id = product_id AND s.srv_id = service_id
			 ) product_service_config ON product_service_config.srv_config_option_id = t.id
			 SET t.optionid = product_service_config.pr_option_id, 
			     t.configid = product_service_config.pr_config_id;
	  END IF;
    
      
 
     
###################################### DROP ALL VIEWS #############################################################
	 
 	DROP VIEW IF EXISTS products_config_options;
    DROP VIEW IF EXISTS service_config_options;
END$$
DELIMITER ;

