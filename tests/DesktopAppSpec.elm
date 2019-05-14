module DesktopAppSpec exposing (all)

import DesktopApp.Testable as DesktopApp
import Expect exposing (Expectation)
import Html
import Html.Events exposing (onClick)
import Test exposing (..)
import Test.Html.Selector exposing (text)
import TestContext


type alias TestModel =
    { count : Int }


type TestMsg
    = NoOp
    | Loaded Int
    | Increment


type alias TestContext =
    TestContext.TestContext TestMsg TestModel ( Cmd TestMsg, List DesktopApp.Effect )


start : TestContext
start =
    let
        program =
            DesktopApp.program
                { init = ( { count = 0 }, Cmd.none )
                , subscriptions = \model -> Sub.none
                , update =
                    \msg model ->
                        case msg of
                            NoOp ->
                                ( model, Cmd.none )

                            Loaded newCount ->
                                ( { model | count = newCount }
                                , Cmd.none
                                )

                            Increment ->
                                ( { model | count = model.count + 1 }
                                , Cmd.none
                                )
                , view =
                    \model ->
                        Html.div []
                            [ Html.text ("count:" ++ String.fromInt model.count)
                            , Html.button [ onClick Increment ] [ Html.text "Increment" ]
                            ]
                , files =
                    DesktopApp.jsonFile "data.json"
                        identity
                        (DesktopApp.jsonMapping Loaded
                            |> DesktopApp.withInt "count" .count
                        )
                , noOp = NoOp
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
                    |> simulateLoadFileNotFound "data.json"
                    |> TestContext.expectLastEffect (Tuple.second >> Expect.equal [ DesktopApp.WriteOut ( "data.json", """{"count":0}""" ) ])
        , test "writes stat on update" <|
            \() ->
                start
                    |> simulateLoadFileNotFound "data.json"
                    |> TestContext.clickButton "Increment"
                    |> TestContext.expectLastEffect (Tuple.second >> Expect.equal [ DesktopApp.WriteOut ( "data.json", """{"count":1}""" ) ])
        , test "loads persisted state when present" <|
            \() ->
                start
                    |> simulateLoadFile "data.json" """{"count":7}"""
                    |> TestContext.expectViewHas [ text "count:7" ]
        ]


simulateLoadFile :
    String
    -> String
    -> TestContext.TestContext TestMsg model ( cmd, List DesktopApp.Effect )
    -> TestContext.TestContext TestMsg model ( cmd, List DesktopApp.Effect )
simulateLoadFile expectedFilename loadedContent testContext =
    testContext
        |> TestContext.shouldHaveLastEffect (Tuple.second >> Expect.equal [ DesktopApp.LoadFile expectedFilename ])
        -- TODO: Avoid manually creating the msg after https://github.com/avh4/elm-program-test/issues/17 is implemented
        |> TestContext.update (Loaded 7)


simulateLoadFileNotFound :
    String
    -> TestContext.TestContext TestMsg model ( cmd, List DesktopApp.Effect )
    -> TestContext.TestContext TestMsg model ( cmd, List DesktopApp.Effect )
simulateLoadFileNotFound expectedFilename testContext =
    testContext
        |> TestContext.shouldHaveLastEffect (Tuple.second >> Expect.equal [ DesktopApp.LoadFile expectedFilename ])
        -- TODO: Avoid manually creating the msg after https://github.com/avh4/elm-program-test/issues/17 is implemented
        |> TestContext.update NoOp
