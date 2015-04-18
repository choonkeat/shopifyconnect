# shopifyconnect

a Rails engine to simplify integration with Shopify.

## Installation

Go into your Rails app directory `vendor` directory and place this Rails engine inside.

Edit your `Gemfile` to use this engine

```
gem 'shopifyconnect', path: "vendor/shopifyconnect"
```

Edit your `config/routes.rb` to provide access

```
mount Shopifyconnect::Engine => "/shopifyconnect"
```

Copy `vendor/shopifyconnect/config/locales/en.yml.sample` to `vendor/shopifyconnect/config/locales/en.yml` and edit that `en.yml` to setup your

* recurring charges
* javascript urls (optional)
* webhook end points (optional)

NOTE: those webhook topics without an end point will be ignored

Finally, run these commands to complete the setup

```
bundle install
rake railties:install:migrations db:migrate
```

## Usage

Bring any user logged in to your Rails app to `/shopifyconnect` and the Rails engine will take over

* asks the user for their shopify store address (aka subdomain)
* prompts the user to login at Shopify
* prompts the user to accept the recurring payment
* add javascript tags into the user's shopify store - so when his customers visit his online store, your javascripts will be loaded
* listen for webhooks from the user's shopify store

## Current user

`shopifyconnect` will attempt to identify the `current_user` via `session["warden.user.user.key"]` or `session[:user_id]`. Please update `Shopifyconnect::ShopsController#current_user_id` if your Rails app user id is not picked up.

When `shopifyconnect` cannot find a user id, it will redirect the browser to the login page, as specified in `shopifyconnect.new_session_path` in `en.yml`. It would be wonderful if your login routine will redirect back to `shopifyconnect` once the user is logged in.

When `shopifyconnect` has a reference to the user id, it will use it to load or create the user's `Shopifyconnect::Store` object.

## Scripts and Webhooks


Preconfigured in `en.yml.sample` is the suggestion to use `/shopifyconnect/sample/js` and `/shopifyconnect/sample/webhook` as the embedded script tag and the webhook end point.

You're supposed to write your own end points and replace those configurations. Feel free to reference `Shopifyconnect::SampleController#webhook` and `Shopifyconnect::SampleController#js`.


