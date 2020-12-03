module DesktopAppSpec.WithNoPersistenceSpec exposing (all)

import DesktopApp.Testable as DesktopApp
import DesktopAppHelper exposing (simulateAllEffects)
import Expect exposing (Expectation)
import Html
import Html.Events exposing (onClick)
import Json.Decode
import ProgramTest
import Test exposing (..)
import Test.Html.Selector exposing (class, text)


type alias TestModel =
    { count : Int
    , uiState : Bool
    }


type TestMsg
    = Loaded Int
    | Increment
    | Toggle


type alias ProgramTest =
    ProgramTest.ProgramTest
        (DesktopApp.Model TestModel)
        (DesktopApp.Msg TestMsg)
        ( Cmd (DesktopApp.Msg TestMsg), List DesktopApp.Effect )


start : ProgramTest
start =
    let
        program =
            DesktopApp.program
                { init =
                    ( { count = 0
                      , uiState = False
                      }
                    , Cmd.none
                    )
                , subscriptions = \_ -> Sub.none
                , update =
                    \msg model ->
                        case msg of
                            Loaded newCount ->
                                ( { model | count = newCount }
                                , Cmd.none
                                )

                            Increment ->
                                ( { model | count = model.count + 1 }
                                , Cmd.none
                                )

                            Toggle ->
                                ( { model | uiState = not model.uiState }
                                , Cmd.none
                                )
                , view =
                    \model ->
                        { title = ""
                        , menubar = DesktopApp.defaultMenu
                        , body =
                            [ Html.text ("count:" ++ String.fromInt model.count)
                            , Html.text ("uiState:" ++ Debug.toString model.uiState)
                            , Html.button [ onClick Increment ] [ Html.text "Increment" ]
                            , Html.button [ onClick Toggle ] [ Html.text "Toggle" ]
                            ]
                        }
                , persistence = Nothing
                }
    in
    ProgramTest.createDocument
        { init = program.init
        , update = program.update
        , view = program.view
        }
        |> ProgramTest.withSimulatedEffects simulateAllEffects
        |> ProgramTest.start ()


all : Test
all =
    describe "DesktopApp with no data persistence"
        [ test "does not try to load state" <|
            \() ->
                start
                    |> ProgramTest.expectOutgoingPortValues
                        "loadUserData"
                        (Json.Decode.succeed ())
                        (Expect.equal [])
        , test "skips showing the loading state" <|
            \() ->
                start
                    |> Expect.all
                        [ ProgramTest.expectViewHas [ text "count:0" ]
                        , ProgramTest.expectViewHasNot [ class DesktopApp.htmlClasses.loading ]
                        ]
        ]
