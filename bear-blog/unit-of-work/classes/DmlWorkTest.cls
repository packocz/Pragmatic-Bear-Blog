@IsTest
private class DmlWorkTest {
	private static Lead testLead = new Lead(Company = 'Test', LastName = 'Name', FirstName = 'name');

	@IsTest
	static void registerWorkDoesNotCommit() {
		DmlWork work = DmlWork.registerWork((IUnitOfWork) ClassFactory.newUnitOfWorkInstance());
		work.getUow().registerNew(testLead);
		work.commitIfNeeded();
		Assert.isTrue([SELECT Id FROM Lead].isEmpty(), 'No Lead should insert');
	}

	@IsTest
	static void commitWorkDoesCommit() {
		DmlWork work = DmlWork.commitWork();
		work.getUow().registerNew(testLead);
		work.commitIfNeeded();
		Assert.isFalse([SELECT Id FROM Lead].isEmpty(), 'Lead should have inserted');
	}

	@IsTest
	static void setSupportsRegisterWork() {
		insert testLead;

		IUnitOfWork uow = (IUnitOfWork) ClassFactory.newUnitOfWorkInstance();
		DmlWork work = DmlWork.registerWork(uow);
		work.set(testLead, Lead.Company, 'New Company');
		uow.commitWork();

		Assert.areEqual('New Company', [SELECT Company FROM Lead].Company, 'Lead Company should have been updated');
	}

	@IsTest
	static void setSupportsCommitWork() {
		insert testLead;

		DmlWork work = DmlWork.commitWork();
		work.set(testLead, Lead.Company, 'New Company');
		work.commitIfNeeded();

		Assert.areEqual('New Company', [SELECT Company FROM Lead].Company, 'Lead Company should have been updated');
	}

	@IsTest
	static void setSupportsUpdateReference() {
		DmlWork work = DmlWork.updateReference();
		work.set(testLead, Lead.Company, 'New Company');

		Assert.areEqual('New Company', testLead.Company, 'Lead Company should have been updated');
	}

	@IsTest
	static void assertCommitWorkIsNotUpdateReference() {
		try {
			DmlWork.commitWork().assertNotUpdateReference();
		} catch (DmlWork.DmlWorkException e) {
			Assert.fail('Should not throw exception, Commit Work is not Update Reference');
		}
	}

	@IsTest
	static void assertRegisterWorkIsNotUpdateReference() {
		try {
			DmlWork.registerWOrk((IUnitOfWork) ClassFactory.newUnitOfWorkInstance()).assertNotUpdateReference();
		} catch (DmlWork.DmlWorkException e) {
			Assert.fail('Should not throw exception, Register Changes is not Update Reference');
		}
	}

	@IsTest
	static void assertUpdateReferenceFailsIsNotUpdateReference() {
		try {
			DmlWork.updateReference().assertNotUpdateReference();
			Assert.fail('Should throw exception');
		} catch (DmlWork.DmlWorkException e) {
			System.debug(LoggingLevel.FINE, 'Correct');
		}
	}

	@IsTest
	static void assertCommitWorkIsNotRegisterWork() {
		try {
			DmlWork.commitWork().assertNotRegisterWork();
		} catch (DmlWork.DmlWorkException e) {
			Assert.fail('Should not throw exception, Commit Work is not Register Work');
		}
	}

	@IsTest
	static void assertUpdateReferenceIsNotRegisterWork() {
		try {
			DmlWork.updateReference().assertNotRegisterWork();
		} catch (DmlWork.DmlWorkException e) {
			Assert.fail('Should not throw exception, Update Reference is not Register Work');
		}
	}

	@IsTest
	static void assertRegisterWorkFailsIsNotRegisterWork() {
		try {
			DmlWork.registerWork((IUnitOfWork) ClassFactory.newUnitOfWorkInstance()).assertNotRegisterWork();
			Assert.fail('Should throw exception');
		} catch (DmlWork.DmlWorkException e) {
			System.debug(LoggingLevel.FINE, 'Correct');
		}
	}

	@IsTest
	static void assertCommitWorkFailsIsNotCommitWork() {
		try {
			DmlWork.commitWork().assertNotCommitWork();
			Assert.fail('Should throw exception');
		} catch (DmlWork.DmlWorkException e) {
			System.debug(LoggingLevel.FINE, 'Correct');
		}
	}

	@IsTest
	static void assertUpdateReferenceIsNotCommitWork() {
		try {
			DmlWork.updateReference().assertNotCommitWork();
		} catch (DmlWork.DmlWorkException e) {
			Assert.fail('Should not throw exception, Update Reference is not Commit Work');
		}
	}

	@IsTest
	static void assertRegisterWorkIsNotCommitWork() {
		try {
			DmlWork.registerWork((IUnitOfWork) ClassFactory.newUnitOfWorkInstance()).assertNotCommitWork();
		} catch (DmlWork.DmlWorkException e) {
			Assert.fail('Should not throw exception, Register Work is not Commit Work');
		}
	}
}
