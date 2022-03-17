@IsTest
private class FakeIdTest {
	@IsTest
	static void testBuildId() {
		System.assert(String.valueOf(FakeId.build(Account.getSObjectType())).startsWith('001'), 'Fake Id should be Account specific');
		System.assert(String.valueOf(FakeId.build15chars(Case.getSObjectType())).startsWith('500'), 'Fake Id should be Case specific');
		System.assertEquals(18, String.valueOf(FakeId.build(Case.getSObjectType())).length(), 'Generated Id shoudl have 18 chars');
		System.assertEquals(
			15,
			String.valueOf(FakeId.build15chars(Opportunity.getSObjectType())).length(),
			'Generated Id shoudl have 15 chars'
		);

		for (Integer i = 0; i < 101; i++) {
			FakeId.build(Account.getSObjectType());
		}

		System.assertEquals(18, String.valueOf(FakeId.build(Case.getSObjectType())).length(), 'Generated Id shoudl have 18 chars');
		System.assertEquals(
			15,
			String.valueOf(FakeId.build15chars(Opportunity.getSObjectType())).length(),
			'Generated Id shoudl have 15 chars'
		);
	}
}
