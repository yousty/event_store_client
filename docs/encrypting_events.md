# Encrypting events

To encrypt/decrypt events payload, you can use an encrypted mapper.


```ruby
mapper = EventStoreClient::Mapper::Encrypted.new(key_repository)

EventStoreClient.configure do |config|
  config.mapper = mapper
end
```

The Encrypted mapper uses the encryption key repository to encrypt data in your events according to the event definition.

Here is the minimal repository interface for this to work.

```ruby
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
    { first_name: 'Anakin', last_name: 'Skywalker'}
  end
end
```

Now, having that, you only need to define the event encryption schema:

```ruby
class EncryptedEvent < EventStoreClient::DeserializedEvent
  def schema
    Dry::Schema.Params do
      required(:user_id).value(:string)
      required(:first_name).value(:string)
      required(:last_name).value(:string)
      required(:profession).value(:string)
    end
  end

  def self.encryption_schema
    {
      key: ->(data) { data['user_id'] },
      attributes: %i[first_name last_name email]
    }
  end
end

event = EncryptedEvent.new(
  user_id: SecureRandom.uuid,
  first_name: 'Anakin',
  last_name: 'Skywalker',
  profession: 'Jedi'
)
```

When you'll publish this event, in the store will be saved:

```ruby
{
  'data' => {
    'user_id' => 'dab48d26-e4f8-41fc-a9a8-59657e590716',
    'first_name' => 'encrypted',
    'last_name' => 'encrypted',
    'profession' => 'Jedi',
    'encrypted' => '2345l423lj1#$!lkj24f1'
  },
  type: 'EncryptedEvent'
  metadata: { ... }
}
```
