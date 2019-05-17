module DesktopApp exposing (program, Program, Model, Msg)

{-|

@docs program, Program, Model, Msg

-}

import Browser
import DesktopApp.JsonMapping exposing (ObjectMapping)
import DesktopApp.Ports as Ports
import DesktopApp.Testable as DesktopApp
import Dict exposing (Dict)
import Html exposing (Html)
import Json.Decode exposing (Decoder)
import Json.Encode as Json


{-| This is the type for your Elm program when using `DesktopApp.program`

For example:

    module Main exposing (main)

    import DesktopApp

    type alias Model = { ... }
    type Msg = ...

    main : DesktopApp.Program Model Msg
    main =
        DesktopApp.program { ... }

-}
type alias Program model msg =
    Platform.Program () (Model model) (Msg msg)


{-| This is the Model type for your Elm program when using [`DesktopApp.program`](#program).

Normally you won't need to refer to this directly -- use [`Program`](#Program) instead.

-}
type alias Model yourModel =
    DesktopApp.Model yourModel


{-| This is the Msg type for your Elm program when using [`DesktopApp.program`](#program).

Normally you won't need to refer to this directly -- use [`Program`](#Program) instead.

-}
type alias Msg yourMsg =
    DesktopApp.Msg yourMsg


{-| Use this to define your `main` in your `Main.elm` file, and then use the `elm-desktop-app`
command line tool to build your app.

  - `init`, `update`, `subscription`, `view`: These are the same as in any Elm program.
  - `persistence`: This specifies how the data for you app will be saved to the user's filesystem. (If `Nothing`, then you app will not persist any data.)

-}
program :
    { init : ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> Browser.Document msg
    , persistence : Maybe (ObjectMapping model msg)
    }
    -> Program model msg
program config =
    let
        p =
            DesktopApp.program config

        performAll ( cmd, effects ) =
            Cmd.batch
                [ cmd
                , effects
                    |> List.map perform
                    |> Cmd.batch
                ]

        perform effect =
            case effect of
                DesktopApp.WriteUserData content ->
                    Ports.writeUserData content

                DesktopApp.LoadUserData ->
                    Ports.loadUserData ()
    in
    Browser.document
        { init =
            \flags ->
                p.init flags
                    |> Tuple.mapSecond performAll
        , subscriptions = p.subscriptions
        , update =
            \msg model ->
                p.update msg model
                    |> Tuple.mapSecond performAll
        , view = p.view
        }
