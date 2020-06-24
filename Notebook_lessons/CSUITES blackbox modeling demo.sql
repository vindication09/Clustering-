---Data Prep for Modeling and Deployment Demo 

---Labels- C-Suites and Non-CSuites (1 or 0 binary)
---Features- behaviors such as Adcode, topics, and section front 

---Data: month of May ( build model on train, see performance on test, deploy on validation)


---Our data should contain label followed by n feature columns 
---its best practice to either keep your label column at the front or back of the dataframe
---this will make subsetting much easier 


############### STEP 1: Gather Data 

---target_variable_csuites_aprmay
select 
user_id,
attribute,
value,
case when value in ('Csuite', 'Board and Ownership') then 1
when value in ('Management', 'Non-management') then 0 end as target

from 

(
#########################Inner query to grab target mutually exclusive values 
select 
user_id, 
'Seniority' as attribute, 
value 
from 
(

select 
a.user_id as user_id, 
a.seniority as value 

from 
	(SELECT 
	bloomberg_id as user_id, 
	seniority
 	FROM <BMB_TABLE> 
 	WHERE _PARTITIONTIME >= "2020-04-01 00:00:00" AND _PARTITIONTIME < "2020-06-01 00:00:00" 
 	and seniority is not null 
	group by 1, 2) a 

join 

	(select 
	user_id, count(seniority)
		from 
			(SELECT 
			bloomberg_id as user_id, 
			seniority
 			FROM <BMB_TABLE>  
 			WHERE _PARTITIONTIME >= "2020-04-01 00:00:00" AND _PARTITIONTIME < "2020-06-01 00:00:00" 
 			and seniority is not null
 			group by 1, 2)
			group by user_id
	having count(seniority)=1 ) b #change where clause )

on (a.user_id=b.user_id) 

)
######################### End inner query 

)

group by 1, 2, 3, 4




#################### STEP 2: Gather Features 


---feature_variable_csuites
---grab features from Pat's modeling data


----we will need to grab data points from a pre-prepared table
---the data is prepared such that each user has at least two pvs 
---media-data-science:modeling_data.firstpartyunivariates2020may

---aprmay_csuites_modelingdata
select
target, 
value 
from 
(
	select
	a.target as target, 
	b.value as value
	from <target_variable_csuites_aprmay> a 

	join 

		(
			SELECT 
			userid as userid,
			value as value 
			FROM <UNIVARIATE_1STpARTY__TABLE>  
			where attribute in (
			'Content Type Raw',
			'Brand Raw',
			'BBG Topic',
			'Adcode')
			and value is not null 
			and length(value)>0
			group by 1, 2

			union all 

			SELECT 
			userid as userid,
			value as value 
			FROM <UNIVARIATE_1STpARTY__TABLE> 
			where attribute in (
			'Content Type Raw',
			'Brand Raw',
			'BBG Topic',
			'Adcode')
			and value is not null 
			and length(value)>0
			group by 1, 2

		) b
		on (a.user_id=b.userid)
)
group by 1, 2


---
