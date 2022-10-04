@IsTest
private class ExampleBatchTest {
    @IsTest
    static void whenItemUpdatedPreInvoiceBatchIsLaunchedForItsCampaign() {
        Date today = System.today();
        Date startOfTheMonth = today.toStartOfMonth();
        Date endOfTheMonth = startOfTheMonth.addMonths(1).addDays(-1);

        List<HeaderRecord__c> headerRecords = new List<ADvendio__CaHeaderRecord__cmpaign_Item__c>{
            TestFactory.getRecord(Schema.HeaderRecord__c.SObjectType), //fake
            TestFactory.getRecord(Schema.HeaderRecord__c.SObjectType)
        };

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork unitOfWorkMock = new MockUnitOfWork(); //not from ApexMocks!
        HeaderRecordSelector selectorMock = (HeaderRecordSelector) mocks.mock(HeaderRecordSelector.class);
        HeaderRecordService serviceMock = (HeaderRecordService) mocks.mock(HeaderRecordService.class);

        mocks.startStubbing();
        mocks.when(selectorMock.sObjectType()).thenReturn(Schema.HeaderRecord__c.SObjectType);
        mocks.when(selectorMock.locatorByDateRange(startOfTheMonth, endOfTheMonth)).thenReturn(headerRecords);
        ((HeaderRecordService) mocks.doAnswer(new VoidAnswerUpdateItem(), serviceMock))
            .ensureChildRecordsUpToDate(headerRecords, unitOfWorkMock);
        mocks.stopStubbing();

        ClassFactory.setMock(HeaderRecordSelector.class, selectorMock);
        ClassFactory.setMock(HeaderRecordService.class, serviceMock);
        ClassFactory.setMock(fflib_ISObjectUnitOfWork.class, unitOfWorkMock);

        Test.startTest();
        Database.executeBatch(new ExampleBatch(startOfTheMonth, endOfTheMonth));
        Test.stopTest();

        List<AsyncApexJob> childRecordsJob = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'PotentialChildBatch'];
        System.assertEquals(1, childRecordsJob.size(), 'childRecordsJob job should have been queued for the updated records');
    }

    private class VoidAnswerUpdateItem implements fflib_Answer {
        public Object answer(fflib_InvocationOnMock invocation) {
            List<HeaderRecord__c> headerRecords = (List<HeaderRecord__c>) invocation.getArgument(0);
            fflib_ISObjectUnitOfWork uow = (fflib_ISObjectUnitOfWork) invocation.getArgument(1);
            for (HeaderRecord__c headerRecord : headerRecords) {
                uow.registerUpsert(
                    new ChildRecord__c(
                        Id = fflib_IDGenerator.generate(Schema.ChildRecord__c.SObjectType, HeaderRecord__c = headerRecord.Id)
                    )
                );
            }
            return null; // answer must return something
        }
    }
}
