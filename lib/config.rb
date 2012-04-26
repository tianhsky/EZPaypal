module EZPaypal
  module Config

    # Account setting
    @setting

    def self.Setting
      @setting
    end

    # API endpoint
    @endpoint

    def self.EndPoint
      @endpoint
    end

    # Setup config
    # @param [Hash] options = { "user", "password", "signature",
    #                         "version", "mode" => "sandbox / live",
    #                         "customer_service_tel"}
    #
    def self.Setup (options)
      # Setup account setting
      @setting={
          "USER" => options["user"],
          "PWD" => options["password"],
          "SIGNATURE" => options["signature"],
          "VERSION" => options["version"] || 84.0,
          "CUSTOMERSERVICENUMBER" => options["customer_service_tel"]
      }

      # Setup endpoint
      express_checkout_endpoint = {
          "sandbox" => "https://api-3t.sandbox.paypal.com/nvp",
          "live" => "https://api-3t.paypal.com/nvp"
      }
      set_express_checkout = {
          "sandbox" => "https://www.sandbox.paypal.com/webscr?cmd=_express-checkout",
          "live" => "https://www.paypal.com/webscr?cmd=_express-checkout",
      }

      @endpoint ||= {}
      if (options["mode"] == 'sandbox')
        @endpoint.merge!("express_checkout_endpoint" => express_checkout_endpoint["sandbox"])
        @endpoint.merge!("express_checkout_url" => set_express_checkout["sandbox"])
      else
        @endpoint.merge!("express_checkout_endpoint" => express_checkout_endpoint["live"])
        @endpoint.merge!("express_checkout_url" => set_express_checkout["live"])
      end


    end
  end
end
