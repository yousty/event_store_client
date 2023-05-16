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

  # A simple implementation of in-memory key repo storage and simple encryptor/decryptor. Don't do
  # this in your real implementation! It is here just to emulate encryption/decryption lifecycle.
  class << self
    attr_accessor :repository

    def reset
      self.repository = {}
    end

    def encrypt(str)
      Base64.encode64(str)
    end

    def decrypt(str)
      Base64.decode64(str)
    end
  end
  reset

  def find(user_id)
    Dry::Monads::Success(Key.new(id: user_id))
  end

  def encrypt(key:, message:)
    self.class.repository[key.id] = self.class.encrypt(message)
    message = Message.new({ message: self.class.repository[key.id] })
    Dry::Monads::Success(message)
  end

  def decrypt(key:, message:)
    decrypted =
      if self.class.repository[key.id]
        self.class.decrypt(self.class.repository[key.id])
      else
        {}.to_json
      end
    message = Message.new({ message: decrypted })
    Dry::Monads::Success(message)
  end
end
