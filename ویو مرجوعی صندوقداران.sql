with CTE_Count as (
  select CreationUser as UserID,
       SI.BusinessDate,
	   count(SI.InvoiceID) as InvoiceCount
    from SaleInvoice SI
    where  SI.InvoiceTypeID is null
    group by SI.BusinessDate,SI.CreationUser)

  select 
        DisplayName as [نام کاربر],
        C.Date as [تاریخ],
		ST.Name as [نام فروشگاه],
		CTE.InvoiceCount as [تعداد فاکتور], 
        sum(SaleQuantity) as [تعداد اقلام فروش], 
        sum(ReturnQuantity) as [تعداد مرجوعی],
        sum(NetSaleAmount ) as [مبلغ فروش ],
        sum(NetReturnAmount ) as [مبلغ مرجوعی ],
		sum(NetSaleAmount - NetReturnAmount) as [خالص فروش]
from
  (select
       SI.BookerStoreID as StoreID,
       CreationUser as UserID,
	   SI.BusinessDate, 
       Quantity+BonusQuantity as SaleQuantity,
       case when IsPriceWithTax = 1 then PriceAmount * (Quantity + BonusQuantity)-(SILI.TaxAmount-SILI.TollAmount)
       else
       PriceAmount * (Quantity + BonusQuantity)
       end as SaleAmount, 
       isnull(SILI.DiscountAmount, 0) + isnull(SILI.InvoiceDiscount, 0) + isnull(SILI.ManualDiscount, 0) as DiscountAmount,
	   isnull(cast(SILI.RoundAmount as decimal(30,2)),0) as RoundAmount,
	   SILI.TaxAmount,
	   SILI.TollAmount, 
       case when IsPriceWithTax = 1 then 
       ((SILI.PriceAmount * (SILI.Quantity + BonusQuantity))-SILI.DiscountAmount-SILI.InvoiceDiscount-SILI.ManualDiscount-isnull(SILI.RoundAmount, 0))
       else
       ((SILI.PriceAmount * (SILI.Quantity + BonusQuantity))-SILI.DiscountAmount-SILI.InvoiceDiscount-SILI.ManualDiscount+isnull(SILI.TaxAmount, 0)+isnull(SILI.TollAmount, 0)-isnull(SILI.RoundAmount, 0))
       end as NetSaleAmount,
       0 as ReturnQuantity,
	   0 as ReturnAmount,
	   0 as ReturnDiscount,
	   0 as ReturnRound,
	   0 as ReturnTax,
	   0 as ReturnToll,
	   0 as NetReturnAmount
       from SaleInvoice SI

inner join SaleInvoiceLineItem SILI
on SI.BookerStoreID = SILI.BookerStoreID
and SI.BookerWorkstationID = SILI.BookerWorkstationID
and SI.InvoiceID = SILI.InvoiceID
where SILI.TypeID = 302
and SI.InvoiceTypeID is null

union all

  select
       SI.BookerStoreID as StoreID,
       CreationUser as UserID,
	   SI.BusinessDate,  
       0, 0, 0, 0, 0, 0, 0,
	   Quantity+BonusQuantity as ReturnQuantity,
       case when IsPriceWithTax = 1 then 
       PriceAmount * (Quantity + BonusQuantity)-(SILI.TaxAmount-SILI.TollAmount)
       else 
       PriceAmount * (Quantity + BonusQuantity)
       end,
	   isnull(SILI.DiscountAmount, 0)+isnull(SILI.InvoiceDiscount, 0)+isnull(SILI.ManualDiscount, 0),
	   isnull(cast(SILI.RoundAmount as decimal(30,2)),0),
	   SILI.TaxAmount,
	   SILI.TollAmount, 
       case when IsPriceWithTax = 1 then
       ((SILI.PriceAmount * (SILI.Quantity + BonusQuantity))-SILI.DiscountAmount-SILI.InvoiceDiscount-SILI.ManualDiscount+isnull(SILI.RoundAmount, 0))
        else
       ((SILI.PriceAmount * (SILI.Quantity + BonusQuantity))-SILI.DiscountAmount-SILI.InvoiceDiscount-SILI.ManualDiscount+isnull(SILI.TaxAmount, 0) + isnull(SILI.TollAmount, 0) + isnull(SILI.RoundAmount, 0))
       end
from SaleInvoice SI
inner join SaleInvoiceLineItem SILI
 on SI.BookerStoreID = SILI.BookerStoreID
 and SI.BookerWorkstationID = SILI.BookerWorkstationID
 and SI.InvoiceID = SILI.InvoiceID
where TypeID = 303
and SI.InvoiceTypeID is null) as Final

inner join [User] U
 on Final.UserID = U.UserID
inner join Store ST
 on ST.StoreID= Final.StoreID
inner join Calendar C
 on C.BusinessDate=Final.BusinessDate
and isnull(C.LanguageID,314)=314
inner join CTE_Count CTE
  on CTE.UserID = U.UserID
    and CTE.BusinessDate = Final.BusinessDate

    and Final.BusinessDate = '2021-11-22'
    --and Final.UserID = '4F36125A-8F33-4154-BAA3-03ED0E2AE9F2'
    --and Final.StoreID = '6'

 where isnull(C.LanguageID,314)=314
group by  DisplayName, C.Date,ST.Name,CTE.InvoiceCount
order by  ST.Name
--order by DisplayName
--order by C.Date
