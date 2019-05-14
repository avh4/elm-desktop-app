module DesktopAppSpec exposing (all)

import DesktopApp.Testable as DesktopApp
import Expect exposing (Expectation)
import Html
import Test exposing (..)
import TestContext exposing (TestContext)


start : TestContext () () ( Cmd (), List DesktopApp.Effect )
start =
    let
        program =
            DesktopApp.program
                { init = ( (), Cmd.none )
                , subscriptions = \() -> Sub.none
                , update = \() () -> ( (), Cmd.none )
                , view = \() -> Html.text ""
                , files = DesktopApp.jsonFile "data.json" identity (DesktopApp.jsonMapping ())
                , noOp = ()
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
        [ test "loads persisted state" <|
            \() ->
                start
                    |> TestContext.done
        ]
