Feature: One-time purchase
  In order to make sure purchase go through successfully
  Callback must be verified with Paypal API endpoint

  Scenario: Customer makes a purchase
    * I add a book to shopping cart 
    * I enter my shipping info
    * I click checkout, system calculates total (ez_paypal does not do the calculation, you should calculate it based on your tax/discount setting) 
	* Then system requests for a token from Paypal and generates a checkout url with received token as query string
	* I am taken to the Paypal site to confirm purchase, instead of confirm purchase, I go back to original site with current token as part of query string
	* Original site verifies with Paypal and finds out the purchase was not approved, purchase should not be succeeded
 	 
