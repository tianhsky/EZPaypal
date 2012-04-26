require 'active_support/hash_with_indifferent_access'
require 'cgi'

module EZPaypal
  module Helper
    # Helper method to convert query string to hash
    # also convert hash to encoded hash
    # @param [String / Hash] object to be converted or encoded
    # @return [Hash] converted string or encoded hash
    def self.ConvertParamToHash (object)
      hash_obj = HashWithIndifferentAccess.new()
      if (object.class.to_s == "String")
        object.split("&").each do |e|
          key = CGI::unescape(e.split("=")[0])
          value = CGI::unescape(e.split("=")[1])
          hash_obj.merge!(key => value)
        end
      else
        object.each do |key, value|
          key = CGI::unescape(key)
          value = CGI::unescape(value)
          hash_obj.merge!(key.upcase => value)
        end
      end

      return hash_obj
    end

    def self.ConvertHashToQueryString (hash)
      hash.map { |k, v| CGI::escape(k.to_s)+"="+CGI::escape(v.to_s) }.join("&")
    end

  end
end
