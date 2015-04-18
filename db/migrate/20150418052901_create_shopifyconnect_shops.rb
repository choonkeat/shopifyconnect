class CreateShopifyconnectShops < ActiveRecord::Migration
  def change
    create_table :shopifyconnect_shops do |t|
      t.references :user, index: true
      t.string :store_address, index: true
      t.string :access_token
      t.string :state

      t.timestamps null: false
    end
  end
end
