public with sharing class AssetAuditConsoleController {

    @AuraEnabled
    public static List<AssetAuditWrapper> generateAssetAuditReport (Date startDate, Date endDate, Decimal percentFilter)
    {
        Map<Id,Transaction__c> fullSaleTransactionsMap = new Map<Id,Transaction__c>([SELECT id, Name, Account__c , Account_Type__c, CUSIP__c, XAudit_AccountName__c FROM Transaction__c where Full_Partial__c='Full' AND (RecordType__c LIKE 'Sell%' OR Transaction_Type__c LIKE 'Sell%') AND (Date_Complete__c > :startDate AND Date_Complete__c < :endDate)]);

        Set<Id> cusipIdSet = getFieldIdSetFromTransactionMap(fullSaleTransactionsMap, 'CUSIP__c');
        Set<Id> accountSet = getFieldIdSetFromTransactionMap(fullSaleTransactionsMap, 'Account__c');
        Map<Id,IRAAsset__c> cusipMap = getCusipMapFromCusipIdSet(cusipIdSet);
        List<Transaction__c> transactionList = queryDebitAndCreditFilteringByCusip(cusipIdSet, accountSet);
        Map<Id,List<Transaction__c>> cusipIdToTransactionMap = getFieldIdToTransactionMap(transactionList, 'CUSIP__c');
        Map<Id,List<Transaction__c>> accountIdToTransactionMap = getFieldIdToTransactionMap(transactionList, 'Account__c');

        List<AssetAuditWrapper> assetAuditWrapperList = generateAssetAuditWrapperList(fullSaleTransactionsMap, cusipMap, cusipIdToTransactionMap, accountIdToTransactionMap, percentFilter);

        return assetAuditWrapperList;
    }

    public static Set<Id> getFieldIdSetFromTransactionMap(Map<Id, Transaction__c> transactionsMap , string fieldName)
    {
        Set<Id> idSet = new Set<Id>();
        for(Transaction__c trans : transactionsMap.Values())
        {
            idSet.add((id) trans.get(fieldName));
        }
        return idSet;
    }

    public static Map<Id, List<Transaction__c>> getFieldIdToTransactionMap(List<Transaction__c> transactionList, string keyFieldName)
    {
        map<Id, List<Transaction__c>> cusipIDToTransactionsListMap = new map<Id, List<Transaction__c>>();
        for(Transaction__c trans : transactionList)
        {
            If(cusipIDToTransactionsListMap.containsKey((id)trans.get(keyFieldName)))
            {
                cusipIDToTransactionsListMap.get((id)trans.get(keyFieldName)).add(trans);
            }else {
                List<Transaction__c> transList = new List<Transaction__c>();
                transList.add(trans);
                cusipIDToTransactionsListMap.put((id)trans.get(keyFieldName),transList);
            }
        }
        return cusipIDToTransactionsListMap;
    }

    private static List<Transaction__c> queryDebitAndCreditFilteringByCusip(Set<Id> cusipIdSet, Set<Id> accountIdSet)
    {
        String debitQuery='SELECT Id, Name, Account__c, CUSIP__c,Amount_Cash_Total__c, Transaction_Type__c, Date_Complete__c, Credit_or_Debit__c From Transaction__c Where (Credit_or_Debit__c=\'Debit\' OR Credit_or_Debit__c=\'Credit\') AND CUSIP__c In :cusipIdSet AND Account__c In :accountIdSet AND Date_Complete__c != null ORDER BY Date_Complete__c ASC';
        List<Transaction__c> debitAndCreditList = Database.query(debitQuery);
        return debitAndCreditList;
    }

    public static Map<Id,IRAAsset__c> getCusipMapFromCusipIdSet(Set<Id> cusipIdSet)
    {
        Map<Id,IRAAsset__c> cusipMap = new Map<Id,IRAAsset__c>([SELECT id, name, Asset_Type__c FROM IRAAsset__c WHERE id in :cusipIdSet]);
        return cusipMap;
    }

    private static List<AssetAuditWrapper> generateAssetAuditWrapperList(Map<Id,Transaction__c> fullSaleTransactionsMap, Map<Id,IRAAsset__c>  cusipMap, Map<Id,List<Transaction__c>> cusipIdToTransactionMap, Map<Id,List<Transaction__c>> accountIdToTransactionMap, Decimal percentFilter)
    {
        
        list<AssetAuditWrapper> assetAuditWrapperList = new list<AssetAuditWrapper>();

        for(Transaction__c fullSaleTransaction : fullSaleTransactionsMap.values())
        {
            AssetAuditWrapper assetAudit = generateAuditAssetWrapper(fullSaleTransaction, cusipMap, cusipIdToTransactionMap, accountIdToTransactionMap, percentFilter);
            if(assetAudit!=null)
            {
                assetAuditWrapperList.add(assetAudit);
            }
        }
        return assetAuditWrapperList;
    }

    public static AssetAuditWrapper generateAuditAssetWrapper(Transaction__c fullSaleTransaction, Map<Id,IRAAsset__c>  cusipMap, Map<Id,List<Transaction__c>> cusipIdToTransactionMap, Map<Id,List<Transaction__c>> accountIdToTransactionMap, Decimal percentFilter)
    {
        assetAuditWrapper assetAudit = assignAllTransactionsAndTotalAmmountToAssetAuditWrapper(fullSaleTransaction, cusipIdToTransactionMap, accountIdToTransactionMap, percentFilter);
        if(assetAudit == null)
        {
            return null;
        }

        IRAAsset__c fullSalesCusip = cusipMap.get(fullSaleTransaction.CUSIP__c);

        setFullSaleFields(fullSaleTransaction, assetAudit);
        setFullSaleCusipFields(fullSalesCusip,assetAudit);

        return assetAudit;
    }

    private static AssetAuditWrapper assignAllTransactionsAndTotalAmmountToAssetAuditWrapper(Transaction__c fullSale, Map<Id,List<Transaction__c>> CusipIdToTransactionListMap, Map<Id,List<Transaction__c>> AccountIdToTransactionListMap, Decimal percentFilter)
    {
        AssetAuditWrapper assetAudit = new AssetAuditWrapper();
        list<String> currencyFormattingArgs = new String[]{'0','number','###,###,##0.00'};
        Decimal totalDebit = 0;
        Decimal totalCredit = 0;
        List<Transaction__c> accountTransactionList = CusipIdToTransactionListMap.get(fullSale.Cusip__c);
        List<Transaction__c> cusipTransactionList = AccountIdToTransactionListMap.get(fullSale.Account__c);
        
        List<Transaction__c> debitList = new List<Transaction__c>();
        List<Transaction__c> creditList = new List<Transaction__c>();

        for(Transaction__c acctTrans : accountTransactionList)
        { 
            for(Transaction__c cusipTrans: cusipTransactionList)
            {
                if(cusipTrans.id == acctTrans.id) 
                {
                    if(acctTrans.Credit_or_Debit__c == 'Credit')
                    {
                        creditList.add(acctTrans);
                        totalCredit+=acctTrans.Amount_Cash_Total__c;
                    }else 
                    {
                        debitList.add(acctTrans);
                        totalDebit+=acctTrans.Amount_Cash_Total__c;
                    }
                    break;
                }
            }
        }

        Decimal totalDiff = (totalCredit - totalDebit).setScale(2);

        if( filterOutNegativeProfitOrNoDebit(totalDiff , totalDebit))
        {
            return null;
        }

        Decimal percentDiff = ((totalDiff/totalDebit)*100).setScale(2);

        if(filterOutProfitMarginBelowThreshold(percentDiff, percentFilter))
        {
            return null;
        }

        assetAudit.creditList = creditList;
        assetAudit.totalCredit = String.format(totalCredit.format(), currencyFormattingArgs);

        assetAudit.debitList = debitList;
        assetAudit.totalDebit = String.format(totalDebit.format(), currencyFormattingArgs); 

        assetAudit.totalDiff = String.format(totalDiff.format(), currencyFormattingArgs);
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

    private static void setFullSaleFields(Transaction__c fullSaleTransaction, assetAuditWrapper assetAudit)
    {
        assetAudit.saleId = fullSaleTransaction.Id;
        assetAudit.saleName = fullSaleTransaction.Name;
        assetAudit.accountId = fullSaleTransaction.Account__c;
        assetAudit.accountName = fullSaleTransaction.XAudit_AccountName__c + ' - ' + fullSaleTransaction.Account_Type__c;
    }

    private static void setFullSaleCusipFields(IRAAsset__c fullSalesCusip, assetAuditWrapper assetAudit)
    {
        assetAudit.assetId = fullSalesCusip.Id;
        assetAudit.assetName = fullSalesCusip.Name + ' - ' + fullSalesCusip.Asset_Type__c;
    }

}
