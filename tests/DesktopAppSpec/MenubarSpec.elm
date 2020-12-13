module DesktopAppSpec.MenubarSpec exposing (..)

{-| Tests about the Menubar API for DesktopApps
-}

import DesktopApp.JsonMapping as JsonMapping
import DesktopApp.Menubar as Menubar exposing (Menubar(..))
import DesktopApp.Testable as DesktopApp
import DesktopAppHelper exposing (simulateAllEffects)
import Expect exposing (Expectation)
import Html
import Html.Events exposing (onClick)
import ProgramTest
import Test exposing (..)


type alias TestModel =
    { currentMenu : Menubar
    }


type TestMsg
    = Loaded
    | SetMenu Menubar


type alias ProgramTest =
    ProgramTest.ProgramTest
        (DesktopApp.Model TestModel)
        (DesktopApp.Msg TestMsg)
        ( Cmd (DesktopApp.Msg TestMsg), List DesktopApp.Effect )


all : Test
all =
    describe "DesktopApp"
        [ test "with no menu, tells backend to hide the menubar" <|
            \() ->
                start DesktopApp.noMenu
                    |> expectSetMenu [ NoMenu ]
        , test "with default menu, does not hide the menubar" <|
            \() ->
                start DesktopApp.defaultMenu
                    |> expectSetMenu [ DefaultMenu ]
        , test "with persistence, honors menubar setting once data is loaded" <|
            \() ->
                startHelper True DesktopApp.noMenu
                    |> ProgramTest.update (DesktopApp.UserDataLoaded (Just "{}"))
                    |> expectSetMenu [ NoMenu ]
        , test "with persistence, honors menubar setting on initial run" <|
            \() ->
                startHelper True DesktopApp.noMenu
                    |> ProgramTest.update (DesktopApp.UserDataLoaded Nothing)
                    |> expectSetMenu [ NoMenu ]
        , test "can change the menubar" <|
            \() ->
                start DesktopApp.noMenu
                    |> ensureSetMenu [ NoMenu ]
                    |> ProgramTest.clickButton "Default menu"
                    |> expectSetMenu [ DefaultMenu ]
        ]


start : Menubar -> ProgramTest
start menubar =
    startHelper False menubar


startHelper : Bool -> Menubar -> ProgramTest
startHelper usePersistence menubar =
    let
        program =
            DesktopApp.program
                { init =
                    ( { currentMenu = menubar
                      }
                    , Cmd.none
                    )
                , subscriptions = \_ -> Sub.none
                , update =
                    \msg model ->
                        case msg of
                            Loaded ->
                                ( model, Cmd.none )

                            SetMenu newMenu ->
                                ( { model | currentMenu = newMenu }, Cmd.none )
                , view =
                    \model ->
                        { title = ""
                        , menubar = model.currentMenu
                        , body =
                            [ Html.button
                                [ onClick (SetMenu DesktopApp.defaultMenu) ]
                                [ Html.text "Default menu" ]
                            ]
                        }
                , persistence =
                    if usePersistence then
                        JsonMapping.object Loaded
                            |> Just

                    else
                        Nothing
                }
    in
    ProgramTest.createDocument
        { init = program.init
        , update = program.update
        , view = program.view
        }
        |> ProgramTest.withSimulatedEffects simulateAllEffects
        |> ProgramTest.start ()


expectSetMenu : List Menubar -> ProgramTest -> Expectation
expectSetMenu expected =
    ensureSetMenu expected
        >> ProgramTest.done


ensureSetMenu : List Menubar -> ProgramTest -> ProgramTest
ensureSetMenu expected =
    ProgramTest.ensureOutgoingPortValues
        "setMenu"
        (JsonMapping.decoder Menubar.mapping)
        (Expect.equal expected)
