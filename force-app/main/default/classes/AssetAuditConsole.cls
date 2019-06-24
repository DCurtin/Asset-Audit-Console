public with sharing class AssetAuditConsole {

    @AuraEnabled
    public static List<AssetAuditWrapper> generateAssetAuditReport (Date startDate, Date endDate)
    {
        List<Transaction__c> testTrans = [SELECT id, name, Amount_Cash_Total__c, Transaction_Type__c, Date_Complete__c FROM Transaction__c WHERE Amount_Cash_Total__c != null AND Date_Complete__c != null LIMIT 200];
        List<AssetAuditWrapper> assetReport = new List<AssetAuditWrapper>();
        list<id> testIdList = new List<id>();
        
        testIdList.add('a060M00000WfLI1QAN');
        testIdList.add('a060M00000WfLI1QAO');
        testIdList.add('a060M00000WfLI1QAP');
        testIdList.add('a060M00000WfLI1QAQ');
        testIdList.add('a060M00000WfLI1QAR');

        Integer testNumber = 584524;
        Iterator<Transaction__c> transIter = testTrans.iterator();

        for(integer index=0; index < 5; ++index)
        {
            AssetAuditWrapper record= new AssetAuditWrapper();

            record.id   = testIdList[index];

            record.name = 'TRANS-' + testNumber;
            ++testNumber;

            record.totalCredit = ((Decimal) (Math.random() * 500)).setScale(2);
            record.totalDebit = ((Decimal) (Math.random() * 500)).setScale(2);

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
