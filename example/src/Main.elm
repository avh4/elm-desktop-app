module Main exposing (main)

import BeautifulExample
import Browser
import Color
import DesktopApp
import DesktopApp.JsonMapping as JsonMapping exposing (ObjectMapping)
import Html exposing (Html)
import Html.Attributes exposing (placeholder, style, type_, value)
import Html.Events exposing (onCheck, onClick, onInput)
import Json.Encode as Json
import Time


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
    { name : String
    , count : Int
    , darkMode : Bool
    }


init : Model
init =
    { name = ""
    , count = 0
    , darkMode = False
    }


type Msg
    = Loaded String Int
    | Increment
    | Decrement
    | NameChanged String
    | DarkModeChanged Bool


update : Msg -> Model -> Model
update msg model =
    case msg of
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


view : Model -> Browser.Document Msg
view model =
    { title =
        if String.isEmpty (String.trim model.name) then
            "iCount"

        else
            String.trim model.name ++ "'s iCount"
    , body =
        [ BeautifulExample.view
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
                        , Html.text "Dark mode (not persisted)"
                        ]
                    ]
                ]
        ]
    }


persistence : ObjectMapping Model Msg
persistence =
    JsonMapping.object Loaded
        |> JsonMapping.with "name" .name JsonMapping.string
        |> JsonMapping.with "count" .count JsonMapping.int
