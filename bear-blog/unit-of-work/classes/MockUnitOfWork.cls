public with sharing class MockUnitOfWork implements IUnitOfWork {
    public Map<Id, SObject> insertedRecords = new Map<Id, SObject>();
    public Map<Id, SObject> updatedRecords = new Map<Id, SObject>();
    public Map<Id, SObject> deletedRecords = new Map<Id, SObject>();

    public List<SObject> registeredInsertedRecords = new List<SObject>();
    public Map<Id, SObject> registeredUpdatedRecords = new Map<Id, SObject>();
    public Map<Id, SObject> registeredDeletedRecords = new Map<Id, SObject>();

    public void registerNew(SObject record) {
        this.registeredInsertedRecords.add(record.clone(true, true, true, true));
    }

    public void registerNew(List<SObject> records) {
        for (SObject o : records) {
            registerNew(o);
        }
    }

    public void registerNew(SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerRelationship(SObject record, Schema.SObjectField relatedToField, SObject relatedTo) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerRelationship(Messaging.SingleEmailMessage email, SObject relatedTo) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerRelationship(
        SObject record,
        Schema.SObjectField relatedToField,
        Schema.SObjectField externalIdField,
        Object externalId
    ) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerDirty(SObject record) {
        this.registeredUpdatedRecords.put(record.Id, record.clone(true, true, true, true));
    }

    public void registerDirty(List<SObject> records, List<SObjectField> dirtyFields) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerDirty(SObject record, List<SObjectField> dirtyFields) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerDirty(SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerDirty(List<SObject> records) {
        for (SObject o : records) {
            registerDirty(o);
        }
    }

    public void registerEmptyRecycleBin(SObject record) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerEmptyRecycleBin(List<SObject> records) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerUpsert(SObject record) {
        if (record.Id == null) {
            registerNew(record);
        } else {
            registerDirty(record);
        }
    }

    public void registerUpsert(List<SObject> records) {
        for (SObject o : records) {
            registerUpsert(o);
        }
    }

    public void registerDeleted(SObject record) {
        this.registeredDeletedRecords.put(record.Id, record);
    }

    public void registerDeleted(List<SObject> records) {
        for (SObject o : records) {
            registerDeleted(o);
        }
    }

    public void registerPermanentlyDeleted(List<SObject> records) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerPermanentlyDeleted(SObject record) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerPublishBeforeTransaction(SObject record) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerPublishBeforeTransaction(List<SObject> records) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerPublishAfterSuccessTransaction(SObject record) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerPublishAfterSuccessTransaction(List<SObject> records) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerPublishAfterFailureTransaction(SObject record) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerPublishAfterFailureTransaction(List<SObject> records) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void commitWork() {
        for (SObject o : this.registeredInsertedRecords) {
            o.Id = TestUtilities.getFakeId(o.getSObjectType());
            this.insertedRecords.put(o.Id, o);
        }
        this.registeredInsertedRecords.clear();
        this.updatedRecords.putAll(registeredUpdatedRecords);
        this.registeredUpdatedRecords.clear();
        this.deletedRecords.putAll(registeredDeletedRecords);
        this.registeredDeletedRecords.clear();
    }

    public void registerWork(fflib_SObjectUnitOfWork.IDoWork work) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public void registerEmail(Messaging.Email email) {
        throw new MockUnitOfWorkException('Not yet implemented!');
    }

    public List<Id> getNewOrUpdatedIds() {
        Set<Id> ids = this.insertedRecords.keySet();
        ids.addAll(this.updatedRecords.keySet());
        ids.remove(null);
        return new List<Id>(ids);
    }

    public List<Id> getNewOrUpdatedIds(List<SObjectType> objectTypes) {
        Set<SObjectType> neededTypes = new Set<SObjectType>(objectTypes);
        List<Id> newOrUpdatedIds = new List<Id>();
        List<SObject> newOrUpdatedRecords = new List<SObject>(this.insertedRecords.values());
        newOrUpdatedRecords.addAll(this.updatedRecords.values());
        for (SObject insertedRecord : newOrUpdatedRecords) {
            if (neededTypes.contains(insertedRecord.getSObjectType())) {
                if (insertedRecord.Id != null) {
                    newOrUpdatedIds.add(insertedRecord.Id);
                }
            }
        }
        return newOrUpdatedIds;
    }

    public class MockUnitOfWorkException extends Exception {
    }
}
