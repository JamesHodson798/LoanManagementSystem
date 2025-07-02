/**
 * @description Handler class for Loan_Charge__c triggers
 * @author Your Name
 * @date 2025
 */
public with sharing class LoanChargeTriggerHandler {
    
    /**
     * @description Handles before insert operations
     * @param newCharges List of newly inserted Loan Charge records
     */
    public static void handleBeforeInsert(List<Loan_Charge__c> newCharges) {
        LoanChargeService.validateReleaseCharges(newCharges);
    }
    
    /**
     * @description Handles after insert operations
     * @param newCharges List of newly inserted Loan Charge records
     */
    public static void handleAfterInsert(List<Loan_Charge__c> newCharges) {
        LoanChargeService.handleReleaseChargeAdjustments(newCharges);
        updateLoanBalancesFromCharges(newCharges);
    }
    
    /**
     * @description Handles after update operations
     * @param newCharges List of updated Loan Charge records
     * @param oldChargeMap Map of old Loan Charge records
     */
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
    
    /**
     * @description Handles after delete operations
     * @param deletedCharges List of deleted Loan Charge records
     */
    public static void handleAfterDelete(List<Loan_Charge__c> deletedCharges) {
        updateLoanBalancesFromCharges(deletedCharges);
    }
    
    /**
     * @description Updates loan balances when charges are modified
     * @param charges List of loan charges that were modified
     */
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