/**
 * Re-usable UoW wrapper class for (Service) methods that need to behave differently
 * regarding committing changes based on the calling context.
 *
 * Supported "contexts" are:
 * - Commit Work: method should commit all changes it produces
 * - Register Work: method should register all changes it produces with provided UoW to be committed later
 * - Update Reference: method should update the provided SObject instance(s) with all changes it produces
 *
 * Assertions are available for methods to ensure they are not called in the context they do not
 * support (e.g. most commonly the Update Reference context is not supported when code would be called
 * in After Trigger execution).
 *
 * If a method supports the Commit Work context it must call commitIfNeeded() method appropriately.
 *
 * example:
 * //service
 * public void myServiceMethod(ListSObject> recordToModify, DmlWork work) {
 *   work.assertNotUpdateReference();  // this method does not support updateReference context
 *   for (SObject record : recordToModify) {
 *     // do some work
 *     serviceConfig.getUow().registerDirty(record);
 *   }
 *   serviceConfig.commitIfNeeded();
 * }
 * //caller
 *  // commit any changes inside `myServiceMethod`
 * service.myServiceMethod(recordsToUpdate, DmlWork.commitWork());
 * // register any changes inside `myServiceMethod` with previously created UoW
 * service.myServiceMethod(recordsToUpdate, DmlWork.registerWork(uow));
 * // update the provided records with any changes inside `myServiceMethod`
 * service.myServiceMethod(recordsToUpdate, DmlWork.updateReference());   //throws exception
 */
public with sharing class DmlWork {
	private enum Option {
		UPDATE_REFERENCE,
		REGISTER_WORK,
		COMMIT_WORK
	}

	private class DmlWorkException extends Exception {
	}

	/**
	 * Class that implements IUnitOfWork but does nothing. Used by the
	 * Update Reference context to avoid need for `uow != null` checks.
	 */
	private class SilentUow implements IUnitOfWork {
		public void registerNew(SObject record) {
		}

		public void registerNew(List<SObject> records) {
		}

		public void registerNew(SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord) {
		}

		public void registerRelationship(SObject record, Schema.SObjectField relatedToField, SObject relatedTo) {
		}

		public void registerRelationship(Messaging.SingleEmailMessage email, SObject relatedTo) {
		}

		public void registerRelationship(
			SObject record,
			Schema.SObjectField relatedToField,
			Schema.SObjectField otherField,
			Object theObject
		) {
		}

		public void registerRelationship() {
		}

		public void registerDirty(SObject record) {
		}

		public void registerDirty(List<SObject> records, List<SObjectField> dirtyFields) {
		}

		public void registerDirty(SObject record, List<SObjectField> dirtyFields) {
		}

		public void registerDirty(SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord) {
		}

		public void registerDirty(List<SObject> records) {
		}

		public void registerEmptyRecycleBin(SObject record) {
		}

		public void registerEmptyRecycleBin(List<SObject> records) {
		}

		public void registerUpsert(SObject record) {
		}

		public void registerUpsert(List<SObject> records) {
		}

		public void registerDeleted(SObject record) {
		}

		public void registerDeleted(List<SObject> records) {
		}

		public void registerPermanentlyDeleted(List<SObject> records) {
		}

		public void registerPermanentlyDeleted(SObject record) {
		}

		public void registerPublishBeforeTransaction(SObject record) {
		}

		public void registerPublishBeforeTransaction(List<SObject> records) {
		}

		public void registerPublishAfterSuccessTransaction(SObject record) {
		}

		public void registerPublishAfterSuccessTransaction(List<SObject> records) {
		}

		public void registerPublishAfterFailureTransaction(SObject record) {
		}

		public void registerPublishAfterFailureTransaction(List<SObject> records) {
		}

		public void commitWork() {
		}

		public void registerWork(fflib_SObjectUnitOfWork.IDoWork work) {
		}

		public void registerEmail(Messaging.Email email) {
		}

		public List<Id> getNewOrUpdatedIds() {
			return null;
		}

		public List<Id> getDeletedIds() {
			return null;
		}

		public List<Id> getNewOrUpdatedIds(List<SObjectType> sObjectTypes) {
			return null;
		}

		public List<Id> getDeletedIds(List<SObjectType> sObjectTypes) {
			return null;
		}
	}

	private IUnitOfWork uow;
	private Option selectedOption;

	private DmlWork(IUnitOfWork uow) {
		this.uow = uow;
	}

	public static DmlWork updateReference() {
		DmlWork config = new DmlWork(new SilentUow());
		config.selectedOption = Option.UPDATE_REFERENCE;
		return config;
	}

	public static DmlWork commitWork() {
		DmlWork config = new DmlWork((IUnitOfWork) ClassFactory.newUnitOfWorkInstance());
		config.selectedOption = Option.COMMIT_WORK;
		return config;
	}

	public static DmlWork registerWork(IUnitOfWork uow) {
		DmlWork config = new DmlWork(uow);
		config.selectedOption = Option.REGISTER_WORK;
		return config;
	}

	public void assertNotUpdateReference() {
		if (this.selectedOption == Option.UPDATE_REFERENCE) {
			throw new DmlWorkException('This method cannot be called when the DmlWork was created with updateReference()');
		}
	}

	public void assertNotRegisterWork() {
		if (this.selectedOption == Option.REGISTER_WORK) {
			throw new DmlWorkException('This method cannot be called when the DmlWork was created with registerWork()');
		}
	}

	public void assertNotCommitWork() {
		if (this.selectedOption == Option.COMMIT_WORK) {
			throw new DmlWorkException('This method cannot be called when the DmlWork was created with commitWork()');
		}
	}

	public IUnitOfWork getUow() {
		return this.uow;
	}

	public void set(SObject record, SObjectField field, Object value) {
		this.set(record, new Map<SObjectField, Object>{ field => value });
	}

	public void set(SObject record, Map<SObjectField, Object> newValues) {
		SObject cloneRecord = record.getSObjectType().newSObject(record.Id);
		for (SObjectField field : newValues.keySet()) {
			Object value = newValues.get(field);
			record.put(field, value);
			cloneRecord.put(field, value);
		}
		this.uow.registerDirty(cloneRecord, new List<SObjectField>(newValues.keySet()));
	}

	public void commitIfNeeded() {
		if (this.selectedOption == Option.COMMIT_WORK) {
			this.uow.commitWork();
		}
	}
}
