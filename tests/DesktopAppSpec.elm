module DesktopAppSpec exposing (all)

import DesktopApp.JsonMapping as JsonMapping
import DesktopApp.Testable as DesktopApp
import Expect exposing (Expectation)
import Html
import Html.Events exposing (onClick)
import Json.Decode
import Json.Encode
import ProgramTest
import SimulatedEffect.Cmd
import SimulatedEffect.Ports
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
        |> ProgramTest.withSimulatedEffects simulateAllEffects
        |> ProgramTest.start ()


simulateAllEffects : ( Cmd (DesktopApp.Msg TestMsg), List DesktopApp.Effect ) -> ProgramTest.SimulatedEffect msg
simulateAllEffects ( _, effects ) =
    SimulatedEffect.Cmd.batch (List.map simulateEffect effects)


simulateEffect : DesktopApp.Effect -> ProgramTest.SimulatedEffect msg
simulateEffect effect =
    case effect of
        DesktopApp.WriteUserData content ->
            SimulatedEffect.Ports.send "writeUserData" (Json.Encode.string content)

        DesktopApp.LoadUserData ->
            SimulatedEffect.Ports.send "loadUserData" Json.Encode.null


all : Test
all =
    describe "DesktopApp"
        [ test "writes state on first init" <|
            \() ->
                start
                    |> simulateUserDataNotFound
                    |> expectWriteUserData """{"count":0}"""
        , test "writes stat on update" <|
            \() ->
                start
                    |> simulateUserDataNotFound
                    |> clearRecordedPortValues
                    |> ProgramTest.clickButton "Increment"
                    |> expectWriteUserData """{"count":1}"""
        , test "loads persisted state when present" <|
            \() ->
                start
                    |> simulateLoadUserData """{"count":7}"""
                    |> ProgramTest.expectViewHas [ text "count:7" ]
        , test "does not write to disk if nothing persisted has changed" <|
            \() ->
                start
                    |> simulateUserDataNotFound
                    |> clearRecordedPortValues
                    |> ProgramTest.clickButton "Toggle"
                    |> ProgramTest.expectOutgoingPortValues
                        "writeUserData"
                        (Json.Decode.succeed ())
                        (Expect.equal [])
        ]


clearRecordedPortValues : ProgramTest -> ProgramTest
clearRecordedPortValues =
    ProgramTest.ensureOutgoingPortValues
        "writeUserData"
        (Json.Decode.succeed ())
        (\_ -> Expect.pass)


expectWriteUserData : String -> ProgramTest -> Expectation
expectWriteUserData expected =
    ProgramTest.expectOutgoingPortValues
        "writeUserData"
        Json.Decode.string
        (Expect.equal [ expected ])


simulateLoadUserData : String -> ProgramTest -> ProgramTest
simulateLoadUserData loadedContent testContext =
    testContext
        |> ProgramTest.ensureOutgoingPortValues "loadUserData"
            (Json.Decode.succeed ())
            (List.length >> Expect.greaterThan 0)
        |> ProgramTest.update (DesktopApp.UserDataLoaded (Just loadedContent))


simulateUserDataNotFound :
    ProgramTest.ProgramTest model (DesktopApp.Msg msg) ( cmd, List DesktopApp.Effect )
    -> ProgramTest.ProgramTest model (DesktopApp.Msg msg) ( cmd, List DesktopApp.Effect )
simulateUserDataNotFound testContext =
    testContext
        |> ProgramTest.ensureOutgoingPortValues "loadUserData"
            (Json.Decode.succeed ())
            (List.length >> Expect.greaterThan 0)
        |> ProgramTest.update (DesktopApp.UserDataLoaded Nothing)
