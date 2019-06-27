@isTest
public with sharing class AssetAuditWrapperTest {
    static testMethod void AssetAuditWrapper_ValidCase_ValuesAssigned()
    {
        String testString = 'TestString';
        id testId = 'a0H30000001PXrjEAG';
        Decimal testDec = 0.0;

        List<Transaction__c> testList = new List<Transaction__c>();

        AssetAuditWrapper testWrapper = new AssetAuditWrapper();


        testWrapper.saleId = testId;
        System.assertEquals(testId, testWrapper.saleId);
        testWrapper.saleName = testString;
        System.assertEquals(testString, testWrapper.saleName);

        testWrapper.accountId = testId;
        System.assertEquals(testId, testWrapper.accountId);
        testWrapper.accountName = testString;
        System.assertEquals(testString, testWrapper.accountName);

        testWrapper.assetId = testId;
        System.assertEquals(testId, testWrapper.assetId);
        testWrapper.assetName = testString;
        System.assertEquals(testString, testWrapper.assetName);

        testWrapper.totalDebit = testString;
        System.assertEquals(testString, testWrapper.totalDebit);
        testWrapper.totalCredit = testString;
        System.assertEquals(testString, testWrapper.totalCredit);

        testWrapper.totalDiff = testString;
        System.assertEquals(testString, testWrapper.totalDiff);

        testWrapper.percentDiff = testDec;
        System.assertEquals(testDec, testWrapper.percentDiff);

        testWrapper.debitList = testList;
        System.assertNotEquals(null, testWrapper.debitList);
        testWrapper.creditList = testList;
        System.assertNotEquals(null, testWrapper.creditList);
    }
}
