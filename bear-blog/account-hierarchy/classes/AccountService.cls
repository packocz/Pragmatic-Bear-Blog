public with sharing class AccountService {
	public static AccountService newInstance() {
		//To be covered another day
		//return (AccountService) ClassFactory.newInstance(AccountService.class);
		return new AccountService();
	}

	private static final Integer MAX_RECURSION_LEVEL = 10;

	/**
	 * Will exclude all provided parentAccounts from the result, even if they are a child of another
	 * provided parent Account
	 */
	public List<Account> findAllChildAccounts(List<Account> parentAccounts) {
		return findAllChildAccounts(parentAccounts, new Set<Id>(), 0);
	}

	private List<Account> findAllChildAccounts(List<Account> parentAccounts, Set<Id> rememberedParentIds, Integer level) {
		Set<Id> parentAccountIds = ListUtil.getUniqueIds(parentAccounts, Account.Id);
		List<Account> childAccounts = AccountSelector.newInstance().selectByParentId(parentAccountIds);
		rememberedParentIds.addAll(parentAccountIds);
		List<Account> uniqueChildAccounts = ListUtil.filter(childAccounts, Account.Id, rememberedParentIds);
		if (!uniqueChildAccounts.isEmpty() && level < MAX_RECURSION_LEVEL) {
			uniqueChildAccounts.addAll(findAllChildAccounts(uniqueChildAccounts, rememberedParentIds, level++));
		}
		return uniqueChildAccounts;
	}
}
