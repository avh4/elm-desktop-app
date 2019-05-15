module Main exposing (main)

import DesktopApp as App
import Html exposing (Html)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Json.Encode as Json


type alias Model =
    { count : Int
    }


main : Program () (App.Model Model) Msg
main =
    App.program
        { init = ( init, Cmd.none )
        , update = \msg model -> ( update msg model, Cmd.none )
        , subscriptions = \model -> Sub.none
        , view = view
        , files = files
        , noOp = NoOp
        }


init : Model
init =
    { count = 0
    }


type Msg
    = NoOp
    | Loaded Int
    | Increment


update : Msg -> Model -> Model
update msg model =
    case msg of
        NoOp ->
            model

        Loaded newCount ->
            { model | count = newCount }

        Increment ->
            { model | count = model.count + 1 }


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.span
            [ style "padding" "0 20px" ]
            [ Html.text (String.fromInt model.count)
            ]
        , Html.button
            [ onClick Increment ]
            [ Html.text "+" ]
        ]


files : App.File Model Msg
files =
    App.jsonMapping Loaded
        |> App.withInt "count" .count
        |> App.jsonFile identity
