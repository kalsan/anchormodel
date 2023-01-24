class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :role
      t.string :secondary_role
      t.string :locale
      t.string :preferred_locale, null: false, default: :en

      t.timestamps
    end
  end
end
