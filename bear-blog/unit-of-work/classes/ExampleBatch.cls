public with sharing class ExampleBatch implements Database.Batchable<HeaderRecord__c>, Database.Stateful {
    private Date fromDate;
    private Date toDate;
    private Set<Id> updatedChildRecords;

    public ExampleBatch(Date fromDate, Date toDate) {
        this.fromDate = fromDate;
        this.toDate = toDate;
        this.updatedChildRecords = new Set<Id>();
    }

    public Iterable<HeaderRecord__c> start(Database.BatchableContext bc) {
        HeaderRecordSelector records = HeaderRecordSelector.newInstance();
        return (Iterable<HeaderRecord__c>) records.locatorByDateRange(this.fromDate, this.toDate);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        IUnitOfWork uow = (IUnitOfWork) ClassFactory.newUnitOfWorkInstance();
        try {
            HeaderRecordService service = HeaderRecordService.newInstance();
            service.ensureChildRecordsUpToDate((List<HeaderRecord__c>) scope, uow);
            uow.commitWork();
            this.updatedChildRecords.addAll(uow.getNewOrUpdatedIds(new List<SObjectType>{ Schema.ChildRecord__c.SObjectType }));
        } catch (Exception e) {
            Logger.error(scope, e);
            if (!Test.isRunningTest()) {
                throw e;
            }
        } finally {
            Logger.insertLogs();
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (!this.updatedChildRecords.isEmpty()) {
            Database.executeBatch(new PotentialChildBatch(updatedChildRecords));
        }
    }
}
