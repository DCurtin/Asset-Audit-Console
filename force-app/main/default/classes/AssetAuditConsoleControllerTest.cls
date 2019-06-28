@isTest
public with sharing class AssetAuditConsoleControllerTest {
    static Final Integer FULLSALECOUNT = 4;
    static Final String CUSIP = 'RE79170D';

    @TestSetup
    static void makeData(){
        List<Account> testAccounts = TestUtils.insertAccounts(FULLSALECOUNT);
        
        List<Map<string, string>> debitAndCreditAmmounts = new List<Map<string, string>>();
        debitAndCreditAmmounts.add(new Map<String,String>{'Credit' => '1000', 'Debit' => '2000', 'CUSIP' => (CUSIP+'1')});
        debitAndCreditAmmounts.add(new Map<String,String>{'Credit' => '2000', 'Debit' => '1000', 'CUSIP' => (CUSIP+'2')});
        debitAndCreditAmmounts.add(new Map<String,String>{'Credit' => '1000', 'Debit' => '0', 'CUSIP' => (CUSIP+'3')});
        debitAndCreditAmmounts.add(new Map<String,String>{'Credit' => '9000', 'Debit' => '8000', 'CUSIP' => (CUSIP+'4')});

        Integer testCount=0;
        list<account> updateAccounts = new list<account>();
        list<Transaction__c> updateTransaction = new list<Transaction__c>();

        for(Account testAccount : testAccounts)
        {
            testAccount.Type = 'Roth IRA';
            testAccount.OfficeName__c = 'a0H30000001PXrjEAG'; //is an actual office id though this can be any id I believe
            updateAccounts.add(testAccount);

            IRAAsset__c testCusip = TestUtils.insertCusip(debitAndCreditAmmounts[testCount].get('CUSIP'), 'Note_Secured_by_RE', 'Secured Notes');
            
            Transaction__c testDebitTrans = TestUtils.insertTransaction(testAccount.id, testCusip.id);
            testDebitTrans.Trans_Code__c = '2'; //transaction code for Dedit trans
            testDebitTrans.Amount_Cash__c = Integer.valueOf(debitAndCreditAmmounts.get(testCount).get('Debit'));
            testDebitTrans.Transaction_Type__c = 'Buy - Note (Secured by RE)';
            testDebitTrans.Date_Complete__c = Date.today();
            testDebitTrans.Delivery_Method__c = 'ACH';

            updateTransaction.add(testDebitTrans);

            Transaction__c testCreditTrans = TestUtils.insertTransaction(testAccount.id, testCusip.id);
            testCreditTrans.Trans_Code__c = '1'; //transaction code for Credit trans
            testCreditTrans.Amount_Cash__c = Integer.valueOf(debitAndCreditAmmounts.get(testCount).get('Credit'));
            testCreditTrans.Transaction_Type__c = 'Sell - Other';
            testCreditTrans.Full_Partial__c = 'Full';
            testCreditTrans.Date_Complete__c = Date.today();
            testCreditTrans.Delivery_Method__c='ACH';

            updateTransaction.add(testCreditTrans);

            ++testCount;
        }
        update updateAccounts;
        update updateTransaction;
    }

    static testMethod void getFieldIdSetFromTransactionMap_validCaseCusip_SetOfCusipIdsReturned()
    {
        Map<Id,Transaction__c> fullSaleTransactionsMap = new Map<Id,Transaction__c>([SELECT id, Name, Account__c , Account_Type__c, CUSIP__c, XAudit_AccountName__c FROM Transaction__c where Full_Partial__c='Full' AND Transaction_Type__c LIKE 'Sell%']);
        Set<Id> cusipIds = AssetAuditConsoleController.getFieldIdSetFromTransactionMap(fullSaleTransactionsMap, 'Cusip__c');
        System.assertEquals(FULLSALECOUNT, cusipIds.size(), 'Returned set count does not match total cusips inserted.');
    }

    static testMethod void getCusipMapFromCusipIdSet_validCase_MapofCusipsMatchingtheSet()
    {
        Map<Id,IRAAsset__c> cusipMap = new Map<Id,IRAAsset__c>([SELECT id, Name FROM IRAAsset__c]);
        Set<Id> cusipIds=cusipMap.keySet();

        Id removedCusipId = (cusipMap.values())[0].Id;
        cusipIds.remove(removedCusipId);

        Map<id, IRAAsset__c> testCUSIPS = AssetAuditConsoleController.getCusipMapFromCusipIdSet(cusipIds);
        System.assertEquals(cusipIds.size(), testCUSIPS.size(), 'Returned map count does not match set of cusips provided');
        for(Id cusip : testCUSIPS.keySet())
        {
            System.assert(cusipIds.contains(cusip), 'This cusip id is not in the original set');
        }
    }

    static testMethod void generateAuditAssetWrapper_validCase_AFilledAssetAuditWrapper()
    {
        Map<id,IRAAsset__c> cusipMap = new Map<id,IRAAsset__c>([SELECT ID, Name, Asset_Type__c FROM IRAAsset__c]);

        //getFieldIdToTransactionMap
        List<Transaction__c> transactionsList = [SELECT Id, XAudit_AccountName__c, Name, Account__c, CUSIP__c,Amount_Cash_Total__c, Transaction_Type__c, Account_Type__c, Date_Complete__c, Credit_or_Debit__c From Transaction__c Where (Credit_or_Debit__c='Debit' OR Credit_or_Debit__c='Credit')  AND  Date_Complete__c != null  AND CUSIP__c In :cusipMap.keySet() ORDER BY Date_Complete__c ASC];
        Map<id, List<Transaction__c>> cusipIdToTransactionListMap = AssetAuditConsoleController.getFieldIdToTransactionMap(transactionsList,'Cusip__c');
        Map<id, List<Transaction__c>> AccountIdToTransactionListMap = AssetAuditConsoleController.getFieldIdToTransactionMap(transactionsList,'Account__c');
        //Map<Id,Transaction__c> creditTransactionsMap = new Map<Id,Transaction__c>([SELECT Id, XAudit_AccountName__c,  Name, Account__c, CUSIP__c, Amount_Cash_Total__c, Transaction_Type__c, Account_Type__c, Date_Complete__c From Transaction__c Where Credit_or_Debit__c='Credit' AND  Date_Complete__c != null AND CUSIP__c In :cusipMap.keySet()  ORDER BY Date_Complete__c ASC]);

        Transaction__c salesTransaction;
        for(Transaction__c trans : transactionsList)
        {
            if(cusipMap.get(trans.CUSIP__c).name == CUSIP+'2')
            {
                salesTransaction = trans;
                break;
            }
        }

        Decimal percentFilter = 20;
        System.debug(salesTransaction);

        AssetAuditWrapper testWrapper = AssetAuditConsoleController.generateAuditAssetWrapper(salesTransaction, cusipMap, cusipIdToTransactionListMap, AccountIdToTransactionListMap, percentFilter);
        System.assertNotEquals(null, testWrapper);

    }

    /*static testMethod void generateAuditAssetWrapper_ProfitMarginBelowThreshold_NullSobject()
    {
        Map<id,IRAAsset__c> cusipMap = new Map<id,IRAAsset__c>([SELECT ID, Name, Asset_Type__c FROM IRAAsset__c]);
        Map<Id,Transaction__c> debitTransactionsMap = new Map<Id,Transaction__c>([SELECT Id, XAudit_AccountName__c, Name, Account__c, CUSIP__c,Amount_Cash_Total__c, Transaction_Type__c, Account_Type__c, Date_Complete__c From Transaction__c Where Credit_or_Debit__c='Debit' AND  Date_Complete__c != null  AND CUSIP__c In :cusipMap.keySet() ORDER BY Date_Complete__c ASC]);
        Map<Id,Transaction__c> creditTransactionsMap = new Map<Id,Transaction__c>([SELECT Id, XAudit_AccountName__c,  Name, Account__c, CUSIP__c, Amount_Cash_Total__c, Transaction_Type__c, Account_Type__c, Date_Complete__c From Transaction__c Where Credit_or_Debit__c='Credit' AND  Date_Complete__c != null AND CUSIP__c In :cusipMap.keySet()  ORDER BY Date_Complete__c ASC]);

        Transaction__c salesTransaction;
        for(Transaction__c trans : creditTransactionsMap.values())
        {
            if(cusipMap.get(trans.CUSIP__c).name == CUSIP+'3')
            {
                salesTransaction = trans;
                break;
            }
        }

        Decimal percentFilter = 20;

        AssetAuditWrapper testWrapper = AssetAuditConsoleController.generateAuditAssetWrapper(salesTransaction, cusipMap, debitTransactionsMap, creditTransactionsMap, percentFilter);
        System.assertEquals(null, testWrapper);

    }*/

    /*static testMethod void generateAuditAssetWrapper_NegativeProfit_NullSobject()
    {
        Map<id,IRAAsset__c> cusipMap = new Map<id,IRAAsset__c>([SELECT ID, Name, Asset_Type__c FROM IRAAsset__c]);
        Map<Id,Transaction__c> debitTransactionsMap = new Map<Id,Transaction__c>([SELECT Id, XAudit_AccountName__c, Name, Account__c, CUSIP__c,Amount_Cash_Total__c, Transaction_Type__c, Account_Type__c, Date_Complete__c From Transaction__c Where Credit_or_Debit__c='Debit' AND  Date_Complete__c != null  AND CUSIP__c In :cusipMap.keySet() ORDER BY Date_Complete__c ASC]);
        Map<Id,Transaction__c> creditTransactionsMap = new Map<Id,Transaction__c>([SELECT Id, XAudit_AccountName__c,  Name, Account__c, CUSIP__c, Amount_Cash_Total__c, Transaction_Type__c, Account_Type__c, Date_Complete__c From Transaction__c Where Credit_or_Debit__c='Credit' AND  Date_Complete__c != null AND CUSIP__c In :cusipMap.keySet()  ORDER BY Date_Complete__c ASC]);

        Transaction__c salesTransaction;
        for(Transaction__c trans : creditTransactionsMap.values())
        {
            if(cusipMap.get(trans.CUSIP__c).name == CUSIP+'1')
            {
                salesTransaction = trans;
                break;
            }
        }

        Decimal percentFilter = 20;

        AssetAuditWrapper testWrapper = AssetAuditConsoleController.generateAuditAssetWrapper(salesTransaction, cusipMap, debitTransactionsMap, creditTransactionsMap, percentFilter);
        System.assertEquals(null, testWrapper);

    }*/

    static testmethod void generateAssetAuditReport_validCase_AListOfFilledAssetWrappersAboveOrEqualToThreshold()
    {
        list<AssetAuditWrapper> assetAuditWrapperList = AssetAuditConsoleController.generateAssetAuditReport(Date.Today()-30, Date.Today()+30, 20);
        System.assertEquals(1,assetAuditWrapperList.size(), 'For the given paramters the returned number of assets is greater or less than expected. Please check percentFilter and debitAndCreditAmmounts');
    }


}
