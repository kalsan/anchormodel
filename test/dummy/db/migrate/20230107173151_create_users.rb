class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :role
      t.string :locale

      t.timestamps
    end
  end
end
