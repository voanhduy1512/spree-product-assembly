require 'spec_helper'

describe Spree::StockItem do
  let(:stock_location) { create(:stock_location) }
  let(:assembly) { create(:product, name: "Sample Product Assembly") }
  let(:part1) { create(:product, can_be_part: true) }
  let(:part2) { create(:product, can_be_part: true) }
  let(:part1_stock_item) { stock_location.stock_items.where(variant_id: part1.master.id).first }
  let(:part2_stock_item) { stock_location.stock_items.where(variant_id: part2.master.id).first }

  before do
    # Add some default stock for the parts
    part1_stock_item.adjust_count_on_hand(10)
    part2_stock_item.adjust_count_on_hand(10)

    # Add parts to the assembly
    assembly.add_part part1.master, 1
    assembly.add_part part2.master, 3
  end

  subject {stock_location.stock_items.where(variant_id: assembly.master.id).first }


  it "has correct count_on_hand for parts" do
    part1_stock_item.count_on_hand.should eq(10)
    part2_stock_item.count_on_hand.should eq(10)
  end


  context "count_on_hand of product assemblies" do

    it "returns the availabiliy for the least available part" do
      subject.count_on_hand.should eq(3)
    end

  end

end
