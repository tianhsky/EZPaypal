require 'active_support/hash_with_indifferent_access'
require 'cgi'

module EZPaypal

  # Paypal NVP Documentation:
  #  Express checkout:
  #   https://cms.paypal.com/us/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_nvp_r_GetExpressCheckoutDetails
  #  Recurring payments:
  #   https://cms.paypal.com/us/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_ECRecurringPayments
  #   https://cms.paypal.com/us/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_nvp_r_CreateRecurringPayments
  module Cart

    # A cart object that holds all one time purchase items
    #  How to use:
    #    -> initialize Cart
    #    -> add items (optional)
    #    -> setup shipping info(optional)
    #    -> setup summary(required)
    #    -> done (if involve recurring purchase, please create profile, this cart only shows agreement for recurring items)
    #  Note:
    #    you are responsible for all the cost calculations
    #
    class OneTimePurchaseCart < HashWithIndifferentAccess

      # Max cart size of this cart type
      def cartSize
        10
      end

      # Add item to the cart (optional)
      # @param [Hash] item = {"category" => "digital / physical",
      #                       "name", "item_code", "description", "amount", "quantity" }
      #
      def addItem(item)

        # Check max cart size, make sure do not exceed the limit
        max = 0
        self.each do |key, value|
          max = max + 1 if key.match(/^L_PAYMENTREQUEST_0_NAME/)
        end
        throw "Exceed max cart size: #{cartSize}" if (max+1 > cartSize)

        # Add item to cart
        current_index = max
        current_item = {
            "L_PAYMENTREQUEST_0_ITEMCATEGORY#{current_index}" => item["category"] || "Physical",
            "L_PAYMENTREQUEST_0_NAME#{current_index}" => item["name"] || "",
            "L_PAYMENTREQUEST_0_NUMBER#{current_index}" => item["item_code"] || "",
            "L_PAYMENTREQUEST_0_DESC#{current_index}" => item["description"] || "",
            "L_PAYMENTREQUEST_0_AMT#{current_index}" => item["amount"] || "0",
            "L_PAYMENTREQUEST_0_QTY#{current_index}" => item["quantity"] || "0"
        }
        self.merge!(current_item)

      end

      # Setup shipping info (optional)
      # @param [Hash] shipping = {"name", "street", "street2", "city", "state", "country", "zip", "phone" }
      def setupShippingInfo(shipping)
        item = shipping
        options = {
            "PAYMENTREQUEST_0_SHIPTONAME" => item["name"] || "",
            "PAYMENTREQUEST_0_SHIPTOSTREET" => item["street"] || "",
            "PAYMENTREQUEST_0_SHIPTOSTREET2" => item["street2"] || "",
            "PAYMENTREQUEST_0_SHIPTOCITY" => item["city"] || "",
            "PAYMENTREQUEST_0_SHIPTOSTATE" => item["state"] || "",
            "PAYMENTREQUEST_0_SHIPTOCOUNTRYCODE" => item["country"] || "",
            "PAYMENTREQUEST_0_SHIPTOZIP" => item["zip"] || "",
            "PAYMENTREQUEST_0_SHIPTOPHONENUM" => item["phone"] || ""
        }
        self.merge!(options)
      end

      # Add cart summary, please calculate yourself (required)
      # @param [Hash] summary = {"currency" => "USD"(default "USD"),
      #                         "subtotal", "tax", "shipping", "handling", "shipping_discount", "insurance", "total",
      #                         "disable_change_shipping_info" => "1 / 0" (default 1),
      #                         "allow_note" => "1 / 0" (default 0) }
      #
      def setupSummary (summary)
        item = summary
        options = {
            "PAYMENTREQUEST_0_PAYMENTACTION" => item["payment_action"] || "Sale",
            "PAYMENTREQUEST_0_CURRENCYCODE" => item["currency"] || "USD",

            "PAYMENTREQUEST_0_ITEMAMT" => item["subtotal"] || "0",
            "PAYMENTREQUEST_0_TAXAMT" => item["tax"] || "0",
            "PAYMENTREQUEST_0_SHIPPINGAMT" => item["shipping"] || "0",
            "PAYMENTREQUEST_0_HANDLINGAMT" => item["handling"] || "0",
            "PAYMENTREQUEST_0_SHIPDISCAMT" => item["shipping_discount"] || "0",
            "PAYMENTREQUEST_0_INSURANCEAMT" => item["insurance"] || "0",
            "PAYMENTREQUEST_0_AMT" => item["total"] || "0",

            "ALLOWNOTE" => item["allow_note"] || "0",
            "NOSHIPPING" => item["disable_change_shipping_info"] || "1"
        }
        self.merge!(options)
      end

      # Clean the cart
      def reset
        self.clear
      end

    end


    # A cart object that holds all recurring purchase items
    # Note that this cart only support one subscription item at a time
    #  How to use:
    #    -> initialize Cart
    #    -> setup agreement (required)
    #    -> setup summary(required)
    #    -> done (please create profile after this, this cart only shows agreement for recurring items)
    #  Note:
    #    you are responsible for all the cost calculations
    #
    class RecurringPurchaseCart < HashWithIndifferentAccess

      # Max cart size of this cart type
      def cartSize
        1
      end

      # Setup recurring payment agreement
      # @param [Hash] agreement = {"category" => "digital / physical" (default physical),
      #                            "currency" => "USD"(default "USD")
      #                            "item_code" => ""(code should be unique and meaningful),
      #                            "unit_price", "quantity" ,"amount"}
      #
      def setupAgreement(agreement)

        # Check max cart size, make sure do not exceed the limit
        max = 0
        self.each do |key, value|
          max = max + 1 if key.match(/^L_PAYMENTREQUEST_0_NAME/)
        end
        throw "Exceed max cart size: #{cartSize}" if (max+1 > cartSize)

        item = agreement
        current_index = max
        current_item = {
            "L_PAYMENTREQUEST_0_NAME#{current_index}" => item["item_code"] || "",
            #"L_PAYMENTREQUEST_0_NUMBER#{current_index}" => item["item_code"] || "",
            #"L_PAYMENTREQUEST_0_DESC#{current_index}" => item["description"] || "",
            "L_PAYMENTREQUEST_0_AMT#{current_index}" => item["unit_price"] || "0",
            "L_PAYMENTREQUEST_0_QTY#{current_index}" => item["quantity"] || "0",

            "L_PAYMENTREQUEST_0_ITEMCATEGORY#{current_index}" => item["category"] || "Physical",
            "L_BILLINGTYPE#{current_index}" => "RecurringPayments",
            "L_BILLINGAGREEMENTDESCRIPTION#{current_index}" => item["item_code"] || ""
        }

        summary = {
            "PAYMENTREQUEST_0_PAYMENTACTION" => item["payment_action"] || "Sale",
            "PAYMENTREQUEST_0_CURRENCYCODE" => item["currency"] || "USD",
            #"PAYMENTREQUEST_0_ITEMAMT" => item["total"] || "0",
            #"PAYMENTREQUEST_0_TAXAMT" => item["tax"] || "0",
            #"PAYMENTREQUEST_0_SHIPPINGAMT" => item["shipping"] || "0",
            #"PAYMENTREQUEST_0_HANDLINGAMT" => item["handling"] || "0",
            #"PAYMENTREQUEST_0_SHIPDISCAMT" => item["shipping_discount"] || "0",
            #"PAYMENTREQUEST_0_INSURANCEAMT" => item["insurance"] || "0",
            "PAYMENTREQUEST_0_AMT" => item["amount"] || "0",

            "ALLOWNOTE" => item["allow_note"] || "0",
            "NOSHIPPING" => item["disable_change_shipping_info"] || "1"
        }
        self.merge!(current_item).merge!(summary)
      end

      # Clean the cart
      def reset
        self.clear
      end
    end


    class RecurringProfile < HashWithIndifferentAccess

      # Setup profile
      # @param [Hash] profile = {"token", "email", "currency" => "USD" (default "USD"),
      #                         "item_code", "unit_price", "quantity", "amount",
      #                         "initial_amount" => "0" (recurring profile will do auto-charge since begining! do not use this if you are not sure),
      #                         "start_date" => "2012/02/02" (Default Time.now),
      #                         "period" => "Day/Week/Month/Year" (default "Month"),
      #                         "frequency" => "1" (how many periods a purchase, default 1),
      #                         "cycles" => "0" (total cycles of recurring billing, default 0 means infinite)
      #                          }
      def initialize(profile)
        item = profile
        options = {
            "TOKEN" => item["token"],
            "EMAIL" => item["email"],
            "CURRENCYCODE" => item["currency"] || "USD",
            "FAILEDINITAMTACTION" => "CancelOnFailure", #ContinueOnFailure / CancelOnFailure

            # Display details
            "L_PAYMENTREQUEST_0_ITEMCATEGORY0" => item["category"] || "Physical",
            "L_PAYMENTREQUEST_0_NAME0" => item["item_code"] || "",
            "L_PAYMENTREQUEST_0_AMT0" => item["unit_price"] || "0",
            "L_PAYMENTREQUEST_0_QTY0" => item["quantity"] || "0",

            # Profile details
            "DESC" => item["item_code"] || "",
            "AMT" => item["amount"] || "0",
            "QTY" => item["quantity"] || "0",
            "INITAMT" => item["initial_amount"] || "0",

            # Recurring details
            "PROFILESTARTDATE" => item["start_date"] || Time.now,
            "BILLINGFREQUENCY" => item["frequency"] || "1",
            "BILLINGPERIOD" => item["period"] || "Month",
            "TOTALBILLINGCYCLES" => item["cycles"] || "0"

        }

        self.merge!(options)
      end

      def self.ConvertFromCheckoutDetails (checkout_details)
        profile = {
            "token" => checkout_details["TOKEN"],
            "email" => checkout_details["EMAIL"],
            "item_code" => checkout_details["L_PAYMENTREQUEST_0_NAME0"],
            "unit_price" => checkout_details["L_PAYMENTREQUEST_0_AMT0"],
            "quantity" => checkout_details["L_PAYMENTREQUEST_0_QTY0"],
            "amount" => checkout_details["PAYMENTREQUEST_0_AMT"],
            "start_date" => Time.now,
            "period" => "Month",
            "frequency" => "1"
        }

        profile = self.new(profile)
      end

    end


  end
end