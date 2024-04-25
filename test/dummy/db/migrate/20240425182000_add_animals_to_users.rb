class AddAnimalsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :animals, :string, default: '', null: false
  end
end
