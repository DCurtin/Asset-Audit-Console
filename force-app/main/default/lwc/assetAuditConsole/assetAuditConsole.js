/* eslint-disable no-console */
import { LightningElement, track } from 'lwc';
import generateAssetAuditReport from '@salesforce/apex/AssetAuditConsole.generateAssetAuditReport';

const columns = [
    { label: 'Name', fieldName: 'Name'},
    { label: 'Date Complete', fieldName: 'Date_Complete__c', type: 'date'},
    { label: 'Type', fieldName: 'Transaction_Type__c'},
    { label: 'Amount (Cash Total)', fieldName: 'Amount_Cash_Total__c', type: 'currency'}
]

export default class AssetAuditConsole extends LightningElement {
    @track returnedRecordCount;
    @track endDateStatus;
    @track filterPercentDifference=0.20;
    @track fullSalesReport;
    @track columns = columns;

    startDate;
    endDate;
    

    constructor()
    {
        super();
        this.returnedRecordCount=0;
    }

    generateReport()
    {
        //this.returnedRecordCount +=1;
        generateAssetAuditReport({startDate: this.startDate, endDate: this.endDate}).then(function(result)
        {
            console.log(result[0].debitList);
            this.returnedRecordCount=result.length;
            this.fullSalesReport = result;

        }.bind(this));
    }

    updateStartDate(event)
    {
        this.startDate=event.detail.value;
        
    }

    updateEndDate(event)
    {
        this.endDate=event.detail.value;
        this.endDateStatus=event.detail.value;
    }

    updateFilterPercentDifference(event)
    {
        this.filterPercentDifference=event.detail.value;
    }
}