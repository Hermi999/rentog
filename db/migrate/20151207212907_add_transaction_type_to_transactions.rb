class AddTransactionTypeToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :transaction_type, :string, :default => "intern"  # intern, trusted, extern
  end
end
