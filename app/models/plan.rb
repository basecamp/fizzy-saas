class Plan
  PLANS = {
    free_v1: { name: "Free", price: 0, card_limit: 1000, storage_limit: 1.gigabytes },
    monthly_v1: { name: "Unlimitted", price: 20, card_limit: Float::INFINITY, storage_limit: 5.gigabytes, stripe_price_id: ENV.fetch("STRIPE_MONTHLY_V1_PRICE_ID", "price_1SaHykRwChFE4it8PePOdDpS") }
  }

  attr_reader :key, :name, :price, :card_limit, :storage_limit, :stripe_price_id

  class << self
    def all
      @all ||= PLANS.map { |key, properties| new(key: key, **properties) }
    end

    def free
      @free ||= all.find(&:free?)
    end

    def paid
      @paid ||= all.find(&:paid?)
    end

    def find(key)
      @all_by_key ||= all.index_by(&:key).with_indifferent_access
      @all_by_key[key]
    end

    alias [] find
  end

  def initialize(key:, name:, price:, card_limit:, storage_limit:, stripe_price_id: nil)
    @key = key
    @name = name
    @price = price
    @card_limit = card_limit
    @storage_limit = storage_limit
    @stripe_price_id = stripe_price_id
  end

  def free?
    price.zero?
  end

  def paid?
    !free?
  end

  def limit_cards?
    card_limit != Float::INFINITY
  end

  def formatted_storage_limit
    ActionController::Base.helpers.number_to_human_size(storage_limit).delete(" ")
  end
end
