module Main exposing (main)

import App
import Html
import Json.Encode as Json


main =
    App.program
        { init = ( (), Cmd.none )
        , update = \() () -> ( (), Cmd.none )
        , subscriptions = \() -> Sub.none
        , view = \() -> Html.text ""
        , files =
            \() ->
                App.jsonFile "test-app.json"
                    (Json.object
                        [ ( "key", Json.string "value" )
                        ]
                    )
        }
