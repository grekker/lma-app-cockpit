/**
 * Exercises the LmaAppCockpit class.
 */
@IsTest
private class LmaAppCockpitTests {

	@IsTest
	static void testPage() {

		// set up some test records
		Account a = new Account(Name = 'Acme');
		insert a;
		sfLma__Package__c p = new sfLma__Package__c(
			txt_Namespace__c = 'NSB'
		);
		insert p;
		sfLma__Package_Version__c pv = new sfLma__Package_Version__c(
			sfLma__Package__c = p.Id
		);
		insert pv;
		sfLma__License__c l = new sfLma__License__c(
			sfLma__Account__c = a.Id,
			sfLma__Package__c = p.Id,
			sfLma__Package_Version__c = pv.Id,
			sfLma__Subscriber_Org_ID__c = '00D000000000001'
		);
		insert l;

		Messaging.InboundEmail email = new Messaging.InboundEmail();
		email.plainTextBody =
			'Apex script unhandled exception by user/organization: 005500000024uNj/00D000000000001\n\n' +
				'Visualforce Page: /apex/nsB__myPage\n\n' +
				'caused by: System.NullPointerException: Attempt to de-reference a null object\n\n' +
				'Class.NSB.MyController.createSelectOptions: line 143, column 1\n' +
				'Class.NSB.MyController.<init>: line 31, column 1\n' +
				'Class.NSB.MyController.<init>: line 3, column 1\n'
		;

		// fire a test email at our class
		new LmaAppCockpit().handleInboundEmail(email, null);

		// query the results and confirm correct parsing
		System.assertEquals(1, [SELECT COUNT() FROM AppError__c]);
		AppError__c errorRecord = [SELECT txt_UserId__c, txt_OrgId__c, txt_Namespace__c, txt_ExceptionType__c, txt_ExceptionMessage__c,
			lkp_Account__c, txt_ApexClass__c, txt_VisualforcePage__c, txl_Stacktrace__c, lkp_License__c, lkp_Package__c,
			lkp_PackageVersion__c, txt_MatchedWith__c, txl_FullMailBody__c FROM AppError__c];
		System.assertEquals('005500000024uNj', errorRecord.txt_UserId__c);
		System.assertEquals('00D000000000001', errorRecord.txt_OrgId__c);
		System.assertEquals('NSB', errorRecord.txt_Namespace__c);
		System.assertEquals('System.NullPointerException', errorRecord.txt_ExceptionType__c);
		System.assertEquals('Attempt to de-reference a null object', errorRecord.txt_ExceptionMessage__c);
		System.assertEquals('NSB.MyController', errorRecord.txt_ApexClass__c);
		System.assertEquals('myPage', errorRecord.txt_VisualforcePage__c);
		System.assertNotEquals(null, errorRecord.txl_Stacktrace__c);
		System.assertEquals('PageErrorFormat', errorRecord.txt_MatchedWith__c);

		// test LMA linkage
		System.assertEquals(a.Id, errorRecord.lkp_Account__c);
		System.assertEquals(l.Id, errorRecord.lkp_License__c);
		System.assertEquals(p.Id, errorRecord.lkp_Package__c);
		System.assertEquals(pv.Id, errorRecord.lkp_PackageVersion__c);
	}

