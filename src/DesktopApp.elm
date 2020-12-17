module DesktopApp exposing
    ( program, Program, Window, Model, Msg
    , Menubar, defaultMenu, noMenu
    , customMenu
    )

{-| This module lets you write desktop applications (for Mac, Linux, and Windows) in Elm. You must use the [`elm-desktop-app` ![](https://img.shields.io/npm/v/elm-desktop-app.svg)][npm-package]
command line tool to build your program.
(`DesktopApp.program` will do nothing if you try to use it in a web browser.)

See the [README](./) for an example of how to set up and build your application.

[npm-package]: https://www.npmjs.com/package/elm-desktop-app

@docs program, Program, Window, Model, Msg
@docs Menubar, defaultMenu, noMenu

-}

import Browser
import DesktopApp.JsonMapping as JsonMapping exposing (ObjectMapping)
import DesktopApp.Menu exposing (MenuItem)
import DesktopApp.Menubar
import DesktopApp.Ports as Ports
import DesktopApp.Testable as DesktopApp
import Html exposing (Html)


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
    , view : model -> Window msg
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
                    |> List.map runEffect
                    |> Cmd.batch
                ]
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


runEffect : DesktopApp.Effect -> Cmd msg
runEffect effect =
    case effect of
        DesktopApp.WriteUserData content ->
            Ports.writeUserData content

        DesktopApp.LoadUserData ->
            Ports.loadUserData ()

        DesktopApp.SetMenu menubar ->
            Ports.setMenu menubar


{-| Returned by the `view` function provided to [`program`](#program).

This represents a single window that will be displayed to the user.

-}
type alias Window msg =
    { title : String
    , menubar : Menubar msg
    , body : List (Html msg)
    }


{-| Defines the menu that will be shown for a particular window.
-}
type alias Menubar msg =
    DesktopApp.Menubar.Menubar msg


{-| Shows the default Electron menu.
-}
defaultMenu : Menubar msg
defaultMenu =
    DesktopApp.defaultMenu


{-| Hides the menubar.
-}
noMenu : Menubar msg
noMenu =
    DesktopApp.noMenu


{-| Shows a custom menu.
-}
customMenu : List (MenuItem msg) -> Menubar msg
customMenu items =
    DesktopApp.Menubar.CustomMenu items
