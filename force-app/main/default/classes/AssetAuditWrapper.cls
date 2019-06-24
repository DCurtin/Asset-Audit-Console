public with sharing class AssetAuditWrapper {
    @AuraEnabled
    public Id saleId;

    @AuraEnabled
    public String saleName;

    @AuraEnabled
    public id accountId;

    @AuraEnabled
    public String accountName;
    
    @AuraEnabled
    public id assetId;

    @AuraEnabled
    public String assetName;

    @AuraEnabled
    public Decimal totalDebit;

    @AuraEnabled
    public Decimal totalCredit;

    @AuraEnabled
    public Decimal totalDiff;

    @AuraEnabled
    public Decimal percentDiff;

    @AuraEnabled
    public List<Transaction__c> debitList;

    @AuraEnabled
    public List<Transaction__c> creditList; 
}
