public with sharing class AssetAuditConsole {

    @AuraEnabled
    public static List<AssetAuditWrapper> generateAssetAuditReport (Date startDate, Date endDate, Decimal percentFilter)
    {
        Map<Id,Transaction__c> fullSaleTransactionsMap = new Map<Id,Transaction__c>([SELECT id, Name, Account__c , Account_Type__c, CUSIP__c, XAudit_AccountName__c FROM Transaction__c where Full_Partial__c='Full' AND (RecordType__c LIKE 'Sell%' OR Transaction_Type__c LIKE 'Sell%') AND (Date_Complete__c > :startDate AND Date_Complete__c < :endDate)]);

        Set<Id> cusipIdSet = getCusipSetFromTransactionMap(fullSaleTransactionsMap);
        Map<Id,IRAAsset__c> cusipMap = getCusipMapFromCusipIdSet(cusipIdSet);

        Map<Id,Transaction__c> debitTransactionsMap = new Map<Id,Transaction__c>([SELECT Id, Name, Account__c, CUSIP__c,Amount_Cash_Total__c, Transaction_Type__c, Date_Complete__c From Transaction__c Where Credit_or_Debit__c='Debit' AND CUSIP__c In :cusipIdSet AND Date_Complete__c != null ORDER BY Date_Complete__c ASC]); //getDebitTransactionsMapRelatedToCusipSet(cusipIdSet);
        Map<Id,Transaction__c> creditTransactionsMap = new Map<Id,Transaction__c>([SELECT Id, Name, Account__c, CUSIP__c, Amount_Cash_Total__c, Transaction_Type__c, Date_Complete__c From Transaction__c Where Credit_or_Debit__c='Credit' AND CUSIP__c In :cusipIdSet AND Date_Complete__c != null ORDER BY Date_Complete__c ASC]);

        List<AssetAuditWrapper> assetAuditWrapperList = generateAssetAuditWrapperList(fullSaleTransactionsMap, cusipMap, debitTransactionsMap, creditTransactionsMap, percentFilter);
        //query for all cusips to get their names
        return assetAuditWrapperList;
    }

    public static Set<Id> getCusipSetFromTransactionMap(Map<Id, Transaction__c> transactionsMap)
    {
        Set<Id> cusipIdSet = new Set<Id>();
        for(Transaction__c trans : transactionsMap.Values())
        {
            cusipIdSet.add(trans.CUSIP__c);
        }
        return cusipIdSet;
    }

    public static Map<Id,IRAAsset__c> getCusipMapFromCusipIdSet(Set<Id> cusipIdSet)
    {
        //Set<String> cusipIdSet = getCusipIdSetFromTransactionMap(transactionsMap);
        Map<Id,IRAAsset__c> cusipMap = new Map<Id,IRAAsset__c>([SELECT id, name, Asset_Type__c FROM IRAAsset__c WHERE id in :cusipIdSet]);
        return cusipMap;
    }

    private static List<AssetAuditWrapper> generateAssetAuditWrapperList(Map<Id,Transaction__c> fullSaleTransactionsMap, Map<Id,IRAAsset__c>  cusipMap, Map<Id,Transaction__c> debitTransactionsMap, Map<Id,Transaction__c> creditTransactionsMap, Decimal percentFilter)
    {
        
        list<AssetAuditWrapper> assetAuditWrapperList = new list<AssetAuditWrapper>();

        for(Transaction__c fullSaleTransaction : fullSaleTransactionsMap.values())
        {
            AssetAuditWrapper assetAudit = generateAuditAssetWrapper(fullSaleTransaction, cusipMap, debitTransactionsMap, creditTransactionsMap, percentFilter);
            if(assetAudit!=null)
            {
                assetAuditWrapperList.add(assetAudit);
            }
        }
        return assetAuditWrapperList;
    }

    public static AssetAuditWrapper generateAuditAssetWrapper(Transaction__c fullSaleTransaction, Map<Id,IRAAsset__c>  cusipMap, Map<Id,Transaction__c> debitTransactionsMap, Map<Id,Transaction__c> creditTransactionsMap, Decimal percentFilter)
    {
        list<String> currencyFormattingArgs = new String[]{'0','number','###,###,##0.00'};
            list<Transaction__c> relatedDebitTransactions = new List<Transaction__c>();
            Decimal totalDebit  = assignAllTransactionsReturnTotalAmmount(fullSaleTransaction.CUSIP__c, fullSaleTransaction.Account__c, debitTransactionsMap, relatedDebitTransactions);
            
            list<Transaction__c> relatedCreditTransactions = new List<Transaction__c>(); 
            Decimal totalCredit = assignAllTransactionsReturnTotalAmmount(fullSaleTransaction.CUSIP__c, fullSaleTransaction.Account__c, creditTransactionsMap,relatedCreditTransactions);

            Decimal totalDiff = (totalCredit - totalDebit).setScale(2);

            if( filterOutNegativeProfitOrNoDebit(totalDiff ,totalDebit)) //we are not interested in ammounts that lost logic for filtering percentage might go here
            {
                return null;
            }

            Decimal percentDiff = ((totalDiff/totalDebit)*100).setScale(2);

            if(filterOutProfitMarginBelowThreshold(percentDiff, percentFilter))
            {
                return null;
            }        

            IRAAsset__c fullSalesCusip = cusipMap.get(fullSaleTransaction.CUSIP__c);

            assetAuditWrapper assetAudit = new AssetAuditWrapper();

            assetAudit.saleId = fullSaleTransaction.Id;
            assetAudit.saleName = fullSaleTransaction.Name;
            assetAudit.accountId = fullSaleTransaction.Account__c;
            assetAudit.accountName = fullSaleTransaction.XAudit_AccountName__c + ' - ' + fullSaleTransaction.Account_Type__c;
            assetAudit.assetId = fullSalesCusip.Id;
            assetAudit.assetName = fullSalesCusip.Name + ' - ' + fullSalesCusip.Asset_Type__c;
            assetAudit.debitList=relatedDebitTransactions;
            assetAudit.totalDebit=String.format(totalDebit.format(), currencyFormattingArgs);
            assetAudit.creditList=relatedCreditTransactions;
            assetAudit.totalCredit=String.format(totalCredit.format(), currencyFormattingArgs);
            assetAudit.totalDiff=String.format(totalDiff.format(), currencyFormattingArgs);
            assetAudit.percentDiff=percentDiff;

            return assetAudit;
    }

    private static Boolean filterOutProfitMarginBelowThreshold(Decimal percentDiff, Decimal threshhold)
    {
        return (percentDiff < threshhold);
    }


    private static Boolean filterOutNegativeProfitOrNoDebit(Decimal totalDifference, Decimal totalDebit)
    {
        return (totalDifference <=0 || totalDebit==0);
    }

    private static Decimal assignAllTransactionsReturnTotalAmmount(Id CusipId, Id AccountId, Map<Id,Transaction__c> transactionsMap, list<Transaction__c> assignTo)
    {
        Decimal totalAmmount = 0;

        for(Transaction__c trans : transactionsMap.values())
        { 
            if(trans.CUSIP__c == CusipId && trans.Account__c == AccountId) 
            {
                assignTo.add(trans);
                totalAmmount += trans.Amount_Cash_Total__c;
            }
        }
        return totalAmmount;
    }

}
