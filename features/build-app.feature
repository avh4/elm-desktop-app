Feature: Building an Elm electron app

Scenario: simple app that writes data files
  When I create a new app
  And I make change my program's files to
    """
    App.jsonFile identity (App.jsonMapping () |> App.staticString "key" "value")
    """
  And I run the app
  Then the JSON file "user-data.json" is
    """
    {"key":"value"}
    """

Scenario: app modifies existing data
  Given an existing app
  And a JSON file "user-data.json"
    """
    {"count":3}
    """
  When I run the app
  And click "+"
  Then the JSON file "user-data.json" is
    """
    {"count":4}
    """
