Spree::StockLocation.class_eval do

  def move(variant, quantity, originator=nil)
    product = variant.product
    if product.assembly?
      product.parts.each do |part|
        part_quantity = product.count_of(part)
        move_redifined(part, quantity * part_quantity, originator)
      end
    else
      move_redifined(variant, quantity, originator)
    end
  end

  def move_redifined(variant, quantity, originator = nil)
    stock_item_or_create(variant).stock_movements.create!(quantity: quantity,
                                                          originator: originator)
  end

end
