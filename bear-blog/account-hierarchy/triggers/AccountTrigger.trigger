trigger AccountTrigger on Account(after insert, after update, after delete) {
	if (Trigger.isInsert) {
		AccountHierarchyUpdateService.updateAllHierarchyValuesAfterNewChildInsert(Trigger.new);
	} else if (Trigger.isUpdate) {
		AccountHierarchyUpdateService.updateHierarchyValuesAfterUpdate(Trigger.new, Trigger.oldMap);
	} else if (Trigger.isDelete) {
		AccountHierarchyUpdateService.updateRootAccountIdsAfterAccountDelete(Trigger.oldMap);
	}
}
