/* eslint-disable no-console */
import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import generateAssetAuditReport from '@salesforce/apex/AssetAuditConsole.generateAssetAuditReport';

const columns = [
    { label: 'Name', fieldName: 'Name'},
    { label: 'Date Complete', fieldName: 'Date_Complete__c', type: 'date'},
    { label: 'Type', fieldName: 'Transaction_Type__c'},
    { label: 'Amount (Cash Total)', fieldName: 'Amount_Cash_Total__c', type: 'currency'}
]

export default class AssetAuditConsole extends NavigationMixin(LightningElement) {
    @track returnedRecordCount;
    @track endDateStatus;
    @track filterPercentDifference=0.20;
    @track fullSalesReport;
    @track columns = columns;
    


    startDate;
    endDate;
    recordUrls = new Map();

    constructor()
    {
        super();
        this.returnedRecordCount=0;
    }

    generateReport()
    {
        //this.returnedRecordCount +=1;
        generateAssetAuditReport({startDate: this.startDate, endDate: this.endDate , percentFilter: (this.filterPercentDifference * 100)}).then(function(result)
        {
            console.log(result);
            this.returnedRecordCount=result.length;
            this.fullSalesReport = result;
            //this.generateUrlsForRecords(result);

        }.bind(this));
    }

    generateUrlsForRecords(fullSalesReport)
    {
        fullSalesReport.forEach( report => 
            {
                this.generateUrl(report.saleId, 'Transaction__c').then( event => this.recordUrls.set(report.saleId,event.url));
                this.recordUrls.set(report.accountId, this.generateUrl(report.accountId, 'Account'));
                this.recordUrls.set(report.assetId, this.generateUrl(report.assetId, 'IRAAsset__c'));
            })
            console.log(this.recordUrls);
    }

    updateStartDate(event)
    {
        this.startDate=event.detail.value;
        
    }

    updateEndDate(event)
    {
        this.endDate=event.detail.value;
        this.endDateStatus=Date.now().toISOString();
    }

    updateFilterPercentDifference(event)
    {
        this.filterPercentDifference=event.detail.value;
    }

    handleAccountView(event)
    {
        event.preventDefault();
        event.stopPropagation();
        this.handleObjectView(event.target.dataset.id, 'Account');
    }

    handleAssetView(event)
    {
        event.preventDefault();
        event.stopPropagation();
        this.handleObjectView(event.target.dataset.id, 'IRAAsset__c');
    }

    handleTransactionView(event)
    {
        event.preventDefault();
        event.stopPropagation();
        this.handleObjectView(event.target.dataset.id, 'Transaction__c');
    }

    /*handleObjectView(recordId)
    {
        console.log(this.recordUrls.get(recordId));
        window.open(this.recordUrls.get(recordId));
    }*/

    handleObjectView(objectId, objectType) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: objectId,
                objectApiName: objectType,
                actionName: 'view'
            }
        }).then(result => { console.log(result);
            window.open(result)});
        
        
    }
}