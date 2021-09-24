
-- Cleanup Deletion of Variable Setup
delete from CAR_VARIABLE_CONFIG where var_group = 'PURBEH_MH';
delete from CAR_VARIABLE_TEMPLATE where var_group = 'PURBEH_MH';

-- Update Data Range of Variable Group e.g. PURBEH_MH
-- See the current setup
-- Note that Start and End dates are automaticaaly updated every execution based on "DATA_RANGE_MONTHS" config
-- End Date will be today minus 2 days, POS Data is delayed by more than 1 day
select * from CAR_DATE_REF;

update CAR_DATE_REF set data_range_months = 12 where var_group = 'PURBEH_MH';

-- Check Config setup
select *
from CAR_CONFIG_TBL
where var_group_name = 'PURBEH_MH'
order by 2
;

--******************************************************************************
-- No Need to run this not unless there are changes in source table
--******************************************************************************
insert into CAR_CONFIG_TBL values ('PURBEH_MH', 'SOURCE TABLE', 'TEMP_PURBEH_MH_TXN', '1', '
select
    ~CR~ PROGRAM,
    V_LU_TA_PC.TA_PRODUCT_CATEGORY PRODID,
    V_LU_PRODUCTCATEGORY.PRODCODE,
    V_LU_UNIT.AIRLANDCD AIRLANDCD,
    V_LU_CARD_NOPI.CUSTOMERID CUSTOMERID,
    V_LU_OUTLET.TAID,
    V_LU_DATE.DATE TXNDATE,
    V_FT_CRTRANSACTION.TRANSACTIONDATEKEY TXNDATEKEY,
    cast(V_FT_CRTRANSACTION.TRANSACTIONAUTOID as VARCHAR(255)) TRANSACTIONID,
    V_FT_CRTRANSACTION.AMOUNTSPEND SPEND,
    V_LU_PRODUCTCATEGORY.PRODNM PRODNM,
	V_LU_DATE.ISWEEKEND
from
    DWCDI.ADMIN.V_FT_CRTRANSACTION V_FT_CRTRANSACTION
    join DWCDI.ADMIN.V_LU_CARD_NOPI V_LU_CARD_NOPI on (V_FT_CRTRANSACTION.CARDAUTOID = V_LU_CARD_NOPI.CARDAUTOID)
    join DWCDI.ADMIN.V_LU_DATE V_LU_DATE on (V_FT_CRTRANSACTION.TRANSACTIONDATEKEY = V_LU_DATE.DATEKEY)
    join DWCDI.ADMIN.V_LU_CROUTLET V_LU_CROUTLET on (V_FT_CRTRANSACTION.CROUTLETCD = V_LU_CROUTLET.CROUTLETCD)
    left join DWCDI.ADMIN.V_LU_OUTLET V_LU_OUTLET on (V_LU_CROUTLET.OUTLETID = V_LU_OUTLET.OUTLETID)
    left join DWCDI.ADMIN.V_LU_TA_PC V_LU_TA_PC on (V_LU_OUTLET.TAID = V_LU_TA_PC.TAID)
    left join DWCDI.ADMIN.V_LU_UNIT V_LU_UNIT on (V_LU_OUTLET.UNITID = V_LU_UNIT.UNITID)
    left join DWCDI.ADMIN.V_LU_PRODUCTCATEGORY V_LU_PRODUCTCATEGORY on (V_LU_OUTLET.PRODID = V_LU_PRODUCTCATEGORY.PRODID)
where
    V_FT_CRTRANSACTION.CROUTLETCD not in (~ISC~)
    and V_FT_CRTRANSACTION.TRANSACTIONMODE in (~1~, ~16~, ~17~)
    and V_LU_DATE.DATE between ~#startdt#~ and ~#enddt#~

UNION

select
    ~ISC~ PROGRAM,
    V_LU_TA_PC.TA_PRODUCT_CATEGORY PRODID,
    V_LU_PRODUCTCATEGORY.PRODCODE,
    ~I~ AIRLANDCD,
    V_FT_ISCHEADER_NOPI.CUSTOMERID CUSTOMERID,
    V_LU_OUTLET.TAID,
    V_LU_DATE.DATE TXNDATE,
    string_to_int(to_char(V_FT_ISCHEADER_NOPI.FLIGHTDTTM, ~YYYYMMDD~), ~10~) TXNDATEKEY,
    V_FT_ISCHEADER_NOPI.SALESORDERNO TRANSACTIONID,
    V_FT_ISCDETAILS.GROSSAMT SPEND,
    V_LU_PRODUCTCATEGORY.PRODNM PRODNM,
	V_LU_DATE.ISWEEKEND
from
    DWCDI.ADMIN.V_FT_ISCDETAILS V_FT_ISCDETAILS
    join DWCDI.ADMIN.V_FT_ISCHEADER_NOPI V_FT_ISCHEADER_NOPI on (V_FT_ISCDETAILS.ORDERID = V_FT_ISCHEADER_NOPI.ORDERID)
    join DWCDI.ADMIN.V_LU_ISCORDERSTATUS V_LU_ISCORDERSTATUS on (V_FT_ISCHEADER_NOPI.SALESORDERNO = V_LU_ISCORDERSTATUS.SALESORDERNO)
    join DWCDI.ADMIN.V_LU_DATE V_LU_DATE on (
        to_char(V_FT_ISCHEADER_NOPI.FLIGHTDTTM, ~yyyymmdd~) = V_LU_DATE.DATEKEY
    )
    left join DWCDI.ADMIN.V_LU_OUTLET V_LU_OUTLET on (V_FT_ISCDETAILS.OUTLETID = V_LU_OUTLET.OUTLETID)
    left join DWCDI.ADMIN.V_LU_TA_PC V_LU_TA_PC on (V_LU_OUTLET.TAID = V_LU_TA_PC.TAID)
    left join DWCDI.ADMIN.V_LU_UNIT V_LU_UNIT on (V_LU_OUTLET.UNITID = V_LU_UNIT.UNITID)
    left join DWCDI.ADMIN.V_LU_PRODUCTCATEGORY V_LU_PRODUCTCATEGORY on (V_LU_OUTLET.PRODID = V_LU_PRODUCTCATEGORY.PRODID)
where
    upper(V_LU_ISCORDERSTATUS.ORDERSTATUS) not in (~CANCELLED~)
    and V_LU_DATE.DATE between  ~#startdt#~ and ~#enddt#~'
);

