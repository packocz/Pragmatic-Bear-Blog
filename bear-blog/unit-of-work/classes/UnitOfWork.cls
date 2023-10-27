public inherited sharing class UnitOfWork extends fflib_SObjectUnitOfWork implements IUnitOfWork {
	public UnitOfWork(List<SObjectType> sObjectList) {
		super(sObjectList);
	}

	public List<Id> getNewOrUpdatedIds() {
		List<Id> allNewOrUpdatedIds = new List<Id>();
		for (List<SObject> newRecords : this.m_newListByType.values()) {
			for (Sobject newRecord : newRecords) {
				if (newRecord.Id != null) {
					allNewOrUpdatedIds.add(newRecord.Id);
				}
			}
		}
		for (Map<Id, SObject> updatedRecords : this.m_dirtyMapByType.values()) {
			allNewOrUpdatedIds.addAll(updatedRecords.keySet());
		}
		return allNewOrUpdatedIds;
	}

	public List<Id> getNewOrUpdatedIds(List<SObjectType> objectTypes) {
		List<Id> recordIds = new List<Id>();
		for (SObjectType objectType : objectTypes) {
			String objectName = objectType.getDescribe().getName();
			if (this.m_newListByType.containsKey(objectName)) {
				for (Sobject newRecord : this.m_newListByType.get(objectName)) {
					if (newRecord.Id != null) {
						recordIds.add(newRecord.Id);
					}
				}
			}
			if (this.m_dirtyMapByType.containsKey(objectName)) {
				recordIds.addAll(this.m_dirtyMapByType.get(objectName).keySet());
			}
		}
		return recordIds;
	}
}
