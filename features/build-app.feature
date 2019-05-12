Feature: Building an Elm electron app

Scenario: simple app that writes data files
  When I create a new app
  And I make change my program's files to
    """
    App.jsonFile "test-app.json" (App.object (always ()) |> App.field "key" (always "") (App.staticString "value"))
    """
  And I run the app
  Then the JSON file "test-app.json" is
    """
    {"key":"value"}
    """