--******************************************************************************
-- No Need to run this not unless there are changes in source table
--******************************************************************************
insert into CAR_CONFIG_TBL values ('PURBEH_MH', 'TABLE JOINS', 'MAIN', '2', '
from TEMP_PURBEH_MH_TXN pa11
where pa11.TXNDATE between ~#startdt#~ and ~#enddt#~
group by pa11.CUSTOMERID'
);


--******************************************************************************
-- Changes in Variables below (INSERTS should come from Excel Template)
--******************************************************************************

select distinct * from CAR_VARIABLE_CONFIG where var_group = 'PURBEH_MH' order by 2, 3;

insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','CUSTOMERID','0','','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DAYSFIRSTTRAN','10','','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DAYSFIRSTTRAN_A','11','','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DAYSFIRSTTRAN_L','11','','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DAYSFIRSTTRAN_I','11','','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DAYSFIRSTTRAN_J','11','','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DAYSLASTTRAN','20','','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DAYSLASTTRAN_A','21','','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DAYSLASTTRAN_L','21','','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DAYSLASTTRAN_J','21','','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DAYSLASTTRAN_I','21','','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_PURCHASEGAP','30','','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_PURCHASEGAP_A','31','','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_PURCHASEGAP_L','31','','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_PURCHASEGAP_J','31','','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_PURCHASEGAP_I','31','','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_ATV_VISIT','40','','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_ATV_VISIT_1M','41','1','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_ATV_VISIT_3M','41','3','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_ATV_VISIT_6M','41','6','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_ATV_VISIT_12M','41','12','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DISTINCTPRODCAT','50','','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DISTINCTPRODCAT_1M','51','1','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DISTINCTPRODCAT_3M','51','3','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DISTINCTPRODCAT_6M','51','6','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_DISTINCTPRODCAT_12M','51','12','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN','60','','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_1M','61','1','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_3M','61','3','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_6M','61','6','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_12M','61','12','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_A','62','','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_L','62','','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_J','62','','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_I','62','','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_1M_A','63','1','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_3M_A','63','3','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_6M_A','63','6','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_12M_A','63','12','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_1M_L','63','1','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_3M_L','63','3','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_6M_L','63','6','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_12M_L','63','12','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_1M_J','63','1','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_3M_J','63','3','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_6M_J','63','6','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_12M_J','63','12','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_1M_I','63','1','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_3M_I','63','3','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_6M_I','63','6','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_TRAN_12M_I','63','12','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND','70','','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_1M','71','1','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_3M','71','3','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_6M','71','6','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_12M','71','12','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_A','72','','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_L','72','','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_J','72','','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_I','72','','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_1M_A','73','1','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_3M_A','73','3','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_6M_A','73','6','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_12M_A','73','12','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_1M_L','73','1','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_3M_L','73','3','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_6M_L','73','6','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_12M_L','73','12','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_1M_J','73','1','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_3M_J','73','3','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_6M_J','73','6','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_12M_J','73','12','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_1M_I','73','1','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_3M_I','73','3','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_6M_I','73','6','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_SPEND_12M_I','73','12','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS','80','','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_1M','81','1','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_3M','81','3','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_6M','81','6','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_12M','81','12','','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_A','82','','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_L','82','','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_J','82','','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_I','82','','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_1M_A','83','1','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_3M_A','83','3','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_6M_A','83','6','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_12M_A','83','12','A','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_1M_L','83','1','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_3M_L','83','3','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_6M_L','83','6','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_12M_L','83','12','L','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_1M_J','83','1','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_3M_J','83','3','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_6M_J','83','6','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_12M_J','83','12','J','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_1M_I','83','1','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_3M_I','83','3','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_6M_I','83','6','I','');
insert into CAR_VARIABLE_CONFIG values ('PURBEH_MH','PURBEH_VISITS_12M_I','83','12','I','');


