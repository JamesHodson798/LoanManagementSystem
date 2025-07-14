/***************************************************************************
 *  Date:   14July25
 *  Author: James Hodson
 *  Desc:   Update the loan balance with the new changes to the loan charges.
 * *************************************************************************/
public with sharing class LoanBalanceService {
    
    // Updates the current loan balance for given loans with the list of Loan records to update.
    public static void updateLoanBalances(List<Loan__c> loans) {
        if (loans.isEmpty()) return;
        
        Set<Id> loanIds = new Set<Id>();
        for (Loan__c loan : loans) {
            loanIds.add(loan.Id);
        }
        
        // Get all charges for these loans, sorted by date and processing order
        List<Loan_Charge__c> allCharges = [
            SELECT Id, Loan__c, Amount__c, Date__c, Charge_Type__c, Processing_Order__c
            FROM Loan_Charge__c
            WHERE Loan__c IN :loanIds
            ORDER BY Date__c ASC, Processing_Order__c ASC
        ];
        
        // Group charges by loan
        Map<Id, List<Loan_Charge__c>> chargesByLoan = new Map<Id, List<Loan_Charge__c>>();
        for (Loan_Charge__c charge : allCharges) {
            if (!chargesByLoan.containsKey(charge.Loan__c)) {
                chargesByLoan.put(charge.Loan__c, new List<Loan_Charge__c>());
            }
            chargesByLoan.get(charge.Loan__c).add(charge);
        }
        
        // Calculate total charges by loan (respecting processing order)
        Map<Id, Decimal> totalChargesByLoan = new Map<Id, Decimal>();
        for (Id loanId : chargesByLoan.keySet()) {
            Decimal totalCharges = 0;
            List<Loan_Charge__c> loanCharges = chargesByLoan.get(loanId);
            
            // Process charges in order (date ASC, processing_order ASC)
            for (Loan_Charge__c charge : loanCharges) {
                totalCharges += (charge.Amount__c != null ? charge.Amount__c : 0);
            }
            
            totalChargesByLoan.put(loanId, totalCharges);
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
    
    // Custom exception for loan balance operations.
    public class LoanBalanceException extends Exception {}
}