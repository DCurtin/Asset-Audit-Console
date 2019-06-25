public with sharing class AssetAuditConsole {

    @AuraEnabled
    public static List<AssetAuditWrapper> generateAssetAuditReport (Date startDate, Date endDate)
    {
        List<Transaction__c> testTrans = [SELECT id, name, Amount_Cash_Total__c, Transaction_Type__c, Date_Complete__c FROM Transaction__c WHERE Amount_Cash_Total__c != null AND Date_Complete__c != null LIMIT 200];
        List<Account> testAccounts = [SELECT id, name FROM Account WHERE IsPersonAccount=False LIMIT 200];
        List<IRAAsset__c> testAssets = [SELECT id, name FROM IRAAsset__c LIMIT 200];

        List<AssetAuditWrapper> assetReport = new List<AssetAuditWrapper>();
        
        Iterator<Transaction__c> transIter = testTrans.iterator();
        Iterator<Account> acctIter = testAccounts.iterator();
        Iterator<IRAAsset__c> assetIter = testAssets.iterator();

        for(integer index=0; index < 5; ++index)
        {
            AssetAuditWrapper record= new AssetAuditWrapper();
            Transaction__c testSale = transIter.next();
            Account testAcct = acctIter.next();
            IRAAsset__c testAsset = assetIter.next(); 

            record.saleId   = testSale.id;
            record.saleName = testSale.name;

            record.accountId = testAcct.id;
            record.accountName = testAcct.name;

            record.assetId = testAsset.id;
            record.assetName = testAsset.name;

            record.totalCredit = ((Decimal) (Math.random() * 500)).setScale(2);
            record.totalDebit = record.totalCredit + ((Decimal) (Math.random() * 500)).setScale(2);

            record.totalDiff=record.totalDebit-record.totalCredit;
            record.percentDiff=(record.totalCredit/record.totalDebit*100).setScale(2);


            List<Transaction__c> debitList = new List<Transaction__c>();
            List<Transaction__c> creditList = new List<Transaction__c>();

            Integer transPerSale = ((Integer)(8 * Math.random())) + 1;
            for(Integer transIndex=0; transIndex < transPerSale; ++transIndex)
            {
                debitList.add(transIter.next());
            }

            transPerSale = ((Integer)(8 * Math.random())) + 1;
            for(Integer transIndex=0; transIndex < transPerSale; ++transIndex)
            {
                creditList.add(transIter.next());
            }
            

            record.creditList=creditList;
            record.debitList=debitList;

            assetReport.add(record);
        }
        return assetReport;
    }
    
    public static List<Transaction__c> CreateTransactions(Integer numTransactions) 
	{
        List<Transaction__c> trans = new List<Transaction__c>();
        for (Integer i = 0; i < numTransactions; i++) 
		{
            Transaction__c t = new Transaction__c();
            trans.add(t);
        }
        return trans;
    }
}
