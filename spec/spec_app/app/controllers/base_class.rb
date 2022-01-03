# frozen_string_literal: true

class BaseClass
  # Do NOT use a controller inherited base class to add concerns!
  # If you do that, you'd be sharing state (i.e. overriding/adding) from  concerns across controllers
  # which will probably lead to sharing issues you didn't expect.
  # For example: any controller adding after/before/around filters will be visible
  # to any other controllers sharing the concern.
  # Include a concern to all of them instead

  # Inheritance of classes should be independent from the concerns.
  # I.e., you can use class inheritance in cases where it makes sense from an OO point of view
  # but for the most part, you can probably share code through modules/concerns too.
  def this_is_shared; end
end
