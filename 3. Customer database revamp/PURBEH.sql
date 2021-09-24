--**********************
-- DATA EXTRACTION TABLE
--**********************

drop table temp_txn_MH if exists;

create table temp_txn as (
    select
        'CR' PROGRAM,
        a19.TA_PRODUCT_CATEGORY PRODID,
        a21.PRODCODE,
        a20.AIRLANDCD AIRLANDCD,
        a13.CUSTOMERID CUSTOMERID,
        a18.TAID,
        a16.DATE TXNDATE,
        a11.TRANSACTIONDATEKEY TXNDATEKEY,
        cast(a11.TRANSACTIONAUTOID as VARCHAR(255)) TRANSACTIONID,
        a11.AMOUNTSPEND SPEND,
        a21.PRODNM PRODNM

    from
        DWCDI.ADMIN.V_FT_CRTRANSACTION a11
        join DWCDI.ADMIN.V_LU_CARD_NOPI a13 on (a11.CARDAUTOID = a13.CARDAUTOID)
        join DWCDI.ADMIN.V_LU_DATE a16 on (a11.TRANSACTIONDATEKEY = a16.DATEKEY)
        join DWCDI.ADMIN.V_LU_CROUTLET a17 on (a11.CROUTLETCD = a17.CROUTLETCD)
        left join DWCDI.ADMIN.V_LU_OUTLET a18 on (a17.OUTLETID = a18.OUTLETID)
        left join DWCDI.ADMIN.V_LU_TA_PC a19 on (a18.TAID = a19.TAID)
        left join DWCDI.ADMIN.V_LU_UNIT a20 on (a18.UNITID = a20.UNITID)
        left join DWCDI.ADMIN.V_LU_PRODUCTCATEGORY a21 on (a18.PRODID = a21.PRODID)
    where
        a11.CROUTLETCD not in ('ISC')
        and a11.TRANSACTIONMODE in ('1', '16', '17')
        --and a16.DATE between '2021-05-01' and '2021-05-03'

    UNION

    select
        'ISC' PROGRAM,
        b17.TA_PRODUCT_CATEGORY PRODID,
        b21.PRODCODE,
        'I' AIRLANDCD,
        b12.CUSTOMERID CUSTOMERID,
        b16.TAID,
        b15.DATE TXNDATE,
        string_to_int(to_char(b12.FLIGHTDTTM, 'YYYYMMDD'), '10') TXNDATEKEY,
        b12.SALESORDERNO TRANSACTIONID,
        b11.GROSSAMT SPEND,
        b21.PRODNM PRODNM
    from
        DWCDI.ADMIN.V_FT_ISCDETAILS b11
        join DWCDI.ADMIN.V_FT_ISCHEADER_NOPI b12 on (b11.ORDERID = b12.ORDERID)
        join DWCDI.ADMIN.V_LU_ISCORDERSTATUS b13 on (b12.SALESORDERNO = b13.SALESORDERNO)
        join DWCDI.ADMIN.V_LU_DATE b15 on (
            to_char(b12.FLIGHTDTTM, 'yyyymmdd') = b15.DATEKEY
        )
        left join DWCDI.ADMIN.V_LU_OUTLET b16 on (b11.OUTLETID = b16.OUTLETID)
        left join DWCDI.ADMIN.V_LU_TA_PC b17 on (b16.TAID = b17.TAID)
        left join DWCDI.ADMIN.V_LU_UNIT b18 on (b16.UNITID = b18.UNITID)
        left join DWCDI.ADMIN.V_LU_PRODUCTCATEGORY b21 on (b16.PRODID = b21.PRODID)
    where
        upper(b13.ORDERSTATUS) not in ('CANCELLED')
        --and b15.DATE between '2021-05-01' and '2021-05-03'
)

;

--******************
-- AGGREGATION TABLE
--******************

select
	pa11.CUSTOMERID as CUSTOMERID
date_part(~day~, datetime(''#enddt#'') - min(nvl((pa11.TXNDATE), ~1900-01-01 00:00:00~))) as PURBEH_DAYSFIRSTTRAN
case 
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
end as PURBEH_DAYSFIRSTTRAN_LOC
date_part(~day~, datetime(''#enddt#'') - max(nvl(pa11.TXNDATE, ~1900-01-01 00:00:00~))) as PURBEH_DAYSLASTTRAN
case 
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
end as PURBEH_DAYSLASTTRAN_LOC
case 
    when max(nvl(pa11.TXNDATE, ~1900-01-01 00:00:00~)) = min(nvl(pa11.TXNDATE, ~1900-01-01 00:00:00~)) then 0
    when count(distinct pa11.TXNDATEKEY) <= 1 then 0
    else (max(nvl(pa11.TXNDATE, ~1900-01-01 00:00:00~)) - min(nvl(pa11.TXNDATE, ~9999-01-01 00:00:00~))) / (count(distinct pa11.TXNDATEKEY) - 1)
end as PURBEH_PURCHASEGAP
case
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
end as PURBEH_PURCHASEGAP_LOC
sum(pa11.SPEND) / count(distinct pa11.TXNDATE) as PURBEH_ATV_VISIT
sum(
    case
        when pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'' then pa11.SPEND
    end) / count(distinct
    case
        when pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'' then pa11.TXNDATE
    end) as PURBEH_ATV_VISIT_XMONTH
count(distinct pa11.PRODNM) as PURBEH_DISTINCTPRODCAT
count(distinct
    case
        when pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'' then pa11.PRODNM
    end) as PURBEH_DISTINCTPRODCAT_XMONTH
count(distinct pa11.TRANSACTIONID) as PURBEH_TRAN
count(distinct
    case
        when pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'' then pa11.TRANSACTIONID
    end) as PURBEH_TRAN_XMONTH
count(distinct
    case
        when pa11.AIRLANDCD = ''#loc#'' then pa11.TRANSACTIONID
    end) as PURBEH_TRAN_LOC
count(distinct
    case
        when (pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'') and (pa11.AIRLANDCD = ''#loc#'')
            then pa11.TRANSACTIONID
    end) as PURBEH_TRAN_XMONTH_LOC
sum(pa11.SPEND) as PURBEH_SPEND
sum(
    case
        when pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'' then pa11.SPEND
        else 0
    end) as PURBEH_SPEND_XMONTH
sum(
    case
         when pa11.AIRLANDCD = ''#loc#'' then pa11.SPEND
         else 0
    end) as PURBEH_SPEND_LOC
sum(
    case
        when (pa11.AIRLANDCD = ''#loc#'') and (pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'') then pa11.SPEND
        else 0
    end) as PURBEH_SPEND_XMONTH_LOC
count(distinct pa11.TXNDATE) as PURBEH_VISITS
count(distinct
    case
        when pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'' then pa11.TXNDATE
    end) as PURBEH_VISITS_XMONTH
count(distinct
    case
        when pa11.AIRLANDCD = ''#loc#'' then pa11.TXNDATE
    end) as PURBEH_VISITS_LOC
count(distinct
    case
        when (pa11.TXNDATE between add_months(''#enddt#'', -#period#) and ''#enddt#'') and (pa11.AIRLANDCD = ''#loc#'')
            then pa11.TXNDATE
    end) as PURBEH_VISITS_XMONTH_LOC


from temp_txn pa11

group by pa11.CUSTOMERID
