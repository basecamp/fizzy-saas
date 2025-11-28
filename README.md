This is a Rails engine that [37signals](https://37signals.com/) bundles with [Fizzy](https://github.com/basecamp/fizzy) to offer the hosted version at https://fizzy.do.

## Development

To make Fizzy run in SaaS mode, run this in the terminal:

```ruby
bin/rails saas:enable
```

To can go back to open source mode:

```ruby
bin/rails saas:disable
```

Then you can work do [Fizzy development as usual](https://github.com/basecamp/fizzy).

## Environments

Fizzy is deployed with [Kamal](https://kamal-deploy.org/). You'll need to have the 1Password CLI set up in order to access the secrets that are used when deploying. Provided you have that, it should be as simple as `bin/kamal deploy` to the correct environment.

## Handbook

See the [Fizzy handbook](https://handbooks.37signals.works/18/fizzy) for runbooks and more.

### Beta

Beta is primarily intended for testing product features.

Beta tenant is:

- https://fizzy-beta.37signals.com

This environment uses local disk for Active Storage.


### Staging

Staging is primarily intended for testing infrastructure changes.

- https://fizzy.37signals-staging.com/

This environment uses a FlashBlade bucket for blob storage, and shares nothing with Production. We may periodically copy data here from production.


### Production

- https://app.fizzy.do/

This environment uses a FlashBlade bucket for blob storage.
