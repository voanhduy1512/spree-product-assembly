require 'spec_helper'

describe Spree::StockLocation do
  subject { create(:stock_location) }
  let(:assembly) { create(:product, name: "Sample Product Assembly") }
  let(:part1) { create(:product, can_be_part: true) }
  let(:part2) { create(:product, can_be_part: true) }
  let(:part1_stock_item) { subject.stock_items.where(variant_id: part1.master.id).first }
  let(:part2_stock_item) { subject.stock_items.where(variant_id: part2.master.id).first }
  let(:assembly_stock_item) { subject.stock_items.where(variant_id: assembly.master.id).first }
  let(:regular_product) { create(:product, name: "Mug") }
  let(:regular_stock_item) { subject.stock_items.where(variant_id: regular_product.master.id).first }

  before do
    # Add some default stock for the parts
    part1_stock_item.adjust_count_on_hand(10)
    part2_stock_item.adjust_count_on_hand(10)

    # Add parts to the assembly
    assembly.add_part part1.master, 1
    assembly.add_part part2.master, 3
  end

  context "with regular products" do
    context "unstocking" do
      it "creates a stock movement for the stock item" do
        expect {
          subject.unstock(regular_product.master, 1)
        }.to change { subject.stock_movements.where(stock_item_id: regular_stock_item.id).count }.by(1)
      end

      it "reduces the count_on_hand for the stock item" do
        subject.unstock(regular_product.master, 1)
        regular_stock_item.reload.count_on_hand.should eq -1
      end
    end

    context "restocking" do
      it "creates a stock movement for the stock item" do
        expect {
          subject.restock(regular_product.master, 1)
        }.to change { subject.stock_movements.where(stock_item_id: regular_stock_item.id).count }.by(1)
      end

      it "increase the count_on_hand for the stock item" do
        subject.restock(regular_product.master, 1)
        regular_stock_item.reload.count_on_hand.should eq 1
      end
    end
  end


  context "with product assemblies" do

    context "unstocking" do

      it "creates a movement for the parts" do
        [part1_stock_item, part2_stock_item].each do |stock_item|
          expect {
            subject.unstock(assembly.master, 1)
          }.to change { subject.stock_movements.where(stock_item_id: stock_item.id).count }.by(1)
        end
      end

      it "reduces the the count_on_hand for the parts" do
        subject.unstock(assembly.master, 2)
        part1_stock_item.reload.count_on_hand.should eq 8
        part2_stock_item.reload.count_on_hand.should eq 4
      end

      it "does not create a movement for the assembly" do
        expect {
          subject.unstock(assembly.master, 1)
        }.not_to change { subject.stock_movements.where(stock_item_id: assembly_stock_item.id).count }
      end

      it "does not reduce the count_on_hand for the assembly" do
        assembly_stock_item.read_attribute( :count_on_hand ).should eq 0
        subject.unstock(assembly.master, 2)
        # the value stored in the db:
        assembly_stock_item.read_attribute( :count_on_hand ).should eq 0
        # the count_on_hand method defined by extension:
        assembly_stock_item.count_on_hand.should eq 1
      end

    end

    context "restocking" do
      it "creates a movement for the parts" do
        [part1_stock_item, part2_stock_item].each do |stock_item|
          expect {
            subject.restock(assembly.master, 1)
          }.to change { subject.stock_movements.where(stock_item_id: stock_item.id).count }.by(1)
        end
      end

      it "increases the the count_on_hand for the parts" do
        subject.restock(assembly.master, 2)
        part1_stock_item.reload.count_on_hand.should eq 12
        part2_stock_item.reload.count_on_hand.should eq 16
      end

      it "does not create a movement for the parts" do
        expect {
          subject.restock(assembly.master, 1)
        }.not_to change { subject.stock_movements.where(stock_item_id: assembly_stock_item.id).count }
      end

      it "does not increase the count_on_hand for the parts" do
        assembly_stock_item.read_attribute( :count_on_hand ).should eq 0
        subject.restock(assembly.master, 2)
        # the value stored in the db:
        assembly_stock_item.read_attribute( :count_on_hand ).should eq 0
        # the count_on_hand method defined by extension:
        assembly_stock_item.count_on_hand.should eq 5
      end
    end

  end

end
