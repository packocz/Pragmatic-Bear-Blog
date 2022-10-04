public with sharing class OpportunityCachedSelector extends OpportunitySelector {
	public override List<Opportunity> selectById(Set<Id> ids) {
		return ((RecordCache) OpportunityCache.getOpportunityCache(
				RecordCacheStaticVariable.class,
				RecordCacheProvider.newInstance(this, OpportunityByIdProvider.class)
			))
			.getRecords(ids);
	}

	public override Map<Id, List<Opportunity>> selectByAccountId(Set<Id> accountIds) {
		return ((RecordCache) OpportunityCache.getOpportunityCache(
				RecordCacheStaticVariable.class,
				RecordCacheProvider.newInstance(this, OpportunityByAccountIdProvider.class)
			))
			.getRecordsMap(accountIds);
	}

	private List<Opportunity> selectByIdSuper(Set<Id> ids) {
		return super.selectById(ids);
	}

	private Map<Id, List<SObject>> selectByAccountIdSuper(Set<Id> ids) {
		return super.selectByAccountId(ids);
	}

	private class OpportunityByIdProvider extends RecordCacheProvider {
		public override List<SObject> fetchRecords(Set<Id> keys) {
			OpportunityCachedSelector selector = (OpportunityCachedSelector) this.s;
			return selector.selectByIdSuper(keys);
		}

		public override SObjectField getKeyField() {
			return Schema.Opportunity.Id;
		}
	}

	private class OpportunityByAccountIdProvider extends RecordCacheProvider {
		public override Map<Id, List<SObject>> fetchRecordsMap(Set<Id> keys) {
			OpportunityCachedSelector selector = (OpportunityCachedSelector) this.s;
			return selector.selectByAccountIdSuper(keys);
		}

		public override SObjectField getKeyField() {
			return Schema.Opportunity.AccountId;
		}
	}
}
