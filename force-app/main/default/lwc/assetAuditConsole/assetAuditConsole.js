import { LightningElement, track } from 'lwc';

export default class AssetAuditConsole extends LightningElement {
    @track returnedRecordCount;
    @track endDateStatus;
    @track filterPercentDifference=0.20;

    startDate;
    endDate;
    

    constructor()
    {
        super();
        this.returnedRecordCount=0;
    }

    generateReport()
    {
        this.returnedRecordCount +=1;

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