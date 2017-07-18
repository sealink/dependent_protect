#encoding: utf-8
require 'spec_helper'

describe DependentRestrict do

  context 'when associations are defined' do
    before do
      class OrderInvoice < ActiveRecord::Base
        belongs_to :order
      end

      class Order < ActiveRecord::Base
        belongs_to :category

        def to_s
          "Order #{id}"
        end
      end

      class Category < ActiveRecord::Base
        has_and_belongs_to_many :products

        def to_s
          "Category #{id}"
        end
      end

      class CategoriesProduct < ActiveRecord::Base
        belongs_to :product
        belongs_to :category
      end

      class Product < ActiveRecord::Base
        has_and_belongs_to_many :categories

        def to_s
          "Product #{id}"
        end
      end

    end

    after do
      [OrderInvoice, Order, Category, CategoriesProduct, Product].each(&:delete_all)
      classes_to_remove = %w(
        OrderInvoice
        Order
        Category
        CategoriesProduct
        Product
        CategoryOrdersAssociationExtension
      )
      classes_to_remove.each { |klass| Object.send(:remove_const, klass) }
    end


    context 'when not restricting' do
      it 'should allow creating reflections' do
        expect {
          class Order < ActiveRecord::Base
            has_one :order_invoice
          end

          class Category < ActiveRecord::Base
            has_many :orders do
              def active
                self.select(&:active?)
              end
            end

            has_many :order_invoices, :through => :orders
          end
        }.to_not raise_error
      end
    end


    context 'when restricting with exception' do
      before do
        class Order < ActiveRecord::Base
          has_one :order_invoice, :dependent => :restrict_with_exception
        end

        class Category < ActiveRecord::Base
          has_many :orders, :dependent => :restrict_with_exception do
            def active
              self.select(&:active?)
            end
          end

          has_many :order_invoices, :through => :orders, :dependent => :restrict_with_exception

          has_and_belongs_to_many :products, dependent: :restrict_with_exception
        end

        class Product < ActiveRecord::Base
          has_and_belongs_to_many :categories
        end
      end

      it 'should create the reflections on Order' do
        expect(Order.reflect_on_all_associations.map(&:name)).to eq [:category, :order_invoice]
      end

      it 'should create the reflections on Category' do
        expect(Category.reflect_on_all_associations.map(&:name)).to eq [:products, :orders, :order_invoices]
      end

      it 'should restrict has_and_belongs_to_many relationships' do
        product = Product.create!
        category = Category.create!
        category.products = [product]

        expect { category.reload.destroy }.to raise_error(
                                                  ActiveRecord::DetailedDeleteRestrictionError,
                                                  'Cannot delete record because dependent products exists'
                                              )
        begin
          category.destroy
        rescue ActiveRecord::DetailedDeleteRestrictionError => e
          expect(e.detailed_message).to eq "Cannot delete record because dependent products exists\n\n\nThese include:\n1: Product 1"
        end

        Product.destroy_all
        expect { category.reload.destroy }.to_not raise_error
      end

      it 'should restrict has_many relationships' do
        category = Category.create!
        5.times { Order.create!(:category => category) }
        expect { category.reload.destroy }.to raise_error(
                                                  ActiveRecord::DetailedDeleteRestrictionError,
                                                  'Cannot delete record because 5 dependent orders exist'
                                              )
        begin
          category.destroy
        rescue ActiveRecord::DetailedDeleteRestrictionError => e
          expect(e.detailed_message).to eq "Cannot delete record because 5 dependent orders exist\n\n\nThese include:\n1: Order 1\n2: Order 2\n3: Order 3\n4: Order 4\n5: Order 5"
        end
        1.times { Order.create!(:category => category) }
        begin
          category.destroy
        rescue ActiveRecord::DetailedDeleteRestrictionError => e
          expect(e.detailed_message).to eq "Cannot delete record because 6 dependent orders exist\n\n\nThese include:\n1: Order 1\n2: Order 2\n3: Order 3\n4: Order 4\n...and 2 more"
        end

        Order.destroy_all
        expect { category.reload.destroy }.to_not raise_error
      end

      it 'should restrict has_one relationships' do
        order = Order.create!
        order_invoice = OrderInvoice.create!(:order => order)
        expect { order.reload.destroy }.to raise_error(
                                               ActiveRecord::DetailedDeleteRestrictionError,
                                               'Cannot delete record because dependent order invoice exists'
                                           )

        order_invoice.destroy
        expect { order.reload.destroy }.to_not raise_error
      end

      it 'should still filter active' do
        category = Category.create!
        3.times { Order.create!(:category => category, :active => true) }
        2.times { Order.create!(:category => category, :active => false) }
        expect(category.orders.active.count).to eq 3

        Category.delete_all
        Order.delete_all
      end

      context "using i18n" do
        before do
          I18n.available_locales = [:en, :br]
          I18n.backend.store_translations(:br, {
            :dependent_restrict => {
              :basic_message => {
                :one => 'Não pode ser excluído pois um(a) %{name} relacionado(a) foi encontrado(a)',
                :others => 'Não pode ser excluído pois %{count} %{name} relacionados(as) foram encontrados(as)'
              },
              :detailed_message => {
                :and_more => "e mais %{count}",
                :includes => "Incluindo"
              }
            },
            :activerecord => {
              :models => {
                :order => {
                  :one => "Pedido",
                  :other => "Pedidos"
                },
                :order_invoice => {
                  :one => "Ordem de pedido"
                }
              }
            }
          })

          I18n.locale = :br
        end

        after do
          I18n.locale = :en
        end

        it 'should restrict has_many relationships' do

          category = Category.create!
          5.times { Order.create!(:category => category) }
          expect { category.reload.destroy }.to raise_error(
            ActiveRecord::DetailedDeleteRestrictionError,
            'Não pode ser excluído pois 5 pedidos relacionados(as) foram encontrados(as)'
          )
          begin
            category.destroy
          rescue ActiveRecord::DetailedDeleteRestrictionError => e
            expect(e.detailed_message).to eq "Não pode ser excluído pois 5 pedidos relacionados(as) foram encontrados(as)\n\n\nIncluindo:\n13: Order 13\n14: Order 14\n15: Order 15\n16: Order 16\n17: Order 17"
          end
          1.times { Order.create!(:category => category) }
          begin
            category.destroy
          rescue ActiveRecord::DetailedDeleteRestrictionError => e
            expect(e.detailed_message).to eq "Não pode ser excluído pois 6 pedidos relacionados(as) foram encontrados(as)\n\n\nIncluindo:\n13: Order 13\n14: Order 14\n15: Order 15\n16: Order 16\n...e mais 2"
          end

          Order.destroy_all
          expect { category.reload.destroy }.to_not raise_error
        end

        it 'should restrict has_one relationships' do
          order = Order.create!
          order_invoice = OrderInvoice.create!(:order => order)
          expect { order.reload.destroy }.to raise_error(
            ActiveRecord::DetailedDeleteRestrictionError,
            'Não pode ser excluído pois um(a) ordem de pedido relacionado(a) foi encontrado(a)'
          )

          order_invoice.destroy
          expect { order.reload.destroy }.to_not raise_error
        end
      end
    end


    context 'when restricting with error' do
      before do
        class Order < ActiveRecord::Base
          has_one :order_invoice, :dependent => :restrict_with_error
        end

        class Category < ActiveRecord::Base
          has_many :orders, :dependent => :restrict_with_error do
            def active
              self.select(&:active?)
            end
          end
        end
      end

      it 'should restrict has_many relationships' do
        category = Category.create!
        expect(Category.count).to eq 1
        5.times { Order.create!(:category => category) }
        category.destroy
        expect(Category.count).to eq 1
        Order.destroy_all
        category.reload.destroy
        expect(Category.count).to eq 0
      end

      it 'should restrict has_one relationships' do
        order = Order.create!
        expect(Order.count).to eq 1
        order_invoice = OrderInvoice.create!(:order => order)
        order.reload.destroy
        expect(Order.count).to eq 1

        order_invoice.destroy
        order.reload.destroy
        expect(Order.count).to eq 0
      end
    end
  end


end

