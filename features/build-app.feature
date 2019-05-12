Feature: Building an Elm electron app

Scenario: simple app that writes data files
  When I create a new app
  And I make change my program's files to
    """
    \_ -> App.jsonFile "test-app.json" (Json.object [ ("key", Json.string "value") ])
    """
  And I run the app
  Then the JSON file "test-app.json" is
    """
    {"key":"value"}
    """
