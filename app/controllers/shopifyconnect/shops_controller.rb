require_dependency "shopifyconnect/application_controller"

module Shopifyconnect
  class ShopsController < ApplicationController
    before_filter :requires_current_user_id
    around_filter :with_current_shop # so we can use `ShopifyAPI` directly, already setup to `current_shop`

    def show
      return redirect_to(new_shop_path) if current_shop.new_record?
    end

    def new
    end

    # 1. user has submitted their shopify subdomain
    def create
      current_shop.attributes = shop_params
      if current_shop.save
        redirect_to login_at_shopify_url
      else
        render :new
      end
    end

    # 2. user has logged in at shopify and is returned here
    def authorize
      if (current_shop.access_token = get_access_token) && (current_shop.authorize!)
        # use `with_current_shop` because we just gotten our access_token; around_filter had not kicked in yet
        with_current_shop do
          redirect_to request_recurring_charges_url
        end
      else
        redirect_to shop_path, notice: I18n.t('shopifyconnect.notices.authorize_fail')
      end
    rescue OAuth2::Error
      redirect_to shop_path, notice: I18n.t('shopifyconnect.notices.authorize_oauth_error')
    end

    # 3. user has accepted our recurring charges, install all the things!
    def install
      charge = if params[:charge_id]
        ShopifyAPI::RecurringApplicationCharge.find(:first, params: { id: params[:charge_id] })
      else
        existing_recurring_charge
      end

      case charge.try(:status)
      when 'accepted'
        charge.activate
        current_shop.authorize if current_shop.installed?
        current_shop.install!
      when 'active'
        # update?
      else
        current_shop.destroy unless current_shop.installed? # only remove 'new shop'
      end

      redirect_to shop_path, notice: I18n.t('shopifyconnect.notices.charges_updated', status: charge.status.titleize)
    end

    def update
      if current_shop.update(shop_params)
        if current_shop.access_token
          redirect_to request_recurring_charges_url
        else
          redirect_to login_at_shopify_url
        end
      else
        render :edit
      end
    end

    def destroy
      current_shop.try(:destroy)
      redirect_to new_shop_path
    end

    private

      def shop_params
        params.require(:shop).permit(:store_address)
      end

      def login_at_shopify_url
        current_shopify_session.create_permission_url(Shopifyconnect::SCOPE, authorize_shop_url)
      end

      def get_access_token
        # https://docs.shopify.com/api/authentication/oauth#verification
        # disabled because 'MD5 Signature Validation: To be removed after June 1st, 2015'
        current_shopify_session.request_token(params)
      rescue Exception
        # https://github.com/Shopify/shopify_api/pull/173
        puts $!
        puts $@
        response = current_shopify_session.send(:access_token_request, params[:code])
        JSON.parse(response.body)['access_token']
      end

      def request_recurring_charges_url
        # If you [activate a new recurring application charge] for a shop that already has a recurring
        # application charge in place, the existing recurring application charge will be cancelled and
        # replaced by the new charge.
        # https://docs.shopify.com/api/billings/billings-api#recurring-charge
        charge = ShopifyAPI::RecurringApplicationCharge.create(I18n.t('shopifyconnect.recurring_charge').merge(return_url: install_shop_url))
        charge.confirmation_url
      end

      def current_shopify_session
        @current_shopify_session ||= current_shop.try(:store_address) && ShopifyAPI::Session.new("#{current_shop.store_address}.myshopify.com", current_shop.access_token)
      end

      def with_current_shop(&block)
        if current_shop.try(:access_token)
          ShopifyAPI::Session.temp("https://#{current_shop.store_address}.myshopify.com", current_shop.access_token, &block)
        else
          yield
        end
      end

      def current_user_id
        # if main app uses Devise
        session["warden.user.user.key"].try(:first).try(:first) ||
        # otherwise, refer to standard key
        session[:user_id]
      end

      def current_shop
        @current_shop ||= Shop.where(user_id: current_user_id).first_or_initialize
      end
      helper_method :current_shop

      def requires_current_user_id
        if current_user_id.blank?
          redirect_to I18n.t('shopifyconnect.new_session_path'), notice: I18n.t('shopifyconnect.notices.login_required')
          false
        end
      end

      def existing_recurring_charge
        @existing_recurring_charge ||= ShopifyAPI::RecurringApplicationCharge.current
      rescue Exception
      end

  end
end
