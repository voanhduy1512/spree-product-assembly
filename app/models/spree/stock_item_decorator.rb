Spree::StockItem.class_eval do
  def count_on_hand
    variant.product.assembly? ? on_hand_with_assembly : read_attribute(:count_on_hand)
  end

  def on_hand_with_assembly
    variant.product.parts.map{|v| stock_location.count_on_hand(v) / variant.product.count_of(v) }.min
  end
end
