/***********************************************************************************************************
 *  Date:   14July25
 *  Author: James Hodson
 *  Desc:   Handler class containing business logic for processing Loan Charge records.
 * *********************************************************************************************************/
public with sharing class LoanChargeTriggerHandler {
    
    // Before inserting, assign the processing order and validate the release charge.
    public static void handleBeforeInsert(List<Loan_Charge__c> newCharges) {
        // Assign processing order based on charge type
        LoanChargeService.assignProcessingOrder(newCharges);
        
        // Validate release charge constraints
        LoanChargeService.validateReleaseCharges(newCharges);
    }
    
    // Before updating, check the processing order of the loan charge to make sure the Admin Fee is processed and applied before the Interest Charge.
    public static void handleBeforeUpdate(List<Loan_Charge__c> newCharges, Map<Id, Loan_Charge__c> oldChargeMap) {
        List<Loan_Charge__c> chargesWithTypeChanges = new List<Loan_Charge__c>();
        
        // Check if charge type changed (which would affect processing order)
        for (Loan_Charge__c charge : newCharges) {
            Loan_Charge__c oldCharge = oldChargeMap.get(charge.Id);
            if (charge.Charge_Type__c != oldCharge.Charge_Type__c) {
                chargesWithTypeChanges.add(charge);
            }
        }
        
        if (!chargesWithTypeChanges.isEmpty()) {
            // Reassign processing order for charges with type changes
            LoanChargeService.assignProcessingOrder(chargesWithTypeChanges);
        }
    }
    
    // After insert, check if new charge date is on or after release charge date, extend release charge by one month and update loan balance.
    public static void handleAfterInsert(List<Loan_Charge__c> newCharges) {
        LoanChargeService.handleReleaseChargeAdjustments(newCharges);
        updateLoanBalancesFromCharges(newCharges);
    }
    
    // After update, check each new charge and check if it is the same as the old amount. If not update the loan balance.
    public static void handleAfterUpdate(List<Loan_Charge__c> newCharges, Map<Id, Loan_Charge__c> oldChargeMap) {
        List<Loan_Charge__c> chargesWithAmountChanges = new List<Loan_Charge__c>();
        
        for (Loan_Charge__c charge : newCharges) {
            Loan_Charge__c oldCharge = oldChargeMap.get(charge.Id);
            if (charge.Amount__c != oldCharge.Amount__c) {
                chargesWithAmountChanges.add(charge);
            }
        }
        
        if (!chargesWithAmountChanges.isEmpty()) {
            updateLoanBalancesFromCharges(chargesWithAmountChanges);
        }
    }
    
    // Update the loan balance after a deleted loan charge.
    public static void handleAfterDelete(List<Loan_Charge__c> deletedCharges) {
        updateLoanBalancesFromCharges(deletedCharges);
    }
    
    // Get the loan id's from the loan charges, if it is not empty, send the loans to update the balance. 
    private static void updateLoanBalancesFromCharges(List<Loan_Charge__c> charges) {
        Set<Id> loanIds = new Set<Id>();
        for (Loan_Charge__c charge : charges) {
            loanIds.add(charge.Loan__c);
        }
        
        if (!loanIds.isEmpty()) {
            List<Loan__c> loansToUpdate = [SELECT Id FROM Loan__c WHERE Id IN :loanIds];
            LoanBalanceService.updateLoanBalances(loansToUpdate);
        }
    }
}