select distinct * from CAR_VARIABLE_TEMPLATE where var_group = 'PURBEH_MH' order by 2,3;

insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','0','CUSTOMERID','CUSTOMERID');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','10','PURBEH_DAYSFIRSTTRAN','date_part(~day~, datetime(''#enddt#'') - min(nvl((pa11.TXNDATE), ~1900-01-01 00:00:00~)))');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','11','PURBEH_DAYSFIRSTTRAN_LOC','case 
    when (date_part(~day~, datetime(''#enddt#'') - min(nvl(
        case
            when pa11.AIRLANDCD =''#loc#'' then pa11.TXNDATE 
        end, 
        ~1900-01-01 00:00:00~)))) > 30000 then 999999
    else (date_part(~day~, datetime(''#enddt#'') - min(nvl(
        case
            when pa11.AIRLANDCD = ''#loc#'' then pa11.TXNDATE 
        end, 
        ~1900-01-01 00:00:00~))))
end');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','20','PURBEH_DAYSLASTTRAN','date_part(~day~, datetime(''#enddt#'') - max(nvl(pa11.TXNDATE, ~1900-01-01 00:00:00~)))');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','21','PURBEH_DAYSLASTTRAN_LOC','case 
    when (date_part(~day~, datetime(''#enddt#'') - max(nvl(
        case
            when pa11.AIRLANDCD =''#loc#'' then pa11.TXNDATE 
        end, 
        ~1900-01-01 00:00:00~)))) > 30000 then 999999
    else (date_part(~day~, datetime(''#enddt#'') - max(nvl(
        case
            when pa11.AIRLANDCD = ''#loc#'' then pa11.TXNDATE 
        end, 
        ~1900-01-01 00:00:00~))))
end');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','30','PURBEH_PURCHASEGAP','case 
    when max(nvl(pa11.TXNDATE, ~1900-01-01 00:00:00~)) = min(nvl(pa11.TXNDATE, ~1900-01-01 00:00:00~)) then 0
    when count(distinct pa11.TXNDATEKEY) <= 1 then 0
    else (max(nvl(pa11.TXNDATE, ~1900-01-01 00:00:00~)) - min(nvl(pa11.TXNDATE, ~9999-01-01 00:00:00~))) / (count(distinct pa11.TXNDATEKEY) - 1)
