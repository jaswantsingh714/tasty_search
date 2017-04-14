class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
    	t.string :product_id
    	t.string :user_id
    	t.string :profile_name
    	t.string :helpfulness
    	t.float :score
    	t.datetime :time
    	t.text :summary
    	t.text :text
    end
  end
end
