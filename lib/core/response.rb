require 'json'
require 'cgi'
require File.expand_path('../../config', __FILE__)
require File.expand_path('../helper', __FILE__)

module EZPaypal
  class Response < HashWithIndifferentAccess

    # Constructor for Response object, take string response from paypal api server as param
    # @param [String/Hash] response as a query string or hash including
    #                     { "TOKEN", "PAYERID", "TIMESTAMP", "CORRELATIONID", "ACK", "VERSION", "BUILD",
    #                     "L_ERRORCODE0", "L_SHORTMESSAGE0", "L_LONGMESSAGE0", "L_SEVERITYCODE0", ... }
    # @return [EZPaypal::Response < Hash] response will be encoded, content is same as param
    #
    def initialize (response)
      hash_response = EZPaypal::Helper.ConvertParamToHash(response)
      self.merge!(hash_response)
    end

    # Check current response is success or not
    # @return [Bool] true/false
    def success?
      return self["ACK"].downcase == "success"
    end

    # Get current error message
    # @return [Hash] the error messages and error codes in hash array
    #               example return obj: {"error_codes" => [], "severity_codes"=[],
    #                                   "short_messages" =[], "long_messages" =[]}
    def errors
      error_codes = []
      severity_codes = []
      short_messages = []
      long_messages = []

      self.each do |key, value|
        if key.match(/^L_ERRORCODE/)
          error_codes.push(value)
        end
        if key.match(/^L_SEVERITYCODE/)
          severity_codes.push(value)
        end
        if key.match(/^L_SHORTMESSAGE/)
          short_messages.push(value)
        end
        if key.match(/^L_LONGMESSAGE/)
          long_messages.push(value)
        end
      end

      error_messages = {"error_codes" => error_codes, "severity_codes" => severity_codes,
                        "short_messages" => short_messages, "long_messages" => long_messages}

      return error_messages
    end

    # Get current checkout url to redirect user to, only works if token is obtained
    # @return [String] paypal checkout url to redirect user to
    def getCheckoutURL
      EZPaypal::Request.GetCheckoutURL(self["TOKEN"]) if success?
    end

    # Get current checkout details, only works if token is obtained
    # @return [Hash] checkout details associated with the given token
    def getCheckoutDetails
      EZPaypal::Request.GetCheckoutDetails(self["TOKEN"])
    end

    # Confirm purchase, only works if token and payer_id is obtained
    # @return [Hash] payment details associated with the given token and payer_id
    def confirmPurchase
      EZPaypal::Request.ConfirmPurchase(self["TOKEN"], self["PAYERID"])
    end

  end
end
