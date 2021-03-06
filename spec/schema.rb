ActiveRecord::Schema.define(:version => 1) do
  create_table :categories do |t|
  end

  create_table :order_invoices do |t|
    t.integer :order_id
    t.boolean :active
  end

  create_table :orders do |t|
    t.integer :category_id
    t.boolean :active
  end

  create_table :products do |t|
  end

  create_table :categories_products do |t|
    t.integer :product_id, :category_id
  end
end

