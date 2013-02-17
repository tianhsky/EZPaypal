$:.unshift(File.dirname(__FILE__) + '/../../')
require 'lib/ez_paypal'

# Load config
paypal_config_path = File.expand_path('../paypal.yml', __FILE__)
paypal_config_file = File.open(paypal_config_path)
paypal_config = YAML::load(paypal_config_file)

# Setup config
option =
{
    "user" => paypal_config["test"]["login"],
    "password" => paypal_config["test"]["password"],
    "signature" => paypal_config["test"]["signature"],
    "mode" => "sandbox",
    "version" => "84.0"
}
EZPaypal::Config.Setup(option)
