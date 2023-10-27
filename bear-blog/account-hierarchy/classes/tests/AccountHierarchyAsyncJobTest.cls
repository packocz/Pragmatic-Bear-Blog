@IsTest
public without sharing class AccountHierarchyAsyncJobTest extends AsyncJob {
	public override void handleBatch(List<SObject> scope) {
		update scope;
	}

	public override String toString() {
		return 'AccountHierarchyAsyncJobTest';
	}

	@Future
	public static void reparent(Id accountId, Id newParentId) {
		update new Account(Id = accountId, ParentId = newParentId);
	}
}
