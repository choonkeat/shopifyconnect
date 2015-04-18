require_dependency "shopifyconnect/application_controller"

module Shopifyconnect
  class SampleController < ApplicationController

    def webhook
      request.body.rewind
      data = request.body.tap(&:rewind).read
      raise "Invalid HMAC" unless verified?(data, env["HTTP_X_SHOPIFY_HMAC_SHA256"])

      json_data       = JSON.parse(data)
      webhook_topic   = request.headers['HTTP_X_SHOPIFY_TOPIC']
      shop_subdomain  = request.headers['HTTP_X_SHOPIFY_SHOP_DOMAIN'].to_s.sub('.myshopify.com', '')
      if current_shop = Shop.where(store_address: shop_subdomain).first
        # do stuff
        puts "#{webhook_topic} for #{current_shop.inspect}"
        puts JSON.pretty_generate(json_data)

        # actual work: if apps are uninstalled, it makes sense to handle here
        case webhook_topic
        when 'app/uninstalled'
          current_shop.destroy
        end

      end
      render nothing: true
    end

    def js
      render formats: 'js'
    end

    protected

      # https://docs.shopify.com/api/webhooks/using-webhooks#verify-webhook
      def verified?(data, hmac_header)
        digest  = OpenSSL::Digest.new('sha256')
        calculated_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, Shopifyconnect::API_SECRET, data)).strip
        puts [calculated_hmac, hmac_header].inspect
        calculated_hmac == hmac_header
      end

  end
end
