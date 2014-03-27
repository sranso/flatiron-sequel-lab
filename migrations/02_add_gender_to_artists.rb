Sequel.migration do
  change do
    add_column :artists, :gender, String
  end
end