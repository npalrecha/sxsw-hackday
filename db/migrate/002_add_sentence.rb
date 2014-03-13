class AddSentence < ActiveRecord::Migration
  def change
    create_table :sentences, force: true do |t|
      t.integer :state, default: 0
      t.string :where
      t.string :what
      t.string :who
      t.string :artist

      t.string :lookup_key

      t.timestamps
    end
  end
end
