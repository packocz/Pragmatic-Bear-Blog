global without sharing class SandboxSetup implements SandboxPostCopy {
	global void runApexClass(SandboxContext context) {
		updateSandboxUserEmailAddresses();
	}

	public static void updateSandboxUserEmailAddresses() {
		Set<Id> userIds = ListUtil.getUniqueIds(
			[SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'ActiveSandboxUser' AND IsActive = TRUE],
			PermissionSetAssignment.AssigneeId
		);
		List<User> activeSandboxUsers = [
			SELECT Id, Alias, Name, UserName, Email
			FROM User
			WHERE Id IN :userIds AND IsActive = TRUE AND Email LIKE '%.invalid'
			LIMIT 200
		];
		for (User activeSandboxUser : activeSandboxUsers) {
			activeSandboxUser.Email = activeSandboxUser.Email.removeEnd('.invalid');
		}
		update activeSandboxUsers;
	}
}
