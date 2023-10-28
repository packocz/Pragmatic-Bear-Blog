@IsTest
private class UOWRegisterDirtyTest {
	@IsTest
	static void registerRecordMultipleTimesLastRegisterWins() {
		Account originalAccount = new Account(Name = 'Original Name', Description = 'Original Description');
		insert originalAccount;

		fflib_SObjectUnitOfWork uow = newUow();
		Account firstUpdateName = originalAccount.clone(true, true, true, true);
		firstUpdateName.Name = 'New Name';
		uow.registerDirty(firstUpdateName);

		Account thenUpdateDescription = originalAccount.clone(true, true, true, true);
		thenUpdateDescription.Description = 'New Description';
		uow.registerDirty(thenUpdateDescription);

		uow.commitWork();

		Account committedChanges = [SELECT Id, Name, Description FROM Account WHERE Id = :originalAccount.Id];
		Assert.areEqual(firstUpdateName.Name, committedChanges.Name, 'I wanted Name to update: ' + committedChanges);
		Assert.areEqual(
			thenUpdateDescription.Description,
			committedChanges.Description,
			'I wanted Description to update: ' + committedChanges
		);
	}

	@IsTest
	static void registerRecordMultipleTimesSpecifyUpdatedFields() {
		Account originalAccount = new Account(Name = 'Original Name', Description = 'Original Description');
		insert originalAccount;

		fflib_SObjectUnitOfWork uow = newUow();
		Account firstUpdateName = originalAccount.clone(true, true, true, true);
		firstUpdateName.Name = 'New Name';
		uow.registerDirty(firstUpdateName, new List<SObjectField>{ Account.Name });

		Account thenUpdateDescription = originalAccount.clone(true, true, true, true);
		thenUpdateDescription.Description = 'New Description';
		uow.registerDirty(thenUpdateDescription, new List<SObjectField>{ Account.Description });

		uow.commitWork();

		Account committedChanges = [SELECT Id, Name, Description FROM Account WHERE Id = :originalAccount.Id];
		Assert.areEqual(firstUpdateName.Name, committedChanges.Name, 'I wanted Name to update: ' + committedChanges);
		Assert.areEqual(
			thenUpdateDescription.Description,
			committedChanges.Description,
			'I wanted Description to update: ' + committedChanges
		);
	}

	@IsTest
	static void registerRecordWithUpdatedFieldsOnlySecondRegisterlOverwritesOriginal() {
		Account originalAccount = new Account(Name = 'Original Name', Description = 'Original Description');
		insert originalAccount;

		fflib_SObjectUnitOfWork uow = newUow();
		Account firstUpdateName = new Account(Id = originalAccount.Id, Name = 'New Name');
		uow.registerDirty(firstUpdateName);

		Account thenUpdateDescription = new Account(Id = originalAccount.Id, Description = 'New Description');
		uow.registerDirty(thenUpdateDescription);

		uow.commitWork();

		Account committedChanges = [SELECT Id, Name, Description FROM Account WHERE Id = :originalAccount.Id];
		Assert.areEqual(firstUpdateName.Name, committedChanges.Name, 'I wanted Name to update: ' + committedChanges);
		Assert.areEqual(
			thenUpdateDescription.Description,
			committedChanges.Description,
			'I wanted Description to update: ' + committedChanges
		);
	}

	@IsTest
	static void registerRecordWithUpdatedFieldsOnlySpecifyUpdatedFields() {
		Account originalAccount = new Account(Name = 'Original Name', Description = 'Original Description');
		insert originalAccount;

		fflib_SObjectUnitOfWork uow = newUow();
		Account firstUpdateName = new Account(Id = originalAccount.Id, Name = 'New Name');
		uow.registerDirty(firstUpdateName, new List<SObjectField>{ Account.Name });

		Account thenUpdateDescription = new Account(Id = originalAccount.Id, Description = 'New Description');
		uow.registerDirty(thenUpdateDescription, new List<SObjectField>{ Account.Description });

		uow.commitWork();

		Account committedChanges = [SELECT Id, Name, Description FROM Account WHERE Id = :originalAccount.Id];
		Assert.areEqual(firstUpdateName.Name, committedChanges.Name, 'I wanted Name to update: ' + committedChanges);
		Assert.areEqual(
			thenUpdateDescription.Description,
			committedChanges.Description,
			'I wanted Description to update: ' + committedChanges
		);
	}

