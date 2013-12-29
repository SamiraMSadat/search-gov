module HtmlSelectorsHelpers
  # Maps a name to a selector. Used primarily by the
  #
  #   When /^(.+) within (.+)$/ do |step, scope|
  #
  # step definitions in web_steps.rb
  #
  def selector_for(locator)
    case locator

    when /the page/
      "html > body"
    when /the Collection URL Prefixes modal/
      '#url-prefixes .modal-body .url-prefixes'
    when /the RSS URLs modal/
      '#urls .modal-body .urls'
    when /the RSS URL last crawl status error message/
      '.urls .error .last-crawl-status.in'
    when /the Supplemental URL last crawl status error message/
      '#indexed-documents .error .last-crawl-status.in'
    when /the Header & Footer form/
      '#edit-header-and-footer'
    when /the Admin Center content/
      '.l-content'
    when /the first scaffold row/
      '.records > tr:first-child'
    when /the first table body row/
      "table tbody tr:first-child"
    when /the SERP active navigation/
      '#nav .active'
    when /the SERP navigation/
      '#nav'

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #  when /the (notice|error|info) flash/
    #    ".flash.#{$1}"

    # You can also return an array to use a different selector
    # type, like:
    #
    #  when /the header/
    #    [:xpath, "//header"]

    # This allows you to provide a quoted selector as the scope
    # for "within" steps as was previously the default for the
    # web steps:
    when /"(.+)"/
      $1

    else
      raise "Can't find mapping from \"#{locator}\" to a selector.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(HtmlSelectorsHelpers)
