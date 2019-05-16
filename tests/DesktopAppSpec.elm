module DesktopAppSpec exposing (all)

import DesktopApp.JsonMapping as JsonMapping
import DesktopApp.Testable as DesktopApp
import Expect exposing (Expectation)
import Html
import Html.Events exposing (onClick)
import Test exposing (..)
import Test.Html.Selector exposing (text)
import TestContext


type alias TestModel =
    { count : Int
    , uiState : Bool
    }


type TestMsg
    = Loaded Int
    | Increment
    | Toggle


type alias TestContext =
    TestContext.TestContext (DesktopApp.Msg TestMsg) (DesktopApp.Model TestModel) ( Cmd (DesktopApp.Msg TestMsg), List DesktopApp.Effect )


start : TestContext
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
                , subscriptions = \model -> Sub.none
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
                        , body =
                            [ Html.text ("count:" ++ String.fromInt model.count)
                            , Html.text ("uiState:" ++ Debug.toString model.uiState)
                            , Html.button [ onClick Increment ] [ Html.text "Increment" ]
                            , Html.button [ onClick Toggle ] [ Html.text "Toggle" ]
                            ]
                        }
                , persistence =
                    JsonMapping.object Loaded
                        |> JsonMapping.withInt "count" .count
                        |> Just
                }
    in
    TestContext.create
        { init = program.init ()
        , update = program.update
        , view = \model -> Html.node "body" [] (program.view model).body
        }


all : Test
all =
    describe "DesktopApp"
        [ test "writes state on first init" <|
            \() ->
                start
                    |> simulateUserDataNotFound
                    |> TestContext.expectLastEffect (Tuple.second >> Expect.equal [ DesktopApp.WriteUserData """{"count":0}""" ])
        , test "writes stat on update" <|
            \() ->
                start
                    |> simulateUserDataNotFound
                    |> TestContext.clickButton "Increment"
                    |> TestContext.expectLastEffect (Tuple.second >> Expect.equal [ DesktopApp.WriteUserData """{"count":1}""" ])
        , test "loads persisted state when present" <|
            \() ->
                start
                    |> simulateLoadUserData """{"count":7}"""
                    |> TestContext.expectViewHas [ text "count:7" ]
        , test "does not write to disk if nothing persisted has changed" <|
            \() ->
                start
                    |> simulateUserDataNotFound
                    |> TestContext.clickButton "Toggle"
                    |> TestContext.expectLastEffect (Tuple.second >> Expect.equal [])
        ]


simulateLoadUserData :
    String
    -> TestContext.TestContext (DesktopApp.Msg TestMsg) model ( cmd, List DesktopApp.Effect )
    -> TestContext.TestContext (DesktopApp.Msg TestMsg) model ( cmd, List DesktopApp.Effect )
simulateLoadUserData loadedContent testContext =
    testContext
        |> TestContext.shouldHaveLastEffect (Tuple.second >> Expect.equal [ DesktopApp.LoadUserData ])
        -- TODO: Avoid manually creating the msg after https://github.com/avh4/elm-program-test/issues/17 is implemented
        |> TestContext.update (DesktopApp.AppMsg (Loaded 7))


simulateUserDataNotFound :
    TestContext.TestContext (DesktopApp.Msg msg) model ( cmd, List DesktopApp.Effect )
    -> TestContext.TestContext (DesktopApp.Msg msg) model ( cmd, List DesktopApp.Effect )
simulateUserDataNotFound testContext =
    testContext
        |> TestContext.shouldHaveLastEffect (Tuple.second >> Expect.equal [ DesktopApp.LoadUserData ])
        -- TODO: Avoid manually creating the msg after https://github.com/avh4/elm-program-test/issues/17 is implemented
        |> TestContext.update DesktopApp.NoOp
