select
    V_LU_CUSTOMER_NOPI.CUSTOMERID as CUSTOMERID,
    date_part('year', age( '2021-08-22', V_LU_CUSTOMER_NOPI.DATEOFBIRTH)) as DEMO_AGE,
    date_part('month', V_LU_CUSTOMER_NOPI.DATEOFBIRTH) as DEMO_DOB_MONTH,
    V_LU_CUSTOMER_NOPI.GENDERCD as DEMO_GENDER,
	case
		when (V_LU_CUSTOMER_NOPI.WORKINGINCHANGIFLAG is null) then 0
		when (V_LU_CUSTOMER_NOPI.WORKINGINCHANGIFLAG = 'N') then 0
		else 1
	end as DEMO_AIRPORTSTAFFFLAG,
	case
		when (V_LU_CUSTOMER_NOPI.CAGSTAFFFLAG is null) then 0
		when (V_LU_CUSTOMER_NOPI.CAGSTAFFFLAG = 'N') then 0
		else 1
	end as DEMO_CAGSTAFFFLAG,
    case
        when V_LU_MEMBER_NOPI.ISONATIONALITYCD in ('ZZW', 'ZZX', 'ZZY') then 1
        else 0 
    end as DEMO_POSSTAFFFLAG,
    V_LU_CUSTOMER_NOPI.NATIONALITYCD as DEMO_NATIONALITY,
    V_LU_CUSTOMER_NOPI.COUNTRYCD as DEMO_COUNTRYOFRESIDENCE,
    V_LU_CRMEMBER_NOPI.POSTALREGION as DEMO_CRPOSTALREGION,
	V_LU_CUSTOMER_NOPI.SOURCESYSTEMCODELIST SOURCESYSTEMCODELIST, -- To compute DEMO_COUNTPROGRAM, DEMO_CRFLAG, DEMO_ISC_FLAG, DEMO_OCIDFLAG
    array_split(V_LU_CUSTOMER_NOPI.SOURCESYSTEMCODELIST, ',') as DEMO_COUNTPROGRAM,
    case 
        when V_LU_CUSTOMER_NOPI.SOURCESYSTEMCODELIST like '%CR%' then 1 
        else 0 
    end as DEMO_CRFLAG,
    case 
        when V_LU_CUSTOMER_NOPI.SOURCESYSTEMCODELIST like '%ISC%' then 1 
        else 0 
    end as DEMO_ISC_FLAG,
    case 
        when V_LU_CUSTOMER_NOPI.SOURCESYSTEMCODELIST like '%OCID%' then 1 
        else 0 
    end as DEMO_OCIDFLAG,
	case
    	when V_LU_CUSTOMER_NOPI.OPTINCONSOLIDATEDFLAG = 'Y' then 1
		else 0
	end as DEMO_OPTINCONSOLIDATEDFLAG,
	case
    	when V_LU_CRMEMBER_NOPI.OPTIN = 'Y' then 1
		else 0
	end as DEMO_CROPTINFLAG,
	case
    	when V_LU_MEMBER_NOPI.OPTINFLAG = 'Y' then 1
		else 0
	end as DEMO_ISCOPTINFLAG,
    -- DEMO_OCIDOPTINFLAG missing
	case
	    when V_LU_CUSTOMER_NOPI.NOTIFYSMSFLAG = 'Y' then 1
		else 0
	end as DEMO_NOTIFYSMSFLAG,
	case
		when min(nvl(months_between('2021-08-22', V_LU_CRMEMBER_NOPI.JOINDATETIME), 999999), 
		nvl(months_between('2021-08-22', V_LU_MEMBER_NOPI.JOINDATE), 999999)) < 999999 
		    then min(nvl(months_between('2021-08-22', V_LU_CRMEMBER_NOPI.JOINDATETIME), 999999), 
			nvl(months_between('2021-08-22', V_LU_MEMBER_NOPI.JOINDATE), 999999)) 
		else null
	end as DEMO_MEMBERTENUREMTH,
	months_between('2021-08-22', V_LU_CRMEMBER_NOPI.JOINDATETIME) as DEMO_CRMEMBERTENUREMTH,
	months_between('2021-08-22', V_LU_MEMBER_NOPI.JOINDATE) as DEMO_ISCMEMBERTENUREMTH,
    min(nvl(V_LU_CRMEMBER_NOPI.JOINDATETIME, '9999-01-01'), nvl(V_LU_MEMBER_NOPI.JOINDATE, '9999-01-01')) as DEMO_MEMBERJOINDATE,
    V_LU_CRMEMBER_NOPI.JOINDATETIME as DEMO_CR_MEMBERJOINDATE,
    V_LU_MEMBER_NOPI.JOINDATE as DEMO_ISC_MEMBERJOINDATE
from
    DWCDI.ADMIN.V_LU_CUSTOMER_NOPI V_LU_CUSTOMER_NOPI
    left join DWCDI.ADMIN.V_LU_CRMEMBER_NOPI V_LU_CRMEMBER_NOPI on (V_LU_CUSTOMER_NOPI.CUSTOMERID = V_LU_CRMEMBER_NOPI.CUSTOMERID)
    left join DWCDI.ADMIN.V_LU_MEMBER_NOPI V_LU_MEMBER_NOPI on (V_LU_CUSTOMER_NOPI.CUSTOMERID = V_LU_MEMBER_NOPI.CUSTOMERID)
