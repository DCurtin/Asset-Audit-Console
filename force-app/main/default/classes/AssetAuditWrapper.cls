public with sharing class AssetAuditWrapper {
    @AuraEnabled
    public Id id;

    @AuraEnabled
    public String name;

    @AuraEnabled
    public Decimal totalDebit;

    @AuraEnabled
    public Decimal totalCredit;

    @AuraEnabled
    public List<Transaction__c> debitList;

    @AuraEnabled
    public List<Transaction__c> creditList; 
}
