require "shopifyconnect/engine"

module Shopifyconnect
  API_KEY    = ENV.fetch('SHOPIFY_KEY')
  API_SECRET = ENV.fetch('SHOPIFY_SECRET')
  SCOPE      = ENV.fetch('SHOPIFY_SCOPE') { 'read_orders read_products read_customers write_script_tags' }.split
end

require 'aasm'
require "shopify_api"
ShopifyAPI::Session.api_key = Shopifyconnect::API_KEY
ShopifyAPI::Session.secret  = Shopifyconnect::API_SECRET
