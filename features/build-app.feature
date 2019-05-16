Feature: Building an Elm electron app

Scenario: the init app compiles
  When I create a new app
  Then I can successfully build my app


Scenario: simple app that writes data files
  When I create a new app
  And I make change my program's persistence to
    """
    Just (JsonMapping.object () |> JsonMapping.staticString "key" "value")
    """
  And I run the app with "test-data.json"
  Then the JSON file "test-data.json" is
    """
    {"key":"value"}
    """


Scenario: app modifies existing data
  Given an existing app
  And a JSON file "test-data.json"
    """
    {"count":3}
    """
  And I run the app with "test-data.json"
  And click "+"
  Then the JSON file "test-data.json" is
    """
    {"count":4}
    """