	@IsTest
	static void registerRecordThenChangeTheInstanceModifiesRegisteredChange() {
		Account originalAccount = new Account(Name = 'Original Name', Description = 'Original Description');
		insert originalAccount;

		fflib_SObjectUnitOfWork uow = newUow();
		originalAccount.Name = 'New Name';
		uow.registerDirty(originalAccount);

		originalAccount.Name = 'Unregistered Name Change';
		//this time no register call

		uow.commitWork();

		Account committedChanges = [SELECT Id, Name FROM Account WHERE Id = :originalAccount.Id];
		Assert.areEqual('New Name', committedChanges.Name, 'I wanted Name to update: ' + committedChanges);
	}

	@IsTest
	static void registerRecordThenChangePasedByReferenceInstanceModifiesRegisteredChange() {
		Account originalAccount = new Account(Name = 'Original Name', Description = 'Original Description');
		insert originalAccount;

		fflib_SObjectUnitOfWork uow = newUow();
		Account updatedRegisteredPassedByReferenceAccount = originalAccount; //as if passed into a method via arg
		updatedRegisteredPassedByReferenceAccount.Name = 'New Name';
		uow.registerDirty(updatedRegisteredPassedByReferenceAccount);

		Account notRegisteredPassedByReferenceAccount = originalAccount; //as if passed into another method via arg
		notRegisteredPassedByReferenceAccount.Name = 'Unregistered Name Change';
		//this time no register call

		uow.commitWork();

		Account committedChanges = [SELECT Id, Name FROM Account WHERE Id = :originalAccount.Id];
		Assert.areEqual('New Name', committedChanges.Name, 'I wanted Name to update: ' + committedChanges);
	}

	@IsTest
	static void registerRecordSpecifyUpdatedFieldsThenChangePassedByReferenceInstanceModifiesRegisteredChange() {
		Account originalAccount = new Account(Name = 'Original Name', Description = 'Original Description');
		insert originalAccount;

		fflib_SObjectUnitOfWork uow = newUow();
		Account updatedRegisteredPassedByReferenceAccount = originalAccount; //as if passed into a method via arg
		updatedRegisteredPassedByReferenceAccount.Name = 'New Name';
		uow.registerDirty(updatedRegisteredPassedByReferenceAccount, new List<SObjectField>{ Account.Name });

		Account notRegisteredPassedByReferenceAccount = originalAccount; //as if passed into another method via arg
		notRegisteredPassedByReferenceAccount.Name = 'Unregistered Name Change';
		//this time no register call

		uow.commitWork();

		Account committedChanges = [SELECT Id, Name FROM Account WHERE Id = :originalAccount.Id];
		Assert.areEqual('New Name', committedChanges.Name, 'I wanted Name to update: ' + committedChanges);
	}

	@IsTest
	static void registerAsNewClonedRecordThenChangeOrignalReferenceDoesNotAffectRegisteredChange() {
		Account originalAccount = new Account(Name = 'Original Name', Description = 'Original Description');
		insert originalAccount;

		fflib_SObjectUnitOfWork uow = newUow();
		Account updatedNewInstanceAccount = new Account(Id = originalAccount.Id, Name = 'New Name'); //not passed by reference
		uow.registerDirty(updatedNewInstanceAccount);

		Account notRegisteredPassedByReferenceAccount = originalAccount; //as if passed into another method via arg
		notRegisteredPassedByReferenceAccount.Name = 'Unregistered Name Change';
		//this time no register call

		uow.commitWork();

		Account committedChanges = [SELECT Id, Name FROM Account WHERE Id = :originalAccount.Id];
		Assert.areEqual('New Name', committedChanges.Name, 'I wanted Name to update: ' + committedChanges);
	}

	@IsTest
	static void registerAsNewClonedRecordSpecifyUpdatedFieldsThenChangeOrignalReferenceDoesNotAffectRegisteredChange() {
		Account originalAccount = new Account(Name = 'Original Name', Description = 'Original Description');
		insert originalAccount;

		fflib_SObjectUnitOfWork uow = newUow();
		Account updatedNewInstanceAccount = new Account(Id = originalAccount.Id, Name = 'New Name'); //not passed by reference
		uow.registerDirty(updatedNewInstanceAccount, new List<SObjectField>{ Account.Name });

		Account notRegisteredPassedByReferenceAccount = originalAccount; //as if passed into another method via arg
		notRegisteredPassedByReferenceAccount.Name = 'Unregistered Name Change';
		//this time no register call

		uow.commitWork();

		Account committedChanges = [SELECT Id, Name FROM Account WHERE Id = :originalAccount.Id];
		Assert.areEqual('New Name', committedChanges.Name, 'I wanted Name to update: ' + committedChanges);
	}

	static fflib_SObjectUnitOfWork newUow() {
		return new fflib_SObjectUnitOfWork(new List<SObjectType>{ Account.SObjectType });
	}
}
