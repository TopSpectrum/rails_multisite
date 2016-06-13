class InitLookup < ActiveRecord::Migration
  def change
    create_table :databases do |t|
      t.string :name, null: false
      t.string :adapter
      t.string :database
      t.string :host
      t.string :username
      t.string :password

      t.index :name, unique: true
    end

    create_table :host_names do |t|
      t.string :name, null: false
      t.belongs_to :database, index: true, foreign_key: true
      t.index :name, unique: true
    end
  end
end
