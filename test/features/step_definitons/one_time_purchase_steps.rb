begin require 'rspec/expectations'; rescue LoadError; require 'spec/expectations'; end 
require 'cucumber/formatter/unicode'

$:.unshift(File.dirname(__FILE__) + '/../../')
require 'lib/ez_paypal'
require 'test/config/paypal_setup'

Before do
  @cart = EZPaypal::Cart::OneTimePurchaseCart.new()
  @return_url = "http://127.0.0.1:3000/ec_return"
  @cancel_url = "http://127.0.0.1:3000/ec_cancel"
end

After do
end

Given /^I add a book to shopping cart$/ do
  item = 
  {
      "name" => "book",
      "amount" => "15.5",
      "quantity" => "1"
  }
  @cart.addItem(item)
end

Given /^I enter my shipping info$/ do
  shipping = 
  {
      "name" => "John Smith",
      "street" => "123 xx Rd",
      "city" => "xxxxx",
      "state" => "xx",
      "country" => "US",
      "zip" => "11234",
      "phone" => "123-456-7890"
  }
  @cart.setupShippingInfo(shipping)
end

Given /^I click checkout, system calculates total \(ez_paypal does not do the calculation, you should calculate it based on your tax\/discount setting\)$/ do
  summary = 
   {
       "subtotal" => "15.5",
       "tax" => "0.5",
       "shipping" => "1",
       "handling" => "0",
       "shipping_discount" => "-1",
       "insurance" => "0",
       "total" => "16"
   }
   @cart.setupSummary(summary)
end

Given /^Then system requests for a token from Paypal and generates a checkout url with received token as query string$/ do
  # send cart to request for token
  response_origin = EZPaypal::Request.SetupExpressCheckout(@cart, @return_url, @cancel_url)
  response = EZPaypal::Response.new(response_origin)

  # get checkout url
  @token = response["TOKEN"]
  @token.should_not be_empty
  @checkout_url = response.getCheckoutURL()
end

Given /^I am taken to the Paypal site to confirm purchase, instead of confirm purchase, I go back to original site with current token as part of query string$/ do
  # taken to @checkout_url
  # then go to url = @return_url + "?token=#{@token}"
  # now system should have access to url query params
  @params = {"token" => @token, "PayerID" => "fake_id"}
end

Given /^Original site verifies with Paypal and finds out the purchase was not approved, purchase should not be succeeded$/ do
  params = @params
  d_token = params["token"]
  d_payerid = params["PayerID"]

  response = EZPaypal::Response.new(params)

  # confirm purchase 
  confirm_purchase_origin = response.confirmPurchase()
  confirm_response = EZPaypal::Response.new(confirm_purchase_origin)

  confirm_response.success?.should_not be_true
end

