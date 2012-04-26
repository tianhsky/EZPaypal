require 'active_support/hash_with_indifferent_access'
require 'cgi'
require 'ez_http'
require File.expand_path('../../config', __FILE__)
require File.expand_path('../helper', __FILE__)

module EZPaypal
  module Request

    # Setup express checkout cart
    # @param [EZPaypal::Cart::OneTimePurchaseCart / EZPaypal::Cart::RecurringPurchaseCart] cart
    # @param [String] returnUrl
    # @param [String] cancelUrl
    # @return [Hash] response = {"TOKEN"}
    def self.SetupExpressCheckout (cart, returnUrl, cancelUrl)
      begin
        # Setup default options
        setting = EZPaypal::Config.Setting.clone
        default = {"METHOD" => "SetExpressCheckout",
                   "RETURNURL" => returnUrl,
                   "CANCELURL" => cancelUrl
        }
        setting.merge!(default).merge!(cart)

        # Get setup express checkout details
        query_string = EZPaypal::Helper.ConvertHashToQueryString(setting)
        setup_ec_response_origin = EZHttp.Send(EZPaypal::Config.EndPoint["express_checkout_endpoint"], query_string, "post").body

        # Convert express checkout details to Hash to return
        setup_ec_response = EZPaypal::Helper.ConvertParamToHash(setup_ec_response_origin)

        return setup_ec_response
      rescue
        throw "Error occured in SetupExpressCheckout"
      end
    end

    # Get current checkout url to redirect user to, only works if token has obtained
    # @param [String] token
    # @return [String] paypal checkout url to redirect user to
    def self.GetCheckoutURL(token)
      EZPaypal::Config.EndPoint["express_checkout_url"]+ "&token=" + token unless token.nil?
    end

    # Get current checkout details, only works if token has obtained
    # @param [String] token
    # @return [Hash] checkout details associated with the given token
    def self.GetCheckoutDetails(token)
      unless (token.nil?)
        begin
          # Setup default options
          setting = EZPaypal::Config.Setting.clone
          setting.merge!({"METHOD" => "GetExpressCheckoutDetails"})
          setting.merge!({"TOKEN" => token})

          # Get checkout details
          query_string = EZPaypal::Helper.ConvertHashToQueryString(setting)
          checkout_details_origin = EZHttp.Send(EZPaypal::Config.EndPoint["express_checkout_endpoint"], query_string, "post").body

          # Convert checkout details to Hash to return
          checkout_details = EZPaypal::Helper.ConvertParamToHash(checkout_details_origin)

          return checkout_details
        rescue
          throw "Error occured in GetExpressCheckoutDetails: token=#{token}"
        end
      end
    end

    # Confirm payment, only works if token and payer_id is obtained
    # @param [String] token
    # @param [String] payer_id
    # @return [Hash] payment details associated with the given token and payer_id
    def self.ConfirmPurchase(token, payer_id)
      unless (token.nil? && payer_id.nil?)
        begin
          # Setup default options
          setting = EZPaypal::Config.Setting.clone
          setting.merge!({"METHOD" => "DoExpressCheckoutPayment"})
          setting.merge!({"PAYMENTREQUEST_0_PAYMENTACTION" => "Sale"})
          setting.merge!({"TOKEN" => token})
          setting.merge!({"PAYERID" => payer_id})


          # Get checkout details
          checkout_details_origin = EZPaypal::Request.GetCheckoutDetails(token)
          checkout_details_origin.each do |key, value|
            key = CGI::unescape(key)
            value = CGI::unescape(value)
          end

          # Submit checkout request to confirm the purchase
          payment_response_origin = HashWithIndifferentAccess.new()
          if (checkout_details_origin["ACK"].downcase == "success")
            checkout_details_origin.merge!(setting)
            query_string = EZPaypal::Helper.ConvertHashToQueryString(checkout_details_origin)
            payment_response_origin = EZHttp.Send(EZPaypal::Config.EndPoint["express_checkout_endpoint"], query_string, "post").body
          end

          # Convert response to Hash to return
          payment_response = EZPaypal::Helper.ConvertParamToHash(payment_response_origin)

          return payment_response

        rescue
          throw "Error occured in ConfirmPurchase: TOKEN=#{token}, PAYERID=#{payer_id}"
        end
      end
    end

    # Create a recurring profile for a customer
    # @param [EZPaypal::Cart::RecurringProfile] profile including all the config for the recurring profile
    # @return [Hash] profile creation confirmation from paypal
    def self.CreateRecurringProfile(profile)
      begin
        # Setup default options
        setting = EZPaypal::Config.Setting.clone
        default = {"METHOD" => "CreateRecurringPaymentsProfile"}
        setting.merge!(default).merge!(profile)

        # Http call to create profile and get response
        query_string = EZPaypal::Helper.ConvertHashToQueryString(setting)
        profile_response_origin = EZHttp.Send(EZPaypal::Config.EndPoint["express_checkout_endpoint"], query_string, "post").body

        # Convert response to Hash to return
        profile_response = EZPaypal::Helper.ConvertParamToHash(profile_response_origin)

        return profile_response
      rescue
        throw "Error occured in CreateRecurringProfile"
      end
    end

    # Refund money to a transaction
    # @param [String] all
    # @return [Hash]
    def self.Refund(transaction_id, refund_type, amount, currency, note)
      # Setup default options
      setting = EZPaypal::Config.Setting.clone
      options = {
          "METHOD" => "RefundTransaction",
          "TRANSACTIONID" => transaction_id,
          "REFUNDTYPE" => refund_type || "Partial",
          "AMT" => amount || "0",
          "CURRENCYCODE" => currency || "USD",
          "NOTE" => note || ""
      }
      setting.merge!(options)

      # Http call to create profile and get response
      query_string = EZPaypal::Helper.ConvertHashToQueryString(setting)
      refund_response_origin = EZHttp.Send(EZPaypal::Config.EndPoint["express_checkout_endpoint"], query_string, "post").body

      # Convert response to Hash to return
      profile_response = EZPaypal::Helper.ConvertParamToHash(refund_response_origin)
    end

  end
end
