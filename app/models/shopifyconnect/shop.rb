module Shopifyconnect
  class Shop < ActiveRecord::Base
    validates_presence_of :store_address

    after_destroy :remove_recurring_charge_if_any

    def domain_name
      "#{store_address}.myshopify.com"
    end

    include AASM
    aasm column: 'state', whiny_transitions: false do
      state :pending, initial: true
      state :authorized
      state :installed

      event :authorize do
        transitions from: [:pending, :installed], to: :authorized
      end

      event :install do
        transitions from: :authorized, to: :installed, guard: [:install_webhooks, :install_scripts]
      end
    end

    # make API calls using this shop's oauth
    # charge = shop.session { ShopifyAPI::RecurringApplicationCharge.current }
    def session(&block)
      ShopifyAPI::Session.temp("https://#{store_address}.myshopify.com", access_token, &block)
    end

    protected

      # install_webhooks, install_scripts should be configured in config/locales/en.yml
      # see config/locales/en.yml.sample

      def install_webhooks(hostname = I18n.t('shopifyconnect.install.hostname'), topic_urls_map = I18n.t('shopifyconnect.install.topic_urls'))
        # remove existing if any
        ShopifyAPI::Webhook.find(:all, params: { limit: 100 }).each {|webhook| webhook.destroy if webhook.address.match(hostname) }
        # create new
        topic_urls_map.each {|topic,url| puts ShopifyAPI::Webhook.where(address: url, topic: topic, format: 'json').first_or_create.inspect if topic.present? && url.present? }
        true # explicit truthy value for aasm
      end

      def install_scripts(hostname = I18n.t('shopifyconnect.install.hostname'), script_urls = I18n.t('shopifyconnect.install.script_urls'))
        # remove existing if any
        ShopifyAPI::ScriptTag.find(:all, params: { limit: 100 }).each {|scripttag| scripttag.destroy if scripttag.src.match(hostname) }
        # create new
        script_urls.each {|url| puts ShopifyAPI::ScriptTag.where(event: "onload", src: url).first_or_create.inspect if url.present? }
        true # explicit truthy value for aasm
      end

      def remove_recurring_charge_if_any
        session do
          ShopifyAPI::RecurringApplicationCharge.current.tap {|x| "Removing #{x.inspect}" }.try(:destroy)
        end
      rescue Exception
        # best effort delete records
      end

  end
end
