/*
MIT License

Copyright (c) 2019 logicline GmbH

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

/**
 * Adapted from https://github.com/logiclinegmbh/lma-app-cockpit in order to
 * reduce the clutter and keep it simple.
 */
public with sharing class LmaAppCockpit implements Messaging.InboundEmailHandler {

	private static final List<ErrorFormat> FORMATS = new List<ErrorFormat>{
		new PageErrorFormat(),
		new TriggerErrorFormat(),
		new BatchErrorFormat()
	};

	/*
	 * Receive an error email from the outside world. This is the start of our logic chain.
	 */
	public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail mail, Messaging.InboundEnvelope envelope) {
		parseIncoming(mail.plainTextBody);
		return new Messaging.InboundEmailResult();
	}

	/*
	 * Attempt to interpret the error email body. To do this we iterate through our known parsers,
	 * hoping that one of them will recognize how to interpret the email body.
	 */
	private void parseIncoming(String body) {
		for(ErrorFormat parser : FORMATS) {
			AppError__c errorRecord = parser.parse(body);
			if(errorRecord != null) {
				linkToLma(errorRecord);
				insert errorRecord;
				break;
			}
		}
	}

	private void linkToLma(AppError__c error) {
		for(sfLma__License__c license : [
			SELECT sfLma__Package__c, sfLma__Package_Version__c, sfLma__Account__c
			FROM sflma__License__c
			WHERE sfLma__Subscriber_Org_ID__c = :error.txt_OrgId__c
			AND sfLma__Package__r.txt_Namespace__c = :error.txt_Namespace__c
		]) {
			error.lkp_License__c = license.Id;
			error.lkp_Package__c = license.sfLma__Package__c;
			error.lkp_PackageVersion__c = license.sfLma__Package_Version__c;
			error.lkp_Account__c = license.sfLma__Account__c;
		}
	}

	/**
	 * Defines expected behavior for any of our individual parsers that can interpret certain error shapes.
	 */
	private interface ErrorFormat {
		AppError__c parse(String body);
	}

	private class BatchErrorFormat implements ErrorFormat {
		public AppError__c parse(String body) {
			Matcher matcher = Pattern.compile(
				'(005[A-Za-z0-9]{12})/(00D[A-Za-z0-9]{12})' +
					'[\\s\\S]+' +
					'caused by: (([^:]+):(.+))' +
					'[\\s]+' +
					'(Class\\.(([^\\.]+)\\.([^\\.:]+))([\\S|\\s]+))'
			).matcher(body);
			if(matcher.find()) {
				return new AppError__c(
					txt_MatchedWith__c = 'BatchErrorFormat',
					txl_FullMailBody__c = body,
					txt_UserId__c = matcher.group(1),
					txt_OrgId__c = matcher.group(2),
					txt_ExceptionType__c = matcher.group(4),
					txt_ExceptionMessage__c = matcher.group(5),
					txl_Stacktrace__c = matcher.group(6),
					txt_Namespace__c = matcher.group(8),
					txt_ApexClass__c = matcher.group(9)
				);
			}
			else {
				return null;
			}
		}
	}

	private class PageErrorFormat implements ErrorFormat {
		public AppError__c parse(String body) {
			Matcher matcher = Pattern.compile(
				'(005[A-Za-z0-9]{12})/(00D[A-Za-z0-9]{12})' +
					'[\\s]+' +
					'.+/apex/(.+)__(.+)' +
					'[\\s]+' +
					'caused by: (([^:]+):(.+))' +
					'[\\s]+' +
					'(Class\\.((.+)\\.([^:]+)([\\S\\s]+)))'
			).matcher(body);
			if(matcher.find()) {
				return new AppError__c(
					txt_MatchedWith__c = 'PageErrorFormat',
					txl_FullMailBody__c = body,
					txt_UserId__c = matcher.group(1),
					txt_OrgId__c = matcher.group(2),
					txt_Namespace__c = matcher.group(3).toUpperCase(),
					txt_VisualforcePage__c = matcher.group(4),
					txt_ExceptionType__c = matcher.group(6),
					txt_ExceptionMessage__c = matcher.group(7),
					txl_Stacktrace__c = matcher.group(8),
					txt_ApexClass__c = matcher.group(10)
				);
			}
			else {
				return null;
			}
		}
	}

	private class TriggerErrorFormat implements ErrorFormat {
		public AppError__c parse(String body) {
			Matcher matcher = Pattern.compile(
				'(005[A-Za-z0-9]{12})/(00D[A-Za-z0-9]{12})' +
					'[\\s\\S]+' +
					'caused by: (([^:]+):(.+))' +
					'[\\s]+' +
					'(Trigger\\.((.+)\\.([^:]+)([\\S\\s]+)))'
			).matcher(body);
			if(matcher.find()) {
				return new AppError__c(
					txt_MatchedWith__c = 'TriggerErrorFormat',
					txl_FullMailBody__c = body,
					txt_UserId__c = matcher.group(1),
					txt_OrgId__c = matcher.group(2),
					txt_ExceptionType__c = matcher.group(4),
					txt_ExceptionMessage__c = matcher.group(5),
					txl_Stacktrace__c = matcher.group(6),
					txt_Namespace__c = matcher.group(8),
					txt_ApexClass__c = matcher.group(9)
				);
			}
			else {
				return null;
			}
		}
	}
}