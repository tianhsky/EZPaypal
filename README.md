# EZPaypal

[![Build Status](https://travis-ci.org/tianhsky/EZPaypal.png?branch=master)](https://travis-ci.org/tianhsky/EZPaypal)
[![Code Climate](https://codeclimate.com/github/tianhsky/EZPaypal.png)](https://codeclimate.com/github/tianhsky/EZPaypal)
[![Dependency Status](https://gemnasium.com/tianhsky/EZPaypal.png)](https://gemnasium.com/tianhsky/EZPaypal)
[![Coverage Status](https://coveralls.io/repos/tianhsky/EZPaypal/badge.png?branch=master)](https://coveralls.io/r/tianhsky/EZPaypal)

Paypal express checkout plugin.   

## How to use it

###Configuration

####Add Initializer

Add ~/config/initializers/paypal_setup.rb

	# Load config
	paypal_config_path = File.expand_path('../../paypal.yml', __FILE__)
	paypal_config_file = File.open(paypal_config_path)
	paypal_config = YAML::load(paypal_config_file)

	# Setup config
	option =
	{
		"user" => paypal_config[Rails.env]["login"],
		"password" => paypal_config[Rails.env]["password"],
		"signature" => paypal_config[Rails.env]["signature"],
		"mode" => (Rails.env == "development" || Rails.env == "test") ? "sandbox" : "live",
		"version" => "84.0"
	}
	EZPaypal::Config.Setup(option)

####Add Configuration File

Add ~/config/paypal.yml

	development:
	  login: "xxxx.xxxx.com"
	  password: "xxxxxx"
	  signature: "xxxx.xxxxxxxxxxxxx"

	test:
	  login: "xxxx.xxxx.com"
	  password: "xxxxxx"
	  signature: "xxxx.xxxxxxxxxxxxx"

	production:
	  login: "xxxx.xxxx.com"
	  password: "xxxxxx"
	  signature: "xxxx.xxxxxxxxxxxxx"


###Non-recurring purchase

####Request for token

	# create cart and add items to it
	cart = EZPaypal::Cart::OneTimePurchaseCart.new()

	item = 
	{
		"name" => "Item name",
		"item_code" => "Item code",
		"description" => "xxx, xxxxxx",
		"amount" => "3",
		"quantity" => "1"
	}
	cart.addItem(item)

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
	cart.setupShippingInfo(shipping)

	summary = 
	{
		"subtotal" => "3",
		"tax" => "0.5",
		"shipping" => "1",
		"handling" => "0",
		"shipping_discount" => "-1",
		"insurance" => "0",
		"total" => "3.5"
	}
	cart.setupSummary(summary)

	return_url = "http://127.0.0.1:3000/ec_return"
	cancel_url = "http://127.0.0.1:3000/ec_cancel"

	# send cart to request for token
	response_origin = EZPaypal::Request.SetupExpressCheckout(cart, return_url, cancel_url)
	response = EZPaypal::Response.new(response_origin)

	# get checkout url
	checkout_url = response.getCheckoutURL()

####Handle success purchase

	# verify query string
	d_token = params["token"]
	d_payerid = params["PayerID"]

	response = EZPaypal::Response.new(params)

	# confirm purchase 
	confirm_purchase_origin = response.confirmPurchase()
	confirm_response = EZPaypal::Response.new(confirm_purchase_origin)

	if (confirm_response.success?)
		# handle success purchase ...
		transaction_id = confirm_response["PAYMENTINFO_0_TRANSACTIONID"]
	else
		# handle failed purchase ...
	end

###Recurring purchase

####Request for token

	# create cart and add item to it
	cart = EZPaypal::Cart::RecurringPurchaseCart.new()
	item = 
	{
		"item_code" => "Item code",
		"unit_price" => "4",
		"quantity" => "1",
		"amount" => "4"
	}
	cart.setupAgreement(item)

	return_url = "http://127.0.0.1:3000/ec_return"
	cancel_url = "http://127.0.0.1:3000/ec_cancel"

	# send cart to request for token
	response_origin = EZPaypal::Request.SetupExpressCheckout(cart, return_url, cancel_url)
	response = EZPaypal::Response.new(response_origin)

	# get checkout url
	checkout_url = response.getCheckoutURL()

####Handle success purchase

	# verify query string
	d_token = params["token"]
	d_payerid = params["PayerID"]

	# get checkout details
	response = EZPaypal::Response.new(params)
	checkout_details_origin = EZPaypal::Request.GetCheckoutDetails(response["TOKEN"])
	checkout_details = EZPaypal::Response.new(checkout_details_origin)

	# create and confirm recurring profile
	profile = EZPaypal::Cart::RecurringProfile.ConvertFromCheckoutDetails(checkout_details)
	confirm_response = EZPaypal::Response.new(EZPaypal::Request.CreateRecurringProfile(profile))

	if (confirm_response.success?)
		# handle success purchase ...
		profile_id = confirm_response["PROFILEID"]
	else
		# handle failed purchase ...
	end

## Installation

Add the following line to rails "Gemfile"

	gem "ez_paypal"

then execute

	$ bundle install


See [http://rubygems.org/gems/ez_paypal](http://rubygems.org/gems/ez_paypal "EZPaypal RubyGem Page") for more details

## Authors

Tianyu Huang

