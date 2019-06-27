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
    @track tableLoading;
    @track filterPercentDifference=0.20;
    @track fullSalesReport;
    @track columns = columns;
    @track statusMessage;

    startDate;
    endDate;
    recordUrls = new Map();

    statusMessages ={
        welcome: "Welcome, please choose a start and end date as well as a profit margin percentage. Then click Generate Report",
        loading: "Table is generating, please wait",
        doneLoading : "",
        Error: "Please verify that you set start and end date"
    }

    constructor()
    {
        super();
        this.statusMessage=this.statusMessages.welcome;
    }

    generateReport()
    {
        this.fullSalesReport = [];
        if(this.startDate==null || this.endDate==null)
        {
            this.statusMessage=this.statusMessages.Error;
        }

        this.statusMessage=this.statusMessages.loading;
        generateAssetAuditReport({startDate: this.startDate, endDate: this.endDate , percentFilter: (this.filterPercentDifference * 100)}).then(function(result)
        {
            console.log(result);
            this.statusMessage=this.statusMessages.doneLoading;
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