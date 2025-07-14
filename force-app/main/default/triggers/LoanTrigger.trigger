/*********************************************************************************************
 *  Date:   14July25
 *  Author: James Hodson
 *  Desc:   Intercepts database operations on the Loan obejct and calls the LoanTriggerHandler.
 * *******************************************************************************************/
trigger LoanTrigger on Loan__c (after insert, after update) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            LoanTriggerHandler.handleAfterInsert(Trigger.new);
        }
        
        if (Trigger.isUpdate) {
            LoanTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}