/**
 * @description Service class for managing loan balance calculations
 */
public with sharing class LoanBalanceService {
    
    /**
     * @description Updates the current loan balance for given loans
     * @param loans List of Loan records to update
     */
    public static void updateLoanBalances(List<Loan__c> loans) {
        if (loans.isEmpty()) return;
        
        Set<Id> loanIds = new Set<Id>();
        for (Loan__c loan : loans) {
            loanIds.add(loan.Id);
        }
        
        // Get all charges for these loans
        Map<Id, Decimal> totalChargesByLoan = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT Loan__c, SUM(Amount__c) totalCharges
            FROM Loan_Charge__c
            WHERE Loan__c IN :loanIds
            GROUP BY Loan__c
        ]) {
            totalChargesByLoan.put((Id)ar.get('Loan__c'), (Decimal)ar.get('totalCharges'));
        }
        
        // Get loan details with gross amounts
        Map<Id, Loan__c> loanMap = new Map<Id, Loan__c>([
            SELECT Id, Gross_Loan_Amount__c, Balance_of_the_Loan__c, Total_Charges_on_the_Loan__c
            FROM Loan__c
            WHERE Id IN :loanIds
        ]);
        
        List<Loan__c> loansToUpdate = new List<Loan__c>();
        
        for (Id loanId : loanIds) {
            Loan__c loan = loanMap.get(loanId);
            if (loan != null) {
                Decimal totalCharges = totalChargesByLoan.get(loanId);
                if (totalCharges == null) totalCharges = 0;
                
                Decimal grossAmount = loan.Gross_Loan_Amount__c != null ? loan.Gross_Loan_Amount__c : 0;
                Decimal newBalance = grossAmount + totalCharges;
                
                // Only update if values have changed
                if (loan.Balance_of_the_Loan__c != newBalance || 
                    loan.Total_Charges_on_the_Loan__c != totalCharges) {
                    
                    loan.Balance_of_the_Loan__c = newBalance;
                    loan.Total_Charges_on_the_Loan__c = totalCharges;
                    loansToUpdate.add(loan);
                }
            }
        }
        
        if (!loansToUpdate.isEmpty()) {
            try {
                update loansToUpdate;
            } catch (Exception e) {
                System.debug('Error updating loan balances: ' + e.getMessage());
                throw new LoanBalanceException('Failed to update loan balances: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @description Custom exception for loan balance operations
     */
    public class LoanBalanceException extends Exception {}
}