	@IsTest
	static void testBatch() {
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		email.plainTextBody =
			'Apex script unhandled exception by user/organization: 005500000024uNj/00D000000000001\n\n' +
				'Failed to process batch for class \'NSA.IteratorImpl\' for job id \'7071v0000680gLG\'\n\n' +
				'caused by: System.DmlException: Insert failed. First exception on row 0; first error: STRING_TOO_LONG, Log Status: Datenwert zu groß: Fehler NSA.RetrieveAction.UnsuccessfulCalloutException (max length=80): [Name]\n\n' +
				'Class.NSA.DMLManager.performDMLOperation: line 106, column 1\n' +
				'Class.NSA.DMLManager.insertAsUser: line 35, column 1\n' +
				'Class.NSA.Logger.createErrorLog: line 16, column 1\n' +
				'Class.NSA.RetrieveAction.onError: line 48, column 1\n' +
				'Class.NSA.Executor.execute: line 32, column 1\n' +
				'Class.NSA.IteratorImpl.execute: line 22, column 11\n'
		;

		// fire a test email at our class
		new LmaAppCockpit().handleInboundEmail(email, null);

		// query the results and confirm correct parsing
		System.assertEquals(1, [SELECT COUNT() FROM AppError__c]);
		AppError__c errorRecord = [SELECT txt_UserId__c, txt_OrgId__c, txt_Namespace__c, txt_ExceptionType__c, txt_ExceptionMessage__c,
			lkp_Account__c, txt_ApexClass__c, txt_VisualforcePage__c, txl_Stacktrace__c, lkp_License__c, lkp_Package__c,
			lkp_PackageVersion__c, txt_MatchedWith__c, txl_FullMailBody__c FROM AppError__c];
		System.assertEquals('005500000024uNj', errorRecord.txt_UserId__c);
		System.assertEquals('00D000000000001', errorRecord.txt_OrgId__c);
		System.assertEquals('NSA', errorRecord.txt_Namespace__c);
		System.assertEquals('System.DmlException', errorRecord.txt_ExceptionType__c);
		System.assertEquals('Insert failed. First exception on row 0; first error: STRING_TOO_LONG, Log Status: Datenwert zu groß: Fehler NSA.RetrieveAction.UnsuccessfulCalloutException (max length=80): [Name]', errorRecord.txt_ExceptionMessage__c);
		System.assertEquals('DMLManager', errorRecord.txt_ApexClass__c);
		System.assertEquals(null, errorRecord.txt_VisualforcePage__c);
		System.assertNotEquals(null, errorRecord.txl_Stacktrace__c);
		System.assertEquals('BatchErrorFormat', errorRecord.txt_MatchedWith__c);
	}

	@IsTest
	static void testTrigger() {
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		email.plainTextBody =
			'Apex script unhandled trigger exception by user/organization: 005500000024uNj/00D000000000001\n\n' +
				'NSA.TriggerDelete: execution of BeforeInsert\n\n' +
				'caused by: System.DmlException: Delete failed. First exception on row 0 with id a031t00000RuMxyAAF; first error: ENTITY_IS_DELETED, entity is deleted: []\n\n' +
				'Trigger.NSA.TriggerDelete: line 18, column 1'
		;

		// fire a test email at our class
		new LmaAppCockpit().handleInboundEmail(email, null);

		// query the results and confirm correct parsing
		System.assertEquals(1, [SELECT COUNT() FROM AppError__c]);
		AppError__c errorRecord = [SELECT txt_UserId__c, txt_OrgId__c, txt_Namespace__c, txt_ExceptionType__c, txt_ExceptionMessage__c,
			lkp_Account__c, txt_ApexClass__c, txt_VisualforcePage__c, txl_Stacktrace__c, lkp_License__c, lkp_Package__c,
			lkp_PackageVersion__c, txt_MatchedWith__c, txl_FullMailBody__c FROM AppError__c];
		System.assertEquals('005500000024uNj', errorRecord.txt_UserId__c);
		System.assertEquals('00D000000000001', errorRecord.txt_OrgId__c);
		System.assertEquals('NSA', errorRecord.txt_Namespace__c);
		System.assertEquals('System.DmlException', errorRecord.txt_ExceptionType__c);
		System.assertEquals('Delete failed. First exception on row 0 with id a031t00000RuMxyAAF; first error: ENTITY_IS_DELETED, entity is deleted: []', errorRecord.txt_ExceptionMessage__c);
		System.assertEquals('TriggerDelete', errorRecord.txt_ApexClass__c);
		System.assertEquals(null, errorRecord.txt_VisualforcePage__c);
		System.assertEquals('TriggerErrorFormat', errorRecord.txt_MatchedWith__c);
	}

	@IsTest
	static void testMismatch() {

		Messaging.InboundEmail email = new Messaging.InboundEmail();
		email.plainTextBody = '<bad data>';

		// fire a test email at our class
		new LmaAppCockpit().handleInboundEmail(email, null);

		// query the results and confirm correct parsing
		System.assertEquals(0, [SELECT COUNT() FROM AppError__c]);
	}
}