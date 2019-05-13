module Main exposing (main)

import BeautifulExample
import DesktopApp as App
import Html exposing (Html)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Json.Encode as Json


type alias Model =
    { count : Int
    }


main =
    App.program
        { init = ( { count = 0 }, Cmd.none )
        , update = \msg model -> ( update msg model, Cmd.none )
        , subscriptions = \_ -> Sub.none
        , view = view
        , files = files
        , noOp = NoOp
        }


type Msg
    = NoOp
    | Loaded Model
    | Increment
    | Decrement


update : Msg -> Model -> Model
update msg model =
    case msg of
        NoOp ->
            model

        Loaded newModel ->
            newModel

        Increment ->
            { model | count = model.count + 1 }

        Decrement ->
            { model | count = model.count - 1 }


view : Model -> Html Msg
view model =
    BeautifulExample.view
        { title = "iCount"
        , details = Nothing
        , color = Nothing
        , maxWidth = 600
        , githubUrl = Nothing
        , documentationUrl = Nothing
        }
    <|
        Html.div []
            [ Html.button
                [ onClick Decrement ]
                [ Html.text "-" ]
            , Html.span
                [ style "padding" "0 20px" ]
                [ Html.text (String.fromInt model.count)
                ]
            , Html.button
                [ onClick Increment ]
                [ Html.text "+" ]
            ]


files : App.File Model Msg
files =
    App.jsonMapping Model
        |> App.withInt "count" .count
        |> App.jsonFile "example-app.json" Loaded
