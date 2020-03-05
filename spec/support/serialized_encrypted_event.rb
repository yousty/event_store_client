# frozen_string_literal: true

class SerializedEncryptedEvent
  attr_reader :type

  def metadata
    '{"created_at":"2019-12-05 19:37:38 +0100"}'
  end

  def data
    JSON.generate(
      user_id: 'dab48d26-e4f8-41fc-a9a8-59657e590716',
      first_name: 'encrypted',
      last_name: 'encrypted',
      profession: 'Jedi',
      encrypted: 'darthvader'
    )
  end

  private

  def initialize(type:)
    @type = type
  end
end
