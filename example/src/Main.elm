module Main exposing (main)

import BeautifulExample
import Color
import DesktopApp as App
import Html exposing (Html)
import Html.Attributes exposing (placeholder, style, type_, value)
import Html.Events exposing (onCheck, onClick, onInput)
import Json.Encode as Json
import Time


type alias Model =
    { name : String
    , count : Int
    , darkMode : Bool
    }


main : Program () (App.Model Model) Msg
main =
    App.program
        { init =
            ( { name = ""
              , count = 0
              , darkMode = False
              }
            , Cmd.none
            )
        , update = \msg model -> ( update msg model, Cmd.none )
        , subscriptions = \model -> Sub.none
        , view = view
        , files = files
        , noOp = NoOp
        }


type Msg
    = NoOp
    | Loaded String Int
    | Increment
    | Decrement
    | NameChanged String
    | DarkModeChanged Bool


update : Msg -> Model -> Model
update msg model =
    case msg of
        NoOp ->
            model

        Loaded newName newCount ->
            { model
                | name = newName
                , count = newCount
            }

        Increment ->
            { model | count = model.count + 1 }

        Decrement ->
            { model | count = model.count - 1 }

        NameChanged newName ->
            { model | name = newName }

        DarkModeChanged newDarkMode ->
            { model | darkMode = newDarkMode }


view : Model -> Html Msg
view model =
    BeautifulExample.view
        { title = "iCount"
        , details = Nothing
        , color =
            if model.darkMode then
                Just Color.black

            else
                Nothing
        , maxWidth = 600
        , githubUrl = Nothing
        , documentationUrl = Nothing
        }
    <|
        Html.div []
            [ Html.div []
                [ Html.input
                    [ onInput NameChanged
                    , value model.name
                    , placeholder "Your name"
                    ]
                    []
                ]
            , Html.button
                [ onClick Decrement ]
                [ Html.text "-" ]
            , Html.span
                [ style "padding" "0 20px" ]
                [ Html.text (String.fromInt model.count)
                ]
            , Html.button
                [ onClick Increment ]
                [ Html.text "+" ]
            , Html.div []
                [ Html.label []
                    [ Html.input
                        [ onCheck DarkModeChanged
                        , type_ "checkbox"
                        ]
                        []
                    , Html.text "Dark mode"
                    ]
                ]
            ]


files : App.File Model Msg
files =
    App.jsonMapping Loaded
        |> App.withString "name" .name
        |> App.withInt "count" .count
        |> App.jsonFile identity
