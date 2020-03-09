# frozen_string_literal: true

class DummyRepository
  class Key
    attr_accessor :iv, :cipher, :id
    def initialize(id:, **)
      @id = id
    end
  end

  def find(user_id)
    Key.new(id: user_id)
  end

  def encrypt(*)
    'darthvader'
  end

  def decrypt(*)
    JSON.generate(first_name: 'Anakin', last_name: 'Skylwalker')
  end
end
