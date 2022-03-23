public inherited sharing class AccountSelector {
	public static AccountSelector newInstance() {
		//To be covered another day
		//return (AccountSelector) ClassFactory.newInstance(AccountSelector.class);
		return new AccountSelector();
	}

	protected String fieldsString;

	public AccountSelector() {
		this.fieldsString = getFieldsString();
	}

	public List<Account> selectById(Set<Id> accountIds) {
		String query = String.format(
			'SELECT {0} FROM Account WHERE Id IN :accountIds WITH SECURITY_ENFORCED ORDER BY Name',
			new List<String>{ this.fieldsString }
		);
		return (List<Account>) Database.query(query);
	}

	public List<Account> selectByParentId(Set<Id> parentIds) {
		String query = String.format(
			'SELECT {0} FROM Account WHERE ParentId IN :parentIds WITH SECURITY_ENFORCED ORDER BY ParentId, Name',
			new List<String>{ this.fieldsString }
		);
		return (List<Account>) Database.query(query);
	}

	public List<Account> selectByRootAccountId(Set<Id> rootAccountIds) {
		String query = String.format(
			'SELECT {0} FROM Account WHERE RootAccountId__c IN :rootAccountIds WITH SECURITY_ENFORCED ORDER BY RootAccountId__c, Name',
			new List<String>{ this.fieldsString }
		);
		return (List<Account>) Database.query(query);
	}

	public List<Account> selectByName(Set<String> names) {
		String query = String.format(
			'SELECT {0} FROM Account WHERE Name IN :names WITH SECURITY_ENFORCED ORDER BY Name',
			new List<String>{ this.fieldsString }
		);
		return (List<Account>) Database.query(query);
	}

	public List<Account> selectByNameNot(Set<String> names) {
		String query = String.format(
			'SELECT {0} FROM Account WHERE Name NOT IN :names WITH SECURITY_ENFORCED ORDER BY Name',
			new List<String>{ this.fieldsString }
		);
		return (List<Account>) Database.query(query);
	}

	public List<Account> selectByNameLike(String nameFilter) {
		String query = String.format(
			'SELECT {0} FROM Account WHERE Name LIKE :nameFilter WITH SECURITY_ENFORCED ORDER BY Name',
			new List<String>{ this.fieldsString }
		);
		return (List<Account>) Database.query(query);
	}

	public List<Account> selectByNameNotLike(String nameFilter) {
		String query = String.format(
			'SELECT {0} FROM Account WHERE NOT Name LIKE :nameFilter WITH SECURITY_ENFORCED ORDER BY Name',
			new List<String>{ this.fieldsString }
		);
		return (List<Account>) Database.query(query);
	}

	private String getFieldsString() {
		String fieldsString = '';
		for (Schema.SObjectField field : getSObjectFieldList()) {
			fieldsString += field.getDescribe().getName() + ', ';
		}
		return fieldsString.removeEnd(', ');
	}

	private List<Schema.SObjectField> getSObjectFieldList() {
		return new List<Schema.SObjectField>{
			Account.Id,
			Account.ParentId,
			Account.RootAccountId__c,
			Account.Name,
			Account.Classification__c,
			Account.Priority__c
		};
	}
}
