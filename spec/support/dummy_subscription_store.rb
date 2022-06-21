# frozen_string_literal: true

require 'event_store_client/catch_up_subscription'

class DummySubscriptionStore
  def load_all_position(name)
    sub = get(name)
    return nil unless sub

    sub = JSON.parse(sub)
    { commit_position: sub['commit_position'], prepare_position: sub['prepare_position'] }
  end

  def add(subscription)
    write_subscription(subscription)
  end

  def update_position(subscription)
    write_subscription(subscription)
  end

  def clean_unused(used)
    # not implemented
  end

  def reset(subscriptions)
    subscriptions.each { |sub| store.delete(sub.name) }
  end

  private

  attr_accessor :store

  def initialize(namespace)
    @store = {}
  end

  def get(key)
    store[key]
  end

  def set(key, value)
    store[key] = value
  end

  def write_subscription(subscription)
    set(
      subscription.name,
      {
        commit_position: subscription.position[:commit_position],
        prepare_position: subscription.position[:prepare_position]
      }.to_json
    )
  end
end
