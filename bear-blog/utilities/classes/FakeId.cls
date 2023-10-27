public with sharing class FakeId {
	static Integer counter = 1;

	public static String build(Schema.SObjectType sot) {
		return buildFakeId(sot, 18);
	}

	public static String build15chars(Schema.SObjectType sot) {
		return buildFakeId(sot, 15);
	}

	private static String buildFakeId(Schema.SObjectType sot, Integer length) {
		String numberString = String.valueOf(counter++);
		String prefix = sot.getDescribe().getKeyPrefix();
		System.debug(prefix);
		return prefix + '0'.repeat(length - prefix.length() - numberString.length()) + numberString;
	}
}
