public virtual with sharing class OpportunitySelector extends Selector {
	public virtual List<Opportunity> selectById(Set<Id> ids) {
		return [SELECT Id, Name, AccountId, Amount, StageName FROM Opportunity WHERE Id IN :ids];
	}

	public virtual Map<Id, List<Opportunity>> selectByAccountId(Set<Id> accountIds) {
		return (Map<Id, List<Opportunity>>) ListUtil.mapToListById(
			[SELECT Id, Name, AccountId, Amount, StageName FROM Opportunity WHERE AccountId IN :accountIds],
			Schema.Opportunity.AccountId
		);
	}
}
