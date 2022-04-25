# frozen_string_literal: true

class DummyRepository
  Message = Struct.new(:attributes)

  class Key
    attr_accessor :iv, :cipher, :id
    def initialize(id:, **)
      @id = id
    end

    def attributes
      {}
    end
  end

  def find(user_id)
    Dry::Monads::Success(Key.new(id: user_id))
  end

  def encrypt(*)
    message = Message.new(attributes: { message: 'darthvader' })
    Dry::Monads::Success(message)
  end

  def decrypt(*)
    message = Message.new(
      attributes: { message: JSON.generate(first_name: 'Anakin', last_name: 'Skylwalker') }
    )
    Dry::Monads::Success(message)
  end
end
