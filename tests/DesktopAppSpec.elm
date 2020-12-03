module DesktopAppSpec exposing (all)

import DesktopApp.JsonMapping as JsonMapping
import DesktopApp.Testable as DesktopApp
import Expect exposing (Expectation)
import Html
import Html.Events exposing (onClick)
import ProgramTest
import Test exposing (..)
import Test.Html.Selector exposing (text)


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
                , persistence =
                    JsonMapping.object Loaded
                        |> JsonMapping.with "count" .count JsonMapping.int
                        |> Just
                }
    in
    ProgramTest.createDocument
        { init = program.init
        , update = program.update
        , view = \model -> program.view model
        }
        |> ProgramTest.start ()


all : Test
all =
    describe "DesktopApp"
        [ test "writes state on first init" <|
            \() ->
                start
                    |> simulateUserDataNotFound
                    |> ProgramTest.expectLastEffect (Tuple.second >> Expect.equal [ DesktopApp.WriteUserData """{"count":0}""" ])
        , test "writes stat on update" <|
            \() ->
                start
                    |> simulateUserDataNotFound
                    |> ProgramTest.clickButton "Increment"
                    |> ProgramTest.expectLastEffect (Tuple.second >> Expect.equal [ DesktopApp.WriteUserData """{"count":1}""" ])
        , test "loads persisted state when present" <|
            \() ->
                start
                    |> simulateLoadUserData """{"count":7}"""
                    |> ProgramTest.expectViewHas [ text "count:7" ]
        , test "does not write to disk if nothing persisted has changed" <|
            \() ->
                start
                    |> simulateUserDataNotFound
                    |> ProgramTest.clickButton "Toggle"
                    |> ProgramTest.expectLastEffect (Tuple.second >> Expect.equal [])
        ]


simulateLoadUserData :
    String
    -> ProgramTest.ProgramTest model (DesktopApp.Msg msg) ( cmd, List DesktopApp.Effect )
    -> ProgramTest.ProgramTest model (DesktopApp.Msg msg) ( cmd, List DesktopApp.Effect )
simulateLoadUserData loadedContent testContext =
    testContext
        |> ProgramTest.ensureLastEffect (Tuple.second >> Expect.equal [ DesktopApp.LoadUserData ])
        -- TODO: Avoid manually creating the msg after https://github.com/avh4/elm-program-test/issues/17 is implemented
        |> ProgramTest.update (DesktopApp.UserDataLoaded (Just loadedContent))


simulateUserDataNotFound :
    ProgramTest.ProgramTest model (DesktopApp.Msg msg) ( cmd, List DesktopApp.Effect )
    -> ProgramTest.ProgramTest model (DesktopApp.Msg msg) ( cmd, List DesktopApp.Effect )
simulateUserDataNotFound testContext =
    testContext
        |> ProgramTest.ensureLastEffect (Tuple.second >> Expect.equal [ DesktopApp.LoadUserData ])
        -- TODO: Avoid manually creating the msg after https://github.com/avh4/elm-program-test/issues/17 is implemented
        |> ProgramTest.update (DesktopApp.UserDataLoaded Nothing)
