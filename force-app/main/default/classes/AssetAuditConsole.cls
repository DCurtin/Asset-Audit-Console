public with sharing class AssetAuditConsole {

    @AuraEnabled
    public static List<AssetAuditWrapper> generateAssetAuditReport (Date startDate, Date endDate)
    {
        Map<Id,Transaction__c> fullSaleTransactionsMap = new Map<Id,Transaction__c>([SELECT id, Name, Account__c, CUSIP__c, XAudit_AccountName__c FROM Transaction__c where Full_Partial__c='Full' AND RecordType__c LIKE 'Sell%' AND (Date_Complete__c > :startDate AND Date_Complete__c < :endDate)]);

        Set<Id> cusipIdSet = getCusipSetFromTransactionMap(fullSaleTransactionsMap);
        Map<Id,IRAAsset__c> cusipMap = getCusipMapFromCusipIdSet(cusipIdSet);

        Map<Id,Transaction__c> debitTransactionsMap = new Map<Id,Transaction__c>([SELECT Id, Name, Account__c, CUSIP__c,Amount_Cash_Total__c, Transaction_Type__c, Date_Complete__c From Transaction__c Where Credit_or_Debit__c='Debit' AND CUSIP__c In :cusipIdSet]); //getDebitTransactionsMapRelatedToCusipSet(cusipIdSet);
        Map<Id,Transaction__c> creditTransactionsMap = new Map<Id,Transaction__c>([SELECT Id, Name, Account__c, CUSIP__c, Amount_Cash_Total__c, Transaction_Type__c, Date_Complete__c From Transaction__c Where Credit_or_Debit__c='Credit' AND CUSIP__c In :cusipIdSet]);

        List<AssetAuditWrapper> assetAuditWrapperList = generateAssetAuditWrapperList(fullSaleTransactionsMap, cusipMap, debitTransactionsMap, creditTransactionsMap);
        //query for all cusips to get their names
        return assetAuditWrapperList;
    }



    private static Map<Id,IRAAsset__c> getCusipMapFromCusipIdSet(Set<Id> cusipIdSet)
    {
        //Set<String> cusipIdSet = getCusipIdSetFromTransactionMap(transactionsMap);
        Map<Id,IRAAsset__c> cusipMap = new Map<Id,IRAAsset__c>([SELECT id, name FROM IRAAsset__c WHERE id in :cusipIdSet]);
        return cusipMap;
    }

    private static Set<Id> getCusipSetFromTransactionMap(Map<Id, Transaction__c> transactionsMap)
    {
        Set<Id> cusipIdSet = new Set<Id>();

        for(Transaction__c trans : transactionsMap.Values())
        {
            cusipIdSet.add(trans.CUSIP__c);
        }
        return cusipIdSet;
    }

    private static List<AssetAuditWrapper> generateAssetAuditWrapperList(Map<Id,Transaction__c> fullSaleTransactionsMap, Map<Id,IRAAsset__c>  cusipMap, Map<Id,Transaction__c> debitTransactionsMap, Map<Id,Transaction__c> creditTransactionsMap)
    {
        list<AssetAuditWrapper> assetAuditWrapperList = new list<AssetAuditWrapper>();
        for(Transaction__c fullSaleTransaction : fullSaleTransactionsMap.values())
        {
            list<Transaction__c> relatedDebitTransactions = getAllTransactionsForCusipAndAccount(fullSaleTransaction.CUSIP__c, fullSaleTransaction.Account__c, debitTransactionsMap);
            Decimal totalDebit = getTotalAmmountFromTransactionList(relatedDebitTransactions);

            list<Transaction__c> relatedCreditTransactions = getAllTransactionsForCusipAndAccount(fullSaleTransaction.CUSIP__c, fullSaleTransaction.Account__c, creditTransactionsMap);
            Decimal totalCredit = getTotalAmmountFromTransactionList(relatedCreditTransactions);

            Decimal totalDiff = (totalCredit - totalDebit).setScale(2);

            if(totalDiff <=0) //we are not interested in ammounts that lost logic for filtering percentage might go here
            {
                continue;
            }

            Decimal percentDiff = ((totalDiff/totalDebit)*100).setScale(2);

            IRAAsset__c fullSalesCusip = cusipMap.get(fullSaleTransaction.CUSIP__c);

            assetAuditWrapper assetAudit = new AssetAuditWrapper();

            assetAudit.saleId = fullSaleTransaction.Id;
            assetAudit.saleName = fullSaleTransaction.Name;
            assetAudit.accountId = fullSaleTransaction.Account__c;
            assetAudit.accountName = fullSaleTransaction.XAudit_AccountName__c;
            assetAudit.assetId = fullSalesCusip.Id;
            assetAudit.assetName = fullSalesCusip.Name;
            assetAudit.debitList=relatedDebitTransactions;
            assetAudit.totalDebit=totalDebit;
            assetAudit.creditList=relatedCreditTransactions;
            assetAudit.totalCredit=totalCredit;
            assetAudit.totalDiff=totalDiff;
            assetAudit.percentDiff=percentDiff;
            assetAuditWrapperList.add(assetAudit);
        }
        return assetAuditWrapperList;
    }

    private static list<Transaction__c> getAllTransactionsForCusipAndAccount(Id CusipId, Id AccountId, Map<Id,Transaction__c> transactionsMap)
    {
        List<Transaction__c> transactionsRelatedToCusipAndAccount = new List<Transaction__c>();
        for(Transaction__c trans : transactionsMap.values())
        {
            if(trans.CUSIP__c == CusipId && trans.Account__c == AccountId)
            {
                transactionsRelatedToCusipAndAccount.add(trans);
            }
        }
        return transactionsRelatedToCusipAndAccount;
    }

    private static Decimal getTotalAmmountFromTransactionList(List<Transaction__c> transactionList)
    {
        Decimal totalAmount = 0;
        for(Transaction__c trans : transactionList)
        {
            totalAmount += trans.Amount_Cash_Total__c;
        }
        return totalAmount;
    }

}
