trigger OpportunityCacheResetTrigger on Opportunity(before update, before delete) {
	OpportunityCache.removeBasedOnTriggerContext(Trigger.isDelete ? Trigger.oldMap : Trigger.newMap);
}
