module Main exposing (main)

import Browser
import DesktopApp
import DesktopApp.JsonMapping as JsonMapping
import Html exposing (Html)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Json.Encode as Json


main : DesktopApp.Program Model Msg
main =
    DesktopApp.program
        { init = ( init, Cmd.none )
        , update = \msg model -> ( update msg model, Cmd.none )
        , subscriptions = \model -> Sub.none
        , view = view
        , persistence = Just persistence
        }


type alias Model =
    { count : Int
    }


init : Model
init =
    { count = 0
    }


type Msg
    = Loaded Int
    | Increment


update : Msg -> Model -> Model
update msg model =
    case msg of
        Loaded newCount ->
            { model | count = newCount }

        Increment ->
            { model | count = model.count + 1 }


view : Model -> Browser.Document Msg
view model =
    { title = ""
    , body =
        [ Html.span
            [ style "padding" "0 20px" ]
            [ Html.text (String.fromInt model.count)
            ]
        , Html.button
            [ onClick Increment ]
            [ Html.text "+" ]
        ]
    }


persistence : JsonMapping.ObjectMapping Model Msg
persistence =
    JsonMapping.object Loaded
        |> JsonMapping.with "count" .count JsonMapping.int