end');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','31','PURBEH_PURCHASEGAP_LOC','case
    when max(nvl(
        case
            when pa11.AIRLANDCD = ''#loc#'' then pa11.TXNDATE
        end, 
        ~1900-01-01 00:00:00~)) = min(nvl(
        case
            when pa11.AIRLANDCD = ''#loc#'' then pa11.TXNDATE
        end, 
       ~1900-01-01 00:00:00~)) then 0
    when count(distinct 
        case
            when pa11.AIRLANDCD = ''#loc#'' then pa11.TXNDATEKEY
        end) <= 1 then 0
    else (max(nvl(
        case
            when pa11.AIRLANDCD = ''#loc#'' then pa11.TXNDATE
        end, 
        ~1900-01-01 00:00:00~)) - min(nvl(
        case
            when pa11.AIRLANDCD = ''#loc#'' then pa11.TXNDATE
        end, 
        ~9999-01-01 00:00:00~))) / (count(distinct 
        case
            when pa11.AIRLANDCD = ''#loc#'' then pa11.TXNDATEKEY
        end) -1)
end');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','40','PURBEH_ATV_VISIT','sum(pa11.SPEND) / count(distinct pa11.TXNDATE)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','41','PURBEH_ATV_VISIT_XMONTH','sum(
    case
        when pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'' then pa11.SPEND
    end) / count(distinct
    case
        when pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'' then pa11.TXNDATE
    end)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','50','PURBEH_DISTINCTPRODCAT','count(distinct pa11.PRODNM)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','51','PURBEH_DISTINCTPRODCAT_XMONTH','count(distinct
    case
        when pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'' then pa11.PRODNM
    end)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','60','PURBEH_TRAN','count(distinct pa11.TRANSACTIONID)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','61','PURBEH_TRAN_XMONTH','count(distinct
    case
        when pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'' then pa11.TRANSACTIONID
    end)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','62','PURBEH_TRAN_LOC','count(distinct
    case
        when pa11.AIRLANDCD = ''#loc#'' then pa11.TRANSACTIONID
    end)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','63','PURBEH_TRAN_XMONTH_LOC','count(distinct
    case
        when (pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'') and (pa11.AIRLANDCD = ''#loc#'')
            then pa11.TRANSACTIONID
    end)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','70','PURBEH_SPEND','sum(pa11.SPEND)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','71','PURBEH_SPEND_XMONTH','sum(
    case
        when pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'' then pa11.SPEND
        else 0
    end)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','72','PURBEH_SPEND_LOC','sum(
    case
         when pa11.AIRLANDCD = ''#loc#'' then pa11.SPEND
         else 0
    end)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','73','PURBEH_SPEND_XMONTH_LOC','sum(
    case
        when (pa11.AIRLANDCD = ''#loc#'') and (pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'') then pa11.SPEND
        else 0
    end)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','80','PURBEH_VISITS','count(distinct pa11.TXNDATE)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','81','PURBEH_VISITS_XMONTH','count(distinct
    case
        when pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'' then pa11.TXNDATE
    end)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','82','PURBEH_VISITS_LOC','count(distinct
    case
        when pa11.AIRLANDCD = ''#loc#'' then pa11.TXNDATE
    end)');
insert into CAR_VARIABLE_TEMPLATE values ('PURBEH_MH','83','PURBEH_VISITS_XMONTH_LOC','count(distinct
    case
        when (pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'') and (pa11.AIRLANDCD = ''#loc#'')
            then pa11.TXNDATE
    end)');








-------------------------------------------------
--  START HERE 
-------------------------------------------------

-- Execute PURBEH_MH_TEMP table generation
call SP_GENERATE_CAR('PURBEH_MH');

-- Transaction Source Table
select * from TEMP_PURBEH_MH_TXN;

-- PURBEH_MH Final table
select * from PURBEH_MH_TEMP;

-- Value in PARAM_VAL contains the generated SQL
select * from CAR_CONFIG_TBL where var_group_name = 'PURBEH_MH' and var_group_node_type = 'DYNAMIC SQL' order by 4 desc;

